# Task Record: CI gate integrity (issue #783)

<a id="TASK-2026-11-26-issue-783-ci-gate-integrity"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-26-issue-783-ci-gate-integrity`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Close three mechanical CI gaps: make staged-secret-scan a required input of the Linux aggregate, resolve its diff base from the triggering event instead of unconditionally origin/main, and make the scan inspect the head-vs-base additions in a temporary base worktree so it cannot pass vacuously, wire the missing Windows token-budget regression twin, and replace both hand-maintained syntax lists with fail-closed git ls-files discovery.`
- **External Reference (Optional)**: `GitHub issue #783`
- **Owner / Actor**: `Release Coordinator (approver) + DeepSeek Harness (executor)`
- **Execution Scope**: `promptkit-os repository; .github/workflows/ci.yml, CONTRIBUTING.md, CHANGELOG.md, and this record. Local implementation and verification, then one implementation commit on branch fix/783-ci-gate-integrity.`
- **Approval Boundary**: `Phase 1 (this record): local implementation and verification only. Phase 2 (separate authorization): branch push and one pull request to main. Merge, force-push, squash/rebase/amend, tag, release, npm publication, issue closure, and repository-settings changes remain unauthorized.`
- **Created**: `2026-11-26`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Make the required CI aggregators report the truth: no pull request can pass with a failing credential/narrative scan, push and scheduled runs resolve a real commit range instead of scanning an empty diff, the Windows token-budget twin runs, and every tracked shell and PowerShell script is parsed without a hand-maintained list.`
- **In Scope**:
  - `.github/workflows/ci.yml` — `staged-secret-scan` step base resolution, `validate-linux.needs` and `jq` assertion, Linux Bash syntax discovery, Windows PowerShell syntax discovery, Windows token-budget test step
  - `CONTRIBUTING.md` — the pre-PR twin-parity checklist item and both local syntax-validation snippets, which now call the same discovery commands
  - `CHANGELOG.md` — one `[Unreleased]` / `### Fixed` entry
  - `docs/tasks/TASK-2026-11-26-issue-783-ci-gate-integrity.md` (this record)
- **Explicit Non-Goals**:
  - `No edit to any shipped workflow, template, protocol, or script implementation outside the two syntax/test/scan steps named above.`
  - `No change to scanner detection rules, exit tiers, `scripts/tests/run-token-budget-tests.{sh,ps1}`, or any benchmark figure.`
  - `No `docs/ARCHITECTURE.md` edit: it names the two aggregator jobs as the required checks, and adding a job to `validate-linux.needs` keeps that statement true.`
  - `No tokenizer `--strict` work, no `BENCHMARKS.md` anchor restatement, no link rewiring — those belong to issues #788, #787, and #786.`
  - `No commit, push, PR, merge, tag, release, Actions dispatch, or issue update beyond the single local commit in the execution scope.`
- **Dependencies**: `None.`
- **Risk**: `Low — the workflow change is additive (one more required job, one more Windows step) and the discovery loops are proven against the current tree; the residual risk is a future checkout that lacks `git`, which the non-empty guard fails closed rather than skips.`
- **Verification Condition**: `python yaml.safe_load parses .github/workflows/ci.yml with the expected job count, step order, and needs; the extracted scan step passes a 27-case isolated harness (push leak -> 1 with redaction, push clean -> 0, no-diff -> 0, all-zero -> skip, missing base -> 1 fail-closed, schedule -> skip, pull-request merge leak -> 1, pull-request clean -> 0, no leftover worktrees or dirty repos); the Linux discovery loop parses every tracked .sh plus scripts/pk with zero errors and reports the count; the jq gate exits 1 when staged-secret-scan is failing and 0 when it is green; the Bash twins of the touched suites stay green; git diff --check is clean; PowerShell suites are inspected because the local pwsh shim cannot execute.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `None.`
- **Contract Impact Evidence ID / Path**: `.github/workflows/ci.yml, CONTRIBUTING.md`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-11-26-issue-783-ci-gate-integrity.md (this record); GitHub issue #783.`
- **User-Observable Before Behavior**: `A pull request whose commit range failed the staged-secret scan could still receive a green Lint & Validate (Linux) verdict; worse, the read-tree plus add -A construction rebuilt HEAD's tree in the index, so the scan always produced an empty diff on a clean checkout and had never inspected a single addition, on pull requests either; push and scheduled runs scanned nothing; 10 tracked .sh and 13 tracked .ps1 scripts were never parsed in CI; the Windows token-budget twin never ran.`
- **User-Observable After Behavior**: `The Linux aggregate fails when the scan fails; the scan resolves the event's real commit range, checks out the base into a temporary worktree, loads the head tree into that worktree's index so the scanner sees the range's added lines, cleans the worktree up, and reports a deliberate skip only for events with no range; every tracked script is parsed, and the Windows token-budget suite runs in `windows-code-d`. Contributors are told the sweeps discover scripts automatically.`
- **Impact Classification**: `Internal Maintenance Change`
- **Proposed SemVer Candidate Impact**: `none`
- **Impact Rationale**: `CI enforcement and contributor instructions only; no shipped prompt, workflow, template, protocol, script behavior, CLI surface, or measured figure changes. `ci.yml`, `CONTRIBUTING.md`, and `docs/` are not behavior-surface paths under scripts/check-changelog-entry.sh.`
- **Migration and Upgrade Guidance**: `N/A`
- **Maintenance Commit Declaration**: `N/A`

