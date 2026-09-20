# Senior Developer Pull Request Review Checklist

Use this checklist during PR reviews and self-audits to ensure the highest standard of engineering rigor across both **Spec Fidelity** and **Technical Standards**.

---

## 1. Spec Fidelity & Scope Control
- [ ] **Requirements Complete**: Does the change implement all functional requirements and acceptance criteria from the spec or issue?
- [ ] **No Scope Creep**: Are all changes directly relevant to the issue/feature without speculative hooks, unrequested refactorings, or unrelated tweaks?
- [ ] **Contract Integrity**: Are API routes, response schemas, and domain event payloads compliant with published specs?
- [ ] **Edge Cases Handled**: Are empty states, zero-length arrays, network timeouts, and unauthorized states handled gracefully?

## 2. Accidental Data Loss Prevention (Zero-Destruction Gate)
- [ ] **No Irreversible Schema Drops**: Are database migrations free from destructive `DROP TABLE`, `DROP COLUMN`, or `TRUNCATE` operations?
- [ ] **Expand-Contract Pattern** (when live or compatibility-sensitive data exists; otherwise `N/A - <reason>` — one-shot, disposable, or pre-deployment changes may skip with documented rationale): Are column or table renames performed in multi-phase backward-compatible deployments?
- [ ] **Bounded Deletions**: Are SQL `DELETE` or ORM delete queries strictly bounded with `WHERE` conditions?
- [ ] **Safe Storage Operations**: Are file deletions or cloud bucket mutations guarded with soft-delete flags or explicit backup guarantees?

## 3. Architectural & Domain Design
- [ ] **Single Responsibility**: Does each class, module, function, or component do exactly one thing well?
- [ ] **Layered Separation**: Is business logic strictly separated from UI rendering and database access?
- [ ] **Domain Boundaries**: Are models, entities, and value objects properly encapsulated?
- [ ] **Extensibility vs YAGNI**: Is the solution simple enough for current requirements without unnecessary speculative abstractions?

## 4. Code Smell Baseline (Martin Fowler Heuristics)
- [ ] **No Mysterious Names**: Are all variable, function, and component names self-documenting and intent-revealing?
- [ ] **No Duplicated Code**: Is identical or near-identical logic extracted into reusable functions or hooks?
- [ ] **No Feature Envy**: Do methods live on the objects whose data they manipulate most?
- [ ] **No Data Clumps**: Are groups of 3+ parameters that travel together bundled into dedicated types/interfaces?
- [ ] **No Primitive Obsession**: Are domain concepts (IDs, currencies, statuses) modeled with branded or enum types?
- [ ] **No Repeated Switches**: Are recurring `switch` or `if/else` ladders replaced with polymorphic maps or strategy patterns?
- [ ] **No Shotgun Surgery / Divergent Change**: Are cohesive concepts grouped together so a single change doesn't require editing 10 unrelated files?

## 5. Type Safety & Schema Contracts
- [ ] **No `any` or Loose Casts**: Are types strictly declared without unsafe `as` assertions?
- [ ] **Runtime Validation** (when external inputs exist; otherwise `N/A - <reason>`): Are all external inputs (API params, webhooks, query strings, localStorage) validated using the project's native mechanism (e.g., Zod/Valibot for TypeScript)?
- [ ] **Discriminated Unions**: Are asynchronous or multi-variant states modeled with tagged unions?
- [ ] **Immutability**: Are state mutations pure and immutable?

## 6. Concurrency, Async & Error Resilience
- [ ] **Race Condition Prevention**: Are rapid asynchronous events, network fetches, and user clicks debounced, throttled, or protected by abort signals (`AbortController`)?
- [ ] **Resource Cleanup**: Are intervals, event listeners, streams, and WebSocket connections reliably torn down in unmount/finally blocks?
- [ ] **Graceful Degradation**: If an external dependency fails, does the user receive a helpful error message instead of a blank screen or crashed app?
- [ ] **Transaction Atomicity**: Are multiple database writes wrapped in atomic transactions?

## 7. Security Hygiene & Defense-in-Depth (OWASP)
- [ ] **Authentication & Authorization**: Is every endpoint protected by explicit user session and permission checks?
- [ ] **Injection Prevention**: Are all database queries parameterized (no raw template literal SQL)?
- [ ] **Data Sanitization**: Is HTML/Markdown rendered safely against XSS attacks?
- [ ] **Secrets & PII Hygiene**: Are sensitive fields (passwords, tokens, emails, phone numbers) excluded from public client payloads and logs?

## 8. Performance & Resource Efficiency
- [ ] **Database & Query Indexing** (when DB queries exist; otherwise `N/A - <reason>`): Are all foreign keys and frequently filtered columns indexed? Are N+1 query patterns eliminated?
- [ ] **Frontend Rendering**: Are expensive calculations memoized? Does the component re-render only when its specific props change?
- [ ] **Bundle Size & Asset Optimization**: Are large third-party libraries dynamic-imported / code-split? Are images optimized and sized?

## 9. Accessibility (a11y) & UX Integrity
- [ ] **Semantic Markup**: Are standard HTML tags used for buttons, navigation, headings, and dialogs?
- [ ] **Keyboard Navigability**: Can every action be triggered via keyboard (Tab, Enter, Space, Escape, Arrows)?
- [ ] **Contrast & Focus**: Do focus rings stand out clearly? Does text meet WCAG 2.2 AA contrast ratios?
- [ ] **Screen Reader Support**: Do icons and buttons have accessible labels (`aria-label`, `sr-only`)?

## 10. Testing & Observability
- [ ] **Correct Seams**: Do tests exercise real behavior at the call site rather than mocking out the core defect?
- [ ] **Edge-Case Coverage**: Do tests verify boundary conditions, error responses, and invalid inputs?
- [ ] **Behavioral Tests**: Do tests assert observable behavior rather than private implementation details?
- [ ] **Clean Instrumentation**: Are all temporary debug logs (`[DEBUG-xxxx]`) removed before merge?
