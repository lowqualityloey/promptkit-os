# Task Record: Resolve test.md authority and design-system contradictions

<a id="TASK-2026-09-18-test-design"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-test-design`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #291 — test.md Step 2.5 authority and design-system contradictions
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/291`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 07:30 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Make test.md planning-only again (RED demonstration without GREEN implementation, fixed sequencing, grounded first run) and make design-system.md self-consistent (icon guidance, 44px sample, artifact step, completion criteria).
- **In Scope**:
  - `workflows/test.md` - Step 2.5 reframed as RED-demonstration-only, step renumbering, first-run grounding
  - `workflows/design-system.md` - icon guidance resolution, 44px sample fix, artifact step, completion criteria
  - `docs/tasks/TASK-2026-09-18-test-design.md` (this record)
  - `docs/BENCHMARKS.md` - figure sync only if the contract suite mandates it
- **Explicit Non-Goals**:
  - No test-strategy redesign; no token-system redesign
  - No validator or script changes
- **Dependencies**: Issue #291; fix/debug ownership of implementation (delivered patterns)
- **Risk**: Medium - test.md wording may be behavioral-contract asserted; edits must keep suite green
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; behavioral 178/178; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: test.md never authorizes production code changes; planning-only boundary holds end to end
- [x] **AC-2**: design-system.md samples satisfy its own gate rules; guidance has no contradictions
- [x] **AC-3**: Both workflows have defined artifacts and completion criteria
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
- **Start Time**: `2026-09-18 07:30 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 07:30 UTC | Implementor agent | Record created for Issue #291 Controlled Work | Issue #291 |
| planned | ready | 2026-09-18 07:30 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #291 | This record |
| ready | in_progress | 2026-09-18 07:30 UTC | Implementor agent | Branch `fix/test-design-291`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 08:00 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/test.md` - RED-only Step 3, renumbering, first-run grounding, template path fix
  - `workflows/design-system.md` - icon guidance resolution, 44px sample fix, artifact step, completion criteria
  - `docs/tasks/TASK-2026-09-18-test-design.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=19 (0 diagnostics); behavioral 178/178; playbook 11/11; references 0 warnings; measure-tokens --strict PASS (Balanced 2498<=2500, Lite 1146<=1500)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: pending PR run (Linux + Windows)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: pending commit on branch `fix/test-design-291`
- **Pull Request Evidence**: pending PR referencing Issue #291
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: AC-1 Complete (RED-only Step 3, GREEN owned by fix/feature work); AC-2 Complete (icon framing resolved, 44px sample fixed); AC-3 Complete (test plan artifact, design tokens artifact, completion criteria); AC-4 Complete (178/178, zero figure rot)
- **Changed-File Summary**: 3 files; test.md planning-only restoration, design-system.md consistency repair, Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-18 08:00 UTC`
