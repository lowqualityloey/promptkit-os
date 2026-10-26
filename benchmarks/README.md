# PromptKit OS A/B Benchmark Harness

Paired-run benchmarking of PromptKit OS against bare Command Code, implementing the
Dual-Condition Evaluation Protocol in [`docs/BENCHMARK-METHODOLOGY.md`](../docs/BENCHMARK-METHODOLOGY.md)
§4 with the CPAC telemetry pipeline (`scripts/measure-cpac.sh` +
`scripts/extract-commandcode-telemetry.sh`). The harness exists to turn the methodology's
claims into measured evidence. A published batch is a directional measurement under its
recorded limitations; the harness itself makes no general performance claim.

## Published batches

- [2026-10-26 Phase 3 live batch](runs/2026-10-26-phase3-deepseek-v4.1-flash/README.md) —
  three real backlog tasks (L0/L1/L2) × two arms × one repeat on
  `deepseek/deepseek-v4.1-flash`; all six runs accepted, with higher token/CPAC
  means for the PromptKit arm and both L2 sessions at the 900-second cap. Read the
  batch report before reusing any number from it.

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
     `init.sh --balanced --host=agents` from the pinned engine checkout; arm `bare` receives
     no PromptKit installation. Neither arm is a vanilla CLI: every clone carries the
     seed's checked-in instruction files, and host-level `~/.commandcode` instruction,
     skill, and hook surfaces may apply to both. See Limitations.
3. **Taste freeze**: `~/.commandcode/taste/taste.md` is snapshotted before the batch and
   asserted empty between arms; the driver warns and stops if taste accumulated (learning
   during a batch would make arms unequal).

   Instruction surfaces are not yet frozen by the driver. A fresh clone still carries the
   seed's `AGENTS.md`, and Command Code can load host-level instruction/skill/hook
   configuration; both arms inherit those surfaces. Future batches must snapshot or
   neutralize them alongside `taste.md` and record what remains. The Phase 3 batch did not;
   its report records the resulting `heyloey` hook confound.
4. **Telemetry**: headless sessions persist to `~/.commandcode/projects/<slug>/` and record
   per-message usage exactly like interactive sessions (verified on this host), so the §5
   record is extracted mechanically per run (`accepted=false` at extraction — acceptance is
   a human judgment).
5. **Blind grading**: per run, the diff is stripped of PromptKit artifacts
   (`scripts/strip-benchmark-diff.sh`) and assigned a blind id (`B<nnn>`) by a
   shuffle across the whole batch (reproducible with `BENCH_SHUFFLE_SEED`), so
   id order carries no arm information; when the task declares a `Verify`
   command, the harness itself runs it post-session and ships path-scrubbed
   output as `B<nnn>.verify.txt` with the command's exit code recorded on its
   first line (`verify_exit=`). The harness replaces the run directory, output
   root, and scenario id with `<rundir>`, `<out>`, and `<scenario>` before
   writing the packet, so a Verify command that prints its cwd cannot leak the
   arm. The grader never needs the arm-revealing session log for evidence-gated
   rubric items, and a successful-but-silent command still yields gradeable
   evidence. The blind→scenario mapping lives in `grading/key.csv` and is never
   printed to the terminal; the grader scores `B*.diff` (+ `B*.verify.txt`)
   against the task's frozen rubric without seeing it, and writes the sheet keyed
   by blind id: `blind_id <TAB> rubric_passed <TAB> rubric_total <TAB>
   accepted`. The mapping is withheld during grading, not secret after
   publication: published per-scenario stripped diffs are byte-identical to the
   blind packets, so a reader can recover it by content matching. Do not claim
   otherwise.
6. **Acceptance and aggregation**: after grading, `--finalize` translates the
   blind-id sheet via the key, re-extracts each run's §5 record with its graded
   `accepted` flag, and runs `scripts/aggregate-benchmark-runs.sh` with the
   translated scenario-keyed sheet as a fail-closed cross-check (a mismatch or
   a record missing from the sheet exits 2) — emitting the per-arm summary
   (`BENCH|SUMMARY|...`, including `graded_n`).

Diff capture is anchored to the **seed commit SHA** recorded before each run:
under `--yolo` the agent may `git commit`, and a plain `git diff --cached`
against the moved HEAD would silently return an empty diff. A run that
produced no changes (e.g. `--max-turns` hit) still gets an empty grading
packet and is graded `accepted=false` — it never aborts the batch.

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
Grading is single-reviewer scoring against rubrics frozen before the runs. Blinding is
only as strong as the packets: a Verify command that echoes an arm-bearing path leaks it
unless scrubbed. The driver now scrubs run/output/scenario paths, but a published batch
must disclose any leak that occurred before the scrub rather than claiming arm-blinded
independence. Reviewer bias is mitigated only by packet discipline and rubric
specificity. The rework-loop count is the documented heuristic (no tool exit codes in
schema v3). A published batch is directional evidence under its recorded limitations;
this harness does not establish general performance.

## Usage

```bash
# Validate the environment without spending
bash benchmarks/run-ab-benchmark.sh --engine /path/to/promptkit-os \
  --seed /path/to/seed-repo --tasks benchmarks/tasks/TASK-BENCH-L1-01.md \
  --model <model> --out /tmp/bench-batch-1 --preflight-only

# Run a batch (spends the plan)
bash benchmarks/run-ab-benchmark.sh --engine ... --seed ... --tasks a.md,b.md \
  --model <model> --out /tmp/bench-batch-1

# After grading B*.diff (+ B*.verify.txt) into grading/grading.tsv
# (blind_id <TAB> rubric_passed <TAB> rubric_total <TAB> accepted):
bash benchmarks/run-ab-benchmark.sh --finalize /tmp/bench-batch-1 \
  --grading /tmp/bench-batch-1/grading/grading.tsv
```

The run and finalize paths are regression-tested in CI against a stub CLI with
an isolated HOME (`scripts/tests/run-benchmark-driver-tests.sh`) — see that
harness for the exact observable contract the driver depends on.
