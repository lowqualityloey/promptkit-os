# Task Record: Evidence-safe Session Spend Ledger

<a id="TASK-2026-09-21-session-spend-ledger-evidence"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-21-session-spend-ledger-evidence`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub Issue #377 — Evidence-safe Session Spend Ledger`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/377`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-21 00:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Make unmetered session estimates evidence-safe while retaining compact, backward-compatible operational telemetry.`
- **In Scope**:
  - `workflows/checkpoint.md`
  - `templates/state-tracker-template.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-21-session-spend-ledger-evidence.md`
- **Explicit Non-Goals**:
  - `Provider-specific metering integrations or historical ledger backfill.`
  - `CPAC parser, pricing, or scorecard changes.`
  - `Token-efficiency, cost-savings, or avoided-rework claims.`
- **Dependencies**: `Issue #377 and approved implementation plan`
- **Risk**: `Medium - public workflow/template contract; preserve the five-column schema and verify twin behavior plus token budgets.`
- **Verification Condition**: `Bash and PowerShell behavioral contracts, execution-control validation, strict token gates, and reference validation all exit 0.`

## 3. Acceptance Criteria

- [ ] **AC-1**: An unmetered 15-turn session records a `120k–225k` heuristic context-payload range, not a midpoint estimate.
  - **Result**: `Pending`
  - **Evidence**: `Behavioral-contract assertions and source review`
- [ ] **AC-2**: Running totals keep measured tokens separate from heuristic ranges and never call heuristic payload actual spend.
  - **Result**: `Pending`
  - **Evidence**: `Behavioral-contract assertions and source review`
- [ ] **AC-3**: The existing five-column ledger remains compatible while Note records duration, repairs, interventions, verification, and outcome.
  - **Result**: `Pending`
  - **Evidence**: `State template and checkpoint row contract`
- [ ] **AC-4**: Missing evidence remains `not tracked`, and avoided rework remains `not measured` without comparative evidence.
  - **Result**: `Pending`
  - **Evidence**: `Checkpoint evidence rules`
- [ ] **AC-5**: Bash and PowerShell twins enforce equivalent contract assertions and all required gates pass.
  - **Result**: `Pending`
  - **Evidence**: `Verification commands in Section 6`

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `Command wall time is available; forced task termination is unavailable.`

## 5. State and Active Ownership

- **Execution State**: `in_progress`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: `TASK-2026-09-21-session-spend-ledger-evidence`
- **Start Time**: `2026-09-21 00:00 UTC`
- **Current Actor**: `Implementor agent`
- **Next Action**: `Run the required verification battery.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-21 00:00 UTC | Implementor agent | Controlled-work record created | Issue #377 |
| planned | ready | 2026-09-21 00:00 UTC | Implementor agent | Scope and verification plan approved | Issue #377 |
| ready | in_progress | 2026-09-21 00:00 UTC | Implementor agent | Local implementation authorized | Maintainer approval |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/checkpoint.md` - evidence-safe range and process-evidence contract
  - `templates/state-tracker-template.md` - compatible ledger labels and evidence boundary
  - `scripts/tests/run-behavioral-contract-tests.sh` - Bash contract assertions
  - `scripts/tests/run-behavioral-contract-tests.ps1` - PowerShell contract assertions
  - `docs/tasks/TASK-2026-09-21-session-spend-ledger-evidence.md` - canonical task record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `pending`
- **Behavior IDs**: `N/A - exception work type`
- **TDD Intent Register**: `N/A - exception work type`
- **TDD Execution Evidence**: `N/A - exception work type`
- **TDD Exception Verification**: `Documentation contract verified by Bash/PowerShell behavioral suites and repository gates.`
- **CI Evidence**: `pending`
- **Review Evidence**: `pending`
- **Commit Evidence**: `pending`
- **Pull Request Evidence**: `pending`
- **Release Evidence**: `N/A - no release action in scope`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `pending`
- **Changed-File Summary**: `5 files modified or created within Issue #377 scope`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `pending`
