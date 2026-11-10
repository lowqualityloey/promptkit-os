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
- **Execution Scope**: Repository `promptkit-os` — `scripts/measure-ceremony-overhead.sh` (new), `scripts/measure-ceremony-overhead.ps1` (new), `docs/BENCHMARKS.md`, `.github/workflows/ci.yml`, `CHANGELOG.md`, `docs/STATE.md` (plus two rework rounds after external review; the second round added the PowerShell twin and no other new file)
- **Approval Boundary**: Commit, push, PR creation, release, deployment, and closing #607 each require explicit human confirmation. This record authorizes none of them.
- **Created**: `2026-11-10 22:35 UTC`

## 2. Objective and Boundaries

- **Objective**: Publish a deterministic, CI-gated measurement of the mandatory ceremony template load for Levels 0–3, so the cost of entering controlled work is a recorded number rather than an assumption.
- **In Scope**:
  - `scripts/measure-ceremony-overhead.sh` (new) — per-artifact lines, per-level totals, a shared-setup total, a specification band, whole-line policy-anchor pins, a provenance line, explicit `not measured` lines, and a `--strict` equality gate over every published figure. Only shipped templates are read; no template, workflow, or protocol file is modified.
  - `scripts/measure-ceremony-overhead.ps1` (new) — the behavioural twin, emitting identical output and verdicts so the gate runs on Windows as well as Linux.
  - `docs/BENCHMARKS.md` — one new subsection stating the figures, provenance, and the "what this does not measure" boundary.
  - `.github/workflows/ci.yml` — a Bash strict-gate step, a PowerShell strict-gate step, a `bash -n` line, and the PowerShell syntax list.
  - `CHANGELOG.md` — one Unreleased / Added entry.
  - `docs/STATE.md` — section 3A projection updated to this record.
  - `docs/tasks/TASK-2026-11-10-ceremony-artifact-overhead.md` — this record.
- **Explicit Non-Goals**:
  - Live per-level execution telemetry (tool calls, elapsed time, model identity, human interventions, revision cycles). This repository captures no host telemetry; those fields are reported as `not measured`.
  - Representative multi-run profiling of real L0–L3 tasks; no such runs were executed and none are claimed.
  - Any behavioral enforcement: these figures are evidence for planning, not a gate on agent behavior.
- **Dependencies**: `None` — the work reads existing templates and adds no runtime dependency.
- **Risk**: `Low` — the artifacts are two read-only scripts, documentation, and CI steps; the only failure mode that matters is a wrong number. Mitigations: membership is re-derived from policy and bytes are re-derived independently of the script; an equality gate pins every published figure, so any template drift (growth or reduction) fails loudly; eight whole-line SHA-256 `CEREMONY_ANCHOR|` pins fail the run when a cited policy sentence is rewritten, so a stale curated list cannot stay green; the Bash and PowerShell scripts are diffed against each other rather than assumed equivalent.
- **Verification Condition**: `bash scripts/measure-ceremony-overhead.sh --strict` exits 0 with `CEREMONY_GATE|PASS`; `pwsh -NoProfile -File ./scripts/measure-ceremony-overhead.ps1 -Strict` exits 0 with byte-identical output; `bash scripts/validate-references.sh .` reports no broken links; `bash scripts/measure-tokens.sh --strict` passes; `bash scripts/validate-execution-control.sh --strict` reports `VALID`; `bash scripts/check-doctor.sh .` reports no unexpected row.

## 3. Acceptance Criteria

