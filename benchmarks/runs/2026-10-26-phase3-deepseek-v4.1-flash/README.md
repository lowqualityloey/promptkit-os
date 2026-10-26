# Phase 3 Live A/B Batch — `deepseek/deepseek-v4.1-flash`

First live batch of the dual-condition protocol in
[`docs/BENCHMARK-METHODOLOGY.md`](../../../docs/BENCHMARK-METHODOLOGY.md) §4,
run through the harness in [`benchmarks/README.md`](../../README.md). This is the
Phase 3 deliverable for issue
[#694](https://github.com/lowqualityloey/promptkit-os/issues/694).

- **Date**: 2026-10-26
- **Model**: `deepseek/deepseek-v4.1-flash`
- **Command Code**: 1.88.0
- **Engine and seed**: `9c8080df3e9e8de9fc60fd2f794eebee3af46428` (both arms)
- **Profile**: `balanced`
- **Batch**: 3 tasks × 2 arms × 1 repeat = 6 sessions
- **Raw data**: transcripts remain local under `~/.commandcode/`; `key.csv` was
  withheld from the grader and is not published. Because the per-scenario
  stripped diffs are published alongside the blind packets, the
  blind-to-scenario mapping is derivable by content matching after the fact.
  The sheet itself was written before the key was consulted.

## Protocol

Each run began from a fresh clone of the seed at the recorded SHA. Both arms used
the same prompt bytes, model, `--yolo --tools-all --max-turns 40`, and 900-second
harness timeout. The `promptkit_os` arm additionally installed the Balanced
directive through `init.sh --balanced --host=agents`; the `bare` arm received no
PromptKit installation. Neither arm was a vanilla CLI: both inherited the
seed's checked-in instruction files and any host-level `~/.commandcode`
surfaces. Taste was frozen empty before the batch.

Per-run diffs were stripped of PromptKit artifacts and shuffled into blind-id
packets (`B001`–`B006`). The harness ran each task's `Verify` command and shipped
path-scrubbed output as `B*.verify.txt` with the exit code on its first line; the
harness replaces the run directory, output root, and scenario id with
`<rundir>`, `<out>`, and `<scenario>`. The sheet was written before `key.csv`
was consulted; `--finalize` then translated it and re-extracted the §5 records
with the graded acceptance flags.

Task specs and frozen rubrics:

| Task | Level | Rubric | Verify |
|---|---|---:|---|
| [`BENCH-L0-01`](../../tasks/TASK-BENCH-L0-01.md) | L0 | 6 items | `bash scripts/validate-references.sh . --strict` |
| [`BENCH-L1-02`](../../tasks/TASK-BENCH-L1-02.md) | L1 | 5 items | measurement twins, strict |
| [`BENCH-L2-02`](../../tasks/TASK-BENCH-L2-02.md) | L2 | 6 items | behavioral-contract twins |

## Correction (2026-10-26 review)

An external review of PR #695 found that the two L0 verify packets echoed their
run directory — and therefore the arm — because `validate-references.sh` prints
absolute scan paths. The pre-correction `B003` and `B006` packets exposed
`BENCH-L0-01-<arm>-r1`; the L0 grading was therefore not fully blind. The
harness now scrubs the run directory, output root, and scenario id before
writing any verify packet, and the driver regression prints its cwd to keep the
old leak failing the suite. The published L0 packets and their run-level
`verify.txt` sources were redacted to `<rundir>`; the pre-redaction text remains
in the PR commit history. Redaction does not retroactively blind the sheet, so
the grading limitation below records the leak rather than claiming it away. A
post-publication blind re-grade of the two affected packets is recorded below;
it confirms their outcomes but does not retroactively blind the original sheet.

## Post-publication blind re-grade (B003/B006)

On 2026-10-26, the two affected L0 packets were re-graded by a fresh, isolated
Codex CLI session (OpenAI; default model for that session), separate from the
batch's DeepSeek runs. The reviewer received, as grading evidence, only the
stripped `B003` and `B006` diffs, their `verify_exit=0` summaries, and the
frozen [`BENCH-L0-01`](../../tasks/TASK-BENCH-L0-01.md) rubric. It was given no
repository path, no `key.csv`, no scenario names, and no batch report; the
session ran in an isolated temporary workspace containing only the prompt,
output schema, and an isolation note, with user config disabled and a read-only
sandbox.

| Packet | Original sheet (partial-blind) | Blind re-grade | Accepted |
|---|---:|---:|---:|
| `B003` | 6/6 | 6/6 | yes |
| `B006` | 6/6 | 6/6 | yes |

Both packets passed `R1`–`R6`: the heading, the "not measured" statement and
absence of a numeric ceremony figure, all three template names, the `#607`
link, the single-file change with existing figures untouched, and
`verify_exit=0` with all references valid. This matches the published
[`grading.tsv`](grading/grading.tsv) rows; no scores changed.

This is a post-publication confirmation of the published diffs, not a rerun of
the original grading. The original L0 grading remains partially unblinded
because its verify packets leaked the arm before the harness fix; the re-grade
does not erase that history or turn the original sheet into an arm-blinded
one. It does establish that a reviewer without the mapping reaches the same
6/6 result on both packets.

## Results

All six runs were accepted against their frozen rubrics. The `promptkit_os` arm
used more tokens and produced a higher CPAC than `bare` on every task in this
batch.

| Task | Arm | Rubric | Accepted | Tokens total | Wall (s) | Rework | CPAC (USD) |
|---|---|---:|---:|---:|---:|---:|---:|
| `BENCH-L0-01` | `bare` | 6/6 | yes | 406,461 | 112 | 1 | 1.3103 |
| `BENCH-L0-01` | `promptkit_os` | 6/6 | yes | 442,815 | 100 | 2 | 1.4772 |
| `BENCH-L1-02` | `bare` | 5/5 | yes | 332,155 | 124 | 2 | 1.1744 |
| `BENCH-L1-02` | `promptkit_os` | 5/5 | yes | 587,027 | 132 | 1 | 1.8942 |
| `BENCH-L2-02` | `bare` | 6/6 | yes | 1,173,665 | 636 | 1 | 3.6965 |
| `BENCH-L2-02` | `promptkit_os` | 6/6 | yes | 3,226,094 | 765 | 2 | 9.9611 |

Per-arm aggregate (`BENCH|SUMMARY` from `finalize.log`):

| Arm | n | Accepted | Accept rate | Tokens mean | Tokens median | Wall mean (s) | Wall median (s) | Rework mean | CPAC mean | CPAC median |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `bare` | 3 | 3 | 1.00 | 637,427.0 | 406,461.0 | 290.7 | 124.0 | 1.33 | 2.0604 | 1.3103 |
| `promptkit_os` | 3 | 3 | 1.00 | 1,418,645.3 | 587,027.0 | 332.3 | 132.0 | 1.67 | 4.4442 | 1.8942 |

`tokens_total` is the extractor's total (successful plus rework turns). CPAC is
computed by `scripts/measure-cpac.sh` under its reference defaults: `$3.00` per
1M input tokens, `$15.00` per 1M output tokens, and `$0.05` per rework loop;
cache-read tokens are reported but not priced in v1. These are reference
constants, not provider billing: the records' `transcript_cost_usd` is
`$0.01`–`$0.04` per session for this model. CPAC is a comparative model, not an
invoice.

## Interpretation

This batch shows **no completion advantage** for the PromptKit arm (both arms
were accepted 3/3) and a **token/CPAC disadvantage on all three tasks**, largest
at L2. The honest reading is narrow: on three small-to-medium tasks against the
PromptKit repository itself, the Balanced directive did not pay for itself in
tokens or modeled cost.

It does not establish that PromptKit is generally less efficient. The batch has
one repeat per cell, one model, one host, and one grader; the tasks are
documentation, measurement-script, and contract-test changes in the same
repository that supplies the engine. That task mix may favor direct edits and
does not represent consumer application code, multi-turn collaboration, or
higher-risk migrations. The result is directional evidence under the stated
conventions, not a statistically supported effect.

## Limitations

- **n is small**: 3 tasks × 2 arms × 1 repeat. No variance estimate, confidence
  interval, or significance test is possible from six sessions; do not rank the
  arms from these means.
- **L2 sessions hit the 900-second harness cap**: both L2 runs recorded
  `cli_exit=124` in `driver.log`, and their `session.log` is `Terminated.`. Their
  artifacts were complete enough to satisfy every rubric item and their verify
  commands exited 0, so they were accepted on artifact evidence; wall-clock
  telemetry (765 s and 636 s) is the transcript span, not proof the session
  finished naturally. L2 wall and CPAC comparisons are therefore the weakest in
  the batch.
- **Original grading was single-reviewer and only partially blind**: the sheet
  was written from `B*.diff` and `B*.verify.txt` before `key.csv` was read, and
  `--finalize` was the first key consultation. However, the two L0 verify
  packets leaked the run directory (and thus the arm) before the harness scrub
  described in Correction; the original L0 grade cannot claim arm-blinded
  independence. No independent re-score was performed at the time. A
  post-publication blind re-grade of the two affected packets later confirmed
  both at 6/6 (see the re-grade section above), but it does not make the
  original sheet blind. The key is withheld as a file but derivable from the
  published stripped diffs after publication.
- **Instruction and hook surfaces were not isolated**: every fresh clone
  carries the seed's checked-in `AGENTS.md`, which instructs the agent to
  dispatch milestone updates through `heyloey`; host-level
  `~/.commandcode` instruction/skill/hook surfaces may also apply to both arms.
  Both L1 sessions invoked `heyloey`. The bare L1 call returned `partial`
  (exit 5) while the PromptKit L1 call logged, so the L1 cell contains an
  asymmetric side effect in addition to shared prompt/tool overhead. `bare`
  here means "no PromptKit installation," not "vanilla Command Code"; this
  batch does not measure a clean CLI baseline.
- **One model/host**: results do not transfer to other Command Code models or
  hosts.
- **Self-referential seed**: the seed is the PromptKit repository at the engine
  SHA. The `promptkit_os` arm's full diff includes directive installation
  artifacts; grade only the stripped packets.

## Artifacts

- [`env.txt`](env.txt) — CLI, engine/seed SHAs, model, profile, date.
- [`manifest.tsv`](manifest.tsv) — scenario/arm/paths. The manifest is
  path-normalized for publication; the `transcript` column is redacted because
  raw transcripts are local-only. The original manifest remains in the local
  batch directory.
- [`driver.log`](driver.log) — preflight, per-run `RUNDONE` lines with
  `cli_exit`, blind ids, batch status.
- [`finalize.log`](finalize.log) — `RUN|` rows and per-arm `BENCH|SUMMARY`.
- [`error-patterns.txt`](error-patterns.txt) — frozen rework-loop pattern list.
- [`grading/grading.tsv`](grading/grading.tsv) — blind-id sheet used by finalize.
- [`grading/`](grading/) — the six stripped `B*.diff` packets and their
  path-scrubbed `B*.verify.txt` evidence.
- `runs/<scenario>/record.json` — final §5 record with the graded acceptance.
- `runs/<scenario>/run.diff` — full seed-SHA diff (includes directive artifacts
  for the `promptkit_os` arm).
- `runs/<scenario>/run.stripped.diff` — the graded, artifact-stripped diff.
- `runs/<scenario>/verify.txt`, `session.log`, `strip.log`, `extract.log` —
  path-scrubbed verification and harness evidence.

Not published as files: `key.csv`, `grading.scenario.tsv` (the key-derived
translation), raw Command Code transcripts, and the full clone directories under
the local batch. The mapping is withheld during grading but derivable from the
published diffs; it is not a post-publication secret. The harness's raw-data
policy is in [`benchmarks/README.md`](../../README.md).

## Reproduction

The published batch was produced by the clean rerun (the first attempt stopped on
the transcript-slug defect fixed in `2811353`):

```bash
bash benchmarks/run-ab-benchmark.sh \
  --engine /path/to/promptkit-os \
  --seed /path/to/promptkit-os \
  --tasks benchmarks/tasks/TASK-BENCH-L0-01.md,benchmarks/tasks/TASK-BENCH-L1-02.md,benchmarks/tasks/TASK-BENCH-L2-02.md \
  --model deepseek/deepseek-v4.1-flash \
  --out /tmp/bench-batch-1-clean \
  --max-turns 40 --timeout 900
```

After grading from the blind-id packets:

```bash
bash benchmarks/run-ab-benchmark.sh \
  --finalize /tmp/bench-batch-1-clean \
  --grading /tmp/bench-batch-1-clean/grading/grading.tsv
```
