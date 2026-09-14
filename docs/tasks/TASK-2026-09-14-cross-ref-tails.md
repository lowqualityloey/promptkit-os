# Task Record: Collapse cross-reference tails in workflows

<a id="TASK-2026-09-14-cross-ref-tails"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-cross-ref-tails`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: `docs/token-efficiency-review.md#5c`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/137`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Requires human confirmation for commit and PR`
- **Created**: `2026-09-14 01:00 UTC`
- **Updated**: `2026-09-14 02:15 UTC - verified already implemented`

## 2. Objective and Boundaries

- **Objective**: Remove ~1,688 tokens of duplicated Related Resources / See Also tails from 7 workflows, replace with one-line pointer to WORKFLOW-MAP.md
- **In Scope**:
  - `workflows/*.md` files containing `## Related Resources`, `### See Also`, `For Beginners`, `For Teams`, `Visual Maps` blocks
  - Update to single line: `See docs/WORKFLOW-MAP.md for full navigation`
  - Verify with `bash scripts/validate-references.sh .`
- **Explicit Non-Goals**:
  - No changes to workflow semantics, only tails
  - No changes to `docs/WORKFLOW-MAP.md` itself
  - No new validators or CI jobs
- **Dependencies**: None
- **Risk**: Low - pure deletion, link validator will catch broken refs
- **Verification Condition**: `bash scripts/validate-references.sh .` exits 0 for workflows and `bash scripts/tests/run-behavioral-contract-tests.sh` passes

## 3. Acceptance Criteria

- [x] **AC-1**: All 7 workflows no longer contain duplicated resource blocks, only one-line pointer remains
  - **Result**: Completed 2026-09-14 - already collapsed
  - **Evidence**: `grep -rn "For Beginners\|For Teams\|Visual Maps" workflows/` → 0 results. `grep -c "Related References" workflows/*.md` shows 8 files with 1 each (single-line pointer `Canonical workflow navigation: docs/WORKFLOW-MAP.md`), 14 with 0. No 160-line tails remain. Desired state achieved.
- [x] **AC-2**: Reference validator passes for workflows
  - **Result**: Completed - workflows all ✅. Full repo shows 2 BROKEN only from TASK-2026-09-14-lite-profile.md referencing not-yet-created templates/lite-profile.md (expected, will be fixed by placeholder)
  - **Evidence**: `bash scripts/validate-references.sh .` workflows section all green, behavioral tests Pass 60/0
- [x] **AC-3**: Behavioral contract tests still pass
  - **Result**: Completed
  - **Evidence**: `bash scripts/tests/run-behavioral-contract-tests.sh` → Passed: 60 | Failed: 0 (up from 56 after #136)
- [x] **AC-4**: Token saving measured
  - **Result**: Completed - already collapsed, no further saving needed. Current `wc -l workflows/*.md` = 4315 total, single-line pointer is minimal.

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `N/A - small task`
- **Hard Checkpoint**: `N/A - small task`
- **Event-Driven Checkpoints**: `N/A`
- **Stop Conditions**: `Failed verification, missing approval`
- **Host Timer Capability**: `N/A`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-14 02:15 UTC`
- **Current Actor**: `PromptKit maintainer`
- **Next Action**: `Close GitHub Issue #137 as completed, already implemented before task creation`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 01:00 UTC | maintainer | Task created from token-efficiency-review §5C | docs/token-efficiency-review.md |
| planned | completed | 2026-09-14 02:15 UTC | maintainer | Verified already implemented: grep shows 0 duplicated tails, 8 files with single-line pointer, 14 with 0. No code change needed. | grep -rn + validate-references + behavioral tests 60/0 |

## 6. Evidence and Completion Gate

- **Changed Files**: None - already in desired state since c34be80
- **Scope Change Records**: None
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: `grep -rn "Related Resources" workflows/` shows 8 files with 1-line pointer, `validate-references.sh` workflows ✅, `run-behavioral-contract-tests.sh` 60/0, `measure-tokens.sh` 2076 tok (budget 2500)
- **Behavior IDs**: N/A - TDD Enforcement Mode disabled
- **TDD Intent Register**: N/A - TDD Enforcement Mode disabled
- **TDD Execution Evidence**: N/A - TDD Enforcement Mode disabled
- **TDD Exception Verification**: N/A
- **CI Evidence**: Local: behavioral 60/0, measure-tokens 2076 tok passes, reference validator workflows green (2 errors only from pending lite-profile placeholder)
- **Review Evidence**: N/A - no code change
- **Commit Evidence**: N/A - no commit needed, already implemented in main history
- **Pull Request Evidence**: N/A
- **Release Evidence**: N/A
- **Blocker and Resume Condition**: None
