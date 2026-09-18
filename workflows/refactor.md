# Structural Refactoring & Code Modernization Workflow

## Fast Shorthand
Trigger anytime with: `pk:refactor` (or `/pk-refactor`)

## Mission
Guide the developer and AI assistant through systematic, safe structural code refactoring, technical debt elimination, and architectural modernization **without altering observable runtime behavior**.

Eliminate the "Broken Rewrite Spiral" where unstructured AI refactoring breaks dependencies across multiple files, introduces regressions, and gets lost in compilation errors. Enforce strict behavioral pinning (Golden Master / Characterization testing), dependency-ordered transformation (The Mikado Method), non-destructive parallel migration (Strangler Fig), and rigorous zero-diff output verification.

---

## The Core Invariant: Behavioral Equivalence
Refactoring changes the **internal structure** of software without changing its **external observable behavior**. 

> [!CAUTION]
> **No Opportunistic Bug Fixes or Feature Creep**:
> If you discover a bug while refactoring, do NOT fix it opportunistically. Document it, complete or revert the current refactoring step, and route the bug separately to `pk:fix` or `pk:debug`. If you are adding a feature, complete the refactoring first to prepare the seam, commit cleanly, and route the feature to `pk:plan`.

---

## Level 0–3 Task Ceremony Alignment

- **Level 1 — Localized Refactor (Standard)**: Self-contained module or function cleanup, extracting helpers, or removing local duplication without touching public interfaces, database schemas, or authentication boundaries. Does **not** require a Task Record file (`docs/tasks/<task-id>.md`).
- **Level 2 — Architectural Refactor (Controlled)**: Cross-module decoupling, migrating to Clean/Hexagonal Architecture (Ports and Adapters), public API contract changes, or schema alterations. Requires an explicit RFC spec (`pk:plan`) and a canonical Task Record in `docs/tasks/`.
- **Level 3 — Release-Critical Refactor**: Core engine rewrite touching multi-tenant isolation, billing, or encryption. Requires Level 2 evidence plus dual-lens review (`pk:review`) and explicit human approval.

---

## The 4-Stage Refactoring Lifecycle

```text
┌─────────────────────────────────────────────────────────────┐
│                 PK:REFACTOR 4-STAGE LIFECYCLE               │
├─────────────────────────────────────────────────────────────┤
│ Stage 1: Invariant Pinning & Golden Master Snapshot         │
│          Capture existing behavior with characterization    │
│          tests before modifying a single line of code.      │
├─────────────────────────────────────────────────────────────┤
│ Stage 2: Seam Mapping & The Mikado Method                   │
│          Map prerequisite dependencies. If a change breaks  │
│          the build, REVERT immediately and fix the blocker. │
├─────────────────────────────────────────────────────────────┤
│ Stage 3: Strangler Fig Seam (Parallel Dual-Run)             │
│          Build the new implementation behind an interface   │
│          adapter alongside legacy code. Avoid big-bangs.    │
├─────────────────────────────────────────────────────────────┤
│ Stage 4: Zero-Diff Verification & Dead Code Elimination     │
│          Assert output parity against the Golden Master;    │
│          purge obsolete legacy code and transitional shims. │
└─────────────────────────────────────────────────────────────┘
```

---

## Workflow Steps

### Stage 1: Invariant Pinning & Golden Master Snapshot
Before touching application code, you must prove you can detect if behavior changes:

1. **Assess Existing Test Coverage**:
   - If reliable unit/integration tests already cover all branches of the target code, verify they pass (`pk:test`).
2. **Characterization Testing (Golden Master)**:
   - When refactoring legacy code with absent or brittle tests, construct a temporary **Characterization Test Harness**:
   - Pass 20–50 representative inputs (including edge cases, empty values, boundary numbers) through the legacy function.
   - Record the exact output results into a snapshot file or test fixture.
   - Assert that any future implementation produces identical outputs for the same inputs.

### Stage 2: Seam Mapping & The Mikado Method
Large refactorings fail when agents attempt to change everything at once. Use the **Mikado Method** to ensure every intermediate commit compiles and passes:

```text
       [Target Goal: Extract Clean Payment Gateway Interface]
                                 ▲
                ┌────────────────┴────────────────┐
                │                                 │
     [Prerequisite 1:                 [Prerequisite 2:
      Isolate Stripe SDK imports       Decouple Currency conversion
      from HTTP Controllers]           from Database Queries]
```

1. **Attempt the Immediate Transformation**: Try to extract the target function or interface.
2. **Detect Blockers**: If the compiler, linter, or test suite fails due to a downstream dependency:
   - **Do NOT continue editing other files in a broken state.**
   - **Revert Scoped, Never Blanket**: revert only the files this step modified (`git checkout -- <touched-paths>`). Check `git status -s` first — if unrelated uncommitted work is present, halt with `> [!WARNING] Blocked: Waiting on Human Input` instead of reverting.
   - Record the blocking dependency as a child prerequisite on your task list.
3. **Execute Prerequisites First**: Refactor the leaf prerequisite, verify all tests pass, and commit atomically (`pk:commit`).
4. **Retry the Target**: Return to the parent transformation now that the blocker has been cleanly separated. Bound the recursion: maximum 3 prerequisite levels per target and 2 retries of the same target — a third failure halts with `> [!WARNING] Blocked: Waiting on Human Input` and the Mikado graph recorded as evidence.

