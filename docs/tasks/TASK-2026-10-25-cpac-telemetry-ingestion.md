# Task Record: CPAC Real Telemetry Ingestion

<a id="TASK-2026-10-25-cpac-telemetry-ingestion"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-25-cpac-telemetry-ingestion`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `docs/BENCHMARK-METHODOLOGY.md` §4 Rule 4 and §5 (the standardized telemetry record) — the methodology states that producing an empirical CPAC result "requires an authorized telemetry-ingestion implementation first"; this task is that implementation.
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/596` (Context Economy: live verification), `https://github.com/lowqualityloey/promptkit-os/issues/607` (ceremony/overhead measurement — consumes this pipeline)
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository — CPAC measurement tooling, its fixture tests, CI registration, and the documentation that describes both`
- **Approval Boundary**: `Human approval authorizes local implementation, PR creation, and record updates; merge remains human-only.`
- **Created**: `2026-10-25 (UTC)`

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
  - `.github/workflows/ci.yml` (syntax lists + run steps, both legs)
  - `CONTRIBUTING.md` (validation-command lists)
  - `docs/BENCHMARK-METHODOLOGY.md` (implementation note, §4 Rule 4, §5 mapping/amplifications, §6)
  - `docs/BENCHMARKS.md` (§10 utility description)
  - `docs/specs/SPEC-empirical-benchmark.md` (§5 utility description)
  - `docs/ARCHITECTURE.md` (script-tree inventory)
  - `CHANGELOG.md` ([Unreleased] entries)
  - `docs/tasks/TASK-2026-10-25-cpac-telemetry-ingestion.md`
- **Explicit Non-Goals**:
  - `No benchmark harness/driver, task batch, or A/B protocol implementation (separate later change).`
  - `No hooks-based enforcement or bypass-blocking runtime behavior.`
  - `No extractors for hosts other than Command Code session transcripts (schema v3).`
  - `No measured-input edits (workflows/, protocols/code-quality-gate.md, the four measured templates) — the docs/BENCHMARKS.md provenance anchor and every published figure are unaffected.`
- **Dependencies**: `None (repository-local tooling and documentation)`
- **Risk**: `Low–Medium — changes the CPAC twins' public CLI (bare invocation and default output) and the self-test expectations to align the implemented arithmetic with the documented §2B rework formula; mitigated by fixture tests on both twins and CI registration on both legs.`
- **Verification Condition**: `measure-cpac.sh --self-test and the new run-cpac-ingestion-tests.sh exit 0; changelog gate, reference validator (strict), math-label checker, and staged-secret scan exit 0; behavioral contract twins still pass (no measured input changed).`

## 3. Acceptance Criteria

- [x] **AC-1**: `scripts/measure-cpac.sh`/`.ps1` ingest a §5 telemetry record from a path argument, validate required keys fail-closed (exit 2 with a `CPAC|ERROR|...` diagnostic for unreadable/missing-key/bad-value records), and print a measured scorecard plus a `CPAC|MEASURED|...` machine line.
  - **Result**: `Pass`
  - **Evidence**: `run-cpac-ingestion-tests.sh`/`.ps1` cases 4–8 (valid record machine line `cpac_usd=0.2200`, rejected `cpac_usd=INF`, `MISSING_KEY|rework_loops`, `BAD_VALUE|accepted`, `UNREADABLE`), all green on both twins
- [x] **AC-2**: The implemented rework arithmetic matches the documented §2B formula: `C_rework = Σ(T_loop × P_avg + τ_tool)` — rework-loop tokens priced at the same in/out rates plus the per-loop tool execution cost — replacing the previous flat per-loop penalty; self-tests pin the recomputed exact values.
  - **Result**: `Pass`
  - **Evidence**: `measure-cpac.sh --self-test` (Test 2 = 8.7725 with 12,000/2,100 loop tokens × 3 loops) and `.ps1` `-SelfTest` both green
