# Session Checkpoint & Handover Workflow

## Fast Shorthand
Trigger anytime with: `pk:checkpoint` (or `/pk-checkpoint`, `pk:handoff`)

## Mission
Eliminate AI context window degradation, token lag, and instruction drift during extended pairing sessions. Compress the active working state into an architectural snapshot, persist progress into `docs/STATE.md` on disk, and generate a plug-and-play **Handover Prompt** that carries canonical task identity, authority, and stop/resume conditions into a fresh chat window. Nothing is preserved unconditionally: the receiver regains a task only as far as the cited records verify it, and a missing or conflicting boundary field leaves work blocked rather than assumed approved.

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
6. **Delegated & Assumed Decisions**: Every decision delegated via "you decide" or converted to an Assumption Record through Decision-Budget overflow (slug, choice taken, one-line rationale) — batch review beats interrupt review.

---

### Controlled & Release-Critical Work Checkpoint Contract

For Level 2 (Controlled) and Level 3 (Release-Critical) Work, checkpointing is a durable execution gate linking `docs/tasks/<task-id>.md` in addition to the existing workspace audit and handover prompt. Level 0 (Direct) and Level 1 (Standard) work update `docs/STATE.md` or session notes directly without requiring a Task Record file:

- **Default checkpoint policy**: request a **Soft Checkpoint** around 60 minutes after the active task starts and require a **Hard Checkpoint** at or before 90 minutes, unless the Task Record documents a different policy. Nudge at ~15 substantive turns, hard checkpoint at ~30 turns (L2/L3 hard-stop; L1 advisory with `pk:sync` disk-reload recovery for users who stay).
- **Session Fatigue Meter (estimate, never fake precision)**: when emitting telemetry, append `Session: ~<n>/30 turns — consider pk:checkpoint` as a labeled estimate. If turn count is unknown, write `Session: not measured`.
- Require event-driven checkpoints at major milestones, task switches, scope expansion, handoff, context compaction, or detected context drift (e.g. dropped callouts, missing telemetry, skipped `ask_question`).
- Record the configured thresholds and host capability. If the host cannot observe or forcibly stop live generation, record `POLICY_LIMITATION`; do not claim mechanical timer enforcement.
- A Checkpoint Record at `docs/tasks/<task-id>.checkpoint-<sequence>.md` must include task/specification identity, state, objective, completed and remaining work, changed files, branch/revision, decisions/invariants, verification/CI evidence, blockers, scope changes, and exactly one prioritized next action.
- `checkpoint_due`, `blocked`, `paused`, and `handoff_ready` are stop states. They prohibit implementation edits, commits, pull-request actions, and task switches until the recorded resume condition is satisfied. Read-only diagnosis may continue when it does not change project state.
- A Handoff Record at `docs/tasks/<task-id>.handoff-<sequence>.md` is required at a session/role boundary, handoff state, or major milestone. The receiver must validate the task ID, revision, changed files, acceptance criteria, invariants, blockers, and next action before editing.
- Scope changes require a linked Scope Change Record before changing objective, files, acceptance criteria, dependencies, non-goals, risk, or verification. Expansion requires human confirmation or a separate Task Record.
- Mid-implementation new requirements are intercepted, never silently absorbed, per the canonical New-Requirement Interception table in `workflows/sync.md` (doc-only appends, Scope Change Records, planning re-open with intake status `partial`, Later ledger).

Phase 4 may synchronize `docs/STATE.md`, but STATE is a projection owned by `pk:checkpoint`; the canonical `docs/tasks/<task-id>.md` Task Record remains the Local Task Source. At a session or role boundary, the receiver must validate the Task ID, revision, changed files, acceptance criteria, blockers, invariants, and exactly one next action before editing. A mismatch leaves execution blocked or `checkpoint_due` until reconciled.

#### State Mutation Contract (single arbitration rule)

Multiple workflows invoke STATE writes, but none invents STATE semantics. Section writers:

- **§2 Milestone & Task Progress**: `pk:tasks` (decomposition sync) and `pk:checkpoint` (phase sync).
- **§3 Working Set and §3A Execution-Control Projection**: `pk:checkpoint` stewards; `pk:tasks` contributes generated-spec links without rewriting other §3 content.
- **§4 Locked Invariants**: human-stated rules only, recorded via `pk:onboard` handoff or `pk:checkpoint` with recorded human approval. No workflow writes §4 from inference.
- **§4A Candidate Learnings**: any workflow may stage; promotion requires the recorded human decision per `protocols/context-sync.md` §3.1.
- **§§8–9 Session logs and spend**: the owning workflow appends.

Writers touch only their sections and never rewrite another writer's sections; conflicts surface to the human instead of being silently overwritten. The Task Record overrides STATE on any disagreement.

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

