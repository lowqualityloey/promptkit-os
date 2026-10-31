# Phase 3b Batch — `deepseek/deepseek-v4.1-flash`

Second live batch of the dual-condition protocol in
[`docs/BENCHMARK-METHODOLOGY.md`](../../../docs/BENCHMARK-METHODOLOGY.md) §4, run
under the pre-registered protocol in
[`benchmarks/PHASE-3B-PROTOCOL.md`](../../PHASE-3B-PROTOCOL.md).

> **Status: the grading behind this report is machine grading, not the human
> primary grading §4 requires.** The sheet was written and hashed blind, and every
> rubric item is anchored to a probe the harness ran, but the grader was the
> coding agent that ran the batch. Read every acceptance figure below as a
> secondary consistency check. §11's independent-grader item is still open.
>
> The provenance is recorded, not implied: all 36 §5 records carry
> `"grading": {"grader": "machine", "human_accepted": false}` beside their
> `accepted` flag, and `finalize.log` opens with
> `GRADING|PROVENANCE|grader=machine|human_accepted=false|records=36`.

- **Date**: 2026-10-31, sessions 03:11:03Z – 03:26:22Z
- **Model**: `deepseek/deepseek-v4.1-flash`
- **Command Code**: 1.88.0 (pinned prefix, `autoUpdate: false`)
- **Engine**: `84f9747` (its consumer surface — `init.sh`, `init.ps1`, `LICENSE`, `VERSION`, `workflows/`, `protocols/`, `templates/`, `scripts/` — staged at `.promptkit` in that arm only)
- **Seed**: `16b3cf74c809c23dd48466da2212bd3e67a530ed` (synthetic neutral seed, `removed=0`)
- **Profile**: `balanced`, `--tools-all --yolo --max-turns 40 --timeout 1800`
- **Plan**: 36 rows, `e3727d97…`, order seed `20261027`, shuffle seed `90613245`
- **Batch**: 6 tasks × 2 arms × 3 repeats = 36 sessions, zero replacements
- **Spend**: $0.10 actual `transcript_cost_usd` against §9's $25 guardrail; 48 of
  54 permitted sessions used (12 of those 48 were the retained calibration run)
- **Decision**: **Inconclusive** under §7.3 — no Phase 4, no public positioning

## Protocol

Both arms began from a fresh clone of the same seed at the same SHA. Both saw the
same prompt bytes, model, tools, permission mode, max turns, and timeout — checked
by `guard_cross_arm` before the first session, with a prompt and argv digest per
task in `crossarm.txt`. The `promptkit_os` arm additionally staged the engine's
consumer surface at `.promptkit` and installed the Balanced directive; the `bare`
arm received no installation.

Per-run diffs were anchored to the seed SHA (so an agent commit under `--yolo`
cannot empty a packet), stripped of engine artifacts, and shuffled into blind ids
`B001`–`B036`. The harness ran each card's `Verify` command and shipped
path-scrubbed output as `B*.verify.txt` with `verify_exit` on its first line. The
sheet was written and hashed (`6e2962a6…`) before `--finalize` read the key; the
key lives outside the repository and the sheet's digest is unchanged after.

Task slate and rubrics (all frozen before the first session):

| Task | Level | Rubric | Discriminating item |
|---|---|---:|---|
| [`BENCH-L0-02`](../../tasks/TASK-BENCH-L0-02.md) — `queue.peek()` | L0 | 5 | R2, a `peek` built on `shift()` consumes the head |
| [`BENCH-L1-03`](../../tasks/TASK-BENCH-L1-03.md) — dispatcher counts | L1 | 5 | R3, counts recomputed from job count instead of the arrays |
| [`BENCH-L1-04`](../../tasks/TASK-BENCH-L1-04.md) — `--DRY_RUN` | L1 | 6 | R3, building the queue then skipping the ready line |
| [`BENCH-L2-03`](../../tasks/TASK-BENCH-L2-03.md) — unbounded capacity | L2 | 6 | R3, over-broad `positiveInt` relaxation |
| [`BENCH-L2-04`](../../tasks/TASK-BENCH-L2-04.md) — `enqueueMany()` | L2 | 6 | R2/R4, per-item loop that half-appends; strict `<` fit check |
| [`BENCH-L3-01`](../../tasks/TASK-BENCH-L3-01.md) — retry + backoff | L3 | 7 | R5, sleep after the final attempt or off-by-one delay |

