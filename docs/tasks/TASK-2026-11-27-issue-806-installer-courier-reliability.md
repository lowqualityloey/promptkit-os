# Task Record: Make the installer courier reliable — cancel cleanup, Bash 3 fallback, atomic --update, solo-fast and codex
<a id="TASK-2026-11-27-issue-806-installer-courier-reliability"></a>

## Identity
- **Record Type**: `Task Record`
- **Record Form**: `Lite`
- **Task ID**: `TASK-2026-11-27-issue-806-installer-courier-reliability`
- **Ceremony Level**: `Level 2 (Controlled)`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/806`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: `promptkit-os repository on branch fix/806-installer-courier-reliability; the dual-entry-point installers, the terminal picker, the npm courier wrapper, their Bash regression suites, CHANGELOG.md and this record. Local implementation, verification and one commit on the dedicated branch only.`
- **Approval Boundary**: `Local implementation, verification and commits on a dedicated branch only. Push, PR creation, merge, force-push, squash/rebase/amend, tag, release and issue closure remain unauthorized until the operator approves a review checkpoint.`
- **Created**: `2026-11-27 08:05 UTC`

## Boundaries
- **Objective**: `Ship issue #806: a cancelled fresh courier run leaves no partial .promptkit/, the picker degrades to the numbered menu on Bash 3 and a bare b is no longer a phantom back action, --update replaces a courier install atomically with a 30-second fetch timeout, and --solo-fast plus --host=codex work across init.sh, init.ps1 and the courier wrapper.`
- **In Scope**:
  - `init.sh`
  - `init.ps1`
  - `scripts/terminal-picker.sh`
  - `package/bin/promptkit-os.js`
  - `scripts/tests/run-init-safety-tests.sh`
  - `scripts/tests/run-terminal-picker-tests.sh`
  - `scripts/tests/run-courier-integrity-pin-fixtures.sh`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-27-issue-806-installer-courier-reliability.md`
- **Explicit Non-Goals**:
  - `No push, PR creation, merge, tag or release in this task.`
  - `No change to the default profile, the Balanced budget or the transaction model in init.sh.`
  - `No PowerShell execution: pwsh is unavailable in this host, so init.ps1 was reviewed and parity-grepped but not run; the Bash suites remain the executable gate.`
  - `No --strip-directives work: that is issue #807 on its own branch.`
- **Dependencies**: `None. Issue #806 is self-contained; #807 and #808 follow on their own branches.`
- **Risk**: `Medium` - `The wrapper owns the only destructive path in the installer, and a bad swap would delete a working kit; mitigated by extracting to staging, backing up the previous kit, restoring it on failure, refusing --force and submodule installs, and by six courier-policy fixtures that pin the cancel, refusal and replace directions.`
- **Verification Condition**: `bash scripts/tests/run-init-safety-tests.sh, bash scripts/tests/run-terminal-picker-tests.sh, bash scripts/tests/run-courier-integrity-pin-fixtures.sh, bash scripts/tests/run-behavioral-contract-tests.sh, bash scripts/tests/run-doctor-tests.sh, bash scripts/validate-references.sh . --strict, bash scripts/validate-execution-control.sh --root . --strict, bash scripts/measure-ceremony-overhead.sh, bash scripts/scan-staged-secrets.sh ., bash scripts/check-changelog-entry.sh and git diff --check all exit 0.`

## Acceptance Criteria
- [ ] **AC-1**: `A fresh non-force courier run that exits 130 removes the .promptkit/ it just created, reports the removal, and propagates exit 130; an existing install and a --force overlay are left untouched with their own message.`
  - **Result**: `Pending`
  - **Evidence**: `scripts/tests/run-courier-integrity-pin-fixtures.sh cancel-removes-fresh-kit and cancel-keeps-forced-overlay`
- [ ] **AC-2**: `init.sh forces PICKER_TTY=0 when BASH_VERSINFO[0] is below 4, the Turbo confirmation reaches cancel_setup on EOF, and a bare b in the terminal picker reports other rather than an unimplemented back action.`
  - **Result**: `Pending`
  - **Evidence**: `scripts/tests/run-init-safety-tests.sh Tests 38c-38e and scripts/tests/run-terminal-picker-tests.sh`
