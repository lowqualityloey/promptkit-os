# Phase 3c batch — 60 primary sessions, machine-graded

**Status: run complete, machine-graded.** This directory is the batch record for
the Phase 3c pre-registration in `benchmarks/PHASE-3C-DESIGN.md`. All 60 planned
primary sessions executed under the frozen plan; 59 exited 0 and one was lost to
a provider-side network abort. The batch produced 60 blind packets and a 60-row
key stored outside the repository.

It is **graded by a machine, not by the human primary grader the design requires**.
[`grading/GRADING.md`](grading/GRADING.md) records the sheet, its digest
(`6bef724e…`, written and hashed before `--finalize` opened the key), and the
items every rejected packet failed: **48 of 60 packets cleared their frozen
rubric** (310 of 336 items). `--finalize --graded-by machine` re-extracted all 60
records with `"grading": {"grader": "machine", "human_accepted": false}`, so no
record claims human acceptance and none can be cited as one.

## Pre-registration

The seeds were derived from the batch label rather than chosen, so no favourable
plan could be picked after the fact — see
[`PREREGISTRATION.md`](PREREGISTRATION.md) for the derivation. They are recorded
in `env.txt` and `isolation.txt` as the design requires.

| Item | Value |
|---|---|
| `order_seed` | `60564652` |
| `shuffle_seed` | `760853` |
| Plan SHA-256 | `b08718167f9ba691f528cedb504c5fc68bd35d9a727b50307bde21a041003722` (60 rows, matches the pre-session preflight exactly) |
| Seed | `b0ef652d91b20c57965eb4257cab93301ff68999` (rebuilt for this batch: 27 files, clean, 65/65 tests) |
| Engine | `84f97472ec3eb4ffe2f277aec303f1e58aac7e2d` |
| Model | `deepseek/deepseek-v4.1-flash` |
| CLI | `command-code` 1.88.0, `--max-turns 40`, `--timeout 1800`, `--profile balanced` |
| Isolation | fresh `HOME` holding only `.commandcode/auth.json`; `ISOLATION|OK`, `CROSSARM|OK|cells=60` |
| Blind key | `~/.local/state/promptkit/phase3c-keys/phase3c-batch-1.csv`, 60 rows, sha256 `d3712676e33fc64158745d3111d4ae008fd3a2b82bdc211ad3ca3c37d0473668`; no `key.csv` in `grading/` |

## Run

| | |
|---|---:|
| Window | 2026-10-31T06:43:28Z – 07:45:49Z |
| End-to-end wall clock | **3,741 s (62 min 21 s)** |
| Session wall clock (transcript sums) | 3,506 s; longest session 192 s |
| CLI exits | 59 × `0`, 1 × `6` |
| Timeouts at 1,800 s | 0 |
| Sessions stopped at the 40-turn cap | 0 |
| Packets | 60 `B*.diff` + 60 `B*.verify.txt`; 1 empty diff |
| `transcript_cost_usd` reported | **$0.55** |

## Measured

