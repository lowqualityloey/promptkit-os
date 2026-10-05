# Task Record: Engine version stamp and drift detection

<a id="TASK-2026-10-06-engine-version-stamp"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-06-engine-version-stamp`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Stamp the installed engine identity into both directive templates and docs/STATE.md, and make pk:sync report engine drift as one of six explicit states instead of leaving staleness undetected.`
- **External Reference (Optional)**: `GitHub issue #545`
- **Owner / Actor**: `PromptKit maintainer (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; both installer twins, both directive templates, the state-tracker template, the pk:sync workflow, published token figures, and changelog`
- **Approval Boundary**: `User authorized making the change PR-ready, including branch push and PR creation. Merge remains human-only.`
- **Created**: `2026-10-06`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Make a stale engine install impossible to miss: record the engine version and short SHA at install time, and give pk:sync a deterministic six-state drift audit that distinguishes unknown, ok, behind(+n), diverged, shallow-or-offline, and not-a-git-install.`
- **In Scope**:
  - `init.sh` engine-identity resolution, directive token substitution, `Installed:` refresh on rerun, and STATE.md stamping`
  - `init.ps1` behavioral twin of the same four changes`
  - `templates/agent-directive-template.md` and `templates/agent-directive-lite-template.md` stamp tokens`
  - `templates/state-tracker-template.md` Engine Version row in section 1`
  - `workflows/sync.md` Engine Version and Drift Audit subsection (three comparisons, six states, hard rules)`
  - `docs/BENCHMARKS.md`, `README.md`, `FAQ.md`, `protocols/setup.md`, `templates/lite-profile.md` published token figures`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-10-06-engine-version-stamp.md` (this record)`
- **Explicit Non-Goals**:
  - `No upgrade execution. The stamp detects and offers; running the upgrade stays out of scope.`
  - `No drift arithmetic from git describe --abbrev=0, which discards commit distance and would hide the very signal this task records.`
  - `No merge, tag, or release action; merge remains human-only.`
  - `No edits to issues #546-#553; their revised specifications remain unfiled local drafts.`
- **Dependencies**: `None`
- **Risk**: `Medium — both installer twins must stay behaviorally identical, the stamp line consumes directive token budget, and every published token figure in the repository shifts as a consequence.`
- **Verification Condition**: `Strict token budget gate; behavioral contract tests; reference validator with zero warnings; per-task baseline gate; a real non-interactive install proving the stamp renders and the rerun path refreshes both placeholders.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Installed directive block content, docs/STATE.md section 1, and pk:sync Phase 1 engine-version reporting.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-06-engine-version-stamp; init.sh, init.ps1, both directive templates, templates/state-tracker-template.md, workflows/sync.md.`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-10-06-engine-version-stamp.md (this record); scratch/issue-draft-01-engine-version-stamp.md`
- **User-Observable Before Behavior**: `Nothing recorded which engine version was installed. Re-runs rewrote only the PROMPTKIT.md profile line, so the template's - **Installed**: [YYYY-MM-DD] placeholder survived forever, and a stale engine was indistinguishable from a current one until a governance failure was noticed by hand.`
- **User-Observable After Behavior**: `Every install stamps the engine version and short SHA into the host directive and docs/STATE.md. pk:sync classifies the engine as exactly one of unknown, ok, behind(+n), diverged, shallow-or-offline, or not-a-git-install and reports that state's remediation verbatim. Re-runs refresh the Installed date and both stamps.`
- **Impact Classification**: `User-Facing Additive Contract Change`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `Adds a stamped engine identity and a deterministic drift audit without removing or altering any existing documented installation path.`
- **Migration and Upgrade Guidance**: `N/A — no migration required. Installs without a stamp resolve to the unknown state, which warns once and never errors, and the next installer run stamps them.`
- **Maintenance Commit Declaration**: `N/A — intentional additive contract change.`

## 4. Acceptance Criteria

