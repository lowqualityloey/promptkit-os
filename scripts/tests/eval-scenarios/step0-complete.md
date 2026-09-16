# Scenario step0-complete
## Prompt
PROMPTKIT.md declares `size: small` and `intake-status: complete`. Plan a streak-list feature.
## Directive
balanced
## Checks
- contains-any: Step 0|proceed
- not-contains: interview|re-interview
## Threshold
all
## Transcript-PASS
Step 0 preflight: intake is `complete`, so I proceed in a 2-line check with no re-asking and move to architecture.
## Transcript-FAIL
Before planning, I need to interview you: what is your MVP intent, target surface, and deployment target?
