# Task Record: Jev System One Fast Ceremony Classification & Workflow Routing

<a id="TASK-2026-09-19-jev-system-one-router"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-19-jev-system-one-router`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #340 — Jev System One Decision Provider
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/340`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge.`
- **Created**: `2026-09-19 07:45 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Implement zero-lock-in twin companion scripts (`scripts/pk-route.sh` and `scripts/pk-route.ps1`) using TypeSafe AI's Jev (`jev-1.13`) System One API for fast ceremony classification and workflow routing, bounded by the core architectural tenet: "Jev Recommends, PromptKit Decides."
- **In Scope**:
  - `scripts/pk-route.sh` (Bash twin with native curl, 2s timeout, deterministic pre/post-filter, offline fallback)
  - `scripts/pk-route.ps1` (PowerShell 7 twin with Invoke-RestMethod, identical parity)
  - `scripts/tests/run-pk-route-tests.sh` (Bash contract test suite asserting Scenarios 1–5)
  - `scripts/tests/run-pk-route-tests.ps1` (PowerShell contract test suite twin)
  - `workflows/route.md` (Document optional companion scripts under Tooling)
  - `docs/tasks/TASK-2026-09-19-jev-system-one-router.md`
- **Explicit Non-Goals**:
  - Do not create new workflow files (preserves locked 24-workflow count per ADR 0002).
  - Do not introduce mandatory npm packages, node daemons, or Python binaries to PromptKit OS.
  - Do not make Jev the authority over safety classification or authorization.
  - Do not expand Phase 1 into full multi-agent Z0–Z4 context or Turbo providers before proving Phase 1.
- **Dependencies**: GitHub Issue #340 approved direction
- **Risk**: Low - companion tooling with 100% fail-open deterministic offline fallback; zero runtime lock-in.
- **Verification Condition**: `bash scripts/tests/run-pk-route-tests.sh` exits 0; `pwsh scripts/tests/run-pk-route-tests.ps1` exits 0; `validate-references.sh` exits 0; `measure-tokens.sh --strict` PASS.

## 3. Acceptance Criteria

- [x] **AC-1**: Scenario 1 (Missing API Key) — Missing `TYPESAFE_API_KEY` falls back to deterministic offline guidance without error.
- [x] **AC-2**: Scenario 2 (Standard Operation) — Valid input queries Jev, arbitrates against PromptKit policy, and emits standardized Turn 1 banner.
- [x] **AC-3**: Scenario 3 (Jev Unavailable / Timeout) — Timeout (>2s) or network error gracefully degrades to deterministic offline routing without blocking execution.
- [x] **AC-4**: Scenario 4 (Hard Safety Override & Adversarial Phrasing) — Hard triggers (migrations, auth, releases, "production database", "make this live") override any lower probabilistic recommendation (0% Unsafe Underclassifications).
- [x] **AC-5**: Scenario 5 (Malformed Response) — Invalid/malformed JSON is rejected with safe fallback.
- [x] **AC-6**: Bash/PowerShell Parity & Secret Hygiene — Both scripts pass syntax checks and never leak `TYPESAFE_API_KEY` in output.

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `State that live host timing or forced termination is unavailable or limited.`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-19 07:45 UTC`
- **Current Actor**: `Implementor agent`
- **Next Action**: `Review walkthrough and finalize pull request against issue #340`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-19 07:45 UTC | Implementor agent | Record created for Issue #340 Controlled Work | Issue #340 |
| planned | in_progress | 2026-09-19 08:00 UTC | Implementor agent | User approved execution plan; beginning twin implementation | Implementation Plan |
| in_progress | completed | 2026-09-19 08:05 UTC | Implementor agent | All twin scripts, test suites, and reference checks passed | Test execution logs |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/pk-route.sh` - Bash companion script with curl, timeout, deterministic safety floor, and fallback.
  - `scripts/pk-route.ps1` - PowerShell 7 twin with Invoke-RestMethod.
  - `scripts/tests/run-pk-route-tests.sh` - Bash test harness for Scenarios 1–5.
  - `scripts/tests/run-pk-route-tests.ps1` - PowerShell test harness twin.
  - `workflows/route.md` - Documented companion script under Tooling.
  - `docs/tasks/TASK-2026-09-19-jev-system-one-router.md` - Task record.
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**:
  - `pwsh -NoProfile -File scripts/tests/run-pk-route-tests.ps1`: 13 passed, 0 failed.
  - `bash scripts/tests/run-pk-route-tests.sh`: 15 passed, 0 failed.
  - `bash scripts/validate-references.sh .`: 231 files scanned, 0 warnings.
  - `bash scripts/measure-tokens.sh --strict`: Balanced 2500/2500 PASS, Lite 1146/1500 PASS.
  - `bash scripts/tests/run-behavioral-contract-tests.sh`: All scenarios A–M passed.
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `Local harness verification complete`
- **Review Evidence**: `Pending PR review`
- **Commit Evidence**: `N/A before commit`
- **Pull Request Evidence**: `N/A before PR`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
