# Task Record: Issue #792 — divergent pk:brainstorm mode and Balanced read-only parallelism

<a id="TASK-2026-11-26-issue-792-brainstorm-parallelism"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-26-issue-792-brainstorm-parallelism`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Code Work`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/792`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: `Worktree dsh-a5b9d67e-25a7 (branch feat/792-brainstorm) for lowqualityloey/promptkit-os`
- **Approval Boundary**: `Local implementation, verification, and commits only. Push, pull request, merge, tag, and release actions are not authorized without explicit human confirmation.`
- **Created**: `2026-11-26 06:10 UTC`

## 2. Objective and Boundaries

- **Objective**: `Ship issue #792: add a zero-artifact divergent pk:brainstorm pre-intake that hands one promoted direction into pk:plan, and allow parallel read-only subagents in Balanced while keeping --turbo --experimental, the wave pre-flight checklist and worktree isolation for parallel write waves.`
- **In Scope**:
  - `workflows/plan.md`
  - `workflows/route.md`
  - `workflows/auto.md`
  - `workflows/research.md`
  - `protocols/subagent-delegation.md`
  - `protocols/setup.md`
  - `docs/WORKFLOW-MAP.md`
  - `docs/TURBO-WAVES-GUIDE.md`
  - `README.md`
  - `scripts/validate-references.sh`
  - `scripts/validate-references.ps1`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/BENCHMARKS.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-26-issue-792-brainstorm-parallelism.md`
- **Explicit Non-Goals**:
  - `No new workflow file and no change to the locked 26-workflow registry; pk:brainstorm is a documented alias for the divergent pre-intake section of workflows/plan.md.`
  - `No change to templates/agent-directive-template.md or templates/agent-directive-lite-template.md, so the measured directive figures stay unchanged.`
  - `No relaxation of the parallel write-wave gates: --turbo --experimental, the wave pre-flight checklist and worktree isolation remain mandatory for concurrent edits.`
  - `No push, pull request, merge, tag, or release action.`
- **Dependencies**: `Issue #786 workflow registry and validate-references inventory are already merged on main; no other dependency.`
- **Risk**: `Medium - the alias must satisfy the reference validator's orphan-trigger scan, and the read-only carve-out must not weaken the write-wave isolation gates that ADR 0002 protects.`
- **Verification Condition**: `bash scripts/validate-execution-control.sh --root . --strict exits 0; bash scripts/validate-references.sh . --strict exits 0 with zero trigger warnings; bash scripts/tests/run-token-budget-tests.sh exits 0; bash scripts/measure-tokens.sh --strict exits 0; bash scripts/measure-ceremony-overhead.sh --strict exits 0; bash scripts/measure-tokenizer-delta.sh --strict exits 0; bash scripts/tests/run-doctor-tests.sh reports 52 passed and 0 failed; bash scripts/tests/run-behavioral-contract-tests.sh reports 0 failed.`

## 3. Acceptance Criteria

- [ ] **AC-1**: `pk:brainstorm is a divergent pre-intake with zero mandatory artifacts, bounded by size class, and a clean promotion handoff that runs pk:plan intake from exactly one promoted direction.`
  - **Result**: `Pending`
  - **Evidence**: `workflows/plan.md Divergent Pre-Intake section, workflows/route.md decision matrix row and Tier 2/3 bullets, and the behavioural pins in both contract twins.`
- [ ] **AC-2**: `protocols/subagent-delegation.md and workflows/auto.md allow parallel read-only subagents in Balanced while parallel write waves keep --turbo --experimental, the wave pre-flight checklist and worktree isolation.`
  - **Result**: `Pending`
  - **Evidence**: `Read-Only Parallelism subsection, Turbo-gated write waves heading, route.md parallelism policy bullet, and TURBO-WAVES-GUIDE distinction.`
- [ ] **AC-3**: `The workflow registry in protocols/setup.md and the validate-references inventory stay in sync; the reference validator reports zero trigger warnings for the pk:brainstorm alias.`
  - **Result**: `Pending`
  - **Evidence**: `protocols/setup.md Brainstorm registry entry and the brainstorm allowlist in both validate-references twins.`
