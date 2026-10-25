# PromptKit OS A/B Benchmark Harness

Paired-run benchmarking of PromptKit OS against bare Command Code, implementing the
Dual-Condition Evaluation Protocol in [`docs/BENCHMARK-METHODOLOGY.md`](../docs/BENCHMARK-METHODOLOGY.md)
§4 with the CPAC telemetry pipeline (`scripts/measure-cpac.sh` +
`scripts/extract-commandcode-telemetry.sh`). The harness exists to turn the methodology's
claims into measured evidence; until runs are executed and published, no performance claim
is made here.

## Protocol (what the driver enforces)

For every task × arm × repeat:

1. **Fresh seed**: a clean `git clone` of the seed repository into the run directory. No
   state carries between runs.
2. **Arm parity** (both arms get identical treatment except the directive):
   - `command-code -t --yolo --tools-all --skip-onboarding --no-auto-update -m <model>
     --max-turns <n> -p "<verbatim task prompt>"`, run with cwd = the run directory.
   - Same model (`-m`), same permission mode (`--yolo`), same tool surface (`--tools-all`,
     because `-p` mode withholds tools by default), same turn cap (`--max-turns`), same
     timeout, same prompt text byte-for-byte (`benchmarks/tasks/*.md` is the single source).
   - `--skip-onboarding` prevents taste onboarding from differentiating the arms.
   - Arm `promptkit_os` additionally installs the directive via the engine's
     `init.sh --balanced --host=agents` from the pinned engine checkout; arm `bare` stays
     untouched.
3. **Taste freeze**: `~/.commandcode/taste/taste.md` is snapshotted before the batch and
   asserted empty between arms; the driver warns and stops if taste accumulated (learning
   during a batch would make arms unequal).
4. **Telemetry**: headless sessions persist to `~/.commandcode/projects/<slug>/` and record
   per-message usage exactly like interactive sessions (verified on this host), so the §5
   record is extracted mechanically per run (`accepted=false` at extraction — acceptance is
   a human judgment).
5. **Blind grading**: per task, each arm's diff is stripped of PromptKit artifacts
   (`scripts/strip-benchmark-diff.sh`) and assigned a random blind id (`B<nnn>`); the
   grader scores the stripped diffs against the task's frozen rubric without seeing the
   arm mapping (the key is written to `grading/key.csv` and not consulted until grading is
   complete).
6. **Acceptance and aggregation**: after grading, each run is re-extracted with
   `--accepted` set from the grading sheet, and `scripts/aggregate-benchmark-runs.sh`
   cross-checks the grading TSV against the records (mismatch exits 2) and emits the
   per-arm summary (`BENCH|SUMMARY|...`).

## Raw-data policy

Raw Command Code transcripts record real code and stay on the operator's machine
(`~/.commandcode/`); they are **never committed**. `benchmarks/runs/<batch>/` publishes
only: §5 telemetry records (numeric aggregates), full and stripped diffs, run logs, the
grading sheet, and the manifest. Diffs for tasks against private code are published only
at the operator's discretion — the driver writes them to the run directory, not to the
repository, until `--publish` copies a batch into `benchmarks/runs/`.

## Operator-local by design

`run-ab-benchmark.sh` drives a live, subscription-backed CLI (Command Code) and is
therefore not exercised by CI and has no PowerShell twin: the repository's twin-parity
rule binds repository behavior surfaces, while this script is the operator's benchmark
instrument. Every pure, reusable piece it calls (stripper, aggregator, extractor, scorer)
is a twin-tested script under `scripts/` with fixture harnesses. The driver targets
Linux/WSL (uses GNU `timeout`).

## Spend control

Each run consumes the operator's Command Code plan. Controls: `--max-turns` (default 40,
exit 8 on cap-hit), a wall-clock `timeout` per run (default 900s), and the task batch
itself is reviewed before any run. The driver refuses to start without an explicit
`--model`, and `--preflight-only` validates the environment (CLI, model, taste state,
engine and seed repos) without spending.

## Limitations

Small n, one operator, one host, one model per batch: results are directional evidence
under the stated conventions (see `docs/BENCHMARK-METHODOLOGY.md` §5.A), not proof.
Grading is single-reviewer blind scoring against rubrics frozen before the runs; reviewer
bias is mitigated only by blinding and rubric specificity. The rework-loop count is the
documented heuristic (no tool exit codes in schema v3). Until a batch is published under
`benchmarks/runs/`, this framework demonstrates mechanics, not outcomes.

## Usage

```bash
# Validate the environment without spending
bash benchmarks/run-ab-benchmark.sh --engine /path/to/promptkit-os \
  --seed /path/to/seed-repo --tasks benchmarks/tasks/TASK-BENCH-L1-01.md \
  --model <model> --out /tmp/bench-batch-1 --preflight-only

# Run a batch (spends the plan)
bash benchmarks/run-ab-benchmark.sh --engine ... --seed ... --tasks a.md,b.md \
  --model <model> --out /tmp/bench-batch-1
```

Post-grading finalization and aggregation are documented in the README section the driver
prints at the end of a batch.
