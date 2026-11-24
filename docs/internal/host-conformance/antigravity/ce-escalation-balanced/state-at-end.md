# Project State & Living Execution Tracker

## 1. Executive Summary & Current Position
- **Project Name**: [Project Name]
- **Current Milestone / Epic**: [e.g., Milestone 2: Core Domain Engine]
- **Overall Status**: [ACTIVE | PAUSED | STABILIZING | RELEASE_CANDIDATE | COMPLETED] <!-- ACTIVE while work is in flight; COMPLETED only when all milestones closed, release evidence archived, zero open blockers — recording stops here -->
- **Target Release / Deadline**: [e.g., v1.0.0 / YYYY-MM-DD]
- **Current Working Branch**: [e.g., main or feature/branch-name]
- **Last Updated**: [YYYY-MM-DD]
- **Engine Version**: unknown @ unknown

---

## 2. Milestone & Task Progress

### Milestone Roadmap
- [/] **Milestone 1**: Extend JWT session lifetime in auth subsystem

### Active Milestone Task Breakdown
Track tasks using atomic checklists (`[x]` Done, `[/]` In Progress, `[ ]` Queued, `[!]` Blocked):

- [x] **TASK-2026-11-24-jwt-lifetime**: Extend JWT lifetime in src/auth/session.ts from 1h to 24h

---

## 3. Active Working Set
- **Target Workspace / Package (if Monorepo)**: Standalone repository
- **Active RFC / Spec**: `docs/specs/2026-11-24-auth-session-lifetime.md`
- **Active Task Spec**: `docs/tasks/TASK-2026-11-24-jwt-lifetime.md`
- **Key Source Files in Flight**: `src/auth/session.ts`
- **Verification Commands (Scoped)**:
  - Unit Tests: N/A
  - Typecheck: `npx --yes typescript --noEmit src/auth/session.ts src/api/refresh.ts src/api/tokens.ts src/web/session-client.ts`
  - Linter: N/A

---

## 3A. Execution-Control Projection (Optional)

> This section is a synchronized projection for checkpoint continuity when the host project uses Controlled Work. The canonical authority remains `docs/tasks/<task-id>.md`; disagreement with that record is a validation failure and leaves execution blocked or `checkpoint_due` until reconciled. When a field carries verbatim command output containing a pipe character (for example a validator summary `VALID|RECORDS=28`), escape it as `\|` inside markdown table cells so the table does not read it as a column separator; it then renders as the verbatim `|`.

- **Local Task Source**: `docs/tasks/TASK-2026-11-24-jwt-lifetime.md`
- **Task ID**: `TASK-2026-11-24-jwt-lifetime`
- **Task Record**: `docs/tasks/TASK-2026-11-24-jwt-lifetime.md`
- **Ceremony Level**: `Level 2 (Controlled)`
- **Specification**: `docs/specs/2026-11-24-auth-session-lifetime.md`
- **Execution Scope**: `Standalone repository (/src/auth, /src/api, /src/web)`
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Owner / Current Actor**: `heyloey`
- **Start Time**: `2026-11-24 10:15 UTC`
- **Current Branch**: `main`
- **Current Revision**: `c4a9d62`
- **Checkpoint Policy**: `Soft checkpoint at 60m, hard checkpoint at 90m; live host timing or forced mechanical termination is unavailable`
- **Blockers and Resume Condition**: `None`
- **Verification Status**: `npx --yes typescript --noEmit exit code 0 at 2026-11-24 10:19 UTC`
- **CI Evidence**: `N/A`
- **Changed-File Summary**: `src/auth/session.ts: updated jwtExpiry constant from 1h to 24h`
- **Latest Checkpoint**: `None`
- **Latest Handoff**: `None`
- **Next Action**: `Human review and approval of the 24h lifetime change and quality gate results`

#### Field-mapping (checkpoint labels)

