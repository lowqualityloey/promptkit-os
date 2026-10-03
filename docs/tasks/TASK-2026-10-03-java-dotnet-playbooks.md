# Task Record: Add Java Spring and .NET backend playbooks

<a id="TASK-2026-10-03-java-dotnet-playbooks"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-03-java-dotnet-playbooks`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub issue #520 and docs/stacks/README.md playbook contract.`
- **External Reference (Optional)**: [Issue #520](https://github.com/lowqualityloey/promptkit-os/issues/520)
- **Owner / Actor**: `PromptKit maintainer (review and smoke evidence) + Codex (implementation)`
- **Execution Scope**: `promptkit-os repository; Java/.NET playbooks, catalog, onboarding contract tests, and task evidence`
- **Approval Boundary**: `Implementation and branch push authorized by user request; merge and release remain human-only.`
- **Created**: `2026-10-03`

## 2. Objective and Boundaries

- **Objective**: `Add content-confirmed Spring Boot and .NET backend guidance with framework-specific architecture boundaries.`
- **In Scope**:
  - `docs/stacks/systems-java-spring.md`
  - `docs/stacks/systems-csharp-dotnet.md`
  - `docs/stacks/README.md and workflows/onboard.md`
  - `Bash and PowerShell behavioral contract suites`
- **Explicit Non-Goals**:
  - `No changes to host Java or .NET applications, dependency versions, or database migrations.`
- **Dependencies**: `Maintainer-run Java and .NET onboarding seed repositories.`
- **Risk**: `Low; selection errors could load irrelevant guidance, so unresolved framework signals must stay unconfirmed.`
- **Verification Condition**: `Schema, activation contract, token, and reference checks pass; representative positive and negative seeds are observed before completion.`

## 3. Acceptance Criteria

- [x] **AC-1**: `Spring Boot and ASP.NET Core/Worker/EF Core activation rules and backend boundaries are documented; unresolved indirect declarations remain unconfirmed.`
  - **Result**: `Pass for static implementation`
  - **Evidence**: `bash scripts/tests/run-playbook-contract-tests.sh; bash scripts/tests/run-token-budget-tests.sh; bash scripts/validate-references.sh .`
- [ ] **AC-2**: `Spring Boot, Worker, and EF Core backend seeds select the playbook; plain Java/.NET projects do not; actual selection output is retained.`
  - **Result**: `Pending maintainer-run onboarding smoke`
  - **Evidence**: `No seed transcript or agent file-read evidence is recorded yet.`

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
- **Next Action**: `Run positive/negative Spring Boot and .NET onboarding smoke cases, including a Worker and EF Core library; preserve transcripts.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-03 | Codex | User requested implementation of the referenced GitHub issue. | User request and issue link |
| planned | in_progress | 2026-10-03 | Codex | Began scoped issue implementation. | Feature commits listed below |
| in_progress | awaiting_review | 2026-10-03 | Codex | Static implementation is ready for review; runtime acceptance evidence remains pending. | Verification and blocker fields below |

## 5. Evidence and Completion Gate

- **Changed Files**: `docs/stacks/systems-java-spring.md, docs/stacks/systems-csharp-dotnet.md, docs/stacks/README.md, workflows/onboard.md, Bash and PowerShell behavioral contract suites`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Static schema, token, and reference checks passed locally; these checks do not establish actual onboarding selection.`
- **CI Evidence**: PR #524 [CI run 37153065712](https://github.com/lowqualityloey/promptkit-os/actions/runs/37153065712) passed Linux, Windows, and staged secret scan at implementation revision `66051df441c29c0b3b23dc39cb035094b2d619b1` (2026-10-04).
- **Review Evidence**: `Pending final PR review.`
- **Commit Evidence**: `Feature commit fcb0bd3.`
- **Pull Request Evidence**: [PR #524](https://github.com/lowqualityloey/promptkit-os/pull/524)
- **Release Evidence**: `N/A - documentation work.`
- **Blocker and Resume Condition**: `Live onboarding evidence is pending. Resume with representative Maven/Gradle and .NET seed repositories under pk:onboard.`
- **Changed-File Summary**: `Static playbook/recipe and onboarding contract implementation for this issue; observed runtime acceptance is not claimed.`
- **Completion State**: `awaiting_review`
- **Completion Exception**: `Issue acceptance remains incomplete until the manual smoke evidence below is attached.`
- **Completion Decision and Timestamp**: `Not complete; keep this record open until pending acceptance criteria are observed. 2026-10-03.`
- **Acceptance Results**: `AC-1 Static implementation pass; AC-2 Pending live smoke.`
