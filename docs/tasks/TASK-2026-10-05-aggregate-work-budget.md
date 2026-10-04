# Task Record: Total review and repair cycles bounded across long sessions

<a id="TASK-2026-10-05-aggregate-work-budget"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-05-aggregate-work-budget`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/530`
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; the canonical quality-gate aggregate budget rule, the pk:auto and pk:review references to it, the canonical Task Record budget block, and the published per-task payload figures the protocol growth moves`
- **Approval Boundary**: `Issue #530 authorizes the governance-bound repair. Merge remains human-only; no tag, release, publish, remote, deploy, or rollback action is authorized.`
- **Created**: `2026-10-05`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Establish a durable whole-task bound on repeated review and remediation work, so findings that recur after a green verification can no longer open a fresh unbounded cycle. Define a round, a configurable default limit, who may reset it, where the counters live, how they survive compaction, handoff, and detours, how evidence reuse stays honestly attributed, and what exhaustion must do — without weakening the existing consecutive-failure rule or inventing host enforcement.`
- **In Scope**:
  - `docs/tasks/TASK-2026-10-05-aggregate-work-budget.md` (this record)
  - `protocols/code-quality-gate.md` (Aggregate Round Budget, sibling to the Bounded Repair Rule)
  - `workflows/auto.md` (rail reference composing with the 3-strike breaker)
  - `workflows/review.md` (aggregate round accounting across all review lanes)
  - `templates/execution-task-record-template.md` (optional Aggregate Work Budget block)
  - `docs/BENCHMARKS.md` (re-measured full-set and per-task payload figures)
  - `CHANGELOG.md` (record `[Unreleased]` entry)
- **Explicit Non-Goals**:
  - `No change to the Bounded Repair Rule itself; the aggregate budget is a sibling that never replaces, relaxes, or lengthens the 2-repair / 3rd-consecutive-failure halt.`
  - `No change to the #258 autonomy budgets, the circuit-breaker rails, the subtask tool/time caps, or protocols/context-sync.md recovery ownership; these are referenced, not duplicated.`
  - `No root-directive change; Balanced had only 25 tokens and Lite 89 of static headroom, so the rule lives entirely in JIT-loaded protocols and workflows.`
  - `No claim of improved speed or reduced provider latency; the issue explicitly refuses that attribution.`
  - `No invented time, quota, or round counters; unavailable host data is reported as not measured.`
  - `No edits to historical records, and no merge, tag, or release action (merge remains strictly human-only).`
- **Dependencies**: `Composes with the existing Bounded Repair Rule and #258 autonomy governance. Behavioral evidence remains dependent on #525, which is unimplemented and excluded from this change.`
- **Risk**: `Medium — protocols/code-quality-gate.md loads into all three measured per-task payloads, so the canonical rule moves every published payload figure while all six baselines must keep passing.`
- **Verification Condition**: `Behavioral contract suite passes 420/0; all six per-task payload gates pass strict mode; static budgets pass unchanged; execution control validation reports VALID; reference validation, reference-link harness, release-record examples, profile matrix, token-budget regression, execution-control properties, playbook contracts, milestone-halt and authorization fixtures, and math-label checks all pass; both language variants of the contract suite agree on the re-measured figures.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Quality-gate governance for repeated work, the pk:auto hard-rail composition, pk:review round accounting, the canonical Task Record budget fields, and published per-task payload figures.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-05-aggregate-work-budget; protocols/code-quality-gate.md, workflows/auto.md, workflows/review.md, templates/execution-task-record-template.md.`
- **Supporting Planning / Review Record**: `N/A — sourced directly from issue #530.`
- **User-Observable Before Behavior**: `Only consecutive verification failures were capped. A reviewer could raise a new finding after every green check and consume unbounded rounds, because clearing the consecutive counter reset the only limit that existed. Read-only review work was exempt from the root search breaker, so repeated investigation was uncounted. Nothing recorded what a round was, who could change the limit, or what happened when a whole-task budget ran out.`
- **User-Observable After Behavior**: `A round is one full review, remediate, and re-verify cycle over the whole task. The default is 6 rounds, configurable by a human in the Task Record using their real time or quota constraints, and only a human may change or reset it; passing verification clears the consecutive-failure counter but never the total. Counters persist in existing control records and are restored rather than replenished after compaction, handoff, or a detour. Findings are consolidated before fixing, reused evidence keeps its original revision and coverage binding and is labeled historical, and exhaustion checkpoints the outstanding findings, names the required human action, and stops without weakening a test, skipping a gate, or marking incomplete work done.`
- **Impact Classification**: `Documentation and Contract Clarification`
- **Proposed SemVer Candidate Impact**: `patch`
- **Impact Rationale**: `Adds a governance rule composed with existing caps; no runtime, schema, validator-label, or budget-constant change, and the optional record block adds no required field.`
- **Migration and Upgrade Guidance**: `N/A — existing records stay valid; the Aggregate Work Budget block is optional.`
- **Maintenance Commit Declaration**: `N/A — intentional governance completion.`

