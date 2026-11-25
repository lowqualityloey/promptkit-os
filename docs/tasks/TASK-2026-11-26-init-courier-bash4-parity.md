# Task Record: init.ps1 CLI parity, atomic courier extraction, and Bash 4+ guards

<a id="TASK-2026-11-26-init-courier-bash4-parity"></a>

## 1. Identity and Authority

- **Record Type**: Task Record
- **Task ID**: TASK-2026-11-26-init-courier-bash4-parity
- **Ceremony Level**: Level 2 (Controlled)
- **PromptKit Adaptation Profile**: none
- **Work Type**: Defect fix (installer safety, twin parity, release-integrity)
- **Specification**: GitHub issue #785 "fix(init): enforce strict CLI flag/arg parity in init.ps1, atomic courier extraction, and Bash 4+ version guard" (P1, Type Twin Parity and Installer Safety Defect, Execution Wave A).
- **External Reference**: https://github.com/lowqualityloey/promptkit-os/issues/785
- **Owner / Actor**: repository owner (approval authority); delegated implementation agent impl-785 (execution) under the lead agent.
- **Execution Scope**: isolated worktree `/home/heyloey/personal/pk-wt-785`, branch `fix/785-init-parity`, based on `d7ede1f964e670deca93a559eff294846b030b28`.
- **Approval Boundary**: local implementation, tests, documentation, and one commit only. No push, pull request, merge, release, workflow edit, or other remote action without explicit owner approval.
- **Created**: 2026-11-26

> Sources of authority: GitHub issue #785 (acceptance criteria AC-1 through AC-4); `CONTRIBUTING.md` (Level 2 Controlled Work and twin-parity rules); `docs/tasks/TASK-2026-09-08-execution-control-properties.md` (Task Record contract). The issue text governs scope; this record records execution, not new authorization.

## 2. Objective and Boundaries

- **Objective**: Close the installer-safety and twin-parity gaps named by issue #785: make `init.ps1` fail closed on unknown flags, unknown tracking values, and multiple positional project roots while exposing help byte-identical to `init.sh`; make the npm courier extract releases atomically so a failed download, corrupt archive, or missing `tar` leaves no `.promptkit/` and no staging residue; restore integrity pins for every published 2.x tag; and refuse to run the Bash 4+ scripts on older Bash before the first Bash-4-only construct trips on macOS `/bin/bash` 3.2.
- **In Scope**:
  - `init.ps1`: fail-closed CLI parser, one shared `Show-InitHelp` function used by both `-Help` and `--help`, `[Alias("h")]`, and filtering of the phantom null `$args` element.
  - `package/bin/promptkit-os.js`: staging-directory extraction with `try/finally` cleanup and publish-by-rename, plus seven recovered historical integrity pins.
  - `CHANGELOG.md`: one `[Unreleased]` / `### Fixed` bullet describing the change.
  - `scripts/tests/run-courier-integrity-pin-fixtures.sh`: corrupt-archive, missing-tar, force-with-corrupt-archive, and clean-retry fixtures.
  - `scripts/tests/run-init-safety-tests.sh`: parser and help-parity tests 21a-21e.
  - `scripts/tests/run-init-safety-tests.ps1`: parser and help-parity tests 15f-15i.
  - Bash 4+ guards in `benchmarks/run-ab-benchmark.sh`, `scripts/aggregate-benchmark-runs.sh`, `scripts/extract-commandcode-telemetry.sh`, `scripts/measure-ceremony-overhead.sh`, `scripts/measure-cpac.sh`, `scripts/tests/run-benchmark-driver-tests.sh`, `scripts/tests/run-init-safety-tests.sh`, `scripts/tests/run-release-record-properties.sh`, `scripts/validate-ci-triage.sh`, `scripts/validate-execution-control.sh`, and `scripts/validate-release-records.sh`.
  - This task record at `docs/tasks/TASK-2026-11-26-init-courier-bash4-parity.md`.
