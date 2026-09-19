# Task Record: `pk:sync` — PROMPTKIT.md Drift Detection Against Repository Reality

<a id="TASK-2026-09-19-sync-profile-drift"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-19-sync-profile-drift`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #338 — feat(sync): detect PROMPTKIT.md drift against repo reality
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/338`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge.`
- **Created**: `2026-09-19 16:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Add a bounded, detection-only profile drift pass to `pk:sync` so a stale `PROMPTKIT.md` (stack, toolchain, commands) is reported as findings with a proposed patch instead of being re-derived every session.
- **In Scope**:
  - `workflows/sync.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-19-sync-profile-drift.md`
- **Explicit Non-Goals**:
  - Auto-rewriting `PROMPTKIT.md` or any user-authored section; deep dependency/version analysis or stack inference (that is `pk:onboard`); `docs/STATE.md` semantics; a new command or script; any change to Balanced/Lite directive budgets.
- **Dependencies**: Issue #338 approved direction; canonical manifest list in `workflows/route.md` §4d
- **Risk**: Low — documentation/protocol wording plus contract assertions; no runtime code paths
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh .` 0 broken links; `measure-tokens.sh --strict` PASS; `measure-per-task-tokens.sh --strict` PASS; behavioral contract twins PASS.

## 3. Acceptance Criteria

- [x] **AC-1**: `workflows/sync.md` defines the Profile Drift Audit with a bounded manifest-presence scan (no dependency resolution).
- [x] **AC-2**: Drift is reported as findings with a proposed patch; nothing is rewritten until the developer confirms (detection is observation, not promotion).
- [x] **AC-3**: A clean profile produces no findings and no extra ceremony.
- [x] **AC-4**: Contract assertions pin the behavior in both `.sh` and `.ps1` twins.

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `State that live host timing or forced termination is unavailable or limited.`

## 5. State and Active Ownership

- **Execution State**: `ready`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-19 16:00 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/turbo-waves-guide (uncommitted)`
- **Next Action**: `Human PR review and merge decision on the #338 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-19 16:00 UTC | Implementor agent | Record created for Issue #338 Controlled Work | Issue #338 |
| planned | ready | 2026-09-19 16:00 UTC | Implementor agent | Readiness complete; scope bounded and approved | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/sync.md` — Profile Drift Audit subsection added under Phase 2
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario V assertions
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario V assertions (twin parity)
  - `docs/tasks/TASK-2026-09-19-sync-profile-drift.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `validate-references.sh .` → all references valid; `measure-tokens.sh --strict` → BALANCED 2500/2500 PASS, LITE 1146/1500 PASS; `measure-per-task-tokens.sh --strict` → all 6 baselines PASS; `run-behavioral-contract-tests.sh` → 234 passed / 0 failed (Scenario V: 6 assertions PASS); `validate-execution-control.sh --root . --strict` → VALID|RECORDS=31
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
- **Acceptance Results**: AC-1 through AC-4 Complete
- **Changed-File Summary**: 4 files modified/created
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-19 16:10 UTC`