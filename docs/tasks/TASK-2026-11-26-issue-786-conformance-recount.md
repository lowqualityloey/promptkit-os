# Task Record: Host-conformance recount and validator inventories (issue #786)

<a id="TASK-2026-11-26-issue-786-conformance-recount"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-26-issue-786-conformance-recount`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Make the published conformance counts agree with the 11-row registry table, make protocols/setup.md list the full 26-workflow and 9-protocol inventory, correct the disproven transitive-discovery claim in favour of the measured protocols/context-economy.md §11 finding, and replace the validators' hand-maintained 20/21/4 inventories with filesystem-derived 29/26/9 inventories pinned by both behavioural-contract twins.`
- **External Reference (Optional)**: `GitHub issue #786`
- **Owner / Actor**: `Release Coordinator (approver) + DeepSeek Harness (executor)`
- **Execution Scope**: `promptkit-os repository; README.md, protocols/setup.md, docs/HOST-CONFORMANCE.md, docs/WORKFLOW-MAP.md, scripts/validate-references.{sh,ps1}, scripts/tests/run-behavioral-contract-tests.{sh,ps1}, CHANGELOG.md, and this record. Local implementation and verification, then one implementation commit on branch docs/786-conformance-counts.`
- **Approval Boundary**: `Phase 1 (this record): local implementation and verification only. Phase 2 (separate authorization): branch push and one pull request to main. Merge, force-push, squash/rebase/amend, tag, release, npm publication, issue closure, and repository-settings changes remain unauthorized.`
- **Created**: `2026-11-26`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Every published statement about host-conformance coverage and every validator inventory now agrees with the repository: three of eleven hosts carry live captures and eight are Untested, setup.md registers all 26 workflows and all 9 protocols, discovery is described as measured rather than transitive, and both validators derive and count the real inventory so the figures cannot drift silently again.`
- **In Scope**:
  - `README.md` — host-conformance count sentence and the Command Code CLI / two-turn capture additions
  - `docs/HOST-CONFORMANCE.md` — §3 pointer and §4 set/capture wording
  - `protocols/setup.md` — host-coverage item, context-economy discovery note, workflow and protocol registries
  - `docs/WORKFLOW-MAP.md` — maintenance branch of the decision tree and the navigation rows
  - `scripts/validate-references.sh` — filesystem-derived template/workflow/protocol inventories and registration checks
  - `scripts/validate-references.ps1` — PowerShell twin of the same derivation and registration checks
  - `scripts/tests/run-behavioral-contract-tests.sh` — assertions pinning the counts and the corrected sentences
  - `scripts/tests/run-behavioral-contract-tests.ps1` — PowerShell twin of the same pinned assertions
  - `CHANGELOG.md` — one `[Unreleased]` / `### Fixed` entry
  - `docs/tasks/TASK-2026-11-26-issue-786-conformance-recount.md` (this record)
- **Explicit Non-Goals**:
  - `No edit to any file under workflows/ or to templates/agent-directive*.md, so the docs/BENCHMARKS.md provenance anchor stays where it is (AC-4).`
  - `No change to scanner, tokenizer, release, or benchmark logic and no re-propagation of measured figures.`
  - `No new host captures and no change to the registry table's verdicts; this record corrects the prose around the measured table, not the evidence behind it.`
  - `No link rewiring or export-ignore work (issue #787), no directive token trimming (issue #788), no RFC (issue #789).`
  - `No commit, push, PR, merge, tag, release, Actions dispatch, or issue update beyond the single local commit in the execution scope.`
- **Dependencies**: `Issue #785 touches init.{sh,ps1} and script tests only; it does not edit any file in this scope, so no ordering or conflict applies.`
- **Risk**: `Low — documentation and validator inventories only; the functional risk is a validator that flags an unregistered workflow or protocol, which is exactly the direction the issue asks for, and both validators were run against the full tree.`
- **Verification Condition**: `Both validate-references twins pass --strict/-Strict on the edited tree and print the complete 29-template / 26-workflow / 9-protocol inventory with every workflow and protocol registered in protocols/setup.md; both behavioural-contract twins pass with the new count and sentence assertions; the stale anchors are absent from the tree; no file under workflows/ or templates/ and no docs/BENCHMARKS.md line differs from d7ede1f; git diff --check and the changelog gate are clean.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `None.`
- **Contract Impact Evidence ID / Path**: `README.md, docs/HOST-CONFORMANCE.md, protocols/setup.md, docs/WORKFLOW-MAP.md, scripts/validate-references.{sh,ps1}`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-11-26-issue-786-conformance-recount.md (this record); GitHub issue #786.`
- **User-Observable Before Behavior**: `README.md said eight of ten host configurations were registered while the registry table listed eleven; docs/HOST-CONFORMANCE.md §3 sent readers to §5 for captures that §4 records, and §4's prose still spoke of ten hosts and eleven captures; protocols/setup.md said only OpenCode carried live evidence and claimed context-economy.md was reached transitively, a route the six measured cells never took; setup.md listed 22 of 26 workflows and 8 of 9 protocols, so pk:fix, pk:refactor, pk:sync, pk:auto, and setup.md itself were missing from the reference surface; the decision tree omitted pk:auto, pk:doctor, pk:sync, pk:profile, and pk:verify-bootstrap; both validators checked 20 of 29 templates, 21 of 26 workflows, and 4 of 9 protocols, so a new or missing file could not fail CI.`
- **User-Observable After Behavior**: `The published counts agree with the measured table (three PARTIAL of eleven, eight Untested), setup.md registers every workflow and protocol the tree ships, the decision tree and navigation table cover the maintenance commands, and both validators derive their inventory from disk and fail when a file is missing, unexpected, or unregistered in setup.md, so the counts are pinned by the contract twins instead of maintained by hand.`
- **Impact Classification**: `Internal Maintenance Change`
- **Proposed SemVer Candidate Impact**: `none`
- **Impact Rationale**: `Documentation truthfulness and validator coverage only; no prompt, workflow behavior, template, protocol behavior, CLI surface, or measured figure changes, and docs/ plus scripts/validators are not behavior-surface paths for the measured anchor.`
- **Migration and Upgrade Guidance**: `N/A`
- **Maintenance Commit Declaration**: `N/A`

