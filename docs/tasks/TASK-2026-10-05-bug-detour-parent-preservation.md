# Task Record: Parent task and milestone preserved across debug and fix detours

<a id="TASK-2026-10-05-bug-detour-parent-preservation"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-05-bug-detour-parent-preservation`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/528`
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; pk:debug and pk:fix detour discipline, the canonical Task Record detour block, and the published static/per-task token figures those edits move`
- **Approval Boundary**: `Issue #528 authorizes the workflow-contract repair. Merge remains human-only; no tag, release, publish, remote, deploy, or rollback action is authorized.`
- **Created**: `2026-10-05`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Make a bug fix taken during an unfinished parent task explicitly preserve and restore the interrupted parent continuation, so resolving a local defect cannot leave the original objective, milestone, authorization, or next action ambiguous. Requires: a bounded detour entry that captures the parent continuation in the existing canonical record; exactly one failure-classification verdict routed through the existing interception table; detour-scoped verification whose evidence never satisfies the parent's remaining acceptance criteria; an exit that restores the parent or records a blocker and halts; and survival across compaction/handoff without duplicating the parent task.`
- **In Scope**:
  - `docs/tasks/TASK-2026-10-05-bug-detour-parent-preservation.md` (this record)
  - `workflows/fix.md` (new bounded Step 5 detour contract; Step 5/6 renumbered to Step 6/7 with cross-references and Completion Criteria updated)
  - `workflows/debug.md` (Phase 6 detour pointer)
  - `templates/execution-task-record-template.md` (optional Active Detour block)
  - `docs/BENCHMARKS.md` (re-measured core-six, full-set, and pk:fix payload figures)
  - `README.md` (propagated baseline label)
  - `FAQ.md` (propagated baseline label)
  - `scripts/tests/run-behavioral-contract-tests.sh` (baseline column key realigned)
  - `scripts/tests/run-behavioral-contract-tests.ps1` (PowerShell twin of the column key)
  - `CHANGELOG.md` (record `[Unreleased]` entry)
- **Explicit Non-Goals**:
  - `No new record type, parallel action ledger, or independent state system; the detour persists as an optional block inside the existing canonical Task Record.`
  - `No changes to workflows/sync.md; its canonical New-Requirement Interception table already owns requirement routing and is referenced, not restated.`
  - `No changes to scripts/validate-execution-control.sh/.ps1 label lists; the Active Detour block is optional and adds no required label.`
  - `No repair-budget semantics changes; bounded-repair and whole-task aggregate budget behavior remain as specified in protocols/code-quality-gate.md and are out of scope for this issue.`
  - `No claim that this reduces measured session drift or provider latency; no behavioral conformance result is asserted.`
  - `No edits to historical records under docs/tasks (pre-existing), docs/releases, docs/reviews, or docs/archive.`
  - `No merge, tag, or release action (merge remains strictly human-only).`
- **Dependencies**: `Builds on #527 handover fields and the #526 recovery contract merged in PR #531. Verification of behavioral evidence remains dependent on #525, which is unimplemented and excluded from this change.`
- **Risk**: `Low-Medium — documentation contract repair with a renumbering risk in workflows/fix.md and a published-figure coupling, since workflows/debug.md belongs to the core-six Lite subset and workflows/fix.md carries its own per-task budget.`
- **Verification Condition**: `Behavioral contract suite passes with 420 assertions and zero failures in both Bash and PowerShell variants; the pk:fix per-task budget stays under its 12,861 tok baseline in strict mode; static token budgets pass; reference validation, reference-link harness, and release-record examples pass; execution control validation reports VALID; every string-literal assertion pinned against workflows/fix.md and workflows/debug.md still matches verbatim.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `pk:fix and pk:debug workflow behavior during in-task bug detours, the canonical Task Record detour fields, and the published token figures derived from those files.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-05-bug-detour-parent-preservation; workflows/fix.md, workflows/debug.md, templates/execution-task-record-template.md.`
- **Supporting Planning / Review Record**: `N/A — sourced directly from issue #528.`
- **User-Observable Before Behavior**: `A fix started during an unfinished task narrowed to the defect and had no explicit instruction to preserve or restore the interrupted objective, milestone, authorization, or next action. On success the agent could report the bug fixed with the parent continuation ambiguous; on failure the parent context could be lost. Nothing recorded where the interruption came from, so recovery after compaction or handoff could not restore it.`
- **User-Observable After Behavior`: `pk:fix captures a bounded detour entry in the existing canonical Task Record, classifies the failure exactly once, scopes verification to the detour, then either restores the parent continuation to its own remaining acceptance criteria or records a blocker with an owner and precise resume condition and halts. pk:debug marks a mid-task surgical fix as a detour. The detour survives compaction and handoff without spawning a duplicate parent task.`
- **Impact Classification**: `Documentation and Contract Clarification`
- **Proposed SemVer Candidate Impact**: `patch`
- **Impact Rationale`: `Adds a bounded workflow contract with no new state system, no schema change, and no runtime behavior; it clarifies an existing gap between the debug/fix guidance and the checkpoint/recovery contract.`
- **Migration and Upgrade Guidance**: `N/A — existing Task Records stay valid because the detour block is optional and adds no required field.`
- **Maintenance Commit Declaration**: `N/A — intentional contract completion.`

