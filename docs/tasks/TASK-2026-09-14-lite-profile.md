# Task Record: Ship lite profile with 2+1 modes (Lite, Balanced, Turbo Experimental)

<a id="TASK-2026-09-14-lite-profile"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-lite-profile`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: `QUICKSTART.md` tip "Start with just 2 workflows", due-diligence recommendability gap, and user proposal for Lite/Balanced/Turbo onboarding
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/139` + comment with 2+1 design (GH API blocked edit, canonical task here is source of truth)
- **Owner / Actor**: `PromptKit maintainer`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Requires human confirmation for commit, PR, and README update`
- **Created**: `2026-09-14 01:10 UTC`
- **Updated**: `2026-09-14 02:45 UTC - implemented 2+1 profiles, verified tokens`

## 2. Objective and Boundaries

- **Objective**: Create onboarding with modes Lite/Balanced/Turbo(Experimental) to fix recommendability 5/10 → 8/10. Lite = 4 workflows <1,500 tok (80% value). Balanced = current full 22 workflows with Level 0-3 (already ai+human). Turbo = Balanced + parallel subagent waves, experimental, warns 3-5x token cost, still requires human approval for L3.
- **In Scope**:
  - New file `templates/agent-directive-lite-template.md` (lite directive 845 tok) + `templates/lite-profile.md` design doc
  - Update `init.sh` / `init.ps1` to support `--lite`, `--balanced` (default), `--turbo --experimental` flags + help
  - Store `profile: lite|balanced|turbo` in `PROMPTKIT.md` so agent doesn't re-ask (machine-readable + human section)
  - Update `README.md` Quick Start and `QUICKSTART.md` to promote Lite vs Balanced, Turbo marked Experimental with cost warning
  - Update `templates/project-profile-template.md` to include Profile section by default
  - Measure token saving: lite 845 tok vs balanced 2076 tok (-59%)
- **Explicit Non-Goals**:
  - No fully autonomous Turbo that auto-decides releases/tags/deploys — breaks Level 3 safety
  - No auto-checkpoint detection hook (requires hooks/*.js like gsd-core, out of scope for v1.6.0)
  - No hallucination eval harness (defer)
  - No removal of existing 22 workflows
- **Dependencies**: Depends on Change A already landed (ceremony table in directive)
- **Risk**: Low for Lite+Balanced (additive, opt-in), Medium for Turbo experimental (token cost, user expectations)
- **Verification Condition**: `init.sh --lite /tmp/test-lite` creates PROMPTKIT.md with profile: lite and AGENTS.md <1,500 tok, balanced still passes 60/0 contract tests, reference validator 0 errors

## 3. Acceptance Criteria

- [x] **AC-1**: Lite profile exists and can be installed via `--lite` flag, stores profile: lite
  - **Result**: Completed 2026-09-14
  - **Evidence**: `bash init.sh --lite /tmp/test-lite` → PROMPTKIT.md contains `profile: lite` (line 115), AGENTS.md contains `PromptKit OS Lite` (4 workflows), `wc -c` 3370 bytes, `measure-tokens.sh` 842 tok (96% reduction)
- [x] **AC-2**: Balanced is default (no flag or --balanced), stores profile: balanced, full 22 workflows
  - **Result**: Completed
  - **Evidence**: `bash init.sh --balanced /tmp/test-balanced` → `profile: balanced`, AGENTS.md 2073 tok (89% reduction), 22 workflows via convention
- [x] **AC-3**: Turbo experimental requires --experimental flag, warns about 3-5x token cost, stores profile: turbo, still requires human approval for L3
  - **Result**: Completed
  - **Evidence**: `bash init.sh --turbo /tmp/test-turbo` → fails with "[!] --turbo requires --experimental flag" + warning about 3-5x cost and human L3 approval. `bash init.sh --turbo --experimental /tmp/test-turbo` → success, `profile: turbo`, warning printed
- [x] **AC-4**: README promotes Lite (Recommended for new users) vs Balanced (Recommended for teams), Turbo marked Experimental
  - **Result**: Completed
  - **Evidence**: README.md Quick Start updated with 3 code blocks for --balanced, --lite, --turbo --experimental + Profiles table with token counts. QUICKSTART.md similarly updated.
- [x] **AC-5**: Token measurement shows lite <1,500 tok static overhead vs 2,076 tok balanced
  - **Result**: Completed
  - **Evidence**: Lite 3,378 chars → 845 tok (measured via scripts/measure-tokens.sh), Balanced 8,303 chars → 2,076 tok. Saving 1,231 tok (-59%). Both pass budget <=2500.
- [x] **AC-6**: Existing full/balanced install still works and all contract tests pass
  - **Result**: Completed
  - **Evidence**: `bash scripts/tests/run-behavioral-contract-tests.sh` → Passed: 60 | Failed: 0, `bash scripts/validate-references.sh .` → 0 errors, 3 warnings, `bash -n init.sh` syntax OK

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

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-14 02:30 UTC`
- **Current Actor**: `PromptKit maintainer`
- **Next Action**: `Update GitHub Issue #139 via web UI (API 403 blocked), then close #139 and #137 manually, start #138 benchmarks`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 01:10 UTC | maintainer | Task created to address recommendability gap (5/10) | QUICKSTART.md |
| planned | planned | 2026-09-14 02:00 UTC | maintainer | Refined to 2+1 modes per user proposal cross-exam | User proposal + BENCHMARKS.md §6 + L3 safety |
| planned | completed | 2026-09-14 02:45 UTC | maintainer | Implemented 2+1 profiles: lite template 845 tok, init.sh/init.ps1 flags, PROMPTKIT.md profile injection, README/QUICKSTART updated, verified tokens and validators | init.sh --lite 842 tok, --balanced 2073 tok, behavioral 60/0, references 0 errors |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `templates/agent-directive-lite-template.md` - new lite directive 845 tok (96% reduction)
  - `templates/lite-profile.md` - updated from placeholder to full 2+1 design doc with comparison table, token measurements, upgrade path
  - `templates/project-profile-template.md` - added Profile section 0 with profile: balanced default
  - `init.sh` - added --lite/--balanced/--turbo/--experimental flags, profile injection into PROMPTKIT.md, directive selection based on profile, help text, cost warnings
  - `init.ps1` - same flags, PowerShell parity, profile injection
  - `README.md` - Quick Start updated with 3 profiles code blocks + Profiles table
  - `QUICKSTART.md` - Installation section updated with 2+1 profiles
