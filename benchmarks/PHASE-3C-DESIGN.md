# Phase 3c — Design: a slate that can actually separate the arms

Status: **designed, screened, run, and graded — outcome Tradeoff under Amendment
A.** The primary sheet is `grading/grading-human.tsv` (48/60, owner-authorized,
agent first pass, provenance recorded in `grading/GRADING-HUMAN.md`); the second
grader sample and the re-finalize remain open. This document isthe pre-registration for the Phase 3c batch. It was written before any spend, and
the slate, the seed SHA, the probes and the decision rule below are frozen by it.
§10 records what ran and what the sheets produced: 48 of 60 packets accepted,
`promptkit_os` 26/30 against `bare` 22/30, at a token-ratio median of 1.115.
Amendment A settles the cost bar the original rule left open, and the outcome is
**Tradeoff**: acceptance is 13.3 points higher and the ITT token ratio is above
1.05. What the decision rests on is qualified in two places and those
qualifications travel with it — the primary sheet is owner-authorized rather than
independently human-reviewed (`grading/GRADING-HUMAN.md`), and the second-grader
sample §7 asks for is still outstanding.

Phase 3b is not rewritten or re-read here. Its result stands as published: 36 of
36 sessions accepted on a **machine-graded** sheet (18 of 18 per arm, L1+ median
ratios 1.075 tokens / 1.115 CPAC), and that batch cannot separate the arms on
quality because every run in both arms passed.

---

## 1. Why Phase 3b could not decide anything

Three facts about the 3b batch, all visible in its own artifacts:

1. **Every run was accepted, in both arms.** `BENCH|SUMMARY` reports
   `accepted=18` twice. A batch where nothing fails has no quality signal: the
   only surviving measurement is cost, and cost on tasks both arms solve is a
   price, not a benefit.
2. **The seed's backlog was the slate.** The 3b seed is four modules and a
   28-test suite, and the six tasks were drawn from its own `BACKLOG.md`. The
   backlog told the agent what to do and where; nothing in the slate required
   discovering a requirement that only the docs or a probe expressed.
3. **No task had a trap.** Every card's rubric could be satisfied by the obvious
   edit. A discriminating card needs a *plausible wrong fix* that passes the
   seed's own suite and fails the frozen probe.

Phase 3c changes the seed and the cards, not the driver, the model, or the
grading rules. The aim is narrow: make both arms able to fail, so that acceptance
rate is a measurement instead of a constant.

## 2. The seed

`benchmarks/seed/build-phase3c-seed.sh` writes a purpose-built repository and
commits it deterministically.

| Property | Value |
|---|---|
| Seed SHA (pinned) | `b0ef652d91b20c57965eb4257cab93301ff68999` |
| Tracked files | 27 |
| Modules | 9 (`app`, `cli`, `config`, `dispatcher`, `metrics`, `queue`, `registry`, `scheduler`, `store`) |
| Test suite | 65 tests, `node --test`, passes on the seed as committed |
| Runtime dependencies | none (built-in test runner, no install, no network) |
| Instruction surface | none; `neutralize.sh` accepts it with `removed=0` |
| `heyloey` references | none |

The tree adds what 3b lacked:

- **Coupling.** `app` composes `store`, `queue`, `dispatcher`, `metrics` and
  `scheduler`; a change at one site has a caller elsewhere, and one of those
  callers (`scheduler.sweep`) is covered by no seed test.
- **A docs surface that states requirements.** `docs/ARCHITECTURE.md` carries
  invariants I1 (append-only log) and I2 (a job is pending, or done, or failed,
  never two), and `docs/adr/` carries the store-format and metrics-idempotency
  decisions. Two cards cite those documents instead of naming a file.
- **An executable contract.** `specs/backpressure.spec.js` describes satisfying
  behavior the seed does not implement, and its sha256 is pinned so it cannot be
  edited into passing. It lives outside `test/`, so a bare `node --test` does not
  run it.
- **Ten deliberate defects, one per card**, none of which is pinned by a seed
  test: a test asserting the buggy behavior would have to be rewritten by the
  agent, and a test asserting the correct behavior would hand over the fix. Each
  defect is observable only through its card's probe or the spec.

