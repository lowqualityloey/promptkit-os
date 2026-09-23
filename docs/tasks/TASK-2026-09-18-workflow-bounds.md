# Task Record: Workflow bounds and artifact grounding

<a id="TASK-2026-09-18-workflow-bounds"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-workflow-bounds`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #293 — bounds, evaporating outputs, ceremony pointers
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/293`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 06:30 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Give every unbounded loop a bound/HALT and every produced artifact a destination; declare L2 Task Record entry requirements in data/auth/api/perf. No new authority; bounds follow the existing 2-repair/HALT pattern.
- **In Scope**:
  - `workflows/debug.md` - HALT path when no red loop is buildable
  - `workflows/refactor.md` - Mikado retry depth/attempt bound
  - `workflows/reflect.md` - interrogation round cap plus non-interactive fallback
  - `workflows/plan.md` - Full RFC interrogation bound (minimal; plan payload is figure-guarded)
  - `workflows/auth.md` - threat-model findings destination
  - `workflows/data.md` - seed data and rollback destinations
  - `workflows/review.md` - AC provenance rule per level
  - `workflows/pr.md` - pr-body.md destination
  - `workflows/data.md`, `workflows/auth.md`, `workflows/api.md`, `workflows/perf.md` - L2 Task Record entry pointers
  - `docs/tasks/TASK-2026-09-18-workflow-bounds.md` (this record)
  - `docs/BENCHMARKS.md` - figure sync only if the contract suite mandates it
- **Explicit Non-Goals**:
  - No validator or script changes
  - No authority rewrites (Issues #289/#290 delivered)
  - No test.md/design-system.md changes (Issue #291)
- **Dependencies**: Issue #293; bounded-repair pattern from the shared gate as the model
- **Risk**: Medium - plan.md wording is figure-guarded (payload cells); other files are lower-risk
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; behavioral 178/178; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: Every targeted loop has a bound or HALT (debug, refactor, reflect, plan)
- [x] **AC-2**: Every targeted artifact has a destination (auth, data, review, pr)
- [x] **AC-3**: data/auth/api/perf declare L2 Task Record entry requirements
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
- **Start Time**: `2026-09-18 06:30 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `None - task complete; PR #298 merged`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 06:30 UTC | Implementor agent | Record created for Issue #293 Controlled Work | Issue #293 |
| planned | ready | 2026-09-18 06:30 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #293 | This record |
| ready | in_progress | 2026-09-18 06:30 UTC | Implementor agent | Branch `chore/workflow-bounds-293`; pointer assumed | This record |
| in_progress | completed | 2026-09-18 06:30 UTC | Implementor agent | Branch `chore/workflow-bounds-293`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 07:00 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |
| awaiting_review | completed | 2026-09-18 07:00 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |


## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/debug.md` - Phase 1 HALT path plus hypothesis-iteration bound
  - `workflows/refactor.md` - scoped revert plus Mikado depth/retry bounds
  - `workflows/reflect.md` - single interrogation round plus non-interactive fallback plus template path fix
  - `workflows/plan.md` - planning interrogation bound
  - `workflows/auth.md` - threat-findings destination plus ceremony pointer plus template path fixes
  - `workflows/data.md` - seed/rollback destinations plus ceremony pointer plus template path fixes
  - `workflows/api.md` - ceremony pointer plus template path fix
  - `workflows/perf.md` - ceremony pointer plus production-URL guard
  - `workflows/pr.md` - AC provenance rule plus pr-body destination
  - `docs/BENCHMARKS.md` - section-3 plan cells synced (figure-rot guard mandates sync after plan.md edit)
  - `docs/tasks/TASK-2026-09-18-workflow-bounds.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=18 (0 diagnostics); behavioral 178/178; playbook 11/11; references 0 warnings; measure-tokens --strict PASS (Balanced 2498<=2500, Lite 1146<=1500)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: PR #298 CI green both OSes at merge (Lint and Validate Linux SUCCESS, Windows SUCCESS)
- **Review Evidence**: Maintainer-merged PR #298 on 2026-09-18; no separate review record
- **Commit Evidence**: Branch commits squash-merged as 0da23d8
- **Pull Request Evidence**: PR #298 merged 2026-09-18T02:51:53Z, closes Issue #293
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 Complete (HALT/bounds in debug, refactor, reflect, plan); AC-2 Complete (destinations in auth, data, pr; review sources via pr provenance); AC-3 Complete (L2 pointers in data/auth/api/perf); AC-4 Complete (178/178 after plan figure sync)
- **Changed-File Summary**: 11 files; bounds and destinations across 9 workflows, BENCHMARKS plan sync, Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `completed; PromptKit maintainer; 2026-09-18 09:00 UTC`
