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
- **Execution Scope**: `promptkit-os repository — Phase 3 live benchmark batch (three real backlog tasks), the transcript-slug driver fix discovered by the first live run, publication of the batch under benchmarks/runs/, the Phase 3 record/docs updates, and the post-review verify-packet blinding/disclosure remediation`
- **Approval Boundary**: `Human approval authorized the live Command Code spend (six runs, then a clean six-run rerun), in-session grading after the owner's go, publication of records/diffs/verify packets under benchmarks/runs/, and local commits with a PR body. The owner subsequently authorized push and PR creation ("publish it"), then the post-review remediation and its push to PR #695; merge remains human-only. Raw transcripts and grading/key.csv are never published.`
- **Created**: `2026-10-26 02:31 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Execute and publish the first live dual-condition A/B batch for Phase 3: three real backlog tasks spanning L0-L2, both arms, one repeat, blind-id grading with disclosed packet limits, CPAC aggregation, and an honest limitations record — fixing any harness defect the live run exposes.`
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
  - `No changes to the CPAC formula, pricing defaults, extractor semantics, or the Phase 2 harness contract beyond the transcript-slug defect and the post-review verify-packet scrub; no live re-spend or independent re-grade.`
  - `No publication of raw Command Code transcripts, grading/key.csv, grading.scenario.tsv, or full clone directories.`
  - `No push, PR creation, merge, release, deployment, or Phase 2/CPAC record closure in this task.`
- **Dependencies**: `Merged harness at 9c8080d (PRs #692 + #693); Command Code 1.88.0 in WSL; empty ~/.commandcode/taste/taste.md; owner spend and grading approvals recorded in AUTHZ-live-ab-benchmark-001.`
- **Risk**: `Medium` - `Live spend and a single model/host/repeat; both L2 sessions hit the 900-second cap; the seed is the engine repository itself, which limits external validity; the first live attempt exposed a harness defect that is now fixed and regression-tested.`
- **Verification Condition**: `run-benchmark-driver-tests.sh 9/9; run-benchmark-tools-tests twins 11/11; run-cpac-ingestion-tests twins 19/17; behavioral-contract twins green; validate-execution-control.sh --root . --strict --authorization-baseline origin/main exits 0; check-changelog-entry.sh passes; validate-references.sh . --strict passes; measure-tokens/measure-per-task-tokens strict gates pass on both twins; measured verify packets contain no arm/scenario identifiers; published batch contains no key.csv or raw transcripts.`

## 3. Acceptance Criteria

- [x] **AC-1**: The driver's transcript lookup matches Command Code's actual slug alphabet, and the regression harness pins the real CLI-shaped path.
  - **Result**: `Pass`
  - **Evidence**: `2811353 — slugify_run_path() lowercases and converts underscores/path separators to hyphens; the stub writes the CLI-shaped directory; run-benchmark-driver-tests.sh 9/9 after the review remediation; the old lookup now misses the stub transcript.`
- [x] **AC-2**: Three real backlog task specs with frozen rubrics and Verify commands are committed.
  - **Result**: `Pass`
  - **Evidence**: `e9c82bd — BENCH-L0-01 (6 rubric items, validate-references), BENCH-L1-02 (5, measurement twins), BENCH-L2-02 (6, behavioral twins); issue links #607/#596.`
- [x] **AC-3**: Preflight passes without spend, the clean batch runs six sessions, and its verify packets are path-scrubbed so they do not reveal the arm.
  - **Result**: `Pass after correction`
  - **Evidence**: `PREFLIGHT|OK|engine=9c8080d|seed=9c8080d|model=deepseek/deepseek-v4.1-flash|cli=1.88.0; driver.log BATCH|OK|runs=6; manifest.tsv 6 rows; B001-B006; L0/L1 cli_exit=0, both L2 cli_exit=124. The original B003/B006 verify packets leaked BENCH-L0-01-<arm>-r1; the harness now scrubs $rundir/$OUT/$scenario, the driver regression pins it (9/9), and the published copies were redacted to <rundir>. The L0 grade remains only partially blind; see AC-4.`
