# Session Checkpoint & Handover Workflow

## Fast Shorthand
Trigger anytime with: `pk:checkpoint` (or `/pk-checkpoint`, `pk:handoff`)

## Mission
Eliminate AI context window degradation, token lag, and instruction drift during extended pairing sessions. Compress the active working state into an architectural snapshot, persist progress into `docs/STATE.md` on disk, and generate a plug-and-play **Handover Prompt** to resume work in a fresh chat window with zero lost context.

---

## Preconditions & When to Checkpoint
- **Milestone Completion**: A project milestone, epic, or major feature phase has completed; state must be synchronized to `docs/STATE.md` and working changes staged/committed before advancing to the next milestone.
- **Context Saturation**: The active chat session has exceeded 20-30 turns, or the assistant is exhibiting token lag or memory drift.
- **Task Switch / Boundary**: The developer is switching tasks, ending work for the day, or handing off to another engineer or agent.

---

## 4-Phase Checkpoint Protocol

```text
┌─────────────────────────────────────────────────────────────┐
│                  PK:CHECKPOINT LIFECYCLE                    │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ Phase 1:     │ Phase 2:     │ Phase 3:     │ Phase 4:       │
│ Workspace    │ Invariant &  │ Pre-Handover │ State Sync &   │
│ Delta Audit  │ State Synthe │ Hygiene Scan │ Handover Gen   │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

---

### Phase 1: Workspace Delta Audit

Before summarizing, inspect the physical state of the repository:

1. **Branch & Recent Commit**:
   ```bash
   git branch --show-current
   git log -n 1 --oneline
   ```
2. **Uncommitted Modifications**:
   ```bash
   git status -s
   git diff --stat
   ```
3. **Active Test Suite Status**:
   Verify whether tests are currently passing, failing (expected red loop in `pk:debug`), or unverified.

---

### Phase 2: Invariant & State Synthesis

Extract and structure the 5 vital signals of the session:

1. **Core Objective**: What was the primary business or engineering problem being solved?
2. **Completed Milestones**: What was implemented and verified during this session? (Specific files created, endpoints added, schemas migrated).
3. **Locked Architectural Invariants**: What non-negotiable decisions were agreed upon that the next session must not undo? (e.g., "Using UUIDv7 keys", "HttpOnly cookie sessions instead of localStorage", "Zod boundary schemas").
4. **Active Blockers & Open Questions**: What is currently unresolved, failing, or pending user input?
5. **Immediate Next Step**: Exactly what should the very next prompt or turn accomplish?

---

### Controlled & Release-Critical Work Checkpoint Contract

For Level 2 (Controlled) and Level 3 (Release-Critical) Work, checkpointing is a durable execution gate linking `docs/tasks/<task-id>.md` in addition to the existing workspace audit and handover prompt. Level 0 (Direct) and Level 1 (Standard) work update `docs/STATE.md` or session notes directly without requiring a Task Record file:

- Request a **Soft Checkpoint** around 60 minutes after the active task starts and require a **Hard Checkpoint** at or before 90 minutes, unless the Task Record documents a different policy. Nudge at ~15 substantive turns, hard checkpoint at ~30 turns (L2/L3 hard-stop; L1 advisory with `pk:sync` disk-reload recovery for users who stay).
- **Session Fatigue Meter (estimate, never fake precision)**: when emitting telemetry, append `Session: ~<n>/30 turns — consider pk:checkpoint` as a labeled estimate. If turn count is unknown, write `Session: not measured`.
- Require event-driven checkpoints at major milestones, task switches, scope expansion, handoff, context compaction, or detected context drift (e.g. dropped callouts, missing telemetry, skipped `ask_question`).
- Record the configured thresholds and host capability. If the host cannot observe or forcibly stop live generation, record `POLICY_LIMITATION`; do not claim mechanical timer enforcement.
- A Checkpoint Record at `docs/tasks/<task-id>.checkpoint-<sequence>.md` must include task/specification identity, state, objective, completed and remaining work, changed files, branch/revision, decisions/invariants, verification/CI evidence, blockers, scope changes, and exactly one prioritized next action.
- `checkpoint_due`, `blocked`, `paused`, and `handoff_ready` are stop states. They prohibit implementation edits, commits, pull-request actions, and task switches until the recorded resume condition is satisfied. Read-only diagnosis may continue when it does not change project state.
- A Handoff Record at `docs/tasks/<task-id>.handoff-<sequence>.md` is required at a session/role boundary, handoff state, or major milestone. The receiver must validate the task ID, revision, changed files, acceptance criteria, invariants, blockers, and next action before editing.
- Scope changes require a linked Scope Change Record before changing objective, files, acceptance criteria, dependencies, non-goals, risk, or verification. Expansion requires human confirmation or a separate Task Record.
- Mid-implementation new requirements are intercepted, never silently absorbed: documentation-only deltas append to the intake record and `PROMPTKIT.md` signals; scope or acceptance-criteria changes require the Scope Change Record above; architecture, data-model, auth, or deployment-target changes block execution (`blocked` / `checkpoint_due`) and re-open planning via `pk:plan` with intake status returned to `partial`; unsolicited ideas go to the intake record's **Later ledger**.

Phase 4 may synchronize `docs/STATE.md`, but STATE is a projection owned by `pk:checkpoint`; the canonical `docs/tasks/<task-id>.md` Task Record remains the Local Task Source. At a session or role boundary, the receiver must validate the Task ID, revision, changed files, acceptance criteria, blockers, invariants, and exactly one next action before editing. A mismatch leaves execution blocked or `checkpoint_due` until reconciled.

---


### Optional Release-Evaluation Handoff

When a PromptKit OS release evaluation is being handed from QA/Reviewer to a Release Coordinator, include this optional fragment in the existing Checkpoint Record, Handoff Record, and applicable `docs/STATE.md` projection. The canonical release evaluation and Local Task Record remain authoritative; this fragment is a handoff projection, not a new approval record.

- **Evaluation ID**: `[stable release-evaluation identifier or N/A]`
- **Release Candidate Commit**: `[exact PromptKit OS candidate revision or N/A]`
- **Preliminary SemVer Candidate**: `[candidate version or no candidate]` with status `preliminary`
- **QA Status**: `[QA/Reviewer result, findings reference, and review state or N/A]`
- **Unresolved Blockers**: `[named blocker, owner, and resolution condition, or none recorded]`
- **Requested Release Coordinator Decision**: `[one explicit next human action, such as proceed to pk:ship for approval review, resolve blockers and re-review, defer, or record a no-contract-change decision]`
- **Source Evaluation / Task Record**: `[authoritative evaluation and task-record paths or N/A]`
- **Handoff Status**: `[Ready for Coordinator Review | Blocked | Deferred | N/A]`

The Preliminary SemVer Candidate is not an Approved Release Version. A checkpoint handoff, QA status, empty blocker list, or requested decision does not approve a candidate. `pk:checkpoint` must not create or push tags, create hosted releases, publish changelogs, perform remote operations, deploy, or roll back. Final release evaluation and approval remain with `pk:ship` and the Release Coordinator.

---

### Phase 3: Pre-Handover Hygiene Scan

Ensure the workspace is in a clean state before switching sessions:
- Verify no secrets (`.env`, tokens) were left untracked in working files.
- Verify whether temporary debug logging probes (`[DEBUG-xxxx]`) need cleanup or are intentionally active for the next turn.
- If there are uncommitted changes that represent a stable milestone, suggest running `pk:commit` before starting the new session.

---

### Phase 4: docs/STATE.md Sync & Handover Prompt Generation

1. **Synchronize docs/STATE.md on Disk**:
   If `./docs/STATE.md` exists in the host repository, update it to preserve session progress in git:
   - Check off completed tasks in Section 2 (`- [x] TASK-XX: ...`).
   - Update `Last Updated` date and overall status.
   - Update Section 3 (`Active Working Set`) with files in flight and test commands.
   - Record newly agreed-upon non-negotiables in Section 4 (`Locked Technical Invariants`) — only rules with a recorded human approval. Inferred or tentative rules go to Section 4A as **Candidate Learnings** with status `pending` under the memory-vs-policy boundary (`protocols/context-sync.md` §3.1); checkpointing, persistence, and rereading never promote them.
   - Record active blockers in Section 5 (`Known Blockers, Risks & Open Questions`).
   - Set the prioritized next tasks in Section 7 (`Next Immediate Actions`).
    - Append an entry to Section 8 (`Session Continuity Log`):
      `| YYYY-MM-DD | [Agent/Author] | [Active Task/Milestone] | [Summary of work & decisions] |`
    - Append one row to the Session Spend Ledger (new Section 9 in the state template; skip trivial sessions under ~5 turns with no workflow usage):
      `| YYYY-MM-DD (focus) | [turns] | [measured in/out or not measured] | [~estimated payload] | [host usage source or why not measured] |`
      and refresh its Running-total line. Per-turn card figures stay in chat history; the ledger is the only durable spend artifact.
    If `docs/STATE.md` does not yet exist, offer to scaffold it from `templates/state-tracker-template.md`.

2. **Generate Clean Handover Prompt**:
   Generate a self-contained, copy-pasteable prompt block formatted for a brand-new chat session:

````markdown
### Handover Prompt for Fresh Chat Session

Copy and paste the block below into a new chat window to resume work with zero lost context:

```markdown
# Session Resume: [Feature / Task Name]