- **Explicit Non-Goals**:
  - Do not change `init.sh` parser behavior: its parser already rejects unknown flags, unknown tracking values, and multiple project roots at `init.sh:348-449`.
  - Do not edit `.github/workflows/ci.yml`, `.gitattributes`, `docs/BENCHMARKS.md`, `workflows/`, `templates/`, `README.md`, or `docs/HOST-CONFORMANCE.md`.
  - Do not push the branch, open a pull request, merge, tag, or publish anything.
  - Do not redesign the courier `--force` contract; documented overlay semantics are preserved.
  - Do not add a Bash 3.2 compatibility shim; the scripts require Bash 4+ and now say so.
- **Dependencies**:
  - Local toolchain: node 26.13.1, npm 12.2.3, python3 3.12.3, git, curl. The host `pwsh` is a broken WSL shim, so PowerShell 7.7.0 linux-x64 was downloaded to `/tmp/pwsh7` for verification.
  - Network access for pin recovery and archive verification (npm registry and GitHub tag archives).
  - No new third-party dependency, workflow change, or release artifact is required.
- **Risk**: Medium. The courier is the shipping entry point for every release, so an extraction bug can leave partial installs; the change is therefore covered by failure-injection fixtures rather than only the happy path. `init.ps1` is the Windows twin and cannot run on Linux CI, so its verification depends on the PowerShell suite; a Windows PowerShell 5.1 run remains unverified locally. Historical pins are only useful if they correspond to the actual published archives, so each recovered digest was checked against both the npm courier tarball and a fresh GitHub tag archive verified with `scripts/verify-release-archive.py`.
- **Verification Condition**: `bash scripts/tests/run-courier-integrity-pin-fixtures.sh` exits 0 with 18 fixtures; `bash scripts/tests/run-init-safety-tests.sh` exits 0; `pwsh -NoProfile -File scripts/tests/run-init-safety-tests.ps1` exits 0 under PowerShell 7.7.0 on Linux; `bash -n` and `node --check` pass on every changed source file; `scripts/validate-execution-control.sh` reports VALID; every recovered pin matches its downloaded archive.

## 3. Acceptance Criteria

## 3. Acceptance Criteria

- [x] **AC-1 (init.ps1 Flag and Help Parity)**: `init.sh` and `init.ps1` exit 1 without creating or mutating files for `--unknown-flag`, `--tracking=invalid`, and two positional directories; `--help` and `-Help` emit identical full option documentation.
  - **Result**: Pass
  - **Evidence**: `Show-InitHelp` (`init.ps1:328-350`) is called from the `-Help` branch (`init.ps1:352-355`) and from the `--help` switch arm, so both outputs are byte-identical; `[Alias("h")]` (`init.ps1:29-30`) makes `-h` resolve to the same switch. The four exact tracking arms were replaced by one `--tracking=*` arm that validates against `local|github|jira|linear` and exits 1, and the parser default arm now rejects any `-*` token and any second positional root (`init.ps1:405-424`). The `$AllArgs` construction filters the null element that `@($args)` yields under `[CmdletBinding]`, which previously produced a misleading second-root diagnostic for the two flag cases. Tests 21a-21e (`scripts/tests/run-init-safety-tests.sh`) and 15f-15i (`scripts/tests/run-init-safety-tests.ps1`) assert exit code 1, the exact diagnostics, empty temp roots, byte-identical help, and option-token parity between the two engines. Bash suite: exit 0 (log `/tmp/pk-init-suite.log`). PowerShell suite: exit 0 under PowerShell 7.7.0 (log `/tmp/pk-init-suite-ps1.log`, `EXIT=0`, zero matches for `failed`).
