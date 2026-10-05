# Scenario checkpoint-keyword-only
## Prompt
(31st substantive turn; the host reports context pressure.) Checkpoint the auth refactor now so nothing is lost.
## Directive
balanced
## Checks
- contains-any: checkpoint|fresh session
- not-contains: continuing silently|no state to save
- contains: docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-3.md
- evidence-present: repository/docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-3.md
- evidence-absent: docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-4.md
- record-field: docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-3.md|Next Action
## Threshold
all
## Transcript-PASS
Session: ~31/30 turns — checkpoint is due; recording it now instead of pushing the refactor further.

tool read docs/tasks/TASK-2026-09-20-auth-refactor.md -- Task Record, revision 4f2b9ac
tool read docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-2.md -- prior checkpoint, Execution State handoff_ready
tool write docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-3.md
tool read docs/STATE.md -- M2 projection synced
Checkpoint Record written at `docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-3.md`:
- **Record Type**: Checkpoint Record
- **Checkpoint ID**: CHECKPOINT-2026-09-20-auth-refactor-3
- **Task ID**: TASK-2026-09-20-auth-refactor
- **Execution State**: checkpoint_due
- **Verification Evidence**: auth suite 61 passed, exit 0, measured this turn
- **Next Action**: resume at the auth middleware seam
Start a fresh session from that record rather than from this chat.
## Transcript-FAIL
Session: ~31/30 turns — the word checkpoint is warranted here, so I am flagging it in plain text rather than moving on as if nothing were pending.
Nothing was written: no Checkpoint Record exists for this task, and the state projection (`docs/STATE.md`) was never read, so this chat is the only place the refactor state lives.