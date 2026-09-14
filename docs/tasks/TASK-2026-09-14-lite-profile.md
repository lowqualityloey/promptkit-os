# Task Record: Ship lite profile pk:lite for 80% value

<a id="TASK-2026-09-14-lite-profile"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-lite-profile`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: `QUICKSTART.md` tip "Start with just 2 workflows" and due-diligence recommendability gap
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/139`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Requires human confirmation for commit, PR, and README update`
- **Created**: `2026-09-14 01:10 UTC`

## 2. Objective and Boundaries

- **Objective**: Create `pk:lite` profile that installs only 4 workflows (route, debug, commit, checkpoint) for 80% value, reducing learning curve and improving recommendability from 5/10 to 8/10
- **In Scope**:
  - New file `templates/lite-profile.md` or `profiles/lite.md` defining 4-workflow subset
  - Update `init.sh` / `init.ps1` to support `--lite` flag
  - Update `README.md` Quick Start section to promote lite as default for new users
  - Update `QUICKSTART.md` to mention lite profile
  - Measure token saving: lite directive vs full (expected <1,500 tok)
- **Explicit Non-Goals**:
  - No changes to full 22-workflow set
  - No removal of existing workflows
  - No new binaries
  - No SKILL.md migration yet (defer to separate task)
- **Dependencies**: Depends on Change A already landed (ceremony table in directive)
- **Risk**: Low - additive, opt-in flag
- **Verification Condition**: `init.sh --lite /tmp/test-lite` creates only 4 workflows reference and `AGENTS.md` contains lite marker, plus `bash scripts/validate-references.sh /tmp/test-lite` passes

## 3. Acceptance Criteria

- [ ] **AC-1**: Lite profile exists and can be installed via `--lite` flag
  - **Result**: Pending
  - **Evidence**: `bash init.sh --lite /tmp/test-lite && ls /tmp/test-lite/.promptkit/workflows/ | wc -l` or equivalent marker
- [ ] **AC-2**: README promotes lite as default for new users, full as advanced
  - **Result**: Pending
  - **Evidence**: README Quick Start section updated
- [ ] **AC-3**: Token measurement shows lite <1,500 tok static overhead
  - **Result**: Pending
  - **Evidence**: `bash scripts/measure-tokens.sh /tmp/test-lite/AGENTS.md`
- [ ] **AC-4**: Existing full install still works and all contract tests pass
  - **Result**: Pending
  - **Evidence**: `bash scripts/tests/run-behavioral-contract-tests.sh` → Passed: 56 | Failed: 0

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `N/A`
- **Hard Checkpoint**: `N/A`
- **Event-Driven Checkpoints**: `N/A`
- **Stop Conditions**: `Failed verification, broken full install`
- **Host Timer Capability**: `N/A`

## 5. State and Active Ownership

- **Execution State**: `planned`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `N/A`
- **Current Actor**: `PromptKit maintainer`
- **Next Action**: `Create GitHub Issue with labels type:feature, area:tooling, priority/p2, milestone v1.6.0`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 01:10 UTC | maintainer | Task created to address recommendability gap (5/10) from due-diligence | QUICKSTART.md |

## 6. Evidence and Completion Gate

- **Changed Files**: Pending - templates/lite-profile.md, init.sh, init.ps1, README.md, QUICKSTART.md
- **Scope Change Records**: None
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: Pending
- **Behavior IDs**: N/A - TDD Enforcement Mode disabled
- **TDD Intent Register**: N/A - TDD Enforcement Mode disabled
- **TDD Execution Evidence**: N/A - TDD Enforcement Mode disabled
- **TDD Exception Verification**: N/A - Code Work
- **CI Evidence**: Pending
- **Review Evidence**: Pending
- **Commit Evidence**: Pending
- **Pull Request Evidence**: Pending
- **Release Evidence**: N/A
- **Blocker and Resume Condition**: None