- [x] **AC-2 (Atomic Courier Extraction)**: a simulated `tar` failure (ENOENT or corrupt archive) makes `promptkit-os.js` exit 1 and leaves neither `.promptkit/` nor any staging temp directory, allowing an immediate clean retry.
  - **Result**: Pass
  - **Evidence**: `extract(tarball, root, dest)` now unpacks into `fs.mkdtempSync(path.join(root, ".promptkit-staging-"))` and only renames onto `.promptkit` after `tar` exits 0; the `catch` block removes the staging directory and rethrows, so `main().catch(die)` still exits 1 (`package/bin/promptkit-os.js:144-186`). Four new fixtures in `scripts/tests/run-courier-integrity-pin-fixtures.sh` cover corrupt archive, absent `tar` (empty `PATH`), `--force` over an existing install, and an immediate retry with a good archive. The retry case reuses the same project root and succeeds with a clean `.promptkit/`; every fixture also asserts that no root entry starts with `.promptkit-staging-` and that untouched projects contain only `keep.txt`. Result: `PASS|18 executable courier policy fixtures (stub archive, no real installer)`.
- [x] **AC-3 (Historical Pin Auditability)**: `TARBALL_SHA256_BY_VERSION` resolves verified pins for all published v2.0.0-v2.5.0 tags, and pin recovery provenance is noted in the change record.
  - **Result**: Pass
  - **Evidence**: nine entries now exist (1.10.1, 1.11.0, 2.0.0, 2.0.1, 2.1.0, 2.2.0, 2.3.0, 2.4.0, 2.5.0) with exactly one `// @pin-insert` marker retained. The 2.x digests were recovered from the published `promptkit-os@<version>` npm courier tarballs and cross-checked against `docs/releases/2026-11-12-v2.2.0-approved-release.md:52`, `docs/releases/2026-11-15-v2.3.0-approved-release.md:53`, `docs/releases/2026-11-21-v2.4.0-approved-release.md:59`, `docs/releases/2026-11-24-v2.5.0-approved-release.md:53`, and `docs/releases/2026-10-10-v2.0.0-qa-review.md:65`; 2.0.0, 2.0.1, and 2.1.0 had no pin prose in git and rely on the npm tarball plus the tag-archive check below. Each current GitHub tag archive was downloaded to `/tmp/pk-archives/v<v>.tar.gz`, its sha256 matched the recorded digest, and `python3 scripts/verify-release-archive.py --archive /tmp/pk-archives/v<v>.tar.gz --commit <tag commit> --repository $PWD` reported `Verified downloaded archive contents match commit <sha>` for all seven (commits: 2.0.0 `e2ca0ebe036236d85c3275d26d0b5cacaf665270`, 2.0.1 `3c6a31bd60483375f19616df0943fa777258e432`, 2.1.0 `a951a8378f4f4ecd2d28e1fea45165239df83ecb`, 2.2.0 `06a315472a3e63ca0d2feb66ef50e83994a843eb`, 2.3.0 `52adbe16c0ff2aea0d538e10c3225c2f3e40e315`, 2.4.0 `13006a6e3fe955d220ee7a5d5518d4bd6b7e1652`, 2.5.0 `a8c599435550c0887bd4aadb76e636c222ccac9f`). `node -e "require('./package/bin/promptkit-os.js')"` reports 9 pins and `grep -c '@pin-insert'` is 1.
- [x] **AC-4 (Bash 4+ Guard)**: all 11 Bash 4+ scripts guard `BASH_VERSINFO[0] -lt 4` before any `declare -A` or `mapfile` and emit an actionable "Bash 4.0+ required" message.
  - **Result**: Pass
  - **Evidence**: an identical eight-line guard is placed immediately after the top `set`/`export` lines in all 11 scripts, printing `Bash 4.0+ required (found $BASH_VERSION).` plus the macOS `brew install bash` remedy to stderr and exiting 1. Guard lines: `scripts/validate-execution-control.sh:9`, `scripts/validate-release-records.sh:9`, `scripts/validate-ci-triage.sh:10`, `scripts/measure-ceremony-overhead.sh:96`, `scripts/measure-cpac.sh:15`, `scripts/aggregate-benchmark-runs.sh:20`, `scripts/extract-commandcode-telemetry.sh:30`, `scripts/tests/run-init-safety-tests.sh:8`, `scripts/tests/run-release-record-properties.sh:9`, `scripts/tests/run-benchmark-driver-tests.sh:19`, `benchmarks/run-ab-benchmark.sh:64`. A repo-wide grep for `declare -A` or `mapfile` returns exactly these 11 files, and in each file the guard precedes the first construct (audited). The guard comment deliberately avoids those literal tokens so a text audit does not match the comment. `bash -n` passes for all 11, and no Bash 3.2 binary is available locally, so the negative path itself is unexecuted (see Completion Exception).