## 1. Context & Environment
- **Branch**: `[branch-name]` at commit `[commit-hash]`
- **Active Task**: [1-sentence summary of the active task]
- **Current Status**: [e.g., Schema migrated, backend endpoints complete, frontend pending]

## 2. Key Files to Inspect
- `[path/to/file1.ts]`: [Role of this file]
- `[path/to/file2.ts]`: [Role of this file]
- `docs/[specs|data|auth]/...md`: [Active design spec or matrix]

## 3. Locked Technical Invariants (Do Not Undo)
- [Invariant 1, e.g., All database tables use UUIDv7 primary keys]
- [Invariant 2, e.g., Auth sessions require HttpOnly, SameSite=Lax cookies]
- [Invariant 3, e.g., Presentation components must not contain business logic]

## 4. Current State & Immediate Next Step
- **What is done**: [Brief list of completed work]
- **Next immediate action**: [Exact next task to execute]

## 5. Optional Release-Evaluation Handoff
- **Evaluation ID**: [Stable evaluation identifier or N/A]
- **Release Candidate Commit**: [Exact candidate revision or N/A]
- **Preliminary SemVer Candidate**: [Candidate version or no candidate] (status: `preliminary`, not approved)
- **QA Status**: [QA/Reviewer result, findings reference, and review state or N/A]
- **Unresolved Blockers**: [Named blocker, owner, and resolution condition, or none recorded]
- **Requested Release Coordinator Decision**: [One explicit next human action or N/A]
- **Source Evaluation / Task Record**: [Authoritative record paths or N/A]
- **Handoff Boundary**: [This is a handoff projection only; final approval belongs to `pk:ship` and the Release Coordinator. No tag, release, publication, remote, deployment, or rollback action is authorized.]

