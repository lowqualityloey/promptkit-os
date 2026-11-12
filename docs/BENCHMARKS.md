# PromptKit OS Architecture & Token Economics Analysis

**Historical baseline:** 2026-09-14 on `main` (v1.6.0 with 2+1 profiles) · **Current measurements:** the last committed measurement is 2026-11-12 at `52c09ad`, the implementation commit of the untrusted-content directive: it carries the re-propagated directive figures (2,348 → 2,410 tok Balanced, 1,456 → 1,491 tok Lite), the re-derived component decomposition, the moved per-task payloads (`pk:fix` 11,335/10,443 → 11,397/10,478; `pk:plan` 20,824/19,932 → 20,886/19,967; `pk:ship` 17,125/16,233 → 17,187/16,268), and the refreshed §9 tokenizer rows for both directives, and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. **Moved by the four review fixes (2026-11-13):** the untrusted-content guardrail bullet in both directives grew a project-config carve-out, which re-propagated the directive figures (2,410 → 2,449 tok Balanced, 1,491 → 1,489 tok Lite), the component decomposition, the per-task payloads (`pk:fix` 11,397/10,478 → 11,436/10,476; `pk:plan` 20,886/19,967 → 20,925/19,965; `pk:ship` 17,187/16,268 → 17,226/16,266), and the §9 tokenizer rows for both directives; the prior measurement was 2026-11-12 at `de9ca7b`, the implementation commit of the tracking-gate scope correction: it carries the re-propagated full workflow-set figure (119,719 → 119,766 tok) from the `workflows/tasks.md` GitHub-template paragraph, which now names the three exceptions the first correction missed — local tracking with the GitHub projection, a `--host=copilot` install that still writes `.github/copilot-instructions.md`, and the fact that switching an install away from GitHub leaves existing templates in place — and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA; the prior measurement was 2026-11-12 at `03265ce2399964bc4947053eb4cbc74725d40c73`, the implementation commit of the first tracking-gate documentation correction: it carries the re-propagated full workflow-set figure (119,633 → 119,719 tok) from the same paragraph; the core-six subset (32,903 tok), the Balanced and Lite directives (2,348 / 1,456 tok), and every per-task payload are unchanged and reproduce exactly; the prior measurement was 2026-10-28 at `3cd97feddef1820fe333a31966b412cd32289863`, the implementation commit of the PR-workflow merge-command correction: it carries the re-propagated full workflow-set figure (119,556 → 119,633 tok) from the `workflows/pr.md` merge-command line; the prior measurement was 2026-10-25 at `7ab8b50121987daf257b52ee732d59920acda35b`, the implementation commit of the doctor six-check documentation catch-up: it carries the re-propagated directive figure (2,341 → 2,348 tok), core-six figure (32,814 → 32,903 tok), full workflow-set figure (118,832 → 119,556 tok), and the per-task moves (`pk:fix` 11,320/10,435 → 11,335/10,443; `pk:plan` 20,817/19,932 → 20,824/19,932; `pk:ship` 17,118/16,233 → 17,125/16,233), and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA; the prior measurement was 2026-10-25 at `7fe881586e69906ad07e822b65a342401162ccf2`, which combines the #673/#674 record-evidence documentation with the #667/#672/#668 stack and carries their re-propagated figures; the prior measurement was 2026-10-25 at `3d84c38c99d0f1ab4ac7a150757a359129729fcb`, which combines the #667 doctor gitlink-registration check with the #672 exit-3 and #668 ceremony-vocabulary stack and carries their re-propagated figures; the prior measurement was 2026-10-25 at `c86aa68f4f8df5899e4350388a2070928c42e8dd`, which combines the #672 exit-3 consumer-allowlist remediation clarification with the #668 ceremony-vocabulary normalization and carries their re-propagated figures; the prior measurement was 2026-10-24 at `23113db0559298ccf22f2473628d5b7d4a1bba23`, which carries the #668 ceremony-vocabulary normalization and its re-propagated figures; the prior measurement was 2026-10-24 at `3f0cb51e6f709bd975189a4038104439185549bc`, which carries the #664 self-conformance clarification and its re-propagated figures; the prior measurement was 2026-10-22 at `856fcd2a597da71bad0e6bc4cebef9fcc4cca268`, which carries the #644 onboarding host-document divergence change and its re-propagated figures; the Balanced figures and Balanced per-task payloads are unchanged since the prior measurement commit `998fc1ca347eb118ec4f81a3e779a5303e3577db` (which included the #609/#610 workflow-link, validator, and documentation changes, the mode-aware notes-ownership correction, and the #605 terminology-related refactor workflow clarification). The #646 `workflows/doctor.md` documentation moved only the full workflow-set inventory below; the Balanced and Lite directives, the core-six subset, and the per-task payloads reproduce exactly and are unaffected. The `Current measurements` provenance-anchor guard parses the first SHA on this line and diffs it against `HEAD` over the measured inputs. **Restated for #646:** the anchor was `4f56757d000af4440969e266b4bb486e3000f21d`, the measurement commit for the five-check `pk:doctor` documentation; the measured-input tree was unchanged since it, and the #642 restatement below supersedes it. **Restated for #642:** the anchor is `0600e4df9b70aa94ffde642968cf2dd94d0ff1e2`, the implementation commit of this change: it carries the re-propagated full workflow-set figure (117,290 → 117,590 tok), and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. **Restated for #644:** the anchor is `856fcd2a597da71bad0e6bc4cebef9fcc4cca268`, the implementation commit of this change: it carries the re-propagated full workflow-set figure (117,590 → 118,124 tok) and the refreshed `protocols/discovery-intake.md` tokenizer row, and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. The Balanced and Lite directives, the core-six subset, and the per-task payloads reproduce exactly and are unaffected. The two commits landed in one pull request: the implementation commit carried every figure, and this documentation-only commit changed only this file. Merge with a merge commit (a procedural requirement; the repository also permits squash and rebase) so the anchor commit remains an ancestor of `main` regardless of whether the pull-request branch is later retained. The guard itself validates clone-resolvability and measured-input drift, not ancestry, so a squash or rebase merge does not fail immediately; it risks an unresolvable anchor only if the source branch is deleted or not fetched. **Restated for #664:** the anchor is `3f0cb51e6f709bd975189a4038104439185549bc`, the implementation commit of this change: it carries the re-propagated full workflow-set figure (118,124 → 118,157 tok) and core-six figure (32,280 → 32,313 tok) from the `workflows/route.md` Tier-1/Tier-2 clarifications, and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. The Balanced and Lite directives, the per-task payloads, and every other gated cell are unchanged and reproduce exactly. **Restated for #668:** the anchor is `23113db0559298ccf22f2473628d5b7d4a1bba23`, the implementation commit of this change: it carries the re-propagated full workflow-set figure (118,157 → 118,153 tok), core-six figure (32,313 → 32,311 tok), and the refreshed `workflows/plan.md` and `workflows/route.md` tokenizer rows from the ceremony-vocabulary normalization, and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. The Balanced and Lite directives, the per-task payloads, and every other gated cell are unchanged and reproduce exactly. **Restated for the #672 exit-3 follow-up (merged after #668):** the anchor is `c86aa68f4f8df5899e4350388a2070928c42e8dd`, the merge commit combining the remediation clarification with the #668/#669/#671/#670 stack: it carries the re-propagated full workflow-set figure (118,153 → 118,503 tok) and core-six figure (32,311 → 32,662 tok) from the `workflows/commit.md` consumer-allowlist guidance on top of the ceremony-vocabulary normalization, and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. The Balanced and Lite directives, the per-task payloads, and every other gated cell are unchanged and reproduce exactly. **Restated for #667 (merged after #672):** the anchor is `3d84c38c99d0f1ab4ac7a150757a359129729fcb`, the merge commit combining the doctor gitlink-registration check with the #672/#668 stack: it carries the re-propagated full workflow-set figure (118,503 → 118,506 tok) from the `workflows/doctor.md` `ls-files` contract line, and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. The Balanced and Lite directives, the core-six subset, and the per-task payloads are unchanged and reproduce exactly. **Restated for #673/#674 part 2 (merged after #667):** the anchor is `7fe881586e69906ad07e822b65a342401162ccf2`, the merge commit combining the AC evaluation-time binding and two-commit Commit Evidence documentation with the #667/#672/#668 stack: it carries the re-propagated full workflow-set figure (118,506 → 118,832 tok) and core-six figure (32,662 → 32,814 tok) from the `workflows/commit.md` and `workflows/checkpoint.md` evidence-semantics documentation, and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. The Balanced and Lite directives and the per-task payloads are unchanged and reproduce exactly. **Restated for the doctor six-check catch-up (merged after #688):** the anchor is `7ab8b50121987daf257b52ee732d59920acda35b`, the implementation commit of this change: it carries the re-propagated directive figure (2,341 → 2,348 tok), core-six figure (32,814 → 32,903 tok), full workflow-set figure (118,832 → 119,556 tok), the per-task moves named in the banner above, and the refreshed §9 tokenizer rows for the directive, `workflows/route.md`, and `workflows/fix.md`, and this documentation-only commit restates the anchor to it because a commit cannot contain its own SHA. The Lite directive and its payload column are unchanged and reproduce exactly. Regenerated from the source tree (rerun the commands below after input changes) · **Method:** `bytes / 4` convention via `scripts/measure-tokens.sh` · Historical monolithic baseline: core-6 lifecycle subset 19,794 tok / full workflow set 75,505 tok. · **Lite note:** the current Lite figures are the 2026-11-13 review-fix revision (sha256 `7fe41c7f1bcd6501946ee1f4a4dce01ea0e8a81ddc20b19f5cbb5a1d7e097700`), which moved `templates/agent-directive-lite-template.md` 5,962 B → 5,957 B (**-5 B**: the guardrail bullet gained a project-config carve-out and the redundant upgrade hint was dropped to pay for it) from the 2026-11-12 untrusted-content directive revision (sha256 `781297b78006ae960b0d3de384a305c6a60e8a6954481142761b0c32b00abab6`), which had moved it 5,824 B → 5,962 B from the 2026-10-14 revision committed in `3f3f86f123f43e962a3c41ddedb26b323184ddc6` (sha256 `ffc0349a97fdce97490b9bbab73067674df2640b05a38cdd5268079931afacd0`, base `cbe6a7ad15f28113fbcebacaa49c7c87068fb9ca`).

