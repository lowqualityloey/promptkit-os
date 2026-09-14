# Task Record: Collapse cross-reference tails in workflows

<a id="TASK-2026-09-14-cross-ref-tails"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-cross-ref-tails`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: `docs/token-efficiency-review.md#5c`
- **External Reference (Optional)**: `GitHub Issue TBD - will link after creation`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Requires human confirmation for commit and PR`
- **Created**: `2026-09-14 01:00 UTC`

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
- **Verification Condition**: `bash scripts/validate-references.sh .` exits 0 and `bash scripts/tests/run-behavioral-contract-tests.sh` passes 56/0

## 3. Acceptance Criteria

- [ ] **AC-1**: All 7 workflows no longer contain duplicated resource blocks, only one-line pointer remains
  - **Result**: Pending
  - **Evidence**: `git diff --stat workflows/` and `grep -R "Related Resources" workflows/ | wc -l == 0`
- [ ] **AC-2**: Reference validator passes with no broken links
  - **Result**: Pending
  - **Evidence**: `bash scripts/validate-references.sh .` → All references valid
- [ ] **AC-3**: Behavioral contract tests still pass
  - **Result**: Pending
  - **Evidence**: `bash scripts/tests/run-behavioral-contract-tests.sh` → Passed: 56 | Failed: 0
- [ ] **AC-4**: Token saving measured: ~1,688 bytes removed from workflow set
  - **Result**: Pending
  - **Evidence**: `wc -c workflows/*.md` before/after

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

- **Execution State**: `planned`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `N/A`
- **Current Actor**: `PromptKit maintainer`
- **Next Action**: `Create GitHub Issue with labels type:refactor, area:tooling, priority/p2, milestone v1.6.0`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 01:00 UTC | maintainer | Task created from token-efficiency-review §5C | docs/token-efficiency-review.md |

## 6. Evidence and Completion Gate

- **Changed Files**: Pending
- **Scope Change Records**: None
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: Pending
- **Behavior IDs**: N/A - TDD Enforcement Mode disabled
- **TDD Intent Register**: N/A - TDD Enforcement Mode disabled
- **TDD Execution Evidence**: N/A - TDD Enforcement Mode disabled
- **TDD Exception Verification**: N/A - Code Work exception not applicable, this is refactor
- **CI Evidence**: Pending
- **Review Evidence**: Pending
- **Commit Evidence**: Pending
- **Pull Request Evidence**: Pending
- **Release Evidence**: N/A
- **Blocker and Resume Condition**: None
