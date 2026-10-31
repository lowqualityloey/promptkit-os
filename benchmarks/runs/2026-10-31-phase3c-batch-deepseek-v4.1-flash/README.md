# Phase 3c batch — 60 primary sessions, ungraded

**Status: run complete, not graded.** This directory is the batch record for the
Phase 3c pre-registration in `benchmarks/PHASE-3C-DESIGN.md`. All 60 planned
primary sessions executed under the frozen plan; 59 exited 0 and one was lost to
a provider-side network abort. The batch produced 60 blind packets and a 60-row
key stored outside the repository.

It is **not graded and carries no arm comparison**. Under the design's §7 the
primary endpoint is acceptance, and acceptance is a human grader's judgment made
from the packets without opening the key. Nothing in this file, and nothing in
the telemetry below, substitutes for that.

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

## Acceptance, as far as it goes without grading

**Session-level: 60 of 60.** Every planned row ran, every session produced a
transcript the extractor parsed, and every session produced a stripped diff and a
`verify.txt`. No session hit the turn cap and none came near the 1,800 s timeout.

**Probe outcomes, aggregate only: 54 of 60 packets carry `verify_exit=0`; 6 do
not.** The frozen Verify probes are red on the untouched seed, so a red packet is
a run that did not satisfy the probe in the session. The per-arm split is
deliberately not printed here: it is derivable from `manifest.tsv`, but writing it
into the batch record would put a quality claim in front of the grader who is
supposed to read the packets first. One of the six is the aborted session below;
the other five are real session outcomes.

**Rubric acceptance is not computed.** `accepted=false` in every `record.json` is
the driver's pre-grading placeholder, not a result — `--finalize` is what
re-extracts records with a graded flag.

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

- **Ungraded.** No rubric was applied to these packets. Nothing here is an
  acceptance rate, an arm comparison, or a decision.
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
   `grading/B*.diff` (+ `B*.verify.txt`) against its card's frozen rubric without
   opening the key, and writes `grading/grading.tsv` as
   `blind_id<TAB>rubric_passed<TAB>rubric_total<TAB>accepted`.
2. A second grader independently samples at least 50% of packets; disagreements
   are reported, not averaged away.
3. `bash benchmarks/run-ab-benchmark.sh --finalize "$PWD" --grading "$PWD/grading/grading.tsv"`,
   then the §8 analysis and the decision rule.
