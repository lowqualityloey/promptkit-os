# Task Record: First live A/B benchmark batch (Phase 3)

<a id="TASK-2026-10-26-live-ab-benchmark"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-26-live-ab-benchmark`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Code Work`
- **Specification**: `docs/BENCHMARK-METHODOLOGY.md` §4 (Dual-Condition Evaluation Protocol) and `benchmarks/README.md` (the concrete protocol this batch executes); Phase 3 runbook at `https://github.com/lowqualityloey/promptkit-os/issues/694`.
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/694`, `https://github.com/lowqualityloey/promptkit-os/issues/607`, `https://github.com/lowqualityloey/promptkit-os/issues/596`
- **Owner / Actor**: `PromptKit maintainer (agent-assisted session)`
- **Execution Scope**: `promptkit-os repository — Phase 3 live benchmark batch (three real backlog tasks), the transcript-slug driver fix discovered by the first live run, publication of the batch under benchmarks/runs/, and the Phase 3 record/docs updates`
- **Approval Boundary**: `Human approval authorized the live Command Code spend (six runs, then a clean six-run rerun), in-session blind grading after the owner's go, publication of records/diffs/verify packets under benchmarks/runs/, and local commits with a PR body. Push, PR creation, and merge remain human-only; raw transcripts and grading/key.csv are never published.`
- **Created**: `2026-10-26 02:31 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Execute and publish the first live dual-condition A/B batch for Phase 3: three real backlog tasks spanning L0-L2, both arms, one repeat, blind grading, CPAC aggregation, and an honest limitations record — fixing any harness defect the live run exposes.`
- **In Scope**:
  - `benchmarks/run-ab-benchmark.sh` — Command Code transcript-slug correction
  - `scripts/tests/run-benchmark-driver-tests.sh` — real CLI-shaped slug regression case
  - `benchmarks/tasks/TASK-BENCH-L0-01.md` — real #607 slice (record the unmeasured ceremony-overhead gap)
  - `benchmarks/tasks/TASK-BENCH-L1-02.md` — real #607 slice (static ceremony-artifact sizes in both measurement twins)
  - `benchmarks/tasks/TASK-BENCH-L2-02.md` — real #596 slice (discovery-route regression guard in both contract twins)
  - `benchmarks/runs/2026-10-26-phase3-deepseek-v4.1-flash/` — published batch artifacts and report
  - `benchmarks/README.md` — published-batch pointer
  - `docs/BENCHMARKS.md` — empirical-results pointer
  - `CHANGELOG.md` — batch, fix, and task entries
  - `.gitignore` — scoped exception for published benchmark logs
  - `docs/tasks/TASK-2026-10-26-live-ab-benchmark.md` — this record
- **Explicit Non-Goals**:
  - `No L3 task, second repeat, cross-model comparison, or statistical significance claim in this batch.`
  - `No changes to the CPAC formula, pricing defaults, extractor semantics, or the Phase 2 harness contract beyond the transcript-slug defect.`
  - `No publication of raw Command Code transcripts, grading/key.csv, grading.scenario.tsv, or full clone directories.`
  - `No push, PR creation, merge, release, deployment, or Phase 2/CPAC record closure in this task.`
- **Dependencies**: `Merged harness at 9c8080d (PRs #692 + #693); Command Code 1.88.0 in WSL; empty ~/.commandcode/taste/taste.md; owner spend and grading approvals recorded in AUTHZ-live-ab-benchmark-001.`
- **Risk**: `Medium` - `Live spend and a single model/host/repeat; both L2 sessions hit the 900-second cap; the seed is the engine repository itself, which limits external validity; the first live attempt exposed a harness defect that is now fixed and regression-tested.`
- **Verification Condition**: `run-benchmark-driver-tests.sh 8/8; run-benchmark-tools-tests twins 11/11; run-cpac-ingestion-tests twins 19/17; behavioral-contract twins green; validate-execution-control.sh --root . --strict --authorization-baseline origin/main exits 0; check-changelog-entry.sh passes; validate-references.sh . --strict passes; measure-tokens/measure-per-task-tokens strict gates pass on both twins; published batch contains no key.csv or raw transcripts.`

## 3. Acceptance Criteria

- [x] **AC-1**: The driver's transcript lookup matches Command Code's actual slug alphabet, and the regression harness pins the real CLI-shaped path.
  - **Result**: `Pass`
  - **Evidence**: `2811353 — slugify_run_path() lowercases and converts underscores/path separators to hyphens; the stub writes the CLI-shaped directory; run-benchmark-driver-tests.sh 8/8; the old lookup now misses the stub transcript.`
