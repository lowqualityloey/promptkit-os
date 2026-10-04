# Task Record: Pending human actions retained and required callouts checked

<a id="TASK-2026-10-05-pending-human-action-retention"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-05-pending-human-action-retention`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/529`
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; root directive pre-response trigger, the JIT-loaded callout protocol, the canonical pending-action record block, and every published figure the directive change moves`
- **Approval Boundary**: `Issue #529 authorizes the response-check contract repair. Merge remains human-only; no tag, release, publish, remote, deploy, or rollback action is authorized.`
- **Created**: `2026-10-05`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Ensure an unresolved human action cannot be lost, falsely resolved, or silently authorized away. Add a compact pre-response check to the root directives, make suppression of a lower-priority callout explicitly non-resolving, bind done/merged/numeric/continue replies to the specific recorded action they were offered against, require an externally observable verification where one exists, keep genuine halts firing when decorative cards are off, keep the L0 fast-path exemption free of mandatory overhead, and persist unresolved actions in the existing canonical record rather than a new ledger.`
- **In Scope**:
  - `docs/tasks/TASK-2026-10-05-pending-human-action-retention.md` (this record)
  - `templates/agent-directive-template.md` (one-line pre-response trigger)
  - `templates/agent-directive-lite-template.md` (one-line pre-response trigger)
  - `protocols/telemetry-cards.md` (Pre-Response Check section and its four sub-rules)
  - `templates/execution-task-record-template.md` (optional Pending Human Actions block)
  - `docs/BENCHMARKS.md` (re-measured static and per-task figures)
  - `README.md` (propagated static footprints)
  - `FAQ.md` (propagated static footprints)
  - `templates/lite-profile.md` (propagated static footprints)
  - `protocols/setup.md` (propagated static directive figure)
  - `scripts/tests/run-behavioral-contract-tests.sh` and `.ps1` (baseline column key already realigned; no change required in this issue)
  - `CHANGELOG.md` (record `[Unreleased]` entry)
- **Explicit Non-Goals**:
  - `No second action ledger and no storage of credentials, tokens, or secret values in any record.`
  - `No change to the Single-Callout Invariant, the Mandatory Reply Hint Contract, the Provenance Invariant, or callout precedence tiers; the new section reinforces them by name.`
  - `No static token budget raise; the directive addition was held inside the existing 2,500/1,500 tok budgets (99 and 162 tokens of headroom).`
  - `No claim that this prevents measured session drift or that any model conforms to it; the host cannot mechanically detect a missing callout.`
  - `No new human-callout example, and no rewording or renaming of any existing heading or pinned phrase; the diff is insertion-only.`
  - `No merge, tag, or release action (merge remains strictly human-only).`
- **Dependencies**: `Builds on the #526 recovery directive trigger (PR #531) for the compact-trigger pattern and on the #527/#528 canonical record fields. Behavioral evidence remains dependent on #525, which is unimplemented and excluded.`
- **Risk**: `Medium — the directive is on the static critical path for every task, so any growth consumes shared headroom and moves every published per-task payload figure.`
- **Verification Condition**: `Static budgets pass with Balanced <= 2,500 and Lite <= 1,500; behavioral contract suite passes 420/0; the pk:fix, pk:plan, and pk:ship per-task baselines still pass strict mode; all published static and per-task figures equal fresh measurement output in both Bash and PowerShell suites; reference validation, reference-link harness, release-record examples, profile matrix, token-budget regression, execution-control properties, playbook contracts, and math-label checks pass.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Root directive response behavior, the callout protocol, the canonical pending-action record fields, and all published static/per-task token figures.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-05-pending-human-action-retention; templates/agent-directive-template.md, templates/agent-directive-lite-template.md, protocols/telemetry-cards.md, templates/execution-task-record-template.md.`
- **Supporting Planning / Review Record**: `N/A — sourced directly from issue #529.`
- **User-Observable Before Behavior**: `Suppressing a lower-priority callout gave no way to distinguish "not shown now" from "handled", so an unresolved human action could be dropped by presentation alone. A bare done/merged/numeric/continue reply had no recorded action to bind to, so it could be read as blanket authorization. Detecting omitted formatting relied on the same agent noticing its omission.`
- **User-Observable After Behavior`: `Each turn begins with a five-question check of stop state, highest applicable callout, concrete action plus reply hint, retention of other unresolved actions, and TL;DR/provenance obligations. An action that was not shown stays recorded, unresolved, and unchanged until its recorded condition is actually met and, where observable, verified. A reply resolves only the action it was offered against and cannot authorize a commit, push, PR, release, deploy, rollback, scope change, or milestone crossing. Genuine halts still fire with cards off, and trivial replies gain no mandatory disk or tool overhead.`
- **Impact Classification**: `Documentation and Contract Clarification`
- **Proposed SemVer Candidate Impact**: `patch`
- **Impact Rationale`: `Adds a compact instruction and a protocol section with no runtime, schema, or validator change; the optional record block introduces no required field.`
- **Migration and Upgrade Guidance`: `N/A — existing records stay valid; the Pending Human Actions block is optional. Hosts must re-run the installer to receive the updated managed directive block.`
- **Maintenance Commit Declaration**: `N/A — intentional contract completion.`

## 4. Acceptance Criteria

- [x] **AC-1**: `Unresolved actions remain in the canonical record until the recorded condition is actually met — telemetry-cards.md "Resolution Requires the Recorded Condition" plus the record template's Pending Human Actions block and its Pending Action Retention line.`
- [x] **AC-2**: `Required stops include one appropriate callout, a concrete action, and a reply hint — pre-response checklist items 2 and 3, which reference the existing Single-Callout Invariant and Mandatory Reply Hint Contract.`
- [x] **AC-3**: `Lower-priority action suppression never loses or falsely resolves the action — "Suppression Is Not Resolution" states the action stays recorded, unresolved, and unchanged, and forbids implying the hidden actions were handled.`
- [x] **AC-4**: `Cards-off still communicates genuine stops and simple informational turns retain their exemption — "Cards-Off Still Communicates Genuine Halts" plus checklist item 5 and the L0 exemption in the directive trigger and "Honest Limits".`
- [x] **AC-5**: `Replies cannot authorize unrelated protected actions or bypass milestone boundaries — "Reply Interpretation Is Record-Bound" enumerates commit, push, PR, release, deploy, rollback, and scope change, and forbids crossing a milestone boundary or promoting a blocker into an approval.`
- [x] **AC-6**: `Recovery restores pending actions — the record block's Pending Action Retention line requires actions to survive compaction and handoff, consistent with the #526 recovery trigger that reads the canonical record.`
- [x] **AC-7**: `All verification gates pass and every published figure site equals fresh measurement output, with both directives still inside their existing budgets.`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `N/A — no external-harness continuation loop authorizes this change`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, compaction, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, static budget breach, scope expansion beyond the recorded In Scope boundary, missing approval for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically halt generation, detect a missing callout, or observe whether a reply satisfied a recorded condition; this is a stated discipline, not an enforced control.`
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
| N/A | planned | 2026-10-05 | Sisyphus | Task initialized from issue #529 source-backed response/recovery gap. | Issue #529 |
| planned | in_progress | 2026-10-05 | Sisyphus | Delegated the two directives and the callout protocol under a hard byte budget, then integrated the record block and figure propagation. | Local edits on branch fix/drift-527-530 |
| in_progress | awaiting_review | 2026-10-05 | Sisyphus | Directive triggers, protocol section, and record block in place inside budget; full gate suite green. | 420/420 behavioral contracts |
| awaiting_review | completed | 2026-10-05 | Sisyphus (executor) | PR #532 merged; post-merge commit, PR, CI, and review evidence recorded. | PR #532 / 4c858b0 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `templates/agent-directive-template.md`
  - `templates/agent-directive-lite-template.md`
  - `protocols/telemetry-cards.md`
  - `templates/execution-task-record-template.md`
  - `docs/tasks/TASK-2026-10-05-pending-human-action-retention.md`
  - `docs/BENCHMARKS.md`
  - `README.md`
  - `FAQ.md`
  - `templates/lite-profile.md`
  - `protocols/setup.md`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Behavioral contract suite 420 passed / 0 failed; execution control VALID (61 records); strict static budgets pass with Balanced 2,475/2,500 and Lite 1,411/1,500 with no budget constant raised; all six per-task baselines pass; validate-references, reference-link harness, release-record examples, profile matrix 10/10, token-budget regression 7/7, execution-control properties, playbook contracts, math labels, and git diff --check passed. Itemized commands are recorded below.`
  - `bash scripts/tests/run-behavioral-contract-tests.sh` passed (420 passed, 0 failed).
  - `bash scripts/measure-tokens.sh --strict` passed (BALANCED 2475/2500, LITE 1411/1500). The directive addition is 294 bytes each, consuming 74 and 73 tokens and leaving 25 and 89 tokens of headroom without raising any budget constant.
  - `bash scripts/measure-per-task-tokens.sh --strict` passed for all six payload gates.
  - `bash scripts/validate-execution-control.sh --root .` passed (VALID, 59 records).
  - `bash scripts/validate-references.sh .`, `run-reference-link-tests.sh` (6/6), `run-profile-matrix.sh` (10/10), `run-token-budget-tests.sh` (7/7), `run-execution-control-properties.sh`, `run-playbook-contract-tests.sh`, `release-records.examples.sh`, `check-math-labels.sh --root .`, and `git diff --check` passed.
  - Re-measured after the change: Balanced static directive 2,401 -> 2,475 tok (9,604 -> 9,898 bytes, 70 lines); Lite 1,338 -> 1,411 tok (5,350 -> 5,644 bytes, 55 lines); static reductions unchanged at 92% Balanced and 95% Lite; `pk:fix` 10,597 -> 10,671 and 9,534 -> 9,607 tok (-18%/-26% -> -17%/-25%); `pk:plan` 20,097 -> 20,171 and 19,034 -> 19,107 tok (-19% -> -18% Balanced); `pk:ship` 16,371 -> 16,445 and 15,308 -> 15,381 tok (percentages unchanged).
  - Diff to `protocols/telemetry-cards.md` is insertion-only: 32 lines added, 0 removed, so no pinned heading or contract phrase was reworded.
  - Not verified: PowerShell behavioral-contract parity cannot execute in this WSL environment (measurement tool exits 64, reproducing on a pristine worktree at `2fee6d7`); Windows CI is authoritative. No live host capture was performed, so no model-conformance result is claimed.