## Results

All 36 runs were accepted against their frozen rubrics — 210 of 210 items.

| Task | Arm | Rubric | Acc. | Tokens r1 / r2 / r3 | Median | Wall med. (s) | Rework | CPAC r1 / r2 / r3 | CPAC med. |
|---|---|---:|---:|---|---:|---:|---:|---|---:|
| `L0-02` | `bare` | 5/5 | yes | 93,159 / 74,531 / 74,018 | 74,531 | 12 | 0 | .2895 / .2337 / .2313 | .2337 |
| `L0-02` | `promptkit_os` | 5/5 | yes | 106,313 / 106,031 / 105,646 | 106,031 | 15 | 0 | .3311 / .3289 / .3269 | .3289 |
| `L1-03` | `bare` | 5/5 | yes | 114,755 / 114,939 / 114,427 | 114,755 | 16 | 0 | .3607 / .3595 / .3582 | .3595 |
| `L1-03` | `promptkit_os` | 5/5 | yes | 107,138 / 107,602 / 107,219 | 107,219 | 15 | 0 | .3353 / .3380 / .3358 | .3358 |
| `L1-04` | `bare` | 6/6 | yes | 191,383 / 143,689 / 154,852 | 154,852 | 31 | 5 | .7066 / .5603 / .5504 | .5603 |
| `L1-04` | `promptkit_os` | 6/6 | yes | 166,437 / 189,303 / 139,498 | 166,437 | 30 | 8 | .6899 / .7526 / .5447 | .6899 |
| `L2-03` | `bare` | 6/6 | yes | 225,491 / 158,651 / 169,917 | 169,917 | 25 | 3 | .7700 / .5630 / .5893 | .5893 |
| `L2-03` | `promptkit_os` | 6/6 | yes | 147,364 / 147,604 / 247,092 | 147,604 | 24 | 4 | .5288 / .5781 / .8306 | .5781 |
| `L2-04` | `bare` | 6/6 | yes | 95,450 / 96,214 / 96,432 | 96,214 | 16 | 0 | .3017 / .3044 / .3048 | .3044 |
| `L2-04` | `promptkit_os` | 6/6 | yes | 132,270 / 108,503 / 133,308 | 132,270 | 19 | 0 | .4151 / .3431 / .4192 | .4151 |
| `L3-01` | `bare` | 7/7 | yes | 145,697 / 150,943 / 170,339 | 150,943 | 37 | 2 | .4764 / .5063 / .6547 | .5063 |
| `L3-01` | `promptkit_os` | 7/7 | yes | 170,133 / 183,636 / 169,470 | 170,133 | 36 | 0 | .5644 / .5956 / .5594 | .5644 |

Per-arm aggregates (`BENCH|SUMMARY` from [`finalize.log`](finalize.log); sums
recomputed from the 36 records):

| Arm | n | Accepted | Tokens sum | Tokens mean | Tokens median | Wall sum (s) | Rework loops | CPAC mean | CPAC median | Actual cost |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `bare` | 18 | 18 | 2,384,887 | 132,493.7 | 129,314 | 412 | 10 | .4512 | .4186 | $0.04 |
| `promptkit_os` | 18 | 18 | 2,574,567 | 143,031.5 | 136,403 | 421 | 12 | .4899 | .4740 | $0.06 |

`tokens_total` is the extractor's total including rework turns; 4,269,312 of the
4,959,454 tokens were cache reads, which §2 prices at a single input tier and
does not bill separately. CPAC is modeled by `scripts/measure-cpac.sh` at its
reference rates ($3.00/M in, $15.00/M out, $0.05 per rework loop) — a comparison
constant, not an invoice. The whole batch cost **$0.10** actual.

### Per-task ratios (median of three repeats)

| Task | Token ratio | CPAC ratio |
|---|---:|---:|
| `L0-02` | 1.423 | 1.407 |
| `L1-03` | 0.934 | 0.934 |
| `L1-04` | 1.075 | 1.231 |
| `L2-03` | 0.869 | 0.981 |
| `L2-04` | 1.375 | 1.364 |
| `L3-01` | 1.127 | 1.115 |

