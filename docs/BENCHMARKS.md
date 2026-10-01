# PromptKit OS Architecture & Token Economics Analysis

**Historical baseline:** 2026-09-14 on `main` (v1.6.0 with 2+1 profiles) · **Current measurements:** 2026-10-01, regenerated from the source tree (per-task input fingerprint in §3; rerun the commands below after input changes) · **Method:** `bytes / 4` convention via `scripts/measure-tokens.sh` · Historical monolithic baseline: core-6 lifecycle subset 19,794 tok / full 25-workflow set 75,505 tok.

This document provides a factual, mechanically verifiable analysis of the token economics, context window preservation, and engineering ROI of the PromptKit OS architecture. All numbers below can be reproduced via `bash scripts/measure-tokens.sh [file]` and `wc -c workflows/*.md`.

---

## 1. Architectural Model: Monolithic Prompt Inlining vs. Just-In-Time (JIT) Loading

Traditional AI coding packs and mega-prompts attempt to inline extensive guidelines, workflow checklists, and multi-file instructions into the root system prompt or configuration file (`.cursorrules`, `CLAUDE.md`, system instruction headers). 

PromptKit OS uses a **Just-In-Time (JIT) Filesystem Architecture**:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    MONOLITHIC MEGA-PROMPT MODEL                         │
│ Every Turn: [25 Inlined Workflows + Templates + Protocols (~101.5k tok)] │
│ Context Window Waste: High static token bloat on every single message   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                   PROMPTKIT OS JIT FILESYSTEM MODEL                     │
│ Baseline Static Injection: Router Directive (1,274 tok Lite / 2,318 Bal)  │
│ On-Demand Loading: Tool loads only target workflow file (e.g. pk:debug) │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Static Injection Footprint (Measured Tokens)

| Profile | Template | UTF-8 Bytes | Est. Tokens (bytes/4) | Reduction vs ~26.4k current core-subset baseline¹ | Use |
| :--- | :--- | ---: | ---: | :--- | :--- |
| **Lite** | `agent-directive-lite-template.md` (6 utility workflows: route, debug, commit, checkpoint, sync, profile) | 5,097 | **1,274 tok** | **95% static** | Onboarding, new users, tiny fixes |
| **Balanced** | `agent-directive-template.md` (25 workflows) | 9,273 | **2,318 tok** | **91% static** | Teams, production, default |
| **Turbo** | same as Balanced + parallel waves | 9,273 | 2,318 tok + subagents (~2x measured total (bounds model, see section 8)) | 91% static, higher total | Experimental, greenfield, accepts cost |

### Current Workflow Inventory

| Inventory | Workflow Files | Measured Tokens |
| :--- | ---: | ---: |
| Core-six Lite subset | 6 | **26,927 tok** |
| Full workflow set | 25 | **104,531 tok** |

¹ Current core-subset baseline is the live sum of the six workflow files loaded by the Lite profile (route, debug, commit, checkpoint, sync, profile); the full-set baseline includes every `workflows/*.md` file. The inventory values above are regenerated from the checked-out source revision. Historical values at the 2026-09-14 measurement were 19,794 and 75,505 tok, respectively; the previous unsourced "18.5k" constant is retired.

> **Clarification:** Static-overhead reductions compare the directive with the current core-six workflow baseline (91% Balanced, 95% Lite). Per-task payload reductions use a separate historical per-task baseline; current results are measured below (22–37% Balanced, 27–41% Lite). Neither measures session token usage, estimates live-model cost, or enforces host runtime limits. Session usage is estimated by the host; `workflows/perf.md` covers application performance profiling, not session metering. The search circuit breaker in the directive templates is advisory instruction, not deterministic tool control. Markdown instructs; it cannot stop tools by itself.

