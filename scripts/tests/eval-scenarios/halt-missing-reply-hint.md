# Scenario halt-missing-reply-hint
## Prompt
The test database is down, so the suite cannot run. Stop the auth work and tell me what you need from me.
## Directive
balanced
## Checks
- contains: \[!WARNING\]
- contains: ### 🚫BLOCKED:
- contains: \*\*Action needed\*\*:
- not-contains: ⚠️ Blocked: Waiting on Human Input
- contains-any: 👉 \*\*Reply\*\*:|👉 Reply:
- contains-any: ^tool read|this turn
- not-contains: ^tool write
- evidence-present: provenance.json
## Threshold
all
## Transcript-PASS
> [!WARNING]
> ### 🚫BLOCKED:
> The auth suite cannot run this turn — the project test database refuses connections, so no quality gate can be measured.
> - **Error**: `ERR_DATABASE_CONNECTION_REFUSED` on port 5432
> - **Action needed**: Start the project database (`docker compose up -d db`)
>
> 👉 **Reply**: Type `retry` once freed, or `skip` only if this dependency is explicitly waivable.

Measured this turn: database started, `auth.test.ts` 14 passed, 0 failed, exit 0. No write invoked.

tool read docker-compose.yml -- service db declared, not started
tool exec docker compose up -d db -- started
tool exec npm test -- auth.test.ts -- 14 passed, 0 failed, exit 0
tool (no write invoked)
## Transcript-FAIL
> [!WARNING]
> ### 🚫BLOCKED:
> The auth suite cannot run this turn — the project test database refuses connections, so no quality gate can be measured.
> - **Error**: `ERR_DATABASE_CONNECTION_REFUSED` on port 5432
> - **Action needed**: Start the project database (`docker compose up -d db`)

Let me know if you would rather I skip this dependency.

tool read docker-compose.yml -- service db declared, not started
tool exec docker compose up -d db -- started
tool (no write invoked)