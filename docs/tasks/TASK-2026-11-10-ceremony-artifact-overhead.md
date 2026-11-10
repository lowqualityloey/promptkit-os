# Task Record: Measure ceremony artifact overhead by task level

<a id="TASK-2026-11-10-ceremony-artifact-overhead"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-10-ceremony-artifact-overhead`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Code Work`
- **Specification**: `N/A` — no specification document; acceptance criteria derive from issue #607
- **External Reference (Optional)**: https://github.com/lowqualityloey/promptkit-os/issues/607 `perf(governance): ceremony overhead is unmeasured`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: Repository `promptkit-os` — `scripts/measure-ceremony-overhead.sh` (new), `docs/BENCHMARKS.md`, `.github/workflows/ci.yml`, `CHANGELOG.md`, `docs/STATE.md`
- **Approval Boundary**: Commit, push, PR creation, release, deployment, and closing #607 each require explicit human confirmation. This record authorizes none of them.
- **Created**: `2026-11-10 22:35 UTC`

## 2. Objective and Boundaries

- **Objective**: Publish a deterministic, CI-gated measurement of the mandatory ceremony template load for Levels 0–3, so the cost of entering controlled work is a recorded number rather than an assumption.
- **In Scope**:
  - `scripts/measure-ceremony-overhead.sh` (new) — per-artifact lines, per-level totals, a provenance line, explicit `not measured` lines, and a `--strict` baseline gate. Only shipped templates are read; no template, workflow, or protocol file is modified.
  - `docs/BENCHMARKS.md` — one new subsection stating the figures, provenance, and the "what this does not measure" boundary.
  - `.github/workflows/ci.yml` — one strict-gate step and one `bash -n` line.
  - `CHANGELOG.md` — one Unreleased / Added entry.
  - `docs/STATE.md` — section 3A projection updated to this record.
  - `docs/tasks/TASK-2026-11-10-ceremony-artifact-overhead.md` — this record.
- **Explicit Non-Goals**:
  - Live per-level execution telemetry (tool calls, elapsed time, model identity, human interventions, revision cycles). This repository captures no host telemetry; those fields are reported as `not measured`.
  - Representative multi-run profiling of real L0–L3 tasks; no such runs were executed and none are claimed.
  - Any behavioral enforcement: these figures are evidence for planning, not a gate on agent behavior.
- **Dependencies**: `None` — the work reads existing templates and adds no runtime dependency.
- **Risk**: `Low` — the artifacts are a read-only script, documentation, and a CI step; the only failure mode that matters is a wrong number, mitigated by deriving membership from policy and re-deriving bytes independently of the script.
- **Verification Condition**: `bash scripts/measure-ceremony-overhead.sh --strict` exits 0 with `CEREMONY_GATE|PASS`; `bash scripts/validate-references.sh .` reports no broken links; `bash scripts/measure-tokens.sh --strict` passes; `bash scripts/check-doctor.sh .` exits 0.

## 3. Acceptance Criteria

- [x] **AC-1** — Every level's mandatory artifact set is derived from shipped policy (`workflows/route.md`, `workflows/checkpoint.md`, `workflows/ship.md`), with the citation recorded next to the set.
- [x] **AC-2** — The script prints a provenance line naming the source revision and the token convention, so a reader can reproduce the figures.
- [x] **AC-3** — `--strict` fails when a required per-level total diverges from the recorded baseline.
- [x] **AC-4** — CI runs the strict gate and `bash -n` covers the new script.
- [x] **AC-5** — `docs/BENCHMARKS.md` states the figures, their provenance, and an explicit "what this does not measure" boundary.
- [ ] **AC-6** — Live L0–L3 profiling at three or more runs per level. **Not met and not claimed**; it remains an open criterion on #607 because no host telemetry exists here.

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
  - The artifact is measurement glue over shipped templates, so the failure mode is a wrong figure rather than a wrong branch. Mitigation instead: bytes were summed per artifact and tokens recomputed independently against the repository convention `floor((bytes after CR stripping + 2) / 4)` before the baselines were pinned, plus `bash -n`, `shellcheck -S warning`, and the strict gate. Recorded here as a trade-off, not as test-first discipline.
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `N/A - no external-harness commit authorized by this record`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval or context, failed verification, blocker, hard checkpoint, or developer interrupt`
- **Host Timer Capability**: `No live host timer and no forced termination: elapsed time is not mechanically observable or enforced in this session, so soft and hard checkpoints are advisory and rely on the agent reporting them`

## 5. State and Active Ownership

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-10 22:36 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Owner reviews the diff; then commit on feat/607-ceremony-overhead with the milestone trailer and comment the partial result on #607`