The builder is deterministic by construction — fixed identity and date,
`--template=` on init, `--no-verify` on the commit, `core.autocrlf=false` on both
the add and the commit. Rebuilding the identical tree reproduces
`b0ef652d91b20c57965eb4257cab93301ff68999` on any host, which is what makes the
pin above meaningful.

The seed is **synthetic**. It has a backlog, but not a real one. A batch run
against it measures the arms on a purpose-built repository and must be labeled
that way; it is not evidence about real consumer codebases.

## 3. The slate

Ten cards in `benchmarks/tasks/TASK-P3C-01.md` … `TASK-P3C-10.md`. Each carries
the prompt, the frozen rubric, the Verify probe, and a note naming the plausible
wrong fix the probe is built to catch.

| # | Level | Task | Defect in the seed | Discriminating rubric item (the wrong fix it catches) | Files allowed |
|---|---|---|---|---|---|
| 01 | L1 | Count jobs, not attempts | `jobs` increments per attempt | `R3`: a dedupe set/filter inside the counters makes the number right and the meaning wrong; the probe counts `inc` calls on a fake | `src/dispatcher.js`, `test/dispatcher.test.js` |
| 02 | L1 | Rename the dry-run flag, keep the old spelling | only `--DRY_RUN` exists | `R3`: warning twice, warning on the new spelling, or warning per occurrence | `src/cli.js`, `src/app.js`, `test/cli.test.js`, `test/integration.test.js` |
| 03 | L1 | Report a finished job as finished | `status()` counts `enqueue` records as pending | `R1`/`R2`: fixing `done` but not `failed` passes half the probe; counting queue size passes nothing | `src/app.js`, `test/integration.test.js` |
| 04 | L2 | Survive a restart without re-dispatching | intake ignores the store | `R2`: "skip any id the log mentions" passes `R1` and silently drops unfinished work | `src/app.js`, `test/integration.test.js` |
| 05 | L2 | A rejected batch leaves no trace | batch appends per item before the capacity check | `R1`: a try/catch around the loop cannot retract records already appended; the probe reads the record count | `src/app.js`, `test/integration.test.js` |
| 06 | L2 | Publish counts, update the uncovered caller | no `counts`, no `scheduler.sweep` | `R3`: a dispatcher-only change leaves `sweep` missing; a `sweep` built on `processed.length` returns 0 for two failing jobs | `src/dispatcher.js`, `src/scheduler.js`, `src/app.js`, `test/dispatcher.test.js`, `test/scheduler.test.js` |
| 07 | L3 | Version the store format without rewriting it | records carry no version; only one shape is read | `R4`: skipping an unknown-version record instead of refusing it; `R2`: "add `version: 2` to writes" leaves old records versionless | `src/store.js`, `test/store.test.js` |
| 08 | L3 | Reproducible, bounded backoff | backoff uses `Math.random` and ignores the cap | `R2`: the seed's schedule runs 3× past `jitterCapMs`; `R3`/`R4`: a draw or wait before the first attempt, or after the last | `src/dispatcher.js`, `test/dispatcher.test.js` |
| 09 | L3 | Satisfy the backpressure spec | `BackpressureError` does not exist | `R4`: the cheapest way to green the spec is to edit it; the probe compares its digest first | `src/app.js`, `test/integration.test.js` |
| 10 | L3 | Draining must not degrade with queue size | `drain()` shifts per item | `R2`: an index cursor in `dequeue` that leaves `drain` calling it still moves every item; the probe counts `shift` calls | `src/queue.js`, `test/queue.test.js` |

Level mix: three L1, three L2, four L3. Each level is represented by at least
three cards, so a per-level reading is not a single-task anecdote.

Card rules, applied to all ten:

- The prompt names a **symptom or a document**, never the file to edit. Finding
  the site is part of the task.
- Where a formula or a count decides the outcome, the prompt states it. The
  rubric adds no hidden requirement.
- Every card fixes a maximum changed-file set, so a solution that edits the test
  harness, the spec, or an unrelated module is out of scope by construction.
- No card allows deleting or weakening a pre-existing assertion.

## 4. Probe discrimination — the gate before any spend

Two independent checks, both zero-spend, both already run.

### 4.1 Reference-versus-seed validation

`benchmarks/validate-phase3c-probes.sh` builds the pinned seed twice per card and
runs the card's Verify command with the driver's own field-extraction rule:

