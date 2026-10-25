# PromptKit OS Empirical Benchmark Methodology: Cost Per Accepted Change (CPAC)

A standardized, reproducible framework for measuring engineering economics, token waste, rework cycles, and defect prevention in AI coding agents.

---

## 1. Executive Summary & Problem Definition

Traditional AI coding benchmarks (e.g. SWE-bench, HumanEval) primarily evaluate one-shot code generation or single-turn patch generation. In real-world software engineering, developers collaborate with AI coding agents across **multi-turn, iterative sessions**.

In an unconstrained agent environment, the primary driver of cost is not the size of the initial prompt—it is the **rework spiral**:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                      THE UNCONSTRAINED REWORK SPIRAL                    │
│                                                                         │
│  User Request ──► Unbounded Search (20+ files) ──► Wrong Stack Assumption│
│                          ▲                                 │            │
│                          │                                 ▼            │
│                 Hallucinated Fix ◄── Failed Compile/Test (50k tok lost) │
└─────────────────────────────────────────────────────────────────────────┘
```

PromptKit OS replaces this spiral with a **deterministic engineering control plane**:
1. **JIT Stack Knowledge**: Loads ecosystem-specific invariants ($\le 1,500$ tokens) before editing begins.
2. **Task Ceremony Tiering (L0–L3)**: Aligns verification and planning overhead to real risk.
3. **Evidence-Gated Verification**: Requires verifiable execution proof (`exit code = 0`) before progress is acknowledged.
4. **Bounded Repairs**: Caps iterative failure loops with an automatic circuit breaker.

The purpose of this methodology is to quantify these architectural advantages in dollars, tokens, and developer time.

---

## 2. The Core Metric: Cost Per Accepted Change (CPAC)

**Cost Per Accepted Change (CPAC)** measures the total economic cost required to produce a single verified, production-ready pull request that satisfies all architectural invariants.

$$\text{CPAC} = \frac{C_{\text{inference}} + C_{\text{rework}} + C_{\text{human}}}{N_{\text{accepted}}}$$

Where:

> **Implementation note:** the formula below isolates failed iterations to the rework cost
> ($C_{\text{rework}}$) so they are not double-counted in inference, and it is the formula exercised by
> the self-tests in `scripts/measure-cpac.sh` / `.ps1`. The shipped CLI implements telemetry
> ingestion: `scripts/extract-commandcode-telemetry.sh` / `.ps1` convert a Command Code session
> transcript into the §5 record, and a §5 record path passed to `scripts/measure-cpac.sh` / `.ps1`
> is scored mechanically (unreadable, malformed, or incomplete records fail closed with exit `2`).
> The self-tests verify the arithmetic; only records extracted from real sessions are empirical
> results.

### A. Direct Inference Cost ($C_{\text{inference}}$)
The raw LLM API consumption across all successful conversation turns. Note that inference costs from failed rework loops are accounted for in $C_{\text{rework}}$ instead of here, to avoid double counting:
$$C_{\text{inference}} = (T_{\text{successful-in}} \times P_{\text{in}}) + (T_{\text{successful-out}} \times P_{\text{out}})$$
- $T_{\text{successful-in}}, T_{\text{successful-out}}$: Total prompt and completion tokens during successful execution phases.
- $P_{\text{in}}, P_{\text{out}}$: Standard model pricing per token (e.g., \$3.00/1M in, \$15.00/1M out for frontier models).

### B. Rework Penalty Cost ($C_{\text{rework}}$)
The economic waste incurred from failed compilation loops, unconstrained search loops, and broken assumptions. This isolates the cost of mistakes:
$$C_{\text{rework}} = \sum_{k=1}^{R} \left( T_{\text{loop}(k)} \times P_{\text{avg}} + \tau_{\text{tool}(k)} \right)$$
- $R$: Number of failed verification iterations.
- $T_{\text{loop}(k)}$: Tokens consumed during failed repair cycle $k$.
- $\tau_{\text{tool}(k)}$: Infrastructure execution cost of failed build/test runs.

### C. Human Review & Triage Cost ($C_{\text{human}}$)
The cost of developer intervention required to review diffs, diagnose failures, or fix rejected PRs:
$$C_{\text{human}} = t_{\text{review}} \times R_{\text{dev-hourly}}$$
- $t_{\text{review}}$: Developer time in hours spent reviewing diffs, intervening on stalls, or fixing security violations.
- $R_{\text{dev-hourly}}$: Standardized engineering rate (baseline: \$100.00/hr = \$1.67/min).

### D. Accepted Output Gate ($N_{\text{accepted}}$)
Binary acceptance gate (1 if all tests pass and all non-negotiable invariants are preserved; 0 if rejected or broken). If $N_{\text{accepted}} = 0$, $\text{CPAC} \rightarrow \infty$.

---

## 3. The 5 Observable Benchmark Dimensions

Every benchmark scenario captures five empirical metrics extracted directly from session transcripts and execution telemetry:

| Dimension | Metric | Measurement Method | Target Direction |
| :--- | :--- | :--- | :---: |
| **1. Token Efficiency** | Total Tokens ($T_{\text{in}} + T_{\text{out}}$) | Transcript token tally | Lower |
| **2. Search Overhead** | Exploration Ratio ($\frac{\text{Search Tools}}{\text{Edit Tools}}$) | Tool call frequency | Lower ($\le 2.0$) |
| **3. Rework Cycles** | Failed Verification Loops ($R$) | Number of non-zero exit codes | Lower ($\le 1$) |
| **4. Invariant Adherence** | Invariant Score (0–100%) | Static AST / rule audit of final diff | Higher (100%) |
| **5. Time to Green** | Wall-Clock Duration ($\Delta t$) | Start to clean verification finish | Lower |

---

## 4. Dual-Condition Evaluation Protocol

To ensure rigorous comparison without confounding variables, every evaluation runs under a strict **A/B Dual-Condition Protocol**:

```text
               ┌─────────────────────────────────────────┐
               │         STANDARDIZED SEED REPO          │
               │   Identical Commit · Identical Tests    │
               └────────────────────┬────────────────────┘
                                    │
               ┌────────────────────┴────────────────────┐
               ▼                                         ▼
    [ Condition A: Vanilla ]                 [ Condition B: PromptKit OS ]
    - Same Frontier Model                     - Same Frontier Model
    - Standard generic system prompt          - PromptKit OS JIT Directive
    - No playbooks or recipes                 - Stack Playbook + Boundary Recipe
    - Freeform unconstrained search           - L0–L3 Evidence-Gated Verification
               │                                         │
               └────────────────────┬────────────────────┘
                                    │
                                    ▼
                     [ AUTOMATED SCORING HARNESS ]
