# Task Record: Restore ADR 0001 Static Token Headroom (Wave-2 Extraction)

<a id="TASK-2026-09-24-token-headroom-wave2"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-24-token-headroom-wave2`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `GitHub Issue #383 — Restore ADR 0001 static token headroom (wave-2 extraction)`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/383`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-24 23:05 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Restore static token headroom in the Balanced agent directive template (templates/agent-directive-template.md) per ADR 0001 by eliminating redundant trigger repetition and compacting artifact path listings.`
- **In Scope**:
  - `templates/agent-directive-template.md`
  - `docs/BENCHMARKS.md`
  - `docs/tasks/TASK-2026-09-24-token-headroom-wave2.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
- **Explicit Non-Goals**:
  - `Raising TOKEN_BUDGET_BALANCED constant (Option A rejected per ADR 0001).`
  - `Altering Lite directive (healthy at 1,146 / 1,500 tok).`
  - `Modifying workflow behaviors or adding new workflow files.`
- **Dependencies**: `Issue #383 and operator approval`
- **Risk**: `Low-to-Medium — public directive template; maintain exact behavioral contract assertions and dual-twin parity.`
- **Verification Condition**: `Strict token gates, behavioral contract test twins, per-task token gates, and reference validation all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: Balanced directive token count is measured at $\le 2,450$ tokens ($\ge 50$ tokens of headroom, targeting $\ge 150$ tok buffer per ADR 0001).
  - **Result**: `Pass (measured at 2,254 tok — 246 tokens of headroom)`
  - **Evidence**: `pwsh -NoProfile -File scripts/measure-tokens.ps1 -Strict`
- [x] **AC-2**: Behavioral contract assertions in Scenario P, R, S, T, and O remain green across both contract test twins.
  - **Result**: `Pass`
  - **Evidence**: `scripts/tests/run-behavioral-contract-tests.ps1 and .sh`
- [x] **AC-3**: Published benchmark figures in `docs/BENCHMARKS.md` reflect the exact live measured directive and per-task payload totals.
  - **Result**: `Pass`
  - **Evidence**: `Scenario P exact-match verification in contract test suite`
- [x] **AC-4**: Reference integrity check exits 0.
  - **Result**: `Pass`
  - **Evidence**: `bash scripts/validate-references.sh .`

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
- **Start Time**: `2026-09-24 23:05 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `refactor/issue-383-token-headroom`
- **Next Action**: `Human PR review and merge decision on the #383 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-24 23:05 UTC | Implementor agent | Record created for Issue #383 Controlled Work | Issue #383 |
| planned | ready | 2026-09-24 23:14 UTC | Implementor agent | Readiness complete; scope bounded and verified | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `templates/agent-directive-template.md` — streamlined Protocol Auto-Route bullet and compact Project Artifact Output Paths
  - `docs/BENCHMARKS.md` — synchronized live static directive and per-task payload measurements
  - `docs/tasks/TASK-2026-09-24-token-headroom-wave2.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `validate-references.sh .` → all references valid; `measure-tokens.sh --strict` → BALANCED 2254/2500 PASS (246 tok headroom), LITE 1146/1500 PASS; `measure-per-task-tokens.sh --strict` → all baselines PASS; `run-behavioral-contract-tests.ps1` and `.sh` → 244 passed / 0 failed; `validate-execution-control.sh --root . --strict` → VALID
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
- **Acceptance Results**: `AC-1 through AC-4 Complete`
- **Changed-File Summary**: `3 files modified/created`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-24 23:18 UTC`