- Final merged measurement at `4c858b0`: core-six Lite subset **29,391 tok**, full 25-workflow set **111,086 tok**, Balanced **2,475/2,500**, Lite **1,411/1,500**, `pk:fix` **11,454** Balanced / **10,390** Lite — matching `docs/BENCHMARKS.md`. Earlier deltas above are that commit's incremental effect, not current state.
- **CI Evidence**: `PR #532 CI passed on 4c858b0 (Linux, Windows, and staged secret-scan jobs). The Windows job ran the PowerShell behavioral-contract variant, so the parity limitation recorded in Verification Evidence is resolved rather than outstanding.`
- **Review Evidence**: `Adversarial review of PR #532 returned APPROVE WITH CONDITIONS; its stale-body and disclosure findings were fixed in 28634fb and 97d5ffb and merged within #532.`
- **Commit Evidence**: `Squash-merged as 4c858b0 via PR #532; branch commits b8941e2 (#527), 8f9e2f7 (#528), 6a3d3e6 (#529), 86d4e24 (#530), 28634fb and 97d5ffb (review follow-ups).`
- **Pull Request Evidence**: `PR #532 (https://github.com/lowqualityloey/promptkit-os/pull/532), merged to main as 4c858b0.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `completed`
- **Acceptance Results**: `AC-1 through AC-7 verified against the local gate suite.`
- **Changed-File Summary**: `Add a compact pre-response check to both directives, make suppression non-resolving and replies record-bound in the callout protocol, persist pending actions in the canonical record, and re-propagate all measured figures.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `2026-10-05T04:38:00+13:00`
