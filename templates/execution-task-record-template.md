# Task Record: [Short controlled-work objective]

<!-- Replace the example anchor with the immutable Task ID. For an Adaptation record use the `TASK-<task-slug>` form; for a legacy or `none`-profile record preserve `TASK-YYYY-MM-DD-<slug>`. Derived IDs use the same full task slug. -->
<a id="TASK-YYYY-MM-DD-task-slug"></a>

> **Developer-friendly fill-in guide:** A **Required** field must contain a concrete value before the record can move forward. An **Optional** field may be omitted or set to the stated `N/A` value. **Not applicable** means the field does not apply to this work and must include the template's stated reason when one is requested. Keep values short and observable: for example, `Verification Condition: bash scripts/tests/run-fixtures.sh exits 0` is more useful than `Verification Condition: tested`.
>
> **Field status summary:** `Record Type`, `Task ID`, `Specification`, `Owner / Actor`, `Execution Scope`, `Approval Boundary`, `Created`, the objective and boundary fields, execution policy, state and ownership, and completion evidence are **Required**. `External Reference (Optional)` and `Batch Authorization` are **Optional** unless the selected execution mode requires them. Release, checkpoint, handoff, and TDD exception fields are **Required when applicable** and otherwise **Not applicable** with the exact permitted value. Use `None` only when there is genuinely nothing to record, never to hide an unanswered decision.
>
> **TDD (Test-Driven Development) reminder:** The Local Task Record owns `TDD Enforcement Mode`. For disabled Code Work, keep the exact value `N/A - TDD Enforcement Mode disabled`; for Documentation, Configuration, or Research Work, keep `N/A - exception work type`. The test plan is supporting intent only and cannot turn TDD on.

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-<task-slug>` for `sdlc-overlay-v1`; preserve `TASK-YYYY-MM-DD-<slug>` for legacy/no-profile records
- **PromptKit Adaptation Profile** *(Optional; choose `none` for the legacy contract or `sdlc-overlay-v1` to validate the Adaptation fields below)*: `none`
- **Work Type** *(Required for `sdlc-overlay-v1`; choose Code Work, Documentation Work, Configuration Work, or Research Work)*: `Code Work`
- **Planning Record Link** *(Required for `sdlc-overlay-v1`; use the stable planning ID and matching explicit anchor)*: `N/A`
- **Planning Depth Reference** *(Optional for `sdlc-overlay-v1`; use Minimal, Full, or N/A)*: `N/A`
- **Assumption Record Links** *(Optional for `sdlc-overlay-v1`; use comma-separated stable links, None, or N/A)*: `N/A`
- **Specification**: `docs/specs/[specification].md`
- **External Reference (Optional)**: `[Issue, ticket, or N/A]`
- **Owner / Actor**: `[Person, role, or agent]`
- **Execution Scope**: `[Repository, workspace, package, or session boundary]`
- **Approval Boundary**: `[Actions requiring explicit human confirmation]`
- **Created**: `[YYYY-MM-DD HH:MM UTC]`

> This Local Task Source is authoritative for Controlled Work. Planning Record and Assumption Record links provide context only; they do not control readiness, execution state, active ownership, completion, or approval. Existing records remain valid when these optional traceability fields are absent.
>
> The optional `PromptKit Adaptation Profile` selects validation scope: absent or `none` preserves the legacy dated Task ID and existing contract; `sdlc-overlay-v1` requires the Adaptation fields and link targets shown above. The validator checks local evidence only and never authorizes remote, release, deployment, commit, or rollback actions.

## 2. Objective and Boundaries

> When a linked Planning Record uses `Minimal`, map Requested Outcome to **Objective**, Observable Completion Condition to **Acceptance Criteria** and **Verification Condition**, and Scope Boundary to **In Scope** and **Explicit Non-Goals**. These mappings seed the record; every readiness field below remains required before `ready` or `in_progress`.

- **Objective**: `[One observable objective]`
- **In Scope**:
  - `[File, behavior, or deliverable included]`
- **Explicit Non-Goals**:
  - `[File, behavior, release action, or independent concern excluded]`
- **Dependencies**: `[Dependency and owner, or None]`
- **Risk**: `[Low | Medium | High]` - `[Risk summary and mitigation]`
- **Verification Condition**: `[Command, check, artifact assertion, or explicit not-applicable reason]`

## 3. Acceptance Criteria

- [ ] **AC-1**: `[Observable acceptance condition]`
  - **Result**: `[Pending]`
  - **Evidence**: `[Command, check, artifact, or link]`
- [ ] **AC-2**: `[Observable acceptance condition]`
  - **Result**: `[Pending]`
  - **Evidence**: `[Command, check, artifact, or link]`

## 4. Execution Policy

- **Mode**: `Gated Mode` <!-- Use Approved Batch Mode only with a linked Batch Authorization. This is execution policy, not TDD mode. -->
- **TDD Enforcement Mode** *(Required for `sdlc-overlay-v1`; choose disabled or enabled. An absent field defaults to disabled only for legacy records)*: `disabled` <!-- The Task Record owns this field. -->
- **Batch Authorization**: `[docs/tasks/batch-[batch-id].md or N/A]`
- **Soft Checkpoint**: `[Around 60 minutes, configured alternative, or N/A with reason]`
- **Hard Checkpoint**: `[At or before 90 minutes, configured alternative, or N/A with reason]`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `[Observed capability and limitation; do not claim mechanical enforcement when unavailable]`

## 5. State and Active Ownership

- **Execution State**: `planned` <!-- planned | ready | in_progress | checkpoint_due | blocked | paused | handoff_ready | awaiting_review | completed | aborted -->
- **Mapped `pk:tasks` Status**: `To Do` <!-- To Do | In Progress | In Review | Done -->
- **Active Task Pointer**: `[This Task ID while in_progress (gated sub-task work counts), otherwise None]`
- **Start Time**: `[YYYY-MM-DD HH:MM UTC or N/A]`
- **Current Actor**: `[Person, role, or agent]`
- **Next Action**: `[Exactly one prioritized action]`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `[State]` | `[State]` | `[YYYY-MM-DD HH:MM UTC]` | `[Actor]` | `[Reason]` | `[Link or N/A]` |

Canonical transition graph (enforced by `scripts/validate-execution-control.sh` / `.ps1`; every history row must be one of these edges): `N/A`/`None`→`planned`; `planned`→`ready`/`in_progress`/`aborted`; `ready`→`in_progress`/`blocked`/`paused`/`aborted`; `in_progress`→`checkpoint_due`/`blocked`/`paused`/`handoff_ready`/`awaiting_review`/`completed`/`aborted`; `checkpoint_due`→`in_progress`/`blocked`/`paused`/`handoff_ready`/`aborted`; `blocked`→`ready`/`in_progress`/`paused`/`aborted`; `paused`→`ready`/`in_progress`/`aborted`; `handoff_ready`→`in_progress`/`checkpoint_due`/`blocked`/`aborted`; `awaiting_review`→`planned`/`in_progress`/`completed`/`blocked`.

A task cannot enter `ready` until its objective, scope, non-goals, acceptance criteria, dependencies, verification condition, owner/approval boundary, and execution policy are complete. It cannot enter `in_progress` until readiness, start time, execution scope, and active ownership are recorded. Only one task may hold the active pointer in this Execution Scope.

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `[path]` - `[summary]`
- **Scope Change Records**: `[docs/tasks/[task-id].scope-[sequence].md or None]`
- **Checkpoint Records**: `[docs/tasks/[task-id].checkpoint-[sequence].md or None]`
- **Handoff Records**: `[docs/tasks/[task-id].handoff-[sequence].md or None]`
- **Verification Evidence**: `[Commands and results, or structured evidence:verification block per protocols/code-quality-gate.md]`
- **Behavior IDs [Required when enabled]**: `[BEHAVIOR-<task-slug>-<nnn> links]`, `N/A - TDD Enforcement Mode disabled` for disabled Code Work, or `N/A - exception work type` for Documentation, Configuration, or Research Work
- **TDD Intent Register [Required when enabled]**: `[TDD-INTENT-<task-slug>-<nnn>](../tests/<test-plan>.md#TDD-INTENT-<task-slug>-<nnn>)`, `N/A - TDD Enforcement Mode disabled` for disabled Code Work, or `N/A - exception work type` for Documentation, Configuration, or Research Work
- **TDD Execution Evidence [Required when enabled]**: `[TDD-EXEC-<task-slug>-<behavior-seq> entries]`, `N/A - TDD Enforcement Mode disabled` for disabled Code Work, or `N/A - exception work type` for Documentation, Configuration, or Research Work
- **TDD Exception Verification [Required for Documentation, Configuration, or Research Work; Not applicable for Code Work]**: `[Exception verification link and reason]` or `N/A - Code Work`
- **CI Evidence**: `[Provider, workflow/job, run, revision, result, or N/A]`
- **Review Evidence**: `[REVIEW-<review-slug>](../reviews/<review-slug>.md#REVIEW-<review-slug>); reviewer; result; or N/A]`
- **Commit Evidence**: `[Commit SHA and message, or N/A before commit]`
- **Pull Request Evidence**: `[PR URL/number, or N/A before PR]`
- **Release Evidence**: `[Release evaluation/tag/post-release link, or N/A]`
- **Blocker and Resume Condition**: `[Blocker, owner, evidence, and precise resume condition, or None]`

### TDD Mode Branches

Select exactly one branch from the canonical Local Task Record fields:

- **Enabled Code Work [Required]:** Create one intent and one execution block per Behavior ID. Link the test-plan intent to the Local Task Record and record Red, Green, and Refactor results there.
- **Disabled Code Work [Required]:** Record both the TDD Intent Register and TDD Execution Evidence as `N/A - TDD Enforcement Mode disabled`. Do not use the exception path. Normal dependency-ordered milestones, acceptance criteria, test strategy, review, and verification remain required.
- **Documentation, Configuration, or Research Work [Required]:** Record TDD fields as `N/A - exception work type` and provide the TDD Exception Verification link, reason, acceptance, evidence, review, and verification.
- **Ambiguous Work [Required]:** Follow the Code Work branch until Work Type and TDD Enforcement Mode are clarified; do not record an automatic exception.

### TDD Execution Evidence Shape

Use one block per enabled Code Work behavior. The Local Task Record is authoritative for execution evidence; the test plan is a supporting intent reference.

<!-- Replace the example anchors with each immutable execution and behavior ID. -->
<a id="TDD-EXEC-task-slug-001"></a>
<a id="BEHAVIOR-task-slug-001"></a>

- **Execution ID [Required when enabled]**: `TDD-EXEC-<task-slug>-<behavior-seq>`
- **Behavior ID [Required when enabled]**: `BEHAVIOR-<task-slug>-<nnn>`
- **Task Record Link [Required]**: `[TASK-<task-slug>](#TASK-<task-slug>)`
- **Red Result [Required when enabled]**: `[Expected failing assertion, exact runnable command, and observed failing result]`
- **Green Result [Required when enabled]**: `[Passing result from the same Red command for the same Behavior ID]`
- **Refactor Result [Required when enabled]**: `[Passing result from the same Red command after refactor, or an explicit no-refactor reason]`
- **Commands and Results [Required when enabled]**: `[Exact commands and observable results for Red, Green, and Refactor]`
- **Execution Status [Required when enabled]**: `planned | red_recorded | green_recorded | refactor_recorded | exception | blocked | complete`
- **Exception Verification [Not applicable for enabled Code Work]**: `N/A - Code Work`



- **Completion State**: `[awaiting_review | completed | blocked | paused | aborted]`
- **Acceptance Results**: `[AC-1 result; AC-2 result; ...]`
- **Changed-File Summary**: `[Complete summary]`
- **Completion Exception**: `[docs/tasks/[task-id].exception-[sequence].md, approver and reason, or None]`
- **Completion Decision and Timestamp**: `[Decision, actor, and YYYY-MM-DD HH:MM UTC]`

A task may be marked `completed` only after acceptance results, verification evidence, changed-file summary, and required commit evidence are linked. Major milestones also require pull-request evidence or an explicit human-confirmed not-applicable exception. A passing validator does not authorize remote, release, deployment, or rollback actions.
