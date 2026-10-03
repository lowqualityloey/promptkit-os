# Task Record: Add AWS and Google Cloud deployment playbooks

<a id="TASK-2026-10-03-cloud-playbooks"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-03-cloud-playbooks`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub issue #521 and docs/stacks/README.md playbook contract.`
- **External Reference (Optional)**: [Issue #521](https://github.com/lowqualityloey/promptkit-os/issues/521)
- **Owner / Actor**: `PromptKit maintainer (review and smoke evidence) + Codex (implementation)`
- **Execution Scope**: `promptkit-os repository; AWS/GCP playbooks, catalog, onboarding contract tests, and task evidence`
- **Approval Boundary**: `Implementation and branch push authorized by user request; merge, deployment, and release remain human-only.`
- **Created**: `2026-10-03`

## 2. Objective and Boundaries

- **Objective**: `Add provider-specific deployment guidance selected only from confirmed AWS or Google Cloud deployment configuration.`
- **In Scope**:
  - `docs/stacks/deploy-aws.md and docs/stacks/deploy-gcp.md`
  - `docs/stacks/README.md and workflows/onboard.md`
  - `Bash and PowerShell behavioral contract suites`
- **Explicit Non-Goals**:
  - `No cloud deployment, IAM/resource mutation, provider setup tutorial, or cloud credential use.`
- **Dependencies**: `Maintainer-run CDK, SAM, Cloud Run, and Functions onboarding seeds.`
- **Risk**: `Medium; generic manifests must not cause over-activation or trigger a deployment.`
- **Verification Condition**: `Static schema and trigger checks pass; representative positive/negative seeds record actual selection without deployment.`

## 3. Acceptance Criteria

- [x] **AC-1**: `Provider playbooks include IAM, secrets, environment separation, safe review, and non-deploying verification guidance.`
  - **Result**: `Pass for static implementation`
  - **Evidence**: `bash scripts/tests/run-playbook-contract-tests.sh; bash scripts/tests/run-token-budget-tests.sh; bash scripts/validate-references.sh .`
- [ ] **AC-2**: `CDK, SAM, Cloud Run, and Functions seeds select the correct playbook; generic containers/Cloud Build/Terraform do not; transcripts show actual selection.`
  - **Result**: `Pending maintainer-run onboarding smoke`
  - **Evidence**: `No provider seed transcript or agent file-read output is recorded yet.`

## 4. Execution Policy and State

- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes, advisory.`
- **Hard Checkpoint**: `At or before 90 minutes, advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, handoff, or context drift.`
- **Stop Conditions**: `Any deployment or resource mutation, failed verification, missing approval, or maintainer stop.`
- **Host Timer Capability**: `This environment has a timer-enforcement limitation: it does not provide an enforced hard-stop timer; elapsed-time checkpoints are advisory only.`
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-03`
- **Current Actor**: `PromptKit maintainer (smoke evidence and review)`
- **Next Action**: `Run provider-specific positive and generic-manifest negative onboarding cases without deploying; retain transcripts.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-03 | Codex | User requested implementation of the referenced GitHub issue. | User request and issue link |
| planned | in_progress | 2026-10-03 | Codex | Began scoped issue implementation. | Feature commits listed below |
| in_progress | awaiting_review | 2026-10-03 | Codex | Static implementation is ready for review; runtime acceptance evidence remains pending. | Verification and blocker fields below |

## 5. Evidence and Completion Gate

- **Changed Files**: `docs/stacks/deploy-aws.md, docs/stacks/deploy-gcp.md, docs/stacks/README.md, workflows/onboard.md, Bash and PowerShell behavioral contract suites`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Static schema, token, and reference checks passed locally; they do not establish actual provider selection.`
- **CI Evidence**: PR #524 [CI run 37153065712](https://github.com/lowqualityloey/promptkit-os/actions/runs/37153065712) passed Linux, Windows, and staged secret scan at implementation revision `66051df441c29c0b3b23dc39cb035094b2d619b1` (2026-10-04).
- **Review Evidence**: `Pending final PR review.`
- **Commit Evidence**: `Feature commits c447331 and 840888e.`
- **Pull Request Evidence**: [PR #524](https://github.com/lowqualityloey/promptkit-os/pull/524)
- **Release Evidence**: `N/A - documentation work.`
- **Blocker and Resume Condition**: `Provider smoke evidence is pending. Resume with representative CDK, SAM, Cloud Run, Functions, and generic-manifest seed repositories.`
- **Changed-File Summary**: `Static playbook/recipe and onboarding contract implementation for this issue; observed runtime acceptance is not claimed.`
- **Completion State**: `awaiting_review`
- **Completion Exception**: `Issue acceptance remains incomplete until the manual smoke evidence below is attached.`
- **Completion Decision and Timestamp**: `Not complete; keep this record open until pending acceptance criteria are observed. 2026-10-03.`
- **Acceptance Results**: `AC-1 Static implementation pass; AC-2 Pending live smoke.`
