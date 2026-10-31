# Phase 3c calibration — one repeat, not the batch

This directory is **not** the Phase 3c batch. It is a 6-session run (three cards,
one per level, × two arms × one repeat) retained for cost, duration and packet
calibration. It is **ungraded**: no rubric was applied, no packet was read, and
nothing here is evidence about either arm. Its job was to prove that the 3c seed,
cards and driver can carry a 60-session batch without surprises.

- **Run**: 2026-10-31T05:51:24Z – 05:55:23Z (end-to-end 230 s; 216 s of
  transcript-derived session wall clock, maximum 61 s)
- **Plan**: `order_seed=20261031`, `shuffle_seed=48392761`,
  `sha256=0229d0b0bd802a9723407646281a0308be94922ebd68fef1f16dd1d94b76c101`,
  **6 rows** — see `order.tsv`
- **Engine**: `84f97472ec3eb4ffe2f277aec303f1e58aac7e2d` (working tree carries
  the uncommitted Phase 3c work; the staged kit is copied from it)
- **Seed**: `b0ef652d91b20c57965eb4257cab93301ff68999`, rebuilt from
  `benchmarks/seed/build-phase3c-seed.sh` for this run, clean, 27 tracked files
- **CLI**: `command-code` 1.88.0; **model**: `deepseek/deepseek-v4.1-flash`;
  `--max-turns 40`, `--timeout 1800`, `--profile balanced`
- **Host**: isolated `HOME=/tmp/pk-home-p3c-cal-20261031T054152Z` holding only
  `.commandcode/auth.json` — no global instruction surface, no MCP servers, no
  hooks, no taste file, no `heyloey` on `PATH` (`isolation.txt`)
- **Packets**: 6 diffs and 6 verification files, blind ids `B001`–`B006`
- **Blind key**: outside the repository at
  `/home/heyloey/.local/state/promptkit/phase3c-keys/phase3c-calibration-1repeat.csv`
  (mode 700 dir, sha256 `c8ab8c51…`, 6 rows). Never opened, never applied.

## Measured

| Scenario | Arm | Lvl | tok_in | tok_out | tok_total | cache_read | tools | rework | wall_s | diff lines |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| P3C-01-bare-r1 | bare | 01 | 115,987 | 961 | 164,910 | 140,800 | 16 | 2 | 23 | 64 |
| P3C-01-promptkit_os-r1 | promptkit_os | 01 | 157,216 | 1,247 | 210,109 | 183,680 | 10 | 2 | 28 | 53 |
| P3C-06-bare-r1 | bare | 06 | 330,854 | 6,872 | 360,661 | 318,720 | 35 | 1 | 61 | 136 |
| P3C-06-promptkit_os-r1 | promptkit_os | 06 | 288,347 | 4,027 | 345,296 | 300,288 | 19 | 2 | 53 | 151 |
| P3C-08-bare-r1 | bare | 08 | 137,737 | 1,014 | 162,244 | 139,520 | 9 | 1 | 23 | 49 |
| P3C-08-promptkit_os-r1 | promptkit_os | 08 | 196,595 | 1,730 | 222,926 | 196,224 | 12 | 1 | 28 | 50 |

| Arm | n | tokens_total | median tokens | wall_s | rework | tool calls | transcript USD |
|---|---:|---:|---:|---:|---:|---:|---:|
| bare | 3 | 687,815 | 164,910 | 107 | 4 | 60 | 0.01 |
| promptkit_os | 3 | 778,331 | 222,926 | 109 | 5 | 41 | 0.03 |
| **all** | **6** | **1,466,146** | — | **216** | **9** | **101** | **0.04** |

`transcript_cost_usd` is what the CLI reported per transcript. At ~$0.007 per
session this run cost about four cents, so the `$40` abort threshold in §6 of the
design is nowhere near binding at 60 sessions.

## Acceptance, as far as it goes without grading

Run-level acceptance is 6 of 6: every session exited 0, every session produced a
transcript the extractor parsed, and every session produced a non-empty stripped
diff (49–151 lines) plus a `verify.txt`. No session hit the 40-turn cap, and
none came near the 1,800 s per-session timeout.

**Rubric acceptance is not computed here.** It requires grading the six packets
against the frozen rubrics, which this run was explicitly not for. The records
carry `accepted=false` because the driver writes that before grading; `--finalize`
is what re-extracts them with the graded flag. Do not read `accepted=false` in
this directory as a result.

## Infrastructure failure: one session spent, then `TRANSCRIPT_MISSING`

The first attempt (2026-10-31T18:44 local) ran `P3C-08-bare-r1` to completion and
then aborted the batch with `BENCH|ERROR|TRANSCRIPT_MISSING|P3C-08-bare-r1`.
Nothing was graded and no key was written; the batch was restarted from row 1
after the fix. That is **1 session spent as an infrastructure failure**, which
the design's replacement allowance (10 sessions) covers. The re-run executed all
six rows afresh, so no cell carries two packets.

**Cause.** `command-code` records transcripts under
`@sindresorhus/slugify(cwd)`, which decamelizes before lowercasing: `P3C-08`
becomes `p3-c-08`. The driver's ASCII mirror of that alphabet skipped the
digit→upper split, computed `p3c-08`, found no directory, and failed closed. A
fails-closed abort after a spent session is the right shape of failure, but the
mirror was wrong.

**Fix.** `slugify_run_path` in `benchmarks/run-ab-benchmark.sh` now applies
slugify's two decamelize rules (`[a-z0-9][A-Z]` and `[A-Z][A-Z][a-z]` boundaries)
before lowering and separator folding. The mock CLI in
`scripts/tests/run-benchmark-driver-tests.sh` mirrors the same rule, and two
regression cases pin it: one asserts the extracted function against the real
tool's observed output (`P3C-08` → `p3-c-08`, `AbC9dE` → `ab-c9d-e`,
`BENCH-L2-04` → `bench-l2-04`, unchanged), the other runs a `P3C-08` card
end-to-end and requires its transcript to resolve under `p3-c-08`. Harness:
75 passed, 0 failed.

## What this does not establish

- Anything about either arm. Six ungraded sessions cannot measure quality, and
  one repeat per cell cannot separate cost from run-to-run variance.
- That the 60-session batch will stay inside 30 hours. It projects to roughly
  36 minutes of session wall clock at the observed mean, but the cap is a
  ceiling, not a forecast.
- That the ten cards are uniformly priced. Three were sampled; `P3C-06` (the
  five-file, cross-module L2) cost about twice the L1 and L3 cards in tokens and
  wall clock, which is the shape a per-level reading should expect.
