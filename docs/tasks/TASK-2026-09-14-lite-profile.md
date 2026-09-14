# Task Record: Ship lite profile with 2+1 modes (Lite, Balanced, Turbo Experimental)

<a id="TASK-2026-09-14-lite-profile"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-lite-profile`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: `QUICKSTART.md` tip "Start with just 2 workflows", due-diligence recommendability gap, and user proposal for Lite/Balanced/Turbo onboarding
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/139` + comment with 2+1 design (GH API blocked edit, see below)
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Requires human confirmation for commit, PR, and README update`
- **Created**: `2026-09-14 01:10 UTC`
- **Updated**: `2026-09-14 02:00 UTC - refined to 2+1 modes per cross-exam`

## 2. Objective and Boundaries

- **Objective**: Create onboarding with modes Lite/Balanced/Turbo(Experimental) to fix recommendability 5/10 → 8/10. Lite = 4 workflows <1,500 tok (80% value). Balanced = current full 22 workflows with Level 0-3 (already ai+human). Turbo = Balanced + parallel subagent waves, experimental, warns 3-5x token cost, still requires human approval for L3.
- **In Scope**:
  - New file `templates/lite-profile.md` or `profiles/lite.md` defining 4-workflow subset (route, debug, commit, checkpoint)
  - Update `init.sh` / `init.ps1` to support `--lite`, `--balanced` (default), `--turbo --experimental` flags
  - Store `profile: lite|balanced|turbo` in `PROMPTKIT.md` so agent doesn't re-ask
  - Update `README.md` Quick Start to promote Lite vs Balanced, Turbo marked Experimental with cost warning
  - Update `QUICKSTART.md` to mention lite profile
  - Measure token saving: lite directive vs full (expected <1,500 tok vs 1,929 tok)
  - Onboarding UX: 1 question with recommended default, not 3 equal choices (avoid paralysis)
- **Explicit Non-Goals**:
  - No fully autonomous Turbo that auto-decides releases/tags/deploys — breaks Level 3 safety (requires human approval)
  - No auto-checkpoint detection hook (requires hooks/*.js like gsd-core, out of scope for v1.6.0, zero binaries promise)
  - No hallucination eval harness (defer to separate task, needs superpowers-evals style harness)
  - No removal of existing 22 workflows
  - No SKILL.md migration yet (defer)
- **Dependencies**: Depends on Change A already landed (ceremony table in directive now in template)
- **Risk**: Low for Lite+Balanced (additive, opt-in), Medium for Turbo experimental (token cost, user expectations)
- **Verification Condition**: `init.sh --lite /tmp/test-lite` creates PROMPTKIT.md with profile: lite and AGENTS.md <1,500 tok, plus `bash scripts/validate-references.sh /tmp/test-lite` passes; balanced still passes 56/0 contract tests

## 3. Acceptance Criteria

- [ ] **AC-1**: Lite profile exists and can be installed via `--lite` flag, stores profile: lite
  - **Result**: Pending
  - **Evidence**: `bash init.sh --lite /tmp/test-lite && cat /tmp/test-lite/PROMPTKIT.md | grep profile && ls /tmp/test-lite/.promptkit/workflows/ | wc -l`
- [ ] **AC-2**: Balanced is default (no flag or --balanced), stores profile: balanced, full 22 workflows
  - **Result**: Pending
  - **Evidence**: `bash init.sh /tmp/test-balanced && grep profile /tmp/test-balanced/PROMPTKIT.md`
- [ ] **AC-3**: Turbo experimental requires --experimental flag, warns about 3-5x token cost, stores profile: turbo, still requires human approval for L3
  - **Result**: Pending
  - **Evidence**: `bash init.sh --turbo --experimental /tmp/test-turbo 2>&1 | grep -i "experimental\|cost\|warning"`
- [ ] **AC-4**: README promotes Lite (Recommended for new users) vs Balanced (Recommended for teams), Turbo marked Experimental
  - **Result**: Pending
  - **Evidence**: README Quick Start section updated with 3 modes and cost warning
- [ ] **AC-5**: Token measurement shows lite <1,500 tok static overhead vs 1,929 tok balanced
  - **Result**: Pending
  - **Evidence**: `bash scripts/measure-tokens.sh /tmp/test-lite/AGENTS.md` and `/tmp/test-balanced/AGENTS.md`
- [ ] **AC-6**: Existing full/balanced install still works and all contract tests pass
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
- **Next Action**: `Implement init.sh --lite/--balanced/--turbo flags + PROMPTKIT.md profile field, update README, verify tokens`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 01:10 UTC | maintainer | Task created to address recommendability gap (5/10) from due-diligence | QUICKSTART.md |
| planned | planned | 2026-09-14 02:00 UTC | maintainer | Refined to 2+1 modes per user proposal cross-exam: Lite official, Balanced official default, Turbo experimental with cost warning. GH Issue #139 edit blocked by integration permissions (403), so canonical update here is source of truth. | User proposal + BENCHMARKS.md §6 + Level 3 safety |

## 6. Evidence and Completion Gate

- **Changed Files**: Pending - templates/lite-profile.md, init.sh, init.ps1, README.md, QUICKSTART.md, PROMPTKIT.md template
- **Scope Change Records**: None - refinement within same objective, not scope change
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: Pending
- **Behavior IDs**: N/A - TDD Enforcement Mode disabled
- **TDD Intent Register**: N/A - TDD Enforcement Mode disabled
- **TDD Execution Evidence**: N/A - TDD Enforcement Mode disabled
- **TDD Exception Verification**: N/A - Code Work
- **CI Evidence**: Pending
- **Review Evidence**: Pending
- **Commit Evidence**: Pending - will link after commit
- **Pull Request Evidence**: Pending
- **Release Evidence**: N/A
- **Blocker and Resume Condition**: None - GH API edit blocked (403 Resource not accessible by integration) for Issue #139, so Issue body still shows old 4-workflow-only design. Workaround: canonical task here is updated, and user should manually update Issue #139 body or add comment via GitHub web UI. Task file is source of truth per CONTRIBUTING.md.