This document provides a factual, mechanically verifiable analysis of the token economics, context window preservation, and engineering ROI of the PromptKit OS architecture. All numbers below can be reproduced via `bash scripts/measure-tokens.sh [file]` and `wc -c workflows/*.md`.

---

## 1. Architectural Model: Monolithic Prompt Inlining vs. Just-In-Time (JIT) Loading

Traditional AI coding packs and mega-prompts attempt to inline extensive guidelines, workflow checklists, and multi-file instructions into the root system prompt or configuration file (`.cursorrules`, `CLAUDE.md`, system instruction headers). 

PromptKit OS uses a **Just-In-Time (JIT) Filesystem Architecture**:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    MONOLITHIC MEGA-PROMPT MODEL                         │
│ Every Turn: [26 Inlined Workflows (119,766 tok) + Templates + Protocols] │
│ Context Window Waste: High static token bloat on every single message   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                   PROMPTKIT OS JIT FILESYSTEM MODEL                     │
│ Baseline Static Injection: Router Directive (1,489 tok Lite / 2,449 Bal)  │
│ On-Demand Loading: Tool loads only target workflow file (e.g. pk:debug) │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Static Injection Footprint (Measured Tokens)

| Profile | Template | UTF-8 Bytes | Est. Tokens (bytes/4) | Reduction vs ~32.8k current core-subset baseline¹ | Use |
| :--- | :--- | ---: | ---: | :--- | :--- |
| **Lite** | `agent-directive-lite-template.md` (6 utility workflows: route, debug, commit, checkpoint, sync, profile) | 5,957 | **1,489 tok** | **95% static** | Onboarding, new users, tiny fixes |
| **Balanced** | `agent-directive-template.md` (26 workflows) | 9,797 | **2,449 tok** | **93% static** | Teams, production, default |
| **Turbo** | same as Balanced + parallel waves | 9,797 | 2,449 tok + subagents (~2x measured total (bounds model, see section 8)) | 93% static, higher total | Experimental, greenfield, accepts cost |

### Current Workflow Inventory

| Inventory | Workflow Files | Measured Tokens |
| :--- | ---: | ---: |
| Core-six Lite subset | 6 | **32,903 tok** |
| Full workflow set | 26 | **119,766 tok** |

¹ Current core-subset baseline is the live sum of the six workflow files loaded by the Lite profile (route, debug, commit, checkpoint, sync, profile); the full-set baseline includes every `workflows/*.md` file. The inventory values above are regenerated from the checked-out source revision. Historical values at the 2026-09-14 measurement were 19,794 and 75,505 tok, respectively; the previous unsourced "18.5k" constant is retired.

> **Lite revision provenance (committed in `3f3f86f123f43e962a3c41ddedb26b323184ddc6`, 2026-10-14, from base `cbe6a7ad15f28113fbcebacaa49c7c87068fb9ca`):** `templates/agent-directive-lite-template.md` moved 5,745 B → 5,824 B (**+79 B**, the single measured file that differs from that base; `templates/agent-directive-template.md`, `workflows/*.md`, `protocols/code-quality-gate.md`, and every other measured input are unchanged). The revised file's SHA-256 is `ffc0349a97fdce97490b9bbab73067674df2640b05a38cdd5268079931afacd0`, reproducible with `sha256sum templates/agent-directive-lite-template.md`. That commit was the provenance anchor in the banner above until the 2026-11-12 untrusted-content directive revision, which moved the file 5,824 B → 5,962 B (**+138 B**) and changed its SHA-256 to `781297b78006ae960b0d3de384a305c6a60e8a6954481142761b0c32b00abab6`; the 2026-11-13 review-fix revision then moved it 5,962 B → 5,957 B (**-5 B**) and changed the SHA-256 to `7fe41c7f1bcd6501946ee1f4a4dce01ea0e8a81ddc20b19f5cbb5a1d7e097700`.

> **Clarification:** Static-overhead reductions compare the directive with the current core-six workflow baseline (93% Balanced, 95% Lite). Per-task payload reductions use a separate historical per-task baseline; current results are measured below (11–30% Balanced, 19–34% Lite). Neither measures session token usage, estimates live-model cost, or enforces host runtime limits. Session usage is estimated by the host; `workflows/perf.md` covers application performance profiling, not session metering. The search circuit breaker in the directive templates is advisory instruction, not deterministic tool control. Markdown instructs; it cannot stop tools by itself.

Component rows were re-derived at the current banner anchor. The #644 `workflows/onboard.md` and `protocols/discovery-intake.md` changes and every later banner-anchor move left `templates/agent-directive-template.md` untouched until the 2026-11-12 untrusted-content directive added one guardrail bullet to it, which the 2026-11-13 review fixes then extended with a project-config carve-out; the rows below are measured against that revision. They use the repo's own convention (`(bytes + 2) / 4`, the same formula `scripts/measure-tokens.sh` applies to the whole directive). Each row is a contiguous line range of `templates/agent-directive-template.md`: lines 1-4, 6-33, 35-53, 55-61, 63-69, and 71-73. Those cover **68 of the file's 73 lines**; the five omitted lines (5, 34, 54, 62, and 70) are blank separators between sections and carry no content. The rows sum to 2,448 against the 2,449-token figure `scripts/measure-tokens.sh` reports for the same file, and the 1-token gap is fully accounted for in bytes: the six ranges total 9,792 B (2,448.0 tokens unrounded), so rounding each range independently and adding the parts lands at 2,448. The five omitted blank lines add 5 B for 9,797 B, the file's full byte count, which `measure-tokens.sh` rounds to 2,449. The component rows are a decomposition for orientation; the `Total Baseline Static Overhead` row below is the gated figure and carries the tool value. The `Total Baseline Static Overhead` rows are the CI-gated cells (`scripts/tests/run-behavioral-contract-tests.sh` looks up `Component (Balanced)` / `Approx. Token Weight` / `Total Baseline Static Overhead (Balanced)` by exact string equality) and must continue to match `measure-tokens.sh` output; the component rows are explanatory and are not gated.

| Component (Balanced) | Lines | Approx. Token Weight | Purpose |
| :--- | :---: | :---: | :--- |
| **System Introduction & Scope** | 4 | ~87 tokens | Identifies PromptKit root in workspace (`./.promptkit`) |
| **Fast Shorthand Triggers** | 28 | ~462 tokens | Direct workflow routing shorthand (`pk:debug`, `pk:test`, etc.) |
| **Smart Auto-Route & Guardrails** | 19 | ~1,279 tokens | Secret hygiene, circuit breaker, telemetry provenance, milestone boundaries |
| **Workflows & Protocols Reference** | 7 | ~231 tokens | Lazy-load convention plus trigger-to-file exceptions |
| **Task Ceremony Levels** | 7 | ~293 tokens | Composable 4-level task ceremony engine |
| **Project Artifact Output Paths** | 3 | ~96 tokens | Canonical locations for generated specs, ADRs, and plans |
| **Total Baseline Static Overhead (Balanced)** | **73 lines** | **~2,449 tokens** | **Permanent footprint in system prompt (~93% static saving vs. current ~32.8k core-subset (~98% vs. current full 26-file set))** |
| **Total Baseline Static Overhead (Lite)** | **57 lines** | **~1,489 tokens** | **95% static saving, ~61% of Balanced** |
> **Opt-in add-on — §5a LSP diagnostics (net **~447 tok**):** `workflows/review.md` step 2a (~313 tok) + Diagnostics Evidence table (~134 tok), with the carried comparison figure 3,228 tok from the original row. Additive only when `LSP Enabled: true`; runtime evidence capped at 150 lines. Applies to **Balanced + `pk:review`** on TS repos (Lite stays at 1,489 tok — skipped silently).

