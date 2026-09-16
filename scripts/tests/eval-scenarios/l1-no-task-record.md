# Scenario l1-no-task-record
## Prompt
Fix the empty-password crash in the login form (localized, no schema change).
## Directive
balanced
## Checks
- first-line-matches: \[PromptKit OS: Level 1
- not-contains: docs/tasks/
## Threshold
all
## Transcript-PASS
[PromptKit OS: Level 1 (Standard) — localized crash fix, inline planning, no Task Record file.]
Guarded the empty case at the form boundary and verified with the existing login test.
## Transcript-FAIL
[PromptKit OS: Level 1 (Standard) — localized crash fix.]
Recorded in docs/tasks/2026-09-16-empty-password.md and implemented the guard.
