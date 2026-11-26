# Task Record: Strip PromptKit directive blocks transactionally and align the lifecycle docs
<a id="TASK-2026-11-27-issue-807-directive-strip-and-lifecycle-docs"></a>

## Identity
- **Record Type**: `Task Record`
- **Record Form**: `Lite`
- **Task ID**: `TASK-2026-11-27-issue-807-directive-strip-and-lifecycle-docs`
- **Ceremony Level**: `Level 2 (Controlled)`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/807`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: `promptkit-os repository on branch feat/807-strip-directives-lifecycle-docs; both installer entry points, the Bash init-safety suite, README.md, QUICKSTART.md, package/README.md, CHANGELOG.md and this record. Local implementation, verification and one commit on the dedicated branch only.`
- **Approval Boundary**: `Local implementation, verification and commits on a dedicated branch only. Push, PR creation, merge, force-push, squash/rebase/amend, tag, release and issue closure remain unauthorized until the operator approves a review checkpoint.`
- **Created**: `2026-11-27 08:10 UTC`

## Boundaries
- **Objective**: `Ship issue #807: both installers gain a transactional --strip-directives / -StripDirectives mode that removes only complete PromptKit directive blocks while preserving custom content, line endings and EOF state, deletes a host file only when nothing else remains, never touches user-owned PROMPTKIT.md, docs/STATE.md or .promptkit/, and prints the door-matched kit removal command instead; README.md, QUICKSTART.md and package/README.md describe courier --update and directive-block removal consistently.`
- **In Scope**:
  - `init.sh`
  - `init.ps1`
  - `scripts/tests/run-init-safety-tests.sh`
  - `README.md`
  - `QUICKSTART.md`
  - `package/README.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-27-issue-807-directive-strip-and-lifecycle-docs.md`
- **Explicit Non-Goals**:
  - `No push, PR creation, merge, tag or release in this task.`
  - `No automatic deletion of PROMPTKIT.md, docs/STATE.md, docs/tasks/ or .promptkit/: the strip mode prints the door-matched kit command and leaves those decisions to the operator.`
  - `No change to the installer transaction model, profile budgets or directive content outside the stripped blocks.`
  - `No --update work: the courier update path shipped with issue #806; this branch only documents it.`
  - `No Windows CI run here: init.ps1 is executed locally only when a working pwsh is available, and the Bash gate always pins its switch surface.`
- **Dependencies**: `Issue #806 at commit 7247cea supplies the courier --update behaviour this branch documents; issue #808 follows on its own branch.`
- **Risk**: `Medium` - `Strip mode rewrites assistant host files in place; a marker-parsing mistake could clip custom content or corrupt line endings. Mitigated by requiring exactly one ordered block per file, validating and staging every file before the first write, backing up each file and restoring all of them on failure, matching the existing marker regexes, and pinning CRLF, no-final-newline and whitespace-only deletion with byte comparisons.`
- **Verification Condition**: `bash scripts/tests/run-init-safety-tests.sh, bash scripts/tests/run-terminal-picker-tests.sh, bash scripts/tests/run-courier-integrity-pin-fixtures.sh, bash scripts/tests/run-behavioral-contract-tests.sh, bash scripts/tests/run-doctor-tests.sh, bash scripts/validate-references.sh . --strict, bash scripts/validate-execution-control.sh --root . --strict, bash scripts/measure-ceremony-overhead.sh, bash scripts/scan-staged-secrets.sh ., bash scripts/check-changelog-entry.sh and git diff --check all exit 0.`

## Acceptance Criteria
- [ ] **AC-1**: `init.sh --strip-directives removes only complete <!-- PROMPTKIT_START --> ... <!-- PROMPTKIT_END --> blocks from every known host file and any --target path, preserves custom content, CRLF endings and the original EOF state byte for byte, and deletes a host file only when nothing but whitespace remains; --dry-run reports the same plan and writes nothing.`
  - **Result**: `Pass`
  - **Evidence**: `scripts/tests/run-init-safety-tests.sh Tests 39a-39c: mixed-content block removal, whitespace-only host file deletion, byte-exact CRLF and no-final-newline preservation, and dry-run immutability all pass`
- [ ] **AC-2**: `A file with duplicate, reversed or otherwise incomplete markers exits 1 before any write, and the mode refuses PROMPTKIT.md, docs/STATE.md and .promptkit/ as user-owned.`
  - **Result**: `Pass`
  - **Evidence**: `scripts/tests/run-init-safety-tests.sh Tests 39a and 39d: PROMPTKIT.md, docs/STATE.md and .promptkit/ survive untouched, and duplicate or reversed markers exit 1 with the file unchanged`