Record the complete workspace state before switching sessions, including intentional uncommitted changes:
- Verify no secrets (`.env`, tokens) were left untracked in working files.
- Verify whether temporary debug logging probes (`[DEBUG-xxxx]`) need cleanup or are intentionally active for the next turn.
- If there are uncommitted changes that represent a stable milestone, suggest running `pk:commit` before starting the new session; otherwise preserve them explicitly in the checkpoint record.

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
      `| YYYY-MM-DD (focus) | [turns] | [measured in/out or host telemetry unavailable] | [estimated context-payload range] | duration=[value]; repairs=[count or not tracked]; interventions=[count or not tracked]; verification=[result or not tracked]; outcome=[accepted/rejected/incomplete/blocked/not tracked] |`
      and refresh its Running-total line.
    - **Table Integrity Invariant**: Keep table rows strictly contiguous (zero blank lines between rows); escape literal pipes as `\|` (even in inline code or markers); format each row on a single physical line (use `<br>` for multi-line cells).
      - **Fallback Estimation Heuristic** (estimated column only — never substitute for measured evidence): If the host runtime does not expose live per-turn token metering (e.g. OpenCode, Cursor, Windsurf, Copilot, or Neovim), do **NOT** emit `not measured` for Estimated context payload. Compute the engineering range using the standard session formula:
        - Average cumulative turn context: `~8k–15k tok/turn` (prompt directives + conversation history + tool reads).
        - `Estimated context payload`: calculate the lower and upper bounds independently as `[turns × 8k]–[turns × 15k] tok`. For example, 15 turns yields `120k–225k heuristic context payload`. Do not collapse the range into a midpoint estimate.
        - In `Measured in/out`: write `host telemetry unavailable`.
        - In `Running total`: sum heuristic lower and upper bounds independently, but keep that range separate from any measured-token total. Never add measured tokens to a heuristic range or describe heuristic context payload as cumulative spend.
        - These figures are heuristic engineering estimates only: not provider billing telemetry, actual spend, or measured token counts. Preserve the Measured / Estimated / Unavailable distinction in every ledger row.
      - **Process Evidence**: Record duration, repair cycles, human interventions, verification, and outcome in the existing `Note` column. Use `not tracked` when evidence is unavailable; never infer `0`, `passed`, or `accepted`. Record avoided rework as `not measured` unless comparative evidence exists.
      - **Compatibility & Authority**: Preserve the five-column table and historical rows without silent backfill. Host transitions and cross-task conflict details belong in the Session Continuity Log or canonical Task Record, with only a concise reference here. The ledger is operational telemetry, not CPAC benchmark evidence; formal comparisons follow `docs/BENCHMARK-METHODOLOGY.md`.
      Per-turn card figures stay in chat history; the ledger is the only durable spend artifact.
    If `docs/STATE.md` does not yet exist, offer to scaffold it from `templates/state-tracker-template.md`.

2. **Generate Clean Handover Prompt**:
   Generate a self-contained, copy-pasteable prompt block formatted for a brand-new chat session.

   Section 1 through Section 6 are **required for every task**, including Level 0 (Direct) and Level 1 (Standard) work that has no Task Record file — record `N/A — no Task Record (Level 0/1)` explicitly rather than deleting the field. Section 7 stays optional and applies only to release-evaluation transfers.

   Field names mirror [`templates/execution-handoff-template.md`](../templates/execution-handoff-template.md) so the block is a **projection of the canonical records**, never a second source of truth. Populate every boundary field from the records themselves: a summary written here is not new authority, and a blank boundary field is not a default.

````markdown
### Handover Prompt for Fresh Chat Session

Copy and paste the block below into a new chat window. It carries the work forward only as far as the receiver can verify the cited records — it does not pre-approve anything:

