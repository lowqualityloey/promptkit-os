# Auth Workflow (Authentication Architecture & Access Control Matrices)

## Fast Shorthand
Trigger anytime with: `pk:auth` (or `/pk-auth`)

## Mission
Guide the developer through designing robust, production-grade Authentication (AuthN) and Authorization (AuthZ) architectures.

Eliminate the primary causes of authentication vulnerabilities: token storage in browser `localStorage`, missing CSRF mitigations, flawed OAuth state validation, fragile string-based role checks, and missing session revocation capabilities.

---

## Preconditions
- Developer is implementing user registration, authentication, third-party OAuth, session management, or role-based permissions.
- Auth work is Level 2 (Controlled): a canonical Task Record at `docs/tasks/<task-id>.md` is required before implementation (see `workflows/route.md`).
- Target storage directory: `./docs/auth/` in the host project.
- Access to `templates/auth-matrix-template.md`.
- Recipe: see `docs/recipes/auth-session.md` for cookie vs bearer lifecycles, route guards, and refresh token rotation.

---

## Core Authentication & Authorization Pillars

### 1. Session Storage and Token Hygiene
- **Storage Strategy**:
  - **Server-Managed Database Sessions (Recommended for Web Apps)**: Store an opaque session ID in an `HttpOnly` cookie; query session state in Redis or PostgreSQL. Allows immediate server-side revocation on account compromise.
  - **Stateless JWTs**: Use only when cross-domain microservice token propagation is strictly necessary. Keep access token lifetimes short (5 to 15 minutes) and pair with refresh tokens.
- **Strict Cookie Configuration**:
  - Never store access or refresh tokens in `localStorage` or `sessionStorage` (vulnerable to XSS extraction; see `docs/recipes/auth-session.md`).
  - All auth cookies must carry explicit security attributes:
    ```typescript
    res.setHeader('Set-Cookie', [
      'session_id=...;',
      'HttpOnly;',                 // Disallows JavaScript access (XSS immune)
      'Secure;',                   // Transmitted only over HTTPS
      'SameSite=Lax;',             // Protects against CSRF on top-level navigations
      'Path=/;',
      'Max-Age=604800;'            // Explicit expiration in seconds
    ].join(' '));
    ```
- **Refresh Token Rotation & Reuse Detection**:
  - Issue refresh tokens in rotating families. When a refresh token is used, invalidate it and issue a new one.
  - If an already-used refresh token is presented, assume token theft: immediately invalidate all sessions belonging to that user.

---

### 2. Authentication Flows and Identity Providers
1. **OAuth 2.0 / OIDC with PKCE**:
   - Always use the **Authorization Code Flow with PKCE** (Proof Key for Code Exchange), even for server-side applications.
   - Generate a cryptographically random `state` parameter and verify it in the callback to prevent CSRF login attacks.
2. **Passkeys and WebAuthn (Passwordless)**:
   - Provide passkey support as a first-class credential option.
   - Store public keys, credential IDs, and signature counters in the database.
   - Verify signature counters to prevent credential cloning.
3. **Magic Links and Email Verification**:
   - Hash tokens with SHA-256 before storing in the database.
   - Bind magic link tokens to short TTLs (10 to 15 minutes max) and single-use constraints (`used_at IS NULL`).

---

### 3. Authorization Modeling (RBAC and ABAC)
Avoid hardcoding role checks like `if (user.role === 'ADMIN')` throughout the codebase. Instead, decouple **Roles** from **Permissions**:

1. **Granular Capabilities (Permissions)**:
   - Define permissions as discrete `resource:action` strings:
     - `documents:read`
     - `documents:create`
     - `members:invite`
     - `billing:manage`
2. **Role Mapping**:
   - Roles are bundles of permissions:
     ```typescript
     export const RolePermissions = {
       VIEWER: ['documents:read'],
       EDITOR: ['documents:read', 'documents:create'],
       ADMIN:  ['documents:read', 'documents:create', 'members:invite', 'billing:manage'],
     } as const;
     ```