By contrast, the measured cost of inlining the complete workflow set is listed in the Current Workflow Inventory above; it would be paid on turn 1 before any user request is processed.

> **Budget semantics:** these gates enforce **static prompt size** (directive + workflow + gate payload, bytes/4). They do not measure session token usage, estimate live-model cost, or enforce host runtime limits. Session usage is estimated by the host; `workflows/perf.md` covers application performance profiling, not session metering. The search circuit breaker in the directive templates is advisory instruction, not deterministic tool control. Markdown instructs; it cannot stop tools by itself.

### CI Budget Gate (Strict Mode)

The budgets above are enforced mechanically on every push and pull request so template edits cannot regress them silently. Both commands emit machine-parseable `NAME|MEASURED|BUDGET|STATUS` lines:

```bash
# Static directives: asserts Balanced <= 2,500 tok AND Lite <= 1,500 tok
bash scripts/measure-tokens.sh --strict
pwsh -NoProfile -File .\scripts\measure-tokens.ps1 -Strict   # PowerShell parity

# Per-task payloads: asserts pk:fix / pk:plan / pk:ship stay <= baselines 12,861 / 24,666 / 24,761 tok
bash scripts/measure-per-task-tokens.sh --strict
```

Gate coverage: the static dual-profile budget **and** the per-task baseline gate (PowerShell mirror included) run in **both** Linux and Windows CI jobs; the Turbo overhead claim window runs in both jobs as well. Negative-path behavior is covered by `scripts/tests/run-token-budget-tests.sh`. Budget constants are defined once per script; this document is the human reference. If a deliberate contract expansion requires raising a budget, update the constant in `scripts/measure-tokens.sh`, `scripts/measure-tokens.ps1`, and this document in the same change.

---

### Ceremony Artifact Overhead by Task Level (static, measured)

[`workflows/route.md`](../workflows/route.md) decides what each ceremony level must produce; until now nothing recorded what those required artifacts *weigh*. This section closes the deterministic half of that gap — the template set each level requires, measured from the checked-out tree.

Two units are reported separately because they are paid differently:

- **Per-task artifacts** — templates the level obliges the agent to fill for *each* task. Repeated cost.
- **Shared setup** — `docs/STATE.md` from [`templates/state-tracker-template.md`](../templates/state-tracker-template.md), filled once per project and updated in place afterwards. Counted once below, never inside a per-level total.

| Ceremony Level | Per-task required artifacts | Bytes | Est. tokens (bytes/4) |
| :--- | ---: | ---: | ---: |
| **Level 0 (Direct)** | 0 | 0 | **0 tok** |
| **Level 1 (Standard)** | 0 | 0 | **0 tok** (optional quick-tier checkpoint 267 tok) |
| **Level 2 (Controlled)** | 2 | 21,488 | **5,372 tok** (Minimal Planning default) |
| **Level 3 (Release-Critical)** | 5 | 52,764 | **13,191 tok** (Minimal Planning default) |
| *Shared setup, once per project* | 1 | 12,084 | *3,021 tok* |

**Planning depth is part of the model, not a footnote.** [`workflows/plan.md`](../workflows/plan.md) makes *Minimal Planning* the Level 2 default and stops "without continuing into the full RFC", so a Level 2 task does **not** necessarily produce a specification file. The per-level totals above are therefore the Minimal Planning set — Task Record plus checkpoint — and the specification is published as a band that Full Planning adds:

| Level | Minimal Planning (default) | Full Planning (triggering) |
| :--- | ---: | ---: |
| Level 2 | 5,372 tok | 6,351–10,852 tok |
| Level 3 | 13,191 tok | 14,170–18,671 tok |

Growth from Level 2 to Level 3 is **+7,819 tok (2.46×)** on the Minimal Planning set. There is no ratio against Level 1, because Level 1 has no per-task template surface: [`workflows/checkpoint.md`](../workflows/checkpoint.md) (anchor: `Level 1 (Standard) work updates`) lets Level 1 work "update `docs/STATE.md` or session notes directly without requiring a Task Record file", so its per-task load is the shared tracker already counted once. Three earlier revisions are superseded and recorded here so the correction trail is auditable: the first (L1 3,021 / L2 8,660 / L3 16,479) charged the shared tracker at every level and omitted the Level 2 specification; the second (L2 11,119 / L3 18,938) charged every Level 2 task for a tech spec that Minimal Planning never writes; the third (L2 5,639 / L3 13,458) charged the whole checkpoint template at both levels, although policy gives Level 2 and Level 3 only its Full Tier and reserves the Quick Tier for Level 1.

**The checkpoint has two tiers, and policy names which level gets which.** [`templates/execution-checkpoint-template.md`](../templates/execution-checkpoint-template.md) ships a shared header (476 B / 119 tok), a Quick Tier section (1,069 B / 267 tok) and a Full Tier section (1,763 B / 441 tok). [`workflows/checkpoint.md`](../workflows/checkpoint.md) gives Level 1 the `quick` tier (anchor: `Requires ten canonical labels`) and Level 2 and Level 3 only the `full` tier (anchor: `Mandatory durable execution gate requiring all 20 canonical checkpoint labels`). The figures above therefore charge **the shared header plus the Full Tier section — 2,239 B / 560 tok — to Level 2 and Level 3**, and publish the Quick Tier section on its own (267 tok) as the Level 1 optional artifact. Charging the whole file at every level, as the third revision did, overstates both. The tier boundaries are read from the template's own headings, never from line numbers, and the script asserts that header + quick + full section equals the whole file, so a restructured template fails the run with `MEASURE_ERROR|TIER_SPLIT` instead of being silently mis-split.

**Which artifact belongs to which level** — membership is a curated reading of policy, not a parse:

| Level | Required per-task template | Policy source |
| :--- | :--- | :--- |
| L2 | `execution-task-record-template.md` (4,812 tok) and the Full Tier checkpoint (560 tok); a specification from the family below only under Full Planning | [`workflows/route.md`](../workflows/route.md) (anchor: `Requires a Local Task Record`) — "Requires a Local Task Record at `docs/tasks/<task-id>.md` and formal specification (`pk:plan`, `pk:data`, `pk:auth`, `pk:api`)"; [`workflows/checkpoint.md`](../workflows/checkpoint.md) (anchor: `Mandatory durable execution gate requiring all 20 canonical checkpoint labels`) — the `full` tier at Level 2/3; [`workflows/plan.md`](../workflows/plan.md) (anchor: `Minimal Planning (Level 2 default)`) — Minimal Planning is the default |
| L3 | Level 2 plus `release-checklist.md` (3,409 tok), `release-evaluation-template.md` (3,163 tok), `contract-impact-evidence-template.md` (1,247 tok) | [`workflows/route.md`](../workflows/route.md) (anchor: `Uses full release candidate evaluation`) — "contract impact evidence (`pk:ship`)", release evaluation; [`workflows/route.md`](../workflows/route.md) (anchor: `as supporting references; do not create a new command`) — names `contract-impact-evidence-template.md` and `release-evaluation-template.md` as the supporting references; [`workflows/ship.md`](../workflows/ship.md) (anchor: `Access to`) — the release checklist as a `pk:ship` precondition |

**One required artifact has no shipped template.** [`workflows/review.md`](../workflows/review.md) gives `pk:review` "one durable two-axis report at `docs/reviews/<review-slug>.md`", and no template for it ships in this repository. It is listed as required at Level 2 and Level 3 and reported as `untemplated` with zero measurable bytes — never silently dropped, never estimated. Its absence is why the totals above are a floor on required artifact text, not a complete account of it.

**The Level 2 specification is a family, not one file.** `pk:plan` selects the generic tech spec; `pk:data`, `pk:auth` and `pk:api` select other templates, and a task uses one of them, not all four:

| Sub-trigger | Template | Tokens | L2 total with it |
| :--- | :--- | ---: | ---: |
| `pk:plan` — pinned baseline | `tech-spec-template.md` | 5,480 | **10,852 tok** |
| `pk:data` | `data-model-spec.md` | 1,825 | 7,197 tok |
| `pk:api` | `api-contract-spec.md` | 1,347 | 6,719 tok |
| `pk:auth` | `auth-matrix-template.md` | 979 | 6,351 tok |

The band **6,351–10,852 tok** is the size of the Level 2 template set *when Full Planning adds one specification member*; it is not what every Level 2 task costs, because the default path writes no specification at all. The gate pins the largest member so the recorded baseline never depends on which sub-trigger a given task happened to use.

**Optional artifacts, measured separately** (required only in the condition named): L1 quick-tier checkpoint 267 tok; L2 handoff 978 tok and scope-change 782 tok; L3 additionally CI triage 1,603 tok, conditional on a reported CI failure ([`workflows/ship.md`](../workflows/ship.md), anchor: `Evidence-First CI Failure Triage and Release Linkage`), and the QA review checklist 1,534 tok, which is review evidence rather than a per-task record. An L2 task that both hands off and expands scope carries 1,760 tok beyond its required set.