```

### Protocol Rules:
1. **Identical Model Parameters**: Both conditions execute on the identical foundation model (same snapshot, temperature, and tool calling interface).
2. **Zero Prior Context**: Both runs begin from a clean checkout at the designated commit fixture.
3. **Identical Task Prompt**: The user request text must be verbatim identical.
4. **Mechanical Evaluation**: this protocol requires telemetry to be extracted mechanically from
   transcript logs rather than scored by qualitative subjective rating. That extraction is
   implemented in the shipped tooling: `scripts/extract-commandcode-telemetry.sh` and its `.ps1`
   twin mechanically convert a Command Code session transcript into the §5 telemetry record, and
   `scripts/measure-cpac.sh` / `.ps1` score such a record (a telemetry path that is empty,
   malformed, or missing required keys fails closed with exit `2`). Empirical claims still require
   real session transcripts: the bundled fixtures and self-tests verify mechanics, not outcomes.

---

## 5. Telemetry Schema & Machine-Readable Scorecard

Execution logs must export a standardized JSON telemetry record conforming to this schema:

```json
{
  "scenario_id": "WEB-01-AUTH-WEBHOOK",
  "condition": "promptkit_os",
  "model": "frontier-v1",
  "timestamp": "2026-09-18T10:00:00Z",
  "metrics": {
    "tokens_in": 14250,
    "tokens_out": 1820,
    "tokens_total": 16070,
    "cache_read_tokens": 5300,
    "tool_calls_total": 14,
    "tool_calls_search": 4,
    "tool_calls_edit": 5,
    "tool_calls_verify": 5,
    "tool_calls_other": 0,
    "rework_loops": 0,
    "rework_tokens_in": 0,
    "rework_tokens_out": 0,
    "wall_clock_seconds": 184,
    "invariants_checked": 5,
    "invariants_passed": 5,
    "human_interventions": 0,
    "accepted": true
  },
  "costs": {
    "inference_cost_usd": 0.070,
    "rework_cost_usd": 0.000,
    "human_cost_usd": 0.000,
    "cpac_usd": 0.070
  }
}
```

### A. Extraction Implementation and v1 Conventions (Command Code)

`scripts/extract-commandcode-telemetry.sh` / `.ps1` implement the extraction for Command Code
session transcripts (`~/.commandcode/projects/<slug>/<session>.jsonl`, JSONL schema v3), and
`scripts/measure-cpac.sh` / `.ps1` score the emitted record (a `CPAC|MEASURED|...` machine line;
unreadable, malformed, or incomplete records exit `2`). The v1 mapping fixes the following
conventions, which any empirical claim must state alongside its numbers:

- **Successful vs rework split (no double counting)**: usage sums from assistant turns are
  attributed to `tokens_in`/`tokens_out` (successful) or to `rework_tokens_in`/`rework_tokens_out`
  (rework) by a turn-walk rule: a turn that follows a failed tool result — until the next
  non-failed tool result — is a rework turn. `tokens_total` is the sum of all four fields.
- **Failure detection is a heuristic**: Command Code schema v3 records no tool exit codes, so the
  dimension-3 measurement ("number of non-zero exit codes") is approximated by matching a
  documented pattern list over tool-result text (overridable with `--error-patterns` on the
  extractor). Treat `rework_loops` as approximate, and state the pattern list used when publishing
  comparisons.
- **Cache reads are reported, not priced**: `cache_read_tokens` sums the host's cache-read usage
  but is excluded from $C_{\text{inference}}$, because §2 defines a single input price with no
  cache-read tier. The host's `inputTokens` are used as recorded. Cross-condition comparisons
  share the convention, so ratios remain meaningful.
- **Tool classification is best-effort**: `tool_calls_search`/`edit`/`verify` classify tool names
  and shell commands by documented keyword rules; the remainder is `tool_calls_other` (the four
  need not be assumed to sum to `tool_calls_total`).
- **Human interventions**: user prompts after the first — the initial request is the task, not an
  intervention.
- **Acceptance stays human**: the record's `accepted` flag defaults to `false` and may be set to
  `true` only by an operator after human acceptance; an unaccepted record scores
  `INF (REJECTED)`.
- `costs.transcript_cost_usd` reports the host's own recorded cost for transparency (it reads `0`
  under subscription pricing) and is not part of the CPAC formula.

---

## 6. Related Documentation

- [`BENCHMARKS.md`](./BENCHMARKS.md) — Static directive token weights and context window analysis.
- [`BEHAVIORAL-EVAL.md`](./BEHAVIORAL-EVAL.md) — Qualitative prompt-compliance evaluation results.
- [`specs/SPEC-empirical-benchmark.md`](./specs/SPEC-empirical-benchmark.md) — Detailed benchmark task definitions and assertion rubrics.
- [`../scripts/measure-cpac.sh`](../scripts/measure-cpac.sh) — CPAC scoring: ingests a §5 telemetry
  record (exit `2` on invalid records), plus formula self-tests and a `--demo` simulated scorecard.
- [`../scripts/extract-commandcode-telemetry.sh`](../scripts/extract-commandcode-telemetry.sh) —
  Command Code session transcript → §5 telemetry record extractor (dependency-free, with a `.ps1`
  twin; see §5.A for the v1 mapping conventions).
