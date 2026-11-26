# Task Record: Canonical strip-target protection, courier symlink refusal, and PowerShell strip-mode parity
<a id="TASK-2026-11-27-issue-814-strip-courier-symlink-hardening"></a>

## Identity
- **Record Type**: `Task Record`
- **Record Form**: `Lite`
- **Task ID**: `TASK-2026-11-27-issue-814-strip-courier-symlink-hardening`
- **Ceremony Level**: `Level 2 (Controlled)`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/814`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: `promptkit-os worktree on branch fix/814-strip-courier-symlink-hardening, based on origin/main 76a4f17`
- **Approval Boundary**: `No push, release, or upstream mutation without human confirmation; the local commit stops for independent review.`
- **Created**: `2026-11-26 21:05 UTC`

## Boundaries
- **Objective**: `--strip-directives refuses every canonical alias of PROMPTKIT.md, docs/STATE.md and .promptkit/ with zero mutations in both installers; the npm courier refuses a symbolic-link or non-directory .promptkit; the PowerShell safety suite covers the same strip-mode and canonical-alias cases as the Bash suite.`
- **In Scope**:
  - `init.sh` - canonical protected-path guard inside strip_directives.
  - `init.ps1` - canonical protected-path guard inside Invoke-StripDirectives.
  - `package/bin/promptkit-os.js` - lstat guard and canonical root containment for .promptkit.
  - `scripts/tests/run-init-safety-tests.sh` - canonical protected-path alias refusal test.
  - `scripts/tests/run-init-safety-tests.ps1` - strip-mode tests 39a-39f.
  - `scripts/tests/run-courier-integrity-pin-fixtures.sh` - three symlinked-.promptkit refusal fixtures.
  - `docs/ADOPTION-GUIDE.md` - courier update command and Level 2 Lite checkpoint wording.
  - `CHANGELOG.md` - one Unreleased Fixed entry.
  - `docs/tasks/TASK-2026-11-27-issue-814-strip-courier-symlink-hardening.md` - this task record.
- **Explicit Non-Goals**:
  - `No changes under workflows/, protocols/, templates/ or docs/BENCHMARKS.md (no provenance anchor churn).`
  - `No engine, protocol or adoption behavior changes beyond the two documentation corrections.`
  - `No release, tag, or push from this task.`
- **Dependencies**: `None` - the installers and the courier are self-contained; PowerShell 7 is available locally for the parity suite.
- **Risk**: `Medium` - the guards sit on install and strip paths that can delete user files; every refusal path is covered by a fixture that asserts exit 1 and byte-identical preservation.
- **Verification Condition**: `Every command in Verification Evidence exits 0 with the recorded result; the courier fixtures include the three symlink-refusal cases; no raw absolute host path appears in any staged addition.`

## Acceptance Criteria
- [ ] **AC-1**: `--strip-directives rejects ./PROMPTKIT.md, docs/./STATE.md, docs//STATE.md, docs\STATE.md on Windows, and an in-repo symlink to PROMPTKIT.md with exit 1 and zero mutations in both init.sh and init.ps1.`
  - **Result**: `Pass`
  - **Evidence**: `Bash Test 39g and PowerShell Test 39f pass; a direct init.ps1 probe returned status 1 with "protected PromptKit path" for all four aliases and byte-identical protected files.`
- [ ] **AC-2**: `The npm courier refuses a symbolic-link (including dangling) or non-directory .promptkit before default install, --force overlay, and --update, leaves the external target byte-identical, and verifies canonical root containment.`
  - **Result**: `Pass`
  - **Evidence**: `scripts/tests/run-courier-integrity-pin-fixtures.sh: 27 fixtures pass, including install-refuses-kit-symlink, force-refuses-kit-symlink and update-refuses-kit-symlink with exit=1, fetch=false and an unchanged external tree snapshot.`
- [ ] **AC-3**: `The PowerShell safety suite covers mixed-content strip, whitespace-only delete, CRLF and no-final-newline byte preservation, -DryRun immutability, malformed/reversed marker refusal, door-matched removal hints, and canonical protected-path aliases.`
  - **Result**: `Pass`
  - **Evidence**: `scripts/tests/run-init-safety-tests.ps1 Tests 39a-39f pass; final summary line names the strip-mode coverage.`
- [ ] **AC-4**: `docs/ADOPTION-GUIDE.md documents npx promptkit-os@latest --update with the git-submodule refusal and describes Level 2 Lite as the 17-label default with the full 20-label checkpoint as opt-in.`
  - **Result**: `Pass`
  - **Evidence**: `docs/ADOPTION-GUIDE.md lines 30 and 40 read the updated wording.`