**Provenance and reproduction.** `bash scripts/measure-ceremony-overhead.sh` prints the policy anchors, every artifact line, the shared-setup total, the per-level totals, the specification band, and a provenance line; `scripts/measure-ceremony-overhead.ps1` is its behavioural twin and prints the same lines with the same verdicts. `--strict` / `-Strict` asserts **equality** — not a ceiling — between every published figure and the baseline recorded in the script, and runs in CI as *Assert Ceremony Artifact Baselines* in both the Linux and Windows jobs. Equality is deliberate: growth and reduction both mean a template changed, and every figure published here must be restated in the same commit, so a one-sided gate would let a shrinking template keep a table that has quietly become wrong. Coverage is every figure the gate can derive from a template file — the four per-level totals, the shared setup, **each required artifact on its own**, all four specification variants, all five optional artifacts, and both band endpoints for Level 2 and Level 3. The per-artifact units matter: without them, offsetting drift inside one level cancels out, so adding 400 bytes to `release-evaluation-template.md` while removing 400 from `contract-impact-evidence-template.md` would leave the Level 3 total unchanged and the gate green. With them, both artifacts fail. Padding an `auth-matrix` or a `code-review-checklist` fails too, even though neither appears in a per-level total. A unit with no recorded baseline fails rather than passing unrecorded. The figures this gate does **not** cover are the ones it cannot derive from a file: the growth ratio and the per-sub-trigger "L2 total with it" column are arithmetic over covered units, and the untemplated review report has no bytes to pin. The measurement is deterministic — same tree, same numbers — and uses the repository convention `floor((bytes after CR stripping + 2) / 4)`.

**What the anchors do and do not catch.** Policy names *commands* (`pk:plan`, `pk:ship`), never template filenames, so no parser can derive the artifact list from the text; the selection is curated and documented as such. What the script can assert is that the policy it rests on has not moved: each of the fifteen cited lines is pinned by the SHA-256 of the **whole line**, so rewriting a cited sentence — or appending a requirement to it, as in "…before implementation begins. A Threat Model Record at `docs/threats/<task-id>.md` is also required." — fails the run with `ANCHOR_ERROR|POLICY_DRIFT` instead of leaving a green gate over a stale list. It does **not** catch a requirement added elsewhere in a workflow file, in a different paragraph or a different file: those edits leave every pinned line untouched and the gate green. The artifact list is therefore only as current as the last human reading of the workflows, and this paragraph is the honest statement of that limit rather than a claim of completeness.

> **What these figures are not.** They are the size of the *selected template set* at each level — the text of the artifacts policy makes mandatory. They are not measured task cost, not the cost of filling a record (filling costs generation; reproducing 5,372 tokens of template is not the same as writing a Task Record), and not the runtime cost of the ceremony. Live per-level overhead — tool calls, elapsed time, model/host identity, human interventions, revision cycles — is **not measured**: this repository captures no host telemetry, so those fields are reported as `not measured` by the script rather than estimated. Representative L0–L3 tasks profiled at three or more runs per level remain the open acceptance criterion on #607; this section does not claim them.

> **Namespace note.** The bare `CEREMONY|` line prefix is reserved by the benchmark task card [`benchmarks/tasks/TASK-BENCH-L1-02.md`](../benchmarks/tasks/TASK-BENCH-L1-02.md) for `scripts/measure-per-task-tokens.sh`; this measurement emits `CEREMONY_ANCHOR|`, `CEREMONY_ARTIFACT|`, `CEREMONY_SHARED_SETUP|`, `CEREMONY_TOTAL|`, `CEREMONY_SPEC_BAND|`, `CEREMONY_BASELINE|`, and `CEREMONY_PROVENANCE|` so the two never collide.

## 3. Dynamic Per-Task Context Economics & Runtime Benchmarks

PromptKit OS benchmarks both the **static footprint** (1,489 tok Lite, 2,449 tok Balanced) and the **dynamic per-task runtime context**.

