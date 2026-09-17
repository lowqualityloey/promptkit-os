# Task Record: README control-plane rewrite per Issue #283

<a id="TASK-2026-09-18-readme-rewrite"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-readme-rewrite`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #283 — restructure README.md from workflow-catalog layout into control-plane-first technical product document
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/283`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 00:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Restructure README.md from a workflow-catalog layout into a control-plane-first technical product document. Lead with architecture diagram, problem statement, and core idea. Remove workflow count as headline differentiator. Route depth to specialist docs.
- **In Scope**:
  - `README.md` - control-plane-first rewrite (hero framing, problem, architecture diagram, ceremony levels, docs table)
  - `docs/tasks/TASK-2026-09-18-readme-rewrite.md` (this record)
- **Explicit Non-Goals**:
  - No changes to workflows, protocols, templates, or scripts
  - No changes to other doc files (QUICKSTART, ARCHITECTURE, BENCHMARKS, COMPARISONS, stacks, recipes)
  - No release, tag, or deployment actions
- **Dependencies**: Issue #283 approved direction; main at `e682680`
- **Risk**: Low - README wording is public contract; documentation-only change, no runtime behavior
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; `measure-tokens.sh --strict` PASS; behavioral 178/178; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: First 3 sections communicate control-plane architecture, not workflow count
- [x] **AC-2**: validate-references.sh exits 0
- [x] **AC-3**: measure-tokens.sh --strict passes (Balanced <= 2500, Lite <= 1500)
- [x] **AC-4**: run-behavioral-contract-tests.sh passes 178/178
- [x] **AC-5**: run-playbook-contract-tests.sh passes 11/11

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
- **Start Time**: `2026-09-18 00:00 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision on PR #284`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 00:00 UTC | Implementor agent | Record created for Issue #283 Controlled Work | Issue #283 |
| planned | ready | 2026-09-18 00:00 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #283 | This record |
| ready | in_progress | 2026-09-18 00:00 UTC | Implementor agent | Branch `docs/readme-control-plane-rewrite`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-17 23:30 UTC | Implementor agent | README rewrite complete; PR #284 opened | PR #284 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `README.md` - control-plane-first restructure per Issue #283
  - `docs/tasks/TASK-2026-09-18-readme-rewrite.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: PR-battery per PR description: validate-references.sh PASS (0 broken links, 0 warnings); measure-tokens.sh --strict PASS (Balanced 2498<=2500, Lite 1146<=1500); run-behavioral-contract-tests.sh 178/178; run-playbook-contract-tests.sh 11/11
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: PR #284 CI re-run pending after canonical record repair (Linux + Windows)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: branch `docs/readme-control-plane-rewrite` commit `404ede7`
- **Pull Request Evidence**: PR #284 `docs/readme-control-plane-rewrite` -> main, closes #283
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: AC-1 Complete (control-plane hero, problem, architecture diagram lead); AC-2 Complete (references 0 errors per PR battery); AC-3 Complete (Balanced 2498, Lite 1146); AC-4 Complete (178/178); AC-5 Complete (11/11)
- **Changed-File Summary**: 2 files; README.md restructure (+128/-185) plus this canonical Task Record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-17 23:30 UTC`
