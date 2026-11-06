# Phase 4 — Design: does the Phase 3c result hold on other models?

Status: **frozen 2026-11-01 — Appendix A filled and signed; amended 2026-11-06 (Amendment B and its correction: both model pairs blocked by plan entitlement); STOPPED 2026-11-06 pending billing; no session has reached a model.**
The model list, engine commit, seeds, CLI version and caps in Appendix A are
fixed; nothing there may change after the first session. This document exists
because Phase 3c returned **Tradeoff** under Amendment A, and
`benchmarks/PHASE-3C-DESIGN.md` §8 opens cross-model work only on Keep or
Tradeoff.

---

## 1. What Phase 4 is asking

Phase 3c measured one thing on one model: on a discriminating 10-card slate
against the neutral seed `b0ef652d…`, `promptkit_os` accepted **26 of 30** runs
against `bare`'s **22 of 30** (+13.3 points) at a token-ratio median of
**1.115**.

That is a single-model result with a descriptive interval that still spans 1.0.
Phase 4 asks the narrow question the design can actually answer:

> **Is the acceptance gain, and the cost of it, stable across models — or is it a
> property of one provider's model?**

It is not asking whether PromptKit OS is good. It is asking whether the sign and
rough size of the Phase 3c effect survive a change of model.

## 2. What is held fixed, and why

| Item | Value | Why |
|---|---|---|
| Seed | `b0ef652d91b20c57965eb4257cab93301ff68999` | Same tree Phase 3c used, so the only changed variable is the model. |
| Cards | `TASK-P3C-01` … `TASK-P3C-10`, byte-identical | Editing a card would break comparability with 3c. Known card defects are handled by analysis, not by editing (§5). |
| Arms | `promptkit_os` and `bare`, same `session_argv` builder, `guard_cross_arm` | Unchanged from 3b/3c. |
| Repeats | 3 per cell | Same variance structure as 3c. |
| Driver | `benchmarks/run-ab-benchmark.sh` at a pinned commit | No driver change is proposed by this phase. |
| Rubrics and probes | Frozen by the cards | Same instrument, so a difference is a model difference. |

**The engine stays pinned too.** If PromptKit itself changes between 3c and 4,
the comparison confounds engine and model. The engine commit is recorded in
Appendix A and the treatment arm stages that exact surface.

## 3. What changes: the model

Phase 3c ran `deepseek/deepseek-v4.1-flash`. Phase 4 adds **two models**, for
three in total, each chosen by a rule rather than by hand after seeing results:

1. The 3c incumbent, as the anchor.
2. The two highest-capability models the CLI exposes at freeze time, enumerated
   with `command-code --list-models` and recorded verbatim in Appendix A.

**Frozen 2026-11-01:** `claude-fable-5-1` (Anthropic) and `gpt-6-astra` (OpenAI),
copied verbatim from `command-code --list-models` 1.88.2 at freeze. That list
carries 95 models and no numeric capability field, only prose descriptions, so
"highest-capability" was instantiated as *the model in each vendor section whose
description makes an unqualified top-tier claim*, taking two vendors rather than
one so the phase tests transfer across providers rather than family variation.
`claude-fable-5-1` is "most capable for demanding reasoning & long-horizon
agents"; `gpt-6-astra` is "most capable OpenAI model for demanding reasoning &
agents". The full freeze-time enumeration and the runner-up readings are recorded
in Appendix A, so the choice can be checked rather than trusted.

## 4. Pre-registration and spend

| Item | Value |
|---|---:|
| Tasks | 10 |
| Arms | 2 |
| Repeats per cell | 3 |
| Models | 2 new (+ incumbent anchor where needed) |
| Primary sessions | **120** (10 × 2 × 3 × 2) |
| Calibration (1 repeat, 3 tasks × 2 arms × 2 models) | 12 |
| Infrastructure replacements | 20 |
| Total CLI sessions (ceiling) | **152** |
| Wall-clock ceiling | 60 hours |
| Per-session timeout | 1,800 s |
| Max turns | 40 |
| `transcript_cost_usd` abort threshold | **$80** |

