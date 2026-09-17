# Project State & Living Execution Tracker

## 1. Executive Summary & Current Position
- **Project Name**: [Project Name]
- **Current Milestone / Epic**: [e.g., Milestone 2: Core Domain Engine]
- **Overall Status**: ACTIVE <!-- Options: ACTIVE | PAUSED | STABILIZING | RELEASE_CANDIDATE | COMPLETED (all milestones closed, release evidence archived, zero open blockers — recording stops here) -->
- **Target Release / Deadline**: [e.g., v1.0.0 / YYYY-MM-DD]
- **Current Working Branch**: [e.g., main or feature/branch-name]
- **Last Updated**: [YYYY-MM-DD]

---

## 2. Milestone & Task Progress

### Milestone Roadmap
- [ ] **Milestone 1**: not tracked — defined by `pk:onboard` intake, then owned here

### Active Milestone Task Breakdown
Track tasks using atomic checklists (`[x]` Done, `[/]` In Progress, `[ ]` Queued, `[!]` Blocked):

- [ ] not tracked — populated by `pk:tasks` and `pk:checkpoint` from real execution, never pre-filled

---

## 3. Active Working Set
- **Target Workspace / Package (if Monorepo)**: [e.g. `apps/web` or `@repo/db` (leave blank for standalone repo)]
- **Active RFC / Spec**: `docs/specs/YYYY-MM-DD-feature-name.md`
- **Active Task Spec**: `docs/tasks/YYYY-MM-DD-task-breakdown.md`
- **Key Source Files in Flight**: not tracked — recorded here when work starts, never pre-filled
- **Verification Commands (Scoped)**:
  - Unit Tests: `npm test` (or `pnpm --filter <pkg> test`, `turbo run test --filter=<pkg>`)
  - Typecheck: `npm run typecheck` (or `pnpm --filter <pkg> typecheck`)
  - Linter: `npm run lint` (or `pnpm --filter <pkg> lint`)

---

## 3A. Execution-Control Projection (Optional)

> This section is a synchronized projection for checkpoint continuity when the host project uses Controlled Work. The canonical authority remains `docs/tasks/<task-id>.md`; disagreement with that record is a validation failure and leaves execution blocked or `checkpoint_due` until reconciled.

- **Local Task Source**: `docs/tasks/<task-id>.md`
- **Task ID**: `TASK-[YYYY-MM-DD]-[slug]`
- **Task Record**: `docs/tasks/<task-id>.md`
- **Specification**: `docs/specs/[specification].md`
- **Execution Scope**: `[Repository, workspace, package, or session boundary]`
- **Execution State**: `[planned | ready | in_progress | checkpoint_due | blocked | paused | handoff_ready | awaiting_review | completed | aborted]`
- **Mapped `pk:tasks` Status**: `[To Do | In Progress | In Review | Done]`
- **Active Task Pointer**: `[Task ID while active, otherwise None]`
- **Owner / Current Actor**: `[Person, role, agent, or session]`
- **Start Time**: `[YYYY-MM-DD HH:MM UTC or N/A]`
- **Current Branch**: `[Branch name]`
- **Current Revision**: `[Exact commit or revision]`
- **Checkpoint Policy**: `[Soft/hard intervals, event triggers, and host timer capability/limitation]`
- **Blockers and Resume Condition**: `[Blocker, owner, evidence, and precise condition, or None]`
- **Verification Status**: `[Commands, results, and timestamp]`
- **CI Evidence**: `[Provider, workflow/job, run, revision, result, or N/A]`
- **Changed-File Summary**: `[Current working set summary]`
- **Latest Checkpoint**: `[Record path or None]`
- **Latest Handoff**: `[Record path or None]`
- **Next Action**: `[Exactly one prioritized action]`

---

## 3B. Release-Evaluation Handoff (Optional)

> Use this projection only when PromptKit OS release evaluation is being handed from QA/Reviewer to a Release Coordinator. It is a durable handoff, not approval, and the canonical evaluation or Task Record remains authoritative.

- **Evaluation ID**: `[evaluation ID or N/A]`
- **Release Candidate Commit**: `[exact candidate revision or N/A]`
- **Preliminary SemVer Candidate**: `[preliminary version, including prerelease identifier when applicable, or N/A]`
- **QA/Reviewer Result**: `[Pass | Fail | Pending | N/A]`
- **Unresolved Blockers**: `[blocker, owner, and resolution condition, or None]`
- **Requested Release Coordinator Decision / Next Approval Action**: `[exact human decision requested, or N/A]`
- **Handoff Status**: `[Ready for Coordinator Review | Blocked | Deferred | N/A]`
- **Approval Boundary**: `This projection does not approve a candidate or version and does not authorize tag creation, hosted release creation, changelog publication, remote operations, deployment, or rollback.`
- **Source Evaluation / Task Record**: `[authoritative record path or N/A]`

---

## 4. Locked Technical Invariants (Do Not Undo)
Document non-negotiable architectural decisions agreed upon during pairing sessions:
- not tracked — invariants are recorded here as pairing sessions lock them in, never pre-filled

---

## 4A. Candidate Learnings (Unpromoted)

Staging area for rules observed during sessions but not yet approved as invariants. Entries here are **never pre-filled** and are non-authoritative: agents must not treat them as policy, quote them as invariants, or copy them into project guardrails. Promotion requires a recorded human decision (`approved` / `rejected` / `deferred`) with approver, date, evidence reference, and destination (see `protocols/context-sync.md` §3.1).

| Date | Proposed Rule | Source / Evidence | Scope | Status | Human Decision (approver, date, destination) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked | not tracked | not tracked |

---

## 5. Known Blockers, Risks & Open Questions
- **Blockers**:
  - [e.g., TASK-06 blocked on third-party API sandbox credentials from devops team]
- **Architectural Questions**:
  - [e.g., Evaluate Redis vs in-memory caching for session tokens before Milestone 4]
- **Technical Debt & Risks**:
  - [e.g., Monolithic test suite is taking >45s in CI; needs sharding before launch]

---

## 6. Recent Architectural Decisions (ADR Log)
| Date | Title & Scope | Decision Summary | ADR File |
| :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked |

---

## 7. Next Immediate Actions (Queued)
1. not tracked — populated by `pk:checkpoint` from real session state, never pre-filled.

---

## 8. Session Continuity Log
Compact record of pairing sessions to enable instant chat resumption:

| Date | Engineer / Agent | Milestone / Focus | Key Changes & Artifacts |
| :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked |

---

## 9. Session Spend Ledger

| Session | Turns | Measured in/out | Estimated payload | Note |
| :--- | :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked | not tracked |

- **Running total**: not tracked — refreshed by `pk:checkpoint`; one row per real work session (trivial sessions under ~5 turns with no workflow usage write nothing). When host metering is unavailable, compute `Estimated payload` via heuristic (`turns × ~8k–15k tok/turn`) rather than emitting `not measured`.
