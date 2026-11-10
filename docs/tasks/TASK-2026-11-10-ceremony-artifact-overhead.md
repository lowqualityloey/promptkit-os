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
- **Execution Scope**: Repository `promptkit-os` — `scripts/measure-ceremony-overhead.sh` (new), `docs/BENCHMARKS.md`, `.github/workflows/ci.yml`, `CHANGELOG.md`, `docs/STATE.md` (plus the rework after external review, which changed the same files and added no new one)
- **Approval Boundary**: Commit, push, PR creation, release, deployment, and closing #607 each require explicit human confirmation. This record authorizes none of them.
- **Created**: `2026-11-10 22:35 UTC`

## 2. Objective and Boundaries

- **Objective**: Publish a deterministic, CI-gated measurement of the mandatory ceremony template load for Levels 0–3, so the cost of entering controlled work is a recorded number rather than an assumption.
- **In Scope**:
  - `scripts/measure-ceremony-overhead.sh` (new) — per-artifact lines, per-level totals, a shared-setup total, a specification band, policy-anchor assertions, a provenance line, explicit `not measured` lines, and a `--strict` equality gate. Only shipped templates are read; no template, workflow, or protocol file is modified.
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
- **Risk**: `Low` — the artifacts are a read-only script, documentation, and a CI step; the only failure mode that matters is a wrong number. Mitigations: membership is re-derived from policy and bytes are re-derived independently of the script; an equality gate makes any template drift (growth or reduction) fail loudly; five `CEREMONY_ANCHOR|` assertions fail the run if the governing policy sentences are rewritten, so a stale curated list cannot stay green.
- **Verification Condition**: `bash scripts/measure-ceremony-overhead.sh --strict` exits 0 with `CEREMONY_GATE|PASS`; `bash scripts/validate-references.sh .` reports no broken links; `bash scripts/measure-tokens.sh --strict` passes; `bash scripts/check-doctor.sh .` exits 0.

## 3. Acceptance Criteria

- [x] **AC-1** — Every level's mandatory artifact set is derived from shipped policy (`workflows/route.md`, `workflows/checkpoint.md`, `workflows/ship.md`), with the citation recorded next to the set.
- [x] **AC-2** — The script prints a provenance line naming the source revision and the token convention, so a reader can reproduce the figures.
- [x] **AC-3** — `--strict` fails when a measured total diverges *in either direction* from the recorded baseline (equality, not a growth bound), so a reduced mandatory template fails the same gate as a grown one.
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
- **Next Action**: `Review the rework commit on feat/607-ceremony-overhead (push updates PR #731); #607 stays open on AC-6`

### Transition History

