# Task Record: Enforceable tutor modes and tiered grill probes

<a id="TASK-2026-09-18-tutor-modes"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-tutor-modes`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issues #302 (tiered self-sufficient grill probes) and #303 (enforceable tutor modes)
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/302`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 11:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Make tutor modes govern their sessions (precedence over the generic loop, one trigger owner, stop rules, testable code boundary) and make grill probes tiered and self-sufficient. One branch closes both issues.
- **In Scope**:
  - `workflows/tutor.md` - Mode 5 tiering plus probe format; Modes 1-4/6 precedence, code boundary, debug trigger ownership, stops, stale path fixes in-file
  - `docs/tasks/TASK-2026-09-18-tutor-modes.md` (this record)
  - `docs/BENCHMARKS.md` - figure sync only if the contract suite mandates it
- **Explicit Non-Goals**:
  - No frontier-rounds/scorecard/grounding machinery (future grill rewrite)
  - No new modes; no validator or script changes
- **Dependencies**: Issues #302 and #303
- **Risk**: Medium - tutor.md wording may be behavioral-contract asserted; edits must keep suite green
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; behavioral 178/178; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: Grill probes are tiered and self-sufficient (numbered, titled, why-it-matters, tier examples)
- [x] **AC-2**: Literal Step execution cannot violate any mode rule (precedence stated)
- [x] **AC-3**: `pk:debug` has exactly one primary owner; stuck learners hit a stop, not a loop
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
- **Start Time**: `2026-09-18 11:00 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 11:00 UTC | Implementor agent | Record created for Issues #302/#303 Controlled Work | Issues #302, #303 |
| planned | ready | 2026-09-18 11:00 UTC | Implementor agent | Readiness complete; scope pre-approved in Issues #302/#303 | This record |
| ready | in_progress | 2026-09-18 11:00 UTC | Implementor agent | Branch `fix/tutor-modes-302-303`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 11:30 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/tutor.md` - Mode 5 tiering plus probe format; mode precedence; code boundary; debug trigger ownership; ADR verification; journal writer; teach-back stop; stale path fixes
  - `docs/tasks/TASK-2026-09-18-tutor-modes.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=21 (0 diagnostics); behavioral 178/178; playbook 11/11; references 0 warnings; measure-tokens --strict PASS (Balanced 2498<=2500, Lite 1146<=1500)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: pending PR run (Linux + Windows)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: pending commit on branch `fix/tutor-modes-302-303`
- **Pull Request Evidence**: pending PR referencing Issues #302 and #303
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: AC-1 Complete (tiered self-sufficient probes, teaching rules suspended in drills); AC-2 Complete (mode precedence, code boundary, ADR verification, journal writer); AC-3 Complete (debug.md primary, Mode 6 overlay, teach-back stop); AC-4 Complete (178/178, zero figure rot)
- **Changed-File Summary**: 2 files; tutor.md mode repair, Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-18 11:30 UTC`
