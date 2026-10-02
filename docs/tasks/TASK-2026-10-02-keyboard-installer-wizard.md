# Task Record: Keyboard-driven installer wizard

<a id="TASK-2026-10-02-keyboard-installer-wizard"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-02-keyboard-installer-wizard`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Replace error-prone numbered interactive install choices with keyboard-driven single-select and checkbox pickers, a final review step, and a responsive terminal banner.`
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Codex (executor)`
- **Execution Scope**: `promptkit-os repository; Bash and PowerShell installers, picker helpers/tests, CI, install documentation, and changelog`
- **Approval Boundary**: `User authorized making the change PR-ready, including branch push and PR creation. Merge remains human-only.`
- **Created**: `2026-10-02`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Make interactive install choices easy to select and correct in a terminal: use arrow keys and Enter for single choices, Space and Enter for host/projection checkboxes, and a final review screen that allows edits, install, or cancellation before project files are changed.`
- **In Scope**:
  - `init.sh` and `init.ps1` interactive flow and non-interactive compatibility
  - `scripts/terminal-picker.sh` and `scripts/terminal-picker.ps1`
  - `scripts/tests/run-terminal-picker-tests.sh` and `scripts/tests/run-terminal-picker-tests.ps1`
  - `scripts/tests/run-profile-matrix.sh` and `scripts/tests/run-profile-matrix.ps1` regression coverage for rerun preservation
  - `.github/workflows/ci.yml` picker syntax/test coverage for Linux and Windows
  - `templates/terminal-banner.txt` responsive PromptKit terminal art
  - `README.md`, `QUICKSTART.md`, and `CHANGELOG.md`
  - `docs/tasks/TASK-2026-10-02-keyboard-installer-wizard.md` (this record)
- **Explicit Non-Goals**:
  - `No installer package, profile, tracker, or host-template changes beyond interactive selection behavior.`
  - `No merge, tag, or release action; merge remains human-only.`