Projection basis: Phase 3c spent $0.55 across 60 sessions on
`deepseek/deepseek-v4.1-flash`. That figure does **not** transfer to either frozen
model — both are flagship-tier and priced far above the 3c flash model — so Phase 4
does not pretend to forecast its cost from it. The $80 threshold stands, and
calibration is a **spend gate**: after the 12 calibration sessions, project the
primary block from the measured per-session cost; if the projection exceeds $80,
stop before the primary block and re-file the cap rather than abort mid-batch. The
caps bind.

**No extra runs.** No re-running a task because a model did surprisingly well or
badly, no dropped task, no fourth repeat. A timeout is recorded and stays in the
ITT denominator.

## 5. Analysis, and the two things 3c taught us

The Phase 3c grading pass found two measurement artefacts that Phase 4 must
handle **in the pre-registration**, not after the numbers:

- **`P3C-06` is wording-sensitive.** Five of six 3c packets read "the scheduler
  exposes `sweep(...)`" as a module export rather than an instance method, and the
  frozen probe fails them. That card measures a wording detail as much as a
  behavior. Phase 4 keeps the card frozen but **pre-registers a sensitivity cut
  that reports every model twice: with and without `P3C-06`.** If the conclusion
  flips when one card is removed, it was never about the arms.
- **The cost bar must be stated up front.** 3c left `either`/`both` open and had
  to amend it afterwards. Phase 4 carries **Amendment A** verbatim: the cost bar
  is the **ITT per-task median token ratio**, and CPAC is reported context, never
  a gate.

Also carried from 3c:

- Per-arm acceptance over all primary sessions, plus a paired per-task comparison.
- Per-task median ratios for tokens and CPAC, with n and individual values; the
  rejected-run `INF` selection effect named wherever a CPAC median appears.
- A task-cluster bootstrap (10,000 resamples) reported as a **descriptive**
  interval, with seeds derived from the batch label rather than chosen.
- Sensitivity cuts: ITT vs complete-case, cache reads included/excluded, actual
  cost vs modeled CPAC, per level.
- Anything not listed here is exploratory and must be labelled so.

## 6. Decision rule

Applied **per model**, so one model can be Keep while another is Worse. This is a
deliberate change from 3c's single outcome, and it must be read as three answers,
not one.

| Outcome | Condition |
|---|---|
| **Keep** | `promptkit_os` acceptance not below `bare` **and** its ITT token ratio ≤ 0.95 |
| **Tradeoff** | acceptance ≥ 5 points higher **and** ITT token ratio > 1.05 |
| **Worse** | acceptance ≥ 5 points lower than `bare` |
| **Inconclusive** | anything else |

There is no aggregate "Phase 4 verdict". A split result (Keep on one model,
Inconclusive on another) is reported as exactly that. Averaging across models
would hide the only thing this phase is built to detect.

**Worse on every model** closes the line with no further phases. **Inconclusive
on every model** does the same unless a named design defect justifies a new batch.

## 7. Grading

Carried from 3c and tightened where 3c fell short:

- Packets are blind, keyed by a whole-batch shuffle, and the key is written
  outside the workspace a grader reads.
- The sheet is hashed **before** `--finalize` opens the key.
- **The primary grade must come from a grader who did not produce the first pass.**
  3c's primary sheet was an owner-authorized agent first pass, disclosed in
  `grading/GRADING-HUMAN.md`; that disclosure protected the record but did not
  satisfy §7's independence requirement. The second-grader sample was scored
  afterwards (`grading/SECOND-READER.md`, 30/30 agreement) but from a fresh session
  of the generating model's family, which is consistency evidence, not
  independence. Phase 4 pre-registers the independence requirement as a
  **blocking** item: no Phase 4 batch is considered complete until a second grader
  who did not produce the sheet has scored ≥50% of packets, with disagreements
  reported packet-by-packet.
- `--finalize` must run with `--graded-by human|machine` telling the truth about
  who asserted the result.