- [ ] **AC-3**: `--update is courier-only and atomic: it refuses --force and .promptkit/.git, requires an existing kit, fetches under AbortSignal.timeout(30_000), verifies the pinned archive, stages the extraction, swaps it in, and restores the previous kit if the swap fails.`
  - **Result**: `Pending`
  - **Evidence**: `scripts/tests/run-courier-integrity-pin-fixtures.sh update-* fixtures, 24/24 passing`
- [ ] **AC-4**: `--solo-fast writes preset: solo-fast into the staged project profile and --host=codex maps to AGENTS.md in init.sh, init.ps1 and the courier wrapper; help option tokens stay identical between init.sh and Show-InitHelp, and a successful courier install prints the commit-versus-gitignore note.`
  - **Result**: `Pending`
  - **Evidence**: `scripts/tests/run-init-safety-tests.sh Tests 38a, 38b and 21e`
- [ ] **AC-5**: `Every required local gate exits 0, the record lists every touched path with no brace shorthand, CHANGELOG.md carries exactly one [Unreleased] entry for the branch, and no raw host path appears in code, docs or this record.`
  - **Result**: `Pending`
  - **Evidence**: `The gate commands in Verification Condition plus bash scripts/scan-staged-secrets.sh .`

## Execution Policy
- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, scope expansion, handoff, or compaction`
- **Stop Conditions**: `Missing approval, failed verification, blocker, or stop`
- **Host Timer Capability**: `Observed limit; live timing is not enforceable in this host`

## State and Ownership
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-27 07:20 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Review the local diff, then ask the operator for the push/PR checkpoint.`

### Transition History
| Previous State | New State | Timestamp | Actor | Reason | Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `2026-11-27 07:20 UTC` | `DeepSeek Harness agent (lead)` | `Created` | `N/A` |
| `planned` | `in_progress` | `2026-11-27 07:25 UTC` | `DeepSeek Harness agent (lead)` | `Implementation started` | `Issue #806` |
| `in_progress` | `awaiting_review` | `2026-11-27 08:05 UTC` | `DeepSeek Harness agent (lead)` | `Local changes and the three edited suites are green; full gates and commit pending` | `Gate transcripts in Verification Evidence` |

## Evidence and Completion
- **Changed Files**:
  - `init.sh` - Bash-version picker fallback, Turbo EOF cancel, codex host and AGENTS.md door, --solo-fast parsing/help/preset write, help host list from KNOWN_HOSTS
  - `init.ps1` - -SoloFast and --solo-fast, codex host and AGENTS.md door, preset write in Get-UpdatedProfileContent, help and detection parity
  - `scripts/terminal-picker.sh` - removed the dead b/B back branch so a bare b reports other
  - `package/bin/promptkit-os.js` - --update and --solo-fast passthrough policy, assertUpdatable, 30-second fetch timeout, staging/backup replace, exit-130 cleanup, install note
  - `scripts/tests/run-init-safety-tests.sh` - Tests 38a-38e for preset, codex, Bash guard, picker back removal and Turbo cancel
  - `scripts/tests/run-terminal-picker-tests.sh` - bare b must decode as other
  - `scripts/tests/run-courier-integrity-pin-fixtures.sh` - update/cancel fixtures and the assertion changes that describe them
  - `CHANGELOG.md` - one [Unreleased] entry for issue #806
  - `docs/tasks/TASK-2026-11-27-issue-806-installer-courier-reliability.md` - this Level 2 Lite record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `run-init-safety-tests.sh PASS; run-terminal-picker-tests.sh PASS; run-courier-integrity-pin-fixtures.sh PASS|24 executable courier policy fixtures; the remaining gates are recorded in the branch commit message after they run.`
- **CI Evidence**: `N/A - local branch, not pushed`
- **Review Evidence**: `N/A`
- **Commit Evidence**: `N/A before commit`
- **Pull Request Evidence**: `N/A`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 pending; AC-2 pending; AC-3 pending; AC-4 pending; AC-5 pending`
- **Changed-File Summary**: `The dual-entry-point installer gained the cancel, Bash 3, --update, --solo-fast and --host=codex behaviours; the picker lost a phantom back action; the courier wrapper gained the atomic replace and exit-130 cleanup; three Bash suites pin the behaviour; CHANGELOG.md and this record describe it.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Pending review, DeepSeek Harness agent (lead), 2026-11-27 08:05 UTC`

Transition rows use the canonical edges from the full template; the last row matches Execution State.