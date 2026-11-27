# Task Record: Hard-link-safe strip mode and engine identity preservation across non-git reruns
<a id="TASK-2026-11-28-issue-818-819-strip-hard-links-and-engine-identity"></a>

## Identity
- **Record Type**: `Task Record`
- **Record Form**: `Lite`
- **Task ID**: `TASK-2026-11-28-issue-818-819-strip-hard-links-and-engine-identity`
- **Ceremony Level**: `Level 2 (Controlled)`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/818` and `https://github.com/lowqualityloey/promptkit-os/issues/819`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: `promptkit-os git worktree on branch fix/818-819-v2.6.2-hardening, based on origin/main 0d0274a (v2.6.1)`
- **Approval Boundary**: `No push, pull request, tag, npm publish or release action; the single local commit stops for independent review.`
- **Created**: `2026-11-27 20:05 UTC`

## Boundaries
- **Objective**: `--strip-directives refuses a hard link to PROMPTKIT.md, docs/STATE.md or any file inside .promptkit/ with exit 1 and zero mutations in both installers, strips a multiply-linked host file exactly once, and a rerun without git metadata or --engine-version= no longer degrades a valid engine stamp to "unknown".`
- **In Scope**:
  - `init.sh` - file-identity helper, protected-identity and identity-dedupe guards in strip_directives, and the post-arg engine identity resolver with the docs/STATE.md and host-directive fallbacks.
  - `init.ps1` - Get-FileIdentity (Win32 handle information on Windows, stat device:inode on Unix), protected-identity and identity-dedupe guards in Invoke-StripDirectives, and Get-StateStampEngineIdentity / Get-DirectiveStampEngineIdentity fallbacks.
  - `package/bin/promptkit-os.js` - the post-extraction kitTargetKind re-check, moved inside extract() after extractToStaging so the check-then-use window ends immediately before the rename.
  - `scripts/tests/run-init-safety-tests.sh` - Tests 39h (hard-link refusals), 39i (identity dedupe) and 40a (engine identity preservation), plus summary coverage text.
  - `scripts/tests/run-init-safety-tests.ps1` - PowerShell twins: Tests 39g (hard-link refusals), 39h (identity dedupe) and 40a (engine identity preservation), plus summary coverage text.
  - `CHANGELOG.md` - one Unreleased Fixed entry covering both issues.
  - `docs/tasks/TASK-2026-11-28-issue-818-819-strip-hard-links-and-engine-identity.md` - this task record.
- **Explicit Non-Goals**:
  - `No changes under workflows/, protocols/, templates/ or docs/BENCHMARKS.md (no provenance anchor churn).`
  - `No OS-specific handle locking, no new dependency, and no change to the release archive verification path.`
  - `No release, tag, push, pull request or npm publish from this task.`
  - `No change for a project that carries no usable stamp: it still installs stamped "unknown".`
- **Dependencies**: `None` - both installers and the courier are self-contained; PowerShell 7.7.0 and git are available locally for the parity suites.
- **Risk**: `Medium` - the guards sit on a path that rewrites user-owned files; every refusal asserts exit 1 and byte-identical protected files, and the identity dedupe only merges names that share one inode.
- **Verification Condition**: `Every command in Verification Evidence exits 0 with the recorded result, both safety suites include the new cases, and no staged addition contains a raw absolute host path.`

## Acceptance Criteria
- [ ] **AC-1**: `--strip-directives refuses a hard link to PROMPTKIT.md, to docs/STATE.md and to a file inside .promptkit/ with exit 1, a diagnostic naming the candidate, and zero mutations, in both init.sh and init.ps1.`
  - **Result**: `Pass`
  - **Evidence**: `Bash Test 39h (three fixtures: AGENTS.md hard-linked to PROMPTKIT.md, .cursorrules to docs/STATE.md, CLAUDE.md to .promptkit/rules.md) and PowerShell Test 39g (same matrix, SHA-256 before and after) pass. init.sh behaviour was probed directly before the suites existed: exit 1 with "hard link to a protected PromptKit path" / "hard link inside the protected .promptkit/ directory" and untouched protected files.`
- [ ] **AC-2**: `Two host names hard-linked to one non-protected file are stripped and backed up once, never twice under two names, in both installers.`
  - **Result**: `Pass`
  - **Evidence**: `Bash Test 39i and PowerShell Test 39h: exactly one "  stripped .cursorrules" line, "Removed PromptKit directives from 1 file(s).", both names byte-identical to the expected result.`
- [ ] **AC-3**: `The courier re-checks the target kind after extractToStaging rather than before it, exits before any mutation, and leaves every existing courier fixture green.`
  - **Result**: `Pass`
  - **Evidence**: `package/bin/promptkit-os.js passes node --check; scripts/tests/run-courier-integrity-pin-fixtures.sh passes 27 of 27 fixtures including install-refuses-kit-symlink, force-refuses-kit-symlink and update-refuses-kit-symlink.`
