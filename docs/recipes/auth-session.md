---
name: auth-session
category: recipe
version: 1
token_budget: 1500
description: Cookie vs Bearer lifecycles, route guards, and refresh token rotation.
---

# Authentication & Session Boundary Recipe

Operational security invariants and canonical implementation patterns for browser sessions and programmatic API authentication.

---

## 1. Non-Negotiable Invariants

- **Storage Isolation by Client**:
  - **Browser**: Session tokens must be stored in `HttpOnly; Secure; SameSite=Lax` (or `Strict`) cookies. Never store session or refresh tokens in `localStorage` or `sessionStorage` (vulnerable to XSS).
  - **Machine/Mobile**: Bearer tokens are reserved for native apps, CLIs, and service accounts passing `Authorization: Bearer <token>` headers.
- **Server-Side Signature Verification**:
  - Route middleware and endpoints must cryptographically verify session tokens on every request. Never trust unverified client-side state or unvalidated JWT payloads.
- **Single-Use Refresh & Family Revocation**:
  - Refresh tokens must rotate on every exchange via atomic conditional consumption (single transaction or conditional write). If two concurrent requests present the same token or an already-used refresh token is presented, at most one exchange can succeed; any failed consumption triggers **Automatic Family Invalidation** revoking all sessions in that token family immediately.
- **CSRF Defense on State Mutations**:
  - Cookie-authenticated state mutations (`POST`, `PUT`, `DELETE`) must verify `Origin`/`Referer` headers or validate anti-CSRF tokens alongside `SameSite` cookies.

---

## 2. Canonical Implementation Patterns

### Pattern A: Secure Session Cookie Helper

```typescript
export const SESSION_COOKIE = "app_session";

export function setSessionCookie(headers: Headers, token: string, isProd: boolean): void {
  const parts = [
    `${SESSION_COOKIE}=${token}`,
    "Path=/",
    "Max-Age=604800", // 7 days
    "HttpOnly",
    "SameSite=Lax",
  ];
  if (isProd) parts.push("Secure");
  headers.append("Set-Cookie", parts.join("; "));
}
```

### Pattern B: Unified Route Guard

```typescript
export interface SessionPrincipal {
  userId: string;
  role: string;
  sessionId: string;
}

export async function authenticateRequest(
  cookieHeader: string | null,
  authHeader: string | null,
  verify: (raw: string) => Promise<SessionPrincipal | null>
): Promise<SessionPrincipal> {
  let token: string | null = null;

  if (authHeader?.startsWith("Bearer ")) {
    token = authHeader.slice(7).trim();
  } else if (cookieHeader) {
    const match = cookieHeader.match(new RegExp(`(?:^|; )${SESSION_COOKIE}=([^;]*)`));
    if (match) token = decodeURIComponent(match[1]);
  }

  if (!token) throw new Error("UNAUTHORIZED: Missing credentials");
  const principal = await verify(token);
  if (!principal) throw new Error("UNAUTHORIZED: Invalid or expired token");
  return principal;
}
```

### Pattern C: Refresh Token Rotation with Atomic Single-Use Consumption

```typescript
export interface RotationResult {
  status: "success" | "reuse_detected" | "not_found";
  successorTokenId?: string;
  familyId?: string;
}

export async function rotateRefreshToken(
  tokenId: string,
  store: {
    // Atomically consumes unused token and creates successor in a single transaction/CAS write
    consumeAndRotate: (tokenId: string) => Promise<RotationResult>;
    revokeFamily: (familyId: string) => Promise<void>;
  }
): Promise<string> {
  const result = await store.consumeAndRotate(tokenId);

  if (result.status === "not_found") {
    throw new Error("UNAUTHORIZED: Unknown token");
  }

  // Invariant: Failed consumption due to prior use triggers immediate family invalidation
  if (result.status === "reuse_detected") {
    if (result.familyId) await store.revokeFamily(result.familyId);
    throw new Error("SECURITY_ALERT: Token reuse detected; family revoked");
  }

  if (!result.successorTokenId) {
    throw new Error("INTERNAL_ERROR: Failed to issue successor token");
  }

  return result.successorTokenId;
}
```

> **Transaction Atomicity Invariant**: Token consumption and successor creation must occur in a single atomic transaction or conditional write (e.g. `UPDATE ... WHERE id = $1 AND used = false`). Non-atomic reads and writes allow concurrent exchanges to mint duplicate valid successors.

---

## 3. Framework Adaptations

- **Next.js App Router**: Await `cookies()` in Server Components/Route Handlers. Check sessions in middleware before route rendering.
- **Express / Fastify**: Read cookies via `req.cookies`, verify, and attach `req.user`. Return HTTP 401 on failure.
- **Go / Python**: In Go, use `http.Cookie` with `HttpOnly: true`. In FastAPI, extract via `Cookie(None)` and `Depends()`.

---

## 4. Anti-Patterns & Failure Modes

- **LocalStorage Tokens**: Storing auth tokens in `localStorage` invites instant XSS exfiltration.
- **Client-Decoded Claims**: Trusting `jwt.decode()` in the browser without server cryptographic verification.
- **Unbounded Refresh Tokens**: Non-expiring tokens without single-use rotation or revocation tables.
- **Non-Atomic Token Exchange**: Reading `used=false`, marking used, and creating a successor in separate non-transactional awaits allows concurrent exchanges to mint multiple valid successors without triggering reuse detection.
- **Silent Fallback to Guest**: Masking expired tokens by silently treating users as unauthenticated rather than returning 401.

---

## 5. Verification Checklist

- [ ] Auth cookies enforce `HttpOnly`, `Secure` (prod), and `SameSite=Lax/Strict`.
- [ ] No tokens stored in `localStorage` or `sessionStorage`.
- [ ] Refresh token consumption and rotation are atomic (single transaction or conditional write); concurrent exchanges cannot issue multiple successors and reuse revokes the entire family.
- [ ] Protected endpoints reject invalid sessions with 401.