## 4. Acceptance Criteria

- [x] **AC-1**: `Debug/fix entry and exit explicitly preserve/restore the parent objective and next step — workflows/fix.md Step 5 items 1 and 4 capture the parent task/milestone, interrupted next action, objective, approved scope, authorization reference, and pending stop condition on entry, and restore the recorded next action, remaining acceptance criteria, and stop conditions on exit.`
- [x] **AC-2**: `Parent task completion still depends on its original remaining acceptance criteria — Step 5 states detour evidence never satisfies the parent's remaining acceptance criteria and that a green detour is not parent completion; mirrored in workflows/debug.md Phase 6.`
- [x] **AC-3**: `Out-of-scope findings follow existing authorization/interception rules — Step 5 item 2 assigns exactly one verdict and routes blocking new requirements through the existing Scope Change Record or planning re-open, and unrelated findings to the Later ledger or a separate Task Record, referencing the canonical New-Requirement Interception table in workflows/sync.md instead of restating it.`
- [x] **AC-4**: `Unresolved detours preserve blockers and stop conditions across recovery — Step 5 item 4 keeps the captured parent continuation intact, records owner plus precise resume condition, and halts with the canonical BLOCKED callout; item 5 plus the record template's Active Detour block make the entry recoverable after compaction or handoff without duplicating the parent task.`
- [x] **AC-5**: `No detour silently starts another milestone or resets repair budgets — Step 5 item 4 requires respecting the bounded-repair limit and any milestone sign-off and states a detour cannot grant new authority; the Active Detour block records that detour bookkeeping does not reset the repair counter or the whole-task aggregate budget.`
- [x] **AC-6**: `All repository verification gates pass on the rebuilt base, and the published core-six, full-set, and pk:fix payload figures are propagated to every claim site.`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `N/A — no external-harness continuation loop authorizes this change`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, compaction, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion beyond the recorded In Scope boundary, missing approval for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically enforce checkpoint deadlines, observe an in-flight detour, or forcibly stop generation; timing and detour observation remain a manual protocol limitation.`
- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-05`
- **Current Actor**: `Sisyphus (executor)`
- **Branch / Revision**: `fix/drift-527-530` (base `origin/main` @ `2fee6d7`)
- **Next Action**: `None — merged in PR #532. Successor work is tracked in #525.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-05 | Sisyphus | Task initialized from issue #528 source-backed missing return-to-parent transition. | Issue #528 |
| planned | in_progress | 2026-10-05 | Sisyphus | Delegated the two workflow files, then integrated the canonical record block and figure propagation. | Local edits on branch fix/drift-527-530 |
| in_progress | awaiting_review | 2026-10-05 | Sisyphus | Step 5 detour contract, debug Phase 6 pointer, and record block in place; full gate suite green. | 420/420 behavioral contracts |
| awaiting_review | completed | 2026-10-05 | Sisyphus (executor) | PR #532 merged; post-merge commit, PR, CI, and review evidence recorded. | PR #532 / 4c858b0 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/fix.md`
  - `workflows/debug.md`
  - `templates/execution-task-record-template.md`
  - `docs/tasks/TASK-2026-10-05-bug-detour-parent-preservation.md`
  - `docs/BENCHMARKS.md`
  - `README.md`
  - `FAQ.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Behavioral contract suite 420 passed / 0 failed; execution control VALID (61 records); strict static and per-task budgets pass (pk:fix 11,454 Balanced / 10,390 Lite against a 12,861 baseline); validate-references, reference-link harness 6/6, release-record examples, profile matrix 10/10, execution-control properties, playbook contracts, and git diff --check passed. Itemized commands are recorded below.`
  - `bash scripts/tests/run-behavioral-contract-tests.sh` passed (420 passed, 0 failed).
  - Every string-literal assertion pinned against `workflows/fix.md` and `workflows/debug.md` in both the Bash and PowerShell suites was re-verified present verbatim after the edit (6 for fix.md, 5 for debug.md, plus the `Level 0 and Level 1.*bypass` regex).
  - `bash scripts/measure-per-task-tokens.sh --strict` passed; `pk:fix` Balanced payload 10,597 tok and Lite payload 9,534 tok remain under the 12,861 tok baseline.
  - `bash scripts/measure-tokens.sh --strict` passed (BALANCED 2401/2500, LITE 1338/1500).
  - `bash scripts/validate-execution-control.sh --root .` passed (VALID, 58 records).
  - `bash scripts/validate-references.sh .`, `bash scripts/tests/release-records.examples.sh`, and `bash scripts/tests/run-reference-link-tests.sh` (6/6) passed.
  - `bash scripts/tests/run-profile-matrix.sh`, `run-execution-control-properties.sh`, and `run-playbook-contract-tests.sh` passed.
  - `git diff --check` passed.
  - Re-measured after the change: core-six Lite subset 29,252 -> 29,391 tok; full 25-workflow set 109,368 -> 110,319 tok; `pk:fix` Balanced 9,785 -> 10,597 tok and Lite 8,722 -> 9,534 tok, with its context-reduction cells updated from -24%/-32% to -18%/-26%.
  - Not verified: PowerShell behavioral-contract parity cannot execute in this WSL environment — the PowerShell measurement tool exits 64 and yields empty output, reproducing on a pristine detached worktree at `2fee6d7`. Windows CI was resolved by the PR #532 Windows job. No behavioral host capture was performed, so no model-conformance or drift-reduction result is claimed.
