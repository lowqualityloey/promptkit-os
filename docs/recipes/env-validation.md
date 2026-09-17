---
name: env-validation
category: recipe
version: 1
token_budget: 1500
description: Boot-time preflight validation, client vs server boundaries, and type-safe environment schemas.
---

# Environment Configuration & Boundary Validation Recipe

Operational invariants and canonical implementation patterns for fail-fast environment variable validation and secret boundary enforcement.

---

## 1. Non-Negotiable Invariants

- **Fail-Fast Boot Preflight**:
  - Environment variables must be validated at process boot or build time. If any required variable is missing or malformed, terminate immediately with an actionable error list. Never defer missing config discovery to live runtime requests.
- **Client vs Server Isolation**:
  - Sensitive secrets (database credentials, private keys, webhook secrets) must never enter public client bundles. Enforce mandatory public prefixes (`NEXT_PUBLIC_`, `VITE_`, `PUBLIC_`) for client constants; non-prefixed variables are strictly server-only.
- **Explicit Type Coercion**:
  - Raw `process.env` values are strings. Numbers (ports, timeouts) and booleans must be explicitly coerced through schema parsers (`"false"` is truthy in raw JavaScript).
- **Centralized Typed Accessor**:
  - Domain code must import a centralized typed `env` singleton rather than querying `process.env` ad-hoc across files.

---

## 2. Canonical Implementation Patterns

### Pattern A: Schema-Based Preflight Validator

```typescript
import { z } from "zod";

const serverSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  DATABASE_URL: z.string().url(),
  SESSION_SECRET: z.string().min(32),
  PORT: z.coerce.number().int().positive().default(3000),
});

const clientSchema = z.object({
  NEXT_PUBLIC_APP_URL: z.string().url(),
  NEXT_PUBLIC_STRIPE_KEY: z.string().startsWith("pk_"),
});

export function createEnv(isServer: boolean = typeof window === "undefined") {
  const merged = isServer ? serverSchema.merge(clientSchema) : clientSchema;
  const parsed = merged.safeParse(process.env);

  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `  - ${i.path.join(".")}: ${i.message}`).join("\n");
    throw new Error(`❌ FATAL: Environment validation failed on startup:\n${issues}`);
  }
  return parsed.data;
}

export const env = createEnv();
```

### Pattern B: Build-Time Server Module Isolation Guard

```typescript
// Enforce compile-time or runtime crash if server module is imported in client
if (typeof window !== "undefined") {
  throw new Error("SECURITY_ERROR: Server module imported into client bundle");
}
```

---

## 3. Framework Adaptations

- **Next.js App Router**: Use `@t3-oss/env-nextjs` or import `src/env.ts` inside `next.config.mjs` to validate during `next build`.
- **Vite**: Use `import.meta.env` with `VITE_` prefix; validate configs in `vite.config.ts`.
- **Express / Fastify**: Import `src/env.ts` at the top of `src/index.ts` before starting listeners.
- **Go / Python**: In Go, use `caarlos0/env` with struct tags. In Python, use `pydantic-settings` `BaseSettings`.

---

## 4. Anti-Patterns & Failure Modes

- **Prefixing Private Keys with `NEXT_PUBLIC_`**: Exposes sensitive credentials to browser users via client JavaScript bundles.
- **String Boolean Truthiness**: `if (process.env.FLAG)` evaluates to `true` when `FLAG="false"`.
- **Scattered `process.env` Reads**: Directly reading raw environment variables without type safety guarantees.
- **Skipping CI Preflights**: Failing to assert environment schemas during automated CI builds.

---

## 5. Verification Checklist

- [ ] All environment variables are validated against schemas at startup.
- [ ] Missing variables cause immediate process exit with clear error logs.
- [ ] No server secrets have client-accessible prefixes.
- [ ] Integers and booleans are coerced to native primitives.
- [ ] Codebase imports the centralized `env` singleton.