- **bare tree** — the seed exactly as committed; the probe must **fail**.
- **reference tree** — the seed plus the card's reference solution from
  `benchmarks/tasks/reference/p3c/`; the probe must **pass**.

Result on `b0ef652d…`:

```
PROBE|01..10|bare=fail|reference=pass
VALIDATE|OK|cases=10
```

### 4.2 Driver screening mode

`benchmarks/run-ab-benchmark.sh --screen --arm bare --seed S --tasks a,b,…` runs
every probe on a throwaway copy of the seed and refuses a slate whose probes are
already green:

```
SCREEN|P3C-01|arm=bare|probe=fail
…
SCREEN|OK|arm=bare|tasks=10|red=10|seed=b0ef652
```

Screening needs no model, no CLI, no order seed and no blind key, and it skips
the host guard because it starts no session. It still enforces the seed guard:
an unclean seed, an instruction surface, or a `heyloey` reference stops it.

The driver harness (`scripts/tests/run-benchmark-driver-tests.sh`) pins this mode
with six cases: the red probe, the seed left clean, a green probe refused, a card
without Verify refused, `--arm` without `--screen` refused, and `promptkit_os`
refused.

### 4.3 What this establishes, and what it does not

It establishes that each probe is red on the delivered seed and green on a
correct solution, on this host, at this SHA. It does **not** establish that the
reference is the only solution, and it does not establish that each card's fix is
*minimal*: `src/app.js` serves cards 03, 04, 05 and 09, so the reference tree for
those cards carries all four fixes. A probe passing on that tree therefore shows
the requirement is reachable, not that the graded packet's change to the same
file is the one that satisfied it — that separation comes from the rubric's
file-scope item and the grader reading the diff.

## 5. Arms and parity

Unchanged from Phase 3b, and enforced by the same code:

- `promptkit_os` — the directive installed through the engine's `init.sh`, with
  the consumer surface staged at `<project>/.promptkit`.
- `bare` — Command Code alone, no directive, no kit.

Both arms run through `session_argv`, which is arm-blind by construction:
`guard_cross_arm` renders both arms and fails closed on any byte difference in
prompt, model, `--max-turns`, permission mode or tool set. `--arm` exists only in
screen mode; on a batch it is refused, because a batch always runs both arms.

## 6. Pre-registration and spend

| Item | Value |
|---|---:|
| Tasks | 10 |
| Arms | 2 |
| Repeats per cell | 3 |
| Primary sessions | **60** |
| Calibration (1 repeat, 3 tasks × 2 arms) | 6 |
| Infrastructure replacements | 10 |
| Total CLI sessions (ceiling) | **76** |
| Wall-clock ceiling | **30 hours** |
| Per-session timeout | **1,800 s** |
| Max turns | 40 |
| `transcript_cost_usd` guardrail | **$40** |

At 3b's observed ~$0.42–0.47 CPAC per session, 60 sessions model to roughly $26;
the $40 figure is the abort threshold on actual transcript cost, not a projection.
The session and time caps bind; modeled CPAC is not a bill.

Pre-registered seeds, recorded in `env.txt` and `isolation.txt` at batch time: an
order seed for the task budget and cell order, and a distinct shuffle seed for
the blind-id mapping. For this batch they are `order_seed=60564652` and
`shuffle_seed=760853`, derived from the batch label rather than chosen — see
`benchmarks/runs/2026-10-31-phase3c-batch-deepseek-v4.1-flash/PREREGISTRATION.md`
for the derivation, which reproduces them from `sha256sum` alone and shares no
value with any 3b or 3c-calibration seed. The whole plan is materialized and committed to
`order.tsv` before the first session, so a mid-batch stop cannot truncate the
pre-registration to an attempted prefix. The blind key is written outside `<out>`
and outside every workspace a grader reads.

**No extra runs.** No re-running a task because the first result was surprising,
no "one more repeat", no task dropped after seeing an arm's result. A timeout is
recorded as a timeout and stays in the ITT denominator.

## 7. Grading

