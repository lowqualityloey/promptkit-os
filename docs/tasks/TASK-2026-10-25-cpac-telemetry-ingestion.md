# Task Record: CPAC Real Telemetry Ingestion

<a id="TASK-2026-10-25-cpac-telemetry-ingestion"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-25-cpac-telemetry-ingestion`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Code Work`
- **Specification**: `docs/BENCHMARK-METHODOLOGY.md` §4 Rule 4 and §5 (the standardized telemetry record) — the methodology states that producing an empirical CPAC result "requires an authorized telemetry-ingestion implementation first"; this task is that implementation.
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/596`, `https://github.com/lowqualityloey/promptkit-os/issues/607`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository — CPAC measurement tooling, its fixture tests, CI registration, and the documentation that describes both`
- **Approval Boundary**: `Human approval authorizes local implementation, PR creation, and record updates; merge remains human-only.`
- **Created**: `2026-10-25 09:45 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Implement real CPAC telemetry ingestion: a Command Code session-transcript extractor that emits the §5 standardized telemetry record, and a measure-cpac scoring path that consumes such records fail-closed — replacing the shipped simulated-only scorecard whose telemetry path was rejected with exit 2.`
- **In Scope**:
  - `scripts/measure-cpac.sh`
  - `scripts/measure-cpac.ps1`
  - `scripts/extract-commandcode-telemetry.sh` (new)
  - `scripts/extract-commandcode-telemetry.ps1` (new)
  - `scripts/tests/run-cpac-ingestion-tests.sh` (new)
  - `scripts/tests/run-cpac-ingestion-tests.ps1` (new)
  - `scripts/tests/fixtures/cpac-ingestion/` (new)
  - `.github/workflows/ci.yml`
  - `CONTRIBUTING.md`
  - `docs/BENCHMARK-METHODOLOGY.md`
  - `docs/BENCHMARKS.md`
  - `docs/specs/SPEC-empirical-benchmark.md`
  - `docs/ARCHITECTURE.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-10-25-cpac-telemetry-ingestion.md`
- **Explicit Non-Goals**:
  - `No benchmark harness/driver, task batch, or A/B protocol implementation (separate later change).`
  - `No hooks-based enforcement or bypass-blocking runtime behavior.`
  - `No extractors for hosts other than Command Code session transcripts (schema v3).`
  - `No measured-input edits (workflows/, protocols/code-quality-gate.md, the four measured templates) — the docs/BENCHMARKS.md provenance anchor and every published figure are unaffected.`