- [x] **AC-1**: `A fresh install renders a real engine version and short SHA in the host directive with no unsubstituted token remaining, and docs/STATE.md carries the same identity.`
- [x] **AC-2**: `The stamp preserves commit distance: a checkout past a tag records the distance suffix rather than the bare tag name.`
- [x] **AC-3**: `A rerun refreshes the PROMPTKIT.md Installed date and both engine stamps, replacing the shipped placeholders with real values.`
- [x] **AC-4**: `pk:sync documents three distinct comparisons, the six-state result table, and the hard rules banning --abbrev=0, requiring --match 'v[0-9]*', and refusing to guess in shallow or courier installs.`
- [x] **AC-5**: `Both directive templates stay within budget (Balanced 2375/2500, Lite 1311/1500) and all published token figures match live measurement.`
- [x] **AC-6**: `init.sh and init.ps1 carry the same four behaviors: resolution, substitution, Installed refresh, and STATE.md stamping.`

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
- **Start Time**: `2026-10-06`
- **Current Actor**: `Sisyphus (handoff)`
- **Next Action**: `Maintainer reviews the PR diff, focusing on the six-state table in workflows/sync.md and the installer stamp blocks in init.sh and init.ps1; merge remains human-only.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-06 | Sisyphus | Task initialized from user request to make the engine-stamp PR review-ready. | User request |
| planned | in_progress | 2026-10-06 | Sisyphus | Implementing the installer twins, templates, and the pk:sync drift audit. | Section 6 |
| in_progress | awaiting_review | 2026-10-06 | Sisyphus | Implementation and local verification complete; preparing PR handoff. | Section 6 |
| awaiting_review | in_progress | 2026-10-06 | Sisyphus | Rebased onto origin/main (87df03f), which independently compressed the directive and added a published-figure provenance gate; all published token figures re-measured and re-propagated against the merged tree. | `git rebase` conflict resolution; Section 6 |
| in_progress | awaiting_review | 2026-10-06 | Sisyphus | Rebase conflict resolved by taking upstream for the six figure-only files, re-measuring every published figure against the merged tree, and re-propagating; all gates green. | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `init.sh`
  - `init.ps1`
  - `templates/agent-directive-template.md`
  - `templates/agent-directive-lite-template.md`
  - `templates/state-tracker-template.md`
  - `workflows/sync.md`
  - `docs/BENCHMARKS.md`
  - `README.md`
  - `FAQ.md`
  - `protocols/setup.md`
  - `templates/lite-profile.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-10-06-engine-version-stamp.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Behavioral contract tests 443/443 PASS (Failed: 0) after the branch was rebased onto origin/main (87df03f). Strict token budget PASS (Balanced 2312/2500, Lite 1436/1500). Per-task baseline gate 6/6 PASS. Turbo overhead strict gate PASS (ship 2.01x, window 1.00-2.60). Reference validation exit 0 with zero warnings. Execution-control strict validation VALID (62 records). Changelog gate exit 0. bash -n init.sh PASS. PowerShell parse of init.ps1 PASS via Parser::ParseInput. Real non-interactive install into a scratch project: directive rendered Engine: v1.10.1-12-ge78fde0 (e78fde0), docs/STATE.md rendered v1.10.1-12-ge78fde0 @ e78fde0, PROMPTKIT.md Installed 2026-10-06, and zero unsubstituted tokens remained in CLAUDE.md, AGENTS.md, PROMPTKIT.md, or docs/STATE.md. Rerun after restoring both shipped placeholders refreshed them to real values, proving the Installed-refresh fix. git check-ignore -v docs/STATE.md exits 1, confirming docs/ is not ignored in this repository.`
- **CI Evidence**: `Pending PR CI.`
- **Review Evidence**: `Local self-review only; no independent reviewer pass on this change.`
- **Commit Evidence**: `Pending; recorded on the feature commit once created.`
- **Pull Request Evidence**: `Pending.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass; AC-5 Pass; AC-6 Pass for the Bash twin and verified by parse plus a resolver-level differential test for the PowerShell twin.`
- **Changed-File Summary**: `Stamp engine identity at install time in both installers and both directive templates, add the STATE.md engine row, add a six-state drift audit to pk:sync, and repropagate every published token figure.`
- **Completion Exception**: `The PowerShell twin could not be executed end to end in this environment. init.ps1:272 in the canonical-path resolver throws under WSL-UNC paths; this is the same provider-path defect class that v1.11.0 fixed for scripts/validate-execution-control.ps1 and scripts/scan-staged-secrets.ps1, and that change set left init.ps1:495 on provider-qualified paths. Independently, Windows git refuses the WSL UNC checkout with exit 128 (detected dubious ownership in repository), so the resolver degraded to unknown, which is the specified fail-safe behavior. PowerShell parity is therefore evidenced by parser validation plus a resolver-and-substitution differential test, not by a completed Windows install. Windows PR CI remains the authoritative check.`
- **Completion Decision and Timestamp**: `Acceptance criteria pass on the Bash surface and the PowerShell surface is verified to the limit the environment allows. Merge remains human-only — 2026-10-06.`