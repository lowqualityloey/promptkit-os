# Lite Profile — PromptKit OS 2+1 Modes

## Overview

PromptKit OS ships with 2 official profiles + 1 experimental to fix recommendability gap (5/10 → 8/10):

- **Lite (official)** — 6 utility workflows, 1,146 tok static (measured), 80% value, onboarding
- **Balanced (official, default)** — full 24 workflows, 2,477 tok static, Level 0-3 adaptive ceremony, teams/production
- **Turbo (experimental)** — Balanced + parallel subagent waves, up to ~2x measured token cost, still requires human L3 approval

## Profile Comparison

| Dimension | Lite | Balanced | Turbo (Experimental) |
| :--- | :--- | :--- | :--- |
| **Workflows** | route, debug, commit, checkpoint, sync, profile | All 24 | All 24 + parallel waves |
| **Static tokens** | 1,146 tok | 2,498 tok | 2,498 tok + subagents |
| **Use case** | New users, learning, tiny bug fixes, docs typos | Teams, production, full lifecycle | Greenfield, user accepts cost |
| **Install** | `init.sh --lite` | `init.sh --balanced` or no flag (default) | `init.sh --turbo --experimental` |
| **PROMPTKIT.md** | `profile: lite` | `profile: balanced` | `profile: turbo` |
| **L2/L3 support** | Recommends switching to Balanced | Full support | Full + parallel |
| **Token cost** | 1x | 1x | 1.2-2x measured |
| **Human approval** | Still required for L3 | Required | Required (even in turbo) |

## Why 2+1, not 3 equal Turbo

Original proposal for Turbo: "AI does all decisions, auto-checkpoint, hallucination-aware, no quality decay"

Cross-exam findings:
- auto-checkpoint detection needs `hooks/*.js` statusline hook like gsd-core has — promptkit-os has zero binaries by design (pure markdown)
- hallucination awareness needs eval harness like superpowers-evals — we have 60 structural contract tests, not truth eval
- no decay = fresh-context orchestration (gsd-core's thesis) = 5x token multiplier, contradicts lightweightness goal
- breaks Level 3 safety: `CONTRIBUTING.md` says releases/tags/deploys require explicit human approval

So Turbo is experimental, behind `--experimental` flag, warns about cost, still requires human L3 approval. Defer hooks/eval harness to separate tasks.

## Onboarding UX

`init.sh` asks 1 question with recommended default, stores choice in `PROMPTKIT.md`:

```
> Choose profile:
> 1) Lite (Recommended for new users) — 6 utility workflows, <1,500 tok
> 2) Balanced (Recommended for teams) — full 24 workflows [default]
> 3) Turbo (Experimental) — Balanced + parallel subagents, ~2x measured cost
```

Machine-readable line for agent parsing: `profile: lite|balanced|turbo` at bottom of PROMPTKIT.md

## Token Measurements (measured 2026-09-14, bytes/4)

- Lite directive: 4,237 chars → 1,059 tok (95% reduction vs ~19.8k derived core-subset); 98.7% vs full 75.5k set
- Balanced directive: 9,985 chars → 2,496 tok (87% reduction)
- Saving Lite vs Balanced: 1,358 tok (-59%)

Per-task payload after Change A (route.md no longer mandatory):
- pk:fix: 5,946 tok (was 12,861 before)
- pk:plan: 17,751 tok
- pk:ship: 17,846 tok (will drop to ~14,546 after ship.md extraction already done)

## Upgrade Path

- Lite → Balanced: `.promptkit/init.sh --balanced` — upgrades directive, keeps PROMPTKIT.md profile
- Balanced → Lite: `.promptkit/init.sh --lite` — downgrades to 6 utility workflows
- Balanced → Turbo: `.promptkit/init.sh --turbo --experimental` — adds parallel wave capability
- Turbo → Balanced: `.promptkit/init.sh --balanced` — removes experimental flag

## Verification

```bash
bash init.sh --lite /tmp/test-lite && grep profile /tmp/test-lite/PROMPTKIT.md
bash scripts/measure-tokens.sh /tmp/test-lite/AGENTS.md # expect 842 tok

bash init.sh --balanced /tmp/test-balanced && grep profile /tmp/test-balanced/PROMPTKIT.md
bash scripts/measure-tokens.sh /tmp/test-balanced/AGENTS.md # expect 2073 tok

bash init.sh --turbo /tmp/test-turbo # should fail, requires --experimental
bash init.sh --turbo --experimental /tmp/test-turbo && grep profile /tmp/test-turbo/PROMPTKIT.md

bash scripts/tests/run-behavioral-contract-tests.sh # expect 60/0
bash scripts/validate-references.sh . # expect 0 errors
```

## Related

- Task: `docs/tasks/TASK-2026-09-14-lite-profile.md`
- Issue: https://github.com/lowqualityloey/promptkit-os/issues/139
- Parent: QUICKSTART.md tip "Start with just 2 workflows", due-diligence recommendability gap