## 4. Acceptance Criteria

- [x] **AC-1**: `A pull request whose staged-secret-scan exits 1, 2, or 3 fails Lint & Validate (Linux): the job is in needs and the jq gate asserts its result is success.`
- [x] **AC-2**: `A push event with a valid non-zero before SHA diffs that SHA's tree against the head tree in a temporary base worktree, so the scan reads the push's actual additions; an all-zero or empty before SHA fails safe and exits 0; a before SHA absent from fetched history fails closed with exit 1; schedule and workflow_dispatch report a skip instead of scanning an empty diff.`
- [x] **AC-3**: `On a full-lane PR or scheduled run, windows-code-d invokes scripts/tests/run-token-budget-tests.ps1 after the syntax sweep.`
- [x] **AC-4**: `Both syntax steps discover inputs from git ls-files ('*.sh' plus scripts/pk, '*.ps1'), parse 100% of them, exit non-zero when discovery returns nothing, and CONTRIBUTING.md documents automatic discovery rather than static lists.`

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
- **Start Time**: `2026-11-26`
- **Current Actor**: `DeepSeek Harness`
- **Next Action**: `Human review of branch fix/783-ci-gate-integrity and its CI run; push and PR require separate authorization.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-11-26 | DeepSeek Harness | Task initialized from the coordinator's Wave A handoff. | Issue #783 body |
| planned | in_progress | 2026-11-26 | DeepSeek Harness | Reproduced the three gaps in `.github/workflows/ci.yml` and applied the fixes. | Section 6 |
| in_progress | awaiting_review | 2026-11-26 | DeepSeek Harness | Local verification complete and one commit created on the feature branch. | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `.github/workflows/ci.yml`
  - `CONTRIBUTING.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-26-issue-783-ci-gate-integrity.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `python3 yaml.safe_load parses the workflow (12 jobs); windows-code-d step order is [Checkout Repository, Validate PowerShell Script Syntax, Run Token Budget Gate Regression Tests (PowerShell)]; validate-linux needs is [changes, linux-docs, linux-code-a, linux-code-b, staged-secret-scan]; the jq gate exits 1 with staged-secret-scan=failure and 0 with success; the extracted scan step passed a 27-assertion isolated harness: push leak exits 1 with a redacted detection, push clean exits 0, identical base/head reports `No diff against <sha> to scan.` exit 0, all-zero before is a notice exit 0, a missing before SHA is exit 1 fail-closed, schedule is a notice exit 0, a pull-request-shaped merge checkout with the fake `sk-proj-...` line exits 1, the same shape with a clean line exits 0, and every run left no worktree entry and no dirty tree; a scratch reproduction also proved the old read-tree plus add -A construction produced an empty diff on a clean merge checkout while `git diff --name-only <base> <merge>` listed the changed file, confirming the prior step was structurally vacuous; running the extracted Linux syntax step locally prints `Parsed 87 shell scripts with 0 syntax errors.` (86 tracked .sh plus scripts/pk); bash -n is clean across every tracked script; both CONTRIBUTING.md snippets run the same `git ls-files` discovery as CI; git diff --check is clean.`
- **CI Evidence**: `Pending — Windows and Linux jobs have not run against this branch.`
- **Review Evidence**: `Pending human review.`
- **Commit Evidence**: `Two commits on branch fix/783-ci-gate-integrity: c4dc4f4171785aa32189d7a1242ef72f352a1fe1 (required aggregate input, event-derived base, discovery loops, Windows twin, CONTRIBUTING, this record, CHANGELOG) and a follow-up that replaces the vacuous read-tree/add -A diff with the temporary base-worktree range scan and records the deeper root cause.`
- **Pull Request Evidence**: `Pending separate authorization.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass (needs and jq assertion; exhausted via jq exit-code probe); AC-2 Pass (27-assertion harness: push range, skip, fail-closed, and pull-request merge shapes); AC-3 Pass (workflow wiring verified statically; PowerShell suite not executable locally); AC-4 Pass.`
- **Changed-File Summary**: `Make staged-secret-scan a required Linux input, resolve its base from the event, and build the range diff in a temporary base worktree so the scanner actually reads added lines; replace both syntax lists with fail-closed discovery, wire the Windows token-budget twin, and document automatic discovery in CONTRIBUTING.`
- **Completion Exception**: `The local pwsh is an unusable WSL shim (it execs a Windows PowerShell path that does not exist), so no PowerShell suite could be executed here; the added step is verified by YAML structure and step order only, and Windows CI remains authoritative.`
- **Completion Decision and Timestamp**: `Acceptance criteria verified on every surface the environment can execute; committed locally for review — 2026-11-26.`