- [x] **AC-4**: Grading is completed before the key is consulted, any packet-level blinding defect is disclosed, and finalize produces per-run and per-arm CPAC results.
  - **Result**: `Pass with disclosed partial blinding`
  - **Evidence**: `grading/grading.tsv (B001 6/6, B002 5/5, B003 6/6, B004 6/6, B005 5/5, B006 6/6; all accepted); finalize.log RUN| rows + BENCH|SUMMARY (bare: spot 3/3, CPAC mean 2.0604; promptkit_os: 3/3, CPAC mean 4.4442); key.csv first consulted by --finalize. The L0 verify packets leaked the arm, so L0 was not fully blind; no independent re-score was performed and the batch report records the limitation.`
- [x] **AC-5**: The batch is published under benchmarks/runs/ with records, full and stripped diffs, verify packets, blind packets, manifest, logs, and the report; raw transcripts and the key are excluded.
  - **Result**: `Pass`
  - **Evidence**: `benchmarks/runs/2026-10-26-phase3-deepseek-v4.1-flash/ — 872K; 6 record.json, 6 full run.diff, 6 stripped diffs, 6 verify.txt, B001-B006 packets, grading.tsv, env/manifest/driver/finalize/error-patterns, report; no key.csv, grading.scenario.tsv, transcript, or clone dir.`
- [x] **AC-6**: The report and repository docs state the measured result, the n=6/single-model limitation, the L2 timeout, the single-reviewer/partially-blind grading, the verify-packet leak, and the instruction/hook confound without overclaiming.
  - **Result**: `Pass`
  - **Evidence**: `batch README §Correction/§Results/§Interpretation/§Limitations; benchmarks/README.md Published batches and Limitations; docs/BENCHMARKS.md §10 pointer; CHANGELOG entry; this record.`
- [x] **AC-7**: The full verification battery passes on the final branch.
  - **Result**: `Pass`
  - **Evidence**: `run-benchmark-driver-tests.sh 9/9; run-benchmark-tools-tests.sh 11/11 and .ps1 11/11; run-cpac-ingestion-tests.sh 19/19 and .ps1 17/17; validate-execution-control.sh --root . --strict --authorization-baseline origin/main → VALID|RECORDS=69; check-changelog-entry.sh → PASS; validate-references.sh . --strict → pass; measure-tokens strict → Balanced 2,348/2,500, Lite 1,456/1,500; measure-per-task-tokens strict → pass both twins; check-math-labels.sh → PASS; behavioral-contract twins 560/560 Bash, 549/549 PowerShell.`
- [x] **AC-8**: At acceptance the branch was local, with no push, PR creation, merge, release, or deployment, and the PR body was prepared. The owner subsequently authorized publishing.
  - **Result**: `Pass` (held at acceptance; publish authorized after acceptance)
  - **Evidence**: `PR #695 opened after the owner's "publish it"; no merge performed.`

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
- **Next Action**: `Owner review of PR #695; merge remains human-only.`

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

<a id="AUTHZ-live-ab-benchmark-002"></a>

- **Authorization Checkpoint ID**: `AUTHZ-live-ab-benchmark-002`
- **Declared Boundary**: `pr`
- **Verbatim Human Instruction**: `"publish it"`
- **Instruction Source**: `Owner message in the 2026-10-26 agent session, after the PR-ready handoff`
- **Frozen Task and Milestone Scope**: `Push feat/phase-3-live-ab-benchmark and open a ready PR against main using the prepared PR body; merge, release, and deployment remain human-only.`
- **Batch Authorization Reference**: `N/A`

<a id="AUTHZ-live-ab-benchmark-003"></a>