- [ ] **AC-5**: `Every required gate exits 0, CHANGELOG.md carries exactly one [Unreleased] Fixed entry, this record lists every touched file explicitly, and no staged addition contains a raw absolute host path.`
  - **Result**: `Pass`
  - **Evidence**: `Gate results in Verification Evidence; git diff --check clean; scan-staged-secrets reports no findings.`

## Execution Policy
- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A` - a single reviewed implementation batch issued by the task brief.
- **Soft Checkpoint**: `N/A - the batch completed well inside one session with gates re-run after each defect fix.`
- **Hard Checkpoint**: `N/A - no scope expansion or external blocker occurred.`
- **Event-Driven Checkpoints**: `Milestone, scope expansion, handoff, or compaction`
- **Stop Conditions**: `Missing approval, failed verification, blocker, or stop; the local commit stops before push for independent review.`
- **Host Timer Capability**: `DSH session; no automatic timer, live checkpoints are not enforceable.`

## State and Ownership
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-26 21:10 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Independent reviewer audits the local commit diff on fix/814-strip-courier-symlink-hardening before any push.`

### Transition History
| Previous State | New State | Timestamp | Actor | Reason | Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `2026-11-26 21:05 UTC` | `DeepSeek Harness agent (lead)` | `Task brief received from issue #814.` | `N/A` |
| `planned` | `in_progress` | `2026-11-26 21:10 UTC` | `DeepSeek Harness agent (lead)` | `Branch created from origin/main 76a4f17 and implementation started.` | `git switch -c fix/814-strip-courier-symlink-hardening origin/main` |
| `in_progress` | `awaiting_review` | `2026-11-26 21:55 UTC` | `DeepSeek Harness agent (lead)` | `Implementation, tests and docs are in place; gates green and local commit pending.` | `Verification Evidence` |

## Evidence and Completion
- **Changed Files**:
  - `init.sh` - canonical protected-path guard in strip_directives (PROMPTKIT.md, docs/STATE.md, .promptkit/ containment).
  - `init.ps1` - canonical protected-path guard in Invoke-StripDirectives with platform-correct comparison.
  - `package/bin/promptkit-os.js` - kitTargetKind lstat guard, symlink and non-directory refusal, canonical root containment, re-check inside extract.
  - `scripts/tests/run-init-safety-tests.sh` - Test 39g canonical alias refusal plus summary coverage text.
  - `scripts/tests/run-init-safety-tests.ps1` - Tests 39a-39f with Invoke-StripAssert helper and summary coverage text.
  - `scripts/tests/run-courier-integrity-pin-fixtures.sh` - symlink fixture support and three refusal cases.
  - `docs/ADOPTION-GUIDE.md` - courier --update wording and Level 2 Lite checkpoint wording.
  - `CHANGELOG.md` - one Unreleased Fixed entry.
  - `docs/tasks/TASK-2026-11-27-issue-814-strip-courier-symlink-hardening.md` - this task record.
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `bash scripts/tests/run-init-safety-tests.sh exit 0; /usr/bin/pwsh -NoProfile -File scripts/tests/run-init-safety-tests.ps1 exit 0 (strip-mode and canonical-alias cases included); bash scripts/tests/run-courier-integrity-pin-fixtures.sh 27/27 fixtures pass; bash scripts/tests/run-behavioral-contract-tests.sh Passed 831 | Failed 0; bash scripts/validate-references.sh . --strict exit 0; bash scripts/validate-execution-control.sh --root . --strict VALID|RECORDS=89|ROOT=. (exit 0); bash scripts/scan-staged-secrets.sh . reports no findings; bash scripts/check-changelog-entry.sh exit 0 before commit (empty range by design, re-run after the commit validates the entry); git diff --check clean.`
- **CI Evidence**: `N/A - local worktree only; no CI run for the unpushed branch.`
- **Review Evidence**: `N/A - awaiting independent reviewer audit before push.`
- **Commit Evidence**: `N/A before commit; the local commit on fix/814-strip-courier-symlink-hardening is recorded after this record.`
- **Pull Request Evidence**: `N/A - push and pull request deliberately withheld for review.`
- **Release Evidence**: `N/A - no release action in this task.`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 pass; AC-2 pass; AC-3 pass; AC-4 pass; AC-5 pass.`
- **Changed-File Summary**: `9 files: two installer guards, one courier guard, three test suites, one adoption-guide correction, one changelog entry, one task record.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Awaiting independent review, DeepSeek Harness agent (lead), 2026-11-26 21:56 UTC`

Transition rows use the canonical edges from the full template; the last row matches Execution State.
