# Lite-as-Default Evaluation (decision record, not implementation)

- **Record Type**: `Strategy Evaluation`
- **Date**: `2026-09-16`
- **Owner**: `Implementor agent (drafting) — maintainer (decision owner)`
- **Status**: `preliminary — recommendation recorded, no default changed`
- **Pattern**: comparable with `docs/releases/2026-09-14-v1.7.0-evaluation.md` (attributed figures at a named SHA, falsifiable conclusion)
- **Measurement SHA**: `main` @ `90a4629` (2026-09-16; Wave B branch changes no measured file, so figures hold at merge)

## Figures (all measured, none estimated)

| Dimension | Lite | Balanced (current default) |
| :--- | :--- | :--- |
| Static directive | 1,059 tok of 1,500 (`LITE\|1059\|1500\|PASS`) | 2,345 tok of 2,500 (`BALANCED\|2345\|2500\|PASS`) |
| Workflows | 6 (route, debug, commit, checkpoint, sync, profile) | 23 |
| `pk:fix` payload | 5,341 tok | 6,617 tok |
| `pk:plan` payload | 14,896 tok | 16,172 tok |
| `pk:ship` payload | 10,442 tok | 11,718 tok |
| Adoption signal | stars=0, forks=0 (`gh repo view`, 2026-09-16) | same repo |

Methods: `scripts/measure-tokens.sh --strict`, `scripts/measure-per-task-tokens.sh` (bytes/4; validated ±0–19% vs `tiktoken` in `docs/BENCHMARKS.md` §9 — absolute figures conservative on both sides).

## Analysis

1. **Adoption friction.** Install path is identical (submodule + `init.sh --lite|--balanced`); Lite wins time-to-first-value on tiny tasks (fewer concepts). No user data exists either way (stars=0, forks=0), so friction arguments are reasoning, not evidence.
2. **Capability coverage.** A typical first task (debug, commit, checkpoint, sync) fits Lite's 6 workflows. But the flagship first impressions — `pk:plan` architecture, `pk:review` two-axis review, `pk:test` strategy — are Balanced-only. Lite's `pk:plan` path is also thinner (14,896 vs 16,172 tok reflects less planning machinery, not just a smaller directive).
3. **Token cost.** Lite saves ~1.3–1.5k tok per task (~19% on fix, ~8% on plan/ship). Real but modest — the JIT architecture already removed the dominant cost (mandatory `route.md` load) for both profiles.
4. **Migration impact.** `profile: balanced` in `templates/project-profile-template.md` and installer defaults are untouched by this record. If the default ever flips: existing `PROMPTKIT.md` files declaring `profile: balanced` keep working unchanged (explicit value beats default); only fresh installs without a profile line would resolve differently. Reversible per-install via `pk:profile`.

## Recommendation

**Keep Balanced as the default.** Rationale: with zero adoption signal, the decision must rest on product identity — and the repository's differentiating claims (spec-driven planning, two-axis review, intake gates) are Balanced features. Making Lite the default would advertise the 80%-value slice as the product while the evidence it needs (new-user success delta) cannot exist before users exist.

## Evidence that would overturn this

- New-user completion data (even N≈10 informal reports) showing Balanced's surface — not its token cost — blocks first-task success while Lite succeeds.
- Sustained Balanced headroom pressure (e.g. <100 tok for two consecutive feature waves) forcing triage that Lite's smaller surface avoids.
- A flagship first task that Lite covers fully (e.g. if review/planning depth migrates into Lite's set).

Revisit when any of the above materializes. Implementing a flip is out of scope here: installer, template default, and Lite workflow set are unchanged.