## 8. What Phase 4 does not establish

- Real consumer codebases. The seed remains synthetic and must be labelled as such.
- Long-horizon or multi-user work; each session is one card, one clone, one run.
- Any public positioning change. That is the Phase 5 decision memo's job.
- That a model difference is a *capability* difference rather than a difference in
  how each model responds to a directive written for another model. Phase 4 can
  see the effect; it cannot attribute the cause.

## 9. Status

- [x] Appendix A filled 2026-11-01: models named, engine commit, seed, seed derivation, caps signed.
- [x] Zero-spend preflight (`--preflight-only`) on each model, `CROSSARM|OK` and
      `ISOLATION|OK`. 2026-11-06: the original pair passed at `cli=1.88.2`
      (plan `1ebf5715…`, 60 rows each), and the amended pair passed again after
      Amendment B — `moonshotai/kimi-k3.1-pro` and `qwen/qwen3.8-max`, same
      digest, same 60 rows each, `$0` spent.
- [x] Probe screen (`--screen --arm bare`) red on all 10 cards for the pinned seed.
      2026-11-06: `SCREEN|OK|arm=bare|tasks=10|red=10`, each probe failing on its
      seeded defect while the seed’s own suite stays green.
- [ ] Calibration block (12 sessions) — **blocked 2026-11-06**: first pair `403 MODEL_NOT_IN_PLAN` (12/12), amended pair `Insufficient credits` (12/12); no session reached a model. Phase 4 stopped pending billing (Amendment B correction).
- [ ] Batch run.
- [ ] Primary grading with a grader independent of the first pass.
- [ ] Second-grader sample ≥50%.
- [ ] Report with a **per-model** outcome and the `P3C-06` sensitivity cut.
- [ ] Only then: Phase 5 memo or a no-decision closeout.

## Appendix A — Frozen parameters

Frozen 2026-11-01. No Phase 4 session had run when this table was filled; the
enumeration below is the freeze-time capture, not a later reconstruction.

| Parameter | Value |
|---|---|
| Models (verbatim CLI identifiers) | **`moonshotai/kimi-k3.1-pro`** and **`qwen/qwen3.8-max`** (amended 2026-11-06 — Amendment B); anchor `deepseek/deepseek-v4.1-flash` (Phase 3c, not re-run). Originally frozen as `claude-fable-5-1` and `gpt-6-astra`. Neither replacement completes a session on current credits (amendment correction); only the anchor runs. |
| Model selection rule | 3c incumbent + the two highest-capability models in `--list-models` at freeze; re-applied 2026-11-06 to the highest two whose probes answered, superseded the same day when neither ran a session (Amendment B and correction) |
| Enumeration evidence | `benchmarks/PHASE-4-MODELS-2026-11-01.txt` — verbatim `command-code --list-models`, CLI 1.88.2, 95 models, sha256 `8ea2facb67244afc4952948fa457cfad66fb78764ab74c6aa66dbfc409e68543` |
| Engine commit (staged consumer surface) | `40b69bb9d094ecf10ca576a9746452fdecdf11ca` (main at freeze) |
| Seed | `b0ef652d91b20c57965eb4257cab93301ff68999` |
| Batch label | `phase4-batch` (run directory `2026-11-01-phase4-cross-model`) |
| `order_seed` | `40662191` |
| `shuffle_seed` | `21978707` |
| Seed derivation | `int(sha256("<label>\|order")[0:8], 16) mod 100000000`, and the same with `shuffle`; reproduces Phase 3c's recorded `60564652` / `760853` exactly |
| CLI version | `command-code` 1.88.2 |
| Owner signature and date | `lowqualityloey`, approved 2026-11-01 |

**Batch label.** The seed label is `phase4-batch`, shared by both models so the
same plan and blind shuffle order apply across them. The run directory is
`benchmarks/runs/2026-11-01-phase4-cross-model/`.

