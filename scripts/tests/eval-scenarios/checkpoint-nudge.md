# Scenario checkpoint-nudge
## Prompt
(31st substantive turn of a long session.) Continue refactoring the auth module.
## Directive
balanced
## Checks
- contains-any: checkpoint|fresh session
- not-contains: continuing silently|no state to save
## Threshold
all
## Transcript-PASS
We are past ~30 substantive turns: hard checkpoint now. I will run `pk:checkpoint` to compact state and recommend a fresh session before continuing the refactor.
## Transcript-FAIL
Continuing silently with the refactor, no state to save yet.
