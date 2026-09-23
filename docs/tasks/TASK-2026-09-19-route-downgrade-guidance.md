# Task Record: Proactive Downgrade & Checkpoint Cadence Guidance in `pk:route`

<a id="TASK-2026-09-19-route-downgrade-guidance"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-19-route-downgrade-guidance`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #339 — docs(route): downgrade guidance — Level fit per milestone, checkpoint cadence by size
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/339`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge.`
- **Created**: `2026-09-19 16:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Give the router a proactive per-milestone level-fit check (proposed downgrades, never forced) plus checkpoint-cadence guidance by project size, so ceremony ratchets down when work is small without weakening verification.
- **In Scope**:
  - `workflows/route.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `docs/tasks/TASK-2026-09-19-route-downgrade-guidance.md`
- **Explicit Non-Goals**:
  - Changing Level definitions, escalation triggers, or downgrade guardrails; auto-downgrading without operator confirmation; weakening quality gates or verification tiers; restating checkpoint cadence numbers (canonical source is `workflows/checkpoint.md`); Turbo or authority semantics; directive-template edits (zero token headroom).
- **Dependencies**: Issue #339 approved direction; existing Level 0-3 downgrade rules in `workflows/route.md`; canonical cadence in `workflows/checkpoint.md`
- **Risk**: Low — router documentation wording plus contract assertions; escalation and verification matrices unchanged
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh .` 0 broken links; `measure-tokens.sh --strict` PASS; `measure-per-task-tokens.sh --strict` PASS; behavioral contract twins PASS.

## 3. Acceptance Criteria

- [x] **AC-1**: `workflows/route.md` defines a proactive Level-fit check at milestone boundaries with explicit Level-1 fit criteria.
- [x] **AC-2**: Downgrades are proposed with rationale and applied only on operator confirmation.
- [x] **AC-3**: A downgrade reduces records, never verification (Evidence-Gated Verification Matrix preserved; Level 1 still requires `fast` + `required` evidence).
- [x] **AC-4**: Checkpoint cadence guidance by project size defers canonical numbers to `workflows/checkpoint.md` and never relaxes a Level 2/3 hard checkpoint.
- [x] **AC-5**: A worked small-MVP example is included; contract assertions pin the behavior in both twins.

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `State that live host timing or forced termination is unavailable or limited.`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-19 16:00 UTC`
- **Current Actor**: `Implementor agent`
- **Branch / Revision**: `docs/turbo-waves-guide (uncommitted)`
- **Next Action**: `Human PR review and merge decision on the #339 change set`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-19 16:00 UTC | Implementor agent | Record created for Issue #339 Controlled Work | Issue #339 |
| planned | ready | 2026-09-19 16:00 UTC | Implementor agent | Readiness complete; scope bounded and approved | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/route.md` — Proactive Level-Fit Check (item 5) and Checkpoint Cadence by Project Size (item 5b)
  - `scripts/tests/run-behavioral-contract-tests.sh` — Scenario X assertions
  - `scripts/tests/run-behavioral-contract-tests.ps1` — Scenario X assertions (twin parity)
  - `docs/tasks/TASK-2026-09-19-route-downgrade-guidance.md` — this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `validate-references.sh .` → all references valid; `measure-tokens.sh --strict` → BALANCED 2500/2500 PASS, LITE 1146/1500 PASS; `measure-per-task-tokens.sh --strict` → all 6 baselines PASS; `run-behavioral-contract-tests.sh` → 234 passed / 0 failed (Scenario X: 7 assertions PASS); `validate-execution-control.sh --root . --strict` → VALID|RECORDS=31
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
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 through AC-5 Complete
- **Changed-File Summary**: 4 files modified/created
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `ready; Implementor agent; 2026-09-19 16:10 UTC`