| Component (Balanced) | Lines | Approx. Token Weight | Purpose |
| :--- | :---: | :---: | :--- |
| **System Introduction & Scope** | ~13 | ~193 tokens | Identifies PromptKit root in workspace (`./.promptkit`) |
| **Fast Shorthand Triggers** | ~24 | ~295 tokens | Direct workflow routing shorthand (`pk:debug`, `pk:test`, etc.) |
| **Engineering Quality Gates** | ~36 | ~642 tokens | Secret hygiene, timeout budgets, and anti-hallucination rules |
| **Task Ceremony Levels & Output** | ~25 | ~397 tokens | Composable 4-level task ceremony engine & output protocol |
| **Standard Output Directories** | ~17 | ~226 tokens | Canonical locations for generated specs, ADRs, and plans |
| **Total Baseline Static Overhead (Balanced)** | **68 lines** | **~2,318 tokens** | **Permanent footprint in system prompt (~91% static saving vs. current ~26.4k core-subset (~98% vs. current full 25-file set))** |
| **Total Baseline Static Overhead (Lite)** | **53 lines** | **~1,274 tokens** | **95% static saving, ~55% of Balanced** |
| **Opt-in add-on: §5a LSP diagnostics** | `workflows/review.md` step 2a (~313 tok) + Diagnostics Evidence table (~134 tok) | 3,228 | **~447 tok** | Additive only when `LSP Enabled: true`; runtime evidence capped at 150 lines | **Balanced + `pk:review` on TS repos** (Lite stays at 1,274 tok — skipped silently) |

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

Gate coverage: the static dual-profile budget runs in **both** Linux and Windows CI jobs; the per-task baseline gate runs in the Linux job (PowerShell mirror tracked as a follow-up). Negative-path behavior is covered by `scripts/tests/run-token-budget-tests.sh`. Budget constants are defined once per script; this document is the human reference. If a deliberate contract expansion requires raising a budget, update the constant in `scripts/measure-tokens.sh`, `scripts/measure-tokens.ps1`, and this document in the same change.

---

## 3. Dynamic Per-Task Context Economics & Runtime Benchmarks

PromptKit OS benchmarks both the **static footprint** (1,274 tok Lite, 2,318 tok Balanced) and the **dynamic per-task runtime context**.

By embedding decision-grade Level 0–3 classification directly into the static directive and adopting lazy convention loading (`$KIT_DIR_REL/workflows/<trigger>.md`), agents classify tasks without a mandatory preload of `workflows/route.md` (6,962 tokens at the historical `fc98f2f` benchmark; 9,241 tokens at the current measurement). At the historical revision, Change A's modeled saving was 6,915 tokens (6,962 route tokens less 47 tokens of directive growth); current end-to-end payloads are measured below and do not reuse that historical estimate.

**Methodology for per-task table:**
- Historical comparison anchors: `fc98f2f` (after 2+1 profiles) and `c34be80` (before profiles, Balanced only). These SHAs identify historical inputs; they are not the source of the refreshed current values.
- Refreshed measurement input: base revision `b8e8b92cd0ad533047e5b84fb945f75157b64c42` plus measured-input diff SHA-256 `841e1042adb58c0502f1933dd187d2e8d3727cad576684744e7e39b746347eb9`, measured on 2026-10-02. The digest is reproducible with `git diff --binary b8e8b92cd0ad533047e5b84fb945f75157b64c42 -- 'workflows/*.md' protocols/code-quality-gate.md templates/agent-directive-template.md templates/agent-directive-lite-template.md templates/tech-spec-template.md templates/release-checklist.md | sha256sum`. Re-run `bash scripts/measure-per-task-tokens.sh` after applying that input diff; the script sums the current directive, workflow, `code-quality-gate.md`, and relevant task template.
- Historical baseline payload = directive 1,882 + route 6,962 + workflow + gate (old behavior before Change A), plus the same task template where applicable.
- Current JIT payload = directive 1,274-2,318 + workflow + gate + relevant task template (route.md is not loaded by default).
- Current Lite vs Balanced static directive sizes: 1,274 vs 2,318 tokens.

### Measured Per-Task Context Breakdown (bytes / 4 convention, after Change A + B):