- [x] **AC-2**: Three real backlog task specs with frozen rubrics and Verify commands are committed.
  - **Result**: `Pass`
  - **Evidence**: `e9c82bd — BENCH-L0-01 (6 rubric items, validate-references), BENCH-L1-02 (5, measurement twins), BENCH-L2-02 (6, behavioral twins); issue links #607/#596.`
- [x] **AC-3**: Preflight passes without spend, and the clean batch runs six sessions and produces six blind packets.
  - **Result**: `Pass`
  - **Evidence**: `PREFLIGHT|OK|engine=9c8080d|seed=9c8080d|model=deepseek/deepseek-v4.1-flash|cli=1.88.0; driver.log BATCH|OK|runs=6; manifest.tsv 6 rows; blind B001-B006; L0/L1 cli_exit=0, both L2 cli_exit=124.`
- [x] **AC-4**: Blind grading is completed before the key is consulted, and finalize produces per-run and per-arm CPAC results.
  - **Result**: `Pass`
  - **Evidence**: `grading/grading.tsv (B001 6/6, B002 5/5, B003 6/6, B004 6/6, B005 5/5, B006 6/6; all accepted); finalize.log RUN| rows + BENCH|SUMMARY (bare: spot 3/3, CPAC mean 2.0604; promptkit_os: 3/3, CPAC mean 4.4442); key.csv first consulted by --finalize.`
- [x] **AC-5**: The batch is published under benchmarks/runs/ with records, full and stripped diffs, verify packets, blind packets, manifest, logs, and the report; raw transcripts and the key are excluded.
  - **Result**: `Pass`
  - **Evidence**: `benchmarks/runs/2026-10-26-phase3-deepseek-v4.1-flash/ — 872K; 6 record.json, 6 full run.diff, 6 stripped diffs, 6 verify.txt, B001-B006 packets, grading.tsv, env/manifest/driver/finalize/error-patterns, report; no key.csv, grading.scenario.tsv, transcript, or clone dir.`
- [x] **AC-6**: The report and repository docs state the measured result, the n=6/single-model limitation, the L2 timeout, and the single-reviewer/delegated-grading limitation without overclaiming.
  - **Result**: `Pass`
  - **Evidence**: `batch README §Results/§Interpretation/§Limitations; benchmarks/README.md Published batches; docs/BENCHMARKS.md §10 pointer; CHANGELOG entry; this record.`
- [x] **AC-7**: The full verification battery passes on the final branch.
  - **Result**: `Pass`
  - **Evidence**: `run-benchmark-driver-tests.sh 8/8; run-benchmark-tools-tests.sh 11/11 and .ps1 11/11; run-cpac-ingestion-tests.sh 19/19 and .ps1 17/17; validate-execution-control.sh --root . --strict --authorization-baseline origin/main → VALID|RECORDS=69; check-changelog-entry.sh → PASS; validate-references.sh . --strict → pass; measure-tokens strict → Balanced 2,348/2,500, Lite 1,456/1,500; measure-per-task-tokens strict → pass both twins; check-math-labels.sh → PASS; behavioral-contract twins 560/560 Bash, 549/549 PowerShell.`
- [x] **AC-8**: The branch remains local, with no push, PR creation, merge, release, or deployment; the PR body is prepared for the owner.
  - **Result**: `Pass` (held at acceptance)
  - **Evidence**: `Branch feat/phase-3-live-ab-benchmark; no remote write performed; PR body prepared separately.`

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled` - `N/A - TDD Enforcement Mode disabled`
- **Batch Authorization**: `N/A - owner-gated spend approvals recorded in AUTHZ-live-ab-benchmark-001`
- **Authorization Checkpoint Reference**: `AUTHZ-live-ab-benchmark-001`
- **Soft Checkpoint**: `N/A - owner checkpoints at preflight, batch start, clean rerun, and publication; the batch itself ran unattended`
- **Hard Checkpoint**: `N/A - no 90-minute timed checkpoint; owner approvals governed each spend/publication boundary`
- **Event-Driven Checkpoints**: `Milestone, spend approval, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `No live host timer or forced-termination capability is available in this agent session; checkpoint timing is advisory only and cannot be mechanically enforced.`

## 5. State and Active Ownership

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-26 00:10 UTC`
- **Current Actor**: `PromptKit maintainer (agent-assisted session)`
- **Next Action**: `Owner review of the local branch and PR body; push, PR creation, and merge remain human-only.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `None` | `planned` | `2026-10-26 00:05 UTC` | `agent-assisted session` | Phase 3 setup fixed the seed, model, and 3-task scope | `Owner Phase 3 setup message` |
| `planned` | `ready` | `2026-10-26 00:05 UTC` | `agent-assisted session` | Task batch and rubrics frozen; spend boundary recorded | `Frozen task specs` |
| `ready` | `in_progress` | `2026-10-26 00:10 UTC` | `agent-assisted session` | Preflight green; clean six-run batch started | `PREFLIGHT\|OK`; batch driver log |
| `in_progress` | `awaiting_review` | `2026-10-26 02:31 UTC` | `agent-assisted session` | Batch finalized, published, and verified | `finalize.log`; published batch; verification battery |

