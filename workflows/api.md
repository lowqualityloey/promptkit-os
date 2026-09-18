# API Workflow (Frontend-Backend Contracts & Error Envelopes)

## Fast Shorthand
Trigger anytime with: `pk:api` (or `/pk-api`)

## Mission
Guide the developer through designing clean, robust, type-safe API contracts across the frontend-backend seam.

Eliminate the leading causes of API integration friction: inconsistent error shapes, unhandled network edge cases, brittle status code usage, missing mutation idempotency, and manually duplicated type definitions.

---

## Preconditions
- Developer is designing an API endpoint, tRPC router, Next.js Server Action, or webhook handler.
- Public or breaking contract work is Level 2 (Controlled): a canonical Task Record at `docs/tasks/<task-id>.md` is required before implementation (see `workflows/route.md`).
- Target storage directory: `./docs/api/` in the host project.
- Access to `templates/api-contract-spec.md`.

---

## Core API Contract Pillars

### 1. Protocol Conventions and HTTP Semantics
- **Resource-Oriented Routes**:
  - Use plural nouns for resource collections: `/api/v1/workspaces`, `/api/v1/workspaces/:id/members`.
  - Use sub-resources for nested relations: `/api/v1/workspaces/:id/documents`.
  - Use explicit verb actions only when an operation does not map cleanly to CRUD: `/api/v1/orders/:id/cancel`.
- **HTTP Method Precision**:
  - `GET`: Safe and idempotent read operations. Never mutates server state.
  - `POST`: Non-idempotent resource creation or procedural action dispatch.
  - `PATCH`: Partial updates containing only the modified fields.
  - `PUT`: Complete idempotent resource replacement.
  - `DELETE`: Resource removal. Subsequent requests return 204 or 404.
- **Accurate Status Codes**:
  - `200 OK`: Successful read or update returning payload.
  - `201 Created`: Successful resource creation (include `Location` header where appropriate).
  - `204 No Content`: Successful mutation returning no payload (typical for `DELETE`).
  - `400 Bad Request`: Malformed JSON or syntax failure.
  - `401 Unauthorized`: Missing or invalid authentication token/session.
  - `403 Forbidden`: Authenticated user lacks permission for this action.
  - `404 Not Found`: Resource does not exist (or concealed for privacy).
  - `409 Conflict`: Business invariant or optimistic concurrency violation.
  - `422 Unprocessable Entity`: Semantic validation failure (e.g. Zod schema errors).
  - `429 Too Many Requests`: Rate limit exceeded (include `Retry-After` header).
  - `500 Internal Server Error`: Unhandled crash; never leak stack traces to client.

---

### 2. The Unified Error Envelope
Never return ad-hoc strings or inconsistent error formats. All non-2xx responses must adhere to a strict, parseable error structure:

```json
{
  "error": {
    "code": "WORKSPACE_LIMIT_EXCEEDED",
    "message": "This organization has reached its limit of 5 active workspaces.",
    "details": {
      "limit": 5,
      "current": 5,
      "upgradeUrl": "/billing/plans"
    },
    "requestId": "req_01h8x4v9b2c3"
  }
}
```

#### Why Machine-Readable Error Codes Matter:
- Frontend code must **never** inspect human-readable `message` strings to control UI state (such strings change for i18n or copy polish).
- Frontend logic switches programmatically on `error.code`:
  ```typescript
  if (error.code === 'WORKSPACE_LIMIT_EXCEEDED') {
    openUpgradeModal(error.details.upgradeUrl);
  }
  ```

---

### 3. Pagination, Filtering, and Sorting
1. **Cursor-Based Pagination (Default for Feeds & Large Datasets)**:
   - Use time-sortable cursor keys (`createdAt` or ID) instead of offset limits:
     ```typescript
     // Query Parameters
     // GET /api/v1/documents?limit=25&cursor=doc_01h8x4v...
     
     // Response Payload
     {
       "data": [ ... ],
       "pagination": {
         "limit": 25,
         "hasMore": true,
         "nextCursor": "doc_01h8x9p..."
       }
     }
     ```
   - Benefit: Eliminates missing or duplicated records when items are inserted while a user scrolls.
