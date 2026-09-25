# Task Record: Recipe Workflow Wiring, Contract-Test Gating, and Recipe Index

<a id="TASK-2026-09-25-recipe-wiring-and-gates"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-25-recipe-wiring-and-gates`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub Issue #393 — Wire 3 orphaned recipes, gate recipes in contract-test twins, add index + prioritized gap recipes`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/393`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-25 04:30 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Wire all orphaned recipes (auth-session.md, env-validation.md, form-mutations.md, test-isolation.md, webhook-idempotency.md) into owning workflows, extend contract test twins to validate category: recipe schema with a strict <= 1,500 token ceiling, add docs/recipes/README.md catalog index and intake criteria, and assert behavioral contracts with 100% twin parity.`
- **In Scope**:
  - `scripts/validate-playbooks.sh`
  - `scripts/validate-playbooks.ps1`
  - `scripts/tests/run-playbook-contract-tests.sh`
  - `scripts/tests/run-playbook-contract-tests.ps1`
  - `docs/recipes/README.md`
  - `workflows/auth.md`
  - `workflows/debug.md`
  - `workflows/onboard.md`
  - `workflows/api.md`
  - `workflows/test.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-25-recipe-wiring-and-gates.md`
- **Explicit Non-Goals**:
  - `Modifying templates/agent-directive-template.md or Lite directive (headroom preserved).`
  - `Inlining or duplicating full recipe content into workflows (single-line links only).`
  - `Adding CMS playbooks (scheduled as part of Issue #392 roadmap).`
  - `Changing stack playbook manifest schemas.`
- **Dependencies**: `Issue #393 and operator approval`
- **Risk**: `Low — documentation, validation scripts, and behavioral contract tests only; zero directive bloat.`
- **Verification Condition**: `Dual contract test twins, dual behavioral contract test twins, strict token gates, reference validation, and execution control validation all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: `scripts/validate-playbooks.sh` and `validate-playbooks.ps1` validate `category: recipe` frontmatter (`name`, `category: recipe`, `version`, `token_budget: <= 1500`, `description`), enforce token budget ceiling $\le 1,500$ tokens, include recipe self-test fixtures, and skip `README.md`.
  - **Result**: `Pass`
  - **Evidence**: `Dual playbook contract self-tests pass; all 8 recipes validate cleanly`
- [x] **AC-2**: `scripts/tests/run-playbook-contract-tests.sh` and `.ps1` validate all recipes in `docs/recipes` alongside `docs/stacks` with 100% twin parity.
  - **Result**: `Pass`
  - **Evidence**: `run-playbook-contract-tests.sh and .ps1 validate 11 stacks and 8 recipes with 0 failures`
- [x] **AC-3**: All orphaned recipes (`auth-session.md`, `env-validation.md`, `form-mutations.md`, `webhook-idempotency.md`, `test-isolation.md`) are wired into owning workflows (`workflows/auth.md`, `workflows/debug.md`, `workflows/onboard.md`, `workflows/api.md`, `workflows/test.md`) via single-line links.
  - **Result**: `Pass`
  - **Evidence**: `validate-references.sh and .ps1 pass with 0 broken links; Scenario AA verifies wiring`
- [x] **AC-4**: `docs/recipes/README.md` provides an index catalog matrix of all 8 recipes, architectural intake criteria (rule vs playbook vs recipe), token ceiling rules, and prioritized gap candidate roadmap.
  - **Result**: `Pass`
  - **Evidence**: `docs/recipes/README.md created with catalog table, intake rules, and gap roadmap`
- [x] **AC-5**: Behavioral contract test twins (`run-behavioral-contract-tests.sh` and `.ps1`) include Scenario AA validating recipe schema, index, and workflow wiring.
  - **Result**: `Pass`
  - **Evidence**: `Scenario AA passes in run-behavioral-contract-tests twins (271 passed / 0 failed)`

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `Session boundary or ~30 turns`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `State that live host timing or forced termination is unavailable or limited.`

## 5. State and Active Ownership

- **Execution State**: `ready`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-25 04:30 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/issue-393-recipe-wiring-and-gates`
- **Next Action**: `Human PR review and merge decision on the #393 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-25 04:30 UTC | Implementor agent | Record created for Issue #393 Controlled Work | Issue #393 |
| planned | ready | 2026-09-25 04:45 UTC | Implementor agent | Readiness complete; scope bounded and verified | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/validate-playbooks.sh` — added recipe validation, <= 1500 token check, self-test fixtures, and README skipping
  - `scripts/validate-playbooks.ps1` — added recipe validation, <= 1500 token check, self-test fixtures, and README skipping (twin parity)
  - `scripts/tests/run-playbook-contract-tests.sh` — added `docs/recipes` test execution
  - `scripts/tests/run-playbook-contract-tests.ps1` — added `docs/recipes` test execution (twin parity)
  - `docs/recipes/README.md` — catalog matrix, intake criteria, token rules, gap roadmap
  - `workflows/auth.md` — wired `docs/recipes/auth-session.md`
  - `workflows/debug.md` — wired `docs/recipes/env-validation.md`
  - `workflows/onboard.md` — wired `docs/recipes/env-validation.md`
  - `workflows/api.md` — wired `docs/recipes/form-mutations.md` and `docs/recipes/webhook-idempotency.md`
  - `workflows/test.md` — wired `docs/recipes/test-isolation.md`
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario AA assertions
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario AA assertions (twin parity)
  - `docs/tasks/TASK-2026-09-25-recipe-wiring-and-gates.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `run-playbook-contract-tests.sh` and `.ps1` -> 11 stacks + 8 recipes PASS; `validate-references.sh .` and `.ps1` -> all references valid; `measure-tokens.sh --strict` -> BALANCED 2254/2500 PASS, LITE 1146/1500 PASS; `measure-per-task-tokens.sh --strict` -> all baselines PASS; `run-behavioral-contract-tests.ps1` and `.sh` -> 271 passed / 0 failed (Scenario AA verified); `validate-execution-control.ps1 -Root . -Strict` -> VALID
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation/Protocol Work`
- **CI Evidence**: `pending - CI runs the .sh and .ps1 contract twins on push`
- **Review Evidence**: `pending`
- **Commit Evidence**: `pending`
- **Pull Request Evidence**: `pending`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `ready`
- **Acceptance Results**: `AC-1 through AC-5 Complete`
- **Changed-File Summary**: `13 files modified/created`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-25 04:45 UTC`
