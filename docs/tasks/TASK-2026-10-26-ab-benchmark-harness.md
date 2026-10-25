# Task Record: A/B Benchmark Harness

<a id="TASK-2026-10-26-ab-benchmark-harness"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-26-ab-benchmark-harness`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Code Work`
- **Specification**: `docs/BENCHMARK-METHODOLOGY.md` §4 (Dual-Condition Evaluation Protocol) and `benchmarks/README.md` (the concrete protocol this harness implements) — the approved Phase 2 of the empirical-evidence roadmap.
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/607`, `https://github.com/lowqualityloey/promptkit-os/issues/596`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository — benchmark scaffolding (task specs, run artifacts policy), pure benchmark tooling with twins, fixture tests, CI registration, and describing docs`
- **Approval Boundary**: `Human approval authorizes local implementation, PR creation, and record updates; running the benchmark against live Command Code sessions (spend), and merge, remain human-only.`
- **Created**: `2026-10-26 01:55 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Build the A/B benchmark harness per the approved Phase 2 plan: frozen task specs with rubrics, a paired-run driver over headless Command Code (PromptKit directive vs bare), blind grading support, and CPAC aggregation through the Phase-1 pipeline — plus the two audit P3 one-liners promised for this phase (extractor LC_ALL=C, fractional-offset parsing).`
- **In Scope**:
  - `scripts/extract-commandcode-telemetry.sh`
  - `scripts/extract-commandcode-telemetry.ps1`
  - `scripts/strip-benchmark-diff.sh` (new)
  - `scripts/strip-benchmark-diff.ps1` (new)
  - `scripts/aggregate-benchmark-runs.sh` (new)
  - `scripts/aggregate-benchmark-runs.ps1` (new)
  - `scripts/tests/run-benchmark-tools-tests.sh` (new)
  - `scripts/tests/run-benchmark-tools-tests.ps1` (new)
  - `scripts/tests/run-cpac-ingestion-tests.sh`
  - `scripts/tests/run-cpac-ingestion-tests.ps1`
  - `scripts/tests/fixtures/benchmark-tools/` (new)
  - `benchmarks/README.md` (new)
  - `benchmarks/tasks/TEMPLATE-task.md` (new)
  - `benchmarks/tasks/TASK-BENCH-L1-01.md` (new, synthetic example)
  - `benchmarks/tasks/TASK-BENCH-L2-01.md` (new, synthetic example)
  - `benchmarks/run-ab-benchmark.sh` (new, operator-local orchestrator)
  - `benchmarks/runs/.gitkeep` (new)
  - `.github/workflows/ci.yml`
  - `CONTRIBUTING.md`
  - `docs/ARCHITECTURE.md`
  - `docs/BENCHMARKS.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-10-26-ab-benchmark-harness.md`
- **Explicit Non-Goals**:
  - `No live benchmark execution, task-batch selection, model choice, or results publication (Phase 3, owner-gated spend).`
  - `No changes to CPAC scoring semantics in measure-cpac twins beyond what Phase 1 shipped.`
  - `No measured-input edits (workflows/, protocols/code-quality-gate.md, the four measured templates) — the docs/BENCHMARKS.md provenance anchor and every published figure are unaffected.`
- **Dependencies**: `PR #692 merged (0d83422) — the §5 pipeline this harness drives`
- **Risk**: `Medium` - `The orchestrator is operator-local and cannot be exercised end-to-end in CI (it drives a live subscription CLI); mitigated by keeping all pure logic in twin-tested scripts, fixture coverage for strip/aggregate, and a --preflight-only mode that validates the environment without spending.`
- **Verification Condition**: `run-benchmark-tools-tests.sh and its .ps1 twin exit 0; run-cpac-ingestion-tests.sh and .ps1 (with the new P3 cases) exit 0; validate-execution-control.sh --root . --strict --authorization-baseline origin/main exits 0; changelog gate, reference validator (strict), math-label checker, token budget gates, and behavioral contract twins all exit 0; extractor twin parity re-verified on a real transcript after the P3 edits.`

## 3. Acceptance Criteria

- [ ] **AC-1**: The extractor twins are locale-independent (`LC_ALL=C`) and parse `±HH:MM` offsets after fractional seconds correctly; both behaviors are pinned by harness cases and real-transcript parity still holds.
- [ ] **AC-2**: `scripts/strip-benchmark-diff.sh`/`.ps1` drop whole diff file sections for PromptKit artifacts (`.promptkit/`, `PROMPTKIT.md`, `docs/STATE.md`, `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/`, `AGENTS.md`), pass code changes through unchanged, and fail closed on non-diff input, with identical verdicts across twins.
- [ ] **AC-3**: `scripts/aggregate-benchmark-runs.sh`/`.ps1` merge §5 records with a grading TSV into per-run rows and per-arm aggregates (acceptance rate, token/cost/wall-clock/rework means, CPAC over accepted runs) keyed by each record's `condition`, with hand-computed fixture expectations and identical verdicts across twins.
- [ ] **AC-4**: `benchmarks/README.md` states the full protocol (arm parity bindings, blind grading, raw-transcript local-only policy, spend cap, limitations), `benchmarks/tasks/` carries a template plus two synthetic example tasks with frozen rubrics, and `benchmarks/run-ab-benchmark.sh` implements the preflight/run/grade/aggregate flow with a `--preflight-only` mode, clearly marked operator-local.
- [ ] **AC-5**: The new script pairs and harness join both CI syntax lists and both run legs; `CONTRIBUTING.md`'s validation-command lists gain the same entries.
- [ ] **AC-6**: `docs/ARCHITECTURE.md` and `docs/BENCHMARKS.md` reference the benchmark scaffolding; `CHANGELOG.md` [Unreleased] carries the entry with behavior-surface paths; the changelog gate passes against origin/main.
- [ ] **AC-7**: Twin parity: strip and aggregate twins reach identical verdicts (exit codes, machine-line fields) from identical inputs for every fixture case; extractor twins remain byte-identical on the real transcript.

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `N/A - TDD Enforcement Mode disabled`
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `AUTHZ-ab-benchmark-harness-001`
- **Soft Checkpoint**: `N/A - single-session agent-assisted task with human-visible per-commit progress; no timed checkpoint configured`
- **Hard Checkpoint**: `N/A - task executed to awaiting_review inside one session; no 90-minute window crossed without a checkpoint`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `No live host timer or forced-termination capability is available in this agent session; checkpoint timing is advisory only and cannot be mechanically enforced — event-driven checkpoints are the operative control.`

