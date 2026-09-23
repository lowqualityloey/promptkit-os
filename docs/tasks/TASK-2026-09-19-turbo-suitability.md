# Task Record: Turbo Suitability Check in `pk:profile` / `pk:onboard`

<a id="TASK-2026-09-19-turbo-suitability"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-19-turbo-suitability`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #337 — feat(profile): Turbo suitability check — warn when work is sequential
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/337`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge.`
- **Created**: `2026-09-19 16:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Ask a single advisory suitability question before the Turbo acknowledgement is accepted, so dependency-ordered/sequential work is warned that parallel waves buy zero benefit while the experimental cost still applies.
- **In Scope**:
  - `workflows/profile.md`
  - `workflows/onboard.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-19-turbo-suitability.md`
- **Explicit Non-Goals**:
  - Blocking or refusing Turbo (override stays); automatic workload/dependency analysis; changing Turbo refusal semantics or the installer (`init.sh` / `init.ps1`); profile defaults; template/directive edits (zero token headroom); the Turbo verdict (#213).
- **Dependencies**: Issue #337 approved direction; existing `docs/recipes/auto-waves-preflight-checklist.md` reused as evidence source (linked, not duplicated); installer guard text in `init.sh` / `init.ps1` unchanged
- **Risk**: Low — advisory workflow wording; Turbo override and Balanced/Lite paths unchanged
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh .` 0 broken links; `measure-tokens.sh --strict` PASS; `measure-per-task-tokens.sh --strict` PASS; behavioral contract twins PASS; `run-init-safety-tests.sh` and `run-profile-matrix.sh` unaffected (no installer edits).

## 3. Acceptance Criteria

- [x] **AC-1**: `workflows/profile.md` asks the suitability question before the Turbo acknowledgement and warns that sequential work gains zero benefit.
- [x] **AC-2**: The check is advisory, never blocking: a "no" routes to Balanced only on confirmation and an explicit Turbo override is still honored.
- [x] **AC-3**: The pre-flight checklist is linked as evidence, never restated (single authority).
- [x] **AC-4**: `workflows/onboard.md` runs the same advisory check before its Turbo acknowledgement; contract assertions pin the behavior in both twins.
- [x] **AC-5**: Non-interactive/CI paths remain prompt-free and the refusal semantics are unchanged.

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

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-19 16:00 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/turbo-waves-guide (uncommitted)`
- **Next Action**: `Human PR review and merge decision on the #337 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-19 16:00 UTC | Implementor agent | Record created for Issue #337 Controlled Work | Issue #337 |
| planned | ready | 2026-09-19 16:00 UTC | Implementor agent | Readiness complete; scope bounded and approved | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/profile.md` — Turbo suitability check (step 2b) and completion criterion
  - `workflows/onboard.md` — advisory suitability check before the Turbo acknowledgement
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario W assertions
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario W assertions (twin parity)
  - `docs/tasks/TASK-2026-09-19-turbo-suitability.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `validate-references.sh .` → all references valid; `measure-tokens.sh --strict` → BALANCED 2500/2500 PASS, LITE 1146/1500 PASS; `measure-per-task-tokens.sh --strict` → all 6 baselines PASS; `run-behavioral-contract-tests.sh` → 234 passed / 0 failed (Scenario W: 7 assertions PASS); `validate-execution-control.sh --root . --strict` → VALID|RECORDS=31; `run-init-safety-tests.sh` and `run-profile-matrix.sh` → PASS (no installer edits)
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
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 through AC-5 Complete
- **Changed-File Summary**: 5 files modified/created
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-19 16:10 UTC`