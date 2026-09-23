# Task Record: Dual-Mode Telemetry & Single-Callout Invariant per Issue #316

<a id="TASK-2026-09-18-dual-mode-telemetry"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-dual-mode-telemetry`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #316 — standardize dual-mode telemetry, single-callout invariant, and anti-glitch visual formatting
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/316`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 00:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Standardize visual output across both Markdown-capable environments (Cursor, VS Code, Antigravity) and non-markdown CLI terminals (Cline, OpenCode, Aider), enforcing the Single-Callout Invariant and universal anti-glitch progress bars.
- **In Scope**:
  - `protocols/telemetry-cards.md`
  - `templates/agent-directive-template.md`
  - `templates/agent-directive-lite-template.md`
  - `workflows/checkpoint.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-18-dual-mode-telemetry.md`
- **Explicit Non-Goals**:
  - No changes to prompt routing logic or ceremony level thresholds
  - No external background daemons or network-dependent badges
  - No release, tag, or deployment actions
- **Dependencies**: Issue #316 approved direction; main at `e682680`
- **Risk**: Low - visual formatting and protocol clarity; documentation and protocol enhancements
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; `measure-tokens.sh --strict` PASS; behavioral 187/187; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: `protocols/telemetry-cards.md` codifies the Single-Callout Invariant (max 1 callout per turn; priority IMPORTANT > WARNING > TIP).
- [x] **AC-2**: Progress bars in both Markdown and CLI modes use the anti-glitch square standard `[■■■■■■■■□□]`; shaded characters (`▓`, `▒`, `░`) are banned.
- [x] **AC-3**: CLI mode specifies ceiling and floor boxes (`╔═ <EMOJI><TITLE> ═════╗` / `╚═════╝`) with zero vertical side-walls (`║`).
- [x] **AC-4**: Opening sections in Markdown mode specify two-column tables (`| What Changed | Verification Evidence |`) and descriptive links (`👉 [text](url)`).
- [x] **AC-5**: Strict token budget gate passes (Balanced <= 2500, Lite <= 1500).
- [x] **AC-6**: Behavioral contract tests pass in both Bash and PowerShell twins (187/187).

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `Live host timing and forced generation termination are unavailable in this host; checkpoint thresholds are protocol discipline, not mechanical enforcement.`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-18 00:00 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision on PR #317`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 00:00 UTC | Implementor agent | Record created for Issue #316 Controlled Work | Issue #316 |
| planned | ready | 2026-09-18 00:00 UTC | Implementor agent | Readiness complete; scope approved in Issue #316 | This record |
| ready | in_progress | 2026-09-18 00:00 UTC | Implementor agent | Branch `feat/dual-mode-telemetry-formatting`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 00:30 UTC | Implementor agent | Telemetry protocol and behavioral tests complete; PR #317 opened | PR #317 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `protocols/telemetry-cards.md`
  - `templates/agent-directive-template.md`
  - `templates/agent-directive-lite-template.md`
  - `workflows/checkpoint.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-18-dual-mode-telemetry.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: validate-references.sh PASS (0 broken links, 0 warnings); measure-tokens.sh --strict PASS (Balanced 2498<=2500, Lite 1146<=1500); run-behavioral-contract-tests.sh 187/187; run-behavioral-contract-tests.ps1 187/187; run-playbook-contract-tests.sh 11/11; validate-execution-control.sh VALID.
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation/Protocol Work`
- **CI Evidence**: PR #317 CI run
- **Review Evidence**: pending human PR review
- **Commit Evidence**: branch `feat/dual-mode-telemetry-formatting` commit `f16d992`
- **Pull Request Evidence**: PR #317 `feat/dual-mode-telemetry-formatting` -> main, closes #316
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 through AC-6 Complete
- **Changed-File Summary**: 7 files modified/created per commit `f16d992`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-18 00:30 UTC`