- Rubrics are frozen by the cards above; the Verify probes are frozen by §4.
- The sheet is blind-id keyed and hashed before `--finalize` opens the key.
- **Primary endpoint is acceptance**, because that is what 3b could not measure.
  Acceptance requires every rubric item in a packet to pass, and every rubric item
  is anchored to an artifact the harness produced (probe exit, test names, changed
  file set), not to the agent's prose.
- The batch is graded by a **human primary grader** who did not run it. A machine
  re-grade may accompany it as a consistency check and must be labeled as such —
  after 3b, a machine-graded sheet is a secondary check by definition, and it
  cannot carry a decision about quality.
- The human grade is recorded by finalizing with `--graded-by human`, which
  writes `"grading": {"grader": "human", "human_accepted": true}` into every §5
  record; a machine re-grade uses `--graded-by machine` and writes
  `human_accepted: false`. The flag is required, so a batch cannot be aggregated
  without saying who asserted the rubric result.
- A second grader independently samples at least 50% of packets; disagreements are
  reported, not averaged away.

## 8. Analysis and decision rule

Preregistered, before any session:

- **Quality (primary).** Per-arm acceptance counts and rate over 60 sessions, and
  a paired per-task comparison across repeats. McNemar on the paired
  task-level outcome is reported as secondary and is not a significance test.
- **Cost (secondary).** Per-task median ratios for tokens and CPAC, median and
  mean of task ratios, with n and individual task values.
- **Interval.** Cluster bootstrap by task, 10,000 resamples, reported as a
  descriptive 95% interval. Not a proof, not a significance test.
- **Sensitivity.** ITT versus artifact-graded timeout handling; cache-read
  included/excluded; actual cost versus modeled CPAC; per-level.
- No subgroup fishing. Anything not in this section is labeled exploratory.

Decision rule:

| Outcome | Condition |
|---|---|
| **Keep** | `promptkit_os` acceptance is not below `bare`, **and** its L1+ median token ratio is ≤ 0.95 |
| **Tradeoff** | `promptkit_os` acceptance is at least 5 points higher while token/CPAC ratios are above 1.05 |
| **Worse** | `promptkit_os` acceptance is at least 5 points lower than `bare` |
| **Inconclusive** | Anything else |

**Amendment A (2026-11-01) — the Tradeoff cost bar, settled before human grading.**
Owner-authorized: the *Tradeoff* cost bar is the ITT per-task median **token ratio
above 1.05**. The accepted-only CPAC median is reported alongside with its
selection caveat (rejected runs score `INF` and drop out, so the arm that fails
more has its most expensive runs removed) plus the all-artifact sensitivity cut,
but it is not a second gate. Rationale, on principle rather than outcome: the
*Keep* row already binds cost to the token ratio alone (≤ 0.95), and only the ITT
token ratio keeps every run — an accepted-only gate can be satisfied partly by
failing more, which is incoherent as a cost bar. This amendment applies to the
forthcoming human-graded figures; it does not re-grade or re-interpret the
machine sheet, which still claims no decision.

**Worse** closes this line without Phase 4. **Inconclusive** does too, unless a
named design defect — not a disappointing number — justifies a new batch. Phase 4
cross-model work starts only on **Keep** or **Tradeoff**.

## 9. What Phase 3c does not establish

- General efficiency or quality of PromptKit OS: one model, one host, one
  synthetic repository.
- Behavior on real consumer codebases, on other models, or across hosts.
- Long-horizon or multi-user work; each session is one card, one clone, one run.
- Any public positioning change. That is the Phase 5 decision memo's job.
- Human acceptance, unless and until the human primary grading completes. Until
  then the batch result is single-grader machine evidence and is labeled that way.

## 10. Status

- [x] Seed builder written; rebuild reproduces the pinned SHA and the suite passes (65/65).
- [x] Ten cards written with rubrics, probes and file scopes.
- [x] Reference solutions written (`benchmarks/tasks/reference/p3c/`).
- [x] All ten probes discriminate: red on the seed, green on the reference.
- [x] Driver `--screen --arm bare` implemented and regression-tested (6 cases).
- [x] Zero-spend preflight: `--screen` all red, driver harness green.
- [x] Calibration: 6 sessions (P3C-01/06/08 × 2 arms, 1 repeat) at the pinned
  seed, ungraded — see `benchmarks/runs/2026-10-31-phase3c-calibration-1repeat/CALIBRATION.md`.
  It exposed a driver defect that only the `P3C-nn` ids could hit (slugify
  decamelizes, so `P3C-08` is stored under `p3-c-08`; the mirror found nothing
  and aborted after spending a session). Fixed and pinned; 1 session spent as
  an infrastructure failure, inside the 10-session replacement allowance. The
  slate, caps and decision rule above are unchanged.