- Final merged measurement at `4c858b0`: core-six Lite subset **29,391 tok**, full 25-workflow set **111,086 tok**, Balanced **2,475/2,500**, Lite **1,411/1,500**, `pk:fix` **11,454** Balanced / **10,390** Lite — matching `docs/BENCHMARKS.md`. Earlier deltas above are that commit's incremental effect, not current state.
- **CI Evidence**: `PR #532 CI passed on 4c858b0 (Linux, Windows, and staged secret-scan jobs). The Windows job ran the PowerShell behavioral-contract variant, so the parity limitation recorded in Verification Evidence is resolved rather than outstanding.`
- **Review Evidence**: `Adversarial review of PR #532 returned APPROVE WITH CONDITIONS; its stale-body and disclosure findings were fixed in 28634fb and 97d5ffb and merged within #532.`
- **Commit Evidence**: `Squash-merged as 4c858b0 via PR #532; branch commits b8941e2 (#527), 8f9e2f7 (#528), 6a3d3e6 (#529), 86d4e24 (#530), 28634fb and 97d5ffb (review follow-ups).`
- **Pull Request Evidence**: `PR #532 (https://github.com/lowqualityloey/promptkit-os/pull/532), merged to main as 4c858b0.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `completed`
- **Acceptance Results**: `AC-1 through AC-6 verified against the local gate suite.`
- **Changed-File Summary**: `Add a bounded bug-detour contract to pk:fix and pk:debug, persist the detour in the canonical Task Record, and re-propagate the published token figures.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `2026-10-05T03:52:00+13:00`