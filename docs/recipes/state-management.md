---
name: state-management
category: recipe
version: 1
token_budget: 1500
description: Keep server data, URL state, and transient UI state in their proper ownership boundaries.
---
# State Management Recipe

State belongs to the narrowest owner that can preserve its lifecycle. Separate authoritative server data, navigable URL state, and ephemeral interface state.

## 1. Non-Negotiable Invariants

- Server data remains server-owned; cache keys include identity/tenant scope and invalidation follows successful mutations.
- Put shareable filters, pagination, and selection in the URL. Keep temporary dialogs, focus, and drag state local to a component.
- A client store is not a substitute for request-scoped server state or an authorization boundary.
- Reset identity-scoped caches on sign-out or tenant change; never reuse one user's cached data for another.

## 2. Implementation Patterns & Worked Examples

Classify each value before choosing storage: `query → URL`, `remote entity → server cache`, `temporary interaction → component`, `cross-route client preference → scoped store`. Use stable query keys such as `['projects', tenantId, filters]`; invalidate or replace that key after a mutation. Persist only deliberate preferences, version their schema, and exclude credentials and server responses.

## 3. Anti-Patterns to Avoid

- Copying fetched entities into multiple global stores creates stale competing sources of truth.
- Persisting an entire store can leak tenant data across account changes or resurrect obsolete state.
- Hiding filters only in component memory breaks reload, back-button, and shared-link behavior.
- Updating optimistic UI without rollback or reconciliation leaves false state after a failed mutation.