### Transition History

| Previous State | New State | Recorded By and Timestamp |
| :--- | :--- | :--- |
| N/A | planned | lead, 2026-11-10 22:35 UTC |
| planned | in_progress | lead, 2026-11-10 22:36 UTC |
| in_progress | awaiting_review | lead, 2026-11-10 23:10 UTC |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/measure-ceremony-overhead.sh` (new, executable)
  - `docs/BENCHMARKS.md` (new subsection in section 2)
  - `.github/workflows/ci.yml` (one strict-gate step, one `bash -n` line)
  - `CHANGELOG.md` (Unreleased / Added entry)
  - `docs/STATE.md` (section 3A projection points at this record)
  - `docs/tasks/TASK-2026-11-10-ceremony-artifact-overhead.md` (this record)
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**:
  - `bash scripts/measure-ceremony-overhead.sh --strict` → exit 0; `CEREMONY_BASELINE|L1|3021|3021|PASS`, `CEREMONY_BASELINE|L2|8660|8660|PASS`, `CEREMONY_BASELINE|L3|16479|16479|PASS`, `CEREMONY_GATE|PASS`; `CEREMONY_BASELINE|L0|0|unrecorded|SKIP` (Level 0 has no artifact to baseline).
  - `bash scripts/validate-references.sh .` → exit 0, "All references valid! No broken links found."
  - `bash scripts/measure-tokens.sh --strict` → exit 0, Balanced and Lite budgets pass.
  - `bash scripts/check-doctor.sh .` → exit 0.
  - `bash -n scripts/measure-ceremony-overhead.sh` → exit 0; `shellcheck -S warning` → no findings.
  - Measured figures at `471ebc7`, 2026-11-10, profile `balanced`: L0 0 B / 0 tok; L1 12,084 B / 3,021 tok; L2 34,641 B / 8,660 tok; L3 65,917 B / 16,479 tok. Optional and measured separately: L1 checkpoint 827 tok; L2 handoff 978 tok and scope-change 782 tok; L3 CI triage 1,603 tok.
  - Namespace: `CEREMONY_ARTIFACT|` rather than the bare `CEREMONY|` prefix, which `benchmarks/tasks/TASK-BENCH-L1-02.md` reserves for `scripts/measure-per-task-tokens.sh`.
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `N/A - not pushed; the strict gate runs locally and is wired into .github/workflows/ci.yml for the next CI run`
- **Review Evidence**: `N/A - awaiting owner review`
- **Commit Evidence**: `N/A before commit`
- **Pull Request Evidence**: `N/A before PR`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

### Durable Authorization Checkpoints

- `None created` — no review, PR, or release boundary was authorized or exercised under this record.

### Commit Evidence Entries

- `N/A before commit` — this record is committed together with the work it describes.

### Completion Gate

- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 met (policy citations recorded per level); AC-2 met (CEREMONY_PROVENANCE names sha 471ebc7 and the bytes/4 convention); AC-3 met (--strict compares against pinned baselines); AC-4 met (CI step plus bash -n); AC-5 met (BENCHMARKS section with the "what these figures are not" boundary); AC-6 not met and not claimed (no live profiling)`
- **Changed-File Summary**: `One new script, one new documentation subsection, one CI step, one changelog entry, one STATE projection update, one task record — no shipped template, workflow, or protocol was modified.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Submitted for review by lead, 2026-11-10 23:10 UTC; completion is the owner's decision`
