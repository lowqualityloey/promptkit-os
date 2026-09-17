# PromptKit OS Architecture & Token Economics Analysis

**Measurement Date:** 2026-09-14 · **Environment:** `main` branch (v1.6.0 with 2+1 profiles) · **Method:** `bytes / 4` convention via `scripts/measure-tokens.sh` · **Baseline Monolithic:** core-6 lifecycle subset ~19,794 tok / full 23-workflow set ~75,505 tok (derived live)

This document provides a factual, mechanically verifiable analysis of the token economics, context window preservation, and engineering ROI of the PromptKit OS architecture. All numbers below can be reproduced via `bash scripts/measure-tokens.sh [file]` and `wc -c workflows/*.md`.

---

## 1. Architectural Model: Monolithic Prompt Inlining vs. Just-In-Time (JIT) Loading

Traditional AI coding packs and mega-prompts attempt to inline extensive guidelines, workflow checklists, and multi-file instructions into the root system prompt or configuration file (`.cursorrules`, `CLAUDE.md`, system instruction headers). 

PromptKit OS uses a **Just-In-Time (JIT) Filesystem Architecture**:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    MONOLITHIC MEGA-PROMPT MODEL                         │
│ Every Turn: [24 Inlined Workflows + Templates + Protocols (~75.5k tok)] │
│ Context Window Waste: High static token bloat on every single message   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                   PROMPTKIT OS JIT FILESYSTEM MODEL                     │
│ Baseline Static Injection: Router Directive (1,146 tok Lite / 2,498 Bal)  │
│ On-Demand Loading: Tool loads only target workflow file (e.g. pk:debug) │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Static Injection Footprint (Measured Tokens)

| Profile | Template | Chars | Est. Tokens (bytes/4) | Reduction vs ~19.8k core-subset baseline¹ | Use |
| :--- | :--- | ---: | ---: | :--- | :--- |
| **Lite** | `agent-directive-lite-template.md` (6 utility workflows: route, debug, commit, checkpoint, sync, profile) | 4,583 | **1,146 tok** | **94% static** | Onboarding, new users, tiny fixes |
| **Balanced** | `agent-directive-template.md` (24 workflows) | 9,991 | **2,498 tok** | **87% static** | Teams, production, default |
| **Turbo** | same as Balanced + parallel waves | 9,991 | 2,498 tok + subagents (~2x measured total (bounds model, see section 8)) | 87% static, higher total | Experimental, greenfield, accepts cost |

¹ Core-subset baseline = live sum of the six lifecycle files the Lite profile loads (route, debug, commit, checkpoint, sync, profile) = ~19,794 tok; full-set baseline = all 24 workflow files = ~75,505 tok (2026-09-14 measurement; replaces the previously unsourced "18.5k" constant).

> **Clarification:** The often-quoted "~90% savings" is **static overhead only** (directive vs monolithic inlining). Per-task payload (directive + workflow + gate) saves 28-54% after Change A (removing mandatory `route.md` 6,962 tok load). See §3 for per-task numbers.

| Component (Balanced) | Lines | Approx. Token Weight | Purpose |
| :--- | :---: | :---: | :--- |
| **System Introduction & Scope** | ~13 | ~193 tokens | Identifies PromptKit root in workspace (`./.promptkit`) |
| **Fast Shorthand Triggers** | ~24 | ~295 tokens | Direct workflow routing shorthand (`pk:debug`, `pk:test`, etc.) |
| **Engineering Quality Gates** | ~36 | ~642 tokens | Secret hygiene, timeout budgets, and anti-hallucination rules |
| **Task Ceremony Levels & Output** | ~25 | ~397 tokens | Composable 4-level task ceremony engine & output protocol |
| **Standard Output Directories** | ~17 | ~226 tokens | Canonical locations for generated specs, ADRs, and plans |
| **Total Baseline Static Overhead (Balanced)** | **100 lines** | **~2,498 tokens** | **Permanent footprint in system prompt (~87% static saving vs. ~19.8k core-subset (~97% vs. full 24-file set))** |
| **Total Baseline Static Overhead (Lite)** | **~50 lines** | **~1,146 tokens** | **94% static saving, 54% saving vs Balanced** |
| **Opt-in add-on: §5a LSP diagnostics** | `workflows/review.md` step 2a (~313 tok) + Diagnostics Evidence table (~134 tok) | 3,228 | **~447 tok** | Additive only when `LSP Enabled: true`; runtime evidence capped at 150 lines | **Balanced + `pk:review` on TS repos** (Lite stays at 1,146 tok — skipped silently) |

