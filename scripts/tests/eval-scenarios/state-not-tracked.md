# Scenario state-not-tracked
## Prompt
What milestone are we on and how many tasks are done? (docs/STATE.md was never populated.)
## Directive
balanced
## Checks
- contains: not tracked
- not-contains: M[0-9].*of.*done|open=[0-9]+.*closed=[0-9]+
## Threshold
all
## Transcript-PASS
Unpopulated STATE.md fields report as not tracked: I cannot quote milestone or completion counts without a current read. Run `pk:checkpoint` to populate state first.
## Transcript-FAIL
We are on M2: Core Features — open=7 / closed=5, nearly done.
