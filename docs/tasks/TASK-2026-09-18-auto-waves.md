# Task Record: Parallel waves with bounded auto-refine in pk:auto

<a id="TASK-2026-09-18-auto-waves"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-auto-waves`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #314 — parallel waves with bounded auto-refine for pk:auto and Turbo
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/314`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 16:30 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Add bounded parallel wave execution with auto-refine to auto.md as a Turbo-gated mode (no new workflow files): strict eligibility, wave boundary, per-task verify, max-2 refine, human gates, refine evidence convention.
- **In Scope**:
  - `workflows/auto.md` - wave mode section, refine loop, flag surface, Turbo gate, evidence convention
  - `docs/tasks/TASK-2026-09-18-auto-waves.md` (this record)
  - `docs/BENCHMARKS.md` - figure sync only if the contract suite mandates it
- **Explicit Non-Goals**:
  - No new workflow files; no scheduler/daemon; no validator or script changes
  - No task-sensitive auto-routing (v1.9 direction, unscoped)
- **Dependencies**: Issue #314 plus amendments (eligibility, wave boundary, budget linkage)
- **Risk**: Medium - auto.md wording is behavioral-contract asserted; edits must keep suite green
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; behavioral 178/178; playbook 11/11; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: Strictly eligible tasks run in parallel waves and merge in dependency order
- [x] **AC-2**: At most 2 refine attempts precede human escalation with diagnostics
- [x] **AC-3**: Unsupported hosts and non-Turbo profiles fall back to sequential review-ready
- [x] **AC-4**: Behavioral contract suite passes (210/210 at closure; 178/178 at record creation)

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
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-18 16:30 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `None - wave mode merged (#315); hardening under #329`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 16:30 UTC | Implementor agent | Record created for Issue #314 Controlled Work | Issue #314 |
| planned | ready | 2026-09-18 16:30 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #314 | This record |
| ready | in_progress | 2026-09-18 16:30 UTC | Implementor agent | Branch `feat/auto-waves-314`; pointer assumed | This record |
| in_progress | completed | 2026-09-19 02:09 UTC | PromptKit maintainer | Wave mode merged as `aa0ec5c` (#315); ACs verified against `main` + #329 hardening | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-09-18-auto-waves.md` - this record (closed)
  - Wave mode implementation itself: `workflows/auto.md` via `aa0ec5c` (#315); hardening via branch `docs/auto-reconciliation-329` (#329: explicit 3-strike model, #258 link, pre-flight checklist + phrase-sheet recipes, strike assertion in contract twins)
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Battery green at closure on branch `docs/auto-reconciliation-329`: self-validator VALID|RECORDS=27 (0 diagnostics); behavioral 210/210 (includes new Strike-1 assertion); playbook suite green; references 0 warnings; measure-tokens --strict PASS (Balanced 2500<=2500, Lite 1146<=1500); per-task baselines PASS all profiles
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: pending PR run (Linux + Windows)
- **Review Evidence**: maintainer review in session 2026-09-19 (two-axis review + external cross-review, findings F1–F6)
- **Commit Evidence**: implementation `aa0ec5c` (#315); hardening commits `fd9b336`, `17b1770`, `9ab295c` on branch `docs/auto-reconciliation-329`
- **Pull Request Evidence**: PR #315 merged (Issue #314); hardening PR pending
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 Complete (wave section + eligibility + checklist recipe); AC-2 Complete (explicit Strike 1/2/3 model, max 2 refines); AC-3 Complete (sequential fallback text intact); AC-4 Complete (210/210)
- **Changed-File Summary**: Task Record closed; implementation previously merged; hardening in #329 branch
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `completed; PromptKit maintainer; 2026-09-19 02:09 UTC`