- [x] **AC-1** — Every level's mandatory artifact set is derived from shipped policy (`workflows/route.md`, `workflows/checkpoint.md`, `workflows/plan.md`, `workflows/review.md`, `workflows/ship.md`), with the citation recorded next to the set, the Level 2 planning depth split into the Minimal default and the Full variant, and the untemplated `docs/reviews/<review-slug>.md` report listed as required but not measurable.
- [x] **AC-2** — The script prints a provenance line naming the source revision and the token convention, so a reader can reproduce the figures.
- [x] **AC-3** — `--strict` fails when any published figure diverges *in either direction* from its recorded baseline (equality, not a growth bound) — the four level totals, the shared setup, all four specification variants, all five optional artifacts, and both band endpoints per level — so a reduced mandatory template fails the same gate as a grown one, and a padded variant or optional template cannot drift green.
- [x] **AC-4** — CI runs the strict gate on both hosts (Bash step on Linux, PowerShell step on Windows) and the syntax lists cover both new scripts.
- [x] **AC-5** — `docs/BENCHMARKS.md` states the figures, their provenance, and an explicit "what this does not measure" boundary, in template-size language rather than as a per-task cost claim, and states what the anchors do and do not catch.
- [ ] **AC-6** — Live L0–L3 profiling at three or more runs per level. **Not met and not claimed**; it remains an open criterion on #607 because no host telemetry exists here.
- [x] **AC-7** — `scripts/measure-ceremony-overhead.ps1` is a behavioural twin: identical stdout (after CR stripping), identical stderr, and identical exit codes to the Bash script on the clean tree and on every negative probe.

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
| awaiting_review | in_progress | lead, 2026-11-11 00:05 UTC (second external review: five requested changes) |
| in_progress | awaiting_review | lead, 2026-11-11 00:40 UTC (second rework landed) |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/measure-ceremony-overhead.sh` (new, executable)
  - `scripts/measure-ceremony-overhead.ps1` (new, behavioural twin)
  - `docs/BENCHMARKS.md` (new subsection in section 2)
  - `.github/workflows/ci.yml` (Bash strict-gate step, PowerShell strict-gate step, `bash -n` line, PowerShell syntax list)
  - `CHANGELOG.md` (Unreleased / Added entry)
  - `docs/STATE.md` (section 3A projection points at this record)
  - `docs/tasks/TASK-2026-11-10-ceremony-artifact-overhead.md` (this record)
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**:
  - `bash scripts/measure-ceremony-overhead.sh --strict` → exit 0 with `CEREMONY_GATE|PASS` and eighteen passing equality rows: `CEREMONY_BASELINE|L0|0|0|PASS`, `|L1|0|0|PASS`, `|L2|5639|5639|PASS`, `|L3|13458|13458|PASS`, `|SETUP|3021|3021|PASS`, four `SPEC:` rows (tech-spec 5,480 / data-model 1,825 / auth-matrix 979 / api-contract 1,347), five `OPT:` rows (checkpoint 827 / handoff 978 / scope-change 782 / ci-triage 1,603 / code-review-checklist 1,534), and four band endpoints (`BAND:L2:min|6618`, `BAND:L2:max|11119`, `BAND:L3:min|14437`, `BAND:L3:max|18938`).
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/measure-ceremony-overhead.ps1 -Strict` → exit 0, and `diff` against the Bash stdout after CR stripping is empty (`PARITY_IDENTICAL`); stderr and exit codes match too.
  - Gate discriminates in both directions, proven in an isolated copy at `/tmp/cer-test` with the repository tree untouched, Bash and PowerShell agreeing on every case: pristine copy PASS/PASS; padding `templates/auth-matrix-template.md` by 112 B (a published variant) → exit 1/1 `CEREMONY_GATE|FAIL`; padding `templates/code-review-checklist.md` by 400 B (a published optional artifact) → exit 1/1 FAIL; shrinking `templates/tech-spec-template.md` to 10,000 B → exit 1/1 FAIL; restoring → PASS/PASS.
  - Policy-drift probe in the same copy: appending a requirement to the cited Level 2 ceremony line in `workflows/route.md` → exit 2/2 with `CEREMONY_ANCHOR|workflows/route.md|CHANGED`, so the curated list cannot silently outlive the policy it cites. The anchors pin whole lines by SHA-256, which catches edits to the cited lines; they do not catch a requirement added elsewhere in the same workflow file, and `docs/BENCHMARKS.md` says so.
  - `bash scripts/validate-references.sh .` → exit 0, "All references valid! No broken links found."
  - `bash scripts/measure-tokens.sh --strict` → exit 0, `BALANCED|2348|2500|PASS` and `LITE|1456|1500|PASS`.
  - `bash scripts/validate-execution-control.sh --strict` → exit 0, `VALID|RECORDS=70`.
  - `bash scripts/check-doctor.sh .` → exit 1 with a single failing row, `version DIVERGED` ("engine v2.1.0-6-ga300e85 diverged from refs/remotes/origin/main"). That row is expected on this branch: the check tests whether HEAD is an ancestor of the upstream ref, and HEAD carries this task's commit. The base commit is current (`git merge-base --is-ancestor 471ebc7 refs/remotes/origin/main` → 0), so the row returns to OK once the branch merges. Every other row is OK or an expected SKIP/IGNORED, including `host:AGENTS.md OK` and `docs-drift OK` (projection agrees with this record).
  - `bash -n scripts/measure-ceremony-overhead.sh` → exit 0; `shellcheck -S warning` → no findings.
  - Published figures (profile `balanced`, tokens = floor((bytes after CR stripping + 2) / 4)): L0 0 B / 0 tok; L1 0 B / **0 tok**; L2 22,557 B / **5,639 tok** (Minimal Planning default: Task Record + checkpoint); L3 53,833 B / **13,458 tok**; shared one-time setup `templates/state-tracker-template.md` 12,084 B / **3,021 tok**, counted once (`CEREMONY_SHARED_SETUP|files=1|bytes=12084|tokens=3021|amortisation=once-per-project`). Full Planning adds exactly one specification member: `CEREMONY_SPEC_BAND|L2|6618|11119` and `CEREMONY_SPEC_BAND|L3|14437|18938`, both `pinned=templates/tech-spec-template.md`. The required `docs/reviews/<review-slug>.md` report is listed as `untemplated` with no byte or token figure. These supersede the first published 0 / 3,021 / 8,660 / 16,479 (which double-counted the shared tracker and omitted the specification family) and the second published 0 / 0 / 11,119 / 18,938 (which charged the Full Planning specification to every Level 2 task and omitted the durable review report).
  - Namespace: `CEREMONY_ARTIFACT|` and its siblings (`CEREMONY_ANCHOR|`, `CEREMONY_SHARED_SETUP|`, `CEREMONY_SPEC_BAND|`, `CEREMONY_TOTAL|`, `CEREMONY_BASELINE|`, `CEREMONY_PROVENANCE|`) rather than the bare `CEREMONY|` prefix, which `benchmarks/tasks/TASK-BENCH-L1-02.md` reserves for `scripts/measure-per-task-tokens.sh`.
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `PR #731 run 42797339041 passed 12/12 (4m57s) for the pre-rework commit e8f8033, run 42801026295 passed 12/12 for the first rework commit 500ed5d, and run 42801690875 passed 12/12 for c3f8dc2; the second rework adds the Windows PowerShell step, so its own run is the first to exercise both hosts`
- **Review Evidence**: `Two external reviews (arena.ai, 2026-11-10), all nine findings upheld. First review: (1) per-task artifacts were conflated with the shared tracker and the Level 2 formal specification was missing; (2) template size was mislabeled as per-task cost and as a static ceiling; (3) artifact membership was hard-coded with no policy-consistency check; (4) --strict was growth-only, so a reduced template passed (L2 8,660 -> 6,348) and Level 0 was skipped. Second review of c3f8dc2: (1) BENCHMARKS still called the band what Level 2 "actually costs"; (2) the selected set was not universally required per task - plan.md:67-69 makes Minimal Planning the Level 2 default with no spec file, and the durable pk:review report was missing entirely; (3) the strict gate covered only the five pinned totals, so a padded variant or optional template drifted green; (4) anchors proved only that short fragments still existed; (5) no PowerShell twin, against PROMPTKIT.md:86 twin parity. Fixes in this round: every cost claim replaced with template-size language; Level 2 split into Minimal (5,639 tok) and Full (6,618-11,119) with the untemplated review report listed as required and not measurable; every published figure pinned by the equality gate; anchors upgraded to whole-line SHA-256 pins with the documentation narrowed to what they actually catch; and scripts/measure-ceremony-overhead.ps1 added, wired into Windows CI, and proven byte-identical to the Bash output. Owner review of the rework is the open step.`
- **Commit Evidence**: `Pending at record-write time: the second rework lands as a third commit on feat/607-ceremony-overhead, and this record is committed with it`
- **Pull Request Evidence**: `PR #731 (open) — the rework commit is pushed to the same branch, updating the PR rather than opening a second one`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

