# Task Record: Add PostgreSQL and MySQL playbooks

<a id="TASK-2026-10-03-database-playbooks"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-03-database-playbooks`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub issue #522 and docs/stacks/README.md playbook contract.`
- **External Reference (Optional)**: [Issue #522](https://github.com/lowqualityloey/promptkit-os/issues/522)
- **Owner / Actor**: `PromptKit maintainer (review and migration smoke evidence) + Codex (implementation)`
- **Execution Scope**: `promptkit-os repository; database playbooks, catalog, onboarding contract tests, and task evidence`
- **Approval Boundary**: `Implementation and branch push authorized by user request; merge and release remain human-only.`
- **Created**: `2026-10-03`

## 2. Objective and Boundaries

- **Objective**: `Add content-confirmed PostgreSQL and MySQL guidance that protects applied migrations and respects active datasource boundaries.`
- **In Scope**:
  - `docs/stacks/database-postgres.md and docs/stacks/database-mysql.md`
  - `docs/stacks/README.md and workflows/onboard.md`
  - `Bash and PowerShell behavioral contract suites`
- **Explicit Non-Goals**:
  - `No database provisioning, production migration, ORM selection, or host schema change.`
- **Dependencies**: `Isolated disposable PostgreSQL/MySQL migration smoke environments and maintainer transcripts.`
- **Risk**: `Medium; migration guidance must preserve existing applied history and must not run against production.`
- **Verification Condition**: `Static schema/activation checks pass; isolated smoke creates a new migration and proves the seeded applied migration is unchanged.`

## 3. Acceptance Criteria

- [x] **AC-1**: `Playbooks require active engine evidence, mark conflicting or generic signals unconfirmed, and prohibit rewriting applied migrations.`
  - **Result**: `Pass for static implementation`
  - **Evidence**: `bash scripts/tests/run-playbook-contract-tests.sh; bash scripts/tests/run-token-budget-tests.sh; bash scripts/validate-references.sh .`
- [ ] **AC-2**: `PostgreSQL and MySQL onboarding seeds select only confirmed engines; isolated migration smoke creates a forward migration and leaves the seeded applied migration unchanged.`
  - **Result**: `Pending maintainer-run smoke`
  - **Evidence**: `No database seed transcript, migration diff, or baseline comparison is recorded yet.`

## 4. Execution Policy and State

- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes, advisory.`
- **Hard Checkpoint**: `At or before 90 minutes, advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, any production database target, missing approval, or maintainer stop.`
- **Host Timer Capability**: `This environment has a timer-enforcement limitation: it does not provide an enforced hard-stop timer; elapsed-time checkpoints are advisory only.`
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-03`
- **Current Actor**: `PromptKit maintainer (database smoke evidence and review)`
- **Next Action**: `Run the migration smoke in isolated disposable databases and preserve seed, transcript, and before/after migration evidence.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-03 | Codex | User requested implementation of the referenced GitHub issue. | User request and issue link |
| planned | in_progress | 2026-10-03 | Codex | Began scoped issue implementation. | Feature commits listed below |
| in_progress | awaiting_review | 2026-10-03 | Codex | Static implementation is ready for review; runtime acceptance evidence remains pending. | Verification and blocker fields below |

## 5. Evidence and Completion Gate

- **Changed Files**: `docs/stacks/database-postgres.md, docs/stacks/database-mysql.md, docs/stacks/README.md, workflows/onboard.md, Bash and PowerShell behavioral contract suites`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Static schema, token, and reference checks passed locally; no migration behavior is claimed from these checks.`
- **CI Evidence**: `PR #524 CI run at the current branch revision is pending; update after completion.`
- **Review Evidence**: `Pending final PR review.`
- **Commit Evidence**: `Feature commit 840888e.`
- **Pull Request Evidence**: [PR #524](https://github.com/lowqualityloey/promptkit-os/pull/524)
- **Release Evidence**: `N/A - documentation work.`
- **Blocker and Resume Condition**: `Migration smoke evidence is pending. Resume using isolated PostgreSQL and MySQL seeds with known applied migration baselines.`
- **Changed-File Summary**: `Static playbook/recipe and onboarding contract implementation for this issue; observed runtime acceptance is not claimed.`
- **Completion State**: `awaiting_review`
- **Completion Exception**: `Issue acceptance remains incomplete until the manual smoke evidence below is attached.`
- **Completion Decision and Timestamp**: `Not complete; keep this record open until pending acceptance criteria are observed. 2026-10-03.`
- **Acceptance Results**: `AC-1 Static implementation pass; AC-2 Pending live smoke.`