| Label | Quick (L1) required | From /handoff payload | Derivable from local git | Degrades to (when unmappable) |
| :--- | :--- | :--- | :--- | :--- |
| Record Type | yes | no | no | n/a |
| Checkpoint ID | yes | no | no | n/a |
| Task ID | no | yes | no | TRACEABILITY_MISSING (full); `N/A — no Task Record (Level 0/1)` (quick) |
| Specification | no | yes | no | POLICY_LIMITATION |
| Created | yes | partial | yes | n/a |
| Checkpoint Type | no | no | no | POLICY_LIMITATION |
| Execution State | yes | yes | no | not measured |
| Objective | yes | yes | no | not measured |
| Completed Work | no | partial | no | not measured |
| Remaining Work | yes | partial | no | not measured |
| Changed Files | no | yes | yes | not measured |
| Branch / Revision | no | yes | yes | n/a |
| Locked Decisions and Invariants | no | yes | no | not measured |
| Verification Evidence | no | yes | no | not measured |
| CI Evidence | no | partial | no | POLICY_LIMITATION |
| Blockers | yes | partial | no | not measured |
| Scope Changes | no | partial | no | not measured |
| Next Action | yes | yes | no | not measured |
| Resume Condition | yes | partial | no | not measured |
| Recorded By | yes | no | no | POLICY_LIMITATION |

The importer emits a `Ceremony Level` line in every draft whose level is known, so a `quick` draft re-validates at the quick tier. Level 0 payloads are refused (`REFUSED-L0`); unlabeled payloads default fail-closed to the `full` tier. Verdicts: `QUICK-VALID` (all ten quick labels resolve at Level 1; unresolved full-only labels degrade via `POLICY_LIMITATION` and are never reported as full-valid), `FULL-VALID` (all 20 labels and a resolvable Task ID), otherwise `DRAFT-INCOMPLETE`. The exit status is 0 only for `QUICK-VALID` or `FULL-VALID`. A resolvable linked Task Record owns the tier: a lower payload claim is flagged as a downgrade (`POLICY_LIMITATION`) and the draft takes the record's level. A supplied `Task ID` that does not resolve, or a `Checkpoint ID` that is not a stable canonical ID, stays visible in the draft and counts as unresolved, so canonical re-validation reports the same failure.

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
Document non-negotiable architectural decisions agreed upon during pairing sessions. Every **actual invariant entry** is a human-approved rule that carries an inline source: a confirmed decision ID (`DECISION-*`) or an explicit pre-existing project policy (`policy:` plus a project-relative path). An entry without one of those two sources is not an invariant.

**Illustrative syntax — not invariant entries.** The fenced lines below show only the required `source:` shape. They are placeholders, not locked or human-approved rules, and must never be copied into a tracker as policy:

```text
<invariant> — source: DECISION-<spec-slug>-<nnn>
<invariant> — source: policy: <project-relative path>
```

A candidate learning, derived PromptKit baseline, or unverified recommendation is never human-approved or locked without one of those sources. Keep it in §4A until the human decision is recorded (`protocols/context-sync.md` §3.1).

A contradiction between a detected project document and a confirmed decision is not a §4 entry: the Intake Record owns those divergence rows (`protocols/discovery-intake.md` §G). A precedence statement about a detected project document belongs in §4 only when a human approved it and it cites its `DIVERGENCE-*` row or policy path; an unsupported override claim stays out of the tracker.

**Empty state — not an invariant entry.** Until a pairing session locks a real decision, leave §4 without entry bullets; keep only this guidance and never pre-fill an entry.

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
<!-- Table Invariant: Keep rows strictly contiguous without blank lines; escape literal pipes as \|; use <br> for multi-line cells -->

| Date | Engineer / Agent | Milestone / Focus | Key Changes & Artifacts |
| :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked |

---

## 9. Session Spend Ledger
<!-- Table Invariant: Keep rows strictly contiguous without blank lines; escape literal pipes as \|; use <br> for multi-line cells -->

| Session | Turns | Measured in/out | Estimated context payload | Note |
| :--- | :--- | :--- | :--- | :--- |
| not tracked | not tracked | not tracked | not tracked | not tracked |

- **Running total**: not tracked — refreshed by `pk:checkpoint`; keep measured tokens and heuristic context-payload ranges as separate totals and never add them together. One row per real work session (trivial sessions under ~5 turns with no workflow usage write nothing). When host metering is unavailable, compute the lower and upper bounds independently via the heuristic (`turns × 8k` through `turns × 15k tok/turn`) rather than emitting a midpoint or `not measured`.
- **Note evidence**: use `duration=<value>; repairs=<count or not tracked>; interventions=<count or not tracked>; verification=<result or not tracked>; outcome=<accepted | rejected | incomplete | blocked | not tracked>`. Never infer `0`, `passed`, or `accepted` from missing evidence.
- **Evidence boundary**: this ledger is operational telemetry, not CPAC benchmark evidence. Heuristic context payload is not provider billing telemetry or actual spend; avoided rework remains `not measured` without comparative evidence. Preserve historical rows and the five-column shape without silent backfill.
