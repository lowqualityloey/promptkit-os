# Task Record: Issue #791 — compact default telemetry, honest checkpoint spend, STATE freshness guard

<a id="TASK-2026-11-26-issue-791-telemetry-state-guard"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-26-issue-791-telemetry-state-guard`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Code Work`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/791`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: `Worktree dsh-a5b9d67e-25a7 (branch feat/791-telemetry-state) for lowqualityloey/promptkit-os`
- **Approval Boundary**: `Local implementation, verification, and commits only. Push, pull request, merge, tag, and release actions are not authorized without explicit human confirmation.`
- **Created**: `2026-11-26 04:30 UTC`

## 2. Objective and Boundaries

- **Objective**: `Ship issue #791: routine telemetry is compact Markdown by default with framed cards reserved for ACTION REQUIRED and BLOCKED halts, pk:checkpoint records not measured instead of the 8k-15k heuristic spend range, and pk:doctor plus pk:checkpoint detect a bloated or stale docs/STATE.md and provide a one-step archival flow.`
- **In Scope**:
  - `protocols/telemetry-cards.md`
  - `PROMPTKIT.md`
  - `QUICKSTART.md`
  - `docs/ARCHITECTURE.md`
  - `workflows/checkpoint.md`
  - `workflows/doctor.md`
  - `templates/project-profile-template.md`
  - `templates/state-tracker-template.md`
  - `scripts/check-doctor.sh`
  - `scripts/check-doctor.ps1`
  - `scripts/tests/run-doctor-tests.sh`
  - `scripts/tests/run-doctor-tests.ps1`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `scripts/measure-ceremony-overhead.sh`
  - `scripts/measure-ceremony-overhead.ps1`
  - `docs/BENCHMARKS.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-26-issue-791-telemetry-state-guard.md`
- **Explicit Non-Goals**:
  - `No change to templates/agent-directive-template.md or templates/agent-directive-lite-template.md, so the measured directive figures and directive savings stay unchanged.`
  - `No change to the State Mutation Contract or to docs/STATE.md section ownership.`
  - `No new workflow in the locked 26-workflow registry.`
  - `No push, pull request, merge, tag, or release action.`
- **Dependencies**: `Issue #788 telemetry wording is already merged on main; no other dependency.`
- **Risk**: `Medium - the doctor gains a git rev-list history probe and the checkpoint workflow gains a write-time preflight, so both must stay read-only until the archival step and must keep the existing docs-drift contract intact.`
- **Verification Condition**: `bash scripts/validate-execution-control.sh --root . --strict exits 0; bash scripts/validate-references.sh . --strict exits 0; bash scripts/tests/run-token-budget-tests.sh exits 0; bash scripts/measure-tokens.sh --strict exits 0; bash scripts/measure-ceremony-overhead.sh --strict exits 0 with SETUP 3078; bash scripts/measure-tokenizer-delta.sh --strict exits 0; bash scripts/tests/run-doctor-tests.sh reports 52 passed and 0 failed; bash scripts/tests/run-behavioral-contract-tests.sh reports 0 failed.`

## 3. Acceptance Criteria

- [ ] **AC-1**: `Routine completion telemetry is three compact Markdown lines with no box, framed cards fire only for ACTION REQUIRED and BLOCKED, and status-cards: off still suppresses only the decorative output.`
  - **Result**: `Pending`
  - **Evidence**: `protocols/telemetry-cards.md Compact Status Default section plus the behavioural pins in both contract twins.`
- [ ] **AC-2**: `workflows/checkpoint.md records host telemetry unavailable and not measured when the host does not meter, and no longer instructs a turns times 8k-to-15k estimate; the measured/unavailable distinction survives.`
  - **Result**: `Pending`
  - **Evidence**: `workflows/checkpoint.md Honest Telemetry Rule plus the assert_not_contains for Fallback Estimation Heuristic.`
- [ ] **AC-3**: `pk:doctor reports a state-freshness row from the state-guard thresholds and pk:checkpoint archives completed entries to docs/STATE-ARCHIVE.md without breaking the State Mutation Contract.`
  - **Result**: `Pending`
  - **Evidence**: `scripts/check-doctor.sh and .ps1 check_state_freshness rows, workflows/checkpoint.md State Health Preflight, and doctor scenarios S16-S19.`
