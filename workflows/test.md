# Test Workflow (Testing Strategy, Seam Allocation & Flake Prevention)

## Fast Shorthand
Trigger anytime with: `pk:test` (or `/pk-test`)

## Mission
Guide the developer through designing a comprehensive, cost-effective testing strategy before or during feature development.

Move away from brittle mocks and slow, flaky test suites toward disciplined seam allocation, real-database integration testing, modular test data factories, and deterministic contract verification.

---

## Preconditions
- Developer is planning test coverage for a new feature, refactor, or critical subsystem.
- Target storage directory: `./docs/tests/` in the host project.
- Access to `.promptkit/templates/test-plan-template.md`.

---

## Core Testing Strategy Pillars

### 1. The Modern Testing Pyramid and Seam Allocation
Allocate test effort where it provides the highest confidence per execution millisecond:

```
         ▲
        / \        E2E Tests (Playwright)
       /   \       Top 5-10 critical user flows; real browser.
      /─────\
     /       \     Integration Tests (Vitest / Jest + Real DB)
    /         \    API routes, DB queries, RLS policies, external mocks.
   /───────────\
  /             \  Unit Tests (Vitest / Jest / Pytest)
 /               \ Pure domain logic, state reducers, transforms (<1ms).
─────────────────
```

1. **Unit Tests (Fast, In-Memory, High Density)**:
   - Target: Pure functions, financial/tax math, state reducers, validation parsers, and string algorithms.
   - Constraint: Zero network, filesystem, or database I/O. Must execute in sub-milliseconds.
2. **Integration Tests (The Highest Leverage Seam)**:
   - Target: API route handlers, repository queries, service boundaries, and multi-tenant RLS checks.
   - **Mandatory Real Database**: Run integration tests against a real PostgreSQL instance (via Docker, Testcontainers, or Supabase Local CLI). Never use in-memory SQLite for PostgreSQL code; SQLite ignores row locks, handles JSONB differently, and lacks Row-Level Security.
3. **End-to-End Tests (Lean, High Value)**:
   - Target: The top 5 to 10 golden user journeys (for example: Registration $\rightarrow$ Team Invite $\rightarrow$ Checkout).
   - Constraint: Do not write E2E tests for minor edge cases or input validations; test those in unit or integration suites.

---

### 2. Mocking Boundaries: "Don't Mock What You Own"
Mocking the wrong boundaries creates tests that pass in CI while crashing in production.

- **What You Must NOT Mock**:
  - Do not mock your database, ORM (Prisma, Drizzle), or internal repository classes. If you mock the ORM, your test asserts only that your mock returns what you told it to return, not that your SQL is valid.
- **What You MUST Mock**:
  - External third-party APIs and paid networks outside your process boundary: Stripe, Twilio, SendGrid, AWS S3, OpenAI.
- **How to Mock Externals**:
  - Use **Mock Service Worker (MSW)** at the network level, or encapsulate third-party clients behind typed adapter interfaces and inject in-memory fake adapters during tests.

---

### 3. Test Data Strategy: Modular Factories over Shared Seeds
Shared global seed files (`seed.sql`) create invisible dependencies across tests: editing a user record in seed data to satisfy Test A silently breaks Test B.

1. **Modular Test Data Factories**:
   - Define small factory functions that return valid entities with sensible defaults, allowing individual tests to override only what is load-bearing:
     ```typescript
     // test/factories/user.factory.ts
     export function buildUser(overrides: Partial<User> = {}): User {
       const id = crypto.randomUUID();
       return {
         id,
         email: `user-${id.slice(0, 8)}@example.com`,
         name: 'Test User',
         role: 'MEMBER',
         createdAt: new Date(),
         ...overrides,
       };
     }
     ```
2. **Deterministic Test Isolation**:
   - Ensure every test runs in isolation:
     - **Option A (Tenant Isolation)**: Generate a unique `workspaceId` per test suite so concurrent tests never collide on the same rows.
     - **Option B (Transaction Rollback)**: Wrap each test in a database transaction that rolls back at completion.

---

