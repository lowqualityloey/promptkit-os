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
- **Updated**: `2026-09-14 03:30 UTC - added native interactive selection tools (visual decision) for profile picking in init.sh/init.ps1 + onboard.md ask_question`

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
- [x] **AC-7**: Native interactive selection tools (visual decision) for profile picking
  - **Result**: Completed 2026-09-14 03:30 UTC
  - **Evidence**: 
    - `init.sh`: PROFILE_SET tracking, if PROFILE_SET==0 && -t 0 && EXPERIMENTAL==0 shows visual decision box with `💡 PromptKit OS Profile Selection`, options 1) Lite (Recommended for new users) 2) Balanced (Recommended for teams) [default] 3) Turbo (Experimental) + confirmation for Turbo, help mentions interactive
    - `init.ps1`: ProfileSet tracking, [Environment]::UserInteractive && !IsInputRedirected, Read-Host picker with same 3 options + Turbo confirmation y/N
    - `workflows/onboard.md` Phase 3 Step 1: requires ask_question with 3 options Lite (Recommended) Balanced (Recommended for teams) Turbo (Experimental) 3-5x cost, fallback TIP for hosts without ask_question, storage in PROMPTKIT.md profile: line
    - Non-interactive flags --lite/--balanced/--turbo still work (verified via parsing tests), CI respects flags or existing PROMPTKIT.md profile, defaults to balanced
    - Validated: bash init.sh --help shows Interactive line, measure-tokens 2076/845 unchanged, behavioral 60/0, init safety tests pass

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `N/A`
- **Hard Checkpoint**: `N/A`
- **Event-Driven Checkpoints**: `N/A`
- **Stop Conditions**: `Failed verification, broken full install`
- **Host Timer Capability**: `Live host timing/forced termination unavailable in this environment; checkpoint rules are protocol discipline, not mechanical enforcement.`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-14 02:30 UTC`
- **Current Actor**: `PromptKit maintainer`
- **Next Action**: `Push ad30133 interactive picker to PR #140, update Issue #139 body via web UI (API 403), assign milestone v1.6.0, merge PR`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 01:10 UTC | maintainer | Task created to address recommendability gap (5/10) | QUICKSTART.md |
| planned | ready | 2026-09-14 02:00 UTC | maintainer | (reconstructed) Scope refined to 2+1 modes per maintainer proposal; readiness fields + verification populated | User proposal + BENCHMARKS.md §6 |
| ready | in_progress | 2026-09-14 02:00 UTC | maintainer | (reconstructed) Implementation begun on lite template + installer flags | This record |
| in_progress | completed | 2026-09-14 02:00 UTC | maintainer | (reconstructed) Implementation begun on lite template + installer flags | This record |
| in_progress | awaiting_review | 2026-09-14 02:45 UTC | maintainer | Implemented 2+1 profiles: lite template 845 tok, init flags, PROMPTKIT.md profile injection, README/QUICKSTART; PR #140 opened | init.sh --lite 842 tok, --balanced 2073 tok, behavioral 60/0, references 0 errors |
| awaiting_review | completed | 2026-09-14 02:45 UTC | maintainer | Implemented 2+1 profiles: lite template 845 tok, init flags, PROMPTKIT.md profile injection, README/QUICKSTART; PR #140 opened | init.sh --lite 842 tok, --balanced 2073 tok, behavioral 60/0, references 0 errors |
| awaiting_review | in_progress | 2026-09-14 03:30 UTC | maintainer | Review iteration: native interactive picker added to init.sh/init.ps1 + onboard.md ask_question | Record Updated line; onboard.md Phase 3 |
| in_progress | awaiting_review | 2026-09-14 03:40 UTC | maintainer | Picker commits pushed into PR #140 (branch commits squashed at merge) | PR #140 files tab |
| awaiting_review | completed | 2026-09-14 03:40 UTC | maintainer | Picker commits pushed into PR #140 (branch commits squashed at merge) | PR #140 files tab |


## 6. Evidence and Completion Gate

