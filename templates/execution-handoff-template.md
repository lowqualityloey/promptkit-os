# Handoff Record: [Task and transfer purpose]

## 1. Identity and Transfer

- **Record Type**: `Handoff Record`
- **Handoff ID**: `HANDOFF-[YYYY-MM-DD]-[task-id]-[sequence]`
- **Task ID**: `TASK-<task-slug>` (preserve `TASK-YYYY-MM-DD-<slug>` for legacy/`none`-profile records)
- **Specification**: `docs/specs/[specification].md`
- **Created**: `[YYYY-MM-DD HH:MM UTC]`
- **Sender / Current Owner**: `[Person, role, agent, or session]`
- **Intended Receiver**: `[Person, role, agent, or fresh session]`
- **Approval Boundary**: `[Actions the receiver must confirm before continuing]`

## 2. Current Execution Snapshot

- **Execution State**: `handoff_ready` <!-- handoff_ready | blocked | checkpoint_due | awaiting_review -->
- **Execution Scope**: `[Repository, workspace, package, or session boundary]`
- **Objective**: `[One observable objective]`
- **Completed Milestones**:
  - `[Milestone and evidence]`
- **Remaining Acceptance Criteria**:
  - `[AC-* ID and remaining condition]`
- **Blockers and Resume Conditions**: `[Blocker, owner, evidence, and precise condition, or None]`
- **Next Action**: `[Exactly one prioritized action]`

## 3. Workspace and Evidence

- **Branch**: `[Branch name]`
- **Validated Revision**: `[Exact commit or revision]`
- **Changed Files**:
  - `[path]` - `[summary and current state]`
- **Task Record**: `docs/tasks/[task-id].md`
- **Related Scope Changes**: `[Paths or None]`
- **Related Checkpoints**: `[Paths or None]`
- **Related Exceptions**: `[Paths or None]`
- **Verification Commands and Results**: `[Commands, results, and timestamps]`
- **CI Evidence**: `[Provider, workflow/job, run, revision, result, or N/A]`
- **Review / Commit / PR Evidence**: `[Links and current state]`
- **Release Evidence**: `[Release evaluation/tag/post-release link, or N/A]`

## 4. Decisions, Invariants, and Limitations

- **Locked Decisions**:
  - `[Decision and source]`
- **Non-Negotiable Invariants**:
  - `[Invariant and verification]`
- **Rejected Approaches**: `[Approach and reason, or None]`
- **Scope and Approval Constraints**: `[What the receiver must not change without a Scope Change Record]`
- **Host or Timer Limitations**: `[Observed limitation; do not claim a mechanical stop the host cannot provide]`

## 5. Receiver Validation

Before making implementation changes, the receiver must check and record:

- [ ] **Task identity**: Task ID and specification match the Task Record.
- [ ] **Revision**: Current workspace matches the validated revision or the difference is explained.
- [ ] **Changed files**: Current file set matches the handoff or discrepancies are recorded.
- [ ] **Acceptance**: Remaining and completed `AC-*` criteria are understood.
- [ ] **Invariants**: Locked decisions and non-negotiable constraints are accepted.
- [ ] **Blockers**: Blockers and resume conditions are still valid.
- [ ] **Next action**: Exactly one next action is accepted without implicit scope expansion.

- **Receiver**: `[Person, role, agent, or session]`
- **Acceptance Decision**: `[Accepted | Blocked | Rejected]`
- **Acceptance Timestamp**: `[YYYY-MM-DD HH:MM UTC]`
- **Receiver-Validated Revision**: `[Exact revision]`
- **Validation Evidence**: `[Commands, review, or reason]`
- **Scope Changed During Acceptance**: `[No | Scope Change Record link]`
- **Acceptance Blocker and Resume Condition**: `[Blocker and condition, or None]`

A stale, incomplete, contradictory, or revision-inconsistent handoff must remain blocked or `checkpoint_due` until reconciled. Acceptance records the receiver and next action; it does not change task scope or mark the task complete.

## 6. Disposition

- **Resulting Execution State**: `[in_progress | blocked | checkpoint_due | awaiting_review]`
- **Task Record Updated**: `[Path and revision]`
- **Handoff Closed By**: `[Actor]`
- **Closed Timestamp**: `[YYYY-MM-DD HH:MM UTC]`
- **Next Action**: `[Exactly one prioritized action]`
