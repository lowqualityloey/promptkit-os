# Task Record: Directive headroom and executed-evidence milestone gate (issue #788)

<a id="TASK-2026-11-26-issue-788-directive-headroom"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-26-issue-788-directive-headroom`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Restore real tokenizer headroom under the published directive caps without raising them: trim unpinned prose out of both agent directives (Balanced 2,488 -> 2,404 proxy tokens, Lite 1,482 -> 1,415) so both clear 2,500/1,500 in cl100k_base and o200k_base; tighten the bytes/4 ceilings to 2,425/1,450 and add an optional --strict real-tokenizer gate; forbid honoring a milestone sign-off or resume reply whose closing milestone has no executed exit-0 verification evidence, pinned in both contract twins; require confirming an unfamiliar PROMPTKIT.md Section 3 command with the operator before first execution in a newly cloned repo; compact the docs/BENCHMARKS.md banner below 600 bytes with the historical anchors preserved in a structured table; re-propagate every dependent figure.`
- **External Reference (Optional)**: `GitHub issue #788`
- **Owner / Actor**: `Release Coordinator (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; templates/agent-directive-template.md, templates/agent-directive-lite-template.md, scripts/measure-tokens.sh, scripts/measure-tokens.ps1, scripts/measure-tokenizer-delta.sh, scripts/measure-tokenizer-delta.ps1, scripts/tests/run-behavioral-contract-tests.sh, scripts/tests/run-behavioral-contract-tests.ps1, protocols/context-sync.md, protocols/setup.md, README.md, FAQ.md, templates/lite-profile.md, docs/BENCHMARKS.md, CHANGELOG.md, and this record. Local implementation and verification, then one implementation commit and one documentation-only provenance commit on a dedicated branch.`
- **Approval Boundary**: `Local implementation, verification, and commits on a dedicated branch only. Push, PR, merge, force-push, squash/rebase/amend, tag, release, and issue closure remain unauthorized.`
- **Created**: `2026-11-26`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Make the directive token gates bound real tokenizer counts for both published caps, and make the milestone sign-off gate require executed evidence rather than an assertion.`
- **In Scope**:
  - `templates/agent-directive-template.md` (unpinned-prose trims plus the executed-evidence milestone clause)
  - `templates/agent-directive-lite-template.md` (unpinned-prose trims plus the executed-evidence milestone clause)
  - `scripts/measure-tokens.sh` (proxy ceiling 2,425 and the rationale comment)
  - `scripts/measure-tokens.ps1` (proxy ceiling 2,425 and the rationale comment)
  - `scripts/measure-tokenizer-delta.sh` (`--strict` mode; offline `SKIPPED` exit 0 preserved)
  - `scripts/measure-tokenizer-delta.ps1` (`--strict` mode; offline `SKIPPED` exit 0 preserved)
  - `scripts/tests/run-behavioral-contract-tests.sh` (two new milestone-evidence assertions)
  - `scripts/tests/run-behavioral-contract-tests.ps1` (two new milestone-evidence assertions)
  - `scripts/tests/run-token-budget-tests.ps1` (derive the Balanced cap from the measure script instead of a literal)
  - `protocols/context-sync.md` (section 1 and section 3.3 first-run command-review guidance)
  - `protocols/setup.md` (guard-required numeric refresh of the Balanced figure)
  - `README.md` (two numeric/claim refreshes)
  - `FAQ.md` (two numeric refreshes)
  - `templates/lite-profile.md` (two numeric refreshes)
  - `docs/BENCHMARKS.md` (banner compaction, new section 11 provenance tables, re-propagated figures)
  - `CHANGELOG.md` (one `[Unreleased]` bullet)
  - `docs/tasks/TASK-2026-11-26-issue-788-directive-headroom.md` (this record)
- **Explicit Non-Goals**:
  - `No raise of the published 2,500/1,500 caps, and no new CI dependency on tiktoken or the network.`
  - `No contract-pinned sentence is rewritten or deleted; every pre-existing assertion still passes unchanged.`
  - `No change to workflow routing, protocol content outside context-sync.md, template inventories, install behaviour, or release tooling.`
  - `No edit to scripts/measure-per-task-tokens.*, package/, init.*, .github/workflows/, or the protocols other than context-sync.md.`
- **Dependencies**: `Lands after #787 (the last content change to the measured directive templates) and before any later directive work; the branch is forked from 2698040.`
- **Risk**: `Medium - both directives are measured inputs, so the trims move every published per-task, turbo, and tokenizer figure; a trim that reaches a contract-pinned sentence would fail the behavioral gate.`
- **Verification Condition**: `bash scripts/measure-tokens.sh --strict reports BALANCED|2404|2425|PASS and LITE|1415|1450|PASS; bash scripts/measure-tokenizer-delta.sh --strict reports all four real-encoding rows PASS; both behavioral-contract twins pass with the two new assertions and no deleted assertion; both validate-references twins exit 0; the changelog gate passes; git diff --check is clean; the banner provenance guard passes after the documentation-only restatement commit.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `The published static directive figures and their budgets, the milestone sign-off gate in both directives, and the untrusted-content guidance for a committed PROMPTKIT.md command block.`
- **Contract Impact Evidence ID / Path**: `templates/agent-directive-template.md, templates/agent-directive-lite-template.md, scripts/measure-tokens.sh, scripts/measure-tokenizer-delta.sh, scripts/tests/run-behavioral-contract-tests.sh, protocols/context-sync.md, docs/BENCHMARKS.md.`
- **Supporting Planning / Review Record**: `This record; GitHub issue #788; ADR docs/adrs/0001-static-token-headroom.md.`
- **User-Observable Before Behavior**: `Both directives passed the bytes/4 gate while the Lite directive measured 1,529 cl100k_base tokens against a 1,500 cap; the Balanced directive cleared its cap by 3 real tokens. A milestone sign-off or resume reply was accepted even when the closing milestone carried no executed verification evidence.`
- **User-Observable After Behavior**: `Balanced measures 2,404 proxy / 2,411 cl100k_base / 2,401 o200k_base and Lite 1,415 / 1,449 / 1,448, so both clear 2,500/1,500 in both encodings; the proxy ceilings are 2,425/1,450 and --strict fails a real-encoding breach. A sign-off or resume reply is void unless the closing milestone recorded executed exit-0 verification evidence.`
- **Impact Classification**: `User-Facing Instruction Change`
- **Proposed SemVer Candidate Impact**: `patch`
- **Impact Rationale**: `The caps, triggers, workflow routing, and install steps are unchanged; the trim removes redundant prose, and the two new rules only tighten a gate that already required sign-off.`
- **Migration and Upgrade Guidance**: `N/A - an existing install receives the trimmed directives on re-injection; no project-side migration is required.`
- **Maintenance Commit Declaration**: `N/A - an intentional correction of a gate that measured the wrong quantity, not debt.`

