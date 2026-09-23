# Task Record: Rewrite ship.md steps-vs-overlays contradiction

<a id="TASK-2026-09-18-ship-authority"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-ship-authority`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #290 — rewrite ship.md steps-vs-overlays contradiction
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/290`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 04:30 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Make ship.md say one thing about deploy authority: convert base Steps 3-5 from agent-executed imperatives into prepare-and-propose evidence steps terminating at explicit human authorization gates, consistent with the overlays and the gate Authority Model. Fix Completion Criteria to cover overlays; remove leaked Task 6/12 plan numbers.
- **In Scope**:
  - `workflows/ship.md` - steps rewrite plus completion criteria plus plan-number cleanup
  - `docs/BENCHMARKS.md` - section-3 ship cells synced (figure-rot guard mandates sync after ship.md edit)
  - `docs/tasks/TASK-2026-09-18-ship-authority.md` (this record)
  - `docs/BENCHMARKS.md` - figure sync only if the contract suite mandates it
- **Explicit Non-Goals**:
  - No validator or script changes
  - No release record schema changes
  - No auto.md/pr.md/commit.md changes (Issue #289 delivered)
- **Dependencies**: Issue #290; #289 Authority Model table (merged) as the referenced single source
- **Risk**: Medium - ship.md wording is behavioral-contract asserted; edits must keep suite green
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; behavioral 178/178; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: ship.md contains exactly one deploy authority (human-only), readable end to end
- [x] **AC-2**: Completion Criteria cover overlay additions (CI-triage linkage, release-impact evaluation)
- [x] **AC-3**: No internal Task 6/12 plan numbers remain in user-facing text
- [x] **AC-4**: Behavioral contract suite passes 178/178

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `Live host timing and forced generation termination are unavailable in this host; checkpoint thresholds are protocol discipline, not mechanical enforcement.`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-18 04:30 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `None - task complete; PR #296 merged`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 04:30 UTC | Implementor agent | Record created for Issue #290 Controlled Work | Issue #290 |
| planned | ready | 2026-09-18 04:30 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #290 | This record |
| ready | in_progress | 2026-09-18 04:30 UTC | Implementor agent | Branch `fix/ship-authority-290`; pointer assumed | This record |
| in_progress | completed | 2026-09-18 04:30 UTC | Implementor agent | Branch `fix/ship-authority-290`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 05:00 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |
| awaiting_review | completed | 2026-09-18 05:00 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |


## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/ship.md` - steps reframed as prepare-and-propose, completion criteria, plan-number cleanup, template path fix
  - `docs/BENCHMARKS.md` - section-3 ship cells synced (figure-rot guard mandates sync after ship.md edit)
  - `docs/tasks/TASK-2026-09-18-ship-authority.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=16 (0 diagnostics); behavioral 178/178; playbook 11/11; references 0 warnings; measure-tokens --strict PASS (Balanced 2498<=2500, Lite 1146<=1500)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: PR #296 CI green both OSes at merge (Lint and Validate Linux SUCCESS, Windows SUCCESS)
- **Review Evidence**: Maintainer-merged PR #296 on 2026-09-18; no separate review record
- **Commit Evidence**: Branch commits squash-merged as 80fdde6
- **Pull Request Evidence**: PR #296 merged 2026-09-18T02:38:51Z, closes Issue #290
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 Complete (prepare-and-propose steps, one human-only authority); AC-2 Complete (CI-triage linkage, impact evaluation, authorization criteria); AC-3 Complete (no Task 6/12 numbers); AC-4 Complete (178/178 after ship figure sync)
- **Changed-File Summary**: 3 files; ship.md authority rewrite, BENCHMARKS ship figure sync, Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `completed; PromptKit maintainer; 2026-09-18 09:00 UTC`