3. **Attribute-Based Access Control (ABAC) for Ownership**:
   - When access depends on context (e.g., "A user can only edit their own profile"), evaluate ownership attributes explicitly:
     ```typescript
     function canEditDocument(user: UserSession, doc: Document): boolean {
       if (hasPermission(user, 'documents:manage_all')) return true;
       return hasPermission(user, 'documents:create') && doc.createdById === user.id;
     }
     ```

---

### 4. Defense-in-Depth and Endpoint Hardening
1. **Rate Limiting on Sensitive Endpoints**:
   - Apply strict, tiered rate limiting to `/auth/login`, `/auth/register`, `/auth/forgot-password`, and `/auth/verify-otp`.
   - Rate limit by IP address and targeted account identifier to stop credential stuffing and brute-force attacks.
2. **Timing-Attack Resistance**:
   - Use constant-time comparisons when checking passwords, tokens, or signatures (always verify buffer length equality first, as `crypto.timingSafeEqual` throws if byte lengths differ):
     ```typescript
     import crypto from 'node:crypto';

     function safeTokenCompare(provided: string, stored: string): boolean {
       const a = Buffer.from(provided);
       const b = Buffer.from(stored);
       if (a.length !== b.length) {
         return false;
       }
       return crypto.timingSafeEqual(a, b);
     }
     ```
3. **Session Invalidation on Security Events**:
   - Invalidate all existing active sessions when a user resets their password, changes their email, or updates their 2FA settings.

---

## Workflow Steps

### Step 1: Define Authentication Strategy
1. Identify authentication requirements: Email/password, OAuth providers (Google, GitHub), magic links, passkeys.
2. Choose session model: Database session cookie vs. short-lived JWT with rotating refresh cookies.

### Step 2: Draft the Authorization Matrix
1. List all domain resources and required actions.
2. Map permissions to roles in a structured matrix.
3. Define ownership and multi-tenant isolation rules.

### Step 3: Specify Token Lifecycles and Cookie Security
1. Define access token lifetime, refresh token rotation strategy, and session idle timeouts.
2. Verify all cookie attributes (`HttpOnly`, `Secure`, `SameSite`).

### Step 4: Threat Modeling and Attack Surface Review
1. Review brute-force mitigations, rate-limit thresholds, and lockout policies.
2. Ensure secrets (signing keys, OAuth client secrets) are loaded via environment variables and never exposed to client bundles.
3. Record threat-model findings (threat, affected surface, mitigation, residual risk) in the Step 5 specification artifact — findings have no other destination and must not evaporate into chat.

### Step 5: Generate Auth Specification Artifact
1. Use `templates/auth-matrix-template.md`.
2. Save specification to `./docs/auth/YYYY-MM-DD-auth-<subsystem>.md`.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Vulnerability | Remedy |
| :--- | :--- | :--- |
| **Tokens in LocalStorage** | Direct token exfiltration via cross-site scripting (XSS). | Store tokens in `HttpOnly`, `Secure`, `SameSite=Lax/Strict` cookies to block script access (pair with CSRF protection). |
| **Hardcoded Role Strings** | Brittle access control that breaks when adding new tiers. | Model access as granular capabilities/permissions. |
| **Missing OAuth State** | CSRF login attacks linking attacker accounts to victim sessions. | Validate cryptographically secure `state` parameter in callback. |
| **Unbounded Auth Endpoints** | Credential stuffing and distributed brute-force attacks. | Enforce rate limiting by IP and username. |
| **Permanent JWT Lifetimes** | Inability to revoke compromised tokens before expiration. | Keep JWTs short-lived (<15m) or use server-tracked sessions. |

---

## Completion Criteria
- Comprehensive auth specification generated in `./docs/auth/`.
- Cookie security attributes and token lifetimes explicitly defined.
- RBAC capability matrix and ABAC ownership rules documented.
- Rate-limiting thresholds and session invalidation rules established.