- [ ] **AC-4**: `On a non-git courier install a rerun with no --engine-version= preserves the existing v2.6.1 stamp in docs/STATE.md and in the managed host directive (never degrading to "unknown"), while an explicit --engine-version=v2.6.2 still overrides it cleanly and a fresh project with no stamp still installs as "unknown"; strip mode never reads a stamp.`
  - **Result**: `Pass`
  - **Evidence**: `Bash Test 40a and PowerShell Test 40a run the same four-install sequence against a copied non-git kit: with --engine-version=v2.6.1, without the flag, with --engine-version=v2.6.2, and a fresh host without the flag. The resolver call in init.sh sits below the --strip-directives exit.`
- [ ] **AC-5**: `Every required gate exits 0, CHANGELOG.md carries exactly one Unreleased Fixed entry covering both issues, this record lists every touched file, and no staged addition contains a raw absolute host path.`
  - **Result**: `Pass`
  - **Evidence**: `Verification Evidence below; git diff --check clean; scan-staged-secrets reports no findings.`

## Execution Policy
- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A` - a single reviewed implementation batch issued by the task brief.
- **Soft Checkpoint**: `N/A - the batch completed inside one session with gates re-run after each defect fix.`
- **Hard Checkpoint**: `N/A - no scope expansion or external blocker occurred.`
- **Event-Driven Checkpoints**: `Milestone, scope expansion, handoff, or compaction`
- **Stop Conditions**: `Missing approval, failed verification, blocker, or stop; the local commit stops before push for independent review.`
- **Host Timer Capability**: `DSH session; no automatic timer, live checkpoints are not enforceable.`

## State and Ownership
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-27 20:10 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Independent reviewer audits the local commit on fix/818-819-v2.6.2-hardening, and Windows CI runs the PowerShell leg, before any push.`

### Transition History
| Previous State | New State | Timestamp | Actor | Reason | Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `2026-11-27 20:05 UTC` | `DeepSeek Harness agent (lead)` | `Task brief received from issues #818 and #819.` | `N/A` |
| `planned` | `in_progress` | `2026-11-27 20:10 UTC` | `DeepSeek Harness agent (lead)` | `Branch created from origin/main 0d0274a and implementation started.` | `git switch -c fix/818-819-v2.6.2-hardening origin/main` |
| `in_progress` | `awaiting_review` | `2026-11-27 22:15 UTC` | `DeepSeek Harness agent (lead)` | `Both installers, the courier, both safety suites, the changelog entry and this record are in place; gates green and the local commit is prepared.` | `Verification Evidence` |

## Evidence and Completion
- **Changed Files**:
  - `init.sh` - get_file_identity, protected file and kit identity refusals, identity dedupe, ENGINE_VERSION_EXPLICIT and resolve_engine_identity_after_args with the state and directive stamp fallbacks.
  - `init.ps1` - Get-FileIdentity Win32/Unix probe, protected-identity and kit-identity refusals, identity dedupe, $hasGitDir, and the state and directive stamp fallbacks.
  - `package/bin/promptkit-os.js` - kitTargetKind re-check moved after extractToStaging, immediately before the replace/overlay/fresh mutation.
  - `scripts/tests/run-init-safety-tests.sh` - Tests 39h, 39i, 40a and extended summary coverage text.
  - `scripts/tests/run-init-safety-tests.ps1` - Tests 39g, 39h, 40a and extended summary coverage text.
  - `CHANGELOG.md` - one Unreleased Fixed entry covering both issues.
  - `docs/tasks/TASK-2026-11-28-issue-818-819-strip-hard-links-and-engine-identity.md` - this task record.
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `bash scripts/tests/run-init-safety-tests.sh exit 0 with the extended summary line; pwsh -NoProfile -File scripts/tests/run-init-safety-tests.ps1 exit 0 on Linux PowerShell 7.7.0; both PowerShell files parse cleanly with [System.Management.Automation.Language.Parser]::ParseFile; bash scripts/tests/run-courier-integrity-pin-fixtures.sh exit 0, 27 of 27 fixtures pass; bash scripts/tests/run-behavioral-contract-tests.sh exit 0, Passed 831 | Failed 0; bash scripts/validate-references.sh . --strict exit 0; bash scripts/validate-execution-control.sh --root . --strict exit 0; bash scripts/scan-staged-secrets.sh . reports no findings; bash scripts/check-changelog-entry.sh exit 0 before the commit (empty range by design) and again after the commit to validate the entry; git diff --check clean.`
- **CI Evidence**: `N/A - local worktree only; the Windows PowerShell leg is left to Windows CI after a pull request.`
- **Review Evidence**: `N/A - awaiting independent reviewer audit before push.`
- **Commit Evidence**: `N/A before commit; the single local commit on fix/818-819-v2.6.2-hardening is recorded after this record.`
- **Pull Request Evidence**: `N/A - push and pull request deliberately withheld for review.`
- **Release Evidence**: `N/A - no release action in this task.`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 pass; AC-2 pass; AC-3 pass; AC-4 pass; AC-5 pass.`
- **Changed-File Summary**: `7 files: two installer hard-link and engine-identity changes, one courier check-ordering change, two safety suites, one changelog entry, one task record.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Awaiting independent review, DeepSeek Harness agent (lead), 2026-11-27 22:15 UTC`

Transition rows use the canonical edges from the full template; the last row matches Execution State.
