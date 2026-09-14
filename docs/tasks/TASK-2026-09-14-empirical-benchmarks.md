# Task Record: Add empirical benchmarks beyond static token count

<a id="TASK-2026-09-14-empirical-benchmarks"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-empirical-benchmarks`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: `docs/BENCHMARKS.md` and `docs/token-efficiency-review.md#2`
- **External Reference (Optional)**: `GitHub Issue TBD`
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Requires human confirmation for commit, PR, and benchmark methodology`
- **Created**: `2026-09-14 01:05 UTC`

## 2. Objective and Boundaries

- **Objective**: Add measurable, verifiable benchmarks for per-task token payload, time-to-first-action, and total tokens (main + subagents) for same bug fix across promptkit-os vs no framework
- **In Scope**:
  - Update `docs/BENCHMARKS.md` with per-task payload table (pk:fix, pk:plan, pk:ship) measured via bytes/4 convention
  - Add methodology: how measurement was done, repo checkout SHA, model used
  - Add empirical data: time-to-fix for Level 1 bug, regression rate
  - Add script `scripts/measure-per-task-tokens.sh` to automate per-task measurement (optional)
- **Explicit Non-Goals**:
  - No claims without measurement method
  - No A/B against superpowers/gsd-core unless reproducible (avoid unverifiable comparisons)
  - No new CI job required, but measurement script should be documented
- **Dependencies**: Depends on Change A already landed (route.md no longer mandatory)
- **Risk**: Medium - benchmark methodology can be criticized if not reproducible
- **Verification Condition**: `docs/BENCHMARKS.md` contains per-task table with SHA, method, and numbers that can be reproduced via `bash scripts/measure-tokens.sh` and manual workflow load

## 3. Acceptance Criteria

- [ ] **AC-1**: BENCHMARKS.md contains per-task payload for pk:fix, pk:plan, pk:ship with before/after A
  - **Result**: Pending
  - **Evidence**: Table with measured tok values, SHA `c34be80`, method `bytes/4`
- [ ] **AC-2**: Time-to-first-action (TTFA) measured: time from prompt to first file read
  - **Result**: Pending
  - **Evidence**: Documented TTFA with/without route.md load, 3-6 sec saving claim verified or corrected
- [ ] **AC-3**: No unverifiable marketing claims remain (90% saving clarified as static-only)
  - **Result**: Pending
  - **Evidence**: BENCHMARKS.md section 2 updated to distinguish static vs per-task
- [ ] **AC-4**: Reference validator still passes
  - **Result**: Pending
  - **Evidence**: `bash scripts/validate-references.sh .`

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `N/A`
- **Hard Checkpoint**: `N/A`
- **Event-Driven Checkpoints**: `N/A`
- **Stop Conditions**: `Missing benchmark methodology, unverifiable claims`
- **Host Timer Capability**: `N/A`

## 5. State and Active Ownership

- **Execution State**: `planned`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `N/A`
- **Current Actor**: `PromptKit maintainer`
- **Next Action**: `Create GitHub Issue with labels type:docs, area:tooling, priority/p1, milestone v1.6.0`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 01:05 UTC | maintainer | Task created to address benchmark gap identified in due-diligence | docs/BENCHMARKS.md |

## 6. Evidence and Completion Gate

- **Changed Files**: Pending - docs/BENCHMARKS.md, optionally scripts/measure-per-task-tokens.sh
- **Scope Change Records**: None
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: Pending
- **Behavior IDs**: N/A - TDD Enforcement Mode disabled
- **TDD Intent Register**: N/A - TDD Enforcement Mode disabled
- **TDD Execution Evidence**: N/A - TDD Enforcement Mode disabled
- **TDD Exception Verification**: Exception verification for Documentation Work - will link benchmark method
- **CI Evidence**: Pending
- **Review Evidence**: Pending
- **Commit Evidence**: Pending
- **Pull Request Evidence**: Pending
- **Release Evidence**: N/A
- **Blocker and Resume Condition**: None