**Engine.** `40b69bb` is `main` at freeze. It differs from the Phase 3c engine
commit `84f9747` only in benchmark tooling, CI, changelog and `CONTRIBUTING`
instructions; the staged promptkit surface is unchanged, so the model remains the
only variable the phase changes.

### Freeze-time enumeration

`command-code --list-models` lists 95 models in provider sections with prose
descriptions and **no numeric capability field**, so the rule was applied by
reading each top-tier claim. The candidates and the reading:

| Model | Description (verbatim) | Reading |
|---|---|---|
| `claude-fable-5-1` | "most capable for demanding reasoning & long-horizon agents" | Anthropic's unqualified top claim — **chosen** |
| `gpt-6-astra` | "most capable OpenAI model for demanding reasoning & agents" | OpenAI's top claim — **chosen** |
| `claude-opus-5-5` | "most intelligent Opus for agents and coding" | qualified to the Opus line, not the vendor |
| `gpt-6.1-sol` | "near-Astra performance for complex work at a lower cost" | explicitly below Astra |
| `google/gemini-4-argon` | "multimodal reasoning for documents and agent workflows" | no supremacy claim |
| `moonshotai/kimi-k3.1-pro` | "frontier reasoning & agentic coding with 1M context" | frontier, not top |
| `qwen/qwen3.8-max` | "autonomous long-horizon coding & professional work" | no supremacy claim |
| `zai-org/glm-5.3` | "frontier coding with emergent cyber capabilities" | frontier, not top |
| `mistral/mistral-large-4` | "frontier open-weight multimodal model for coding & analysis" | frontier, not top |

Two vendors were taken rather than two models from one vendor: the phase asks
whether a single-model result survives a change of model, and a single vendor
would test family variation only. This is a reading of vendor prose, not a
measured capability ranking — §8's caveat still applies.

### Signature

Owner: `lowqualityloey`. Approved 2026-11-01. The owner instructed this freeze
and approved the two models named above; an agent transcribed the table in the
same session, with zero Phase 4 sessions run at the time of signing.

Nothing in this appendix may change after the first session. If a frozen model is
unavailable at preflight, the phase stops and this appendix is amended **before**
the first session with the reason recorded — that is not a licence to swap a model
after results have been seen.

### Amendment B — 2026-11-06: model pair replaced under a plan-entitlement block

The frozen pair cannot run on this account. The Phase 4 calibration block was
started on `claude-fable-5-1` and `gpt-6-astra` — three cards, one per level, two
arms, one repeat, 12 sessions — and all 12 exited `cli_exit=4` with
`403 MODEL_NOT_IN_PLAN` before inference: zero tokens, `transcript_cost_usd`
$0.0000, empty bare diffs, and 47,116-byte `promptkit_os` diffs that contain only
the kit install. No Phase 4 session reached a model, so the clause above applies:
the phase stops and the appendix is amended before the first session, with the
reason recorded.

The failure is entitlement, not configuration. `command-code status` reports the
account authenticated as `lowqualityloey`, `--list-models` still lists both frozen
models, and the refusal names the plan: "available in Provider and above plans or
extra on demand usage". Preflight cannot see this: it validates the model
identifier, the seed, the engine and the CLI, not the plan behind the account.

**Entitlement probe, 2026-11-06.** One turn per candidate with the driver flags
(`-t --yolo --tools-all --skip-onboarding --no-auto-update --max-turns 1`) under
the isolated `HOME`, from the depth chart above downward:

| Candidate | Result |
|---|---|
| `claude-fable-5-1` | `403 MODEL_NOT_IN_PLAN` — Provider plan or on-demand |
| `gpt-6-astra` | `403 MODEL_NOT_IN_PLAN` — Provider plan or on-demand |
| `claude-opus-5-5` | `403 MODEL_NOT_IN_PLAN` — Provider plan or on-demand |
| `gpt-6.1-sol` | `403 MODEL_NOT_IN_PLAN` — Max plan or on-demand |
| `google/gemini-4-argon` | `403 MODEL_NOT_IN_PLAN` — Pro plan or on-demand |
| `zai-org/glm-5.3` | `Insufficient credits` |
| `mistral/mistral-large-4` | `Insufficient credits` |
| `moonshotai/kimi-k3.1-pro` | answered |
| `qwen/qwen3.8-max` | answered |
| `deepseek/deepseek-v4.1-flash` (anchor) | answered |

