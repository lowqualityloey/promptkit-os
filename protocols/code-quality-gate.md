# Senior Code Quality Gate Protocol

## Purpose
Define the non-negotiable definition-of-done (DoD) and engineering quality bar for all code written, reviewed, or mentored within PromptKit OS. This protocol acts as a pre-flight checklist before any code is committed, submitted for PR, or marked complete.

---

## The 6 Pillars of Senior Code Quality

```
┌─────────────────────────────────────────────────────────────┐
│                  SENIOR CODE QUALITY GATE                   │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ 1. Type      │ 2. Testing   │ 3. Security  │ 4. Performance │
│    Safety    │    Pyramid   │    Hygiene   │    & Latency   │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ 5. Clean     │ 6. Accessi-  │ 7. Resilience│ 8. Observabi-  │
│    Arch & DX │    bility    │    & Errors  │    lity & Logs │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

---

## Pre-Commit Verification Checklist

### 1. Type Safety & Contract Integrity
- [ ] Zero `any` or loose casting without explicit type guards (`isType`) or Zod/Valibot schema validation.
- [ ] Discriminated unions used for polymorphic states (e.g., `Idle | Loading | Success<T> | Error<E>`).
- [ ] API responses and external inputs validated at boundary layers using runtime schemas.
- [ ] Immutable data structures favored (`readonly`, `as const`, immutable update patterns).

### 2. Testing Pyramid & Test Quality
- [ ] **Observable Red-to-Green Execution**: For new features and bug fixes, test failure (RED) with the expected assertion error was observed before writing production code.
- [ ] **Unit Tests**: Pure business logic, utilities, state reducers, and domain algorithms tested in isolation with 100% path coverage for edge cases (null, empty, boundary numbers, unexpected types).
- [ ] **Integration Tests**: Database queries, API handlers, service boundaries tested with realistic fixtures or testcontainers.
- [ ] **E2E / Component Tests**: Critical user flows and interaction states verified with tools like Playwright or React Testing Library (testing behavior, not implementation details).
- [ ] Tests are deterministic (no flaky time/race dependencies) and cleanly isolated.

### 3. Security Hygiene & Defense-in-Depth
- [ ] **Injection Prevention**: Parameterized queries / ORM bindings used; zero raw SQL or unescaped HTML string interpolation.
- [ ] **Authentication & Authorization**: Explicit RBAC / ABAC checks on every server endpoint / mutation.
- [ ] **Secrets & Sensitive Data**: Zero hardcoded API keys, tokens, or PII; environment variables validated at startup. Never ask the user to paste real secrets into chat.
- [ ] **Environment Template Hygiene (`.env.example`)**: Any feature requiring new environment variables must update or generate `.env.example` with sanitized placeholder keys, directing the human to populate their local untracked `.env`.
- [ ] **Input Sanitization & Rate Limiting**: All public endpoints bounded by rate limiters and payload size limits.
- [ ] **Zero Data Loss & Safe Migrations**: Database schema modifications follow the Expand-Contract pattern (no single-step destructive drops or truncates); all delete queries are strictly bounded.

### 4. Performance & Efficiency
- [ ] **Frontend**: Zero unnecessary re-renders; proper memoization (`useMemo`, `useCallback`, atomic selectors); images optimized (modern formats, responsive sizes); Core Web Vitals (LCP, INP, CLS) respected.
- [ ] **Backend**: N+1 query problems eliminated via eager loading or dataloaders; database queries indexed; expensive operations cached (Redis/Memory) with explicit TTLs.
- [ ] **Bundle & Memory**: Tree-shaking verified; event listeners, intervals, and WebSocket subscriptions cleaned up on teardown.

### 5. Clean Architecture & Maintainability
- [ ] **Separation of Concerns**: UI components are presentation-focused; business logic resides in hooks/services/domain entities; data fetching resides in query hooks or repository adapters.
- [ ] **DRY vs. WET**: Duplication abstracted only when domain semantics match; premature abstractions avoided.
- [ ] **Self-Documenting Code**: Clear, intent-revealing naming for variables and functions. Comments explain *why*, not *what*.

### 6. Accessibility (a11y) & UX Standards
- [ ] Semantic HTML tags used (`<main>`, `<nav>`, `<article>`, `<button>`, `<dialog>`).
- [ ] Full keyboard navigability (focus states visible via `focus-visible`, tab traps avoided, escape keys handled).
- [ ] ARIA attributes applied accurately according to WAI-ARIA 1.2 patterns (Radix/Aria primitives preferred).
- [ ] Color contrast meets WCAG 2.2 Level AA (minimum 4.5:1 for normal text).
- [ ] **Mandatory 8-State Component Contract**: All interactive elements (buttons, inputs, selects, toggles) explicitly implement `default`, `hover`, `:focus-visible`, `:active`, `disabled`, `loading`, `error`, and `success`.
- [ ] **Honest Copy & Data Integrity**: Zero hallucinated marketing claims, fake customer counts ("Join 100,000+ engineers"), synthetic logos, or generic AI buzzwords in user-facing UI.
- [ ] **Unified Icon Family**: Icons drawn from a single cohesive family (Iconify catalog, Lucide/Tabler/Heroicons); `simple-icons` used strictly for brand logos; no mismatched weights.


### 7. Resilience & Error Handling
- [ ] Errors handled gracefully with informative user feedback, not silent failures or cryptic crashes.
- [ ] Network requests and async tasks protected by timeout abort controllers and retry policies with jittered backoff.
- [ ] Error boundaries in place to catch runtime UI failures without crashing the entire app.

### 8. Observability & Telemetry
- [ ] Structured logging used (contextual JSON logs with correlation IDs, not raw `console.log`).
- [ ] Clean instrumentation: All temporary debug probes (`[DEBUG-xxxx]`) verified removed (`git grep "DEBUG-"`).
- [ ] Metrics or audit events dispatched for critical business actions (e.g., checkout, role change, data export).

---

## Protocol Execution in Pair-Programming
Before completing any coding task or finishing a PromptKit OS session:
1a. Pull optional diagnostics evidence (read-only, when `./PROMPTKIT.md` Section 5a enables LSP): capture `tsc --noEmit --pretty false` / `biome check --json` / `eslint --format json` locations for the review report. Never auto-fix; record `not measured` when unavailable.
1b. Run mandatory static verification (blocking): `tsc --noEmit`, `eslint`, `biome check`, or commands in `./PROMPTKIT.md`. The task is not done until these pass.
2. Run test suites (`npm test`, `pytest`, `cargo test`, or commands in `./PROMPTKIT.md`).
3. Verify all scenario acceptance criteria (`AC-*`) are completely met with concrete test evidence.
4. Audit against the 6 pillars checklist above.
5. If any gate fails, address it before declaring the task done.
6. When ready to stage and commit, invoke `workflows/commit.md` (`pk:commit`) to ensure atomic single-concern staging, Conventional Commit formatting, and secret leak prevention.
7. Prepare the pull request with `workflows/pr.md` (`pk:pr`), compiling the verified AC checklist for human review and merge. Before `gh pr create`: `git status -s` clean for this task, `git fetch origin` + rebase check against base, and `Quality Gate: measured this turn`. No auto-push.
8. **Milestone Git Boundary & Working Tree Verification**: A **milestone boundary** is the turn after a `pk:plan`/`pk:tasks` milestone or a Task Record closes. At milestone conclusion, verify working tree status with `git status`: all changes produced **by the current task** must be cleanly committed via `pk:commit` and synchronized to `docs/STATE.md` before beginning the next milestone. Files that were already untracked/dirty **before the task started** (including fresh `init.sh` scaffold output) are a documented exception: surface them to the developer and recommend `pk:commit` or ignores — do not stall the session on dirt you did not create.

