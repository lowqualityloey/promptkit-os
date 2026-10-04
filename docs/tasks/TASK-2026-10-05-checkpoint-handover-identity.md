# Task Record: Checkpoint handover carries task identity, authority, and stop conditions

<a id="TASK-2026-10-05-checkpoint-handover-identity"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-05-checkpoint-handover-identity`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/527`
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; workflows/checkpoint.md Phase 4 handover template, its worked example, and the published static-token figures that workflow feeds`
- **Approval Boundary**: `Issue #527 authorizes the documentation contract repair. Merge remains human-only; no tag, release, publish, remote, deploy, or rollback action is authorized.`
- **Created**: `2026-10-05`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Reconcile the pk:checkpoint Phase 4 fresh-chat handover template with the checkpoint contract it is supposed to satisfy: the generated block must carry canonical Task Record identity, checkpoint/handoff record references, branch/revision and dirty-file state, objective/milestone, completed and remaining work, acceptance criteria and invariants, approved scope and approval source, pending human actions and blockers, execution state, the exact resume condition, and verification artifacts attributed by command/result/revision with an explicit historical-versus-current disclosure; the receiver must reconcile the canonical records before editing, and the unconditional "zero lost context" promise must be replaced with an explicit verification requirement.`
- **In Scope**:
  - `docs/tasks/TASK-2026-10-05-checkpoint-handover-identity.md` (this record)
  - `workflows/checkpoint.md` (Mission claim, Phase 4 handover template, worked example, Related References)
  - `docs/BENCHMARKS.md` (re-measured core-six and full-set token totals, reduction percentages, baseline label)
  - `README.md` (propagated baseline and reduction figures)
  - `FAQ.md` (propagated baseline figures)
  - `scripts/tests/run-behavioral-contract-tests.sh` (baseline column key realigned to the propagated label)
  - `scripts/tests/run-behavioral-contract-tests.ps1` (PowerShell twin of the same column key)
  - `CHANGELOG.md` (record `[Unreleased]` entry)
- **Explicit Non-Goals**:
  - `No changes to the Optional Release-Evaluation Handoff fragment semantics; it stays optional and keeps all eight fields.`
  - `No changes to scripts/validate-execution-control.sh/.ps1, their label lists, or any execution-control fixture.`
  - `No new Task Record, Checkpoint Record, or Handoff Record schema; the handover prompt projects existing canonical records only.`
  - `No edits to historical records under docs/tasks, docs/releases, docs/reviews, or docs/archive.`
  - `No scope expansion into the sibling issues #525 (eval scorer) or #526 (post-compaction recovery directives), which remain separate work.`
  - `No merge, tag, or release action (merge remains strictly human-only per protocols/code-quality-gate.md).`
