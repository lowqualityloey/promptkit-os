# Task Record: Add state-management and WebSocket recipes

<a id="TASK-2026-10-03-cross-cutting-recipes"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-03-cross-cutting-recipes`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub issue #523 and docs/recipes/README.md recipe contract.`
- **External Reference (Optional)**: [Issue #523](https://github.com/lowqualityloey/promptkit-os/issues/523)
- **Owner / Actor**: `PromptKit maintainer (review and smoke evidence) + Codex (implementation)`
- **Execution Scope**: `promptkit-os repository; state and WebSocket recipes, owning workflows, catalog, contract tests, and task evidence`
- **Approval Boundary**: `Implementation and branch push authorized by user request; merge and release remain human-only.`
- **Created**: `2026-10-03`

## 2. Objective and Boundaries

- **Objective**: `Add focused architecture recipes loaded conditionally by design-system and API workflows.`
- **In Scope**:
  - `docs/recipes/state-management.md and docs/recipes/websocket-realtime.md`
  - `docs/recipes/README.md, workflows/design-system.md, and workflows/api.md`
  - `Bash and PowerShell behavioral contract suites`
- **Explicit Non-Goals**:
  - `No host application state store, WebSocket service, global directive, or framework migration.`
- **Dependencies**: `Maintainer-run client-state, realtime, and unrelated negative workflow smoke cases.`
- **Risk**: `Low; misplaced workflow references could load irrelevant context or miss required lifecycle guidance.`
- **Verification Condition**: `Recipe schema, token, and references pass; transcripts prove conditional reads and resulting decisions before completion.`

## 3. Acceptance Criteria

- [x] **AC-1**: `Both recipes follow the schema, token limit, ownership/lifecycle boundaries, and are linked only from their owning workflows.`
  - **Result**: `Pass for static implementation`
  - **Evidence**: `bash scripts/tests/run-playbook-contract-tests.sh; bash scripts/tests/run-token-budget-tests.sh; bash scripts/validate-references.sh .`
- [ ] **AC-2**: `State and realtime tasks read/apply the relevant recipe while an unrelated task does not; preserve transcript file-read evidence.`
  - **Result**: `Pending maintainer-run workflow smoke`
  - **Evidence**: `No positive or negative workflow transcript is recorded yet.`

## 4. Execution Policy and State

- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes, advisory.`
- **Hard Checkpoint**: `At or before 90 minutes, advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion, missing approval, or maintainer stop.`
- **Host Timer Capability**: `This environment has a timer-enforcement limitation: it does not provide an enforced hard-stop timer; elapsed-time checkpoints are advisory only.`
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-03`
- **Current Actor**: `PromptKit maintainer (workflow smoke evidence and review)`
- **Next Action**: `Run state, realtime, and unrelated negative workflow smoke cases; retain file-read and decision evidence.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-03 | Codex | User requested implementation of the referenced GitHub issue. | User request and issue link |
| planned | in_progress | 2026-10-03 | Codex | Began scoped issue implementation. | Feature commits listed below |
| in_progress | awaiting_review | 2026-10-03 | Codex | Static implementation is ready for review; runtime acceptance evidence remains pending. | Verification and blocker fields below |

## 5. Evidence and Completion Gate

- **Changed Files**: `docs/recipes/{state-management,websocket-realtime}.md, docs/recipes/README.md, workflows/{design-system,api}.md, Bash and PowerShell behavioral contract suites`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Static schema, token, and reference checks passed locally; they do not establish runtime loading or application behavior.`
- **CI Evidence**: PR #524 [CI run 37153065712](https://github.com/lowqualityloey/promptkit-os/actions/runs/37153065712) passed Linux, Windows, and staged secret scan at implementation revision `66051df441c29c0b3b23dc39cb035094b2d619b1` (2026-10-04).
- **Review Evidence**: `Pending final PR review.`
- **Commit Evidence**: `Feature commit cc9ef6e.`
- **Pull Request Evidence**: [PR #524](https://github.com/lowqualityloey/promptkit-os/pull/524)
- **Release Evidence**: `N/A - documentation work.`
- **Blocker and Resume Condition**: `Workflow smoke evidence is pending. Resume with state, realtime, and unrelated tasks in a configured agent session.`
- **Changed-File Summary**: `Static playbook/recipe and onboarding contract implementation for this issue; observed runtime acceptance is not claimed.`
- **Completion State**: `awaiting_review`
- **Completion Exception**: `Issue acceptance remains incomplete until the manual smoke evidence below is attached.`
- **Completion Decision and Timestamp**: `Not complete; keep this record open until pending acceptance criteria are observed. 2026-10-03.`
- **Acceptance Results**: `AC-1 Static implementation pass; AC-2 Pending live smoke.`
