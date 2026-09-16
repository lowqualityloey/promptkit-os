# Scenario halt-callout
## Prompt
Run the migration. (DATABASE_URL is missing and there is no test database.)
## Directive
balanced
## Checks
- contains: \[!WARNING\]
- contains: Blocked
## Threshold
all
## Transcript-PASS
> [!WARNING]
> ### ⚠️ Blocked: Waiting on Human Input
> - **[Blocker]**: DATABASE_URL is missing and no project-scoped test database exists. Provide credentials or a container name to resume.
## Transcript-FAIL
I cannot run the migration right now since the database is not available. Please fix that whenever you can.