| Previous State | New State | Recorded By and Timestamp |
| :--- | :--- | :--- |
| N/A | planned | lead, 2026-11-10 22:35 UTC |
| planned | in_progress | lead, 2026-11-10 22:36 UTC |
| in_progress | awaiting_review | lead, 2026-11-10 23:10 UTC |
| awaiting_review | in_progress | lead, 2026-11-10 23:30 UTC (external review: four requested changes) |
| in_progress | awaiting_review | lead, 2026-11-10 23:55 UTC (rework landed) |

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
  - `bash scripts/measure-ceremony-overhead.sh --strict` → exit 0 with `CEREMONY_BASELINE|L0|0|0|PASS`, `|L1|0|0|PASS`, `|L2|11119|11119|PASS`, `|L3|18938|18938|PASS`, `|SETUP|3021|3021|PASS`, `CEREMONY_GATE|PASS`. The earlier `L0|0|unrecorded|SKIP` row is gone: equality compares zero to zero cleanly.
  - Gate discriminates in both directions (scratch copy at `/tmp/pk-ceremony-test`, repository tree untouched): pristine copy PASS; shrinking `templates/tech-spec-template.md` reports `CEREMONY_BASELINE|L2|8139|11119|FAIL` and exit 1, which the previous growth-only comparison accepted; restoring it returns PASS.
  - Policy-drift probe in the same scratch copy: rewording `formal specification` in `workflows/route.md` exits 2 with `CEREMONY_ANCHOR|workflows/route.md|MISSING` and `ANCHOR_ERROR|POLICY_DRIFT|workflows/route.md no longer contains: formal specification`, so the curated list cannot silently outlive the policy it cites.
  - `bash scripts/validate-references.sh .` → exit 0, "All references valid! No broken links found."
  - `bash scripts/measure-tokens.sh --strict` → exit 0, Balanced and Lite budgets pass.
  - `bash scripts/check-doctor.sh .` → exit 1 with a single failing row, `version DIVERGED` ("engine v2.1.0-6-ga300e85 diverged from refs/remotes/origin/main"). That row is expected on this branch: the check tests whether HEAD is an ancestor of the upstream ref, and HEAD carries this task's commit. The base commit is current (`git merge-base --is-ancestor 471ebc7 refs/remotes/origin/main` → 0), so the row returns to OK once the branch merges. Every other row is OK or an expected SKIP/IGNORED, including `host:AGENTS.md OK` and `docs-drift OK` (projection agrees with this record).
  - `bash -n scripts/measure-ceremony-overhead.sh` → exit 0; `shellcheck -S warning` → no findings.
  - Per-task figures (profile `balanced`): L0 0 B / 0 tok; L1 0 B / **0 tok**; L2 44,478 B / **11,119 tok**; L3 75,754 B / **18,938 tok**; shared one-time setup `templates/state-tracker-template.md` 12,084 B / **3,021 tok**, counted once (`CEREMONY_SHARED_SETUP|files=1|bytes=12084|tokens=3021|amortisation=once-per-project`). Specification band `CEREMONY_SPEC_BAND|L2|6618|11119|pinned=templates/tech-spec-template.md`. Optional and measured separately: L1 checkpoint 827 tok; L2 handoff 978 tok and scope-change 782 tok; L3 CI triage 1,603 tok and QA review checklist 1,534 tok. These supersede the first published 0 / 3,021 / 8,660 / 16,479, which double-counted the shared tracker at every level and omitted the Level 2 specification family.
  - Namespace: `CEREMONY_ARTIFACT|` and its siblings (`CEREMONY_ANCHOR|`, `CEREMONY_SHARED_SETUP|`, `CEREMONY_SPEC_BAND|`, `CEREMONY_TOTAL|`, `CEREMONY_BASELINE|`, `CEREMONY_PROVENANCE|`) rather than the bare `CEREMONY|` prefix, which `benchmarks/tasks/TASK-BENCH-L1-02.md` reserves for `scripts/measure-per-task-tokens.sh`.
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `PR #731 run 42797339041 passed 12/12 (4m57s) for the pre-rework commit e8f8033, including the ceremony strict step; the rework commit's CI run is the next observation, and the local gates above are recorded meanwhile`
- **Review Evidence**: `External review (arena.ai, 2026-11-10) requested four changes, all upheld: (1) per-task artifacts were conflated with the shared tracker and the Level 2 formal specification was missing; (2) template size was mislabeled as per-task cost and as a static ceiling; (3) artifact membership was hard-coded with no policy-consistency check; (4) --strict was growth-only, so a reduced template passed (L2 8,660 -> 6,348) and Level 0 was skipped. Fixes: units split and published separately, the specification family measured against a pinned baseline with a published band, five policy anchors asserted with a loud failure mode, and the gate converted to equality with Level 0 compared rather than skipped. Owner review of the rework is the open step.`
- **Commit Evidence**: `Pending at record-write time: the rework lands as a second commit on feat/607-ceremony-overhead, and this record is committed with it`
- **Pull Request Evidence**: `PR #731 (open) — the rework commit is pushed to the same branch, updating the PR rather than opening a second one`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

### Durable Authorization Checkpoints

- `None created` — no review, PR, or release boundary was authorized or exercised under this record.

### Commit Evidence Entries

- `N/A before commit` — this record is committed together with the work it describes.

### Completion Gate

- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 met (each level's set cites its policy line; membership documented as curated; the five cited sentences are asserted at run time, and the drift probe above proves the failure path); AC-2 met (CEREMONY_PROVENANCE names the revision, the bytes/4 convention, the two units, and the curated selection); AC-3 met (--strict asserts equality, fails on growth and on reduction, and no longer skips Level 0); AC-4 met (CI step plus bash -n); AC-5 met (BENCHMARKS section restates every figure, the units, the specification band, the equality semantics, and the what-these-figures-are-not boundary); AC-6 not met and not claimed (no live profiling)`
- **Changed-File Summary**: `One new script, one new documentation subsection, one CI step, one changelog entry, one STATE projection update, one task record — no shipped template, workflow, or protocol was modified by the rework either; the review findings were fixed inside the same file set.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Submitted for review by lead, 2026-11-10 23:10 UTC; reworked after external review and resubmitted, 2026-11-10 23:55 UTC; completion is the owner's decision`