- **Dependencies**: `Independent of #525 and #526; #525 supplies the behavioral evidence checks used to verify this change, and #526 covers the recovery bootstrap that remains separate.`
- **Risk**: `Low-Medium — documentation contract repair. The main coupling is arithmetic: workflows/checkpoint.md is one of the six Lite-subset workflows, so a longer template moves the published monolithic-baseline figures that the behavioral contract tests compare by exact equality.`
- **Verification Condition**: `Bash and PowerShell behavioral contract tests pass; release-record example checks pass; reference-link harness passes; reference validation passes; execution control validation passes; static token budgets and per-task budgets pass; changelog entry check passes; no "zero lost context" claim remains in workflows/checkpoint.md.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `The pk:checkpoint handover prompt emitted to fresh chat sessions, and the published static-token baseline figures derived from it.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-05-checkpoint-handover-identity; workflows/checkpoint.md, docs/BENCHMARKS.md.`
- **Supporting Planning / Review Record**: `N/A — sourced directly from issue #527.`
- **User-Observable Before Behavior**: `The generated ordinary-task handover prompt offered narrative task/status, a file list, invariants, and a next step only. Canonical Task Record identity, checkpoint/handoff references, approval source, pending human actions, execution state, and the exact resume condition could be lost across a handoff, and the workflow advertised resumption "with zero lost context" regardless of what the receiver could actually verify.`
- **User-Observable After Behavior**: `The generated handover prompt carries the canonical identity, authority, state, evidence, and stop/resume fields that templates/execution-handoff-template.md defines, marks verification evidence as historical or current, requires receiver reconciliation of the canonical records before any edit, and states that nothing is preserved beyond what those records verify. Published baseline figures match the re-measured workflow set.`
- **Impact Classification**: `Documentation and Contract Clarification`
- **Proposed SemVer Candidate Impact**: `patch`
- **Impact Rationale`: `Corrects an incomplete generated artifact and an overstated preservation claim; it does not add a workflow, trigger, or state machine, and it changes no runtime behavior.`
- **Migration and Upgrade Guidance**: `N/A — no state, schema, or configuration migration. Re-run the installer if a generated directive copy of the workflow is tracked in the host repository.`
- **Maintenance Commit Declaration**: `N/A — intentional contract reconciliation.`

## 4. Acceptance Criteria

- [x] **AC-1**: `The Phase 4 generic handover template carries canonical Task Record path/ID, specification, checkpoint/handoff record references, branch plus validated revision, changed-file state including intentional uncommitted work, objective/milestone, completed and remaining work, acceptance criteria, locked invariants, and exactly one next action.`
- [x] **AC-2**: `The template carries the approval source and scope/approval constraints, pending human actions and blockers, the execution state, and the exact resume condition; it states that a narrative summary is not new authority.`
- [x] **AC-3**: `Verification artifacts are referenced by command, result, and revision, with an explicit historical-versus-current disclosure and a not-verified field; old success is never presented as a current-turn green claim.`
- [x] **AC-4**: `The receiver must inspect the canonical sources and reconcile identity, revision, changed files, acceptance criteria, invariants, blockers, and next action before editing; missing or conflicting boundary fields keep the receiver blocked or checkpoint_due rather than defaulting to approval or completion.`
- [x] **AC-5**: `Sections 1-6 are required for ordinary tasks including Level 0/1 work with no Task Record (explicit N/A), the release-evaluation fragment stays optional with all eight fields intact, and the worked example agrees with the template.`
- [x] **AC-6**: `The unconditional "zero lost context" claim is replaced by an explicit verification requirement in both the Mission and the template preamble.`
- [x] **AC-7**: `All repository verification gates pass, including exact-equality token figure assertions in both language variants, and the published baseline figures are propagated to every claim site.`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, compaction, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion beyond the recorded In Scope boundary, missing approval for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically enforce checkpoint deadlines or forcibly stop generation; timing remains a manual protocol limitation.`
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
| N/A | planned | 2026-10-05 | Sisyphus | Task initialized from issue #527 source-backed mismatch report. | Issue #527 |
| planned | in_progress | 2026-10-05 | Sisyphus | Starting the Phase 4 template rewrite, example reconciliation, and figure re-propagation. | Local edits to workflows/checkpoint.md |
| in_progress | awaiting_review | 2026-10-05 | Sisyphus | Template, example, and claim repaired; figures re-propagated; full gate suite green. | Stale-base draft; superseded by rebuild onto 2fee6d7 |
| awaiting_review | in_progress | 2026-10-05 | Sisyphus | Base staleness discovered: local HEAD e78fde0 predated origin/main 2fee6d7 (#524, #526/#531), so the token figures were measured against the wrong tree and every benchmark claim site collided. | git merge-base --is-ancestor 2fee6d7 HEAD returned false |
| in_progress | awaiting_review | 2026-10-05 | Sisyphus | Rebuilt onto origin/main @ 2fee6d7, re-measured, re-propagated all figure claim sites, and re-verified against the 420-test suite. | 13/13 local gates green |
| awaiting_review | completed | 2026-10-05 | Sisyphus (executor) | PR #532 merged; post-merge commit, PR, CI, and review evidence recorded. | PR #532 / 4c858b0 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `workflows/checkpoint.md`
  - `docs/tasks/TASK-2026-10-05-checkpoint-handover-identity.md`
  - `docs/BENCHMARKS.md`
  - `README.md`
  - `FAQ.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Base Reconcile Note**: `This work was first drafted against a stale local base (e78fde0, 2 commits behind origin/main @ 2fee6d7) and was rebuilt onto 2fee6d7. Every token figure below is measured on the corrected base; the stale-base numbers were discarded, not shipped.`
- **Handoff Records**: `None`
- **Verification Evidence**: `Behavioral contract suite 420 passed / 0 failed; execution control VALID (61 records); validate-references, reference-link harness 6/6, release-record examples, profile matrix 10/10, token-budget regression 7/7, execution-control properties, playbook contracts, milestone-halt and authorization fixtures, math labels, and git diff --check all passed. Itemized commands and the pre-existing WSL PowerShell limitation are recorded below; the PR #532 Windows job later ran that variant and passed.`
  - `bash scripts/tests/run-behavioral-contract-tests.sh` passed (420/420 passed, 0 failed) on base `2fee6d7`.
  - `bash scripts/validate-execution-control.sh --root .` passed (VALID, 58 records).
  - `bash scripts/tests/release-records.examples.sh` passed.
  - `bash scripts/tests/run-reference-link-tests.sh` passed (6/6).
  - `bash scripts/validate-references.sh .` passed (0 broken links).
  - `bash scripts/measure-tokens.sh --strict` passed (BALANCED 2401/2500, LITE 1338/1500).
  - `bash scripts/measure-per-task-tokens.sh --strict` passed.
  - `bash scripts/tests/run-profile-matrix.sh` passed.
  - `bash scripts/tests/run-execution-control-properties.sh` passed.
  - `bash scripts/tests/run-playbook-contract-tests.sh` passed.
  - `bash scripts/tests/run-token-budget-tests.sh` passed.
  - `bash scripts/tests/run-milestone-halt-evidence-fixtures.sh` and `run-authorization-evidence-fixtures.sh` passed.
  - `bash scripts/check-math-labels.sh --root .` and `git diff --check` passed.
  - Re-measured on the corrected base: core-six Lite subset 27,547 -> 29,252 tok; full 25-workflow set 107,662 -> 109,368 tok (incremental effect of #527 at commit `b8941e2`; superseded by later commits in the same PR); Balanced static reduction 91% -> 92%; Lite unchanged at 95%.
  - Repo-wide sweep confirms no unconditional "zero lost context" claim remains outside historical records.
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/tests/run-behavioral-contract-tests.ps1` cannot complete in this WSL environment: the PowerShell measurement tool exits 64 and yields empty output, cascading into figure-check failures. An identical failure reproduces on a pristine detached worktree at `2fee6d7`, so it is environmental and pre-existing, not a regression. The PR #532 Windows job later ran that variant and passed, so parity is confirmed rather than outstanding.
- Final merged measurement at `4c858b0`: core-six Lite subset **29,391 tok**, full 25-workflow set **111,086 tok**, Balanced **2,475/2,500**, Lite **1,411/1,500**, `pk:fix` **11,454** Balanced / **10,390** Lite — matching `docs/BENCHMARKS.md`. Earlier deltas above are that commit's incremental effect, not current state.
- **CI Evidence**: `PR #532 CI passed on 4c858b0 (Linux, Windows, and staged secret-scan jobs). The Windows job ran the PowerShell behavioral-contract variant, so the WSL measurement-tool limitation recorded in Verification Evidence no longer gates parity.`
- **Review Evidence**: `Adversarial review of PR #532 returned APPROVE WITH CONDITIONS; its stale-body and disclosure findings were fixed in 28634fb and 97d5ffb and merged within #532.`
- **Commit Evidence**: `Squash-merged as 4c858b0 via PR #532; branch commits b8941e2 (#527), 8f9e2f7 (#528), 6a3d3e6 (#529), 86d4e24 (#530), 28634fb and 97d5ffb (review follow-ups).`
- **Pull Request Evidence**: `PR #532 (https://github.com/lowqualityloey/promptkit-os/pull/532), merged to main as 4c858b0.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `completed`
- **Acceptance Results**: `AC-1 through AC-7 verified against the local gate suite.`
- **Changed-File Summary**: `Reconcile the pk:checkpoint fresh-chat handover template with the checkpoint contract and re-propagate the measured static-token baseline figures.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `2026-10-05T00:00:00+13:00`