Please inspect the files listed above and confirm you are ready to proceed with the next step.
```
````

---

## Example Checkpoint Output

### Example: Handing off mid-way through an auth migration

````markdown
[PromptKit OS: Session Checkpoint Generated]
[PromptKit OS: Synced session updates to docs/STATE.md]

### Session Summary
* **Objective**: Add email verification invariant to team invite flow.
* **Completed**:
  * Added `email_verified_at` timestamp to `users` table via migration `20260906_add_email_verified_at.sql`.
  * Updated `auth-matrix-template.md` in `docs/auth/email-verification-matrix.md`.
  * Unit tests passing in `tests/auth/verify-email.test.ts`.
* **Pending**: Adding verification barrier in the `inviteUser` server action.

### Ready-to-Paste Handover Prompt for New Chat:

```markdown
# Session Resume: Email Verification Invariant

## 1. Context & Environment
- **Branch**: `feature/email-verification` at commit `9312b1a`
- **Active Task**: Implement verification gate on team invite server action
- **Current Status**: Database migration and auth spec complete; server action update pending

## 2. Key Files to Inspect
- `src/server/actions/invite.ts`: Target server action to protect
- `docs/auth/email-verification-matrix.md`: Auth capability matrix
- `tests/auth/verify-email.test.ts`: Verified test cases

## 3. Locked Technical Invariants
- Unverified users must receive 403 Forbidden with `ERR_EMAIL_UNVERIFIED`
- All verification checks happen on the server session, never trusted from client props

```
````

---

## Post-Merge Synchronization Hook

When the human informs the assistant that a pull request has been merged into `main`, execute the post-merge synchronization procedure:

1. **Switch to Main & Pull Latest**:
   ```bash
   git checkout main && git pull origin main
   ```
2. **Prune Merged Local Branch**:
   Safely delete the merged local feature branch:
   ```bash
   git branch -d <feature-branch>
   ```
3. **Synchronize `docs/STATE.md`**:
   - Mark the completed task (`- [x] TASK-XX: ...`) in the active milestone.
   - Reset Section 3 (`Active Working Set`) for the next task.
   - Append a completion record to Section 8 (`Session Continuity Log`):
     `| YYYY-MM-DD | Assistant (pk:checkpoint) | Post-Merge Sync | PR merged into main; pulled latest and pruned local branch |`

---

## Project Closeout Record (COMPLETED transition)

When the developer declares the project finished and `docs/STATE.md` Overall Status moves to `COMPLETED` (all milestones closed, release evidence archived, zero open blockers), seal the spend ledger with a closeout record at the end of `docs/STATE.md`:

```markdown
## Project Closeout (Definition of Done)
- **Completed**: [YYYY-MM-DD] · **Scope delivered**: [milestones shipped]
- **Measured spend**: [in/out totals with per-session sources, or not measured]
- **Estimated spend**: [sum of per-task payloads for work done]
- **Variance**: [measured vs estimated on measured sessions, or not measurable]
- **Gates held**: [contract suite, budgets, references at closeout SHA]
```

No further ledger rows accumulate after `COMPLETED`. This record is the receipt the efficiency claims reconcile against — estimated vs measured, in one place.

---

## Related References
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md)
