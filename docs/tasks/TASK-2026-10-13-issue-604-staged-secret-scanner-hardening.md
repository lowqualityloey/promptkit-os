# Task Record: Staged-secret scanner hardening (issue #604)

<a id="TASK-2026-10-13-issue-604-staged-secret-scanner-hardening"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-13-issue-604-staged-secret-scanner-hardening`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Extend the staged-secret scanner twins with conservative, format-aware detectors for OpenAI project (sk-proj-), Anthropic (sk-ant-), npm (npm_), Stripe test/restricted (sk_test_, rk_live_), and OpenAI classic (sk-) credentials, with synthetic positive, negative, and regression fixtures, preserving staged-additions-only scanning, NUL-safe paths, redaction, fail-closed semantics, and Bash/PowerShell parity.`
- **External Reference (Optional)**: `GitHub issue #604`
- **Owner / Actor**: `Release Coordinator (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; scripts/scan-staged-secrets.sh + .ps1 twin, scripts/tests/run-staged-secret-scan-tests.sh + .ps1 twin, docs/ADOPTION-GUIDE.md detection-limitations note, CHANGELOG.md, and this record. Local implementation and verification, then one implementation commit, its branch push, and one PR to main.`
- **Approval Boundary**: `Two authorized phases. Phase 1: local implementation, synthetic fixtures, and Bash/PowerShell verification only. Phase 2 (separate authorization): one implementation commit on a dedicated branch, its non-force push, and one PR to main, plus CI observation. Merge, force-push, squash/rebase/amend, release/tag/npm publication, issue closure, and repository-settings changes remain unauthorized.`
- **Created**: `2026-10-13`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Close five credential-format detection gaps in both scanner twins without loosening any existing invariant: detect OpenAI project/classic keys, Anthropic keys, npm access tokens, and Stripe test/restricted keys on staged additions only, reporting redacted file:line diagnostics under the existing exit tiers.`
- **In Scope**:
  - `scripts/scan-staged-secrets.sh` detector block and path-redaction array`
  - `scripts/scan-staged-secrets.ps1` detector array (drives detection and path redaction)`
  - `scripts/tests/run-staged-secret-scan-tests.sh` synthetic positive/negative/regression fixtures`
  - `scripts/tests/run-staged-secret-scan-tests.ps1` synthetic positive/negative/regression fixtures`
  - `docs/ADOPTION-GUIDE.md` credential-coverage and staged-boundary limitations note`
  - `docs/tasks/TASK-2026-10-13-issue-604-staged-secret-scanner-hardening.md` (this record)`
- **Explicit Non-Goals**:
  - `No entropy scoring, external API lookups, secret uploads, new dependencies, or separate scanner subsystem.`
  - `No change to exit-code semantics (1 secret, 2 scan-incomplete, 3 narrative), staged-only boundary, NUL-safe path handling, redaction, or narrative-surface precedence.`
  - `No edit to GitHub Actions configuration, release tooling, workflow routing, model policy, or other security subsystems.`
  - `No commit, push, PR, merge, tag, release, Actions dispatch, or issue update.`
- **Dependencies**: `None`
- **Risk**: `Medium — a noisy detector would add false positives to the commit gate, and a non-portable regex would silently break the mawk engine the test suite exercises.`
- **Verification Condition**: `Bash scanner regression suite green under gawk, mawk, and mawk -W traditional; PowerShell scanner regression suite green under the Windows PowerShell runtime; identical Bash/PowerShell detection sets across the full detector family; shellcheck, bash -n, PowerShell AST parse, git diff --check, reference validation, and behavioral-contract tests all green.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `pk:commit staged-secret gate detector coverage on added lines (exit 1 tier).`
- **Contract Impact Evidence ID / Path**: `scripts/scan-staged-secrets.sh, scripts/scan-staged-secrets.ps1, scripts/tests/run-staged-secret-scan-tests.sh, scripts/tests/run-staged-secret-scan-tests.ps1.`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-10-13-issue-604-staged-secret-scanner-hardening.md (this record); GitHub issue #604.`
- **User-Observable Before Behavior**: `OpenAI project (sk-proj-), Anthropic (sk-ant-), npm (npm_), Stripe test (sk_test_), Stripe restricted (rk_live_), and OpenAI classic (sk-) credential-shaped strings staged in a commit were not reported; the scanner exited 0.`
- **User-Observable After Behavior**: `Each staged addition carrying one of those shapes is reported as a redacted file:line diagnostic under exit 1, with content suppressed; existing detections and all other invariants are unchanged.`
- **Impact Classification**: `User-Facing Additive Contract Change`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `Adds detector coverage without removing, renaming, or altering any existing detector, exit tier, boundary, or output format.`
- **Migration and Upgrade Guidance**: `N/A — no migration; the gate simply detects five more credential families.`
- **Maintenance Commit Declaration**: `N/A — intentional additive contract change.`

