# Task Record: Issue #602 Installed-Instruction Integrity Documentation

## 1. Identity and Authority
- **Record Type**: Task Record
- **Task ID**: TASK-2026-10-14-issue-602-installed-instruction-integrity
- **Ceremony Level**: Level 2 (Controlled Work)
- **PromptKit Adaptation Profile**: none
- **Work Type**: Documentation
- **Planning Record Link**: N/A — requester-provided Issue #602 specification is the controlling formal scope
- **Planning Depth Reference**: N/A — no architecture or design change
- **Assumption Record Links**: None
- **Specification**: User-provided Issue #602 authorization and acceptance criteria (F-04 / B4)
- **External Reference (Optional)**: https://github.com/lowqualityloey/promptkit-os/issues/602 (read-only)
- **Owner / Actor**: Local coding agent; no collaborators
- **Execution Scope**: protocols/setup.md, docs/MIGRATION.md, CHANGELOG.md, and docs/tasks/TASK-2026-10-14-issue-602-installed-instruction-integrity.md
- **Approval Boundary**: Coordinator DOCS ONLY direction (2026-10-14) authorized implementation and review in isolated worktree. Subsequent coordinator commit authorization permits exactly one local atomic commit of the four-file scope on branch docs/issue-602-instruction-integrity. No push, PR creation, merge, rebase, amend, second commit, issue update, release, tag, npm publication, or cross-project logging.
- **Created**: 2026-10-13 21:15 UTC (2026-10-14 10:15 NZDT)

## 2. Objective and Boundaries
- **Objective**: Document the installed-instruction integrity boundaries, threat models, and residual risks across Git submodule, npm courier, standalone vault, and host-directive installation modes, distinguishing archive and transport verification from post-install and host runtime execution.
- **In Scope**:
  - protocols/setup.md: add Installed-Instruction Integrity Boundary subsection covering the four distinct lifecycle stages, threat model, and optional environmental defenses.
  - docs/MIGRATION.md: add concise cross-reference from courier upgrade guidance to protocols/setup.md.
  - CHANGELOG.md: add minimal [Unreleased] Changed entry for Issue #602.
  - docs/tasks/TASK-2026-10-14-issue-602-installed-instruction-integrity.md: maintain canonical Level 2 execution record.
- **Explicit Non-Goals**:
  - No new checksum manifests, integrity verifiers, Git hooks, daemons, background schedulers, or runtime services.
  - No changes to existing security scanners, installers, or verification behavior.
  - No changes to docs/ARCHITECTURE.md or release evaluation history.
  - No push, PR creation, merge, rebase, amend, second commit, issue update, release, tag, npm publication, or cross-project logging.
- **Dependencies**: Verified current main baseline 2617a5d77ff78658eeb5ff1706fde81d4d1a71fa; isolated worktree at .worktrees/issue-602-instruction-integrity on branch docs/issue-602-instruction-integrity.
- **Risk**: Overstating security guarantees could mislead users into expecting runtime protection against local file tampering; understating existing archive pins could obscure PR #616 courier guarantees.
- **Verification Condition**: Pass reference validation, behavioral contract suites, execution control validator, and git diff --check cleanly.

## 3. Acceptance Criteria
- [x] **AC-1**: Git submodule boundaries precisely distinguish gitlink commit recording, Git object tree hashing, git submodule status '+' commit-drift semantics (not working-tree dirty detection), explicit working-tree status checks, and non-mandatory runtime pre-load status.
- [x] **AC-2**: npm courier boundaries precisely state version-specific SHA-256 archive pins, fail-closed handling on missing/malformed pins, pre-extraction verification, PROMPTKIT_TARBALL_SHA256 operator override, historical 1.11.0 fail-open behavior, and trust dependencies on npm and GitHub releases.
- [x] **AC-3**: Standalone and host-directive boundaries note Git tracking limits, user-owned content preservation, and that presence/version checks do not constitute runtime cryptographic proof of loaded instructions.
- [x] **AC-4**: Threat model separates accidental drift, authorized customization, malicious post-install tampering, compromised distribution, and compromised host/AI environment; explains unanchored self-referential manifest limits without claiming zero utility.
- [x] **AC-5**: Optional OS-level hardening distinguishes ordinary discretionary permissions from security boundaries (chmod -R a-w does not stop same-user processes) and notes read-only mount tradeoffs.
- [x] **AC-6**: protocols/setup.md carries concise subsection Installed-Instruction Integrity Boundary; docs/MIGRATION.md carries minimal cross-reference.
- [x] **AC-7**: CHANGELOG.md carries [Unreleased] Changed entry.
- [x] **AC-8**: All local verification gates (reference validation, behavioral contracts, execution control, git diff --check) pass cleanly.

