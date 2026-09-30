# Scope Change Record: [Short change description]

## 1. Identity and Approval Boundary

- **Record Type**: `Scope Change Record`
- **Scope Change ID**: `SCOPE-[YYYY-MM-DD]-[task-id]-[sequence]`
- **Task ID**: `TASK-<task-slug>` (preserve `TASK-YYYY-MM-DD-<slug>` for legacy/`none`-profile records)
- **Specification**: `docs/specs/[specification].md`
- **Proposer / Actor**: `[Person, role, or agent]`
- **Created**: `[YYYY-MM-DD HH:MM UTC]`
- **Approval Boundary**: `[Human approval required, separate task required, or within existing scope]`

> Create this record before changing the task objective, in-scope files, acceptance criteria, dependencies, non-goals, risk, or verification condition. Do not silently rewrite the original Task Record.

## 2. Proposed Change

- **Reason or Discovery**: `[Why the change is requested]`
- **Current Task Value**: `[Current objective/scope/criterion/dependency/non-goal/risk/verification]`
- **Proposed Value**: `[Requested replacement or addition]`
- **Affected Objective**: `[Objective impact]`
- **Affected Files or Artifacts**: `[Paths or None]`
- **Affected Acceptance Criteria**: `[AC-* IDs or None]`
- **Affected Dependencies**: `[Dependencies and owners or None]`
- **New or Changed Non-Goals**: `[Updated exclusions or None]`
- **Risk / Estimate Impact**: `[Impact and mitigation]`
- **Changed Verification Condition**: `[New command/check/condition or None]`

## 3. Impact and Disposition

- **Disposition**: `[Within existing scope | Scope expansion | Separate Task Record | Emergency exception]`
- **Independent Work Discovered**: `[New task proposal and Task ID, or None]`
- **Required Human Confirmation**: `[Required | Not required with rationale]`
- **Required New Task Record**: `[docs/tasks/[new-task-id].md or N/A]`
- **Block Until Resolved**: `[Yes | No]`

A scope expansion requires explicit Human Confirmation or a separate Task Record before implementation continues. If neither is available, the current task remains `blocked` or `checkpoint_due`.

## 4. Approval and Evidence

- **Decision**: `[Proposed | Approved | Rejected | Superseded]`
- **Approver**: `[Person/account or N/A while proposed]`
- **Decision Timestamp**: `[YYYY-MM-DD HH:MM UTC or N/A]`
- **Approval Evidence**: `[Conversation reference, review, PR, or link]`
- **Related Checkpoint**: `[docs/tasks/[task-id].checkpoint-[sequence].md or N/A]`
- **Related Handoff**: `[docs/tasks/[task-id].handoff-[sequence].md or N/A]`
- **Branch / Revision**: `[branch and exact revision]`
- **Verification Plan or Result**: `[Plan before change or result after change]`
- **Blocker and Resume Condition**: `[Owner, evidence, and condition, or None]`

## 5. Resolution

- **Previous Task State**: `[State before disposition]`
- **Resulting Task State**: `[State after disposition]`
- **Task Record Updated**: `[Path and revision, or Pending]`
- **New Task / Exception Links**: `[Paths or None]`
- **Changed Scope Summary**: `[Accepted change, rejected change, or pending decision]`
- **Next Action**: `[Exactly one prioritized action]`
- **Recorded By and Timestamp**: `[Actor and YYYY-MM-DD HH:MM UTC]`