Per arm, n = 30 each (the network-aborted session stays in its arm's n and in the
design's ITT denominator):

| Arm | n | tokens_in | tokens_out | tokens_total | cache_read | tools | rework | wall_s (sum) | wall_s (mean) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `bare` | 30 | 6,765,541 | 122,415 | 7,722,895 | 6,623,744 | 475 | 34 | 1,692 | 56.4 |
| `promptkit_os` | 30 | 7,548,148 | 121,690 | 8,787,241 | 7,435,776 | 475 | 40 | 1,814 | 60.5 |
| **all** | **60** | **14,313,689** | **244,105** | **16,510,136** | **14,059,520** | **950** | **74** | **3,506** | **58.4** |

Per card, median `tokens_total` over the three repeats per arm — the shape the
design's secondary cost analysis wants, reported here without a quality reading:

| Card | Level | `bare` median | `promptkit_os` median | ratio |
|---|---|---:|---:|---:|
| P3C-01 | L1 | 235,619 | 214,977 | 0.913 |
| P3C-02 | L1 | 392,402 | 323,518 | 0.824 |
| P3C-03 | L1 | 154,354 | 203,454 | 1.318 |
| P3C-04 | L2 | 280,119 | 476,873 | 1.703 |
| P3C-05 | L2 | 315,804 | 434,223 | 1.375 |
| P3C-06 | L2 | 297,715 | 324,572 | 1.091 |
| P3C-07 | L3 | 273,086 | 270,924 | 0.992 |
| P3C-08 | L3 | 164,774 | 138,599 | 0.841 |
| P3C-09 | L3 | 262,673 | 299,230 | 1.139 |
| P3C-10 | L3 | 96,181 | 153,475 | 1.596 |

Median of the ten per-task ratios: **1.115**; mean: **1.179**. Level rollup
(all three repeats summed, n = 9/9/12 per arm):

| Level | `bare` tokens | `promptkit_os` tokens | ratio | `bare` wall_s | `promptkit_os` wall_s |
|---|---:|---:|---:|---:|---:|
| L1 | 2,235,811 | 2,239,995 | 1.002 | 430 | 415 |
| L2 | 2,974,786 | 3,731,943 | 1.254 | 727 | 820 |
| L3 | 2,512,298 | 2,815,303 | 1.121 | 535 | 579 |

These are cost figures, not benefits. On the Phase 3b slate both arms solved
everything, so a token ratio was a price with no measured return; whether that is
still true here is exactly what grading has to decide, and this file does not.

## Acceptance (machine-graded sheet)

**Rubric acceptance: 48 of 60 packets; 310 of 336 rubric items.** Twelve packets
failed at least one item — five L2 `sweep` packets, five L3 scope violations, one
L2 `queue.js` scope violation, and the empty packet from the aborted session. The
`REJECTED` items are named card by card in
[`grading/GRADING.md`](grading/GRADING.md).

| Arm | n | Accepted | Rate | `tokens_total` | rework loops |
|---|---:|---:|---:|---:|---:|
| `bare` | 30 | 22 | 0.73 | 7,722,895 | 34 |
| `promptkit_os` | 30 | 26 | 0.87 | 8,787,241 | 40 |

Per card, accepted repeats out of three (paired by card):

| Card | Level | `bare` | `promptkit_os` | Only one arm at 3/3 |
|---|---|---:|---:|---|
| P3C-01 | L1 | 3/3 | 3/3 | neither |
| P3C-02 | L1 | 3/3 | 3/3 | neither |
| P3C-03 | L1 | 3/3 | 3/3 | neither |
| P3C-04 | L2 | 2/3 | 3/3 | `promptkit_os` |
| P3C-05 | L2 | 2/3 | 3/3 | `promptkit_os` |
| P3C-06 | L2 | 0/3 | 1/3 | neither (both below 3/3) |
| P3C-07 | L3 | 3/3 | 3/3 | neither |
| P3C-08 | L3 | 3/3 | 3/3 | neither |
| P3C-09 | L3 | 1/3 | 1/3 | neither |
| P3C-10 | L3 | 2/3 | 3/3 | `promptkit_os` |

This is the sheet, not the decision. The primary endpoint is acceptance and the
primary grader is a human who did not run the batch; this sheet is a secondary
consistency check under §4 and cannot carry a quality decision on its own.

### What the pre-registered rule gives, and where it is ambiguous

Applying §8 to the sheet above:

- **Acceptance**: `promptkit_os` 26/30 against `bare` 22/30 — **13.3 points
  higher**, past the 5-point bar in the *Tradeoff* row.
- **Cost**: the median of per-task token ratios is **1.115** over all runs, above
  the 1.05 bar. The median of per-task CPAC ratios is **0.980** over the 9 cards
  where both arms have an accepted run, below it.

The rule does not say whether *Tradeoff* needs both ratios above 1.05 or either
one. Read as **either**, the pre-registered outcome is **Tradeoff**; read as
**both**, it is **Inconclusive**. Neither reading is a Keep, because the token
ratio is above 0.95. That fork is a defect in the pre-registration, recorded here
rather than settled after seeing the numbers.

The CPAC figure also carries a selection effect the design did not anticipate:
rejected runs score `INF (REJECTED)` and drop out of the median, so the arm that
fails more often has its most expensive runs removed from its own median. The
token ratio keeps every run and does not have that problem; per-task CPAC ratios
in this batch are not like-for-like, and `BENCH|SUMMARY` reports `cpac_n=22` and
`cpac_n=26` for that reason. The interval and sensitivity section below measures
that effect: 0.980 accepted-only against 1.135 when every artifact run is kept.

## Interval and sensitivity (descriptive)

§8 asks for a task-cluster interval and four sensitivity cuts; this section adds
them to the machine-graded sheet, plus two exploratory additions (an
acceptance-difference interval and an all-artifact CPAC cut). They are
descriptive, not significance tests, and they do not settle the decision rule.

Each card is one cluster. The cost intervals resample the ten task ratios with
replacement 10,000 times and take the 2.5th and 97.5th percentiles of the
resampled medians; the CPAC accepted-only interval uses the nine cards where both
arms have an accepted run. The acceptance interval resamples the ten cards and
pools the repeats per arm within each draw; the complete-case cut drops the
aborted bare run from the denominator for that arm. Seeds are the first four
bytes, big-endian, of SHA-256 over a fixed metric tag and the batch label
(`phase3c-task-cluster-bootstrap|2026-10-31-phase3c-batch-deepseek-v4.1-flash`
and `phase3c-acceptance-bootstrap|2026-10-31-phase3c-batch-deepseek-v4.1-flash`):
`2135913078` for the cost ratios and `125716171` for acceptance, so they were
derived rather than chosen after the ratios were seen. Percentiles use linear
interpolation. No new tool or dependency was added.

### Cost ratios

| Statistic | Clusters | Median | Mean | 95% interval |
|---|---:|---:|---:|---:|
| Token ratio, ITT | 10 | 1.115 | 1.179 | 0.912 to 1.457 |
| Token ratio, complete-case | 10 | 1.115 | 1.164 | 0.912 to 1.383 |
| Token ratio, cache reads excluded | 10 | 1.206 | 1.214 | 0.945 to 1.510 |
| CPAC ratio, accepted runs only (harness) | 9 | 0.980 | 1.049 | 0.829 to 1.309 |
| CPAC ratio, all artifact runs (exploratory) | 10 | 1.135 | 1.154 | 0.917 to 1.357 |

Every interval includes 1.0 and the 1.05 cost bar, so none of these cuts resolves
the cost direction at this sample size; the point medians are what the rule uses,
and the interval is descriptive.

### Acceptance difference (exploratory interval)

| Statistic | Clusters | Point | 95% interval |
|---|---:|---:|---:|
| Acceptance difference, ITT | 10 | +13.3 points | +3.3 to +23.3 |
| Acceptance difference, complete-case | 10 | +10.8 points | +0.7 to +20.9 |

### Per-task inputs

These are the ten (or nine) ratios the intervals resample. `n/a` means at least
one arm had no accepted run, so the harness CPAC is `INF` and no ratio exists;
`P3C-06` is therefore excluded from the nine-cluster accepted-only CPAC
interval. The all-artifact column keeps every packet that produced a diff,
including rejected packets, and always excludes the provider-aborted cell
because it produced no artifact and no measurable work.

| Card | Level | Token ratio (ITT) | Token ratio (cache excluded) | CPAC ratio (accepted) | CPAC ratio (all artifacts, exploratory) |
|---|---:|---:|---:|---:|---:|
| P3C-01 | L1 | 0.912 | 1.170 | 0.920 | 0.920 |
| P3C-02 | L1 | 0.824 | 0.945 | 0.829 | 0.829 |
| P3C-03 | L1 | 1.318 | 1.242 | 1.280 | 1.280 |
| P3C-04 | L2 | 1.702 | 1.512 | 1.160 | 1.619 |
| P3C-05 | L2 | 1.375 | 1.822 | 1.309 | 1.357 |
| P3C-06 | L2 | 1.090 | 0.913 | n/a | 1.129 |
| P3C-07 | L3 | 0.992 | 1.510 | 0.980 | 0.980 |
| P3C-08 | L3 | 0.841 | 0.747 | 0.853 | 0.853 |
| P3C-09 | L3 | 1.139 | 0.991 | 0.682 | 1.141 |
| P3C-10 | L3 | 1.596 | 1.293 | 1.430 | 1.430 |

### What the cuts show

- **Cache reads move the token result.** 14,059,520 of 16,510,136 tokens (85.2%)
  are cache reads. Excluding them (`tokens_total - cache_read_tokens`, so
  rework-loop tokens stay in) raises the median task ratio from 1.115 to 1.206
  and shifts the interval from 0.912–1.457 to 0.945–1.510. The direction is
  unchanged, but the size is not cache-neutral; the pre-registered token ratio
  keeps the §2 convention (cache reads included), and this cut shows the
  convention matters.
- **The CPAC figure is selection-sensitive.** The harness scores rejected runs
  `INF`; the accepted-only median is 0.980 over nine cards. Keeping the modeled
  cost of every artifact run (rejected packets included, the aborted cell
  excluded) raises it to 1.135 over ten cards. That is the selection effect the
  earlier note named, now measured: the arm that fails more often has more of its
  expensive runs removed. The 1.135 figure is a sensitivity, not the
  pre-registered CPAC, and it does not replace the 0.980 used in the rule.
- **The aborted cell changes the tail, not the point.** Excluding
  `P3C-10-bare-r2` leaves the token median at 1.115 and narrows the upper bound
  from 1.457 to 1.383. Acceptance moves from 22/30 (73.3%) to 22/29 (75.9%), so
  the gap falls from 13.3 to 10.8 points. The missing-cell bounds are 10.0 to
  13.3 points: 22/30 if a replacement would have been rejected, 23/30 if it
  would have been accepted. No session timed out; the only missing artifact is
  this provider abort, so the artifact-graded cut is the aborted-cell exclusion.
  No replacement was run, under §6.
- **Acceptance has the widest interval.** The task-cluster interval for the
  13.3-point ITT difference is +3.3 to +23.3 points; complete-case it is +0.7 to
  +20.9. The point estimate clears the 5-point bar in both cuts, but the interval
  includes values below it, so the margin is not stable across task clusters.
  With ten clusters that is expected, and it is why the interval is descriptive.
- **Actual cost is coarse but points the same way as tokens.** The reported
  `transcript_cost_usd` totals are $0.26 for `bare` and $0.29 for
  `promptkit_os` ($0.55 total), a 1.115 aggregate ratio. The field is rounded to
  two decimals, so the per-run median is $0.01 for both arms and only the
  aggregate is stable; it agrees in direction with the token ratio and the
  all-artifact CPAC, not with the accepted-only CPAC.

Per level, the L2 block carries the acceptance gap; the token medians are not the
sum-based rollup in the table above, because the rollup weights by tokens and the
median treats each card equally:

| Level | Cards | Accepted, `bare` | Accepted, `promptkit_os` | Token ratio, median of cards | CPAC ratio, median of cards |
|---|---:|---:|---:|---:|---:|
| L1 | 3 | 9/9 (100.0%) | 9/9 (100.0%) | 0.912 | 0.920 |
| L2 | 3 | 4/9 (44.4%) | 7/9 (77.8%) | 1.375 | 1.234 (n=2) |
| L3 | 4 | 9/12 (75.0%) | 10/12 (83.3%) | 1.066 | 0.917 |

The interval is descriptive and does not enter the rule, but the CPAC sensitivity
shows the fork is also a choice of population. Under the harness CPAC (rejected
runs `INF`) the **both ratios** reading is still **Inconclusive**; under the
all-artifact sensitivity both ratios are above 1.05, so that reading would be
**Tradeoff**, and the **either ratio** reading is **Tradeoff** on both cuts. The
CPAC population therefore has to be named before the next pre-registration. No
decision is claimed, because the primary endpoint still requires the human
grader §7 names.

## Blinding of the delivery

Checked directly against `grading/`, read-only: `promptkit` appears in 0 files,
no packet carries a scenario id (`P3C-nn-<arm>`), no absolute run path, and no
`session.log`. The word `bare` appears in 63 of the 120 packet files, and every
hit is the 3c seed's own test name — "parses values, bare flags and a job list" —
which is identical in every packet. A mechanical `\bbare\b` scan of a real
delivery therefore proves nothing on its own; arm-label shapes are what the audit
should look for.

## The one lost session

`P3C-10-bare-r2` exited `6` after 61 s with `Error: Unable to connect to the API.
Please check your network connection.` It is a provider-side network abort: zero
tokens, an empty diff, `verify_exit=1`.

It is **retained in the ITT denominator and not re-run**, under §6's no-extra-runs
rule, and it is disclosed for the ITT-versus-artifact sensitivity the design
pre-registers. If the analyst would rather replace the cell before grading, the
honest route is a recorded two-session cell (both arms, same repeat) in its own
keyed batch, which spends 2 of the remaining 8 replacement sessions; that is a
decision for the grader and analyst to make explicitly, not something to do
silently while the batch record is being written.

## Sessions spent against the caps

| Item | Used | Ceiling |
|---|---:|---:|
| Phase 3c primary sessions | 60 | 60 |
| Calibration sessions (separate, ungraded) | 6 | 6 |
| Infrastructure failures | 2 | 10 |
| — 3c calibration: `P3C-08` slugify mirror | 1 | |
| — this batch: relative `--out` (below) | 1 | |
| Total Phase 3c CLI sessions | 68 | 76 |
| Wall clock | 62 min | 30 h |
| Actual transcript cost | $0.55 | $40 (abort threshold) |

## Harness defect this batch found: a relative `--out`

The first launch passed `--out benchmarks/runs/…` (relative). `command-code`
records a transcript under `slugify(absolute cwd)`, the driver builds each run
path from `<out>`, so a relative `<out>` produced a run path whose slug could
never match the CLI's project directory. Row 1 completed, then the batch aborted
with `BENCH|ERROR|TRANSCRIPT_MISSING|P3C-09-bare-r2` — a fails-closed abort after
spending one session. That spent session is the second infrastructure failure
above, and the aborted attempt's artifacts were kept outside the repository.

`benchmarks/run-ab-benchmark.sh` now resolves `<out>` to an absolute path with
`realpath -m` before it is used for anything, so the key checks and the run paths
compare like with like. `scripts/tests/run-benchmark-driver-tests.sh` pins it
(76 cases): a batch run from a relative `<out>` must resolve its transcripts and
record absolute run directories. The stub CLI had always used absolute paths,
which is why no existing case could catch this. The pre-registered plan, seeds,
slate and caps were unchanged by the fix — the relaunch reproduced plan
`b0871816…` exactly.

## Limitations

- **Graded by a machine.** Every rubric item was applied to a packet artifact,
  but the grader is the coding agent that ran the batch, so this is a secondary
  check and not independent acceptance. The human primary grading and the second
  grader sample are both outstanding.
- **The interval and sensitivity were computed after the batch.** The method was
  pre-registered in §8, but the bootstrap seeds were derived from the batch label
  rather than frozen before the run; the intervals are descriptive and do not
  change the pre-registered rule or substitute for human acceptance.
- One model, one host, one **synthetic** repository. This is not evidence about
  real consumer codebases.
- One of 60 sessions is an infrastructure loss and is counted, not replaced.
- `tokens_total` and `wall_clock_seconds` are transcript-derived (cache reads
  included in the total, excluded from `C_inference` per the v1 convention);
  `transcript_cost_usd` is what the CLI reported, at 2 decimal places, so the
  $0.55 total is a sum of rounded values.
- Probe reds are artifact facts, not rubric outcomes: a packet can fail its probe
  and still pass every rubric item that is scoped to its diff.
- The batch is a single-grader artifact until a human grader and a second grader
  sample complete; until then it is machine-gradeable evidence only.

## Next steps

1. A human primary grader, who did not run the batch, grades each
   `grading/B*.diff` (+ `B*.verify.txt`) against its card frozen rubric without
   opening the key. The machine sheet at `grading/grading.tsv`
   (`6bef724e…`) is available as a cross-check but must not be the starting
   point, or the second read stops being independent.
2. A second grader independently samples at least 50% of packets; disagreements
   are reported, not averaged away.
3. Re-finalize with `--graded-by human` once that sheet exists:
   `bash benchmarks/run-ab-benchmark.sh --finalize "$PWD" --grading "$PWD/grading/grading.tsv" --graded-by human`,
   which overwrites each record provenance with `grader: human`.
