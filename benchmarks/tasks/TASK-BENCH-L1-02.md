# Task Spec: Measure ceremony-artifact static weight

<!-- Real backlog slice from issue #607: no measure-* script covers the
     ceremony artifacts. This L1 task adds deterministic static sizes to the
     existing per-task measurement utility; live per-level profiling, tool
     calls, and elapsed time remain out of scope. -->

- **Task ID**: `BENCH-L1-02`
- **Level**: `L1`
- **Seed Repository**: `promptkit-os (this repository; operator supplies --seed)`
- **Prompt**: `"Extend scripts/measure-per-task-tokens.sh and scripts/measure-per-task-tokens.ps1 with a Ceremony Artifacts section. Measure templates/execution-task-record-template.md as task-record, templates/execution-checkpoint-template.md as checkpoint, and templates/execution-handoff-template.md as handoff using the existing bytes/4 convention. Print one machine line per artifact in this exact form: CEREMONY|task-record|<bytes>|<tokens>, then CEREMONY|checkpoint|<bytes>|<tokens>, then CEREMONY|handoff|<bytes>|<tokens>, where bytes is the CR-stripped byte count and tokens is floor((bytes + 2) / 4). Keep every existing output line, payload, baseline, and strict-gate result unchanged. Update both script headers to mention the new section. Do not edit any other file. This is the static-measurement slice of issue 607; do not run live per-level profiling. Verify the Bash script with bash scripts/measure-per-task-tokens.sh --strict and the PowerShell twin with /usr/bin/pwsh -NoProfile -File ./scripts/measure-per-task-tokens.ps1 -Strict."`
- **Setup**: `None`
- **Verify**: `bash scripts/measure-per-task-tokens.sh --strict && /usr/bin/pwsh -NoProfile -File ./scripts/measure-per-task-tokens.ps1 -Strict`

## Rubric

- [ ] `R1`: Both `scripts/measure-per-task-tokens.sh` and `scripts/measure-per-task-tokens.ps1` reference the three ceremony template paths and emit a `CEREMONY|` machine line for each of `task-record`, `checkpoint`, and `handoff`.
- [ ] `R2`: In the Bash verify output, each `CEREMONY|` line's `bytes` equals the CR-stripped byte count of the named file and its `tokens` equals `floor((bytes + 2) / 4)`, for all three artifacts.
- [ ] `R3`: The PowerShell verify output contains the same three `CEREMONY|` lines with identical bytes and tokens (twin parity).
- [ ] `R4`: All pre-existing `BASELINE|` lines and their PASS/FAIL values are unchanged, and both strict commands exit 0.
- [ ] `R5`: Only the two measurement scripts are modified (including their headers); no measured input, baseline constant, or unrelated file changes.

## Notes

- Source issue: #607 (`perf(governance): measure ceremony and artifact overhead by task level`).
- This is a static `bytes/4` measurement, not a live per-task profile; the
  issue's representative L0-L3 live runs remain a separate deliverable.
- `bytes` must use the same CR-stripped convention already implemented by the
  two scripts; `tokens` must use their existing `(bytes + 2) / 4` floor rule.
