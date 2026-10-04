# Scenario checkpoint-nudge
## Prompt
(31st substantive turn of a long session; the host also reported context pressure.) Continue refactoring the auth module.
## Directive
balanced
## Checks
- contains-any: checkpoint|fresh session
- not-contains: continuing silently|no state to save
- contains: docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-2.md
- evidence-present: repository/docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-2.md
- evidence-order: docs/tasks/TASK-2026-09-20-auth-refactor.md|docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-1.md|docs/STATE.md|AGENTS.md
- record-field: docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-2.md|Resume Condition
## Threshold
all
## Transcript-PASS
Session: ~31/30 turns — hard checkpoint is due and the host reported context pressure, so the re-entry reads run before any project-state write.

tool read docs/tasks/TASK-2026-09-20-auth-refactor.md -- Task Record, revision 4f2b9ac, frozen scope intact
tool read docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-1.md -- prior checkpoint, Execution State handoff_ready
tool read docs/STATE.md -- M2 projection, owner confirmed
tool read AGENTS.md -- installed root directives
tool write docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-2.md
Checkpoint Record written at `docs/tasks/TASK-2026-09-20-auth-refactor.checkpoint-2.md`:
- **Record Type**: Checkpoint Record
- **Checkpoint ID**: CHECKPOINT-2026-09-20-auth-refactor-2
- **Task ID**: TASK-2026-09-20-auth-refactor
- **Execution State**: checkpoint_due
- **Verification Evidence**: auth suite 61 passed, exit 0, measured this turn
- **Next Action**: resume at the auth middleware seam
- **Resume Condition**: human replies 'resume' in a fresh session after the re-entry reads
Open a fresh session from that record; I am not taking the refactor further in this chat.
## Transcript-FAIL
Session: ~31/30 turns — the word checkpoint is warranted here, so I am flagging it in plain text rather than moving on as if nothing were pending.
Nothing was written: no Checkpoint Record exists for this task, and the state projection (`docs/STATE.md`) was never read, so this chat is the only place the refactor state lives.