- **Scope Change Records**: None - refinement within same objective
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: 
  - `bash init.sh --lite /tmp/test-lite` → profile: lite, 842 tok
  - `bash init.sh --balanced /tmp/test-balanced` → profile: balanced, 2073 tok
  - `bash init.sh --turbo` → fails requiring --experimental
  - `bash init.sh --turbo --experimental /tmp/test-turbo` → profile: turbo with warning
  - `bash scripts/validate-references.sh .` → 0 errors, 3 warnings
  - `bash scripts/tests/run-behavioral-contract-tests.sh` → 60/0
  - `bash -n init.sh` → syntax OK
  - `wc -c templates/agent-directive-lite-template.md` 3378 → 845 tok est
- **Behavior IDs**: N/A - TDD Enforcement Mode disabled
- **TDD Intent Register**: N/A - TDD Enforcement Mode disabled
- **TDD Execution Evidence**: N/A - TDD Enforcement Mode disabled
- **TDD Exception Verification**: N/A - Code Work
- **CI Evidence**: Local green, full CI will run on PR (Linux + Windows)
- **Review Evidence**: Pending - requires human review
- **Commit Evidence**: Will be added after commit
- **Pull Request Evidence**: Pending
- **Release Evidence**: N/A
- **Blocker and Resume Condition**: None - GH API edit blocked (403) for Issue #139, so Issue body still shows old 4-workflow-only design. Workaround: canonical task here is updated, user should manually update Issue #139 body via web UI with /tmp/new139.md content (2+1 design). Task file is source of truth per CONTRIBUTING.md.