## 4. Execution Policy
- **Mode**: Gated Mode
- **TDD Enforcement Mode**: disabled; documentation-only task
- **Batch Authorization**: N/A
- **Authorization Checkpoint Reference**: User authorization in Issue #602 request and commit authorization
- **Soft Checkpoint**: After documentation drafting
- **Hard Checkpoint**: Stop on baseline drift, scanner code mutation, or unauthorized file modification
- **Event-Driven Checkpoints**: Baseline, review, and final pre-commit verification
- **Stop Conditions**: Baseline drift; code modifications; scope creep into daemons/manifests; any push, PR, merge, issue update, rebase, amend, or second commit
- **Host Timer Capability**: Limitation — no task-wide live timer is enforced; tool calls bounded by executor timeouts

## 5. State and Active Ownership
- **Execution State**: completed
- **Mapped `pk:tasks` Status**: Done
- **Active Task Pointer**: None
- **Start Time**: 2026-10-13T21:15:00Z
- **Current Actor**: Local coding agent
- **Next Action**: Execute one authorized local atomic commit on branch docs/issue-602-instruction-integrity; perform post-commit verification; stop.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-13 21:15 UTC | Local coding agent | Preflight verified baseline 2617a5d; created isolated worktree | Verified git status and rev-parse |
| planned | in_progress | 2026-10-13 21:20 UTC | Local coding agent | Drafted Task Record; initiated documentation updates | TASK-2026-10-14-issue-602-installed-instruction-integrity.md |
| in_progress | completed | 2026-10-13 22:05 UTC | Local coding agent | Completed documentation updates, review corrections, and local verification gates | Verified reference links, behavioral contracts, and execution control |

## 6. Evidence and Completion Gate
- **Changed Files**:
  - protocols/setup.md — added Installed-Instruction Integrity Boundary subsection covering lifecycle stages, threat models, and optional hardening.
  - docs/MIGRATION.md — added cross-reference to setup protocol integrity boundary.
  - CHANGELOG.md — added [Unreleased] Changed entry for issue #602.
  - docs/tasks/TASK-2026-10-14-issue-602-installed-instruction-integrity.md — canonical Level 2 execution record.
- **Scope Change Records**: None — strictly within authorized 4-file documentation scope.
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: Reference validation (bash scripts/validate-references.sh .) passed with zero errors across 383 markdown files (exit 0); Reference-link suite (bash scripts/tests/run-reference-link-tests.sh) passed 8/8 tests (exit 0); Behavioral contracts (bash scripts/tests/run-behavioral-contract-tests.sh) passed 450/450 tests (exit 0); Execution control validator (bash scripts/validate-execution-control.sh --root .) passed with 66 valid records (exit 0); git diff --check exited 0 with no whitespace errors. PowerShell twin status: scripts/validate-execution-control.ps1 passed with 66 valid records (exit 0); scripts/tests/run-reference-link-tests.ps1 passed 8/8 tests (exit 0); under WSL-native /usr/bin/pwsh, scripts/validate-references.ps1 passed (exit 0) and scripts/tests/run-behavioral-contract-tests.ps1 passed 448/448 (exit 0).
- **CI Evidence**: N/A — local worktree only; no push or pull request performed; native Windows CI observation awaits separate publication authorization.
- **Review Evidence**: Independent review performed in the separate Level 2 review report; security claims, submodule distinctions, courier pinning semantics, host runtime limitations, and review corrections verified against current source without findings.
- **Commit Evidence**: One local atomic commit authorized on branch docs/issue-602-instruction-integrity covering exactly the four authorized documentation files; no remote push, PR, or history rewrite.
- **Pull Request Evidence**: N/A — explicitly prohibited.
- **Release Evidence**: N/A — no release authorized.
- **Blocker and Resume Condition**: None.
- **Completion State**: completed
- **Acceptance Results**: AC-1 PASS; AC-2 PASS; AC-3 PASS; AC-4 PASS; AC-5 PASS; AC-6 PASS; AC-7 PASS; AC-8 PASS.
- **Changed-File Summary**: Exactly four files changed in isolated worktree: protocols/setup.md, docs/MIGRATION.md, CHANGELOG.md, and docs/tasks/TASK-2026-10-14-issue-602-installed-instruction-integrity.md.
- **Completion Exception**: None; all authorized verification checks passed cleanly.
- **Completion Decision and Timestamp**: Local documentation implementation and verification completed on 2026-10-13 22:05 UTC (2026-10-14 11:05 NZDT); one local atomic commit authorized.
