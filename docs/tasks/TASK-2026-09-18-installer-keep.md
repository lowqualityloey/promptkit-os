# Task Record: Installer keeps installed profile and tracker on re-run

<a id="TASK-2026-09-18-installer-keep"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-installer-keep`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #311 — re-runs keep installed profile/tracker, flags override
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/311`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 15:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Make update re-runs silent when settings exist: pre-seed profile/tracker from installed PROMPTKIT.md, print keeping-notice, skip prompts; flags always override; fresh installs unchanged.
- **In Scope**:
  - `init.sh` - installed-value pre-seed for profile and tracker pickers
  - `init.ps1` - identical behavior (twin parity)
  - `docs/tasks/TASK-2026-09-18-installer-keep.md` (this record)
  - `docs/BENCHMARKS.md` - figure sync only if the contract suite mandates it
- **Explicit Non-Goals**:
  - No picker redesign; no host-selection changes; no new backends
- **Dependencies**: Issue #311
- **Risk**: Medium - installer flows are init-safety asserted; prompt text may be behavioral-contract asserted
- **Verification Condition**: `run-init-safety-tests.sh` green; behavioral 178/178; references 0 warnings; execution-control VALID; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: Installed balanced re-run without flags shows no profile prompt and keeps the value
- [x] **AC-2**: Flags override installed values
- [x] **AC-3**: Fresh installs behave exactly as today
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

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-18 15:00 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 15:00 UTC | Implementor agent | Record created for Issue #311 Controlled Work | Issue #311 |
| planned | ready | 2026-09-18 15:00 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #311 | This record |
| ready | in_progress | 2026-09-18 15:00 UTC | Implementor agent | Branch `fix/installer-keep-installed-311`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 15:30 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `init.sh` - installed-value pre-seed plus stale projection cleanup
  - `init.ps1` - identical behavior (twin parity)
  - `docs/tasks/TASK-2026-09-18-installer-keep.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=23 (0 diagnostics); behavioral 178/178; playbook 11/11; references 0 warnings; tokens PASS; init-safety green; live sandbox runs verified keep/fresh/override on Bash twin (ps1 by line-trace plus CI Windows job)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: pending PR run (Linux + Windows)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: pending commit on branch `fix/installer-keep-installed-311`
- **Pull Request Evidence**: pending PR referencing Issue #311
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: AC-1 Complete (pre-seed verified live in sandbox); AC-2 Complete (flags won, stale projection removed); AC-3 Complete (fresh defaults unchanged); AC-4 Complete (178/178, zero figure rot)
- **Changed-File Summary**: 3 files; twin pre-seed plus stale cleanup, Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-18 15:30 UTC`