## 4. Acceptance Criteria

- [x] **AC-1**: `Both twins detect OpenAI project (sk-proj-), Anthropic (sk-ant-), npm (npm_), Stripe test (sk_test_), Stripe restricted (rk_live_), and OpenAI classic (sk-) staged additions under exit 1, reporting redacted file:line only.`
- [x] **AC-2**: `Negative fixtures (ordinary prose mentioning prefixes, malformed/short look-alikes, benign identifiers, below-threshold classic key, unstaged content, removed-only content) stay silent and exit 0.`
- [x] **AC-3**: `Existing detections (AWS, GitHub ghp_/gho_/ghu_/ghs_/ghr_/github_pat_, Stripe sk_live_, Slack, Google, JWT, private-key, password/entropy), staged-only boundary, NUL-safe paths, redaction, and fail-closed 1/2/3 tiers are unchanged.`
- [x] **AC-4**: `Bash and PowerShell twins produce identical detection categories and exit codes for the full detector family.`
- [x] **AC-5**: `bash -n, shellcheck, PowerShell AST parse, and git diff --check are clean; reference validation and behavioral-contract tests remain green.`
- [x] **AC-6**: `No authentic or literal matchable credential appears in any fixture, log, or file.`

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
- **Start Time**: `2026-10-13`
- **Current Actor**: `Sisyphus`
- **Next Action**: `Observe the PR's Linux and Windows CI checks; merge remains human-only.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-13 | Sisyphus | Task initialized from the coordinator's Level 2 authorization. | Coordinator brief |
| planned | in_progress | 2026-10-13 | Sisyphus | Verified baseline, reproduced gaps, and implemented detectors in both twins. | Section 6 |
| in_progress | awaiting_review | 2026-10-13 | Sisyphus | Local implementation and verification complete; uncommitted by design. | Section 6 |
| awaiting_review | in_progress | 2026-10-13 | Sisyphus | Publication authorized: independent diff review, CHANGELOG entry, and final gates before one commit. | Coordinator brief; Section 6 |
| in_progress | awaiting_review | 2026-10-13 | Sisyphus | One implementation commit created, branch pushed without force, and a PR opened to main; awaiting CI and human merge. | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/scan-staged-secrets.sh`
  - `scripts/scan-staged-secrets.ps1`
  - `scripts/tests/run-staged-secret-scan-tests.sh`
  - `scripts/tests/run-staged-secret-scan-tests.ps1`
  - `docs/ADOPTION-GUIDE.md`
  - `docs/tasks/TASK-2026-10-13-issue-604-staged-secret-scanner-hardening.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Baseline before edits: bash suite exit 0 (gawk, mawk, mawk-traditional); PowerShell suite exit 0. Gap reproduction: both scanners exit 0 on six synthetic staged families. After edits: bash suite exit 0 with 28 redacted detections across three awk engines; PowerShell suite exit 0 with 20 redacted detections. Direct cross-runtime parity: identical 20 detection categories and exit 1 for the full detector family. shellcheck and bash -n clean on both Bash scripts; PowerShell AST parse clean on both PowerShell scripts; git diff --check clean. Reference validation exit 0 (zero warnings). Behavioral contract 450/450 PASS. CHANGELOG gate PASS. Independent reviewer verdict APPROVE-WITH-NITS with no blocking findings (prefix-length gates exact, byte-identical Bash/PowerShell behavior, full redaction, no ReDoS, no leaked material).`
- **CI Evidence**: `Pending PR CI.`
- **Review Evidence**: `Independent diff review (fresh reviewer context) returned APPROVE-WITH-NITS with no blocking findings; non-blocking nits: documented shape-based false-positive risk at the commit gate, out-of-scope coverage gaps (sk-svcacct-/sk-admin-/rk_test_), and a pre-existing PowerShell-suite category asymmetry.`
- **Commit Evidence**: `Recorded on the single feature commit of the dedicated branch fix/604-staged-secret-scanner-hardening.`
- **Pull Request Evidence**: `Pending.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass; AC-5 Pass; AC-6 Pass.`
- **Changed-File Summary**: `Add five credential-family detectors to both scanner twins, extend both regression suites with synthetic positive/negative/regression fixtures, and document detector coverage and the staged-additions-only boundary.`
- **Completion Exception**: `PowerShell parity was verified with the Windows PowerShell 7.6.6 runtime (pwsh.exe) invoked from WSL against fixtures on the Windows temp filesystem, not a natively initiated Windows session, and Windows CI remains the authoritative parity check.`
- **Completion Decision and Timestamp**: `Acceptance criteria pass on both surfaces within the environment's limits; local gates and the independent review passed, and the change was committed and opened as a PR under separate authorization. Merge remains human-only — 2026-10-13.`