By embedding decision-grade Level 0–3 classification directly into the static directive and adopting lazy convention loading (`$KIT_DIR_REL/workflows/<trigger>.md`), agents classify tasks without a mandatory preload of `workflows/route.md` (6,962 tokens at the archived review's source revision `258cf8c`; 9,513 tokens at the current banner anchor). Change A's modeled saving was 6,915 tokens – the 6,962-token route figure less the 47-token modeled directive growth recorded by the landed Change A record (1,882 → 1,929). That saving belongs to the historical baseline; the current end-to-end payloads are measured below and do not reuse it.

**Methodology for per-task table:**
- Historical comparison anchors: `fc98f2f` (after 2+1 profiles) and `c34be80` (before profiles, Balanced only). These SHAs identify historical inputs; they are not the source of the refreshed current values, and neither is the source of the per-task baseline constants below – those trace to the archived 2026-09-12 review at `258cf8c`, which predates both (see **Historical baseline provenance** below).
- Comparison-input fingerprint: base revision `2b6c9e9db5f0b8fe8e54f8e6f7d7eb4bd80b6e40` plus measured-input diff SHA-256 `8f0f0d2313d6ad3b633f9f156cb6f39966cc4728dce836d596f99589d60e454d`, captured on 2026-10-02 for the prior comparison. The digest is reproducible with `git diff --binary 2b6c9e9db5f0b8fe8e54f8e6f7d7eb4bd80b6e40 -- 'workflows/*.md' protocols/code-quality-gate.md templates/agent-directive-template.md templates/agent-directive-lite-template.md templates/tech-spec-template.md templates/release-checklist.md | sha256sum`; it is not the source of the current figures. Per-task values were re-measured 2026-10-12 at `d41cf10a5157351578d0e66b5a9056c10cef1a00` including the #609/#610 changes with `bash scripts/measure-per-task-tokens.sh` (`pk:fix` and `pk:plan` unchanged at 11,320/10,435 and 20,820/19,935; `pk:ship` moved to 17,118/16,233 with the added workflow-link text); the anchor is restated here from the prior `044c557`, whose sentence is superseded for `pk:ship` but preserved as history in the remainder of this paragraph. The anchor is the commit the figures were measured at, and it DOES move when a measured input changes: `60765c3` compressed the trigger descriptions in `templates/agent-directive-template.md`, which is inside the measured-input set, so every Balanced figure moved with it. Re-measuring at the previous anchor `86d4e24` reproduces the superseded numbers (2,475 / 11,454 / 20,954 / 17,228), which is why the anchor is restated rather than left to drift. **A commit that touches only documentation reproduces these figures exactly; any commit touching `workflows/*.md`, `protocols/code-quality-gate.md`, or a measured template must restate this anchor and re-propagate. (The figures are anchored at `d41cf10a5157351578d0e66b5a9056c10cef1a00`; the earlier `6efe91f` and `60765c3` anchors are retained above only as history and no longer reproduce the current values, because the #609/#610 workflow-link edits and the mode-aware notes-ownership correction changed measured inputs.)** The Lite-column payloads (10,435 / 19,935 / 16,233) were re-measured 2026-10-14 with the Lite revision committed in `3f3f86f123f43e962a3c41ddedb26b323184ddc6`; the Balanced columns reproduce at the stated `d41cf10a5157351578d0e66b5a9056c10cef1a00` anchor. The per-task payloads were re-measured again 2026-10-25 at the then-current banner anchor `7fe881586e69906ad07e822b65a342401162ccf2` after the #668 ceremony-vocabulary normalization moved `pk:plan` to 20,817 / 19,932 tok (Balanced / Lite); `pk:fix` and `pk:ship` reproduce unchanged at 11,320 / 10,435 and 17,118 / 16,233 tok. The per-task payloads moved again 2026-10-25 with the doctor six-check enumeration change: the Balanced directive grew to 2,348 tok (9,393 B), moving `pk:fix` to 11,335 / 10,443, `pk:plan` to 20,824 / 19,932, and `pk:ship` to 17,125 / 16,233 tok (Balanced / Lite). The per-task payloads moved once more 2026-11-12 with the untrusted-content directive: the Balanced directive grew to 2,410 tok (9,640 B) and the Lite directive to 1,491 tok (5,962 B), moving `pk:fix` to 11,397 / 10,478, `pk:plan` to 20,886 / 19,967, and `pk:ship` to 17,187 / 16,268 tok (Balanced / Lite). The 2026-11-13 review fixes then extended the same guardrail bullet with a project-config carve-out: the Balanced directive grew to 2,449 tok (9,797 B) and the Lite directive moved to 1,489 tok (5,957 B), moving `pk:fix` to 11,436 / 10,476, `pk:plan` to 20,925 / 19,965, and `pk:ship` to 17,226 / 16,266 tok (Balanced / Lite).
- Historical baseline payload = directive 1,882 + route 6,962 + workflow + gate (old behavior before Change A), plus the same task template where applicable. All constants are per-file `floor(bytes / 4)` values measured at `258cf8c`; the complete decomposition is in **Historical baseline provenance** below.
- Current JIT payload = directive 1,489-2,449 + workflow + gate + relevant task template (route.md is not loaded by default).
- Current Lite vs Balanced static directive sizes: 1,489 vs 2,449 tokens.

### Historical baseline provenance (source revision `258cf8c`)

The three baseline constants in the table below are the **frozen historical loading-policy baseline**, not a current measurement. Their source revision is `258cf8c` (2026-09-13), the scope commit of the archived review in [`docs/token-efficiency-review.md`](./token-efficiency-review.md) (dated 2026-09-12, "measured, not estimated"). Every component reproduces exactly at that revision under the historical convention, so the decomposition is mechanically checkable rather than asserted:

```text
pk:fix   = directive 1,882 + route 6,962 + fix 2,089 + gate 1,928                                         = 12,861
pk:plan  = directive 1,882 + route 6,962 + plan 5,772 + gate 1,928 + context-sync 2,882 + tech-spec 5,240 = 24,666
pk:ship  = directive 1,882 + route 6,962 + ship 8,292 + gate 1,928 + context-sync 2,882 + checklist 2,815 = 24,761
```

The **2,882-token contribution is [`protocols/context-sync.md`](../protocols/context-sync.md)** (11,531 B), which the old progressive-loading policy pulled into both `pk:plan` and `pk:ship`; it is not part of `pk:fix`. `gate` is `protocols/code-quality-gate.md` (1,928 tok), and the two template terms are `templates/tech-spec-template.md` (5,240 tok) and `templates/release-checklist.md` (2,815 tok).

**Two conventions, and they are not the same.** These historical figures are **per-file `floor(bytes / 4)`** over the raw byte count, with no CR stripping: the directive 7,530 B → 1,882, `route.md` 27,850 B → 6,962, `ship.md` 33,168 B → 8,292. The current tooling is **per-file `floor((bytes + 2) / 4)` after stripping CR bytes** (`scripts/measure-tokens.{sh,ps1}`, `scripts/measure-per-task-tokens.{sh,ps1}`). The `+2` rounding term is not cosmetic, so the two are not interchangeable: the same `258cf8c` directive reads 1,882 historically and 1,883 currently, and `route.md` read 9,473 raw against a 9,474 tool report at the 2026-10-02 comparison revision (the current figure is 9,505 tok at the banner anchor). Baseline constants are therefore stated under the historical convention while current payloads are summed under the current one.

**Three different things, kept distinct:**

- the **archived review** – [`docs/token-efficiency-review.md`](./token-efficiency-review.md), archived 2026-09-14 and scoped to `258cf8c`: an analysis with recommendations, preserved for provenance and never re-measured;
- the **historical baseline** – the frozen constants above, a fixed denominator that does not move when the source tree changes; and
- the **current JIT measurements** – the payload columns and percent reductions, recomputed from the checked-out tree on every run.

`fc98f2f` and `c34be80` anchor the *historical profile comparison* named above. Measured at `fc98f2f`, the directive is 2,075 tok and `route.md` is 6,916 tok under the historical convention: a different tree, and not the source of this baseline.

### Measured Per-Task Context Breakdown (bytes / 4 convention, after Change A + B):

| Workflow Path | Task Type & Loaded Scope | Baseline Payload (before A) | PromptKit OS JIT Payload (Balanced) | PromptKit OS JIT Payload (Lite) | Context Reduction vs Baseline |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **`pk:fix`** | Localized bug fix (Directive + `fix.md` + `code-quality-gate.md`) | 12,861 tok | **11,436 tok** | **10,476 tok** | **-11% Balanced, -19% Lite (-1,425 to -2,385 tok)** |
| **`pk:plan`** | Controlled feature planning (Directive + `plan.md` + `tech-spec` + `gate`) | 24,666 tok | **20,925 tok** | **19,965 tok** | **-15% Balanced, -19% Lite (-3,741 to -4,701 tok)** |
| **`pk:ship`** | Release candidate & verification (Directive + `ship.md` + `code-quality-gate.md` + release checklist) | 24,761 tok | **17,226 tok** | **16,266 tok** | **-30% Balanced, -34% Lite (-7,535 to -8,495 tok)** |

> **How to read the comparison table.** The **numerator** (the Balanced and Lite JIT payload columns, and the percentages derived from them) is a **current deterministic sum** of the selected instruction-file payloads – current directive + workflow + `code-quality-gate.md` + the relevant task template, measured from the checked-out tree. The **denominator** (`Baseline Payload (before A)`: 12,861 / 24,666 / 24,761 tok) is the **fixed historical loading-policy baseline** at `258cf8c` documented above. Each published percentage therefore means **current modeled payload against that frozen historical baseline**. It is **not** a freshly measured contemporaneous baseline, **not** total session-token usage, and **not** measured inference cost or a development-speed improvement. The six absolute payload figures (Balanced 11,436 / 20,925 / 17,226; Lite 10,476 / 19,965 / 16,266 tok) are current measurements; only the denominator is frozen.

> **Budget headroom: the binding constraint was relieved by description compression, not by raising the cap.** The Balanced static directive grew 2,350 tok (#503) → 2,401 tok (#531) → 2,475 tok (#527–#530), leaving **25 tokens of a 2,500 cap** — roughly one rule short of the ~70-75 tokens a new governance or recovery rule costs. Compressing the 26 `pk:` trigger *descriptions* in `templates/agent-directive-template.md` (names and aliases untouched, so discoverability is unchanged) brought the directive to **2,287 tok — 213 tokens of headroom**. The install-time engine stamp then cost 25 tok; the #547 `pk:doctor` trigger line then added 29 tok, the 2026-10-25 doctor six-check enumeration swap added 7 tok, the 2026-11-12 untrusted-content directive added 62 tok, and the 2026-11-13 review fixes added 39 tok, so it now sits at **2,449 tok — 51 tokens of headroom**, roughly one rule of room. The 2,500 cap was **not** raised. Lite sits at 1,489 of 1,500 (11 headroom). The lesson generalizes: the trigger catalog was carrying ~425 tok of prose that restated what each workflow file already says, and the names alone are cheap. When a rule no longer fits, extract the *detail* to a lazy-loaded protocol and leave a pointer — the pattern #526 and #529 already use — before reaching for the cap. Do not absorb this by silently raising the cap.
>
> **Per-task savings are eroding, and the table above does not show it.** The comparison baseline is a fixed historical constant, so every payload addition shows up as a smaller reduction: `pk:fix` has moved 24% → 12% Balanced on the current `main` baseline (9,785 → 11,320 tok). Most of that erosion is contract text, not overhead regression — the #528 detour discipline in `workflows/fix.md` (+812 tok) and the #530 aggregate round budget in `protocols/code-quality-gate.md` (+783 tok, loaded by all three measured tasks). Compression works in the other direction too: #536 removed 188 tok of trigger-description prose from the directive, which is why all three Balanced payloads dropped by exactly 188 tok and the reductions ticked back up one point each. The absolute figures remain honest and reproducible; read the trend, not only the endpoint, when judging whether a payload change is acceptable.

### Baseline Methodology Decision

**Decision: retain the frozen historical baseline with explicit provenance and scope.**

The alternative considered was replacing the 12,861 / 24,666 / 24,761 denominator with a reconstructed modern counterfactual: re-deriving what the old loading policy would have cost against today's larger workflow files. That was rejected, because a reconstruction models a run that never happened, while the frozen constants are an **observed measurement of a real tree at a named revision**. The two are not equivalent, and publishing a reconstructed denominator would present a model as though it were a measurement. The reductions such a counterfactual model produces are consequently **not** measured current improvements, and they are not published as current results here. Keeping the observed baseline also keeps the trend legible: because the denominator is fixed, a rising payload cannot be masked by a denominator that rises with it.

**Revisit trigger:** reconsider a new baseline only when an equivalent, reproducible and clearly defined comparison can be established – one measured from a named, reachable revision, reproducible by a documented command, and comparable in scope to the current payload definition. Until then the frozen baseline stands, with its scope stated here rather than implied. This decision adds no second denominator and no new CI gate.

### Planning-Intake Cost: One-Time Premium, Zero Steady State

The intake wave adds a bounded one-time cost and no steady-state cost (measured at `db4da7c`, `bytes/4` convention, reproducible via `wc -c protocols/discovery-intake.md workflows/plan.md`):

| Intake cost item | Measurement | Tokens |
| :--- | :--- | ---: |
| `protocols/discovery-intake.md` (12,635 B, lazy-loaded only while intake is incomplete) | new file | 3,159 |
| `workflows/plan.md` Step 0 preflight growth (22,660 → 25,835 B) | +3,175 B | +794 |
| **One-time premium total** | | **~3,953** |
| **Steady state after intake closes** (`complete` or `legacy-partial`) | protocol unloaded | **0 additional** |

### Key Runtime Efficiencies:
1. **Time-to-First-Action (TTFA)**: Eliminates 1 full tool-reading turn on Turn 1 (no longer loads `route.md` 6,962 tok to discover Level 0 is zero overhead), saving modeled latency on every interaction. Measured via Turn 1 file reads before/after Change A.
2. **Context Window Endurance**: Chat conversations maintain high attention reasoning for longer durations (modeled at additional turns) before reaching compaction thresholds (parent thread saves ~98.7% via subagent delegation, see §4).
3. **Pure Host Isolation**: Repository-internal governance (e.g. `docs/internal/release-evaluation.md`) is decoupled from consumer workflows, keeping `ship.md` lean (~5,971 tokens vs 8,292 before extraction; ~4,627 at the time of extraction).

---

## 4. Subagent Context Preservation Mechanics

In complex multi-file tasks (code reviews, multi-package monorepo scans, architecture spikes), dumping raw search results or multi-file contents into the primary conversation window causes severe context window bloat and attention degradation.

PromptKit OS enforces strict **Subagent Delegation with Compact Synthesis** ([`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md)):

```text
[Main Thread] ──(Delegates Scan)──> [Subagent Context]
                                          │
                                     Reads 15 files & tool traces
                                     (~20,000 raw tokens)
                                          │
[Main Thread] <──(5-15 line report)───────┘
  Consumes only ~250 tokens
```

### Mathematical Context Efficiency
- **Raw File Inspection in Main Context**: 15 source files @ 1,300 tokens/file = **~19,500 tokens** added to permanent conversational history.
- **Subagent Delegation**: Subagent absorbs the 19,500 token traversal in an isolated thread and emits an indexed, 12-line synthesized finding with line references = **~250 tokens** returned to main thread.
- **Effective Context Window Preservation**: **~98.7% reduction in parent-thread context payload**. *Note: This preserves parent working memory and reasoning attention; it does not imply an equivalent reduction in total model tokens consumed across both threads combined.*

---

## 5. Engineering ROI & Regressions Prevention

Beyond token counts, PromptKit's structured protocols deliver qualitative engineering improvements:

### 1. Stopping Speculative Guess-and-Patch Loops (`pk:debug`)
- **Unstructured Debugging**: AI repeatedly modifies speculative code without a reproduction mechanism, resulting in 4–8 iterative failure turns (~8,000–15,000 tokens) and broken regressions.
- **PromptKit Protocol**: Mandates building a sub-3-second deterministic reproduction test before writing application patches. Zero code is modified until the failure hypothesis is proven.

### 2. Eliminating Single-Step Destructive Migrations (`pk:data` / `pk:ship`)
- **Unstructured Database Changes**: Direct `DROP COLUMN` or column renaming causing downtime or breaking rolling deployment pods.
- **PromptKit Protocol**: Strict Expand-Contract phased migrations for live or compatibility-sensitive data (add additive column -> backfill -> switch reads -> deprecate -> drop in separate release; one-shot/disposable/pre-deployment may skip with rationale).

### 3. Preventing Session Amnesia (`pk:checkpoint`)
- **Unstructured Multi-Turn Drift**: After 30 turns, LLM forgets locked architectural decisions.
- **PromptKit Protocol**: Compresses state into git-tracked `docs/STATE.md` and generates fresh-session handover prompts intended to mitigate context-loss regressions.

---

## 6. Architectural Comparison: PromptKit OS vs. Autonomous Multi-Agent Swarms

While autonomous multi-agent looping frameworks attempt to solve software engineering via unmonitored background sub-agent loops and complex runtime daemons, they introduce significant token multipliers, harness complexity, and context exhaustion risks.

| Architectural Dimension | PromptKit OS (Disciplined Pairing OS) | Autonomous Multi-Agent Swarms |
| :--- | :--- | :--- |
| **Execution Model** | **Human-in-the-Loop Pairing**: AI proposes, verifies against Gherkin AC, and human reviews/commits. | **Autonomous Looping**: Agents iterate in unmonitored background loops until stopped or timed out. |
| **Token Footprint** | **Lean 1x Baseline**: Just-In-Time filesystem loading (measured token overhead vs monolithic). Unused workflows consume 0 tokens. | **Additional Model Calls**: Multi-agent pipelines (research $\rightarrow$ planning $\rightarrow$ execution waves) introduce additional model calls and aggregate token overhead proportional to pipeline depth and context size. |
| **State Persistence** | **Git-Tracked Plain Markdown**: `docs/STATE.md` and `docs/tasks/` survive session resets and IDE restarts. | **Hidden Local Cache Directories**: Prone to lock-file race conditions and uncommitted state drift. |
| **Context Degradation** | **Proactive Reset Cadence**: `pk:checkpoint` flushes state before context window limits cause attention degradation. | **Exhaustion Vulnerability**: Looping pipelines frequently drive model working memory to limits before persisting state. |
| **Quality & Done-Gates** | **Enforced Verifiable Gates**: Strict Milestone Git Boundaries, automated secret scans, and test verification proof. | **Timeout Heuristics**: Fragile duration or turn heuristics that can stall or abort long-running tasks. |
| **Infrastructure & Lock-In** | **Zero Binaries or Daemons**: Pure markdown protocols running in any AI host without background processes. | **High Complexity Tax**: Requires dedicated runtime adapters, orchestrators, and daemon dependencies. |
| **Secret Hygiene** | **Intended Safeguard**: Enforces `.env.example` templates and aims to block secrets from chat and CLI history. | **Vulnerable**: Unmonitored subagents frequently leak credentials into shell execution history. |

---

## 7. Resource Optimization: Matching Model Tier to Ceremony Level

In addition to static prompt JIT loading, PromptKit OS provides significant token cost savings through **Adaptive Ceremony Model Tiering** ([`workflows/route.md`](../workflows/route.md)):

```
┌─────────────────────────────────────────────────────────────────────────┐
│              CEREMONY-TO-MODEL TIER RESOURCE MAPPING                    │
├─────────────────────────────────────────────────────────────────────────┤
│ Level 0 (Direct / Typos)    ──► Economy Tier (Gemini Flash, Haiku)      │
│ Level 1 (Standard Feature)  ──► Balanced Tier (Sonnet, Flash-High)     │
│ Level 2 (Controlled Schema) ──► Frontier Reasoning Tier (Pro, o3-mini)  │
│ Level 3 (Release-Critical)  ──► Max Reasoning Tier (Opus, o1)           │
└─────────────────────────────────────────────────────────────────────────┘
```

- **Avoid Flagship Burn on L0 Tasks**: Standard coding assistants frequently waste expensive flagship reasoning tokens on basic single-line formatting, regex syntax checks, or documentation typo fixes. Routing Level 0 tasks to economy models reduces token spend significantly on daily ad-hoc queries.
- **Avoid Reasoning Failures on Hard Tasks**: Conversely, under-powering database migrations (Expand-Contract) or authentication boundary redesigns with lightweight models causes expensive defect repair loops. Deploying deep reasoning models exclusively on Level 2/3 work provides a verification standard for intended zero-downtime safety while keeping total aggregate token budgets lean.

---

## 8. Turbo Protocol Economics — Measured Bounds & Decision (Issue #145)

**Measurement provenance:** `bash scripts/measure-turbo-overhead.sh` (deterministic static analysis, bytes/4). Turbo is a **documentation protocol**, not a runtime engine — there is no installed binary to profile. This section measures the *protocol's* fan-out token budget; actual host behavior varies with subagent implementation. "Time saved" figures are **structural upper bounds**, not empirical seconds.

**Model.** A Turbo branch runs in a fresh context. Beyond the first branch, each parallel lane costs either a directive reload + 250-tok synthesis return (lower bound) or a full task-path context reload (upper bound).

**Measured (main @ `76e3168`, directive 2,496 tok; re-baselined 2026-09-16, prior measurement `719a74e` @ 2,319 tok):**

| Task path | Balanced tok | Turbo tok (lower–upper) | Multiplier | Time saved (bound) | Fan-out anchor |
| :--- | ---: | :--- | :--- | :--- | :--- |
| `pk:fix` | 6,722 | 6,722–6,722 | **1.00x** | 0% (single-thread) | `route.md` Tier-3 offload only |
| `pk:plan` | 16,225 | 18,971–32,700 | **1.17x–2.02x** | ≤50% of spike segment | Delegation Pattern A (k=2) |
| `pk:ship` | 11,879 | 14,625–24,008 | **1.23x–2.02x** | ≤50% of QA segment | Pattern B (k=2) + Pattern C verifier |

**Decision (per #145 threshold rule):** **KEEP Turbo experimental — do not promote, do not remove.** Measured overhead tops out near **2x**, materially below the "3-5x" band previously advertised, and the structural time benefit caps at ~50% of only the parallelizable segment. Promotion would require real multi-host wall-clock evidence that a documentation protocol cannot produce; removal would discard a genuinely useful (≤2x) pattern for greenfield spikes. All shipped "3-5x" claims were corrected in this change to "up to ~2x measured" and the claim window is now CI-gated (`--strict`, 1.00–2.60x): widening fan-out without re-baselining this section fails the build.

**Revisit trigger (per #213):** this verdict expires on the earlier of (a) multi-host wall-clock evidence for promotion being presented, or (b) the next minor version release. On expiry, record a new dated verdict entry (promote / keep / remove with rationale and disconfirming evidence) and re-arm this trigger — experimental status never persists by silence.

**2026-10-02 re-confirmation (v1.10.1):** KEEP Turbo experimental. The previous trigger window closed with no multi-host evidence presented; trigger re-armed to the next minor release.

**2026-10-25 re-confirmation (v2.0.1, closing the lapsed v1.11.0 / v2.0.0 / v2.0.1 windows):** KEEP Turbo experimental. The intervening minor and major windows closed with no multi-host wall-clock evidence presented and no change to the measured fan-out patterns; the CI-gated claim window (1.00–2.60x) still bounds every shipped figure. The missed re-arm at v1.11.0 is a recording lapse, not a silent promotion — this entry restores the dated-verdict discipline. Trigger re-armed to the next minor release.

**Safety invariant (AC-3, grep-asserted by the script):** Turbo never removes the human Level-3 approval requirement for releases, tags, deployments, or rollback, in any shipped surface.

---

## 9. Proxy Validation: `bytes/4` vs Real Tokenizers (Issue #194)

The figures in this section use the `bytes/4` proxy. Issue #194 validated that convention against real tokenizers without replacing it; `bytes/4` remained the gated convention and the validation did not change the published figures at that time.

> [!IMPORTANT]
> This section is **ungated** — `scripts/measure-tokenizer-delta.sh` always exits 0 and prints `SKIPPED` when `tiktoken` is unavailable, so no CI job fails when these rows go stale. That is a deliberate trade (the check needs network-free BPE data and is validation-only), but it means staleness is caught by review, not by a gate. Re-run it in the same change that touches a measured input, and treat a stale row here as a documentation defect. See `CONTRIBUTING.md` item 4.

**Current measurement:** The tokenizer comparison below was re-measured 2026-10-12 at `d41cf10a5157351578d0e66b5a9056c10cef1a00` including the #609/#610 changes and the mode-aware notes-ownership correction, superseding the 2026-10-09 snapshot, the 2026-10-08 snapshot, the 2026-10-06 snapshot, the 2026-10-05 `401cc9e` one, the 2026-10-02 `2b6c9e9` one, the 2026-10-01 `e159c70` one, and the earlier 2026-09-28 `b7e9c8c` one. Validation only — `bytes/4` remains the gated convention and no published budget figure changed. The re-run at the mode-aware correction moved no row because `workflows/tutor.md` is not among the tokenizer-measured files. One row moved at the prior #609/#610 re-measurement and remains corrected here: `workflows/ship.md` grew with the added template-scaffold pointer (5,947 → 5,971 `bytes/4`; CL100K 4,653 → 4,675; O200K 4,654 → 4,678), leaving its RATIO effectively unchanged at 0.783 (was 0.782). Previously, `workflows/route.md` grew with router-coverage documentation (9,310 → 9,474 `bytes/4`; CL100K 8,080 → 8,221; O200K 8,054 → 8,193) at the 2026-10-09 re-measurement. The remaining rows still match the 2026-10-09 snapshot. Only the Lite directive row has been refreshed for the Lite revision committed 2026-10-14 in `3f3f86f123f43e962a3c41ddedb26b323184ddc6`; every other row matches the prior 2026-10-12 snapshot above. One pre-existing discrepancy was corrected on the 2026-10-21 re-run for #646: `protocols/discovery-intake.md` had not been re-measured after the #641 intake-provenance changes (3,938 → 5,045 `bytes/4`; CL100K 3,458 → 4,427; O200K 3,446 → 4,403), leaving its RATIO unchanged at 0.878. That correction is unrelated to the #646 `workflows/doctor.md` edit, which is not among the tokenizer-measured files and moved no row. The 2026-10-22 re-run for #644 moved one row: `protocols/discovery-intake.md` grew with the #644 host-documentation divergence contract (5,045 → 6,180 `bytes/4`; CL100K 4,427 → 5,458; O200K 4,403 → 5,415), leaving its RATIO effectively unchanged at 0.883 (was 0.878); `workflows/onboard.md` is not among the tokenizer-measured files, so it moved no row. The 2026-10-24 re-run for #664 moved one row: `workflows/route.md` grew with the Tier-1 banner restatement and Tier-2 `pk:auto` routing clarifications (9,474 → 9,506 `bytes/4`; CL100K 8,221 → 8,257; O200K 8,193 → 8,229), leaving its RATIO effectively unchanged at 0.869 (was 0.868); every other row reproduces the #644-state values exactly. The 2026-10-24 re-run for #668 moved two rows: `workflows/plan.md` shrank with the ceremony-vocabulary normalization (7,602 → 7,599 `bytes/4`; CL100K 6,165 → 6,163; O200K 6,153 → 6,151) and `workflows/route.md` shrank (9,506 → 9,505 `bytes/4`; CL100K 8,257 → 8,261; O200K 8,229 → 8,231), both RATIOs effectively unchanged (0.811 and 0.869). The 2026-10-25 re-run for the doctor six-check catch-up moved three rows: `templates/agent-directive-template.md` (2,341 → 2,348 `bytes/4`; CL100K 2,376 → 2,380; O200K 2,366 → 2,370; RATIO 1.015 → 1.014), `workflows/route.md` (9,505 → 9,513; CL100K 8,261 → 8,265; O200K 8,231 → 8,235; RATIO unchanged 0.869), and `workflows/fix.md` (3,582 → 3,590; CL100K 3,055 → 3,058; O200K 3,041 → 3,043; RATIO 0.853 → 0.852); every other row reproduces the #668-state values exactly. The 2026-11-12 re-run for the untrusted-content directive moved two rows: `templates/agent-directive-template.md` (2,348 → 2,410 `bytes/4`; CL100K 2,380 → 2,430; O200K 2,370 → 2,419; RATIO 1.014 → 1.008) and `templates/agent-directive-lite-template.md` (1,456 → 1,491; CL100K 1,499 → 1,527; O200K 1,495 → 1,523; RATIO 1.030 → 1.024); every other row reproduces the doctor six-check-state values exactly. The 2026-11-13 re-run for the four review fixes moved the same two rows: `templates/agent-directive-template.md` (2,410 → 2,449 `bytes/4`; CL100K 2,430 → 2,463; O200K 2,419 → 2,451; RATIO 1.008 → 1.006) and `templates/agent-directive-lite-template.md` (1,491 → 1,489; CL100K 1,527 → 1,528; O200K 1,523 → 1,523; RATIO 1.024 → 1.026); every other row reproduces the untrusted-content-state values exactly.

**Provenance:** `tiktoken 0.14.0`, encodings `cl100k_base` + `o200k_base`, measured 2026-10-12 at `d41cf10a5157351578d0e66b5a9056c10cef1a00` including the #609/#610 changes and the mode-aware notes-ownership correction (prior: 2026-10-09, 2026-10-08, 2026-10-06, 2026-10-05 at `401cc9e`, 2026-10-02 at `2b6c9e9`). Current Lite refresh: only the Lite row was re-measured 2026-10-14 with `tiktoken 0.14.0` for the Lite revision committed in `3f3f86f123f43e962a3c41ddedb26b323184ddc6` (revised Lite SHA-256 `ffc0349a97fdce97490b9bbab73067674df2640b05a38cdd5268079931afacd0`, reproducible with `sha256sum templates/agent-directive-lite-template.md`; all other rows remain as measured 2026-10-12 at `d41cf10a5157351578d0e66b5a9056c10cef1a00`). Reproduce with `bash scripts/measure-tokenizer-delta.sh` (offline-safe: prints `SKIPPED`, exits 0 without network). RATIO = CL100K / BYTES4. Re-run 2026-10-21 for #646 with `tiktoken 0.14.0`: no row moved from the `workflows/doctor.md` documentation, and the `protocols/discovery-intake.md` row was corrected for the pre-existing #641 discrepancy documented above. This table is **not** gated and never fails the build, so unlike the sections above it has no CI guard against going stale: re-run it whenever a measured input changes, which is every release that touches `workflows/`, `protocols/code-quality-gate.md`, or a measured template. Re-run 2026-10-22 for #644 with `tiktoken 0.14.0`: the `protocols/discovery-intake.md` row moved as documented above; the `workflows/onboard.md` edit is not among the tokenizer-measured files and moved no row. Re-run 2026-10-24 for #664 with `tiktoken 0.14.0`: the `workflows/route.md` row moved as documented above; no other row changed. Re-run 2026-10-25 for the doctor six-check catch-up with `tiktoken 0.14.0`: the directive, `route.md`, and `fix.md` rows moved as documented above; no other row changed. Re-run 2026-11-12 for the tracking-gate documentation correction with `tiktoken 0.14.0`: no row moved, because `workflows/tasks.md` is not among the tokenizer-measured files. Re-run 2026-11-12 for the tracking-gate scope correction with `tiktoken 0.14.0`: no row moved again, for the same reason. Re-run 2026-11-12 for the untrusted-content directive with `tiktoken 0.14.0`: the two directive rows moved as documented above; no other row changed. Re-run 2026-11-13 for the four review fixes with `tiktoken 0.14.0`: the same two directive rows moved as documented above; no other row changed.

| File | BYTES4 | CL100K | O200K | RATIO |
| :--- | ---: | ---: | ---: | ---: |
| `templates/agent-directive-template.md` | 2,449 | 2,463 | 2,451 | 1.006 |
| `templates/agent-directive-lite-template.md` | 1,489 | 1,528 | 1,523 | 1.026 |
| `workflows/plan.md` | 7,599 | 6,163 | 6,151 | 0.811 |
| `workflows/route.md` | 9,513 | 8,265 | 8,235 | 0.869 |
| `workflows/fix.md` | 3,590 | 3,058 | 3,043 | 0.852 |
| `workflows/ship.md` | 5,971 | 4,675 | 4,678 | 0.783 |
| `protocols/discovery-intake.md` | 6,180 | 5,458 | 5,415 | 0.883 |

**Verdict (published as measured):**

- **The gates bound the `bytes/4` proxy, not a tokenizer.** The Balanced directive reads ~0.6% low against `cl100k_base` (2,449 proxy vs 2,463 actual) and Lite ~2.6% low (1,489 vs 1,528). `scripts/measure-tokens.sh` compares `(bytes + 2) / 4` against the 2500/1500 caps and never invokes a tokenizer, so the caps are proxy bounds: the Lite directive passes its 1,500 gate at 1,489 proxy while measuring 1,528 `cl100k_base` tokens, 28 over the cap in that encoding. Read the gate as "the proxy is under budget", not as "the real token count is under budget"; the Balanced directive is the one that clears its cap in both conventions (2,449 proxy, 2,463 actual, 37 under 2,500).
- **Workflow/protocol figures are conservative.** The proxy overstates real counts by ~14–28% (whitespace, table padding, comments). Published per-task payloads are upper bounds — real costs are lower.
- **Relative savings hold approximately.** Both sides of each reduction ratio were measured in the same convention, so the overstatement largely cancels; absolute tok figures should be read as conservative estimates.
- **Encodings agree.** `cl100k_base` vs `o200k_base` differ by ≤1% on every file (max observed 0.54%) — no per-host restatement is warranted from this data.

---

## 10. Empirical Runtime Economics: The Cost Per Accepted Change (CPAC) Framework (Issue #279)

While sections 1–9 measure the **static and dynamic instruction footprint** of PromptKit OS, the **Cost Per Accepted Change (CPAC)** framework measures real-world economic efficiency during active iterative development.

Unconstrained AI coding agents often appear cheap on turn 1, but incur massive economic waste through the **rework spiral**:
1. Unbounded file searches reading 20+ files across the repo.
2. Formulating incorrect framework or architectural assumptions.
3. Repeated compilation failures, broken tests, and hallucinated API corrections.
4. Violating non-negotiable security or concurrency invariants that require expensive senior human developer triage.

PromptKit OS bounds this waste by coupling JIT Stack Playbooks (`docs/stacks/`), Contract Boundary Recipes (`docs/recipes/`), and the Evidence-Gated Verification Matrix (`protocols/telemetry-cards.md`).

For full mathematical definitions, pricing constants, and the A/B evaluation protocol:
- [`BENCHMARK-METHODOLOGY.md`](./BENCHMARK-METHODOLOGY.md) — Formal CPAC mathematical model and telemetry schema.
- [`specs/SPEC-empirical-benchmark.md`](./specs/SPEC-empirical-benchmark.md) — Multi-ecosystem benchmark scenarios (`WEB-01`, `SYS-02`, `DATA-03`).
- [`../scripts/measure-cpac.sh`](../scripts/measure-cpac.sh) — CPAC formula self-tests, a `--demo`
  SIMULATED demonstration scorecard, and measured scoring of a §5 telemetry record
  (extracted from a Command Code session transcript by `scripts/extract-commandcode-telemetry.sh`;
  invalid records exit `2`). An empirical CPAC result additionally requires records from real
  accepted sessions — the fixtures and self-tests verify mechanics, not outcomes.
- [`../benchmarks/README.md`](../benchmarks/README.md) — the A/B benchmark harness: frozen task
  specs with rubrics, the paired-run protocol over headless Command Code (PromptKit directive vs
  bare), blind grading, and per-arm aggregation through the §5 pipeline.
- [`../benchmarks/runs/2026-10-26-phase3-deepseek-v4.1-flash/README.md`](../benchmarks/runs/2026-10-26-phase3-deepseek-v4.1-flash/README.md) — the first published live batch (2026-10-26): 3 tasks × 2 arms × 1 repeat on `deepseek/deepseek-v4.1-flash`; all six runs accepted, with a higher token/CPAC mean for the PromptKit arm and both L2 sessions at the 900-second cap. Six sessions, one model, single-reviewer grading; the two L0 verify packets leaked run paths before the harness scrub, so the L0 grade is reported as only partially blind. Raw transcripts stay local; the key is withheld but derivable from the published stripped diffs. Directional evidence only.
- [`../benchmarks/runs/2026-10-31-phase3b-deepseek-v4.1-flash/README.md`](../benchmarks/runs/2026-10-31-phase3b-deepseek-v4.1-flash/README.md) — the second published live batch (2026-10-31): 6 tasks × 2 arms × 3 repeats on `deepseek/deepseek-v4.1-flash`, 36 of 36 runs accepted on a sheet the coding agent graded blind. Under §4 that machine grade is a secondary consistency check, not human acceptance, and each §5 record states it (`"grading": {"grader": "machine", "human_accepted": false}`). L1+ median ratios are 1.075 tokens and 1.115 CPAC with a task-cluster interval of 0.869–1.375 tokens; both arms solved every task on every repeat, so the batch measures cost and non-inferiority only and the outcome is Inconclusive. Directional evidence only.
- [`../benchmarks/runs/2026-10-31-phase3c-batch-deepseek-v4.1-flash/README.md`](../benchmarks/runs/2026-10-31-phase3c-batch-deepseek-v4.1-flash/README.md) — the third batch (2026-10-31), **outcome Tradeoff**: 10 discriminating cards × 2 arms × 3 repeats on a purpose-built seed, 60 primary sessions in 62 minutes for $0.55 reported cost, 59 clean exits with one provider abort retained in the denominator. 48 of 60 packets cleared their frozen rubrics — `promptkit_os` 26 of 30 runs accepted against 22 of 30 for `bare` — at a token-ratio median of 1.115. The pre-registered rule left open whether the cost bar meant both ratios above 1.05 or either; **Amendment A** settles it on the ITT token ratio alone, which makes the outcome **Tradeoff** and opens Phase 4. The primary sheet's first pass was performed by an agent under the owner's authorization, which its grading record states in full — cite it as owner-authorized agent grading, not as an independent human review. A second read of 30 of 60 packets matched the primary sheet 30/30 with no disagreements, but ran in a fresh session of the generating model's family, so it is not an independent review; the §5 records were re-extracted with `--graded-by human` on 2026-11-01, so all 60 read `grader: human` with `human_accepted` true for the 48 accepted packets. The pre-registered slate and decision rule live in [`../benchmarks/PHASE-3C-DESIGN.md`](../benchmarks/PHASE-3C-DESIGN.md).
- **Calibration runs (not evidence):** the 12-session Phase 3b calibration ([`CALIBRATION.md`](../benchmarks/runs/2026-10-31-phase3b-calibration-1repeat/CALIBRATION.md)) and the six-session Phase 3c calibration ([`CALIBRATION.md`](../benchmarks/runs/2026-10-31-phase3c-calibration-1repeat/CALIBRATION.md)) are retained beside the batches with the same per-run packet files. Both are ungraded, were never unblinded, and do not enter either batch's denominator.

---

## Related References
- [`BENCHMARK-METHODOLOGY.md`](./BENCHMARK-METHODOLOGY.md) — Cost Per Accepted Change (CPAC) empirical evaluation protocol
- [`protocols/context-economy.md`](../protocols/context-economy.md) — Context Economy, Z0–Z4 progressive zoom, & provider capability contract
- [`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md) — Subagent delegation & context preservation rules
- [`protocols/context-sync.md`](../protocols/context-sync.md) — 30-turn reset threshold & MCP discovery
- [`workflows/route.md`](../workflows/route.md) — Canonical task ceremony levels & model tiering
- [`FAQ.md`](../FAQ.md) — Common adoption questions & setup details