- **Dependencies**: `None`
- **Risk**: `Medium — the installer is a cross-platform setup boundary; Bash and PowerShell behavior must remain aligned, and cancellation must precede project writes.`
- **Verification Condition**: `Bash and PowerShell picker tests; Bash and PowerShell installer syntax/help checks; existing installer safety and profile suites; behavioral contract tests; reference, execution-control, changelog, and staged-secret gates; real terminal behavior at 80 and 120 columns; Windows CI.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Interactive terminal installation and rerun behavior.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-02-keyboard-installer-wizard; init.sh, init.ps1, README.md, QUICKSTART.md.`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-10-02-keyboard-installer-wizard.md (this record).`
- **User-Observable Before Behavior**: `Profile, tracker, and AI-host selections used typed values or numeric lists, making mistypes easy and offering limited correction before setup.`
- **User-Observable After Behavior**: `Interactive terminals show arrow-key radio choices and Space-key checkboxes, preserve installed choices on reruns, provide a final edit/install/cancel screen, and offer a responsive PromptKit banner. Command-line and redirected non-interactive behavior remain available.`
- **Impact Classification**: `User-Facing Additive Contract Change`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `Adds a new interactive setup experience while preserving documented command-line and non-interactive installation paths.`
- **Migration and Upgrade Guidance**: `N/A — installer reruns keep the installed profile, tracker, projection, and detected host selections unless the user changes them.`
- **Maintenance Commit Declaration**: `N/A — intentional interactive UX improvement.`

## 4. Acceptance Criteria

- [x] **AC-1**: `In an interactive TTY, profile and task-tracker questions use Up/Down and Enter; hosts and the optional GitHub projection use Up/Down, Space, and Enter.`
- [x] **AC-2**: `A final review screen summarizes the selections and lets users edit a choice, install, or cancel. Cancellation exits before installer project writes.`
- [x] **AC-3**: `A responsive text banner shows the full supplied art in wide terminals and a compact title in narrower terminals; headings use readable symbols.`
- [x] **AC-4**: `Existing installer settings remain selected on reruns, including universal-only AGENTS.md installs, while explicit flags and non-interactive behavior continue to work.`
- [x] **AC-5**: `Both picker helper suites pass single-select movement, checkbox toggling, and cancellation; Bash PTY runs pass at 80 and 120 columns.`
- [x] **AC-6**: `README, QUICKSTART, changelog, and Linux/Windows CI describe or verify the delivered picker behavior.`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion, missing authorization for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically enforce checkpoint deadlines; timing remains a manual protocol limitation.`
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-02`
- **Current Actor**: `PromptKit maintainer (review) + Codex (handoff)`
- **Next Action**: `Run the final exact-head review after this evidence-record correction, then push and open the PR for maintainer review; PR CI will run after creation, and merge remains human-only.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-02 | Codex | Task initialized from user request to make the keyboard picker and banner plan PR-ready. | User request |
| planned | in_progress | 2026-10-02 | Codex | Implementing the Bash and PowerShell wizard, tests, and documentation. | Branch `codex/installer-keyboard-picker` |
| in_progress | awaiting_review | 2026-10-02 | Codex | Implementation and local verification complete; preparing exact-commit review and PR handoff. | Section 6 |
| awaiting_review | in_progress | 2026-10-02 | Codex | Goal review reproduced loss of the universal-only host choice on rerun; fixed both installers and added matrix regression coverage. | `.omo/evidence/installer-keyboard-picker/review-ledger.md`; Bash profile matrix and 80-column PTY rerun |
| in_progress | awaiting_review | 2026-10-02 | Codex | Universal-only rerun fix and regression tests pass; fresh exact-head review and PR CI remain. | Section 6; `.omo/evidence/installer-keyboard-picker/final-refresh/` |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `.github/workflows/ci.yml`
  - `CHANGELOG.md`
  - `QUICKSTART.md`
  - `README.md`
  - `init.ps1`
  - `init.sh`
  - `scripts/terminal-picker.ps1`
  - `scripts/terminal-picker.sh`
  - `scripts/tests/run-terminal-picker-tests.ps1`
  - `scripts/tests/run-terminal-picker-tests.sh`
  - `scripts/tests/run-profile-matrix.ps1`
  - `scripts/tests/run-profile-matrix.sh`
  - `templates/terminal-banner.txt`
  - `docs/tasks/TASK-2026-10-02-keyboard-installer-wizard.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Bash picker PASS; PowerShell picker PASS; Bash syntax PASS; PowerShell init.ps1 -Help PASS; Bash init safety PASS; Bash profile matrix 10/10 PASS including universal-only AGENTS.md rerun; Bash behavioral contracts 394/394 PASS; Bash execution-control fixture/property suites and strict validator PASS; Bash staged-secret and reference-link tests PASS; Bash strict token budget PASS (Balanced 2350/2500, Lite 1286/1500); git diff --check PASS. Harness preflight PASS from the primary checkout; the linked-worktree checkout reports the documented GIT_LAYOUT limitation. Bash installer PTY install/edit/cancel plus AGENTS-only rerun evidence and fresh 80/120-column xterm.js screens and width checks are under .omo/evidence/installer-keyboard-picker/.`
- **CI Evidence**: `Pending PR CI.`
- **Review Evidence**: `Implementation review lanes passed at 630bfd2d5957700b7f9a9e659101c95b0f891f13, including native Windows TTY QA. An exact-head review at 86d0f362cd9170225b4a3802119ceb3c4a9bc033 found an inaccurate commit-attribution phrase in this record; this correction clarifies the history. Run the final exact-head handoff review before PR creation. Local reports are under .omo/evidence/installer-keyboard-picker/.`
- **Commit Evidence**: `Feature commit b84a81737831d2e0c23d6bae87e30fe387a8e911; universal-only rerun preservation and its regression coverage are in 630bfd2d5957700b7f9a9e659101c95b0f891f13. Later task-record evidence reconciliations are documentation-only commits.`
- **Pull Request Evidence**: `Pending.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass with AGENTS-only regression fixed and verified; AC-5 Pass; AC-6 Pass locally; PR CI pending.`
- **Changed-File Summary**: `Add keyboard-driven setup and review screens to both installers, responsive terminal branding, focused tests and CI wiring; preserve universal-only host selection across reruns.`
- **Completion Exception**: `The full PowerShell profile matrix cannot run from the WSL-backed shell because its nested child command pwsh is unavailable; direct WSL-hosted installer runs also hit the Windows provider-path boundary. The interactive wizard itself was exercised in a native Windows Console at 80 and 120 columns, including install/edit/cancel, rerun preservation, and universal-only AGENTS.md rerun. Windows PR CI remains pending.`
- **Completion Decision and Timestamp**: `Acceptance criteria and native Windows interaction pass. This task-record correction fixes the inaccurate commit attribution found during handoff review; rerun the final exact-head review before PR creation. PR CI remains pending — 2026-10-02.`