## 4. Acceptance Criteria

- [x] **AC-1**: `Total-round semantics, default/configuration, reset authority, and stop behavior are documented consistently — canonically in protocols/code-quality-gate.md (round definition, 6-round configured default, human-only reset, exhaustion behavior) and referenced without divergent numbers by workflows/auto.md and workflows/review.md.`
- [x] **AC-2**: `Repeated new findings after green verification still consume the durable aggregate budget — the rule states that findings recurring after a green verification cannot open a fresh unbounded cycle, and passing verification never resets the total.`
- [x] **AC-3`: `Compaction, handoff, and debug detours cannot silently replenish the budget — durable counters live in existing control records and, per protocols/context-sync.md, are restored after compaction, session handoff, and bug detours; the canonical Task Record block repeats it.`
- [x] **AC-4`: `Exhaustion preserves incomplete status and pending findings without bypassing required gates — exhaustion checkpoints outstanding findings and evidence, states the required human action, stops, and cannot weaken a test, skip a mandatory gate, or convert incomplete work into done.`
- [x] **AC-5`: `Evidence reuse respects revision/coverage and current-turn telemetry provenance — reused evidence keeps its original revision and coverage binding, is labeled historical, and is never presented as a current-turn green result.`
- [x] **AC-6`: `Missing host counters or enforceability are explicit; no invented time/quota numbers — observed tool work and elapsed time are recorded only when the host exposes them, otherwise not measured, and host enforceability is stated as unavailable.`
- [x] **AC-7`: `Any performance claim requires comparable recorded measurements and provider latency is not attributed to kit policy — repeated-work counters are separated from tool/network/model latency and no speed improvement is claimed.`
- [x] **AC-8`: `All verification gates pass and every published per-task figure equals fresh measurement output in both language variants.`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `N/A — no external-harness continuation loop authorizes this change`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, compaction, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, per-task budget breach, scope expansion beyond the recorded In Scope boundary, missing approval for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically count rounds or force a stop; the aggregate budget is protocol discipline plus durable evidence, and a higher-priority host policy conflict must be surfaced rather than silently ignored.`
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
| N/A | planned | 2026-10-05 | Sisyphus | Task initialized from issue #530 source-backed aggregate-budget gap. | Issue #530 |
| planned | in_progress | 2026-10-05 | Sisyphus | Delegated the canonical rule plus the two referencing files, then integrated the record block and figure propagation. | Local edits on branch fix/drift-527-530 |
| in_progress | awaiting_review | 2026-10-05 | Sisyphus | Canonical rule, references, and record block in place; full gate suite green. | 420/420 behavioral contracts |
| awaiting_review | completed | 2026-10-05 | Sisyphus (executor) | PR #532 merged; post-merge commit, PR, CI, and review evidence recorded. | PR #532 / 4c858b0 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `protocols/code-quality-gate.md`
  - `workflows/auto.md`
  - `workflows/review.md`
  - `templates/execution-task-record-template.md`
  - `docs/tasks/TASK-2026-10-05-aggregate-work-budget.md`
  - `docs/BENCHMARKS.md`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Behavioral contract suite 420 passed / 0 failed; execution control VALID (61 records); all six per-task baselines pass in strict mode (pk:fix 11,454 / 10,390 against 12,861; pk:plan 20,954 / 19,890 against 24,666; pk:ship 17,228 / 16,164 against 24,761); static budgets unchanged at 2,475/2,500 and 1,411/1,500; Turbo overhead claim window 2.01x within 1.00-2.60x; reference validation, math labels, and git diff --check passed. Itemized commands are recorded below.`
  - `bash scripts/tests/run-behavioral-contract-tests.sh` passed (420 passed, 0 failed).
  - `bash scripts/measure-per-task-tokens.sh --strict` passed for all six payload gates: pk:fix 11,454 Balanced / 10,390 Lite against a 12,861 baseline; pk:plan 20,954 / 19,890 against 24,666; pk:ship 17,228 / 16,164 against 24,761.
  - `bash scripts/measure-tokens.sh --strict` passed unchanged (BALANCED 2475/2500, LITE 1411/1500); no directive or budget constant was touched.
  - `bash scripts/validate-execution-control.sh --root .` passed (VALID, 60 records).
  - `bash scripts/validate-references.sh .`, `run-reference-link-tests.sh`, `run-profile-matrix.sh`, `run-token-budget-tests.sh`, `run-execution-control-properties.sh`, `run-playbook-contract-tests.sh`, `run-milestone-halt-evidence-fixtures.sh`, `run-authorization-evidence-fixtures.sh`, `release-records.examples.sh`, `check-math-labels.sh --root .`, and `git diff --check` passed.
  - Diffs to the three contract files are insertion-only (8, 11, and 11 lines added; zero removed), so no pinned heading or phrase was reworded.
  - Re-measured after the change: full 25-workflow set 110,319 -> 111,086 tok; core-six unchanged at 29,391 tok because none of the six Lite-subset workflows were touched; per-task context-reduction cells updated to -11%/-19% (pk:fix), -15%/-19% (pk:plan), and -30%/-35% (pk:ship).
  - Not verified: PowerShell behavioral-contract parity cannot execute in this WSL environment (measurement tool exits 64, reproducing on a pristine worktree at `2fee6d7`); Windows CI is authoritative. No live host capture was performed, so no model-conformance result is claimed and no latency improvement is asserted.
- **CI Evidence**: `PR #532 CI passed on 4c858b0 (Linux, Windows, and staged secret-scan jobs). The Windows job ran the PowerShell behavioral-contract variant, so the parity limitation recorded in Verification Evidence is resolved rather than outstanding.`
- **Review Evidence**: `Adversarial review of PR #532 returned APPROVE WITH CONDITIONS; its stale-body and disclosure findings were fixed in 28634fb and 97d5ffb and merged within #532.`
- **Commit Evidence**: `Squash-merged as 4c858b0 via PR #532; branch commits b8941e2 (#527), 8f9e2f7 (#528), 6a3d3e6 (#529), 86d4e24 (#530), 28634fb and 97d5ffb (review follow-ups).`
- **Pull Request Evidence**: `PR #532 (https://github.com/lowqualityloey/promptkit-os/pull/532), merged to main as 4c858b0.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `completed`
- **Acceptance Results**: `AC-1 through AC-8 verified against the local gate suite.`
- **Changed-File Summary**: `Add a canonical aggregate round budget that composes with the bounded-repair rule, reference it from pk:auto and pk:review, persist it in the canonical Task Record, and re-propagate the measured per-task figures.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `2026-10-05T05:12:00+13:00`
