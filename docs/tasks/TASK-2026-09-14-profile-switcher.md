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
  - New `workflows/profile.md` (trigger, mission, ceremony alignment, steps: detect `profile:` → guard flags incl. turbo-experimental → `ask_question` picker → delegate `init.sh/.ps1 --<profile>` → verify `profile:` line, `## 0.` section body, directive token count → telemetry card close)
  - `pk:profile` trigger line added to `templates/agent-directive-template.md` and `templates/agent-directive-lite-template.md`
  - Lite template header/upgrade-path count truth updated (4 → 6 workflows: route, debug, commit, checkpoint, sync, profile)
  - `init.sh` / `init.ps1`: on re-run with existing `profile:` line, also sync the `## 0. PromptKit OS Profile` body (`**Profile**:` bullet) — residue gap confirmed by pre-flight (sed currently updates bottom line only); help/picker/upgrade strings updated to true counts
  - Behavioral-contract scenario (sh + ps1): `workflows/profile.md` exists; both directives list `pk:profile`; claimed Balanced workflow count equals `ls workflows/*.md | wc -l` (tripwire for future drift)
  - `run-profile-matrix.sh` extension: Section 0 body flip assertion
  - Docs reconciliation: README (feature table, shorthand table, repo layout, "all 21 workflows" legend, token-efficiency rows), QUICKSTART, `protocols/setup.md` reference list, `docs/WORKFLOW-MAP.md` where counts appear, `docs/BENCHMARKS.md` §2/§3 re-measured directive tokens, `templates/lite-profile.md` counts
- **Explicit Non-Goals**:
  - No new installer flags or CLI binary; switching delegates to existing idempotent `init.sh` / `init.ps1` path
  - No auto-migration or rewriting of user-customized directive/PROMPTKIT.md sections beyond the `## 0.` body and marker-block replacement already defined
  - No Turbo autonomy changes (L3 human approval invariant untouched)
  - No release, tag, or deployment actions
- **Dependencies**: #141 strict token gate (merged `9ef6c7c`) · #143 profile matrix + upgrade idempotency proof (merged `77317e2`) — both satisfied
- **Risk**: Medium - doc reconciliation spans many files and is error-prone (mitigation: mechanical count guard in behavioral scenario + `validate-references`); directive grows ~15 tokens per profile (mitigation: #141 gate, headroom Balanced 424 / Lite 655)
- **Verification Condition**: `bash scripts/tests/run-behavioral-contract-tests.sh`, `bash scripts/tests/run-profile-matrix.sh`, `bash scripts/tests/run-token-budget-tests.sh`, `bash scripts/measure-tokens.sh --strict`, `bash scripts/validate-references.sh .` all exit 0 locally; GitHub Actions Linux + Windows jobs green on the PR.

## 3. Acceptance Criteria

- [ ] **AC-1**: Given a `profile: lite` host install, when `pk:profile` selects Balanced, then `init.sh --balanced` is applied and `PROMPTKIT.md` shows `profile: balanced` **and** the `## 0. PromptKit OS Profile` body shows Profile: balanced, and `AGENTS.md` contains exactly one directive block matching the full Balanced template.
  - **Result**: Pending
  - **Evidence**: run-profile-matrix.sh Section-0 assertion + PR CI link
- [ ] **AC-2**: Given any current profile, when `pk:profile --turbo` is invoked without experimental acknowledgement, then the switch is refused with the `--turbo requires --experimental` guard message and no file changes (inherited from `init.sh`; workflow must state it).
  - **Result**: Pending
  - **Evidence**: profile.md guard text + existing matrix guard test
- [ ] **AC-3**: Given `PROMPTKIT_NO_INTERACTIVE=1` or a non-interactive host, when `pk:profile` is invoked with no flag, then the agent applies the Balanced default non-interactively (flags or default only, no picker, no hang).
  - **Result**: Pending
  - **Evidence**: profile.md non-interactive rule + onboard.md/env alignment note
- [ ] **AC-4**: Every Balanced workflow-count claim in shipped docs equals the on-disk workflow file count (23 after this PR), Lite claims equal the Lite trigger list (6), and a new behavioral-contract scenario fails CI if a future file/doc drift reappears (also corrects pre-existing "21 workflows pass CI" and "4 workflows" miscounts).
  - **Result**: Pending
  - **Evidence**: behavioral scenario output + grep reconciliation list in PR
- [ ] **AC-5**: After directive additions, `bash scripts/measure-tokens.sh --strict` passes both budgets and docs cite the newly measured token values (no stale 845/2,076 claims if numbers move).
  - **Result**: Pending
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

- **Execution State**: `in_progress`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: `TASK-2026-09-14-profile-switcher`
- **Start Time**: `2026-09-14 06:50 UTC`
- **Current Actor**: `Implementor agent`
- **Next Action**: `Commit 2: workflows/profile.md + directive triggers + init Section-0 sync`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 06:50 UTC | Implementor agent | Task Record created for approved #142 plan | This record |
| planned | ready | 2026-09-14 06:52 UTC | PromptKit maintainer | Readiness complete: objective, scope, non-goals, AC-1..5, dependencies (#141/#143 merged), verification condition, approval boundary, execution policy all populated | Human plan approval (2 confirmations) + validator readiness fields |
| ready | in_progress | 2026-09-14 06:52 UTC | Implementor agent | Active ownership assumed on branch `142-profile-switcher` after human approved Task Record via picker | Approval selection "Approve record — start coding PR2" |

## 6. Evidence and Completion Gate

- **Changed Files**: (N/A before implementation; will list commit-2/3/4 outputs)
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: (pending — local suites + CI links)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: (pending)
- **Review Evidence**: (pending — human PR review)
- **Commit Evidence**: (pending)
- **Pull Request Evidence**: (pending)
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `in_progress`
- **Acceptance Results**: (pending)
- **Changed-File Summary**: (pending)
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: (pending)
