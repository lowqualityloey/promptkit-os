# Task Record: Documentation Truthfulness & Coherence Sweep

<a id="TASK-2026-09-25-docs-truthfulness-sweep"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-25-docs-truthfulness-sweep`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `GitHub Issue #384 — Docs truthfulness & coherence sweep (DESIGN-MD-FAQ, unhedged claims, terminology, orphan guide, dead lockfile)`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/384`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human approval authorizes local implementation, issue and PR creation; merge remains human-only.`
- **Created**: `2026-09-25 00:10 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Audit and resolve residual documentation truthfulness defects, unhedged claims, terminology drift, orphan guides, and dead files identified during post-merge audit and issue #384.`
- **In Scope**:
  - `docs/DESIGN-MD-FAQ.md`
  - `README.md`
  - `FAQ.md`
  - `workflows/ship.md`
  - `templates/tech-spec-template.md`
  - `templates/test-plan-template.md`
  - `docs/WORKFLOW-MAP.md`
  - `workflows/auto.md`
  - `docs/BENCHMARKS.md`
  - `scripts/measure-cpac.sh`
  - `scripts/measure-cpac.ps1`
  - `docs/BENCHMARK-METHODOLOGY.md`
  - `skills-lock.json` (removal)
  - `docs/tasks/TASK-2026-09-25-docs-truthfulness-sweep.md`
- **Explicit Non-Goals**:
  - `Modifying templates/agent-directive-template.md or templates/agent-directive-lite-template.md (frozen headroom).`
  - `Changing runtime workflow execution behavior.`
- **Dependencies**: `Issue #384 and operator approval`
- **Risk**: `Low — documentation and script annotation cleanup; maintain twin parity and strict reference validity.`
- **Verification Condition**: `Strict token gates, behavioral contract test twins, per-task token gates, execution control validator, and reference validation all exit 0.`

## 3. Acceptance Criteria

- [x] **AC-1**: Ground DESIGN.md usage in `docs/DESIGN-MD-FAQ.md` removing ungrounded auto-enforcement claim.
  - **Result**: `Pass`
  - **Evidence**: `docs/DESIGN-MD-FAQ.md:56-71 updated`
- [x] **AC-2**: Align static footprint claims in `README.md` and hedge subagent context preservation in `FAQ.md`.
  - **Result**: `Pass`
  - **Evidence**: `README.md:97-98 and FAQ.md:274 updated`
- [x] **AC-3**: Replace lingering "Trivial Work" with "Level 0 Work" across `workflows/ship.md`, `templates/tech-spec-template.md`, `templates/test-plan-template.md`, and `docs/WORKFLOW-MAP.md`. Add `pk:reflect` alongside `pk:retro`.
  - **Result**: `Pass`
  - **Evidence**: `Greps confirmed 0 occurrences of Trivial Work in live files`
- [x] **AC-4**: Link orphaned `docs/TURBO-WAVES-GUIDE.md` from `workflows/auto.md` and `docs/WORKFLOW-MAP.md`.
  - **Result**: `Pass`
  - **Evidence**: `Inbound references verified`
- [x] **AC-5**: Date-stamp historical measurement vintage for `route.md` in `docs/BENCHMARKS.md`.
  - **Result**: `Pass`
  - **Evidence**: `BENCHMARKS.md line 79 updated`
- [x] **AC-6**: Document successful-turn vs rework split in `scripts/measure-cpac.*` twins and update `docs/BENCHMARK-METHODOLOGY.md`.
  - **Result**: `Pass`
  - **Evidence**: `scripts/measure-cpac.sh, scripts/measure-cpac.ps1, docs/BENCHMARK-METHODOLOGY.md updated`
- [x] **AC-7**: Remove dead file `skills-lock.json`.
  - **Result**: `Pass`
  - **Evidence**: `git rm skills-lock.json executed`

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
- **Start Time**: `2026-09-25 00:10 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/issue-384-truthfulness-coherence`
- **Next Action**: `Human PR review and merge decision on the #384 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-25 00:10 UTC | Implementor agent | Record created for Issue #384 Controlled Work | Issue #384 |
| planned | ready | 2026-09-25 00:12 UTC | Implementor agent | Readiness complete; scope bounded and verified | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/DESIGN-MD-FAQ.md` — grounded DESIGN.md usage
  - `README.md` — aligned static footprint and reduction figures
  - `FAQ.md` — hedged subagent context preservation claim
  - `workflows/ship.md` — replaced Trivial Work with Level 0 Work
  - `templates/tech-spec-template.md` — replaced Trivial Work with Level 0 Work
  - `templates/test-plan-template.md` — replaced Trivial Work with Level 0 Work
  - `docs/WORKFLOW-MAP.md` — replaced Trivial Work with Level 0 Work, linked TURBO-WAVES-GUIDE.md, added pk:reflect
  - `workflows/auto.md` — linked TURBO-WAVES-GUIDE.md
  - `docs/BENCHMARKS.md` — date-stamped route.md vintage
  - `scripts/measure-cpac.sh` — added successful-turn/rework split doc comments
  - `scripts/measure-cpac.ps1` — added successful-turn/rework split doc comments
  - `docs/BENCHMARK-METHODOLOGY.md` — updated implementation note
  - `skills-lock.json` — deleted dead file
  - `docs/tasks/TASK-2026-09-25-docs-truthfulness-sweep.md` — this task record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `validate-references.sh .` → all references valid; `measure-tokens.sh --strict` → PASS; `measure-per-task-tokens.sh --strict` → PASS; `run-behavioral-contract-tests.ps1` and `.sh` → PASS; `validate-execution-control.sh --root . --strict` → VALID
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
- **Acceptance Results**: `AC-1 through AC-7 Complete`
- **Changed-File Summary**: `14 files modified/created/deleted`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-25 00:13 UTC`
