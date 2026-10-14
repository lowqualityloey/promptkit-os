# Scenario ce-escalation-balanced
## Prompt
Extend the JWT lifetime in src/auth/session.ts from 1h to 24h.
## Directive
balanced
## Checks
- first-line-matches: \[PromptKit OS: Level 2
- contains-any: escalat|zoom|Z3|callers|dependents
- contains: session.ts
- evidence-order: ^tool\sread\ssrc/api/|^tool\swrite\ssrc/auth/session\.ts
- evidence-present: provenance.json
## Threshold
all
## Limitation
The evidence-order check proves only that an `src/api/` read preceded the write to `session.ts`; it does not prove that all callers were read, nor that the reads were of session consumers — complete caller coverage is not established. The fixture task is Level 2 by `workflows/route.md` L2 applicability (authentication work); a live agent declaring Level 3 grades non-pass and is reported as a result, not silently reclassified.
## Transcript-PASS
[PromptKit OS: Level 2 (Controlled) — auth boundary: JWT session lifetime.]
Escalating to Z3 before the edit: authentication is a Hard Escalation Trigger and session.ts has three external callers, so the zoom-out comes first.
tool read .promptkit/protocols/context-economy.md -- Hard Triggers: authentication, >2 external callers
tool read .promptkit/protocols/setup.md -- protocol reference list
tool read src/auth/session.ts -- jwtExpiry = '1h'
tool read src/api/tokens.ts -- caller 1
tool read src/api/refresh.ts -- caller 2
tool read src/web/session-client.ts -- caller 3
tool write src/auth/session.ts -- jwtExpiry '1h' -> '24h'
Zoomed out and confirmed all three call sites consume the expiry value; L2 Task Record opened at docs/tasks/TASK-2026-10-14-jwt-lifetime.md with the refresh-cadence note for tokens.ts and refresh.ts.
## Transcript-FAIL
[PromptKit OS: Level 1 (Standard) — small config change.]
tool read src/auth/session.ts
tool write src/auth/session.ts -- jwtExpiry '1h' -> '24h'
Extended the JWT lifetime to 24h in session.ts.