| Workflow Path | Task Type & Loaded Scope | Baseline Payload (before A) | PromptKit OS JIT Payload (Balanced) | PromptKit OS JIT Payload (Lite) | Context Reduction vs Baseline |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **`pk:fix`** | Localized bug fix (Directive + `fix.md` + `code-quality-gate.md`) | 12,861 tok | **9,094 tok** | **8,050 tok** | **-29% Balanced, -37% Lite (-3,767 to -4,811 tok)** |
| **`pk:plan`** | Controlled feature planning (Directive + `plan.md` + `tech-spec` + `gate`) | 24,666 tok | **19,296 tok** | **18,252 tok** | **-22% Balanced, -26% Lite (-5,370 to -6,414 tok)** |
| **`pk:ship`** | Release candidate & verification (Directive + `ship.md` + `code-quality-gate.md` + release checklist) | 24,761 tok | **15,555 tok** | **14,511 tok** | **-37% Balanced, -41% Lite (-9,206 to -10,250 tok)** |

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
3. **Pure Host Isolation**: Repository-internal governance (e.g. `docs/internal/release-evaluation.md`) is decoupled from consumer workflows, keeping `ship.md` lean (~4,627 tokens vs 8,292 before extraction).

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

**Safety invariant (AC-3, grep-asserted by the script):** Turbo never removes the human Level-3 approval requirement for releases, tags, deployments, or rollback, in any shipped surface.

---

## 9. Proxy Validation: `bytes/4` vs Real Tokenizers (Issue #194)

The figures in this section use the `bytes/4` proxy. Issue #194 validated that convention against real tokenizers without replacing it; `bytes/4` remained the gated convention and the validation did not change the published figures at that time.

**Current measurement:** The tokenizer comparison below was re-measured 2026-10-01 at `main` @ `e159c70`, superseding the 2026-09-28 `b7e9c8c` snapshot and the earlier 2026-09-16 `1312831` one. Validation only — `bytes/4` remains the gated convention and no published budget figure changed.

**Provenance:** `tiktoken 0.14.0`, encodings `cl100k_base` + `o200k_base`, measured 2026-10-01 at `main` @ `e159c70` (prior: 2026-09-28 at `b7e9c8c`). Reproduce with `bash scripts/measure-tokenizer-delta.sh` (offline-safe: prints `SKIPPED`, exits 0 without network). RATIO = CL100K / BYTES4.

| File | BYTES4 | CL100K | O200K | RATIO |
| :--- | ---: | ---: | ---: | ---: |
| `templates/agent-directive-template.md` | 2,318 | 2,328 | 2,318 | 1.004 |
| `templates/agent-directive-lite-template.md` | 1,274 | 1,341 | 1,334 | 1.053 |
| `workflows/plan.md` | 7,365 | 5,978 | 5,963 | 0.812 |
| `workflows/route.md` | 9,263 | 8,039 | 8,013 | 0.868 |
| `workflows/fix.md` | 2,734 | 2,337 | 2,324 | 0.855 |
| `workflows/ship.md` | 5,947 | 4,653 | 4,654 | 0.782 |
| `protocols/discovery-intake.md` | 3,938 | 3,458 | 3,446 | 0.878 |

**Verdict (published as measured):**

- **Gated artifacts are sound.** The Balanced directive matches real tokenizers within 0.5%; Lite understates by ~5% (proxy reads low). The 2500/1500 budget gates therefore guard real cost, not just the proxy.
- **Workflow/protocol figures are conservative.** The proxy overstates real counts by ~14–28% (whitespace, table padding, comments). Published per-task payloads are upper bounds — real costs are lower.
- **Relative savings hold approximately.** Both sides of each reduction ratio were measured in the same convention, so the overstatement largely cancels; absolute tok figures should be read as conservative estimates.
- **Encodings agree.** `cl100k_base` vs `o200k_base` differ by ≤1% on every file — no per-host restatement is warranted from this data.

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
- [`../scripts/measure-cpac.sh`](../scripts/measure-cpac.sh) — Telemetry parsing and automated CPAC scorecard generation utility.

---

## Related References
- [`BENCHMARK-METHODOLOGY.md`](./BENCHMARK-METHODOLOGY.md) — Cost Per Accepted Change (CPAC) empirical evaluation protocol
- [`protocols/context-economy.md`](../protocols/context-economy.md) — Context Economy, Z0–Z4 progressive zoom, & provider capability contract
- [`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md) — Subagent delegation & context preservation rules
- [`protocols/context-sync.md`](../protocols/context-sync.md) — 30-turn reset threshold & MCP discovery
- [`workflows/route.md`](../workflows/route.md) — Canonical task ceremony levels & model tiering
- [`FAQ.md`](../FAQ.md) — Common adoption questions & setup details
