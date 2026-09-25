# Task Record: Docker Container Deployment Stack Playbook

<a id="TASK-2026-09-25-deploy-docker-playbook"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-25-deploy-docker-playbook`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub Issue #396 — docs(stacks): add deploy-docker stack playbook (Child of #392)`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/396`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-25 05:40 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Ship docs/stacks/deploy-docker.md stack playbook with multi-stage build separation, non-root user execution, cache-optimized layer ordering, and tiered verification commands; index deploy-docker in docs/stacks/README.md catalog and roadmap; wire Docker discovery into workflows/onboard.md; and assert full twin parity across playbook and behavioral contract tests (Scenario AC).`
- **In Scope**:
  - `docs/stacks/deploy-docker.md`
  - `docs/stacks/README.md`
  - `workflows/onboard.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-25-deploy-docker-playbook.md`
- **Explicit Non-Goals**:
  - `Modifying templates/agent-directive-template.md or Lite directive (headroom preserved).`
  - `Implementing unrelated backlog stacks (api-python, api-node, cms-wordpress belong to focused subsequent waves).`
  - `Bypassing strict <= 1,500 token budget.`
- **Dependencies**: `Issue #396 and operator approval`
- **Risk**: `Low — documentation, test twin updates, and workflow detection only; zero directive impact.`
- **Verification Condition**: `Dual contract test twins, dual behavioral contract test twins, strict token gates, reference validation, and execution control validation all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: `docs/stacks/deploy-docker.md` conforms to the Playbook Contract (`category: cloud`, manifests, fast/required/extended tiers, multi-stage and non-root invariants) and passes contract twin gates with token budget $\le 1,500$.
  - **Result**: `Pass`
  - **Evidence**: `deploy-docker.md passes validation in bash and pwsh twins (1,384 tok <= 1,500)`
- [x] **AC-2**: `docs/stacks/README.md` registers `deploy-docker.md` in the catalog matrix (13 stacks total) and marks `deploy-docker.md` as Shipped in Section 4 roadmap.
  - **Result**: `Pass`
  - **Evidence**: `docs/stacks/README.md updated with deploy-docker row and marked Shipped in roadmap`
- [x] **AC-3**: `workflows/onboard.md` explicitly detects Docker containerized projects in Phase 2 architectural pattern discovery.
  - **Result**: `Pass`
  - **Evidence**: `Phase 2 includes Deploy — Docker pattern detection item`
- [x] **AC-4**: Behavioral contract test twins include Scenario AC asserting stacks README, deploy-docker playbook invariants, and onboarding discovery with 100% twin parity.
  - **Result**: `Pass`
  - **Evidence**: `Both contract test twins pass with Scenario AC assertions (288 passed / 0 failed)`

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `Session boundary or ~30 turns`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `State that live host timing or forced termination is unavailable or limited.`

## 5. State and Active Ownership

- **Execution State**: `ready`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-25 05:40 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/issue-396-deploy-docker-playbook`
- **Next Action**: `Open pull request linked to #396 and child of #392`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-25 05:40 UTC | Implementor agent | Record created for Issue #396 Controlled Work | Issue #396 |
| planned | ready | 2026-09-25 05:46 UTC | Implementor agent | Readiness complete; scope bounded and verified | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/stacks/deploy-docker.md` — Docker container deployment stack playbook
  - `docs/stacks/README.md` — catalog matrix addition and roadmap update
  - `workflows/onboard.md` — added Deploy — Docker pattern detection to Phase 2
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario AC assertions
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario AC assertions (twin parity)
  - `docs/tasks/TASK-2026-09-25-deploy-docker-playbook.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `run-playbook-contract-tests.sh` and `.ps1` -> 13 stacks + 8 recipes PASS; `validate-references.sh .` -> all references valid; `measure-tokens.sh --strict` -> BALANCED 2254/2500 PASS, LITE 1146/1500 PASS; `run-behavioral-contract-tests.ps1` and `.sh` -> 288 passed / 0 failed (Scenario AC verified); `validate-execution-control.ps1 -Root .` -> VALID
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation/Protocol Work`
- **CI Evidence**: `pending - CI runs the .sh and .ps1 contract twins on push`
- **Review Evidence**: `pending`
- **Commit Evidence**: `pending`
- **Pull Request Evidence**: `pending`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `ready`
- **Acceptance Results**: `AC-1 through AC-4 Complete`
- **Changed-File Summary**: `6 files modified/created`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-25 05:46 UTC`
