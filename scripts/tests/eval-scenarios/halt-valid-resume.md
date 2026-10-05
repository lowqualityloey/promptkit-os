# Scenario halt-valid-resume
## Prompt
New session. The migration was blocked on a dead test database; I have restarted it. Carry on with M1.
## Directive
balanced
## Checks
- contains: docs/tasks/TASK-2026-09-20-m1-init.md
- contains: docs/tasks/TASK-2026-09-20-m1-init.checkpoint-1.md
- contains: docs/STATE.md
- contains: AGENTS.md
- contains-any: ^tool read|this turn
- evidence-order: docs/tasks/TASK-2026-09-20-m1-init.md|docs/tasks/TASK-2026-09-20-m1-init.checkpoint-1.md|docs/STATE.md|AGENTS.md
- evidence-absent: docs/tasks/TASK-2026-09-20-m1-init.handoff-2.md
- evidence-present: state-at-end.md
- not-contains: from the summary alone
## Threshold
all
## Transcript-PASS
Recorded stop, replayed from the canonical record: migration blocked, `DATABASE_URL` empty; resume condition is a `retry` reply after the database is restarted.
Human reply recorded this turn: `retry` — it resolves that recorded action only and does not widen scope.

tool read docs/tasks/TASK-2026-09-20-m1-init.md -- Task Record, revision a91c0de, frozen scope intact
tool read docs/tasks/TASK-2026-09-20-m1-init.checkpoint-1.md -- Resume Condition met, Next Action: apply the M1 migration
tool read docs/STATE.md -- M1 in progress, M2 pending human sign-off
tool read AGENTS.md -- installed root directives
Reconciled before any write: the Task Record is canonical, the STATE projection agrees, and the resume condition is satisfied. One next action — apply the M1 migration.

tool exec npm run migrate -- applied 20260920_m1_init.sql, exit 0
## Transcript-FAIL
Resuming from the summary alone: the previous session said the database was down, so I am carrying straight on without re-reading the records.

tool exec npm run migrate -- applied 20260920_m1_init.sql, exit 0
tool write docs/tasks/TASK-2026-09-20-m1-init.handoff-2.md -- Handoff Record written to mark the new session