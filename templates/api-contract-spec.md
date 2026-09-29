# API Contract Specification: [Feature / Endpoint Name]

- **Author**: [Your Name / Team]
- **Status**: [Draft | In Review | Approved | Implemented]
- **Created**: [YYYY-MM-DD]
- **Protocol**: [REST / tRPC / Next.js Server Action]
- **Base Route**: `/api/v1/[resource]`

---

## 1. Endpoint Overview

| Method | Route Path | Auth Required | Idempotency Key | Rate Limit |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/workspaces/:id/invitations` | Yes (`members:invite`) | Required (`Header`) | 10 req / min |
| `GET`  | `/api/v1/workspaces/:id/invitations` | Yes (`members:read`)   | No | 60 req / min |

---

## 2. Request Schema Contracts

> **Stack-neutral:** Examples below use TypeScript + Zod. Substitute your project's native validator (e.g., Valibot, Pydantic, Go `validator`, Rust `validator` crate) and language.

### Path Parameters
```typescript
export const WorkspaceParamsSchema = z.object({
  id: z.string().uuid({ message: 'Invalid workspace UUID format' }),
});
export type WorkspaceParams = z.infer<typeof WorkspaceParamsSchema>;
```

### Query Parameters (for GET routes)
```typescript
export const ListInvitationsQuerySchema = z.object({
  limit: z.coerce.number().min(1).max(100).default(20),
  cursor: z.string().optional(),
  status: z.enum(['PENDING', 'ACCEPTED', 'EXPIRED']).optional(),
  sort: z.enum(['createdAt', '-createdAt']).default('-createdAt'),
});
export type ListInvitationsQuery = z.infer<typeof ListInvitationsQuerySchema>;
```

### Request Body (for POST / PATCH routes)
```typescript
export const CreateInvitationBodySchema = z.object({
  email: z.string().email({ message: 'Valid email required' }),
  role: z.enum(['ADMIN', 'MEMBER', 'VIEWER']),
});
export type CreateInvitationBody = z.infer<typeof CreateInvitationBodySchema>;
```

---

## 3. Success Response Schemas

### Single Resource Payload (HTTP 201 Created)
```typescript
export const InvitationResponseSchema = z.object({
  data: z.object({
    id: z.string().uuid(),
    workspaceId: z.string().uuid(),
    email: z.string().email(),
    role: z.enum(['ADMIN', 'MEMBER', 'VIEWER']),
    expiresAt: z.string().datetime(),
    createdAt: z.string().datetime(),
  }),
});
export type InvitationResponse = z.infer<typeof InvitationResponseSchema>;
```

### Paginated List Payload (HTTP 200 OK)
```typescript
export const PaginatedInvitationsResponseSchema = z.object({
  data: z.array(InvitationResponseSchema.shape.data),
  pagination: z.object({
    limit: z.number(),
    hasMore: z.boolean(),
    nextCursor: z.string().nullable(),
  }),
});
export type PaginatedInvitationsResponse = z.infer<typeof PaginatedInvitationsResponseSchema>;
```

---

## 4. Error Response Envelope & Error Code Dictionary

### Unified Error Envelope
> Member identifiers are returned only to callers holding `members:read`. The `members:invite`-only caller below receives conflict context with no member email or internal user ID.
```json
{
  "error": {
    "code": "MEMBER_ALREADY_EXISTS",
    "message": "A member with this email already belongs to the workspace.",
    "details": {
      "workspaceId": "ws_01h8x4..."
    },
    "requestId": "req_01h8x4v9b2c3"
  }
}
```

### Error Code Catalog (HTTP API example — adapt to interface; use interface-appropriate error codes)
| HTTP Status | Error Code (`error.code`) | Human Message (`error.message`) | Trigger Condition |
| :--- | :--- | :--- | :--- |
| `400` | `INVALID_PAYLOAD` | Invalid request parameters. | Request fails schema validation (e.g., Zod for TypeScript; use project's native validator). |
| `401` | `UNAUTHENTICATED` | Authentication required. | Missing or expired session cookie. |
| `403` | `PERMISSION_DENIED` | You lack permission to invite members. | User lacks `members:invite` permission. |
| `404` | `WORKSPACE_NOT_FOUND` | Workspace not found. | Target workspace ID does not exist. |
| `409` | `MEMBER_ALREADY_EXISTS`| User already belongs to workspace. | Email is already an active member. |
| `409` | `IDEMPOTENCY_CONFLICT` | A mutation with this key is currently processing. | Duplicate concurrent submission. |
| `429` | `RATE_LIMIT_EXCEEDED` | Too many requests. | Rate threshold exceeded for this IP/token. |

---

## 5. Client Integration & Consumption Example

```typescript
// Example frontend React Query mutation hook
export function useCreateInvitation(workspaceId: string) {
  // Idempotency key lifecycle: the caller mints one key per deliberate logical
  // operation and passes it with the variables. React Query reuses the same
  // variables (and key) across automatic retries of that operation, so an
  // uncertain outcome retried is never executed twice — while each new
  // deliberate submission (and each concurrent submission) carries its own key.
  // Call site: mutate({ payload, idempotencyKey: crypto.randomUUID() }).
  return useMutation({
    mutationFn: async ({ payload, idempotencyKey }: { payload: CreateInvitationBody; idempotencyKey: string }) => {
      const res = await fetch(`/api/v1/workspaces/${workspaceId}/invitations`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Idempotency-Key': idempotencyKey,
        },
        body: JSON.stringify(payload),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new ApiError(json.error);
      }
      return json.data;
    },
  });
}
```
