# Task Record: WordPress CMS Stack Playbook

<a id="TASK-2026-09-25-cms-wordpress-playbook"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-25-cms-wordpress-playbook`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub Issue #402 — docs(stacks): add cms-wordpress stack playbook (Child 5 of #392)`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/402`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-25 08:48 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Ship docs/stacks/cms-wordpress.md stack playbook with mandatory prepared statements, state mutation nonce verification, explicit capability authorization, contextual late escaping, and unbounded loop query prevention; index cms-wordpress in docs/stacks/README.md catalog and roadmap; wire WordPress CMS discovery into workflows/onboard.md; and assert full twin parity across playbook and behavioral contract tests (Scenario AF).`
- **In Scope**:
  - `docs/stacks/cms-wordpress.md`
  - `docs/stacks/README.md`
  - `workflows/onboard.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-25-cms-wordpress-playbook.md`
- **Explicit Non-Goals**:
  - `Modifying templates/agent-directive-template.md or Lite directive (headroom preserved).`
  - `Implementing unrelated backlog stacks (web-sveltekit, web-vue-nuxt belong to future waves).`
  - `Bypassing strict <= 1,500 token budget.`
- **Dependencies**: `Issue #402 and operator approval`
- **Risk**: `Low — documentation, test twin updates, and workflow detection only; zero directive impact.`
- **Verification Condition**: `Dual contract test twins, dual behavioral contract test twins, strict token gates, reference validation, and execution control validation all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: `docs/stacks/cms-wordpress.md` conforms to the Playbook Contract (`category: web`, manifests, fast/required/extended tiers, prepared SQL, nonces, capabilities, and late escaping invariants) and passes contract twin gates with token budget $\le 1,500$.
  - **Result**: `Pass`
  - **Evidence**: `cms-wordpress.md passes validation in bash and pwsh twins (1,468 tok <= 1,500)`
- [x] **AC-2**: `docs/stacks/README.md` registers `cms-wordpress.md` in the catalog matrix (16 stacks total) and marks `cms-wordpress.md` as Shipped in Section 4 roadmap.
  - **Result**: `Pass`
  - **Evidence**: `docs/stacks/README.md updated with cms-wordpress row and marked Shipped in roadmap`
- [x] **AC-3**: `workflows/onboard.md` explicitly detects WordPress CMS in Phase 2 architectural pattern discovery.
  - **Result**: `Pass`
  - **Evidence**: `Phase 2 includes CMS — WordPress pattern detection item`
- [x] **AC-4**: Behavioral contract test twins include Scenario AF asserting stacks README, cms-wordpress playbook invariants, and onboarding discovery with 100% twin parity.
  - **Result**: `Pass`
  - **Evidence**: `Both contract test twins pass with Scenario AF assertions`

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
- **Start Time**: `2026-09-25 08:48 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/issue-402-cms-wordpress-playbook`
- **Next Action**: `Open pull request linked to #402 and child of #392`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-25 08:48 UTC | Implementor agent | Record created for Issue #402 Controlled Work | Issue #402 |
| planned | ready | 2026-09-25 08:52 UTC | Implementor agent | Readiness complete; scope bounded and verified | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/stacks/cms-wordpress.md` — WordPress CMS stack playbook
  - `docs/stacks/README.md` — catalog matrix addition and roadmap update
  - `workflows/onboard.md` — added CMS — WordPress pattern detection to Phase 2
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario AF assertions
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario AF assertions (twin parity)
  - `docs/tasks/TASK-2026-09-25-cms-wordpress-playbook.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `run-playbook-contract-tests.sh` and `.ps1` -> 16 stacks + 8 recipes PASS; `validate-references.sh .` -> all references valid; `measure-tokens.sh --strict` -> BALANCED and LITE pass token budgets; `run-behavioral-contract-tests.ps1` and `.sh` -> Scenario AF verified; `validate-execution-control.ps1 -Root .` -> VALID
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
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-25 08:52 UTC`
