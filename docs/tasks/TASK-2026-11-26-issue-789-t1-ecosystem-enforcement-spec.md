# Task Record: Ecosystem enforcement pack T1 design (issue #789)

<a id="TASK-2026-11-26-issue-789-t1-ecosystem-enforcement-spec"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-26-issue-789-t1-ecosystem-enforcement-spec`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Stage T1 of issue #789: decide how ecosystem enforcement packs reach a consumer, which deterministic host-hook cells can be claimed and under what evidence rule, and what contract makes pack installation idempotent and progressively discovered. Docs only; the issue's three owner decisions are resolved with a ruling, a rationale, and a reversal condition each.`
- **External Reference (Optional)**: `GitHub issue #789`
- **Owner / Actor**: `Release Coordinator (approver) + DeepSeek Harness (executor)`
- **Execution Scope**: `promptkit-os repository, docs only; docs/specs/2026-11-26-spec-ecosystem-enforcement-packs.md, docs/tasks/TASK-2026-11-26-issue-789-t1-ecosystem-enforcement-spec.md, and CHANGELOG.md. Local implementation and verification, then one documentation commit on branch rfc/789-ecosystem-enforcement-spec.`
- **Approval Boundary**: `Phase 1 (this record): local documentation and verification only, with zero code change. Phase 2 (separate authorization): branch push and one pull request to main. Merge, force-push, squash/rebase/amend, tag, release, npm publication, issue closure, and repository-settings changes remain unauthorized.`
- **Created**: `2026-11-26`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Replace the kit's unsupported advice that a consumer may wire the shipped validators into their own CI with a design that names the channel, the evidence rule, and the installation contract, so that Stage T2 can build one pack on one host without reopening any of the three owner decisions.`
- **In Scope**:
  - `docs/specs/2026-11-26-spec-ecosystem-enforcement-packs.md` — the T1 design record: four gaps, measured inventory with reconciliation, current-state map, stage gates, three rulings, invariants, risks and open questions, acceptance criteria, verification commands
  - `docs/tasks/TASK-2026-11-26-issue-789-t1-ecosystem-enforcement-spec.md` (this record)
  - `CHANGELOG.md` — one `[Unreleased]` `### Documentation` bullet
- **Explicit Non-Goals**:
  - `No edit to any .sh, .ps1, .mjs, .yml, .gitattributes, init.sh, init.ps1, template, protocol, or workflow file — the issue's zero-code rule for T1.`
  - `No implementation of the consumer entry point, the opt-in hook installer, the contains-i: rubric variants, the shellcheck or PSScriptAnalyzer gates, the macOS job, or any twin consolidation: all are T2 deliverables named by the spec, not built here.`
  - `No edit to docs/ENFORCEMENT.md, docs/HOST-CONFORMANCE.md, or docs/BEHAVIORAL-EVAL.md: the consumer tier section and the new check types land with the code that makes them true, so this record does not let the documentation run ahead of the mechanism.`
  - `No commit, push, PR, merge, tag, release, or issue update beyond the single local commit in the execution scope.`
- **Dependencies**: `None. Issue #789 is the only external input; the tier-contract precedent in issue-553-progressive-compliance.md was read, not modified.`
- **Risk**: `Low — no behavior surface changes and no code is touched. The residual risk is design drift: a later stage could cite these rulings loosely, which section 5 of the spec counters by binding each T2 gate to numbered invariants and by marking every hook cell NONE.`
- **Verification Condition**: `bash scripts/validate-references.sh . --strict exits 0 with the new specification included; bash scripts/check-changelog-entry.sh reports PASS; git diff --check is clean; git status --short lists exactly the three in-scope files; every quantitative claim in the spec states its measurement basis and the one figure that does not reproduce from the tree is recorded as a reconciliation rather than smoothed.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `None.`
- **Contract Impact Evidence ID / Path**: `docs/specs/2026-11-26-spec-ecosystem-enforcement-packs.md, CHANGELOG.md`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-11-26-issue-789-t1-ecosystem-enforcement-spec.md (this record); GitHub issue #789.`
- **User-Observable Before Behavior**: `A consumer who wants the kit's mechanical checks enforced had one sentence of documentation and no supported path: docs/ENFORCEMENT.md states that wiring the shipped validators into consumer CI is a user-side integration, not a shipped feature. No published design existed for how packs would be distributed, which host lifecycle hooks could actually block a write, or how installation would behave on a second run.`
- **User-Observable After Behavior**: `A reader of docs/specs gains three rulings with rationale and reversal conditions: Decision 1 stages a consumer entry point plus an opt-in installer before any reusable Action, over one hermetic entry point; Decision 2 records every host-hook cell as NONE with a five-condition rule for promotion and a default-deny answer to the enforcement question; Decision 3 fixes the managed-block, re-run, removal, drift-check, and progressive-discovery contracts, and adds case-insensitive rubric variants without a whole-fixture flag. Nothing user-visible changes at runtime: no file a consumer installs, no script, and no workflow is modified by this record.`
- **Impact Classification**: `Internal Maintenance Change`
- **Proposed SemVer Candidate Impact**: `none`
- **Impact Rationale**: `Documentation only. No shipped prompt, workflow, template, protocol, script behavior, CLI surface, installer behavior, or measured figure changes; docs/ and CHANGELOG.md are not behavior-surface paths under scripts/check-changelog-entry.sh, so the gate reports a pass for a range that carries no behavior-surface file.`
- **Migration and Upgrade Guidance**: `N/A`
- **Maintenance Commit Declaration**: `N/A`

