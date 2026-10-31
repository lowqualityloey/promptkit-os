# Phase 3c batch — pre-registration

Written and committed to disk **before the first session**. Everything below the
line is fixed; the measurements that follow the run live in `README.md` and
`env.txt`, and nothing here is adjusted after seeing a result.

## The seeds, and why these numbers

`benchmarks/PHASE-3C-DESIGN.md` §6 requires two pre-registered numeric seeds and
leaves their *values* to batch time, recorded in `env.txt`/`isolation.txt`. To
avoid picking a number that happens to look favourable, they are derived from
the batch label rather than chosen:

```
order_seed   = 0x 74dbd7ac  (sha256("phase3c-batch|order")[0:8])   mod 1e8 = 60564652
shuffle_seed = 0x b2dbfa15  (sha256("phase3c-batch|shuffle")[0:8]) mod 1e8 = 760853
```

Anyone can re-derive them from the label with `sha256sum` and `printf`, and
neither shares a value with any earlier run (`20261027/90613245` in 3b,
`20261031/48392761` in the 3c calibration), so no plan or blind key can be
reused by accident.

## The frozen invocation

| Item | Value |
|---|---|
| Slate | `benchmarks/tasks/TASK-P3C-01.md` … `TASK-P3C-10.md` (10 cards) |
| Arms | `promptkit_os`, `bare` |
| Repeats per cell | 3 |
| Primary sessions | **60** |
| `order_seed` | `60564652` |
| `shuffle_seed` | `760853` |
| Plan SHA-256 | `b08718167f9ba691f528cedb504c5fc68bd35d9a727b50307bde21a041003722` |
| Plan rows | 60 (`order.tsv`) |
| Seed | `b0ef652d91b20c57965eb4257cab93301ff68999`, rebuilt from `benchmarks/seed/build-phase3c-seed.sh` for this batch (27 files, clean, 65/65 tests) |
| Engine | `84f97472ec3eb4ffe2f277aec303f1e58aac7e2d` (working tree carries the uncommitted Phase 3c work) |
| Model | `deepseek/deepseek-v4.1-flash` |
| CLI | `command-code` 1.88.0 |
| `--max-turns` | 40 |
| `--timeout` | 1,800 s |
| `--profile` | `balanced` |
| Isolation | fresh `HOME` holding only `.commandcode/auth.json`; no instruction surface, no MCP, no hooks, no `heyloey` on `PATH` |
| Blind key | outside the repository: `~/.local/state/promptkit/phase3c-keys/phase3c-batch-1.csv` |

## Caps and the no-extra-runs rule

- Primary sessions: 60. Infrastructure replacements: up to 10. Total ceiling: **76**.
- Wall-clock ceiling: **30 hours**. Abort threshold on `transcript_cost_usd`: **$40**.
- A timeout or a max-turns stop is recorded as such, stays in the ITT denominator,
  and is **not** re-run because its result was disappointing.

## What this batch is for

Acceptance is the primary endpoint, because 36 of 36 sessions passed in Phase 3b
and a constant is not a measurement. This batch is **not graded by this run**: the
design (§7) requires a human primary grader who did not run it, plus a second
grader sampling at least 50% of packets, and the key stays sealed until then.
The run's job is to produce 60 graded-format packets, the telemetry, and a batch
that is honest about its own failures.