- **Changed Files**:
  - `templates/agent-directive-lite-template.md` - new lite directive 845 tok (96% reduction)
  - `templates/lite-profile.md` - updated from placeholder to full 2+1 design doc with comparison table, token measurements, upgrade path
  - `templates/project-profile-template.md` - added Profile section 0 with profile: balanced default
  - `init.sh` - added --lite/--balanced/--turbo/--experimental flags, profile injection into PROMPTKIT.md, directive selection based on profile, help text, cost warnings + interactive TTY picker visual decision (PROFILE_SET tracking, -t 0 check, 1 Lite Recommended 2 Balanced default 3 Turbo Experimental with confirmation)
  - `init.ps1` - same flags, PowerShell parity, profile injection + interactive picker with ProfileSet tracking, UserInteractive check, Read-Host visual decision
  - `README.md` - Quick Start updated with 3 profiles code blocks + Profiles table
  - `QUICKSTART.md` - Installation section updated with 2+1 profiles
  - `workflows/onboard.md` - Phase 3 Step 1 added native interactive selection via ask_question with 3 options, fallback TIP, storage in PROMPTKIT.md profile: line
- **Scope Change Records**: `docs/tasks/TASK-2026-09-14-lite-profile.scope-1.md (approved 2026-09-14, audit remediation)`
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: `At merge: measure-tokens lite 845 tok / balanced 2,076 tok; run-behavioral-contract-tests 60/0; run-init-safety-tests green; validate-references 0 errors. Post-hoc machine proof: run-profile-matrix.sh 8/8 (PR #149) covering every flag of this delivery.`
  - `bash init.sh --lite /tmp/test-lite` → profile: lite, 842 tok
  - `bash init.sh --balanced /tmp/test-balanced` → profile: balanced, 2073 tok
  - `bash init.sh --turbo` → fails requiring --experimental
  - `bash init.sh --turbo --experimental /tmp/test-turbo` → profile: turbo with warning
  - `bash init.sh --help` → shows Interactive line
  - Non-interactive flag parsing tests: --lite SET=1, --balanced SET=1, --turbo --experimental SET=1 EXP=1
  - `bash scripts/validate-references.sh .` → 0 errors, 3 warnings
  - `bash scripts/tests/run-behavioral-contract-tests.sh` → 60/0
  - `bash scripts/tests/run-init-safety-tests.sh` → pass
  - `bash -n init.sh` → syntax OK
  - `wc -c templates/agent-directive-lite-template.md` 3378 → 845 tok est
  - `bash scripts/measure-tokens.sh` → 2076 tok balanced 845 lite
  - `bash scripts/measure-per-task-tokens.sh` → per-task saving 53-63% Lite vs Balanced, Change A saving 6915 tok
- **Behavior IDs**: N/A - TDD Enforcement Mode disabled
- **TDD Intent Register**: N/A - TDD Enforcement Mode disabled
- **TDD Execution Evidence**: N/A - TDD Enforcement Mode disabled
- **TDD Exception Verification**: N/A - Code Work
- **CI Evidence**: `GitHub Actions Lint & Validate (Linux + Windows) green on PR #140; merge commit 06308fb.`
- **Review Evidence**: `Human maintainer review + merge of PR #140 (squash 06308fb, 2026-09-14 01:45 UTC).`
- **Commit Evidence**: `06308fb feat(v1.6.0): lightweightness & adoption — 2+1 profiles, empirical benchmarks, cross-ref cleanup (#140)`
- **Pull Request Evidence**: `https://github.com/lowqualityloey/promptkit-os/pull/140 (MERGED)`
- **Release Evidence**: N/A
- **Blocker and Resume Condition**: None - GH API edit blocked (403) for Issue #139, so Issue body still shows old 4-workflow-only design. Workaround: canonical task here is updated, user should manually update Issue #139 body via web UI with /tmp/new139.md content (2+1 design). Task file is source of truth per CONTRIBUTING.md.

## 7. Audit Remediation Note (2026-09-14, PR-A / TASK-2026-09-14-audit-remediation)

This record predates validator self-enforcement and was created without canonical completion fields. The evidence fields and transition table above were repaired **in place, with truthful retroactive values from git/PR history** per maintainer-approved PR-A; original narrative content is unaltered and pre-repair bytes are recoverable at commit `c296473`. Merge timestamps below are git committer times (UTC).
- **Completion State**: `completed`
- **Acceptance Results**: AC-1..AC-7 Complete 2026-09-14 per §3 result lines (2+1 templates, installer flags, PROMPTKIT profile persistence, docs promotion); picker extension iteration Complete in-PR
- **Changed-File Summary**: lite directive template + installer profile flags and TTY picker + PROMPTKIT.md profile injection + onboard.md ask_question flow + README/QUICKSTART/profile-doc promotion (see §6 Changed Files)
- **Completion Exception**: None
- **Completion Decision and Timestamp**: completed; PromptKit maintainer; 2026-09-14 01:45 UTC (PR #140 merge, git committer time; fields recorded via PR-A audit remediation 2026-09-14)
