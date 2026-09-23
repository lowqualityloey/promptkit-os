# Task Record: Installer tracker multi-select and MCP intent line

<a id="TASK-2026-09-18-installer-picker"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-installer-picker`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #304 — tracker picker multi-select plus MCP intent line
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/304`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 10:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Stop the silent multi-select drop in the tracker picker (both twins) and record MCP intent alongside detection in onboard.
- **In Scope**:
  - `init.sh` - multi-select parsing plus reprompt warning
  - `init.ps1` - identical behavior (twin parity)
  - `workflows/onboard.md` - MCP intended-vs-detected line
  - `docs/tasks/TASK-2026-09-18-installer-picker.md` (this record)
  - `docs/BENCHMARKS.md` - figure sync only if the contract suite mandates it
- **Explicit Non-Goals**:
  - No new tracker backends; no MCP auto-configuration
  - No host-picker changes; no picker redesign beyond multi-select
- **Dependencies**: Issue #304
- **Risk**: Medium - installer prompt text may be behavioral-contract asserted; init-safety suites must pass on both twins
- **Verification Condition**: `run-init-safety-tests.sh` green; behavioral 178/178; references 0 warnings; execution-control VALID; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: `1 and 2` at the tracker prompt records local + GitHub projection
- [x] **AC-2**: Garbage input reprompts with warning instead of silently defaulting
- [x] **AC-3**: Identical input handling verified in Bash and PowerShell twins
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
- **Start Time**: `2026-09-18 10:00 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `None - task complete; PR #305 merged`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 10:00 UTC | Implementor agent | Record created for Issue #304 Controlled Work | Issue #304 |
| planned | ready | 2026-09-18 10:00 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #304 | This record |
| ready | in_progress | 2026-09-18 10:00 UTC | Implementor agent | Branch `fix/installer-tracker-picker-304`; pointer assumed | This record |
| in_progress | completed | 2026-09-18 10:00 UTC | Implementor agent | Branch `fix/installer-tracker-picker-304`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 10:30 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |
| awaiting_review | completed | 2026-09-18 10:30 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |


## 6. Evidence and Completion Gate

- **Changed Files**:
  - `init.sh` - tracker multi-select parsing, reprompt bound, projection line write
  - `init.ps1` - identical behavior (twin parity)
  - `workflows/onboard.md` - MCP intended-vs-detected line
  - `docs/tasks/TASK-2026-09-18-installer-picker.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=20 (0 diagnostics); behavioral 178/178; playbook 11/11; references 0 warnings; tokens PASS; init-safety suites green both twins (ps1 verified by trace + CI Windows job, no local pwsh)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: PR #305 CI green both OSes at merge (Lint and Validate Linux SUCCESS, Windows SUCCESS)
- **Review Evidence**: Maintainer-merged PR #305 on 2026-09-18; no separate review record
- **Commit Evidence**: Branch commits squash-merged as 14e015b
- **Pull Request Evidence**: PR #305 merged 2026-09-18T05:43:04Z, closes Issue #304
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 Complete (multi-select matrix verified); AC-2 Complete (3-attempt bound then announced default); AC-3 Complete (identical mapping traced in ps1); AC-4 Complete (178/178, zero figure rot)
- **Changed-File Summary**: 4 files; twin picker logic, onboard MCP line, Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `completed; PromptKit maintainer; 2026-09-18 12:00 UTC`
