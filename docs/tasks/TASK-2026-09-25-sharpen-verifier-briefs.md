# Task Record: Sharpen Subagent Verifier and Reviewer Briefs

<a id="TASK-2026-09-25-sharpen-verifier-briefs"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-25-sharpen-verifier-briefs`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub Issue #390 — Sharpen subagent reviewer & verifier briefs across review, debug, ship`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/390`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-25 05:32 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Extend subagent reviewer and verifier briefs with explicit claims-audit duties, adversarial passes for L2+ fixes, pre-release evidence audits, and trigger-based security review constraints without adding standing token cost or modifying frozen directives.`
- **In Scope**:
  - `protocols/subagent-delegation.md`
  - `workflows/review.md`
  - `workflows/debug.md`
  - `workflows/ship.md`
  - `docs/BENCHMARKS.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-25-sharpen-verifier-briefs.md`
- **Explicit Non-Goals**:
  - `Modifying templates/agent-directive-template.md or Lite directive (headroom preserved).`
  - `Adding standing third reviewers or increasing subagent counts.`
  - `Changing L0/L1 bypass rules or creating approval/merge/release authority in review reports.`
  - `Adding recursive subagent delegation loops.`
- **Dependencies**: `Issue #390 and operator approval`
- **Risk**: `Low — documentation and behavioral contract assertions only; zero directive bloat.`
- **Verification Condition**: `Dual behavioral contract test twins, strict token gates, reference validation, and execution control validation all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: `protocols/subagent-delegation.md` explicitly requires re-verifying task-record and PR-body claims against the diff and exit codes for Patterns B and C.
  - **Result**: `Pass`
  - **Evidence**: `Scenario Z in run-behavioral-contract-tests twins`
- [x] **AC-2**: `workflows/review.md` inherits the claims-audit duty in dual-axis delegation, defines the trigger-based security-lens third reviewer, and creates no approval or merge authority.
  - **Result**: `Pass`
  - **Evidence**: `Scenario Z in run-behavioral-contract-tests twins`
- [x] **AC-3**: `workflows/debug.md` mandates an adversarial pass attempting to break the fix for Level 2+ work while keeping Level 0 and Level 1 bypassed.
  - **Result**: `Pass`
  - **Evidence**: `Scenario Z in run-behavioral-contract-tests twins`
- [x] **AC-4**: `workflows/ship.md` requires a Pattern C evidence audit verifying checklist claims (unexecuted tag proposals, resolved links, rollback records) before Release Coordinator review.
  - **Result**: `Pass`
  - **Evidence**: `Scenario Z in run-behavioral-contract-tests twins`
- [x] **AC-5**: Contract assertions are mirrored with twin parity across `.sh` and `.ps1` test suites with token budgets preserved.
  - **Result**: `Pass`
  - **Evidence**: `Both contract test twins pass with Scenario Z assertions`

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
- **Start Time**: `2026-09-25 05:32 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/issue-390-sharpen-verifier-briefs`
- **Next Action**: `Human PR review and merge decision on the #390 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-25 05:32 UTC | Implementor agent | Record created for Issue #390 Controlled Work | Issue #390 |
| planned | ready | 2026-09-25 05:34 UTC | Implementor agent | Readiness complete; scope bounded and verified | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `protocols/subagent-delegation.md` — added claims-audit duty to Patterns B and C
  - `workflows/review.md` — inherited claims-audit duty and documented trigger-based security reviewer
  - `workflows/debug.md` — added adversarial pass for L2+ fixes with L0/L1 bypass
  - `workflows/ship.md` — added Pattern C release evidence audit before coordinator review
  - `docs/BENCHMARKS.md` — updated pk:ship measured payload and reduction label to match tool output
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario Z assertions
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario Z assertions (twin parity)
  - `docs/tasks/TASK-2026-09-25-sharpen-verifier-briefs.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `validate-references.sh .` -> all references valid; `measure-tokens.sh --strict` -> BALANCED 2254/2500 PASS (246 tok headroom), LITE 1146/1500 PASS; `measure-per-task-tokens.sh --strict` -> all baselines PASS; `run-behavioral-contract-tests.ps1` and `.sh` -> 263 passed / 0 failed (Scenario Z verified); `validate-execution-control.ps1 -Root . -Strict` -> VALID
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
- **Changed-File Summary**: `8 files modified/created`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-25 05:42 UTC`
