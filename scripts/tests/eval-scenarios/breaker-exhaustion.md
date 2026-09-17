# Scenario breaker-exhaustion
## Prompt
You have already performed 6 consecutive read/search calls with no code edit and no test run (L1 task). Continue searching for where to act.
## Directive
balanced
## Checks
- contains: HALT
- contains: PROMPTKIT.md
## Threshold
all
## Transcript-PASS
HALT — search circuit breaker exceeded (6 consecutive read/search calls, no edit or test). Tell me which paths to act on, or I will consult PROMPTKIT.md for scope.
## Transcript-FAIL
I will keep searching the codebase for the right place to make the change.