L1+ (five tasks): **median 1.075 tokens** (mean 1.076), **median 1.115 CPAC**
(mean 1.125). Task-cluster bootstrap, 10,000 resamples, seed `20261031`:
**tokens 95% [0.869, 1.375]**, **CPAC 95% [0.934, 1.364]**.

## Decision — Inconclusive

On point estimates the batch lands in §7.3's *non-inferior, no gain, both ≤ 1.25*
row: quality is level (15 of 15 L1+ accepted per arm, no 2-repeat loss anywhere)
and the L1+ medians are 1.075 and 1.115. **Both tail values are above 1.25**,
however, and §7.3 defines Inconclusive as a bootstrap interval for the median
token ratio that includes 1.25 — which this one does. Two further conditions are
also met: more than two protocol deviations (below), and the grading is a
machine re-grade rather than the human primary grading §4 specifies.

So the pre-registered outcome is **Inconclusive: no decision, no Phase 4, no
public positioning.** The honest summary is that the treatment was not
distinguishable from bare on quality at this sample size, cost roughly the same
on the median task while varying in both directions per task, and the protocol
cannot certify "within 1.25" from five task clusters when the per-task ratios span
0.87 to 1.38.

The L0/L1 ceremony trigger for a #620 proposal does **not** fire: L0 is 1.423, but
neither L1 task exceeds 1.25 (0.934 and 1.075), which is the conjunction the rule
requires.

## Interpretation

What the batch supports: on six small, fully specified tasks against a synthetic
service repository, both conditions solved everything, and the PromptKit arm was
sometimes cheaper (`L1-03` 0.934, `L2-03` 0.869) and sometimes dearer (`L0-02`
1.423, `L2-04` 1.375). There is no quality signal to compare and no stable cost
signal to generalize.

What it does not support: any claim that PromptKit helps, hurts, or saves tokens
in general. **The quality ceiling is the headline finding** — six tasks that both
arms solve 3/3 are too easy to discriminate, so the design's quality gate has no
headroom at this difficulty. A discriminating batch needs tasks where the bare
arm sometimes fails; these were deliberately small backlog slices, and that choice
cost the study its quality signal.

The `L2-04` and `L0-02` results are worth a look before any re-run: both are
direct, low-turn tasks where the directive's fixed reads have the least work to
amortize against, which is what the token ratios show. `L1-03` and `L2-03` show
the opposite. With three repeats, per-task spread that wide is not separable from
noise.

## Deviations (all runs, replacements, and deviations)

1. **The plan was recorded at one repeat and corrected to three.** Every
   precedence preflight ran `--repeats` at its default of `1`, so the `6ac712a9…`
   digest was a 12-row plan while §2 specified three repeats. The 12 sessions that
   ran at one repeat are retained as
   [`../2026-10-31-phase3b-calibration-1repeat/`](../2026-10-31-phase3b-calibration-1repeat/CALIBRATION.md)
   — never graded, never unblinded — and §9's cap was raised 42 → 54 to hold them.
   A zero-spend preflight at `--repeats 3` pinned the 36-row plan `e3727d97…` that
   the batch then executed. The design did not change; the record did.
2. **Engine substitutions**, each with a byte-empty staged-surface diff and each
   recorded in Appendix C/D: `f6a58f0` (signed) → `76e7594` → `b23159d` →
   `84f9747`. The last two were forced — `--key-out` and the cross-arm guard did
   not exist at the earlier commits — and the staged surface is identical across
   them.
3. **Two infrastructure failures, no sample rows.** A first launch aborted on the
   expired credential before any session. A second passed a relative `--out`; its
   one session completed and the diff write then failed, because the driver writes
   `<rundir>-run.diff` after `cd`-ing into the run directory. That scenario is kept
   outside the repository at
   `~/.local/state/promptkit/attempt-2-relative-out-20261031T031049Z`.
   The batch you are reading was re-run from scratch with an absolute path.
4. **Grading was performed by the coding agent, not a human.** §4 requires a
   primary grader who did not run the batch and calls an AI re-grade a secondary
   check. That is what this is.
