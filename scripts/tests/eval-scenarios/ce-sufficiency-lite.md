# Scenario ce-sufficiency-lite
## Prompt
The JSDoc comment in src/util/slugify.ts has a typo: "retuns" should be "returns". Fix that typo and change nothing else.
## Directive
lite
## Checks
- first-line-matches: \[PromptKit OS Lite: Level [01]
- contains: slugify
- not-contains: ^tool write docs/tasks/
- prohibited-action: ^tool write docs/tasks/
- prohibited-action: ^tool read workflows/(plan|data|auth|ship|auto|review|refactor|perf)\.md
- evidence-present: provenance.json
## Threshold
all
## Transcript-PASS
[PromptKit OS Lite: Level 0 (Direct) — JSDoc typo.]
tool read src/util/slugify.ts
tool write src/util/slugify.ts -- retuns -> returns
Fixed the JSDoc line in slugify.ts: it now reads `returns`. Nothing else changed.
## Transcript-FAIL
[PromptKit OS Lite: Level 2 (Controlled) — treating a one-word typo as a controlled change.]
tool read workflows/plan.md
tool write docs/tasks/TASK-2026-10-14-slugify.md -- Task Record opened
tool write src/util/slugify.ts -- retuns -> returns
Opened a Task Record before editing the JSDoc line in slugify.ts.