## 4. Acceptance Criteria

- [x] **AC-1**: `The specification exists at docs/specs/2026-11-26-spec-ecosystem-enforcement-packs.md and answers Decisions 1, 2, and 3, each with an explicit ruling, its rationale, and its reversal condition.`
- [x] **AC-2**: `Every quantitative claim states its measurement basis; the measured inventory and the section 1.5 reconciliation record the shell total as 31,091 across 87 files, the issue figure as a claim of record, and the +4 line delta as unattributable rather than silently adopted or dropped.`
- [x] **AC-3**: `Every host-hook cell records NONE, distinct from the registry's Untested, with the five promotion conditions and a default-deny rule; no vendor hook schema is restated because none was read.`
- [x] **AC-4**: `Zero code change: git status --short lists exactly the three in-scope files and no script, workflow, installer, template, or protocol appears in the diff.`
- [x] **AC-5**: `The specification's non-goals restate the issue's invariants verbatim in substance: no daemon, proxy, mandatory npm dependency, or network service; no silent hook installation without an explicit opt-in command.`
- [x] **AC-6**: `bash scripts/validate-references.sh . --strict, bash scripts/check-changelog-entry.sh, and git diff --check all pass on the committed tree.`

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
- **Next Action**: `Maintainer review of branch rfc/789-ecosystem-enforcement-spec, then confirmation of the three T1 rulings; push and PR require separate authorization, and T2 needs its own record.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-11-26 | DeepSeek Harness | Task initialized from the Wave D handoff for issue #789 Stage T1. | Issue #789 body |
| planned | in_progress | 2026-11-26 | DeepSeek Harness | Measured the inventory, mapped the current state, and drafted the three rulings. | Section 6 |
| in_progress | awaiting_review | 2026-11-26 | DeepSeek Harness | Local verification complete and one documentation commit created on the design branch. | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/specs/2026-11-26-spec-ecosystem-enforcement-packs.md`
  - `docs/tasks/TASK-2026-11-26-issue-789-t1-ecosystem-enforcement-spec.md`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `bash scripts/validate-references.sh . --strict exits 0 with the new specification scanned (all references valid, no broken links); bash scripts/check-changelog-entry.sh reports CHANGELOG_GATE|PASS with no repeated heading; git diff --check prints nothing; git status --short lists exactly the three in-scope files. The inventory was re-derived at d7ede1f: 86 tracked .sh files summing to 31,045 lines plus the 46-line extensionless scripts/pk, 75 tracked .ps1 files at 25,122 wc -l lines (25,123 counting the unterminated final line of scripts/run-behavioral-eval.ps1), four .mjs files at 2,011 lines, 12 CI jobs in an 898-line workflow with zero shellcheck, PSScriptAnalyzer, and macOS occurrences, and 11 registry host rows of which 3 are PARTIAL and 8 Untested. The issue's 31,095 shell-line figure did not reproduce and is recorded in section 1.5 of the spec with its basis rather than adopted.`
- **CI Evidence**: `Pending — branch not pushed; no CI job exists for this worktree branch. The three local gates above are the complete T1 gate.`
- **Review Evidence**: `Pending maintainer review of the three rulings.`
- **Commit Evidence**: `Single documentation commit on branch rfc/789-ecosystem-enforcement-spec carrying this record, the specification, and the CHANGELOG bullet. The commit that contains this record cannot cite its own SHA; the SHA is reported in the completion handoff instead of being written into the file it would change.`
- **Pull Request Evidence**: `Pending separate authorization.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass (sections 4, 5, and 6 of the spec carry the three rulings with rationale and reversal conditions); AC-2 Pass (inventory table with basis column and the section 1.5 reconciliation); AC-3 Pass (matrix cells NONE, five promotion conditions, default-deny rule, no vendor schema restated); AC-4 Pass (three files in scope, zero code change); AC-5 Pass (non-goals in spec section 7.1); AC-6 Pass (three gates run locally and green).`
- **Changed-File Summary**: `Add the T1 design specification for ecosystem enforcement packs, covering the consumer Tier-1 vacuum, the unclaimed host-hook surfaces, the flat-file versus progressive-discovery gap, and the dual-shell and rubric-literalism tax; rule on the distribution channel, the hook matrix with default-deny, and the idempotency and progressive-discovery contract; and record one CHANGELOG documentation entry.`
- **Completion Exception**: `No PowerShell suite was executed because the local pwsh is an unusable WSL shim; none was in scope, since this record changes no .ps1 and no behavior. The four-line difference between the measured shell total and the figure in issue #789 is left unexplained and documented rather than reconciled by inference.`
- **Completion Decision and Timestamp**: `Acceptance criteria verified on every surface this environment can execute; committed locally for review — 2026-11-26.`

