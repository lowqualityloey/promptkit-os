# Task Record: Stack Playbooks Catalog Index and Astro Stack Playbook

<a id="TASK-2026-09-25-stacks-index-and-astro"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-25-stacks-index-and-astro`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub Issue #392 — docs(stacks): catalog gap map + intake criteria — Astro, api-python, api-node, deploy-docker; add stacks index`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/392`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-25 05:05 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Create docs/stacks/README.md catalog index with intake criteria, authoring rules, and roadmap (including WordPress CMS layer); ship web-astro.md stack playbook with zero-JS, island architecture, and content collection invariants; wire Astro pattern detection into workflows/onboard.md; scope verification shell composition checks; and assert full twin parity in playbook and behavioral contract tests.`
- **In Scope**:
  - `docs/stacks/README.md`
  - `docs/stacks/web-astro.md`
  - `scripts/validate-playbooks.sh`
  - `scripts/validate-playbooks.ps1`
  - `workflows/onboard.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-25-stacks-index-and-astro.md`
- **Explicit Non-Goals**:
  - `Modifying templates/agent-directive-template.md or Lite directive (headroom preserved).`
  - `Implementing all remaining backlog stacks in a single PR (deploy-docker, api-python, api-node belong to focused follow-up waves).`
  - `Bypassing strict <= 1,500 token budget.`
- **Dependencies**: `Issue #392 and operator approval`
- **Risk**: `Low — documentation, validation scripts, and behavioral contract tests only; zero directive bloat.`
- **Verification Condition**: `Dual contract test twins, dual behavioral contract test twins, strict token gates, reference validation, and execution control validation all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: `docs/stacks/README.md` provides an index catalog matrix of all on-disk playbooks (12 stacks), architectural intake criteria (rule vs playbook vs recipe vs workflow), schema contract, and demand-driven gap roadmap (including WordPress CMS layer).
  - **Result**: `Pass`
  - **Evidence**: `docs/stacks/README.md created with 12-row catalog matrix, intake tiers, and CMS roadmap`
- [x] **AC-2**: `docs/stacks/web-astro.md` conforms to the Playbook Contract (category: web, manifests, fast/required/extended tiers, zero-JS and island invariants) and passes contract twin gates with token budget $\le 1,500$.
  - **Result**: `Pass`
  - **Evidence**: `web-astro.md passes validation in bash and pwsh twins (~1,139 tok <= 1,500)`
- [x] **AC-3**: `scripts/validate-playbooks.sh` and `.ps1` verification array shell composition check is scoped specifically to verification blocks, eliminating false positives on prose semicolons.
  - **Result**: `Pass`
  - **Evidence**: `Dual validators isolate verification block before asserting discrete array items`
- [x] **AC-4**: `workflows/onboard.md` explicitly detects Astro projects in Phase 2 architectural pattern discovery.
  - **Result**: `Pass`
  - **Evidence**: `Phase 2 includes Web — Astro pattern detection item`
- [x] **AC-5**: Behavioral contract test twins include Scenario AB asserting stacks README, roadmap, and Astro playbook, and pin `onboard.md -> env-validation` in Scenario AA with 100% twin parity.
  - **Result**: `Pass`
  - **Evidence**: `Both contract test twins pass with Scenario AA and AB assertions (280 passed / 0 failed)`

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
- **Start Time**: `2026-09-25 05:05 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/issue-392-stacks-index-and-astro`
- **Next Action**: `Human PR review and merge decision on the #392 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-25 05:05 UTC | Implementor agent | Record created for Issue #392 Controlled Work | Issue #392 |
| planned | ready | 2026-09-25 05:15 UTC | Implementor agent | Readiness complete; scope bounded and verified | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/stacks/README.md` — catalog matrix, intake criteria, schema rules, and gap roadmap
  - `docs/stacks/web-astro.md` — Astro stack playbook
  - `scripts/validate-playbooks.sh` — scoped verification shell composition check
  - `scripts/validate-playbooks.ps1` — scoped verification shell composition check (twin parity)
  - `workflows/onboard.md` — added Astro pattern detection to Phase 2
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario AB assertions and Scenario AA onboard pin
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario AB assertions and Scenario AA onboard pin (twin parity)
  - `docs/tasks/TASK-2026-09-25-stacks-index-and-astro.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `run-playbook-contract-tests.sh` and `.ps1` -> 12 stacks + 8 recipes PASS; `validate-references.sh .` and `.ps1` -> all references valid; `measure-tokens.sh --strict` -> BALANCED 2254/2500 PASS, LITE 1146/1500 PASS; `measure-per-task-tokens.sh --strict` -> all baselines PASS; `run-behavioral-contract-tests.ps1` and `.sh` -> 280 passed / 0 failed (Scenarios AA and AB verified); `validate-execution-control.ps1 -Root . -Strict` -> VALID
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
- **Acceptance Results**: `AC-1 through AC-5 Complete`
- **Changed-File Summary**: `8 files modified/created`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-25 05:15 UTC`
