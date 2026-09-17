---
name: webhook-idempotency
category: recipe
version: 1
token_budget: 1500
description: Raw body preservation, timing-safe HMAC verification, and idempotency ledgers.
---

# Webhook Ingestion & Idempotency Recipe

Operational security invariants and canonical implementation patterns for reliable webhook ingestion and signature validation.

---

## 1. Non-Negotiable Invariants

- **Raw Byte Preservation Before Parsing**:
  - HMAC webhook signatures must be computed on the raw incoming byte stream. Never re-serialize parsed JSON (`JSON.stringify(req.body)`) to verify signatures; property ordering, whitespace, and numerical precision changes will corrupt the digest.
- **Constant-Time Signature Comparison**:
  - Signature digests must be compared using constant-time equality (`crypto.timingSafeEqual` in Node.js, `hmac.Equal` in Go, `secrets.compare_digest` in Python). String equality (`===`) is vulnerable to timing attacks.
- **Idempotency Ledger & Duplicate Suppression**:
  - Webhook providers guarantee at-least-once delivery; duplicates are expected. Handlers must record event IDs in an idempotency table with a unique constraint. Duplicate deliveries must return HTTP 200 immediately without executing side effects again.
- **Fast ACK & Asynchronous Offloading**:
  - Webhook HTTP handlers must acknowledge receipt within the provider's timeout window (3–5s). Lengthy tasks must be offloaded to background job queues.

---

## 2. Canonical Implementation Patterns

### Pattern A: Timing-Safe HMAC Verification

```typescript
import crypto from "node:crypto";

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

export async function handleWebhook(opts: {
  rawBody: string;
  signature: string;
  secret: string;
  ledger: WebhookLedger;
  enqueue: (event: unknown) => Promise<void>;
}): Promise<{ status: number; message: string }> {
  // 1. Invariant: Verify raw body before parsing
  if (!verifyHmacSignature({ rawBody: opts.rawBody, signature: opts.signature, secret: opts.secret })) {
    return { status: 401, message: "Invalid signature" };
  }

  const payload = JSON.parse(opts.rawBody);
  const eventId = payload.id;
  if (!eventId) return { status: 400, message: "Missing event ID" };

  // 2. Invariant: Atomic duplicate detection
  const state = await opts.ledger.claim(eventId);
  if (state === "DUPLICATE") {
    return { status: 200, message: "Duplicate event acknowledged" };
  }

  try {
    // 3. Offload work asynchronously
    await opts.enqueue(payload);
    await opts.ledger.markDone(eventId);
    return { status: 200, message: "Accepted" };
  } catch (err) {
    await opts.ledger.markFailed(eventId, err instanceof Error ? err.message : "Error");
    return { status: 500, message: "Queue failure" };
  }
}
```

---

## 3. Framework Adaptations

- **Next.js Route Handler**:
  ```typescript
  export async function POST(req: Request) {
    const rawBody = await req.text(); // Reads raw body stream directly
    const signature = req.headers.get("stripe-signature") || "";
    // ...verify and dispatch
  }
  ```
- **Express**: Use `express.raw({ type: "application/json" })` on webhook routes prior to `express.json()`.
- **Fastify**: Register `fastify-raw-body` with `{ runFirst: true }`.
- **Go / Python**: Read raw bytes via `io.ReadAll(r.Body)` or `await request.body()` before JSON unmarshaling.

---

## 4. Anti-Patterns & Failure Modes

- **Re-serializing Parsed JSON**: Running `JSON.stringify()` on `req.body` alters formatting, breaking valid webhook signatures.
- **Using `===` for Digests**: Leaks byte-matching timing information.
- **Synchronous Heavy Operations**: Running emails, file generation, or migrations inside the HTTP webhook handler triggers provider timeout retries.
- **Returning 500 on Duplicates**: Returning 500 when catching duplicate key errors tells the provider to retry continuously. Always return 200.

---

## 5. Verification Checklist

- [ ] HMAC verification consumes raw body stream before JSON parsing.
- [ ] Digest comparison uses `crypto.timingSafeEqual` or equivalent.
- [ ] Unique constraints on event IDs prevent duplicate side effects.
- [ ] Duplicate event deliveries acknowledge with HTTP 200.
- [ ] Heavy workloads are queued to background tasks.