## 5. State and Active Ownership

- **Execution State**: `in_progress`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: `TASK-2026-10-26-ab-benchmark-harness`
- **Start Time**: `2026-10-26 01:56 UTC`
- **Current Actor**: `PromptKit maintainer (agent-assisted session)`
- **Next Action**: `Implement per AC-1..AC-7, run the verification condition, then move Execution State to awaiting_review with per-AC evidence.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `None` | `planned` | `2026-10-26 01:55 UTC` | `agent-assisted session` | Phase 2 plan requested and approved by owner | `ExitPlanMode plan approval in session` |
| `planned` | `ready` | `2026-10-26 01:55 UTC` | `agent-assisted session` | Plan approved; readiness fields complete | `Approved implementation plan in session` |
| `ready` | `in_progress` | `2026-10-26 01:56 UTC` | `agent-assisted session` | Implementation started on feat/ab-benchmark-harness | `branch created at 0d83422` |

### Durable Authorization Checkpoints

<a id="AUTHZ-ab-benchmark-harness-001"></a>

- **Authorization Checkpoint ID**: `AUTHZ-ab-benchmark-harness-001`
- **Declared Boundary**: `full`
- **Verbatim Human Instruction**: `done merging` → (Phase 2 planned and approved via plan mode)
- **Instruction Source**: `Owner message in the 2026-10-26 agent session (merge confirmation; Phase 2 plan approval through the plan-mode flow)`
- **Frozen Task and Milestone Scope**: `Implement the approved A/B benchmark harness plan (Task Record In Scope) as a pull request; live benchmark execution and merge remain human-only.`
- **Batch Authorization Reference**: `N/A`

### Commit Evidence Entries

- **Commit Evidence Entry**: `N/A before commit — this record's commits will be recorded here a posteriori per the two-commit pattern, each citing AUTHZ-ab-benchmark-harness-001 with Authorization Source: owner Phase 2 plan approval.`

## 7. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/extract-commandcode-telemetry.sh` - P3 hardening (LC_ALL=C, fractional-offset parsing)
  - `scripts/extract-commandcode-telemetry.ps1` - twin of the above
  - `scripts/strip-benchmark-diff.sh` - new: PromptKit-artifact diff stripper
  - `scripts/strip-benchmark-diff.ps1` - twin of the above
  - `scripts/aggregate-benchmark-runs.sh` - new: §5 records + grading TSV → per-arm aggregates
  - `scripts/aggregate-benchmark-runs.ps1` - twin of the above
  - `scripts/tests/run-benchmark-tools-tests.sh` - new fixture harness
  - `scripts/tests/run-benchmark-tools-tests.ps1` - twin of the above
  - `scripts/tests/fixtures/benchmark-tools/` - new fixtures
  - `scripts/tests/run-cpac-ingestion-tests.sh` - P3 cases added
  - `scripts/tests/run-cpac-ingestion-tests.ps1` - P3 cases added
  - `benchmarks/README.md` - new: protocol and raw-data policy
  - `benchmarks/tasks/TEMPLATE-task.md` - new: task-spec template
  - `benchmarks/tasks/TASK-BENCH-L1-01.md` - new: synthetic example
  - `benchmarks/tasks/TASK-BENCH-L2-01.md` - new: synthetic example
  - `benchmarks/run-ab-benchmark.sh` - new: operator-local orchestrator
  - `benchmarks/runs/.gitkeep` - new: run-artifact root
  - `.github/workflows/ci.yml` - syntax lists + run steps, both legs
  - `CONTRIBUTING.md` - validation-command lists
  - `docs/ARCHITECTURE.md` - tree entries
  - `docs/BENCHMARKS.md` - §10 pointer to benchmarks/README.md
  - `CHANGELOG.md` - [Unreleased] entry
  - `docs/tasks/TASK-2026-10-26-ab-benchmark-harness.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Pending — the §2 verification condition battery runs before the record moves to awaiting_review; results recorded here per AC at that transition.`
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `N/A before push; the PR run will be recorded here`
- **Review Evidence**: `N/A`
- **Commit Evidence**: `N/A before commit — entries will be recorded a posteriori citing AUTHZ-ab-benchmark-harness-001 (Authorization Source: owner Phase 2 plan approval)`
- **Pull Request Evidence**: `N/A before PR`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

### Completion Gate

- **Completion State**: `N/A - record is in progress`
- **Acceptance Results**: `Pending - AC-1..AC-7 unevaluated at the in_progress state`
- **Changed-File Summary**: `Pending - the Changed Files list above is the implementation target; the summary is written at awaiting_review`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `N/A - completion pending`