## 4. Acceptance Criteria

- [x] **AC-1**: `bash scripts/measure-tokens.sh --strict passes offline at the 2,425/1,450 ceilings, and bash scripts/measure-tokenizer-delta.sh --strict reports Balanced below 2,500 and Lite below 1,500 for both cl100k_base and o200k_base (2,411/2,401 and 1,449/1,448).`
- [x] **AC-2**: `Both directives forbid honoring a milestone sign-off or resume reply when the closing milestone lacks executed exit-0 verification evidence, and each contract twin adds assertions pinning the clause without deleting or weakening an existing assertion.`
- [x] **AC-3**: `protocols/context-sync.md directs agents to confirm an unfamiliar PROMPTKIT.md Section 3 shell command with the operator before its first execution in a newly cloned repository.`
- [x] **AC-4**: `The docs/BENCHMARKS.md banner is at or below 600 bytes with its parseable Current measurements anchor shape intact, historical anchors are auditable in the new structured section 11 table, and the provenance-anchor guard passes in both twins.`

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
- **Current Actor**: `Sisyphus`
- **Next Action**: `Commit the implementation with the figure updates, then land the documentation-only provenance restatement; merge remains unauthorized.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-11-26 | Sisyphus | Task initialized from the coordinator authorization for issue #788. | Coordinator brief |
| planned | in_progress | 2026-11-26 | Sisyphus | Measured the baseline in both encodings, trimmed both directives, tightened the ceilings, added --strict, and added the milestone-evidence clause. | Section 6 |
| in_progress | awaiting_review | 2026-11-26 | Sisyphus | Both contract twins, both validate-references twins, and every measurement gate are green; publication awaits the two commits. | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `templates/agent-directive-template.md`
  - `templates/agent-directive-lite-template.md`
  - `scripts/measure-tokens.sh`
  - `scripts/measure-tokens.ps1`
  - `scripts/measure-tokenizer-delta.sh`
  - `scripts/measure-tokenizer-delta.ps1`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `scripts/tests/run-token-budget-tests.ps1`
  - `protocols/context-sync.md`
  - `protocols/setup.md`
  - `README.md`
  - `FAQ.md`
  - `templates/lite-profile.md`
  - `docs/BENCHMARKS.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-26-issue-788-directive-headroom.md`
- **Scope Change Records**: `Coordinator ruling authorized the numeric-only refresh in protocols/setup.md (guard-required) and the five claim/number edits in README.md (two), FAQ.md, and templates/lite-profile.md (two), because the branch disproves the old only Balanced clears both conventions claim.`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Baseline before the trim: BALANCED|2488|2500|PASS, LITE|1482|1500|PASS; tokenizer rows Balanced 2,488/2,497/2,485 and Lite 1,482/1,529/1,524, so Lite was 29 over its cap in cl100k_base. After the trim: BALANCED|2404|2425|PASS, LITE|1415|1450|PASS; TOKENIZER|BALANCED|cl100k_base|2411|2500|PASS, BALANCED|o200k_base|2401|2500|PASS, LITE|cl100k_base|1449|1500|PASS, LITE|o200k_base|1448|1500|PASS; per-task BASELINE rows 11,391/10,402, 20,880/19,891, 17,224/16,235 against 12,861/24,666/24,761; turbo plan 23,534-42,010 (1.13x-2.01x) and ship 19,878-34,698 (1.15x-2.01x), both claim-window rows PASS; bash behavioral contract Passed: 793 | Failed: 0 and the PowerShell twin Passed: 782 | Failed: 0. Byte counts: Balanced 9,953 -> 9,616 and Lite 5,929 -> 5,658; Lite lines 57 -> 53. The trim removed 84 proxy tokens from Balanced and 67 from Lite, all unpinned prose (redundant recitals, duplicated protocol pointers, verbose trigger descriptions), with every contract-pinned sentence verified present by the existing assertions. The PowerShell token-budget regression twin still pinned the pre-trim literal 2,500 in its strict-gate assertion, so tightening the ceiling left it red on CI run 45738515241 (Passed: 7 | Failed: 1 in Run Token Budget Gate Regression Tests (PowerShell)); it now derives the Balanced cap from `$TokenBudgetBalanced` in scripts/measure-tokens.ps1 and fails closed to UNPARSED if the declaration is missing, and the suite reports Passed: 8 | Failed: 0 locally.`
- **CI Evidence**: `Pending - the branch is not pushed; every gate above ran locally on the worktree, including the PowerShell contract twin.`
- **Review Evidence**: `Local gates only; no independent review requested.`
- **Commit Evidence**: `Two commits planned on fix/788-directive-headroom: the implementation commit carrying every file and figure, then a documentation-only commit that restates the docs/BENCHMARKS.md banner anchor to the implementation SHA and adds its provenance-table row, because a commit cannot contain its own SHA.`
- **Pull Request Evidence**: `Pending.`
- **Release Evidence**: `N/A - no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass.`
- **Changed-File Summary**: `Trim unpinned prose out of both directives until both clear their real-token caps, set the proxy ceilings below the caps, add an optional real-tokenizer gate, make the milestone sign-off depend on executed verification evidence, require first-run confirmation of an unfamiliar committed command, compact the benchmark banner into a structured provenance table, and point the PowerShell token-budget regression twin at the declared cap instead of a literal.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `Acceptance criteria pass on the local gates; the implementation and provenance commits remain to be created - 2026-11-26.`
