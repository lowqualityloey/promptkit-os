# Task Record: [Objective]
<a id="TASK-YYYY-MM-DD-task-slug"></a>

## Identity
- **Record Type**: `Task Record`
- **Record Form**: `Lite`
- **Task ID**: `TASK-YYYY-MM-DD-<slug>`
- **Ceremony Level**: `Level 2 (Controlled)`
- **Specification**: `docs/specs/[spec].md`
- **Owner / Actor**: `[Actor]`
- **Execution Scope**: `[Repo or workspace boundary]`
- **Approval Boundary**: `[Actions needing human confirmation]`
- **Created**: `[YYYY-MM-DD HH:MM UTC]`

## Boundaries
- **Objective**: `[One observable objective]`
- **In Scope**:
  - `[File or behavior included]`
- **Explicit Non-Goals**:
  - `[What is excluded]`
- **Dependencies**: `[Dependency and owner, or None]`
- **Risk**: `[Low | Medium | High]` - `[Summary and mitigation]`
- **Verification Condition**: `[Command or check]`

## Acceptance Criteria
- [ ] **AC-1**: `[State true at acceptance]`
  - **Result**: `Pending`
  - **Evidence**: `[Command or link]`
- [ ] **AC-2**: `[State true at acceptance]`
  - **Result**: `Pending`
  - **Evidence**: `[Command or link]`

## Execution Policy
- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes, or N/A with reason`
- **Hard Checkpoint**: `At or before 90 minutes, or N/A with reason`
- **Event-Driven Checkpoints**: `Milestone, scope expansion, handoff, or compaction`
- **Stop Conditions**: `Missing approval, failed verification, blocker, or stop`
- **Host Timer Capability**: `[Observed limit; live timing is not enforceable]`

## State and Ownership
- **Execution State**: `planned`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `[This Task ID while in_progress, else None]`
- **Start Time**: `[YYYY-MM-DD HH:MM UTC or N/A]`
- **Current Actor**: `[Actor or session]`
- **Next Action**: `[One prioritized action]`

### Transition History
| Previous State | New State | Timestamp | Actor | Reason | Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `[YYYY-MM-DD HH:MM UTC]` | `[Actor]` | `Created` | `N/A` |

## Evidence and Completion
- **Changed Files**:
  - `[path]` - `[summary]`
- **Scope Change Records**: `[<task-id>.scope-<n>.md or None]`
- **Checkpoint Records**: `[<task-id>.checkpoint-<n>.md or None]`
- **Handoff Records**: `[<task-id>.handoff-<n>.md or None]`
- **Verification Evidence**: `[Commands and results]`
- **CI Evidence**: `[Provider, run, revision, result, or N/A]`
- **Review Evidence**: `[REVIEW link, reviewer, result, or N/A]`
- **Commit Evidence**: `[N/A before commit; commit X's entry lives later]`
- **Pull Request Evidence**: `[PR URL or N/A]`
- **Release Evidence**: `[Evaluation or tag link, or N/A]`
- **Blocker and Resume Condition**: `[Blocker, owner, and resume condition, or None]`
- **Completion State**: `[awaiting_review | completed | blocked | paused | aborted]`
- **Acceptance Results**: `[AC-1 result; AC-2 result]`
- **Changed-File Summary**: `[Complete summary]`
- **Completion Exception**: `[Exception record and approver, or None]`
- **Completion Decision and Timestamp**: `[Decision, actor, and YYYY-MM-DD HH:MM UTC]`

Transition rows use the canonical edges from the full template; the last row matches Execution State.