**Replacement.** `moonshotai/kimi-k3.1-pro` and `qwen/qwen3.8-max` — the two
highest entries in the depth chart whose one-turn probes answered, from two
vendors (Moonshot and Alibaba) rather than one, which keeps the two-vendor
property the original freeze argued for. The anchor is retained and still
runnable; it is not re-run, exactly as frozen. The probes answered; sessions did
not, and the correction below records why a probe was the wrong gate.

**Consequence, stated before results.** Phase 4 now asks whether the 3c effect
survives a change of model *at the frontier tier this plan can run*, not at
flagship tier. It supports no flagship claim, and no claim about Claude or OpenAI
models, which never execute. The §8 caveat widens accordingly: a difference here
is a difference between two available frontier models, not a capability ranking.
Cards, seed, engine, repeats, caps, decision rule, analysis cuts and grading
requirements are unchanged, and the plan is model-independent: both new models
reproduce the frozen digest `1ebf5715…` at 60 rows, so the schedule and the blind
shuffle are not recomputed.

**Re-done.** The zero-spend preflight was re-run for each new model because the
pair changed: `CROSSARM|OK`, `ISOLATION|OK`, `PREFLIGHT|OK|cli=1.88.2`, plan
`1ebf5715…` at 60 rows each, $0 spent. The probe screen is model-independent and
stands unamended.

Signature: owner `lowqualityloey`, 2026-11-06, instructed in-session after the
entitlement block was measured; an agent transcribed the probe table in the same
session. Twelve sessions had been attempted and none had reached a model at the
time of signing.


#### Correction — 2026-11-06: the replacement pair is blocked at session scale

The replacement was signed on probe evidence, and that evidence was too weak. A
one-turn probe proves a model answers; it does not prove a session runs. The
twelve-session calibration block was re-run on the amended pair — three cards, two
arms, one repeat, six sessions per model — and all twelve exited `cli_exit=10`
with `Insufficient credits for Command Code.` before inference: zero tokens,
`transcript_cost_usd` $0.0000, empty bare diffs, and 141,348-byte `promptkit_os`
diffs holding only the kit install. No Phase 4 session has reached a model.

The block is per-model credit, not an exhausted account. Probed immediately
afterwards under the same isolated `HOME` with the driver flags:

| Model | One-turn result |
|---|---|
| `deepseek/deepseek-v4.1-flash` (anchor) | answered, `exit=0` |
| `moonshotai/kimi-k3.1-pro` | `Insufficient credits`, `exit=10` |

So the anchor is included in the plan and both replacements are not: they need
purchased credits, and the allowance that let a single probe through did not
survive one session. `qwen/qwen3.8-max` failed identically in all six of its
sessions; the differential probe used one model because the failure text was
identical in both.

**Consequence.** Phase 4 is **stopped pending billing**. This correction records
the measurement and does not name a third pair: the only model this account runs
is the anchor, the design does not re-run the anchor, and choosing again from
one-turn probes would repeat the error just made. Two pairs have now failed for
two different reasons, so the next attempt is gated on a **completed paid
session**, not on a probe. The models row keeps the amended pair as the recorded
choice and marks it not session-runnable.

**What remains open.** The section 9 batch run, primary grading, second-grader
sample and per-model report are untouched, and the $80 cap is unspent at $0.00 of
session cost. No spend projection can be formed from twelve zero-token refusals,
and none is offered. The probe tokens from the entitlement pass are not itemised
by the CLI and are not counted as measurement.

**Harness finding, unchanged.** The driver printed `BATCH|OK|runs=6` and wrote
six blind packets and a key for each model while every session had failed. Both
attempts now carry keys and packets that mean nothing; recorded, not fixed.

Owner instruction: stop the phase pending billing, 2026-11-06.