## 4. Acceptance Criteria

- [x] **AC-1**: `README.md, docs/HOST-CONFORMANCE.md, and protocols/setup.md state three live captures of eleven host configurations with eight Untested, agree with the 11-row §4 table, and carry no stale §5 or 1-of-5 pointers.`
- [x] **AC-2**: `protocols/setup.md lists all 26 workflows and all 9 protocols (including setup.md itself), and its context-economy note matches the measured protocols/context-economy.md §11 finding instead of the disproven transitive route.`
- [x] **AC-3**: `Both validate-references twins derive templates, workflows, and protocols from the filesystem with expected counts 29/26/9, require every workflow and protocol to be registered in protocols/setup.md, and the behavioural-contract twins pin those inventories so drift fails the gate.`
- [x] **AC-4**: `No file under workflows/ and no templates/agent-directive*.md changes, so the docs/BENCHMARKS.md anchor and every measured figure stay where they are.`

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
- **Next Action**: `Human review of branch docs/786-conformance-counts; push and PR require separate authorization.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-11-26 | DeepSeek Harness | Task initialized from the coordinator's Wave B handoff. | Issue #786 body |
| planned | in_progress | 2026-11-26 | DeepSeek Harness | Counted the tree, read the measured §11 record, and corrected the anchors and validators. | Section 6 |
| in_progress | awaiting_review | 2026-11-26 | DeepSeek Harness | Both validators and both contract twins green on the edited tree. | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `README.md`
  - `docs/HOST-CONFORMANCE.md`
  - `docs/WORKFLOW-MAP.md`
  - `protocols/setup.md`
  - `scripts/validate-references.sh`
  - `scripts/validate-references.ps1`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-26-issue-786-conformance-recount.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `bash scripts/validate-references.sh . --strict exits 0 (all references valid; 520 Markdown files end to end) and prints all 29 templates, all 26 workflows, and all 9 protocols, each workflow and protocol confirmed registered in protocols/setup.md; /opt/microsoft/powershell/7/pwsh -NoProfile -File scripts/validate-references.ps1 -PromptKitDir . -Strict reports all references valid; /opt/microsoft/powershell/7/pwsh -NoProfile -File scripts/tests/run-behavioral-contract-tests.ps1 reports Passed: 794 | Failed: 0; bash scripts/tests/run-behavioral-contract-tests.sh reports Passed: 807 | Failed: 0; grep -c confirms 26 workflow rows and 9 protocol rows in protocols/setup.md; git diff --stat d7ede1f shows no path under workflows/ or templates/.`
- **CI Evidence**: `Pending — branch not pushed, so no workflow ran.`
- **Review Evidence**: `Pending human review.`
- **Commit Evidence**: `Pending — the single commit on docs/786-conformance-counts is created after this record.`
- **Pull Request Evidence**: `Pending separate authorization.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass (counts, table agreement, and stale pointers verified by grep); AC-2 Pass (registries complete and context-economy note rewritten from §11); AC-3 Pass (both twins derive 29/26/9 and registration is enforced; contract twins pin the counts); AC-4 Pass (no workflows/ or templates/ diff).`
- **Changed-File Summary**: `Recount the conformance surface from the measured 11-row table, complete the workflow/protocol registry and decision tree, replace the transitive discovery claim with the measured finding, and make both validators derive and pin the real 29/26/9 inventory.`
- **Completion Exception**: `The suite was run with the PowerShell 7 binary at /opt/microsoft/powershell/7/pwsh because the local pwsh shim on PATH is an unusable WSL wrapper; no other environment limitation applied.`
- **Completion Decision and Timestamp**: `Acceptance criteria verified on the edited tree; committed locally for review — 2026-11-26.`
