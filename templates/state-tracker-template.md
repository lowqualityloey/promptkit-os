# Project State & Living Execution Tracker

<!-- Bounded projection: respect `state-guard:` thresholds in `PROMPTKIT.md`; `pk:checkpoint` archives completed history to `docs/STATE-ARCHIVE.md`. -->
## 1. Executive Summary & Current Position
- **Project**: [project]
- **Milestone / Epic**: [milestone]
- **Overall Status**: [ACTIVE | PAUSED | STABILIZING | RELEASE_CANDIDATE | COMPLETED]
- **Branch**: [branch]
- **Last Updated**: [YYYY-MM-DD]
## 2. Milestone & Task Progress
- [ ] **Milestone 1**: not tracked — defined by `pk:onboard`, owned here
- [ ] not tracked — `[x]` Done, `[/]` In Progress, `[ ]` Queued, `[!]` Blocked; owned by `pk:tasks` and `pk:checkpoint`
## 3. Active Working Set
- **Workspace / Package**: [package or blank]
- **Active RFC / Spec**: not tracked
- **Files in Flight**: not tracked
- **Verification Commands**: [native commands]
## 3A. Execution-Control Projection (Optional)
> `docs/tasks/<task-id>.md` is authoritative; escape `|` as `\|` in tables.
- **Task ID**: `TASK-<slug>`
- **Task Record**: `docs/tasks/<task-id>.md`
- **Ceremony Level**: `[1 | 2 | 3]`
- **Specification**: `[path]`
- **Execution Scope**: `[scope]`
- **Execution State**: `[planned | in_progress | blocked | paused | awaiting_review | completed]`
- **Mapped `pk:tasks` Status**: `[To Do | In Progress | In Review | Done]`
- **Active Task Pointer**: `[Task ID or None]`
- **Owner / Current Actor**: `[person or agent]`
- **Start Time**: `[YYYY-MM-DD HH:MM UTC]`
- **Current Revision**: `[commit]`
- **Next Action**: `[one action]`
## 4. Locked Technical Invariants (Do Not Undo)
**Illustrative syntax — not invariant entries.** An actual invariant is a human-approved rule with an inline source — a decision ID (`DECISION-*`) or project policy (`policy:` plus path); a `DIVERGENCE-*`-backed project-document claim needs the same approval. These fenced lines show only that shape; never copy them as policy.

```text
<invariant> — source: DECISION-<spec-slug>-<nnn>
<invariant> — source: policy: <project-relative path>
```

**Empty state — not an invariant entry.** Leave §4 without entry bullets until a decision is locked; never pre-fill one.
## 4A. Candidate Learnings (Unpromoted)
Observed rules staged before promotion; never pre-filled or binding. Promotion needs a recorded human decision (`approved` / `rejected` / `deferred`) with approver, date, evidence reference, and destination (`protocols/context-sync.md` §3.1).

| Date | Proposed Rule | Source / Evidence | Scope | Status | Human Decision |
| :--- | :--- | :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked | not tracked | not tracked |
## 5. Known Blockers, Risks & Open Questions
- **Blockers**: [owner, evidence, resolution, or none]
- **Architectural Questions**: [decision, deadline, or none]
- **Technical Debt & Risks**: [debt, impact, milestone, or none]
## 6. Recent Architectural Decisions (ADR Log)
| Date | Scope | Decision | ADR |
| :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked |
## 7. Next Immediate Actions (Queued)
1. not tracked — populated by `pk:checkpoint`, never pre-filled.
## 8. Session Continuity Log
<!-- Table Invariant: contiguous rows; escape \| -->

| Date | Engineer / Agent | Milestone / Focus | Key Changes & Artifacts |
| :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked |
## 9. Session Spend Ledger

| Session | Turns | Measured in/out | Estimated context payload | Note |
| :--- | :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked | not tracked |

- **Running total**: `not tracked` — sums measured tokens; unmetered hosts record `host telemetry unavailable`, never an inferred range.
- **Note evidence**: `duration=<value>; repairs=<count or not tracked>; interventions=<count or not tracked>; verification=<result or not tracked>; outcome=<accepted | rejected | incomplete | blocked | not tracked>`; never infer `0` or `passed`.
