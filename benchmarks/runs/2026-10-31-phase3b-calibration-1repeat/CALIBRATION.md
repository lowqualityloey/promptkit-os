# Calibration run — one repeat, not the Phase 3b batch

This directory is **not** the Phase 3b confirmatory batch. It is a 12-session
run that executed one repeat of each task × arm cell, retained for cost and
duration calibration only. Nothing here may be graded, unblinded, or reported as
evidence. The graded batch is 36 sessions at three repeats.

- **Run**: 2026-10-31T02:55:49Z – 03:01:10Z (local 15:55 – 16:01, one session
  per cell, no replacements)
- **Plan**: `order_seed=20261027`, `shuffle_seed=90613245`,
  `sha256=6ac712a95506521723a62db35bd86cc0559c9eae61b738e02107b55f3fd452be`,
  **12 rows** — the one-repeat plan
- **Engine**: `84f97472ec3eb4ffe2f277aec303f1e58aac7e2d`; **seed**:
  `16b3cf74c809c23dd48466da2212bd3e67a530ed`; **CLI**: `command-code` 1.88.0;
  **model**: `deepseek/deepseek-v4.1-flash`
- **Measured**: 1,697,538 `tokens_total` across 12 sessions, 292 s of session
  wall clock (maximum 40 s), **$0.03** actual `transcript_cost_usd`
- **Packets**: 12 diffs and 12 verification files in `grading/`, blind ids
  `B001`–`B012`

## Why it ran at one repeat

`--repeats` defaults to `1` in `benchmarks/run-ab-benchmark.sh`, and the
protocol's own Appendix D preflight records pin a 12-row plan digest
(`6ac712a9…`). A 12-row plan *is* a one-repeat plan, so the recording agreed with
the omission and nothing flagged it. §2 and §9 specify three repeats, which is a
36-row plan (`e3727d97…`). The protocol's repeat-count correction records the
discrepancy; the graded batch re-runs the full design.

## Records that predate the rename

This directory was written as `2026-10-31-phase3b-deepseek-v4.1-flash` and
renamed on relabel. `manifest.tsv` embeds absolute paths under the old name; its
contents are otherwise untouched and the files it names moved with the
directory. Read those prefixes as this path. The `record.json` files carry no
paths and are unaffected by the rename.

The blind key lives outside the repository at
`/home/heyloey/.local/state/promptkit/phase3b-keys/phase3b-calibration-1repeat.csv`
(mode 600, sha256 `8b3345e2…`, 12 rows). It was renamed from `phase3b-batch.csv`
at relabel and is never applied to the graded batch.

## Published packet

`runs/<scenario>/` carries the per-run `record.json`, `run.stripped.diff`,
`verify.txt`, `session.log`, `extract.log`, and `strip.log`; the full diff and
install log are at `runs/<scenario>-run.diff` and `runs/<scenario>-init.log`.
Every `record.json` carries `accepted=false` and no `grading` block because no
`--finalize` ran. That is the pre-grading default, not a result. The run clones
and raw transcripts are not published.
