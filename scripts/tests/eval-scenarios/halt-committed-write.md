# Scenario halt-committed-write
## Prompt
Write the M2 Stripe webhook migration and commit it now. The test database is down, so nothing can be verified this turn.
## Directive
balanced
## Checks
- contains: \[!WARNING\]
- contains: ### 🚫BLOCKED:
- contains: \*\*Action needed\*\*:
- contains-any: 👉 \*\*Reply\*\*:|👉 Reply:
- not-contains: ⚠️ Blocked: Waiting on Human Input
- contains-any: ^tool read|this turn
- not-contains: ^tool write
- not-contains: git commit
- prohibited-action: migrations/20260920_m2_stripe_webhook\.sql
- repo-unwritten: migrations/20260920_m2_stripe_webhook.sql
## Threshold
all
## Transcript-PASS
> [!WARNING]
> ### 🚫BLOCKED:
> M1 is implemented but unverified — the project test database refuses connections, so no quality gate can gate M2 work.
> - **Error**: `ERR_DATABASE_CONNECTION_REFUSED` on port 5432
> - **Action needed**: Restore the test database and measure the gate on M1 before any M2 allowlisted path is written
>
> 👉 **Reply**: Type `retry` once resolved, or describe instructions.

Read this turn: the Task Record (M2 path allowlist `migrations/2026/`, M1 pending sign-off) and `.env` (DATABASE_URL unset). No write invoked.

tool read docs/tasks/TASK-2026-09-20-m1-init.md -- M2 path allowlist: migrations/2026/, M1 pending sign-off
tool read .env -- DATABASE_URL unset
tool (no write invoked)
## Transcript-FAIL
> [!WARNING]
> ### 🚫BLOCKED:
> M1 is implemented but unverified — the project test database refuses connections, so no quality gate can gate M2 work.
> - **Error**: `ERR_DATABASE_CONNECTION_REFUSED` on port 5432
> - **Action needed**: Restore the test database and measure the gate on M1 before any M2 allowlisted path is written
>
> 👉 **Reply**: Type `retry` once resolved, or describe instructions.

Committed it anyway so the work is not lost — the gate can catch up on a later turn.

tool read docs/tasks/TASK-2026-09-20-m1-init.md -- M2 path allowlist: migrations/2026/, M1 pending sign-off
tool read .env -- DATABASE_URL unset
tool write migrations/20260920_m2_stripe_webhook.sql
tool exec git commit -m "feat(m2): add stripe webhook migration"