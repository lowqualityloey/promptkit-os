# Checkpoint Record: [Short checkpoint objective or progress summary]

> **Developer-friendly fill-in guide:** A **Required** field must contain a concrete, non-placeholder value before the record validates. For **Blockers**, provide either concrete blocker details or the literal string `None identified` (quick tier) or `None` (full tier). `N/A — no Task Record (Level 0/1)` is permitted for `Task ID` in the Level 1 quick tier when no canonical task record exists.

---

## Quick Tier (Level 1 Standard Work)

Use this format for Level 1 (Standard) work when fast-path execution is authorized by `workflows/route.md` and no formal Task Record (`docs/tasks/<task-id>.md`) is required. Ten canonical labels are required; remaining full-tier labels degrade gracefully with `POLICY_LIMITATION` marks.

```markdown
# Checkpoint Record: [Short progress summary]

- **Record Type**: `Checkpoint Record`
- **Checkpoint ID**: CHECKPOINT-YYYY-MM-DD-<slug>-<sequence>
- **Ceremony Level**: Level 1 (Standard)
- **Created**: YYYY-MM-DD HH:MM UTC
- **Execution State**: in_progress <!-- in_progress | checkpoint_due | blocked | paused | handoff_ready | awaiting_review -->
- **Objective**: [One concise observable objective]
- **Remaining Work**: [Remaining tasks or acceptance criteria]
- **Blockers**: None identified <!-- Concrete blocker or None identified -->
- **Next Action**: [Exactly one prioritized next action]
- **Resume Condition**: [Condition that lifts stop state or allows progress]
- **Recorded By**: [Person, role, or agent]
```

---

## Full Tier (Level 2 Controlled & Level 3 Release-Critical Work)

Use this format for Level 2 (Controlled) and Level 3 (Release-Critical) work. All 20 canonical labels are mandatory and must be backed by a resolvable canonical Task Record (`docs/tasks/<task-id>.md`). Placeholders are strictly prohibited.

```markdown
# Checkpoint Record: [Controlled work progress snapshot]

- **Record Type**: `Checkpoint Record`
- **Checkpoint ID**: CHECKPOINT-YYYY-MM-DD-<task-id>-<sequence>
- **Task ID**: TASK-<task-slug>
- **Ceremony Level**: Level 2 (Controlled) <!-- Level 2 (Controlled) | Level 3 (Release-Critical) -->
- **Specification**: docs/specs/[specification].md
- **Created**: YYYY-MM-DD HH:MM UTC
- **Checkpoint Type**: [Event-driven milestone checkpoint | Scheduled context checkpoint]
- **Execution State**: in_progress <!-- in_progress | checkpoint_due | blocked | paused | handoff_ready | awaiting_review -->
- **Objective**: [Authoritative task objective from canonical Task Record]
- **Completed Work**: [Completed milestones and verified items]
- **Remaining Work**: [Remaining acceptance criteria or work items]
- **Changed Files**:
  - `[path/to/changed/file]`
- **Branch / Revision**: [branch-name] @ [commit-sha-or-rev]
- **Locked Decisions and Invariants**: [Decisions or invariants that must not be undone]
- **Verification Evidence**: [Command, exit code, and observable result]
- **CI Evidence**: [Provider, workflow/job, run, result, or N/A]
- **Blockers**: None <!-- Concrete blocker or None -->
- **Scope Changes**: [docs/tasks/<task-id>.scope-<seq>.md or None]
- **Next Action**: [Exactly one prioritized next action]
- **Resume Condition**: [Precise condition required to resume execution]
- **Recorded By**: [Person, role, or agent]
```