The record was authored at close-out; timestamps describe the work, not the file's creation time.

### Durable Authorization Checkpoints

<a id="AUTHZ-live-ab-benchmark-001"></a>

- **Authorization Checkpoint ID**: `AUTHZ-live-ab-benchmark-001`
- **Declared Boundary**: `full` (local implementation, live spend, publication under `benchmarks/runs/`, and PR-body preparation; no push/open/merge)
- **Verbatim Human Instruction**: `"Phase 3 setup: the seed repo is promptkit-os itself, the model is deepseek v4.1 flash (latest), and first batch scope is 3 tasks: L0, L1, L2, 1 repeat"` → `"Approve 6 runs"` → `"Approve clean rerun (7 total)"` → `"can you plan finish this phase until PR is ready"` → `"You grade"` / `"Local branch + PR body"` / `"Records + diffs + verify packets"` → `"go"`
- **Instruction Source**: `Owner messages in the 2026-10-26 agent session (Phase 3 setup; spend approvals; PR boundary; grading/publication choices)`
- **Frozen Task and Milestone Scope**: `Phase 3 first live batch: BENCH-L0-01, BENCH-L1-02, BENCH-L2-02 × bare/promptkit_os × 1 repeat on deepseek/deepseek-v4.1-flash; fix the live transcript-slug defect; publish records/diffs/verify packets; prepare a local branch and PR body; no push, PR creation, merge, release, or deployment.`
- **Batch Authorization Reference**: `N/A`

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `benchmarks/run-ab-benchmark.sh` - CLI-compatible cwd slug for transcript lookup
  - `scripts/tests/run-benchmark-driver-tests.sh` - real CLI-shaped slug regression
  - `benchmarks/tasks/TASK-BENCH-L0-01.md` - real #607 slice (overhead gap)
  - `benchmarks/tasks/TASK-BENCH-L1-02.md` - real #607 slice (static ceremony sizes)
  - `benchmarks/tasks/TASK-BENCH-L2-02.md` - real #596 slice (discovery-route guard)
  - `benchmarks/runs/2026-10-26-phase3-deepseek-v4.1-flash/` - published batch + report
  - `benchmarks/README.md` - published-batch pointer
  - `docs/BENCHMARKS.md` - first empirical batch pointer
  - `CHANGELOG.md` - Added/Fixed entries
  - `.gitignore` - published benchmark log exception
  - `docs/tasks/TASK-2026-10-26-live-ab-benchmark.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Full battery green: driver 8/8; benchmark tools 11/11 both twins; CPAC ingestion 19/19 Bash and 17/17 PowerShell; execution-control VALID|RECORDS=69; changelog gate PASS; references pass; token gates 2,348/2,500 and 1,456/1,500; per-task gate pass both twins; math-label gate PASS; behavioral-contract 560/560 Bash and 549/549 PowerShell.`
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `N/A before push; the PR run will be recorded here`
- **Review Evidence**: `Blind in-session grading after the owner's go; key.csv was not read before grading.tsv was written; single reviewer, no independent re-score (recorded in the batch README's Limitations).`
- **Commit Evidence**: `2811353, e9c82bd, 0d67371; this record's own commit is recorded in the docs-only follow-up per the two-commit pattern.`
- **Pull Request Evidence**: `N/A - local branch + PR body only; no remote write authorized`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

### Commit Evidence Entries

- **Commit Evidence Entry**: `2811353 fix(benchmarks): match command-code transcript slug; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-001; Authorization Source: owner Phase 3 setup + spend approvals`
- **Commit Evidence Entry**: `e9c82bd docs(benchmarks): add phase 3 live task batch; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-001; Authorization Source: owner Phase 3 setup + frozen rubrics`
- **Commit Evidence Entry**: `0d67371 feat(benchmarks): publish first live ab batch; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-001; Authorization Source: owner publication choice (records + diffs + verify packets) and local-branch boundary`

### Completion Gate

- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass; AC-5 Pass; AC-6 Pass; AC-7 Pass; AC-8 Pass`
- **Changed-File Summary**: `11 paths: driver + driver harness, three real task specs, the published batch directory (report, env, manifest, records, full/stripped diffs, verify packets, blind packets, grading sheet, logs), README/BENCHMARKS pointers, CHANGELOG, .gitignore, this record.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Pending owner review — push, PR creation, and merge are human-only`
