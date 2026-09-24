# Task Record: Skill Coexistence and Precedence Contract

<a id="TASK-2026-09-24-skill-coexistence-contract"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-24-skill-coexistence-contract`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub Issue #385 — Skill coexistence contract: invocation never reclassifies work`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/385`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-24 23:39 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Define explicit contract for how external host skill invocations interact with PromptKit ceremony classification, precedence hierarchy, setup detection, and workflow deduplication.`
- **In Scope**:
  - `workflows/route.md`
  - `protocols/setup.md`
  - `docs/ADOPTION-GUIDE.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-24-skill-coexistence-contract.md`
- **Explicit Non-Goals**:
  - `Modifying templates/agent-directive-template.md or Lite directive (directive frozen).`
  - `Adding runtime skill monitoring daemons or auto-conflict resolvers.`
  - `Reviving skills-lock.json (handled in separate issue).`
- **Dependencies**: `Issue #385 and operator approval`
- **Risk**: `Low — documentation and behavioral contract assertions only; zero directive bloat.`
- **Verification Condition**: `Dual behavioral contract test twins, strict token gates, reference validation, and execution control validation all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: `workflows/route.md` precedence section states that skill invocation never reclassifies work and skill instructions yield to Hard Gates.
  - **Result**: `Pass`
  - **Evidence**: `Scenario Y in run-behavioral-contract-tests twins`
- [x] **AC-2**: `workflows/route.md` warns against host skills using the `pk-*` prefix to prevent namespace collisions.
  - **Result**: `Pass`
  - **Evidence**: `Scenario Y in run-behavioral-contract-tests twins`
- [x] **AC-3**: `protocols/setup.md` Phase 1 inspects host skill directories and confirms governance primacy.
  - **Result**: `Pass`
  - **Evidence**: `Scenario Y in run-behavioral-contract-tests twins`
- [x] **AC-4**: `docs/ADOPTION-GUIDE.md` provides an External Skill Coexistence & Deduplication Matrix.
  - **Result**: `Pass`
  - **Evidence**: `Scenario Y in run-behavioral-contract-tests twins`
- [x] **AC-5**: Contract assertions are mirrored with twin parity across `.sh` and `.ps1` test suites.
  - **Result**: `Pass`
  - **Evidence**: `Both contract test twins pass with 251/251 assertions`

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
- **Start Time**: `2026-09-24 23:39 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/issue-385-skill-coexistence-contract`
- **Next Action**: `Human PR review and merge decision on the #385 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-24 23:39 UTC | Implementor agent | Record created for Issue #385 Controlled Work | Issue #385 |
| planned | ready | 2026-09-24 23:42 UTC | Implementor agent | Readiness complete; scope bounded and verified | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/route.md` — extended Precedence Hierarchy with invocation-vs-classification rule, gate subordination, and collision warnings
  - `protocols/setup.md` — added host skill directory detection and governance primacy confirmation to Phase 1
  - `docs/ADOPTION-GUIDE.md` — added External Skill Coexistence & Deduplication Matrix
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario Y assertions
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario Y assertions (twin parity)
  - `docs/tasks/TASK-2026-09-24-skill-coexistence-contract.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `validate-references.sh .` → all references valid; `measure-tokens.sh --strict` → BALANCED 2254/2500 PASS (246 tok headroom), LITE 1146/1500 PASS; `measure-per-task-tokens.sh --strict` → all baselines PASS; `run-behavioral-contract-tests.ps1` and `.sh` → 251 passed / 0 failed; `validate-execution-control.sh --root . --strict` → VALID
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
- **Changed-File Summary**: `6 files modified/created`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-24 23:42 UTC`