- [ ] **AC-4**: `Behavioural contract tests and validate-references pass; the state-tracker template growth is re-propagated to the ceremony SETUP baseline and docs/BENCHMARKS.md.`
  - **Result**: `Pending`
  - **Evidence**: `Gate output recorded in this record and in the CHANGELOG entry.`

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval, failed verification, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `The host tracks elapsed turn time but cannot mechanically enforce the soft or hard checkpoint; the checkpoints remain operator obligations.`

## 5. State and Active Ownership

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-26 04:35 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Commit the implementation, then restate the docs/BENCHMARKS.md provenance anchor in a docs-only follow-up commit.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `2026-11-26 04:30 UTC` | `DeepSeek Harness agent (lead)` | `Record created for issue #791` | `N/A` |
| `planned` | `in_progress` | `2026-11-26 04:35 UTC` | `DeepSeek Harness agent (lead)` | `Implementation started` | `N/A` |
| `in_progress` | `awaiting_review` | `2026-11-26 05:45 UTC` | `DeepSeek Harness agent (lead)` | `Implementation and local gates complete` | `Gate output in Verification Evidence` |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `protocols/telemetry-cards.md` - compact status default and expanded-card-only framing
  - `PROMPTKIT.md` - status-cards blockquote and state-guard machine line
  - `QUICKSTART.md` - compact default note
  - `docs/ARCHITECTURE.md` - telemetry default description
  - `workflows/checkpoint.md` - State Health Preflight, archival flow, Honest Telemetry Rule
  - `workflows/doctor.md` - seventh check and lifecycle box
  - `templates/project-profile-template.md` - status-cards and state-guard machine lines
  - `templates/state-tracker-template.md` - bounded projection and measured-only spend ledger
  - `scripts/check-doctor.sh` - check_state_freshness
  - `scripts/check-doctor.ps1` - Check-StateFreshness
  - `scripts/tests/run-doctor-tests.sh` - scenarios S16-S19
  - `scripts/tests/run-doctor-tests.ps1` - scenarios S16-S19
  - `scripts/tests/run-behavioral-contract-tests.sh` - telemetry, checkpoint, doctor pins
  - `scripts/tests/run-behavioral-contract-tests.ps1` - telemetry, checkpoint, doctor pins
  - `scripts/measure-ceremony-overhead.sh` - SETUP baseline 3078
  - `scripts/measure-ceremony-overhead.ps1` - SETUP baseline 3078
  - `docs/BENCHMARKS.md` - workflow and shared-setup figures
  - `CHANGELOG.md` - entry for issue #791
  - `docs/tasks/TASK-2026-11-26-issue-791-telemetry-state-guard.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `git diff --check clean; validate-execution-control VALID|RECORDS=82|ROOT=.; validate-references All references valid; run-token-budget-tests Passed 8 Failed 0; measure-tokens BALANCED|2404|2425|PASS and LITE|1415|1450|PASS; measure-ceremony-overhead CEREMONY_GATE|PASS with SETUP 3078 and all 16 anchors OK; measure-tokenizer-delta four rows PASS; run-doctor-tests Passed 52 Failed 0; run-behavioral-contract-tests Passed 818 Failed 0.`
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: `Not yet available - no push authorized.`
- **Review Evidence**: `N/A`
- **Commit Evidence**: `N/A before commit; the implementation commit and the docs-only provenance follow-up are added after the commit step.`
- **Pull Request Evidence**: `N/A - no PR authorized.`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`

- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 pending; AC-2 pending; AC-3 pending; AC-4 pending`
- **Changed-File Summary**: `Compact telemetry default and halt-only framing across protocol, profile template, PROMPTKIT.md, QUICKSTART.md and ARCHITECTURE.md; checkpoint workflow gains the state-health preflight, archival flow and honest telemetry rule; doctor gains the state-freshness check in both twins with four new scenarios; ceremonial SETUP baseline moves 3,021 to 3,078 tokens because the state tracker template grew; published workflow totals re-propagated.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Awaiting review with local gates green, 2026-11-26 05:45 UTC`