## 4. Execution Policy

- **Mode**: bounded batch execution (single delegated agent, one worktree, one commit).
- **Batch Authorization**: issue #785 acceptance criteria and the delegation brief authorize implementation, tests, documentation, and one local commit; no further scope is inferred.
- **Soft Checkpoint**: after code edits and after each test suite, confirm scope still matches the issue before proceeding.
- **Hard Checkpoint**: before `git commit`, review the full diff and confirm no out-of-scope or generated files are staged.
- **Event-Driven Checkpoints**: on any failing suite, stop editing and diagnose the failure before continuing.
- **Stop Conditions**: unmet AC after a fix attempt; a required edit outside the approved scope; a test failure requiring a design change; any request for a remote action.
- **Host Timer Capability**: unavailable in this session. Live host timing, scheduling, forced termination, and progress-time guarantees are not mechanically enforceable; work proceeds event-driven only, and long suites (the PowerShell twin runs about 75 minutes) are treated as background observations rather than timer-bound steps.

## 5. State and Active Ownership

- **Execution State**: awaiting_review
- **Mapped `pk:tasks` Status**: In Review
- **Active Task Pointer**: None
- **Start Time**: 2026-11-26T06:30:00Z
- **Current Actor**: impl-785 (implementation and local verification); repository owner (pending review and remote approval)
- **Next Action**: owner reviews the diff and the evidence below; if accepted, authorize push and pull-request creation.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
| --- | --- | --- | --- | --- | --- |
| N/A | planned | 2026-11-26T06:30:00Z | impl-785 | Delegated issue #785 implementation | delegation brief; issue #785 |
| planned | ready | 2026-11-26T07:10:00Z | impl-785 | Reconnaissance complete: parser sites, courier flow, 11 Bash-4 scripts, seven pins recovered | `/tmp/pk-archives` verification; `init.ps1`/`init.sh` audit |
| ready | in_progress | 2026-11-26T07:20:00Z | impl-785 | Edits started in the isolated worktree | worktree `fix/785-init-parity` |
| in_progress | awaiting_review | 2026-11-26T21:30:00Z | impl-785 | Implementation, regression tests, record, and changelog complete; local suites green | test logs cited in section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `init.ps1` - fail-closed parser, shared `Show-InitHelp`, `[Alias("h")]`, null-args filter.
  - `package/bin/promptkit-os.js` - atomic staging extraction and seven recovered 2.x pins.
  - `CHANGELOG.md` - `[Unreleased]` / `### Fixed` bullet.
  - `scripts/tests/run-courier-integrity-pin-fixtures.sh` - four failure-injection fixtures (18 total).
  - `scripts/tests/run-init-safety-tests.sh` - tests 21a-21e and updated summary.
  - `scripts/tests/run-init-safety-tests.ps1` - tests 15f-15i and updated summary.
  - `benchmarks/run-ab-benchmark.sh`, `scripts/aggregate-benchmark-runs.sh`, `scripts/extract-commandcode-telemetry.sh`, `scripts/measure-ceremony-overhead.sh`, `scripts/measure-cpac.sh`, `scripts/tests/run-benchmark-driver-tests.sh`, `scripts/tests/run-init-safety-tests.sh`, `scripts/tests/run-release-record-properties.sh`, `scripts/validate-ci-triage.sh`, `scripts/validate-execution-control.sh`, `scripts/validate-release-records.sh` - Bash 4+ guards.
  - `docs/tasks/TASK-2026-11-26-init-courier-bash4-parity.md` - this record.
