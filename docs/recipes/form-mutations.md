---
name: form-mutations
category: recipe
version: 1
token_budget: 1500
description: Standard Action Envelopes, schema validation, optimistic rollbacks, and mutation idempotency.
---

# Form Mutations & Action Envelopes Recipe

Operational contracts and canonical implementation patterns for form submissions, data mutations, and optimistic UI rollbacks.

---

## 1. Non-Negotiable Invariants

- **Standardized Response Envelopes**:
  - Mutations must return a discriminated union: `{ success: true, data: T }` or `{ success: false, errors?: Record<string, string[]>, message?: string }`. Never return untyped nulls or allow unhandled database exceptions to crash client boundaries.
- **Pre-Execution Schema Validation**:
  - All input payloads must be validated against a formal parser (Zod, Valibot, ArkType, Pydantic) before invoking domain logic or database queries.
- **Deterministic Optimistic Rollback**:
  - Clients applying optimistic UI state updates must snapshot prior state and roll back cleanly if the server rejects or the network disconnects.
- **Double-Submission Guarding**:
  - Submit buttons must enter a pending/disabled state immediately upon submit. High-value mutations must verify client-generated idempotency keys.

---

## 2. Canonical Implementation Patterns

### Pattern A: Standard Envelope & Safe Parser

```typescript
import { z } from "zod";

export type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; message?: string; errors?: Record<string, string[]> };

export function parseInput<T>(
  schema: z.ZodSchema<T>,
  raw: unknown
): { ok: true; data: T } | { ok: false; failure: ActionResult<never> } {
  const res = schema.safeParse(raw);
  if (res.success) return { ok: true, data: res.data };

  const flat = res.error.flatten();
  return {
    ok: false,
    failure: {
      success: false,
      message: flat.formErrors[0] || "Invalid submission parameters",
      errors: flat.fieldErrors as Record<string, string[]>,
    },
  };
}
```

### Pattern B: Canonical Server Mutation Handler

```typescript
import { z } from "zod";

const ProfileSchema = z.object({
  name: z.string().min(2).max(50),
  email: z.string().email(),
});

export async function updateProfile(
  rawInput: unknown,
  userId: string,
  db: { update: (id: string, d: { name: string; email: string }) => Promise<{ id: string }> }
): Promise<ActionResult<{ id: string }>> {
  // Invariant: Validate before database access
  const parsed = parseInput(ProfileSchema, rawInput);
  if (!parsed.ok) return parsed.failure;

  try {
    const data = await db.update(userId, parsed.data);
    return { success: true, data };
  } catch (err) {
    return {
      success: false,
      message: err instanceof Error ? err.message : "Mutation failed",
    };
  }
}
```

### Pattern C: Optimistic Client Rollback

```typescript
export async function runOptimisticMutation<TState, TData>(opts: {
  getState: () => TState;
  applyOptimistic: (s: TState) => TState;
  setState: (s: TState) => void;
  mutate: () => Promise<ActionResult<TData>>;
  onSuccess: (data: TData) => void;
  onError: (msg: string) => void;
}): Promise<void> {
  const snapshot = opts.getState();
  opts.setState(opts.applyOptimistic(snapshot));

  try {
    const res = await opts.mutate();
    if (res.success) {
      opts.onSuccess(res.data);
    } else {
      opts.setState(snapshot); // Rollback on business error
      opts.onError(res.message || "Action rejected");
    }
  } catch (err) {
    opts.setState(snapshot); // Rollback on network/runtime error
    opts.onError(err instanceof Error ? err.message : "Network failure");
  }
}
```

---

## 3. Framework Adaptations

- **Next.js App Router**: Return `ActionResult<T>` directly from Server Actions with React 19 `useActionState`. Never throw validation errors to prevent unmounting forms.
- **Remix / React Router**: Return `json<ActionResult<T>>(res)` from `action` functions; access in UI via `useActionData()`.
- **Express / Fastify**: Return HTTP 400/422 with the `{ success: false, errors }` envelope for form field binding.

---

## 4. Anti-Patterns & Failure Modes

- **Throwing Errors for Validation**: Triggers framework error boundaries, replacing the whole form with an error screen.
- **Unsnapshot Optimistic Updates**: Modifying state in-place without retaining a clone leads to permanent UI corruption on failure.
- **Direct FormData Access**: Passing unparsed `formData.get()` directly to SQL/ORMs.

---

## 5. Verification Checklist

- [ ] Action returns conform to `{ success: true, data }` | `{ success: false, errors }`.
- [ ] Inputs are validated before executing persistent side-effects.
- [ ] Optimistic UI state captures prior state snapshot and rolls back on failure.
- [ ] Submit buttons enter pending states during in-flight requests.
