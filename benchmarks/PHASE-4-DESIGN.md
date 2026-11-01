# Phase 4 — Design: does the Phase 3c result hold on other models?

Status: **draft, not frozen.** Nothing here is pre-registered yet, and **no
session may run until Appendix A is filled and the owner signs it**. This
document exists because Phase 3c returned **Tradeoff** under Amendment A, and
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
| Driver | `benchmarks/run-ab-benchmark.sh` at a pinned commit | No driver change is proposed by this draft. |
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

**This parameter is deliberately left unfilled in the draft.** It must be frozen
before the first session, exactly as the 3b/3c seeds were, because a model list
chosen after a disappointing run would make the whole phase unfalsifiable. If the
owner would rather name two specific models, that is fine — it just has to happen
in Appendix A before any spend.

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

Projection basis: Phase 3c spent $0.55 of reported `transcript_cost_usd` across
60 sessions in 62 minutes. Doubling the cells roughly doubles both, so ~$1.10 and
~2 hours of wall clock; the numbers above are the caps, not a forecast. The caps
bind.

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

- [ ] Appendix A filled: models named, engine commit, seed, seed derivation, caps signed.
- [ ] Zero-spend preflight (`--preflight-only`) on each model, `CROSSARM|OK` and
      `ISOLATION|OK`.
- [ ] Probe screen (`--screen --arm bare`) red on all 10 cards for the pinned seed.
- [ ] Batch run.
- [ ] Primary grading with a grader independent of the first pass.
- [ ] Second-grader sample ≥50%.
- [ ] Report with a **per-model** outcome and the `P3C-06` sensitivity cut.
- [ ] Only then: Phase 5 memo or a no-decision closeout.

## Appendix A — Frozen parameters (UNFILLED)

| Parameter | Value |
|---|---|
| Models (verbatim CLI identifiers) | **TBD — must be frozen before the first session** |
| Model selection rule | 3c incumbent + the two highest-capability models in `--list-models` at freeze |
| Engine commit (staged consumer surface) | **TBD** |
| Seed | `b0ef652d91b20c57965eb4257cab93301ff68999` |
| `order_seed` / `shuffle_seed` | **TBD — derived from the batch label, recorded before any spend** |
| CLI version | **TBD** |
| Owner signature and date | **TBD** |

Nothing in this appendix may be filled after the first session.