- **Dependencies**: `None`
- **Risk**: `Medium` - `Changes the CPAC twins' public CLI (bare invocation and default output) and the self-test expectations to align the implemented arithmetic with the documented §2B rework formula; mitigated by the 13-case fixture harness on both twins and CI registration on both legs.`
- **Verification Condition**: `bash scripts/measure-cpac.sh --self-test exits 0; bash scripts/tests/run-cpac-ingestion-tests.sh and the .ps1 twin exit 0 (13/13 each); bash scripts/validate-execution-control.sh --root . --strict --authorization-baseline origin/main exits 0; changelog gate, reference validator (strict), math-label checker, token budget gates, and behavioral contract twins all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: `scripts/measure-cpac.sh`/`.ps1` ingest a §5 telemetry record from a path argument, validate required keys fail-closed (exit 2 with a `CPAC|ERROR|...` diagnostic for unreadable/missing-key/bad-value records), and print a measured scorecard plus a `CPAC|MEASURED|...` machine line.
  - **Result**: `Pass`
  - **Evidence**: `run-cpac-ingestion-tests.sh`/`.ps1` scoring cases (valid record machine line `cpac_usd=0.2200`, rejected `cpac_usd=INF`, `MISSING_KEY`, `BAD_VALUE`, `UNREADABLE`), green on both twins
- [x] **AC-2**: The implemented rework arithmetic matches the documented §2B formula: `C_rework = Σ(T_loop × P_avg + τ_tool)` — rework-loop tokens priced at the same in/out rates plus the per-loop tool execution cost — replacing the previous flat per-loop penalty; self-tests pin the recomputed exact values.
  - **Result**: `Pass`
  - **Evidence**: `measure-cpac.sh --self-test` (Test 2 = 8.7725 with 12,000/2,100 loop tokens × 3 loops) and `.ps1` `-SelfTest` both green
- [x] **AC-3**: `scripts/extract-commandcode-telemetry.sh`/`.ps1` convert a Command Code session transcript (JSONL schema v3) into the §5 record: per-message usage sums split into successful vs rework turns by a documented turn-walk rule, tool-call totals with a documented best-effort search/edit/verify classification, human interventions (user prompts after the first), wall clock, model, and cache-read tokens reported but excluded from `C_inference`.
  - **Result**: `Pass`
  - **Evidence**: harness extraction cases green on both twins; both twins byte-identical on a real session transcript
- [x] **AC-4**: Fixture harness `scripts/tests/run-cpac-ingestion-tests.sh`/`.ps1` covers: self-test pass, demo flag, bare-usage behavior, valid-record scoring (exact CPAC string), rejected run (INF), missing-key and bad-`accepted` records (exit 2), empty file (exit 2), extraction of a synthetic session with known totals (exact field assertions), and a no-session-line transcript (exit 2).
  - **Result**: `Pass`
  - **Evidence**: 13/13 cases green on both twins (Bash native in WSL; PowerShell via `/usr/bin/pwsh` on the native repository path)
- [x] **AC-5**: Both new scripts, the measure-cpac twins, and the new harness are registered in `ci.yml` (bash `-n` list, Linux run step, PowerShell `$syntaxFiles`, Windows run step) and in `CONTRIBUTING.md`'s validation-command lists; `measure-cpac.sh`/`.ps1`, previously syntax-checked nowhere, join the syntax lists.
  - **Result**: `Pass`
  - **Evidence**: `.github/workflows/ci.yml` syntax lists + Linux/Windows run steps; `CONTRIBUTING.md` Bash and PowerShell validation blocks updated
- [x] **AC-6**: Every "telemetry ingestion is not implemented / a telemetry path exits 2" claim is corrected in `docs/BENCHMARK-METHODOLOGY.md`, `docs/BENCHMARKS.md`, `docs/specs/SPEC-empirical-benchmark.md`, the script headers, and the `docs/ARCHITECTURE.md` inventory; the §5 schema gains the v1 extension fields and a documented mapping/approximations subsection (cache accounting, rework heuristic, tool classification).
  - **Result**: `Pass`
  - **Evidence**: implementation note, §4 Rule 4, §5 example + §5.A conventions subsection, §6 references, `docs/BENCHMARKS.md` §10, SPEC §5, `docs/ARCHITECTURE.md` script tree, both script headers/usage rewritten; no measured input touched, so the `docs/BENCHMARKS.md` provenance anchor and every published figure are unaffected
- [x] **AC-7**: `CHANGELOG.md` [Unreleased] gains Added and Changed entries with behavior-surface paths (changelog gate passes against origin/main).
  - **Result**: `Pass`
  - **Evidence**: `CHANGELOG.md` [Unreleased] Added + Changed entries; `scripts/check-changelog-entry.sh` → `CHANGELOG_GATE|PASS`
- [x] **AC-8**: Twin parity: both twins reach identical verdicts (exit codes, machine-line fields) from identical inputs for every fixture case.
  - **Result**: `Pass`
  - **Evidence**: both harnesses 13/13 with the same expected values; real-transcript extraction records byte-identical (`diff` clean) and scoring machine lines byte-identical across twins

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `N/A - TDD Enforcement Mode disabled`
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `AUTHZ-cpac-telemetry-ingestion-001`
- **Soft Checkpoint**: `N/A - single-session agent-assisted task with human-visible per-commit progress; no timed checkpoint configured`
- **Hard Checkpoint**: `N/A - task executed to awaiting_review inside one session; no 90-minute window crossed without a checkpoint`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `No live host timer or forced-termination capability is available in this agent session; checkpoint timing is advisory only and cannot be mechanically enforced — event-driven checkpoints are the operative control.`

## 5. State and Active Ownership

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-25 10:48 UTC`
- **Current Actor**: `PromptKit maintainer (agent-assisted session)`
- **Next Action**: `Owner review of PR #692; merge remains a human-only authorization.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `None` | `planned` | `2026-10-25 09:45 UTC` | `agent-assisted session` | Implementation plan requested by owner | `ExitPlanMode plan approval in session` |
| `planned` | `ready` | `2026-10-25 09:58 UTC` | `agent-assisted session` | Plan approved by owner; readiness fields complete | `Approved implementation plan in session` |
| `ready` | `in_progress` | `2026-10-25 10:48 UTC` | `agent-assisted session` | First implementation commit landed | `8b58f79 docs(tasks): record cpac telemetry ingestion task` |
| `in_progress` | `awaiting_review` | `2026-10-25 11:12 UTC` | `agent-assisted session` | All ACs evidenced; PR opened | `ddc9ade; https://github.com/lowqualityloey/promptkit-os/pull/692` |

### Pending Human Actions