- **Branch / Revision**: `fix/785-init-parity` from `d7ede1f964e670deca93a559eff294846b030b28`; the implementation commit is created immediately after this record is staged (HEAD before commit: `d7ede1f`).
- **Scope Change Records**: none. No change crossed the recorded In Scope boundary.
- **Checkpoint Records**: none created; the batch ran without scheduled checkpoints, and soft/hard checkpoints were applied inline.
- **Handoff Records**: none.
- **Verification Evidence**: commands and observed results:
  - `bash scripts/tests/run-courier-integrity-pin-fixtures.sh` -> exit 0, final line `PASS|18 executable courier policy fixtures (stub archive, no real installer)`.
  - `bash scripts/tests/run-init-safety-tests.sh` -> exit 0, final summary begins `init.sh non-destructive update, fail-closed CLI parser (unknown flag, unknown tracking, two project roots; nothing created), byte-identical --help/-h with the full option list and option-token parity against init.ps1's Show-InitHelp...` (log `/tmp/pk-init-suite.log`).
  - `PATH=/tmp/pwsh7:$PATH /tmp/pwsh7/pwsh -NoProfile -File scripts/tests/run-init-safety-tests.ps1` -> exit 0 under PowerShell 7.7.0, `EXIT=0`, zero matches for `failed` (log `/tmp/pk-init-suite-ps1.log`).
  - `bash -n` on `init.sh`, the 11 guarded scripts, and `scripts/tests/run-courier-integrity-pin-fixtures.sh` -> all OK; `node --check package/bin/promptkit-os.js` -> OK.
  - Repo-wide text audit: exactly 11 files use `declare -A` or `mapfile`, exactly the same 11 contain `Bash 4.0+ required`.
  - Pin audit: seven archives re-hashed to the recorded digests; seven `verify-release-archive.py` runs returned `Verified downloaded archive contents match commit <sha>`.
  - `scripts/validate-execution-control.sh` -> VALID (records scanned, no diagnostics).
- **CI Evidence**: none. The branch has not been pushed, so no GitHub Actions run exists; local Linux verification covers the ubuntu leg only. The expected CI commands after authorization are the three issue commands plus the workflow's existing matrix.
- **Review Evidence**: local self-review of the full diff only; no human or peer review yet. Scope, twin parity, and documentation were checked against the issue and CONTRIBUTING.md.
- **Commit Evidence**: a single conventional commit titled `fix(init): enforce CLI parity, atomic courier extraction, and Bash 4+ guards`, with the Context/Mechanism/Impact body, Maintenance classification, SemVer candidate impact `none`, and this record as the supporting planning record. The commit is created after this record is written; it is not pushed.
- **Pull Request Evidence**: none; pull request creation is outside the approval boundary and waits for owner approval.
- **Release Evidence**: none; this is not a release.
- **Blocker and Resume Condition**: no blocker. Resume condition: the repository owner reviews this record and the local commit, then explicitly authorizes `git push` and pull-request creation.

### Completion Decision

- **Completion State**: implementation and local verification complete; remote delivery not started (awaiting owner review).
- **Acceptance Results**: AC-1, AC-2, AC-3, and AC-4 all pass under local verification. Residual unverified surface is listed in Completion Exception.
- **Changed-File Summary**: 16 files: `init.ps1`, `package/bin/promptkit-os.js`, `CHANGELOG.md`, three test files, ten Bash scripts carrying the version guard, and this task record.
- **Completion Exception**: Windows PowerShell 5.1 and the Windows CI leg were not executed (only PowerShell 7.7.0 on Linux); no Bash 3.2 binary was available, so the guard's refusal path was audited and syntax-checked but not executed; `package/test/smoke.sh` was not run because it installs a published release tarball and requires network access to a real release.
- **Completion Decision and Timestamp**: Ready for owner review; no push, pull request, merge, or release was performed. 2026-11-26T21:30:00Z.