- [x] **AC-3**: `scripts/extract-commandcode-telemetry.sh`/`.ps1` convert a Command Code session transcript (JSONL schema v3) into the §5 record: per-message usage sums split into successful vs rework turns by a documented turn-walk rule, tool-call totals with a documented best-effort search/edit/verify classification, human interventions (user prompts after the first), wall clock, model, and cache-read tokens reported but excluded from `C_inference`.
  - **Result**: `Pass`
  - **Evidence**: harness case 9 (session fixture: 11,000/2,200 successful, 4,000/800 rework, 1 loop, cache 3,500, 1/1/2/0 classification, wall 60s) green on both twins; both twins additionally verified byte-identical on a real session transcript
- [x] **AC-4**: Fixture harness `scripts/tests/run-cpac-ingestion-tests.sh`/`.ps1` covers: self-test pass, demo flag, bare-usage behavior, valid-record scoring (exact CPAC string), rejected run (INF), missing-key and bad-`accepted` records (exit 2), empty file (exit 2), extraction of a synthetic session with known totals (exact field assertions), and a no-session-line transcript (exit 2).
  - **Result**: `Pass`
  - **Evidence**: 13/13 cases green on both twins (Bash native in WSL; PowerShell via `/usr/bin/pwsh` on the native repository path)
- [x] **AC-5**: Both new scripts, the measure-cpac twins, and the new harness are registered in `ci.yml` (bash `-n` list, Linux run step, PowerShell `$syntaxFiles`, Windows run step) and in `CONTRIBUTING.md`'s validation-command lists; `measure-cpac.sh`/`.ps1`, previously syntax-checked nowhere, join the syntax lists.
  - **Result**: `Pass`
  - **Evidence**: `.github/workflows/ci.yml` syntax lists + Linux/Windows run steps; `CONTRIBUTING.md` Bash and PowerShell validation blocks updated
- [x] **AC-6**: Every "telemetry ingestion is not implemented / a telemetry path exits 2" claim is corrected in `docs/BENCHMARK-METHODOLOGY.md`, `docs/BENCHMARKS.md`, `docs/specs/SPEC-empirical-benchmark.md`, the script headers, and the `docs/ARCHITECTURE.md` inventory; the §5 schema gains the v1 extension fields and a documented mapping/approximations subsection (cache accounting, rework heuristic, tool classification).
  - **Result**: `Pass`
  - **Evidence**: implementation note, §4 Rule 4, §5 example + §5.A conventions subsection, §6 references, `docs/BENCHMARKS.md` §10, `docs/specs/SPEC-empirical-benchmark.md` §5, `docs/ARCHITECTURE.md` script tree, both script headers/usage rewritten; no measured input touched, so the `docs/BENCHMARKS.md` provenance anchor and every published figure are unaffected
- [x] **AC-7**: `CHANGELOG.md` [Unreleased] gains Added and Changed entries with behavior-surface paths (changelog gate passes against origin/main).
  - **Result**: `Pass`
  - **Evidence**: `CHANGELOG.md` [Unreleased] Added + Changed entries; `scripts/check-changelog-entry.sh` run in the verification pass
- [x] **AC-8**: Twin parity: both twins reach identical verdicts (exit codes, machine-line fields) from identical inputs for every fixture case.
  - **Result**: `Pass`
  - **Evidence**: both harnesses 13/13 with the same expected values; real-transcript extraction records byte-identical (`diff` clean) and scoring machine lines byte-identical across twins

## 4. Execution Policy

- **Execution State**: `awaiting_review`
- **Current Actor**: `PromptKit maintainer (agent-assisted session)`
- **Next Action**: `Human review of the pull request; merge remains a human-only authorization.`
- **Verification Evidence**: `Per-AC evidence above; local verification pass (self-tests, both fixture harnesses, changelog gate, reference validator strict, math-label checker, secret scan, behavioral contract twins) recorded on the pull request.`
