# Task Record: Tighten pk:grill to pk:plan handoff contract

<a id="TASK-2026-10-02-grill-plan-handoff"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-02-grill-plan-handoff`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Tighten pk:grill to pk:plan handoff: require material architectural gaps discovered during pre-implementation grilling to be recorded with an explicit disposition in the tech spec before planning sign-off.`
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Antigravity (executor)`
- **Execution Scope**: `promptkit-os repository; workflow contracts, templates, and behavioral tests`
- **Approval Boundary**: `The user confirmed this task. Branch push and PR creation authorized upon complete verification. Merge remains human-only.`
- **Created**: `2026-10-02`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Tighten the handoff between pk:grill and pk:plan so that material architectural gaps uncovered during pre-implementation grilling cannot be lost in an auxiliary progress journal while a plan is marked ready, requiring every material gap to have an explicit disposition in the specification before sign-off.`
- **In Scope**:
  - `docs/tasks/TASK-2026-10-02-grill-plan-handoff.md` (this record)
  - `templates/tech-spec-template.md` (strengthen Sign-off & Grilling Checklist)
  - `workflows/tutor.md` (clarify Grill Completion Contract during pk:plan)
  - `workflows/plan.md` (Step 6 and Completion Criteria integration)
  - `docs/BENCHMARKS.md` (refresh token payload measurements and input provenance)
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `CHANGELOG.md` (record [Unreleased] entry)
- **Explicit Non-Goals**:
  - `No changes to consumer applications or runtime code.`
  - `No merge, tag, or release action in this task (merge remains strictly human-only per protocols/code-quality-gate.md; branch push and PR creation were authorized by user confirmation).`
- **Dependencies**: `User review and approval to tighten the planning-to-task boundary.`
- **Risk**: `Low — documentation and contract refinement strengthening existing pre-implementation grilling rules without breaking changes.`
- **Verification Condition**: `Bash behavioral contract tests pass with new assertions; dual-OS Bash and PowerShell syntax checks pass; strict token and per-task budget measurements pass; execution control validation passes; reference validation passes; staged secret and changelog gates pass.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Pre-implementation grilling requirements in workflows/tutor.md, workflows/plan.md, and templates/tech-spec-template.md.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-02-grill-plan-handoff; templates/tech-spec-template.md.`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-10-02-grill-plan-handoff.md (this record).`
- **User-Observable Before Behavior**: `Planning sign-off only asked if architecture was challenged via pk:grill, allowing material gaps to remain stranded as unresolved questions in a progress journal.`
- **User-Observable After Behavior**: `Planning sign-off explicitly verifies that all material design gaps discovered during pk:grill carry an explicit disposition (resolved in spec, logged as an approved non-goal, or recorded as a bounded assumption) before reaching sign-off readiness.`
- **Impact Classification**: `User-Facing Additive Contract Change`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `Hardens the planning quality gate against design oversights before task creation without breaking existing workflows.`
- **Migration and Upgrade Guidance**: `N/A - additive guidance.`
- **Maintenance Commit Declaration**: `N/A - intentional contract improvement.`

## 4. Acceptance Criteria

- [x] **AC-1**: `templates/tech-spec-template.md Sign-off & Grilling checklist requires all material design gaps to have an explicit disposition (resolved, non-goal, or bounded assumption).` Result: `Pass.`
- [x] **AC-2**: `workflows/tutor.md Grill Completion Contract specifies that pre-implementation grilling during pk:plan must feed material gaps into the spec/planning record rather than leaving them in a learning journal.` Result: `Pass.`
- [x] **AC-3**: `workflows/plan.md Step 6 and Completion Criteria reflect this required reconciliation before sign-off readiness.` Result: `Pass.`
- [x] **AC-4**: `Behavioral contract tests in both Bash and PowerShell assert the strengthened grill-to-plan handoff.` Result: `Pass; Scenario AK passes across 387 assertions.`
- [x] **AC-5**: `All repository verification gates (behavioral contracts, strict token budgets, reference integrity, execution control, changelog entry) pass cleanly.` Result: `Pass; verified locally.`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, compaction, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion, missing approval for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically enforce checkpoint deadlines; timing remains a manual protocol limitation.`
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-02`
- **Current Actor**: `PromptKit maintainer (review/approval) + Antigravity (handoff)`
- **Branch / Revision**: `feat/tighten-grill-plan-handoff`
- **Next Action**: `Push branch and create Pull Request.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-02 | Antigravity | Task initialized upon user approval of ChatGPT review finding. | User prompt |
| planned | in_progress | 2026-10-02 | Antigravity | Starting implementation of handoff contract in templates and workflows. | Branch feat/tighten-grill-plan-handoff |
| in_progress | awaiting_review | 2026-10-02 | Antigravity | All changes implemented, contract tests passing (387/387), token benchmarks updated and verified, ready for review. | Verification evidence in Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-10-02-grill-plan-handoff.md`
  - `templates/tech-spec-template.md`
  - `workflows/tutor.md`
  - `workflows/plan.md`
  - `docs/BENCHMARKS.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Bash behavioral contract tests 387/387 PASS; strict token budget PASS (Balanced 2318/2500, Lite 1274/1500); strict per-task measurements PASS (fix 9094/12861, plan 19296/24666, ship 15555/24761); reference validation PASS across 316 Markdown files; execution control validation VALID across 47 records; staged secret scan PASS.`
- **CI Evidence**: `Pending branch push and PR creation.`
- **Review Evidence**: `Addresses P2 finding in ChatGPT review of greenfield planning handoffs by tightening pk:grill to pk:plan contract.`
- **Commit Evidence**: `Pending commit.`
- **Pull Request Evidence**: `Branch feat/tighten-grill-plan-handoff ready for push and PR creation targeting main.`
- **Release Evidence**: `N/A - no release action in scope.`
- **Blocker and Resume Condition**: `No implementation blocker. Ready for branch push and PR creation.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass; AC-5 Pass.`
- **Changed-File Summary**: `Tighten pk:grill to pk:plan handoff across template, tutor, plan workflows, contract tests, benchmarks, and changelog.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `All implementation criteria satisfied on 2026-10-02; ready for PR creation.`