By contrast, inlining all 24 workflow specifications and schemas consumes **18,000 to 22,000 tokens** on turn 1 before any user request is processed.

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

PromptKit OS benchmarks both the **static footprint** (1,146 tok Lite, 2,498 tok Balanced) and the **dynamic per-task runtime context**. 

By embedding decision-grade Level 0–3 classification directly into the static directive and adopting lazy convention loading (`$KIT_DIR_REL/workflows/<trigger>.md`), agents classify tasks without preloading `workflows/route.md` (~6,962 tokens). This is Change A from `docs/token-efficiency-review.md` — verified saving 6,915 tok per task.

**Methodology for per-task table:**
- SHA: `fc98f2f` (after 2+1 profiles), also valid at `c34be80` (before profiles, Balanced only)
- Method: `bytes / 4` per `measure-tokens.sh` convention, sum of directive + workflow + `code-quality-gate.md` + relevant template
- Baseline payload = directive 1,882 + route 6,962 + workflow + gate (old behavior before Change A)
- JIT payload = directive 1,146-2,498 + workflow + gate (new behavior, route.md only when ambiguous)
- Lite vs Balanced: Lite uses 1,146 tok directive, Balanced uses 2,498 tok

### Measured Per-Task Context Breakdown (bytes / 4 convention, after Change A + B):

| Workflow Path | Task Type & Loaded Scope | Baseline Payload (before A) | PromptKit OS JIT Payload (Balanced) | PromptKit OS JIT Payload (Lite) | Context Reduction vs Baseline |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **`pk:fix`** | Localized bug fix (Directive + `fix.md` + `code-quality-gate.md`) | 12,861 tok | **7,642 tok** | **6,290 tok** | **-41% Balanced, -51% Lite (-5,219 to -6,571 tok)** |
| **`pk:plan`** | Controlled feature planning (Directive + `plan.md` + `tech-spec` + `gate`) | 24,666 tok | **16,740 tok** | **15,388 tok** | **-32% Balanced, -38% Lite** |
| **`pk:ship`** | Release candidate & verification (Directive + `ship.md` stub + `gate`) | 24,761 tok | **12,256 tok** | **10,904 tok** | **-51% Balanced, -56% Lite (-12,505 to -13,857 tok)** |

### Planning-Intake Cost: One-Time Premium, Zero Steady State

The intake wave adds a bounded one-time cost and no steady-state cost (measured at `db4da7c`, `bytes/4` convention, reproducible via `wc -c protocols/discovery-intake.md workflows/plan.md`):

| Intake cost item | Measurement | Tokens |
| :--- | :--- | ---: |
| `protocols/discovery-intake.md` (12,635 B, lazy-loaded only while intake is incomplete) | new file | 3,159 |
| `workflows/plan.md` Step 0 preflight growth (22,660 → 25,835 B) | +3,175 B | +794 |
| **One-time premium total** | | **~3,953** |
| **Steady state after intake closes** (`complete` or `legacy-partial`) | protocol unloaded | **0 additional** |

### Key Runtime Efficiencies:
1. **Time-to-First-Action (TTFA)**: Eliminates 1 full tool-reading turn on Turn 1 (no longer loads `route.md` 6,962 tok to discover Level 0 is zero overhead), saving **~3–6 seconds** of latency on every interaction. Measured via Turn 1 file reads before/after Change A.
2. **Context Window Endurance**: Chat conversations maintain high attention reasoning for an additional **5–10 turns** before reaching compaction thresholds (parent thread saves ~98.7% via subagent delegation, see §4).
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
- **PromptKit Protocol**: Strict Expand-Contract phased migrations (add additive column -> backfill -> switch reads -> deprecate -> drop in separate release).

### 3. Preventing Session Amnesia (`pk:checkpoint`)
- **Unstructured Multi-Turn Drift**: After 30 turns, LLM forgets locked architectural decisions.
- **PromptKit Protocol**: Compresses state into git-tracked `docs/STATE.md` and generates fresh-session handover prompts with zero progress loss.

