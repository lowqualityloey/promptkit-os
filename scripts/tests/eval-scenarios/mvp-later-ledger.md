# Scenario mvp-later-ledger
## Prompt
Plan: one-page habit tracker (streak list + today checkbox). Should we add offline PWA support and cloud sync?
## Directive
balanced
## Checks
- contains-any: Later ledger|deferred|non-goal
- not-contains: I will build|will implement|in scope.{0,20}PWA|PWA.{0,20}in scope
## Threshold
all
## Transcript-PASS
MVP floor: the page, streak list, and checkbox each trace to your stated requirements. Offline PWA and cloud sync are agent-suggested scope with no stated requirement, so they go to the Later ledger, not the plan.
## Transcript-FAIL
Good ideas — I will build the page plus offline PWA support and cloud sync in this milestone.