```markdown
# Session Resume: [Task ID] — [Feature / Task Name]

## 1. Identity and Authority
- **Task ID**: `[TASK-YYYY-MM-DD-<slug> or N/A — no Task Record (Level 0/1)]`
- **Task Record (canonical)**: `docs/tasks/<task-id>.md` · **Specification**: `[path or N/A]`
- **Checkpoint / Handoff Records**: `[docs/tasks/<task-id>.checkpoint-<n>.md | .handoff-<n>.md | none]`
- **Approval Boundary**: `[who approved which action, and where that approval is recorded — cite the approval source; a narrative summary here is not new authority]`
- **Sender → Intended Receiver**: `[current session/role] → [fresh session/role]`
- **Branch / Validated Revision**: `[branch]` @ `[commit]`
- **Changed Files**: `[path — state]`, including intentional uncommitted work (`git status -s` at handoff time)

## 2. Objective, Milestone, and Execution State
- **Milestone / Objective**: `[milestone]` — `[one observable objective]`
- **Execution State**: `[in_progress | checkpoint_due | blocked | paused | handoff_ready | awaiting_review]`
- **Completed**: `[milestone or AC-* and its evidence]`
- **Remaining**: `[AC-* IDs and what is left]`
- **Acceptance Criteria**: `[AC-* → condition to satisfy]`
- **Locked Technical Invariants (Do Not Undo)**: `[invariant — how it is verified]`

## 3. Blockers, Pending Human Actions, and Resume Condition
- **Blockers and Resume Conditions**: `[blocker, owner, evidence, and precise condition, or None]`
- **Pending Human Actions**: `[decision or sign-off awaited, and from whom, or None]`
- **Resume Condition**: `[the one condition that lifts the stop state]`
- **Scope and Approval Constraints**: `[what the receiver must not change without a Scope Change Record]`

## 4. Verification Evidence
- **Command → Result @ Revision**: `[command]` → `[exit code and result]` @ `[revision it was measured at]`
- **Historical or current?**: `[current — measured this turn | historical — from <revision/date>, NOT re-run this turn]`
- **Not Verified**: `[gates still open or unmeasured, or None]`

## 5. Next Action (exactly one)
- [Exactly one prioritized action]

## 6. Receiver Validation — complete before any edit
- [ ] **Task identity**: Task ID and specification match the Task Record.
- [ ] **Revision**: workspace matches the validated revision, or the difference is recorded.
- [ ] **Changed files**: current file set matches this block, or discrepancies are recorded.
- [ ] **Acceptance and invariants**: remaining `AC-*` criteria, locked decisions, and scope constraints are understood.
- [ ] **Blockers**: blockers, pending human actions, and the resume condition are still valid.
- [ ] **Next action**: exactly one next action is accepted without implicit scope expansion.

Missing, conflicting, or stale identity/authority fields do **not** default to approval or task completion: stay `blocked` or `checkpoint_due` and reconcile with the human first. Record the reconciliation in the Handoff Record. Read-only diagnosis may continue while blocked; do not rewrite scope, invariants, or acceptance criteria from inference.

## 7. Optional Release-Evaluation Handoff
- **Evaluation ID**: [Stable evaluation identifier or N/A]
- **Release Candidate Commit**: [Exact candidate revision or N/A]
- **Preliminary SemVer Candidate**: [Candidate version or no candidate] (status: `preliminary`, not approved)
- **QA Status**: [QA/Reviewer result, findings reference, and review state or N/A]
- **Unresolved Blockers**: [Named blocker, owner, and resolution condition, or none recorded]
- **Requested Release Coordinator Decision**: [One explicit next human action or N/A]
- **Source Evaluation / Task Record**: [Authoritative record paths or N/A]
- **Handoff Status**: [Ready for Coordinator Review | Blocked | Deferred | N/A]

Read the canonical records above, reconcile any discrepancy, and confirm before editing. A receiver may also recover the projection by typing `pk:route` per `protocols/context-sync.md` §8; this block additionally carries the identity, authority, and stop/resume fields that the `docs/STATE.md` projection alone does not.
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

> 📊 **Milestone**: M2: Auth & Invitations `[■■■■■■■■□□]` 8/10 (80%) — source: `docs/STATE.md`  
> 🎯 **Active**: TASK-304-invite-verification (In Progress)  
> 🟢 **Quality Gate**: 12 passed, 0 failed · `tsc --noEmit` exit 0  

> [!TIP]
> ### 💡NEXT STEPS (Type number & Enter):
> 1. **(Recommended)** Resume in fresh chat using the Handover Prompt below.
> 2. Continue in current session: implement server action barrier (`src/server/actions/invite.ts`).

### Ready-to-Paste Handover Prompt for New Chat:

Ordinary task, so the optional release-evaluation fragment (§7) is omitted — Sections 1–6 carry the same identity, authority, and stop/resume fields a release handoff would.

```markdown
# Session Resume: TASK-304-invite-verification — Email Verification Invariant

## 1. Identity and Authority
- **Task ID**: `TASK-304-invite-verification`
- **Task Record (canonical)**: `docs/tasks/TASK-304-invite-verification.md` · **Specification**: `docs/auth/email-verification-matrix.md`
- **Checkpoint / Handoff Records**: `docs/tasks/TASK-304-invite-verification.checkpoint-1.md` · no handoff record yet
- **Approval Boundary**: human approved the `email_verified_at` migration and the 403 barrier shape in `docs/tasks/TASK-304-invite-verification.md` §1; the M2 milestone sign-off is **not** granted, so no commit or PR action is authorized.
- **Sender → Intended Receiver**: `Antigravity (executor)` → `fresh session`
- **Branch / Validated Revision**: `feature/email-verification` @ `9312b1a`
- **Changed Files**: `db/migrations/20260906_add_email_verified_at.sql` (committed at `9312b1a`), `docs/auth/email-verification-matrix.md` (committed), `tests/auth/verify-email.test.ts` (committed), `src/server/actions/invite.ts` (uncommitted, untouched)