| Pending Action ID | Reason and Required Condition | Owner | Status | Authority Scope | Resume Condition |
|---|---|---|---|---|---|
| `PENDING-cpac-telemetry-ingestion-01` | Merge of PR #692 awaits owner review of the CI-green branch | `PromptKit maintainer` | `pending` | `Merge authorization for PR #692 only` | `Owner merge decision on PR #692` |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/measure-cpac.sh` - §5 record ingestion, §2B formula alignment, price flags, `--demo`
  - `scripts/measure-cpac.ps1` - twin of the above
  - `scripts/extract-commandcode-telemetry.sh` - new Command Code transcript → §5 record extractor
  - `scripts/extract-commandcode-telemetry.ps1` - twin of the above
  - `scripts/tests/run-cpac-ingestion-tests.sh` - new 13-case fixture harness
  - `scripts/tests/run-cpac-ingestion-tests.ps1` - twin of the above
  - `scripts/tests/fixtures/cpac-ingestion/` - 6 fixtures with hand-computed totals
  - `.github/workflows/ci.yml` - syntax lists + run steps, both legs
  - `CONTRIBUTING.md` - validation-command lists
  - `docs/BENCHMARK-METHODOLOGY.md` - implementation note, §4 Rule 4, §5 example, new §5.A, §6
  - `docs/BENCHMARKS.md` - §10 utility description
  - `docs/specs/SPEC-empirical-benchmark.md` - §5 utility description
  - `docs/ARCHITECTURE.md` - script-tree inventory
  - `CHANGELOG.md` - [Unreleased] Added + Changed entries
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `bash scripts/measure-cpac.sh --self-test → pass; run-cpac-ingestion-tests.sh 13/13; run-cpac-ingestion-tests.ps1 13/13 (/usr/bin/pwsh, native path); check-changelog-entry.sh → CHANGELOG_GATE|PASS; validate-references.sh . --strict → pass; check-math-labels.sh --root . → pass; measure-tokens.sh --strict + measure-per-task-tokens.sh --strict → pass (anchor 7ab8b50 figures unaffected); run-behavioral-contract-tests.sh → 560/560; extraction→scoring verified end-to-end on a real Command Code transcript with byte-identical twin outputs. Known red at ddc9ade: repository self-validation (execution-control) failed on this record's schema — remediated in the fix commits atop it, validator re-run recorded below.`
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `GitHub Actions run 40187961965 (PR #692 @ ddc9ade): behavioral/security/shard legs green; Linux/Windows Validate (Core) red on Self-Validate Repository Execution Records (ERRORS=30, this record's schema) — fix commits pushed; re-run pending at record time`
- **Review Evidence**: `N/A - external audit (Arena.ai, 2026-10-25: REQUEST CHANGES, 4×P1 + 2×P2, verified against source by this agent) is tracked in the PR conversation; remediation is in the fix commits atop ddc9ade`
- **Commit Evidence**: `Commit Evidence Entries below cover 8b58f79..ddc9ade; the fix commits atop ddc9ade will have their entries recorded in the next docs-only commit (two-commit pattern)`
- **Pull Request Evidence**: `https://github.com/lowqualityloey/promptkit-os/pull/692`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

### Durable Authorization Checkpoints

<a id="AUTHZ-cpac-telemetry-ingestion-001"></a>

- **Authorization Checkpoint ID**: `AUTHZ-cpac-telemetry-ingestion-001`
- **Declared Boundary**: `full`
- **Verbatim Human Instruction**: `create implementation plan` → (plan approved) → `go` → (fix plan after audit) → `go`
- **Instruction Source**: `Owner messages in the 2026-10-25 agent session (plan request, plan approval, implementation go, remediation go)`
- **Frozen Task and Milestone Scope**: `Implement the approved CPAC real-telemetry-ingestion plan (Task Record In Scope); remediate the audited defects on the same branch; PR + record updates authorized; merge, release, and deployment remain human-only.`
- **Batch Authorization Reference**: `N/A`

### Commit Evidence Entries

- **Commit Evidence Entry**: `8b58f79 docs(tasks): record cpac telemetry ingestion task; Authorization Checkpoint Reference: AUTHZ-cpac-telemetry-ingestion-001; Authorization Source: owner plan approval ("create implementation plan" → approved plan)`
- **Commit Evidence Entry**: `d70332b feat(measure): ingest standardized telemetry in cpac twins; Authorization Checkpoint Reference: AUTHZ-cpac-telemetry-ingestion-001; Authorization Source: owner implementation go`
- **Commit Evidence Entry**: `a45549a feat(measure): extract commandcode session telemetry; Authorization Checkpoint Reference: AUTHZ-cpac-telemetry-ingestion-001; Authorization Source: owner implementation go`
- **Commit Evidence Entry**: `b913df1 test(cpac): ingestion fixture harness and ci wiring; Authorization Checkpoint Reference: AUTHZ-cpac-telemetry-ingestion-001; Authorization Source: owner implementation go`
- **Commit Evidence Entry**: `ddc9ade docs(benchmarks): implemented cpac ingestion status and mapping; Authorization Checkpoint Reference: AUTHZ-cpac-telemetry-ingestion-001; Authorization Source: owner implementation go`

### Completion Gate

- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass; AC-5 Pass; AC-6 Pass; AC-7 Pass; AC-8 Pass`
- **Changed-File Summary**: `15 files: 2 CPAC twins (§5 ingestion, §2B formula, price flags, --demo), 2 new extractor twins, 2 new harness twins, 6 fixtures, ci.yml, CONTRIBUTING.md, 4 docs, CHANGELOG.md`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Pending owner review — merge decision is a human-only authorization`
