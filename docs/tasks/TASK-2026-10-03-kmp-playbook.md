# Task Record: Add Kotlin Multiplatform onboarding guidance

<a id="TASK-2026-10-03-kmp-playbook"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-03-kmp-playbook`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub issue #519 and docs/stacks/README.md playbook contract.`
- **External Reference (Optional)**: [Issue #519](https://github.com/lowqualityloey/promptkit-os/issues/519)
- **Owner / Actor**: `PromptKit maintainer (review and smoke evidence) + Codex (implementation)`
- **Execution Scope**: `promptkit-os repository; KMP playbook, stack catalog, onboarding contract tests, and task evidence`
- **Approval Boundary**: `Implementation and branch push authorized by user request; merge and release remain human-only.`
- **Created**: `2026-10-03`

## 2. Objective and Boundaries

- **Objective**: `Add KMP playbook guidance and content-confirmed onboarding selection for Gradle KMP projects.`
- **In Scope**:
  - `docs/stacks/mobile-kmp.md`
  - `docs/stacks/README.md`
  - `workflows/onboard.md`
  - `scripts/tests/run-behavioral-contract-tests.{sh,ps1}`
- **Explicit Non-Goals**:
  - `No changes to host mobile applications, Gradle plugin versions, iOS projects, or macOS toolchains.`
- **Dependencies**: `Maintainer-run KMP onboarding smoke evidence on a configured host.`
- **Risk**: `Low; static guidance is additive, but unobserved onboarding behavior must not be claimed.`
- **Verification Condition**: `Playbook schema, token, and references pass; a representative KMP and plain Android repository smoke is recorded before completion.`

## 3. Acceptance Criteria

- [x] **AC-1**: `The playbook confirms an applied org.jetbrains.kotlin.multiplatform plugin, including a resolved applied catalog alias, and marks unresolved conventions unconfirmed.`
  - **Result**: `Pass`
  - **Evidence**: `bash scripts/tests/run-playbook-contract-tests.sh; bash scripts/tests/run-token-budget-tests.sh; bash scripts/validate-references.sh .; official source links and verification date in docs/stacks/mobile-kmp.md.`
- [ ] **AC-2**: `A KMP seed selects the playbook while a plain Android/JVM Gradle seed does not; target results identify iOS as not measured off macOS.`
  - **Result**: `Pending maintainer-run onboarding smoke`
  - **Evidence**: `No live onboarding transcript or agent file-read output is recorded yet.`

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
- **Current Actor**: `PromptKit maintainer (smoke evidence and review)`
- **Next Action**: `Run positive KMP and negative Android onboarding smoke cases; attach transcripts and observed file reads.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-03 | Codex | User requested implementation of the referenced GitHub issue. | User request and issue link |
| planned | in_progress | 2026-10-03 | Codex | Began scoped issue implementation. | Feature commits listed below |
| in_progress | awaiting_review | 2026-10-03 | Codex | Static implementation is ready for review; runtime acceptance evidence remains pending. | Verification and blocker fields below |

## 5. Evidence and Completion Gate

- **Changed Files**: `docs/stacks/mobile-kmp.md, docs/stacks/README.md, workflows/onboard.md, scripts/tests/run-behavioral-contract-tests.{sh,ps1}`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Playbook schema and token checks passed locally; reference validation passed. Static assertions do not establish actual onboarding selection.`
- **CI Evidence**: `PR #524 CI run at the current branch revision is pending; update after completion.`
- **Review Evidence**: `Pending final PR review.`
- **Commit Evidence**: `Feature commit 840888e; source-verification follow-up 9f8f981.`
- **Pull Request Evidence**: [PR #524](https://github.com/lowqualityloey/promptkit-os/pull/524)
- **Release Evidence**: `N/A - documentation work.`
- **Blocker and Resume Condition**: `Live onboarding evidence is pending. Resume when the maintainer can run KMP and plain Android seed repositories through pk:onboard and preserve transcripts.`
- **Changed-File Summary**: `Static playbook/recipe and onboarding contract implementation for this issue; observed runtime acceptance is not claimed.`
- **Completion State**: `awaiting_review`
- **Completion Exception**: `Issue acceptance remains incomplete until the manual smoke evidence below is attached.`
- **Completion Decision and Timestamp**: `Not complete; keep this record open until pending acceptance criteria are observed. 2026-10-03.`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pending live smoke.`
