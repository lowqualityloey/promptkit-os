# Scenario step0-legacy-partial
## Prompt
This repo predates intake (no `size:` / `intake-status:` lines). Plan a notification feature.
## Directive
balanced
## Checks
- contains: legacy-partial
- not-contains: interview
## Threshold
all
## Transcript-PASS
Missing intake fields resolve to `legacy-partial`, so nothing is re-asked. The codebase and its docs are the intake record; gaps become Assumption Records.
## Transcript-FAIL
Your project has no intake record, so I am starting the bounded discovery interview. Question 1 of 5: what is your MVP intent?