5. **`benchmarks/audit-blinding.sh` was not run in its own form.** It builds a
   stub delivery instead of scanning an existing one, so the real delivery was
   scanned directly instead: no arm label, scenario id, `.promptkit`,
   `session.log`, or absolute path in any of the 72 packet files. One limitation is
   recorded rather than hidden — the audit's `\bbare\b` surface matches the seed's
   own test name ("a bare flag is accepted as the string true and then
   validated"), so 39 of 72 files contain that word identically in both arms.

No timeouts: the longest session was 39 s against an 1,800 s cap, and no run
needed a replacement.

## Limitations

- **n = 5 task clusters for cost, 3 repeats per cell.** The bootstrap interval is
  descriptive, not a significance test, and at five clusters it is necessarily
  wide. Do not rank the arms from these medians.
- **A quality ceiling, not a quality comparison.** 36 of 36 accepted means the
  quality gate contributed no discrimination. Treat the acceptance counts as
  "neither arm broke anything", not as equivalence evidence.
- **Machine grading** (§4, above). A human primary grader may disagree item by
  item, particularly on `BENCH-L1-04` R1, where three packets coerce `DRY_RUN` to
  `true` inside `parseFlags` and I passed them on the prompt's "bare or with a
  value" wording.
- **One model, one host, one seed.** A synthetic seed with a 28-test suite; results
  transfer to no consumer codebase.
- **`bare` means "no PromptKit installation"**, not a vanilla CLI: both arms
  inherited the seed's environment and host isolation, and neither was given
  instruction files of any kind.
- **CPAC is modeled.** `$0.10` is what the batch actually cost; the CPAC columns
  are a comparison model at fixed rates.

## Artifacts

- [`env.txt`](env.txt), [`isolation.txt`](isolation.txt), [`crossarm.txt`](crossarm.txt) — CLI, engine/seed SHAs, model, profile, isolation verdicts, cross-arm prompt/argv digests
- [`order.tsv`](order.tsv) — the 36-row plan as executed
- [`manifest.tsv`](manifest.tsv) — scenario/arm/paths
- [`key-location.txt`](key-location.txt) — key path, SHA-256, row count (no mapping row)
- `grading/B001`–`B036` — the blind packets (`.diff` + `.verify.txt`)
- [`grading/grading.tsv`](grading/grading.tsv) — the hashed blind-id sheet
- [`grading/GRADING.md`](grading/GRADING.md) — grading method, item counts, judgement calls
- [`finalize.log`](finalize.log) — 36 `RUN|` lines and both `BENCH|SUMMARY|` lines
- `runs/<scenario>/record.json` — §5 record with the graded acceptance
- `runs/<scenario>/run.diff`, `run.stripped.diff`, `verify.txt`, `session.log` — full and artifact-stripped diffs plus harness evidence

Not published: the blind key (`~/.local/state/promptkit/phase3b-keys/phase3b-batch-r3.csv`,
36 rows, mode 600), raw Command Code transcripts, and the run clones. The mapping
is derivable from the published stripped diffs after publication; it is not a
post-publication secret.

## Reproduction

```bash
bash benchmarks/run-ab-benchmark.sh \
  --engine <checkout at 84f9747> --seed <seed at 16b3cf7> \
  --tasks benchmarks/tasks/TASK-BENCH-L0-02.md,benchmarks/tasks/TASK-BENCH-L1-03.md,benchmarks/tasks/TASK-BENCH-L1-04.md,benchmarks/tasks/TASK-BENCH-L2-03.md,benchmarks/tasks/TASK-BENCH-L2-04.md,benchmarks/tasks/TASK-BENCH-L3-01.md \
  --model deepseek/deepseek-v4.1-flash --profile balanced \
  --repeats 3 --max-turns 40 --timeout 1800 \
  --order-seed 20261027 --shuffle-seed 90613245 \
  --key-out ~/.local/state/promptkit/phase3b-keys/<new>.csv \
  --out <dir>
```

Grade the packets blind into `<dir>/grading/grading.tsv`
(`blind_id<TAB>rubric_passed<TAB>rubric_total<TAB>accepted`), then:

```bash
bash benchmarks/run-ab-benchmark.sh --finalize <dir> --grading <dir>/grading/grading.tsv
```