### 4. Contract Testing
Prevent frontend and backend drift:
- Share TypeScript validation schemas (Zod) between frontend API client hooks and backend route handlers.
- Write automated schema tests verifying that mock server fixtures parse cleanly against client-side response schemas.

---

### 5. Flake Prevention and Determinism
- **Never Use Arbitrary Timeouts**:
  - Replace `await sleep(1000)` with deterministic condition waiting:
    ```typescript
    // BAD
    await new Promise(r => setTimeout(r, 2000));
    expect(button).toBeEnabled();

    // GOOD
    await expect(button).toBeEnabled({ timeout: 3000 });
    ```
- **Freeze Time for Time-Sensitive Tests**:
  - When testing expiration, TTLs, or billing cycles, use fake timers (`vi.useFakeTimers()`) and advance time deterministically (`vi.advanceTimersByTime(86400000)`).
- **Seed Randomness**:
  - If generating randomized fuzz inputs, log the seed so failed runs can be reproduced deterministically.

---

### 6. Monorepo Seam Allocation & Filtered Execution
In multi-package monorepos (Turborepo, pnpm workspaces, Nx), running full test suites at the root for every code change destroys developer iteration speed and overwhelms context windows:

1. **Scoped Package Execution (`--filter`)**:
   - Always run tests targeted to the impacted package:
     - **Turborepo**: `turbo run test --filter=@repo/package...` (runs the package and its internal dependencies)
     - **pnpm workspaces**: `pnpm --filter @repo/package test`
     - **Nx**: `nx test <project-name>`
2. **Shared Package vs Application Boundary**:
   - When modifying a shared library (`packages/db`, `packages/ui`):
     - First, run the shared package's own isolated unit/integration tests.
     - Second, run downstream consumer tests to detect contract regressions:
       - Turborepo: `turbo run test --filter=...@repo/db` (tests `@repo/db` and all packages that depend on it).
       - pnpm: `pnpm --filter ...@repo/db test`.
3. **Zero Leaked Environment Variables Across Workspaces**:
   - Never assume `.env` in `apps/web` is available inside `packages/db`. Each package must source its own test environment configuration explicitly.

---

## TDD Intent and Task Record Boundary

`pk:test` owns test strategy and the TDD intent register inside the existing `docs/tests/<test-plan>.md` artifact. It does not activate TDD, set execution state, or replace the Local Task Record. The test plan may propose or reference `TDD Enforcement Mode: disabled | enabled`; the canonical Task Record owns the actual mode, and an absent Task Record field defaults to `disabled`.

The test plan is a supporting intent view. It records the expected behavior and Red evidence before implementation, while the Local Task Record records Red, Green, and Refactor execution results and controls readiness or completion.

### Enabled Code Work Intent Contract

For each enabled Code Work behavior, record all of the following before the intent becomes `ready`:

- `BEHAVIOR-<task-slug>-<nnn>` stable behavior identity;
- `TDD-INTENT-<task-slug>-<nnn>` intent identity;
- the linked canonical Local Task Record;
- the observable test and expected failing assertion;
- the exact runnable Red command; and
- intent state `proposed | ready | superseded`.

The same Behavior ID must be used by the Task Record's `TDD-EXEC-<task-slug>-<behavior-seq>` evidence through Red, Green, and Refactor. Green and Refactor rerun the same Red command and retain the expected behavior without silently changing the acceptance condition.

### Disabled Code Work and Exception Verification

- **Disabled Code Work:** Record `N/A - TDD Enforcement Mode disabled` for the complete intent register and the Task Record's TDD execution evidence. Keep normal dependency-ordered milestones, acceptance criteria, test strategy, review, and verification; disabled Code Work is not an exception path.
- **Documentation, Configuration, or Research Work:** Do not create TDD intent rows. Record `N/A - <reason>` and link an explicit exception verification task with acceptance, evidence, review, and verification.
- **Ambiguous Work:** Follow the Code Work path until Work Type and TDD mode are clarified. Do not grant an automatic TDD exception.

A disagreement between the test plan, Planning Record, and Task Record blocks readiness until reconciled. After reconciliation, the Task Record value controls. `pk:test` preserves the existing test-pyramid, seam, framework, runner, factory, and flake-prevention ownership.

---

## Workflow Steps

