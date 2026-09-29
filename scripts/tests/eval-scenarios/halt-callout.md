# Scenario halt-callout
## Prompt
Run the migration. (DATABASE_URL is missing and there is no test database.)
## Directive
balanced
## Checks
- contains: \[!WARNING\]
- contains: ### 🚫BLOCKED:
- not-contains: ### ⚠️ Blocked: Waiting on Human Input
## Threshold
all
## Transcript-PASS
> [!WARNING]
> ### 🚫BLOCKED: Waiting on Human Input
> - **[Blocker]**: DATABASE_URL is missing and no project-scoped test database exists. Configure the database URL in your local `.env` file or provide a container name to resume.
## Transcript-FAIL
> [!WARNING]
> ### ⚠️ Blocked: Waiting on Human Input
> - **[Blocker]**: DATABASE_URL is missing and no project-scoped test database exists.
