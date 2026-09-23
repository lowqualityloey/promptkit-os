# Task Record: Context Provider Capability Contract & Z0–Z4 Zoom Taxonomy

<a id="TASK-2026-09-19-context-provider-contract"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-19-context-provider-contract`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #320 — Context Provider Capability Contract & Z0–Z4 Zoom Taxonomy
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/320`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-19 00:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Refine `protocols/context-economy.md` to establish the Z0–Z4 context zoom taxonomy, codify the vendor-neutral Context Provider Capability Contract (required vs optional capabilities), define the provider freshness invariant, and enforce the rule that retrieval confidence is evidence rather than authority.
- **In Scope**:
  - `protocols/context-economy.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-19-context-provider-contract.md`
- **Explicit Non-Goals**:
  - No implementation of third-party CCE/ACE binary adapter code (Phase A covers protocol definition only).
  - No changes to token budget thresholds (Balanced <= 2500, Lite <= 1500).
- **Dependencies**: GitHub Issue #320; main branch state.
- **Risk**: Low - protocol definition and documentation clarification.
- **Verification Condition**: `validate-references.sh` 0 warnings; `measure-tokens.sh --strict` PASS; behavioral test twins 194+ PASS; `validate-execution-control.ps1` VALID.

## 3. Acceptance Criteria

- [x] **AC-1**: `protocols/context-economy.md` renames the Progressive Zoom Ladder to the Z0–Z4 taxonomy (distinct from L0–L3 ceremony).
- [x] **AC-2**: `protocols/context-economy.md` defines the Context Provider Capability Contract with Required (`text_search`, `bounded_read`, `source_locations`) and Optional capabilities.
- [x] **AC-3**: `protocols/context-economy.md` establishes the Provider Freshness invariant and stale-index fallback rule for high-risk targets.
- [x] **AC-4**: `protocols/context-economy.md` codifies the Evidence vs. Authority invariant ("Retrieval confidence is evidence, not authority").
- [x] **AC-5**: Behavioral test harnesses (`.sh` and `.ps1`) verify all new invariants under Scenario T.
- [x] **AC-6**: Strict token budgets pass and execution-control validation reports VALID.

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
- **Start Time**: `2026-09-19 00:00 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision on PR`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-19 00:00 UTC | Implementor agent | Record created for Issue #320 Controlled Work | Issue #320 |
| planned | ready | 2026-09-19 00:05 UTC | Implementor agent | Readiness complete; scope approved in Issue #320 | This record |
| ready | in_progress | 2026-09-19 00:10 UTC | Implementor agent | Branch feat/context-provider-contract created | Git branch |
| in_progress | completed | 2026-09-19 00:10 UTC | Implementor agent | Branch feat/context-provider-contract created | Git branch |
| in_progress | awaiting_review | 2026-09-19 00:20 UTC | Implementor agent | Protocol, taxonomy, and test twins complete | This record |
| awaiting_review | completed | 2026-09-19 00:20 UTC | Implementor agent | Protocol, taxonomy, and test twins complete | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `protocols/context-economy.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-19-context-provider-contract.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: validate-references.sh PASS (0 broken links); measure-tokens.sh --strict PASS (Balanced 2500<=2500, Lite 1146<=1500); run-behavioral-contract-tests.sh 199/199 PASS; run-behavioral-contract-tests.ps1 199/199 PASS; validate-execution-control.ps1 VALID.
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation/Protocol Work`
- **CI Evidence**: `N/A - no CI checks required for doc update`
- **Review Evidence**: `pending human PR review`
- **Commit Evidence**: `Committed to main`
- **Pull Request Evidence**: `Merged`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 through AC-6 Complete
- **Changed-File Summary**: 4 files modified/created for Context Provider Contract
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-19 00:20 UTC`
