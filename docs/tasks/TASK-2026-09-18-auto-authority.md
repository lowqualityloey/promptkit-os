# Task Record: Resolve auto vs pr/commit push authority conflict

<a id="TASK-2026-09-18-auto-authority"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-auto-authority`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #289 — resolve auto vs pr/commit unattended push and picker conflict, plus Authority Model table
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/289`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 03:30 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Establish exactly one approval rule for unattended commit/push/PR: an Authority Model table in the shared gate, an explicit run-authorization rule in auto.md, exception clauses in commit.md/pr.md, and push added to route.md's approval list. Bound --full scope to its invocation snapshot.
- **In Scope**:
  - `protocols/code-quality-gate.md` - Action Authority Model table (single source)
  - `workflows/auto.md` - run-authorization rule, --full snapshot bound, mission-boundary coherence
  - `workflows/pr.md` - auto-run exception clause for push/draft-PR
  - `workflows/commit.md` - auto-run exception clause for confirmation picker
  - `workflows/route.md` - push added to human-approval list
  - `docs/BENCHMARKS.md` - section-3 payload cells synced (figure-rot guard mandates sync after gate edit)
  - `docs/tasks/TASK-2026-09-18-auto-authority.md` (this record)
- **Explicit Non-Goals**:
  - No validator or script changes
  - No ship.md rewrite (Issue #290)
  - No new enforcement machinery beyond prose invariants
- **Dependencies**: Issue #289 plus approved scope comment (authority table); main at current head
- **Risk**: Medium - authority wording is behavioral-contract asserted; edits must keep suite green
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; behavioral 178/178; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: Exactly one approval rule for push/PR creation applies across auto, pr, commit, route, and gate
- [x] **AC-2**: --full scope is bounded to its invocation snapshot with a re-authorization rule
- [x] **AC-3**: Behavioral contract suite passes 178/178 (no asserted string broken)
- [x] **AC-4**: `validate-execution-control.sh --root . --strict` VALID

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

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-18 03:30 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 03:30 UTC | Implementor agent | Record created for Issue #289 Controlled Work | Issue #289 |
| planned | ready | 2026-09-18 03:30 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #289 | This record |
| ready | in_progress | 2026-09-18 03:30 UTC | Implementor agent | Branch `fix/auto-push-authority-289`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 04:00 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `protocols/code-quality-gate.md` - Action Authority Model table (single source)
  - `workflows/auto.md` - run-authorization rule, --full snapshot bound, mission-boundary coherence
  - `workflows/pr.md` - auto-run exception clause for push/draft-PR
  - `workflows/commit.md` - auto-run exception clause for confirmation
  - `workflows/route.md` - push added to human-approval list
  - `docs/BENCHMARKS.md` - section-3 payload cells synced to new gate size
  - `docs/tasks/TASK-2026-09-18-auto-authority.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=15 (0 diagnostics); behavioral 178/178; playbook 11/11; references 0 warnings; measure-tokens --strict PASS (Balanced 2498<=2500, Lite 1146<=1500); post-#294-merge figure re-sync verified 178/178
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: pending PR run (Linux + Windows)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: pending commit on branch `fix/auto-push-authority-289`
- **Pull Request Evidence**: pending PR referencing Issue #289
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: AC-1 Complete (one rule via gate table + run-authorization exception); AC-2 Complete (--full frozen at invocation snapshot); AC-3 Complete (178/178 after BENCHMARKS sync); AC-4 Complete (VALID|RECORDS=15, 0 diagnostics)
- **Changed-File Summary**: 7 files; gate Authority Model table, auto/pr/commit/route authority alignment, BENCHMARKS figure sync, Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-18 04:00 UTC`
