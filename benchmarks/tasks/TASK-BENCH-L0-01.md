# Task Spec: Record the ceremony-artifact overhead gap

<!-- Real backlog slice from issue #607: docs/BENCHMARKS.md has no
     ceremony-overhead row even though the task-record, checkpoint, and
     handoff artifacts are large. This L0 task records the gap honestly
     instead of inventing a measurement; the live per-level profiling in
     #607 remains out of scope. -->

- **Task ID**: `BENCH-L0-01`
- **Level**: `L0`
- **Seed Repository**: `promptkit-os (this repository; operator supplies --seed)`
- **Prompt**: `"In docs/BENCHMARKS.md, add a short Ceremony artifact overhead subsection that records that per-level ceremony artifact overhead is not yet measured. Name the execution task record template, the execution checkpoint template, and the execution handoff template. Link to https://github.com/lowqualityloey/promptkit-os/issues/607. Do not publish any numeric size or token figure for ceremony artifacts. Keep every existing measured figure, table, and provenance anchor unchanged. Do not edit workflows, protocols, templates, scripts, or CHANGELOG.md. Do not edit any other file. Run bash scripts/validate-references.sh . --strict and make it pass."`
- **Setup**: `None`
- **Verify**: `bash scripts/validate-references.sh . --strict`

## Rubric

- [ ] `R1`: `docs/BENCHMARKS.md` contains a new subsection or table block labeled `Ceremony artifact overhead` (case-insensitive).
- [ ] `R2`: It states that per-level ceremony artifact overhead is not yet measured (for example `not measured`), and it publishes no numeric size or token figure for ceremony artifacts.
- [ ] `R3`: It names `templates/execution-task-record-template.md`, `templates/execution-checkpoint-template.md`, and `templates/execution-handoff-template.md` (paths or filenames).
- [ ] `R4`: It links to `https://github.com/lowqualityloey/promptkit-os/issues/607`.
- [ ] `R5`: Existing measured figures, tables, and the `Current measurements` provenance anchor are unchanged; only `docs/BENCHMARKS.md` is modified.
- [ ] `R6`: The verify packet shows `verify_exit=0` with the reference validator passing.

## Notes

- Source issue: #607 (`perf(governance): measure ceremony and artifact overhead by task level`).
- The task deliberately records the absence of measurement; it must not
  manufacture a per-level number from file sizes or estimates.
- The three artifacts are the execution task record, execution checkpoint, and
  execution handoff templates under `templates/`.
