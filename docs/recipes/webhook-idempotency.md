---
name: webhook-idempotency
category: recipe
version: 1
token_budget: 1500
description: Raw body preservation, timing-safe HMAC verification, and idempotency ledgers.
---

# Webhook Ingestion & Idempotency Recipe

Security invariants and canonical patterns for reliable webhook ingestion and signature validation.

---

## 1. Non-Negotiable Invariants

- **Raw Byte Preservation Before Parsing**:
  - Compute HMAC signatures on the raw byte stream. Never re-serialize parsed JSON (`JSON.stringify(req.body)`) to verify; ordering, whitespace, and precision changes corrupt the digest.
- **Constant-Time Signature Comparison**:
  - Compare digests with constant-time equality (`crypto.timingSafeEqual`, Go `hmac.Equal`, Python `secrets.compare_digest`). `===` leaks timing.
- **Idempotency Ledger & Duplicate Suppression**:
  - Providers deliver at least once; duplicates are expected. Record event IDs in a table with a unique constraint and return HTTP 200 for duplicates without re-running side effects.
- **Fast ACK & Asynchronous Offloading**:
  - Acknowledge within the provider's timeout window (3–5s); offload lengthy work to background queues.

---

## 2. Canonical Implementation Patterns

### Pattern A: Timing-Safe HMAC Verification

```typescript
import crypto from "node:crypto";

// Bare scheme only: a single "<prefix><hex>" digest over rawBody (e.g. GitHub "sha256=").
// Stripe uses a different scheme — see section 3.
export function verifyHmacSignature(opts: {
  rawBody: Buffer | string;
  signature: string;
  secret: string;
  prefix?: string;
}): boolean {
  const hmac = crypto.createHmac("sha256", opts.secret);
  hmac.update(opts.rawBody);
  const expected = (opts.prefix || "") + hmac.digest("hex");

  const expBuf = Buffer.from(expected);
  const provBuf = Buffer.from(opts.signature);

  // Invariant: Constant-time comparison with length matching
  if (expBuf.length !== provBuf.length) return false;
  return crypto.timingSafeEqual(expBuf, provBuf);
}
```

### Pattern B: Ingestion Pipeline with Idempotency Ledger

```typescript
export interface WebhookLedger {
  claim: (eventId: string) => Promise<"NEW" | "DUPLICATE">;
  markDone: (eventId: string) => Promise<void>;
  markFailed: (eventId: string, reason: string) => Promise<void>;
}

// Shared core: runs only AFTER the raw body has been verified.
export async function processVerifiedEvent(
  eventId: string, payload: unknown, ledger: WebhookLedger,
  enqueue: (event: unknown) => Promise<void>,
): Promise<{ status: number; message: string }> {
  // Invariant: atomic duplicate detection before any side effect
  if ((await ledger.claim(eventId)) === "DUPLICATE") {
    return { status: 200, message: "Duplicate event acknowledged" };
  }
  try {
    // Invariant: offload work asynchronously
    await enqueue(payload);
    await ledger.markDone(eventId);
    return { status: 200, message: "Accepted" };
  } catch (err) {
    await ledger.markFailed(eventId, err instanceof Error ? err.message : "Error");
    return { status: 500, message: "Queue failure" };
  }
}

// Bare-HMAC entrypoint: verify, parse, then hand a verified event to the core.
export async function handleWebhook(opts: {
  rawBody: string; signature: string; secret: string;
  ledger: WebhookLedger; enqueue: (event: unknown) => Promise<void>;
}): Promise<{ status: number; message: string }> {
  if (!verifyHmacSignature({ rawBody: opts.rawBody, signature: opts.signature, secret: opts.secret })) {
    return { status: 401, message: "Invalid signature" };
  }
  const payload = JSON.parse(opts.rawBody);
  if (!payload?.id) return { status: 400, message: "Missing event ID" };
  return processVerifiedEvent(payload.id, payload, opts.ledger, opts.enqueue);
}
```

---

## 3. Framework Adaptations

- **Next.js (Stripe)**: Stripe signs `"<timestamp>.<rawBody>"` with a `t=,v1=` header, so never pass it to `verifyHmacSignature`. Verify and parse with `constructEvent`, then route the event to the shared core:
  ```typescript
  import Stripe from "stripe";
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

  export async function POST(req: Request) {
    const rawBody = await req.text();
    const signature = req.headers.get("stripe-signature") ?? "";
    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(rawBody, signature, process.env.STRIPE_WEBHOOK_SECRET!);
    } catch {
      return Response.json({ error: "Invalid signature" }, { status: 400 }); // no side effects
    }
    const result = await processVerifiedEvent(event.id, event, ledger, enqueue);
    return Response.json({ message: result.message }, { status: result.status });
  }
  ```
- **Express**: Use `express.raw({ type: "application/json" })` on webhook routes prior to `express.json()`.
- **Fastify**: Register `fastify-raw-body` with `{ runFirst: true }`.
- **Go / Python**: Read raw bytes (`io.ReadAll(r.Body)` / `await request.body()`) before unmarshaling, then verify with the provider SDK helper (e.g. Go `webhook.ConstructEvent`).

---

## 4. Anti-Patterns & Failure Modes

- **Re-serializing Parsed JSON**: `JSON.stringify(req.body)` alters formatting and breaks valid signatures.
- **Using `===` for Digests**: Leaks byte-matching timing information.
- **Synchronous Heavy Operations**: Long tasks inside the handler trigger provider timeout retries.
- **Returning 500 on Duplicates**: Signals the provider to retry forever; always return 200.

---

## 5. Verification Checklist

- [ ] HMAC verification consumes raw body stream before JSON parsing.
- [ ] Digest comparison uses `crypto.timingSafeEqual` or equivalent.
- [ ] Stripe deliveries are verified with `webhooks.constructEvent`, never the bare-HMAC helper.
- [ ] Rejected, tampered, or duplicate deliveries produce no ledger or queue side effects.
- [ ] Unique constraints on event IDs prevent duplicate side effects.
- [ ] Duplicate event deliveries acknowledge with HTTP 200.
- [ ] Heavy workloads are queued to background tasks.