- [ ] **AC-3**: `After stripping, the installer prints the door-matched kit removal command (rm -rf .promptkit for a courier install, git submodule deinit plus git rm for a submodule) and states that PROMPTKIT.md, docs/STATE.md and .promptkit/ were not modified; init.ps1 implements the same contract with -StripDirectives / -DryRun and matches the Bash twin byte for byte; help option tokens stay identical between init.sh and Show-InitHelp.`
  - **Result**: `Pass`
  - **Evidence**: `scripts/tests/run-init-safety-tests.sh Tests 39e, 39f and 21e: door-matched hints, byte-identical init.ps1 output under a working pwsh, and exact help option-token parity`
- [ ] **AC-4**: `README.md, QUICKSTART.md and package/README.md describe courier --update and directive-block removal consistently; the README removal fence keeps exactly the five commands Test 36p executes.`
  - **Result**: `Pass`
  - **Evidence**: `scripts/tests/run-init-safety-tests.sh Test 36p still extracts and executes exactly the five README removal commands`
- [ ] **AC-5**: `Every required local gate exits 0, the record lists every touched path with no brace shorthand, CHANGELOG.md carries exactly one [Unreleased] entry for the branch, and no raw host path appears in code, docs or this record.`
  - **Result**: `Pass`
  - **Evidence**: `All eleven gates exit 0; see Verification Evidence`

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
- **Start Time**: `2026-11-27 07:55 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Review the local diff, then ask the operator for the push/PR checkpoint.`

### Transition History
| Previous State | New State | Timestamp | Actor | Reason | Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `2026-11-27 07:55 UTC` | `DeepSeek Harness agent (lead)` | `Created` | `N/A` |
| `planned` | `in_progress` | `2026-11-27 07:58 UTC` | `DeepSeek Harness agent (lead)` | `Implementation started` | `Issue #807` |
| `in_progress` | `awaiting_review` | `2026-11-27 08:10 UTC` | `DeepSeek Harness agent (lead)` | `Strip mode, tests and docs are in place; full gates and commit pending` | `Gate transcripts in Verification Evidence` |

## Evidence and Completion
- **Changed Files**:
  - `init.sh` - --strip-directives and --dry-run parsing and help, marker validation, line-exact block removal, whitespace-only deletion, two-phase apply with restore, door-matched removal hint
  - `init.ps1` - -StripDirectives and -DryRun switches, matching help tokens, byte-preserving strip implementation, door-matched removal hint
  - `scripts/tests/run-init-safety-tests.sh` - Tests 39a-39f for stripping, bytes, dry-run, malformed markers, hints and twin parity; suite summary updated
  - `README.md` - courier --update note and strip-mode guidance in the removal section
  - `QUICKSTART.md` - courier --update in the updating fence and strip mode in removal
  - `package/README.md` - pass-through flag list, --update semantics and strip-based removal
  - `CHANGELOG.md` - one [Unreleased] entry for issue #807
  - `docs/tasks/TASK-2026-11-27-issue-807-directive-strip-and-lifecycle-docs.md` - this Level 2 Lite record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `run-init-safety-tests.sh PASS (including Tests 39a-39f and the unchanged 21d/21e/36p assertions); run-terminal-picker-tests.sh PASS; run-courier-integrity-pin-fixtures.sh PASS|24 executable courier policy fixtures; run-behavioral-contract-tests.sh 831 passed, 0 failed; run-doctor-tests.sh 52 passed, 0 failed, 0 skipped; validate-references.sh . --strict PASS; validate-execution-control.sh --root . --strict VALID|RECORDS=87|ROOT=.; measure-ceremony-overhead.sh exit 0 (L2 998 required tokens, unchanged); scan-staged-secrets.sh 0 findings; check-changelog-entry.sh CHANGELOG_GATE|PASS; git diff --check clean.`
- **CI Evidence**: `N/A - local branch, not pushed`
- **Review Evidence**: `N/A`
- **Commit Evidence**: `N/A before commit`
- **Pull Request Evidence**: `N/A`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 pass; AC-2 pass; AC-3 pass; AC-4 pass; AC-5 pass`
- **Changed-File Summary**: `Both installers gained a transactional directive-strip mode with byte-preserving edits and door-matched removal advice; the Bash suite pins its contract; the three lifecycle docs now describe courier updates and directive removal instead of hand edits; CHANGELOG.md and this record describe it.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Pending review, DeepSeek Harness agent (lead), 2026-11-27 08:10 UTC`

Transition rows use the canonical edges from the full template; the last row matches Execution State.