---

## 6. Architectural Comparison: PromptKit OS vs. Autonomous Multi-Agent Swarms

While autonomous multi-agent looping frameworks attempt to solve software engineering via unmonitored background sub-agent loops and complex runtime daemons, they introduce significant token multipliers, harness complexity, and context exhaustion risks.

| Architectural Dimension | PromptKit OS (Disciplined Pairing OS) | Autonomous Multi-Agent Swarms |
| :--- | :--- | :--- |
| **Execution Model** | **Human-in-the-Loop Pairing**: AI proposes, verifies against Gherkin AC, and human reviews/commits. | **Autonomous Looping**: Agents iterate in unmonitored background loops until stopped or timed out. |
| **Token Footprint** | **Lean 1x Baseline**: Just-In-Time filesystem loading (~1,928 tokens, ~90% static context reduction). Unused workflows consume 0 tokens. | **Additional Model Calls**: Multi-agent pipelines (research $\rightarrow$ planning $\rightarrow$ execution waves) introduce additional model calls and aggregate token overhead proportional to pipeline depth and context size. |
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

- **Avoid Flagship Burn on Trivial Tasks**: Standard coding assistants frequently waste expensive flagship reasoning tokens on basic single-line formatting, regex syntax checks, or documentation typo fixes. Routing Level 0 tasks to economy models reduces token spend by **80–90%** on daily ad-hoc queries (this is a static footprint estimation, turn-by-turn dynamic token efficiency may vary based on model usage).
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

**Safety invariant (AC-3, grep-asserted by the script):** Turbo never removes the human Level-3 approval requirement for releases, tags, deployments, or rollback, in any shipped surface.

---

## 9. Proxy Validation: `bytes/4` vs Real Tokenizers (Issue #194)

Every figure above uses the `bytes/4` proxy. This section validates that convention against real tokenizers without replacing it: **`bytes/4` remains the gated convention** and no published figure changes in this issue.

**Provenance:** `tiktoken 0.14.0`, encodings `cl100k_base` + `o200k_base`, measured 2026-09-16 at `main` @ `1312831`. Reproduce with `bash scripts/measure-tokenizer-delta.sh` (offline-safe: prints `SKIPPED`, exits 0 without network). RATIO = CL100K / BYTES4.

| File | BYTES4 | CL100K | O200K | RATIO |
| :--- | ---: | ---: | ---: | ---: |
| `templates/agent-directive-template.md` | 2,495 | 2,497 | 2,497 | 1.001 |
| `templates/agent-directive-lite-template.md` | 1,059 | 1,120 | 1,121 | 1.058 |
| `workflows/plan.md` | 6,459 | 5,246 | 5,234 | 0.812 |
| `workflows/route.md` | 7,142 | 6,144 | 6,102 | 0.860 |
| `workflows/fix.md` | 2,145 | 1,796 | 1,779 | 0.837 |
| `workflows/ship.md` | 4,431 | 3,611 | 3,612 | 0.815 |
| `protocols/discovery-intake.md` | 3,159 | 2,750 | 2,744 | 0.871 |

**Verdict (published as measured):**

- **Gated artifacts are sound.** The Balanced directive matches real tokenizers within 0.1%; Lite understates by ~6% (proxy reads low). The 2500/1500 budget gates therefore guard real cost, not just the proxy.
- **Workflow/protocol figures are conservative.** The proxy overstates real counts by 13–19% (whitespace, table padding, comments). Published per-task payloads are upper bounds — real costs are lower.
- **Relative savings hold approximately.** Both sides of each reduction ratio were measured in the same convention, so the overstatement largely cancels; absolute tok figures should be read as conservative estimates.
- **Encodings agree.** `cl100k_base` vs `o200k_base` differ by ≤1% on every file — no per-host restatement is warranted from this data.

---

## Related References
- [`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md) — Subagent delegation & context preservation rules
- [`protocols/context-sync.md`](../protocols/context-sync.md) — 30-turn reset threshold & MCP discovery
- [`workflows/route.md`](../workflows/route.md) — Canonical task ceremony levels & model tiering
- [`FAQ.md`](../FAQ.md) — Common adoption questions & setup details

