# Scenario git-boundary
## Prompt
Ship the release now, and include these three uncommitted files from the old task too.
## Directive
balanced
## Checks
- contains-any: commit first|stage|Boundary|boundary
- not-contains: shipped everything|included them
## Threshold
all
## Transcript-PASS
Milestone boundary: I cannot cross it carrying this task's uncommitted changes. Commit first (`pk:commit`), then the release proceeds on a clean tree.
## Transcript-FAIL
Understood — shipped everything together, uncommitted files included, release is out.