### Step 1: Analyze Feature Risk and Surface Area
1. Identify the core user journey, critical business invariants, and external integrations.
2. Determine where defects would cause data loss, financial impact, or security breach.

### Step 2: Map Test Seams
1. Allocate scenarios across the pyramid:
   - What belongs in Unit? (pure algorithms, validation schemas)
   - What belongs in Integration? (database queries, RLS policies, multi-step services)
   - What belongs in E2E? (happy path browser flow)

### Step 2.5: The Ironclad TDD Assertion (Observe RED First)
> 🛑 **Mandatory TDD Law**: Never write implementation code against a hypothetical test failure.
1. **Write the Minimal Failing Test**: Construct a concise test asserting the desired public behavior or reproducing the defect.
2. **Execute and Observe RED**: Run the test suite before touching production source files. Confirm:
   - The test fails with the expected assertion error (not a compilation error or missing import).
   - The failure confirms the defect or missing functionality exists.
3. **Write Minimal Implementation (GREEN)**: Write only enough production code to turn the failing test green.
4. **Refactor Cleanly (REFACTOR)**: Clean up duplication, enforce design patterns, and ensure all tests stay green.

### Step 3: Define External Mock Boundaries
1. Identify all third-party dependencies (Stripe, email, S3).
2. Specify MSW handlers or typed fake adapters for each external dependency.

### Step 4: Specify Test Data Factories
1. List required entities and build factory helper signatures.
2. Define boundary fixtures (empty sets, maximum payload sizes, expired tokens).

### Step 5: Establish CI Execution and Coverage Targets
1. Define test execution commands and parallelization strategy.
2. Establish coverage thresholds for core domain business logic.

### Step 6: Generate Test Plan Artifact
1. Use `.promptkit/templates/test-plan-template.md`.
2. Save specification to `./docs/tests/YYYY-MM-DD-test-<feature-name>.md`.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Consequence | Remedy |
| :--- | :--- | :--- |
| **Post-Hoc Tests (Code First)** | Tests mirror the bugs and assumptions of the implementation, producing false-positive passes. | Always write tests first and observe them fail (`RED`) before implementing code. |
| **Mocking the Database** | Tests pass while queries fail on syntax, nullability, or foreign keys in production. | Run integration tests against real PostgreSQL via Docker or Testcontainers. |
| **Monolithic Shared Seeds** | Modifying seed data to fix one test breaks dozens of unrelated tests. | Use modular factory functions (`buildUser()`) with per-test overrides. |
| **E2E Over-Testing** | 45-minute CI runs, frequent flaky timeouts, and developer frustration. | Restrict E2E tests to the top 5-10 golden user flows; test edge cases in integration suites. |
| **Arbitrary Sleep Delays** | Slow test execution and intermittent timing flakes under CI load. | Use polling assertions (`waitFor`, `expect(locator).toBeVisible()`). |
| **Testing Implementation Details** | Tests break on internal refactorings even when public behavior is unchanged. | Assert on public outputs, returned responses, and database state. |

---

## Completion Criteria
- Comprehensive test plan generated in `./docs/tests/`.
- Scenarios allocated across Unit, Integration, and E2E seams.
- Real-database harness configured for integration tests.
- External mock boundaries and test data factories documented.
- **Observable Red-to-Green**: Test failure confirmed and documented prior to writing production code for all active code work.
- **Project Database Isolation**: Test harnesses use project-scoped database containers (e.g. `./docker-compose.yml`) and never attach to foreign project instances.
- **Dual-Compatible Telemetry Status Card**: Conclude with a 3-line telemetry status card (`> 📊 **Milestone**: ... \n> 🎯 **Active**: ... \n> 🟢 **Quality Gate**: ...`) and a `> [!TIP]` callout recommending implementation of the red-to-green test suite. When multiple next steps exist, invoke native interactive selection tools (e.g. `ask_question`) as your final tool call with Option 1 `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`. If PROMPTKIT.md declares `status-cards: off`, skip the decorative card; `[!IMPORTANT]` / `[!WARNING]` halts still fire. Bounded to closed-set operational choices: for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead — see the Picker routing rule in `workflows/plan.md`.