### Durable Authorization Checkpoints

- `None created` — no review, PR, or release boundary was authorized or exercised under this record.

### Commit Evidence Entries

- `N/A before commit` — this record is committed together with the work it describes.

### Completion Gate

- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 met (each level's set cites its policy line, the Level 2 planning depth is split, the untemplated review report is listed, and the eight cited sentences are pinned at run time with the drift probe proving the failure path); AC-2 met (CEREMONY_PROVENANCE names the revision, the bytes/4 convention, the two units, and the curated selection); AC-3 met (--strict asserts equality on all eighteen published figures, failing on growth and on reduction, including padded variants and optional artifacts); AC-4 met (Bash and PowerShell CI steps plus both syntax lists); AC-5 met (BENCHMARKS restates every figure in template-size language, the units, both planning depths, the untemplated report, the equality semantics, what the anchors do and do not catch, and the what-these-figures-are-not boundary); AC-6 not met and not claimed (no live profiling); AC-7 met (the PowerShell twin is byte-identical to the Bash output on the clean tree and on every negative probe)`
- **Changed-File Summary**: `Two new scripts (Bash and PowerShell), one new documentation subsection, two CI steps plus two syntax-list entries, one changelog entry, one STATE projection update, one task record — no shipped template, workflow, or protocol was modified by either rework; every review finding was fixed inside the same file set.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Submitted for review by lead, 2026-11-10 23:10 UTC; reworked after the first external review and resubmitted, 2026-11-10 23:55 UTC; reworked again after the second external review and resubmitted, 2026-11-11 00:40 UTC; completion is the owner's decision`