- **Authorization Checkpoint ID**: `AUTHZ-live-ab-benchmark-003`
- **Declared Boundary**: `pr`
- **Verbatim Human Instruction**: `"Fix the verify-packet blinding leak and the two disclosure gaps on PR #695."`
- **Instruction Source**: `Owner message in the 2026-10-26 agent session`
- **Frozen Task and Milestone Scope**: `Correct the verify-output path leak, add the driver regression, redact the published L0 verify packets, disclose the L0 partial blinding and key recoverability, disclose the seed/host instruction-hook confound, correct the stale docs, push to PR #695, and update its body; no merge, release, or deployment.`
- **Batch Authorization Reference**: `N/A`

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `benchmarks/run-ab-benchmark.sh` - CLI-compatible cwd slug and path-scrubbed verify packets
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
- **Verification Evidence**: `Full battery green: driver 9/9; benchmark tools 11/11 both twins; CPAC ingestion 19/19 Bash and 17/17 PowerShell; execution-control VALID|RECORDS=69; changelog gate PASS; references pass; token gates 2,348/2,500 and 1,456/1,500; per-task gate pass both twins; math-label gate PASS; behavioral-contract 560/560 Bash and 549/549 PowerShell.`
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `PromptKit OS CI (pull_request) run 40260718784 on a1e4caf: 8/8 checks green — Lint & Validate (Linux/Windows), Linux Validate (Core), Windows Validate (Core), Linux Shard - Execution Control Fixtures, Windows Shard - Init Safety, Windows Shard - Documentation Contract, Staged Secret Scan (PR Diff). The remediation CI rerun after d586718 is tracked in the PR checks.`
- **Review Evidence**: `In-session grading after the owner's go; key.csv was not read before grading.tsv was written; single reviewer, no independent re-score. External PR review found the L0 verify-packet leak and the instruction/hook confound; the batch README now records both limitations and the L0 grade as only partially blind.`
- **Commit Evidence**: `2811353, e9c82bd, 0d67371, 5cc85d5, a1e4caf, d586718; the review-remediation record entry is carried by a follow-up docs commit.`
- **Pull Request Evidence**: `[#695](https://github.com/lowqualityloey/promptkit-os/pull/695) — open, non-draft, base main; remediation commit d586718 is being pushed with this record and its CI rerun is tracked in the PR checks; merge remains human-only.`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

### Commit Evidence Entries

- **Commit Evidence Entry**: `2811353 fix(benchmarks): match command-code transcript slug; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-001; Authorization Source: owner Phase 3 setup + spend approvals`
- **Commit Evidence Entry**: `e9c82bd docs(benchmarks): add phase 3 live task batch; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-001; Authorization Source: owner Phase 3 setup + frozen rubrics`
- **Commit Evidence Entry**: `0d67371 feat(benchmarks): publish first live ab batch; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-001; Authorization Source: owner publication choice (records + diffs + verify packets) and local-branch boundary`
- **Commit Evidence Entry**: `5cc85d5 docs(tasks): record phase 3 live ab batch; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-001; Authorization Source: owner local-branch + PR-body boundary`
- **Commit Evidence Entry**: `a1e4caf docs(tasks): record phase 3 record commit evidence; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-001; Authorization Source: owner local-branch + PR-body boundary`
- **Commit Evidence Entry**: `d586718 fix(benchmarks): scrub verify packet paths and correct phase 3 disclosures; Authorization Checkpoint Reference: AUTHZ-live-ab-benchmark-003; Authorization Source: owner review-remediation instruction`

### Post-Review Remediation (PR #695)

- **Trigger**: PR #695 external review found a verify-packet path leak in the L0 packets and undisclosed instruction/hook and key-recoverability confounds.
- **Harness fix**: `benchmarks/run-ab-benchmark.sh` scrubs `$rundir`, `$OUT`, and `$scenario` before writing verify packets; the mock Verify command prints its cwd and the ninth driver case asserts the packet contains `<rundir>` and no arm/scenario id.
- **Published correction**: the L0 `B003`/`B006` verify packets and their run-level sources were redacted to `<rundir>`; the batch report now records that the originals leaked the arm and that the L0 grade remains only partially blind.
- **Disclosure**: the batch report and `benchmarks/README.md` now record the seed-level `AGENTS.md`/`heyloey` and host-level `~/.commandcode` instruction/hook confound, including the bare L1 exit 5; the key is described as withheld during grading but derivable from the published stripped diffs.
- **Scope**: no live Command Code session and no independent re-grade were run; the six graded outcomes are unchanged.
- **Commit Evidence**: `d586718 fix(benchmarks): scrub verify packet paths and correct phase 3 disclosures; this record entry is carried by the follow-up docs commit.`

### Completion Gate

- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass after correction; AC-4 Pass with disclosed partial blinding; AC-5 Pass; AC-6 Pass; AC-7 Pass; AC-8 Pass`
- **Changed-File Summary**: `11 paths: driver + driver harness, three real task specs, the published batch directory (report, env, manifest, records, full/stripped diffs, verify packets, blind packets, grading sheet, logs), README/BENCHMARKS pointers, CHANGELOG, .gitignore, this record.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Pending owner review of PR #695 — merge remains human-only`