2. **Offset-Based Pagination**:
   - Use `page` and `pageSize` strictly for traditional administrative tables requiring page number navigation.
3. **Structured Query Filters & Sorters**:
   - Keep sort params explicit: `?sort=-createdAt,title` (minus sign denotes descending order).
   - Namespace filters: `?filter[status]=ACTIVE&filter[role]=ADMIN`.

---

### 4. Mutation Idempotency
For non-idempotent operations where network timeouts can cause accidental duplicate executions (such as payment charges, account promotions, or bulk dispatches):

1. **Client Header**:
   - Require an `Idempotency-Key` header (UUIDv4) on mutation requests.
2. **Server Idempotency Protocol**:
   - Store incoming idempotency keys in Redis or PostgreSQL with an atomic lock and a 24-hour TTL.
   - If the key is currently processing, return `409 Conflict` or queue.
   - Once completed, cache the HTTP status code and response payload against the key.
   - When a duplicate request arrives with the same key, return the cached response immediately without re-executing the business action.

---

### 5. Type Generation and Single Source of Truth
Avoid writing separate, unlinked TypeScript interfaces on the frontend and backend:
- **Option A (Fullstack TypeScript / tRPC)**:
  - Export backend routers directly; frontend imports inferred types with zero generation step.
- **Option B (Next.js Server Actions with Zod)**:
  - Define Zod action input and output schemas in a shared library file; use `z.infer` on both client and server.
- **Option C (REST / OpenAPI)**:
  - Decorate routes or schemas to produce an OpenAPI 3.1 specification.
  - Run code generators (`openapi-typescript`, `orval`) to generate typed fetch clients automatically during CI.

---

## Workflow Steps

### Step 1: Define API Objectives and Endpoint Contracts
1. Determine HTTP method, URL pattern, and authentication requirement.
2. Draft request parameters (Path, Query, and Body) with strict Zod schemas.

### Step 2: Define Success Responses and Pagination
1. Formulate the success payload structure.
2. If returning a list, select cursor or offset pagination and specify page metadata.

### Step 3: Map the Complete Error Code Catalog
1. Enumerate every expected failure condition (unauthorized, not found, rate limited, business invariant violated).
2. Assign each failure a unique uppercase `ERROR_CODE` and corresponding HTTP status code.

### Step 4: Specify Idempotency and Rate-Limiting Constraints
1. Determine whether mutation requires an `Idempotency-Key` header.
2. Set rate-limit window and maximum allowed requests.

### Step 5: Generate API Specification Artifact
1. Use `.promptkit/templates/api-contract-spec.md`.
2. Save specification to `./docs/api/YYYY-MM-DD-api-<endpoint-name>.md`.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Risk | Remedy |
| :--- | :--- | :--- |
| **Parsing Error Message Strings** | UI breaks when human error copy is revised. | Always provide machine-readable `error.code` identifiers. |
| **200 OK for Errors** | Bypasses HTTP caching, load balancer monitoring, and client error interceptors. | Return accurate 4xx and 5xx status codes. |
| **Naive Offset Pagination** | Data drift and skipped rows during dynamic collection updates. | Use cursor-based pagination for high-velocity collections. |
| **Missing Mutation Idempotency** | Double charges or duplicate emails during network retries. | Require and enforce `Idempotency-Key` headers on mutations. |
| **Hand-Maintained Client Types** | Frontend and backend types drift out of sync silently. | Generate types automatically from Zod schemas or OpenAPI specs. |

---

## Completion Criteria
- Comprehensive API contract generated in `./docs/api/`.
- Strict request and response Zod schemas documented.
- Complete machine-readable error dictionary established.
- Pagination model, idempotency rules, and rate limits defined.