- [x] Batch run: 60 primary sessions under the caps above — 59 exited 0, one was
  lost to a provider network abort and stays in the ITT denominator, 60 packets
  and a 60-row key outside the repository, 62 minutes and $0.55 of transcript
  cost. See `benchmarks/runs/2026-10-31-phase3c-batch-deepseek-v4.1-flash/README.md`.
  It found a second driver defect the slate alone could not: a **relative
  `--out`** made the last run path relative, so its slugify mirror could never
  match the CLI's absolute-path project directory, and the batch aborted on row 1
  with `TRANSCRIPT_MISSING`. `<out>` is now resolved with `realpath -m` before
  use and the harness pins a relative-`--out` batch (76 cases). One session spent
  as an infrastructure failure; 2 of the 10 replacements are used across 3c.
  The plan SHA (`b0871816…`), slate, seeds and caps are unchanged by the fix.
- [x] **Machine** grading pass — secondary, not the §7 primary. All 60 packets
  scored blind against the frozen rubrics; sheet `grading.tsv` hashed
  (`6bef724e…`) before `--finalize` opened the key; 310 of 336 items passed and
  48 of 60 packets were accepted. Finalized with `--graded-by machine`, so every
  record reads `human_accepted: false`. Method, digest and every rejected item:
  `benchmarks/runs/2026-10-31-phase3c-batch-deepseek-v4.1-flash/grading/GRADING.md`.
- [x] **Primary grading** on the blind sheet — `grading/grading-human.tsv`
  (`e4294ab3…`), 48 of 60 accepted, 314 of 336 items. **Provenance caveat:** the
  owner authorized the sheet, but the first pass across all 60 packets was
  performed by an agent; `grading/GRADING-HUMAN.md` states this in full. The
  independent machine sheet (`6bef724e…`) agrees on every packet's acceptance and
  differs on one item count (`B054`, 0/6 against 4/6).
- [ ] Second grader samples ≥50%. The 30-packet sample is drawn
  (`grading/second-grader-sample.txt`) but unscored by anyone other than the pass
  that produced the primary sheet.
- [x] `--finalize --graded-by machine` and the §8 comparison: acceptance 26/30
  against 22/30, token ratio median 1.115, CPAC ratio median 0.980. The rule does
  not say whether *Tradeoff* needs both ratios above 1.05 or either one, so it
  reads as Tradeoff or Inconclusive depending on that; the fork is recorded as a
  pre-registration defect instead of being settled after the numbers were seen.
- [x] Cost-bar reading settled by Amendment A above (owner-authorized 2026-11-01,
  before human grading): *Tradeoff* needs acceptance ≥ 5 points higher **and** the
  ITT token ratio above 1.05; CPAC stays reported context. Applies prospectively
  to the human-graded figures only.
- [x] Report with the decision: **Tradeoff**. Acceptance +13.3 points (26/30
  against 22/30) and the ITT token-ratio median 1.115, which clears Amendment A's
  `> 1.05` bar. Not Keep (ratio above 0.95), not Worse. Recorded in the batch
  `README.md` with its limitations: one model, one host, a synthetic seed, a
  descriptive interval that still spans 1.0, and a primary sheet that is
  owner-authorized rather than independently human-reviewed.
- [x] `--finalize --graded-by human` with the primary sheet: all 60 §5 records
  re-extracted on 2026-11-01 with `grader=human` and `human_accepted: true` for
  the 48 accepted packets, so the per-record provenance now matches the batch
  report. The records carry the owner's authorization, and
  `grading/GRADING-HUMAN.md` still states that the first pass was performed by an
  agent under it.
- [x] Phase 4 **draft** design written: `benchmarks/PHASE-4-DESIGN.md` — cross-model
  work on the Amendment A cost bar. It is deliberately not pre-registered: its
  model list and Appendix A have to be frozen and signed before the first
  session, and nothing in Phase 4 has been run.
