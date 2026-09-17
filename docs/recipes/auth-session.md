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
  - Refresh tokens must rotate on every exchange. If an already-used refresh token is presented, trigger **Automatic Family Invalidation**: revoke all sessions for that token family immediately.
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

### Pattern C: Refresh Token Rotation with Reuse Detection

```typescript
export async function rotateRefreshToken(
  tokenId: string,
  store: {
    get: (id: string) => Promise<{ id: string; familyId: string; used: boolean; userId: string } | null>;
    markUsed: (id: string) => Promise<void>;
    revokeFamily: (familyId: string) => Promise<void>;
    create: (userId: string, familyId: string) => Promise<string>;
  }
): Promise<string> {
  const token = await store.get(tokenId);
  if (!token) throw new Error("UNAUTHORIZED: Unknown token");

  // Invariant: Reuse detection triggers family revocation
  if (token.used) {
    await store.revokeFamily(token.familyId);
    throw new Error("SECURITY_ALERT: Token reuse detected; family revoked");
  }

  await store.markUsed(token.id);
  return store.create(token.userId, token.familyId);
}
```

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
- **Silent Fallback to Guest**: Masking expired tokens by silently treating users as unauthenticated rather than returning 401.

---

## 5. Verification Checklist

- [ ] Auth cookies enforce `HttpOnly`, `Secure` (prod), and `SameSite=Lax/Strict`.
- [ ] No tokens stored in `localStorage` or `sessionStorage`.
- [ ] Refresh tokens rotate upon use; reuse revokes the entire family.
- [ ] Protected endpoints reject invalid sessions with 401.