### Stage 3: Strangler Fig Seam (Parallel Implementation)
For multi-file or cross-module refactors, never execute a destructive "big-bang" overwrite:

1. **Define the Interface / Port**:
   - Create a clean abstraction (e.g. `interface OrderRepository` or `type PaymentAdapter`).
2. **Build the New Implementation in Parallel**:
   - Author the modernized, decoupled component in a separate file (e.g. `NewOrderService.ts`) alongside the legacy code.
3. **Introduce a Transitional Seam**:
   - Route traffic through an adapter or feature toggle:
     ```typescript
     export function getOrderService(): OrderService {
       return process.env.USE_NEW_ORDER_SERVICE === 'true'
         ? new ModernOrderService()
         : new LegacyOrderService();
     }
     ```
4. **Migrate Call Sites Incrementally**:
   - Update callers one at a time, keeping tests green at every step.

### Stage 4: Zero-Diff Verification & Dead Code Pruning
1. **Assert Behavioral Invariants**:
   - Run the Golden Master / Characterization suite against the refactored code.
   - Verify that output diff is strictly zero.
2. **Purge Transitional Infrastructure**:
   - Remove feature toggles, deprecation warnings, and transitional adapter shims.
   - Delete the legacy implementation files.
3. **Static Analysis & Typecheck**:
   - Run linter and typechecker (`tsc --noEmit`, `mypy`, `cargo check`) to ensure no orphan exports or unused variables remain.
4. **Commit Atomically**:
   - Stage changes via `pk:commit` with conventional prefix `refactor(<scope>): ...`.

---

## Code Simplification Pass (Clarity Over Cleverness)

AI coding agents have a natural bias toward generative bloat: constructing single-use wrapper classes, over-engineered abstract interfaces, redundant converter utilities, and nested functional gymnastics. 

The **Code Simplification Pass** is a mandatory deflation review executed before declaring a refactoring complete:

### 1. The 5 Deflation Heuristics
1. **Flatten Indirection**: If a function or method only forwards arguments to another 1-line function with identical parameters, inline it. Do not keep pass-through wrappers that obscure control flow.
2. **Eliminate Premature Abstractions**: If an `interface` or `abstract class` has only a single concrete implementation and no polymorphism or test mock boundary is required, collapse it into a direct class or plain function (YAGNI).
3. **Linearize Control Flow**: Replace deeply nested conditional pyramids and nested ternary soup with early returns (guard clauses). Code should read top-to-bottom with happy paths un-indented.
4. **Delete Speculative Helpers**: Remove unused generic utility functions, "future-proof" parameter options, and uncalled helper methods. If an abstraction has zero callers in the active codebase, delete it.
5. **Prefer Standard Library Over Custom Wrappers**: Replace custom array/object manipulation gymnastics with modern built-in primitives (`Array.prototype.flatMap`, `Object.groupBy`, `structuredClone`, etc.).

### 2. Simplification Invariant
- **Zero Behavior Change**: Simplification is a pure refactor. Never alter external API contracts, error statuses, or observable side effects while deflating code.

---

## Martin Fowler Code Smell Remediation Catalog

| Code Smell | Architectural Indicator | Refactoring Remedy |
| :--- | :--- | :--- |
| **Divergent Change** | One class is commonly modified in different ways for different reasons. | Apply **Extract Class / Module** to separate distinct domain responsibilities. |
| **Shotgun Surgery** | A single change forces small edits across dozens of scattered files. | Apply **Move Method / Move Field** to consolidate related logic into a single cohesive module. |
| **Feature Envy** | A method spends more time accessing data from another object than its own. | Move the method to the class that owns the data, or extract an intermediate domain service. |
| **Long Parameter List** | Functions taking 5+ individual parameters. | Introduce a **Parameter Object** or strongly-typed configuration interface. |
| **Primitive Obsession** | Using raw strings/numbers for domain concepts (e.g. raw string for ZipCode, Currency, or Email). | Replace with lightweight **Value Objects** with encapsulated runtime validation. |
| **Speculative Generality** | Complex abstract classes and unused hook interfaces created "for future use". | Apply **Inline Class** and **Collapse Hierarchy** (YAGNI discipline). |

---

## Completion Checklist (Delivery Gate)

Before closing a `pk:refactor` task, verify:
- [ ] **Zero Functional Regressions**: All existing tests and Golden Master snapshots pass without modifications to test assertions.
- [ ] **Atomic Green Commits**: Every intermediate commit built and passed tests cleanly (Mikado compliance).
- [ ] **Code Simplification Enforced**: Flattened pass-through indirection, collapsed single-implementation abstractions, and linearized nested conditionals with guard clauses.
- [ ] **No Opportunistic Bug Fixes**: Any unrelated defects spotted were filed separately, not mixed into the refactoring diff.
- [ ] **No Dead Code**: Obsolete functions, unused imports, and transitional feature toggles have been completely removed.
- [ ] **Clean Lint & Typecheck**: Zero new linter warnings, zero loose `any` casts, and 100% typecheck pass.
