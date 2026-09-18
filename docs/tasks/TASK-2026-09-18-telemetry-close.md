# Task Record: Bottom-anchored close and single-callout rule

<a id="TASK-2026-09-18-telemetry-close"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-telemetry-close`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #307 — bottom-anchored TL;DR and readable completion format, plus single-callout rule
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/307`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 12:30 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Make completions readable in chat: bottom-anchored TL;DR plus single callout in telemetry-cards.md, with pr.md/commit.md closings pointed at the rule.
- **In Scope**:
  - `protocols/telemetry-cards.md` - bottom-anchored close, readability rules, single-callout rule
  - `workflows/pr.md` - closing qualified by the single-callout rule
  - `workflows/commit.md` - closing qualified by the single-callout rule
  - `docs/tasks/TASK-2026-09-18-telemetry-close.md` (this record)
  - `docs/BENCHMARKS.md` - figure sync only if the contract suite mandates it
- **Explicit Non-Goals**:
  - No telemetry content changes; no new workflows; no validator or script changes
- **Dependencies**: Issue #307 plus approved comment scope (single callout, template closings in scope)
- **Risk**: Low-Medium - protocol wording may be behavioral-contract asserted; edits must keep suite green
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; behavioral 178/178; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: Protocol mandates bottom-anchored TL;DR plus single callout as the completion close
- [x] **AC-2**: pr.md/commit.md closings reference the rule instead of mandating dual callouts
- [x] **AC-3**: Behavioral contract suite passes 178/178
- [x] **AC-4**: `validate-execution-control.sh --root . --strict` VALID

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

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-18 12:30 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 12:30 UTC | Implementor agent | Record created for Issue #307 Controlled Work | Issue #307 |
| planned | ready | 2026-09-18 12:30 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #307 | This record |
| ready | in_progress | 2026-09-18 12:30 UTC | Implementor agent | Branch `docs/telemetry-close-307`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 13:00 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `protocols/telemetry-cards.md` - bottom-anchored close, readability, single-callout rule
  - `workflows/pr.md` - closing qualified by the rule
  - `workflows/commit.md` - closing qualified by the rule
  - `docs/tasks/TASK-2026-09-18-telemetry-close.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=22 (0 diagnostics); behavioral 178/178; playbook 11/11 (one transient blip traced to a parallel edit race, clean on rerun); references 0 warnings; measure-tokens --strict PASS (Balanced 2498<=2500, Lite 1146<=1500)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: pending PR run (Linux + Windows)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: pending commit on branch `docs/telemetry-close-307`
- **Pull Request Evidence**: pending PR referencing Issue #307
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: AC-1 Complete (bottom-anchored close, readability rules, single-callout rule); AC-2 Complete (pr/commit closings qualified); AC-3 Complete (178/178, zero figure rot); AC-4 Complete (VALID|RECORDS=22, 0 diagnostics)
- **Changed-File Summary**: 4 files; telemetry-cards close rules, pr/commit closing qualifiers, Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-18 13:00 UTC`
