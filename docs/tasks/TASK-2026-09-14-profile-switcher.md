# Task Record: Add pk:profile runtime profile switcher workflow

<a id="TASK-2026-09-14-profile-switcher"></a>

> **Fill-in status:** Required fields are populated. Evidence fields are `N/A` before implementation and must be linked before `completed`.

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-profile-switcher`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub issue #142 body (canonical design: detect → ask_question → re-inject via init scripts → verify)
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/142`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No tagging, release, or remote operations in this task.`
- **Created**: `2026-09-14 06:50 UTC`

> This Local Task Source is authoritative for this Controlled Work. External trackers and `docs/STATE.md` are references or synchronized projections, not alternate task authority.

## 2. Objective and Boundaries

- **Objective**: Ship `workflows/profile.md` (`pk:profile`) so users switch Lite/Balanced/Turbo at runtime in-session (delegating re-injection to the already-tested `init.sh` / `init.ps1` idempotent path), and reconcile every workflow-count claim honestly (Balanced 23, Lite 6) with a mechanical drift guard so counts cannot silently rot again.
- **In Scope**:
  - `docs/tasks/TASK-2026-09-14-profile-switcher.md` (this record)
  - New `workflows/profile.md` (trigger, mission, ceremony alignment, steps: detect `profile:` → guard flags incl. turbo-experimental → `ask_question` picker → delegate `init.sh/.ps1 --<profile>` → verify `profile:` line, `## 0.` section body, directive token count → telemetry card close)
  - `pk:profile` trigger line added to `templates/agent-directive-template.md` and `templates/agent-directive-lite-template.md`
  - `templates/agent-directive-lite-template.md` header/upgrade-path count truth updated (4 → 6 utility workflows: route, debug, commit, checkpoint, sync, profile)
  - `templates/project-profile-template.md` Section 0 descriptions updated to honest counts and `pk:profile` upgrade mention
  - `init.sh` / `init.ps1`: on re-run with existing `profile:` line, also sync the `## 0. PromptKit OS Profile` body (`**Profile**:` bullet) — residue gap confirmed by pre-flight (sed previously updated the bottom line only); help/picker/upgrade/summary strings updated to true counts and re-measured tokens
  - `scripts/tests/run-behavioral-contract-tests.sh` + `scripts/tests/run-behavioral-contract-tests.ps1`: Scenario M (profile contract, honest Lite count, on-disk count==23 tripwire, stale 21/22-claim detector)
  - `scripts/tests/run-profile-matrix.sh` + `scripts/tests/run-profile-matrix.ps1`: Section 0 body-flip assertion
  - Docs reconciliation: `README.md`, `QUICKSTART.md`, `FAQ.md`, `docs/BENCHMARKS.md`, `docs/INTERESTING-FACTS.md`, `docs/ADOPTION-GUIDE.md`, `templates/lite-profile.md`, `workflows/onboard.md`, `protocols/setup.md`
- **Explicit Non-Goals**:
  - No new installer flags or CLI binary; switching delegates to existing idempotent `init.sh` / `init.ps1` path
  - No auto-migration or rewriting of user-customized directive/PROMPTKIT.md sections beyond the `## 0.` body and marker-block replacement already defined
  - No Turbo autonomy changes (L3 human approval invariant untouched)
  - No release, tag, or deployment actions