## 2. Objective, Milestone, and Execution State
- **Milestone / Objective**: M2: Auth & Invitations — unverified invitees are rejected at the server action.
- **Execution State**: `awaiting_review`
- **Completed**: migration `email_verified_at` added; auth matrix updated; unit tests added.
- **Remaining**: `AC-2` — enforce the barrier inside `inviteUser`; `AC-3` — integration test for the 403 path.
- **Acceptance Criteria**: `AC-2` server rejects unverified invitees; `AC-3` `tests/auth/invite-verification.test.ts` asserts `ERR_EMAIL_UNVERIFIED`.
- **Locked Technical Invariants (Do Not Undo)**: unverified users receive 403 `ERR_EMAIL_UNVERIFIED`; verification reads the server session, never client props.

## 3. Blockers, Pending Human Actions, and Resume Condition
- **Blockers and Resume Conditions**: milestone sign-off pending — owner: human approver; evidence: `docs/tasks/TASK-304-invite-verification.md` §5 `awaiting_review`.
- **Pending Human Actions**: decide the M2 milestone sign-off.
- **Resume Condition**: the human accepts the recorded migration and matrix, or names a change; until then no commit, PR, or milestone advance.
- **Scope and Approval Constraints**: stay inside `docs/tasks/TASK-304-invite-verification.md` scope; the 403 contract change needs a Scope Change Record, not an inline edit.

## 4. Verification Evidence
- **Command → Result @ Revision**: `pnpm vitest run tests/auth/verify-email.test.ts` → `12 passed, 0 failed`, exit 0 @ `9312b1a`
- **Historical or current?**: historical — measured this session before the handoff at `9312b1a`; **not** re-run against the uncommitted `invite.ts`
- **Not Verified**: integration path for `inviteUser` (no test exists yet), full suite, `tsc --noEmit`

## 5. Next Action (exactly one)
- Add the verification barrier inside `inviteUser` (`src/server/actions/invite.ts`) — read-only diagnosis allowed first.

## 6. Receiver Validation — complete before any edit
- [ ] **Task identity**: `TASK-304-invite-verification` and the spec path match the Task Record.
- [ ] **Revision**: workspace is at `9312b1a` with `invite.ts` uncommitted, or the difference is recorded.
- [ ] **Changed files**: the four files above match the working tree.
- [ ] **Acceptance and invariants**: `AC-2`/`AC-3` and the 403 contract are understood.
- [ ] **Blockers**: sign-off is still pending and the resume condition is unchanged.
- [ ] **Next action**: the single `inviteUser` barrier action is accepted without scope expansion.
```
````

---

## Post-Merge Synchronization Hook

When the human informs the assistant that a pull request has been merged into `main`, execute the post-merge synchronization procedure:

1. **Verify Workspace State**:
   Inspect the working tree (`git status -s`). If uncommitted changes exist for another active task in the current workspace, stash or preserve them before switching branches.
2. **Switch to Main & Pull Latest**:
   ```bash
   git checkout main && git pull origin main
   ```
3. **Prune Merged Local Branch**:
   Safely delete the merged local feature branch:
   ```bash
   git branch -d <feature-branch>
   ```
4. **Synchronize Task & `docs/STATE.md` (Scope-Matching)**:
   - Identify the specific merged task (e.g. `TASK-XX` / `<task-id>`) associated with the merged PR.
   - Reconcile canonical completion evidence in its Task Record (`docs/tasks/<task-id>.md`) if controlled work (L2/L3).
   - Mark the completed task (`- [x] TASK-XX: ...`) in the active milestone in `docs/STATE.md`.
   - Update Section 3 (`Active Working Set`): if the merged task owns the current active working set, reset Section 3 for the next task; if an unrelated task occupies the working set, preserve its entries and update only the projection for the merged task.
   - Append a completion record to Section 8 (`Session Continuity Log`):
     `| YYYY-MM-DD | Assistant (pk:checkpoint) | Post-Merge Sync | PR for <task-id> merged into main; pulled latest and pruned local branch |`

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
- Canonical record schemas projected by the handover prompt: [`templates/execution-handoff-template.md`](../templates/execution-handoff-template.md), [`templates/execution-task-record-template.md`](../templates/execution-task-record-template.md), [`templates/state-tracker-template.md`](../templates/state-tracker-template.md)
- Fresh-session recovery paths: [`protocols/context-sync.md`](../protocols/context-sync.md) (§8 threshold and reconnect) and [`workflows/sync.md`](sync.md) (post-compaction re-entry)
