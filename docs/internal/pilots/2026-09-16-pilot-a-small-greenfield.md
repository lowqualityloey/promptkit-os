# Pilot A: Small Greenfield Project (Scenario Walkthrough)

- **Date**: 2026-09-16 · **Baseline**: main @ `a21ed56` · **Type**: dry-run walkthrough (protocol trace, not a live agent session)
- **Simulated user**: solo developer, small scope: "a tiny habit tracker, single web page, local storage, no login, free hosting."
- **Prior behavior (pre-wave, `76e3168`)**: `pk:onboard` precondition (existing code required) failed on an empty repo; `pk:plan` started directly at Step 1 and drafted an architecture with modal pickers, `(Recommended)` Option 1, and agent-selected deployment/auth defaults.

## Walkthrough (per shipped docs)

1. **Signal read**: `PROMPTKIT.md` has `size: [small | medium | large]` / `intake-status: [unanswered | partial | complete]` → placeholders, not values (`templates/project-profile-template.md` declares these **intake questions, not defaults**).
2. **`pk:onboard` Phase 0 activation gate**: no manifests/lockfiles/code → greenfield path activates; brownfield scan skipped.
3. **Bounded interview (size S = ≤5 questions, 1 round, context window)**: MVP intent · target surfaces · deployment/hosting · auth & data needs · design references. Modal pickers prohibited (`never in choice menus`); links/screenshots invited as answers.
4. **Simulated answers recorded**: MVP = one page, streak list + today checkbox; surface = responsive web; deploy = free static hosting (GitHub Pages); auth = none, data = browser localStorage; design = "clean, minimal, no screenshots yet" → 1 ASSUMPTION entry (visual direction) with owner + validation action; 2 Later-ledger ideas (offline PWA, cloud sync) — proposed, not built.
5. **Close**: user says "enough for now" → Intake Record with `close_reason: human_stopped`; `size: small` / `intake-status: complete` written to `PROMPTKIT.md`.
6. **`pk:plan` Step 0**: `complete` → proceeds in a 2-line check, no re-asking (Question Retention extended to intake slots). MVP floor: every proposed moving part traces to a stated requirement; single surface, single deploy target, no speculative infrastructure; "Decisions I'm defaulting for you" = none beyond recorded answers.

## Measured cost (bytes/4, same convention as `scripts/measure-tokens.sh`)

| Item | Tokens |
|:---|---:|
| One-time intake premium: `protocols/discovery-intake.md` (12,635 B) | 3,158 |
| Step 0 preflight growth in `workflows/plan.md` (measured gate delta 15,539 → 16,333) | +794 |
| Steady state after intake closes | **0 additional** (protocol lazy-loaded only while intake is incomplete) |
| Measured total one-time premium (3,158 + 794) | **~3,952** (no spec band claimed; spec defines no predicted range) |

## Outcome vs. prior behavior
- 5 questions asked instead of ~0; deployment/auth/data now **user-owned** (GitHub Pages / none / localStorage) instead of agent-defaulted.
- 2 agent ideas diverted to the Later ledger instead of entering scope — the overengineering path the wave targets.
- Added wall-clock cost: ~5–10 minutes of interview (within the S-class budget from the protocol).
- **Not measured (honest)**: live agent fidelity, real rework avoidance; this is a protocol-trace pilot, not an empirical A/B.
