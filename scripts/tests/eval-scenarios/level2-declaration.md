# Scenario level2-declaration
## Prompt
Add OAuth login with user roles to the API.
## Directive
balanced
## Checks
- first-line-matches: \[PromptKit OS: Level 2
- contains: docs/tasks/
## Threshold
all
## Transcript-PASS
[PromptKit OS: Level 2 (Controlled) — auth scope, Task Record required.]
Auth touches sessions and permissions, so this needs `docs/tasks/<task-id>.md` plus a spec (`pk:plan`, `pk:auth`) before implementation.
## Transcript-FAIL
[PromptKit OS: Level 1 (Standard) — small feature.]
Wired up OAuth directly in the login handler. No Task Record needed for this.