- [ ] **AC-4**: `Behavioural contract tests and every local gate pass; the workflow growth is re-propagated to docs/BENCHMARKS.md and the provenance anchor is restated in a docs-only follow-up commit.`
  - **Result**: `Pending`
  - **Evidence**: `Gate output recorded in this record and in the CHANGELOG entry.`

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval, failed verification, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `The host tracks elapsed turn time but cannot mechanically enforce the soft or hard checkpoint; the checkpoints remain operator obligations.`

## 5. State and Active Ownership

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-26 06:15 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Commit the implementation, then restate the docs/BENCHMARKS.md provenance anchor in a docs-only follow-up commit.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `2026-11-26 06:10 UTC` | `DeepSeek Harness agent (lead)` | `Record created for issue #792` | `N/A` |
| `planned` | `in_progress` | `2026-11-26 06:15 UTC` | `DeepSeek Harness agent (lead)` | `Implementation started` | `N/A` |
| `in_progress` | `awaiting_review` | `2026-11-26 07:30 UTC` | `DeepSeek Harness agent (lead)` | `Implementation and local gates complete` | `Gate output in Verification Evidence` |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/plan.md` - divergent pre-intake section and Step 0 option-space pointer
  - `workflows/route.md` - decision matrix row, Tier 2/3 routing bullets, parallelism policy
  - `workflows/auto.md` - write-wave scoping of the Turbo gate and read-only fan-out note
  - `workflows/research.md` - read-only candidate fan-out in Balanced
  - `protocols/subagent-delegation.md` - Read-Only Parallelism subsection and matrix updates
  - `protocols/setup.md` - Brainstorm registry entry
  - `docs/WORKFLOW-MAP.md` - brainstorm alias explanation
  - `docs/TURBO-WAVES-GUIDE.md` - read-only fan-out distinction
  - `README.md` - Divergent Ideation cheat-sheet row
  - `scripts/validate-references.sh` - brainstorm alias allowlist
  - `scripts/validate-references.ps1` - brainstorm alias map entry
  - `scripts/tests/run-behavioral-contract-tests.sh` - Scenario M2 pins
  - `scripts/tests/run-behavioral-contract-tests.ps1` - Scenario M2 pins
  - `docs/BENCHMARKS.md` - workflow totals, pk:plan payload, turbo and tokenizer figures
  - `CHANGELOG.md` - entry for issue #792
  - `docs/tasks/TASK-2026-11-26-issue-792-brainstorm-parallelism.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Combined tree after rebasing onto #791: git diff --check clean; validate-execution-control VALID|RECORDS=84|ROOT=.; validate-references All references valid with zero trigger warnings; run-token-budget-tests Passed 8 Failed 0; measure-tokens BALANCED|2404|2425|PASS and LITE|1415|1450|PASS; measure-ceremony-overhead CEREMONY_GATE|PASS with SETUP 3078 and L2 998; measure-tokenizer-delta four rows PASS; run-doctor-tests Passed 52 Failed 0; run-behavioral-contract-tests Passed 831 Failed 0.`
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `Not yet available - no push authorized.`
- **Review Evidence**: `N/A`
- **Commit Evidence**: `N/A before commit; the implementation commit and the docs-only provenance follow-up are added after the commit step.`
- **Pull Request Evidence**: `N/A - no PR authorized.`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 pending; AC-2 pending; AC-3 pending; AC-4 pending`
- **Changed-File Summary**: `Adds a zero-artifact divergent pre-intake for pk:brainstorm inside workflows/plan.md with a one-direction promotion handoff; splits delegation policy so read-only fan-out is allowed in Balanced while parallel write waves keep the Turbo, pre-flight and worktree gates; registers the alias in the router, setup registry, workflow map, README and Turbo guide; teaches the reference validator the alias; re-propagates combined workflow totals to 122,153 tok (core-six 34,058) with the pk:plan payload at 21,424 Balanced and 20,435 Lite.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Awaiting review with local gates green, 2026-11-26 07:30 UTC`