- **Dependencies**: #141 strict token gate (merged `9ef6c7c`) · #143 profile matrix + upgrade idempotency proof (merged `77317e2`) — both satisfied
- **Risk**: Medium - doc reconciliation spans many files and is error-prone (mitigation: mechanical count guard in behavioral scenario + `validate-references`); directive grows ~15 tokens per profile (mitigation: #141 gate, headroom Balanced 424 / Lite 655)
- **Verification Condition**: `bash scripts/tests/run-behavioral-contract-tests.sh`, `bash scripts/tests/run-profile-matrix.sh`, `bash scripts/tests/run-token-budget-tests.sh`, `bash scripts/measure-tokens.sh --strict`, `bash scripts/validate-references.sh .` all exit 0 locally; GitHub Actions Linux + Windows jobs green on the PR.

## 3. Acceptance Criteria

- [x] **AC-1**: Given a `profile: lite` host install, when `pk:profile` selects Balanced, then `init.sh --balanced` is applied and `PROMPTKIT.md` shows `profile: balanced` **and** the `## 0. PromptKit OS Profile` body shows Profile: balanced, and `AGENTS.md` contains exactly one directive block matching the full Balanced template.
  - **Result**: Complete 2026-09-14
  - **Evidence**: run-profile-matrix.sh Section-0 assertion + PR CI link
- [x] **AC-2**: Given any current profile, when `pk:profile --turbo` is invoked without experimental acknowledgement, then the switch is refused with the `--turbo requires --experimental` guard message and no file changes (inherited from `init.sh`; workflow must state it).
  - **Result**: Complete 2026-09-14
  - **Evidence**: profile.md guard text + existing matrix guard test
- [x] **AC-3**: Given `PROMPTKIT_NO_INTERACTIVE=1` or a non-interactive host, when `pk:profile` is invoked with no flag, then the agent applies the Balanced default non-interactively (flags or default only, no picker, no hang).
  - **Result**: Complete 2026-09-14
  - **Evidence**: profile.md non-interactive rule + onboard.md/env alignment note
- [x] **AC-4**: Every Balanced workflow-count claim in shipped docs equals the on-disk workflow file count (23 after this PR), Lite claims equal the Lite trigger list (6), and a new behavioral-contract scenario fails CI if a future file/doc drift reappears (also corrects pre-existing "21 workflows pass CI" and "4 workflows" miscounts).
  - **Result**: Complete 2026-09-14
  - **Evidence**: behavioral scenario output + grep reconciliation list in PR
- [x] **AC-5**: After directive additions, `bash scripts/measure-tokens.sh --strict` passes both budgets and docs cite the newly measured token values (no stale 845/2,076 claims if numbers move).
  - **Result**: Complete 2026-09-14
  - **Evidence**: strict gate run output + BENCHMARKS diff
- **Not-Applicable Exception**: None

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes (single-session scope; unlikely to trip)`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `Live host timing and forced generation termination are unavailable in this host; soft/hard checkpoints are protocol discipline, not mechanical enforcement.`

## 5. State and Active Ownership

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-14 06:50 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 06:50 UTC | Implementor agent | Task Record created for approved #142 plan | This record |
| planned | ready | 2026-09-14 06:52 UTC | PromptKit maintainer | Readiness complete: objective, scope, non-goals, AC-1..5, dependencies (#141/#143 merged), verification condition, approval boundary, execution policy all populated | Human plan approval (2 confirmations) + validator readiness fields |
| ready | in_progress | 2026-09-14 06:52 UTC | Implementor agent | Active ownership assumed on branch `142-profile-switcher` after human approved Task Record via picker | Approval selection "Approve record — start coding PR2" |
| in_progress | awaiting_review | 2026-09-14 07:10 UTC | Implementor agent | All verification commands green locally; full change set committed to branch | Section 6 evidence |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-09-14-profile-switcher.md` - this record (commit `4d543d9`)
  - `workflows/profile.md` - new switcher workflow; `templates/agent-directive-template.md` + `templates/agent-directive-lite-template.md` - triggers & honest counts; `templates/project-profile-template.md` - Section 0 descriptions; `init.sh` / `init.ps1` - Section 0 body sync on re-run + count/number updates (commit `1121886`)
  - `scripts/tests/run-behavioral-contract-tests.sh` + `.ps1` - Scenario M drift guards; `scripts/tests/run-profile-matrix.sh` + `.ps1` - Section 0 body-flip assertion (commit `67b5272`)
  - `README.md`, `QUICKSTART.md`, `FAQ.md`, `docs/BENCHMARKS.md`, `docs/INTERESTING-FACTS.md`, `docs/ADOPTION-GUIDE.md`, `templates/lite-profile.md`, `workflows/onboard.md`, `protocols/setup.md` - count & re-measured token reconciliation (this commit)
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery, all green at HEAD: behavioral 68/68 (Scenario M includes on-disk count==23 tripwire + stale 21/22 detector); token budget harness 6/6; profile matrix 8/8 with Section 0 body-flip; init safety suite rc=0; `validate-references.sh` 0 errors; `measure-tokens.sh --strict` PASS (BALANCED 2,110<=2,500; LITE 877<=1,500); `measure-per-task-tokens.sh --strict` PASS all profiles; `validate-execution-control.sh --root .` reports 0 diagnostics for this record.
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: pending on PR (Linux + Windows jobs)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: `4d543d9` (record), `1121886` (workflow+triggers+installer sync), `67b5272` (guards, TDD red), plus this docs reconciliation commit
- **Pull Request Evidence**: branch `142-profile-switcher` -> PR opened upon push (number linked in PR thread)
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: AC-1 Complete (Section 0 body sync + matrix assertion); AC-2 Complete (workflow guard text + inherited init guard, matrix test 4); AC-3 Complete (non-interactive rule in workflow Phase 2.4, matrix test 7); AC-4 Complete (all claims reconciled, Scenario M tripwires green); AC-5 Complete (strict gate green at 877/2,110, docs cite measured values)
- **Changed-File Summary**: 1 new workflow, 1 task record, 2 directives, 1 project template, 2 installer scripts, 4 test harnesses, 8 docs reconciled
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review, Implementor agent, 2026-09-14 07:10 UTC`

### Update (post-merge follow-up, 2026-09-14 08:05 UTC)

Follow-up branch `150-profile-alias-trim` (Refs #142): resolved a trigger collision this task surfaced — `pk:profile` had been an alias of `pk:perf` since v1.0.0 (pre-existing line, not introduced here). Legacy alias retired, the switch-profile alias (dropping the `pk:` prefix token from prose) trimmed, and Scenario M gained a trigger-token uniqueness guard (RED-proven retroactively). Balanced directive re-baselined from 2,110 tok / 8,438 chars (recorded above, true at the time) to **2,099 tok / 8,395 chars**; Lite unchanged at 877 tok. Original evidence values left intact as historical record.
