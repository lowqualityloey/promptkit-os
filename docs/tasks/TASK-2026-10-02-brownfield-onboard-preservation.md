# Task Record: Brownfield onboarding profile preservation and command truthfulness

<a id="TASK-2026-10-02-brownfield-onboard-preservation"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-02-brownfield-onboard-preservation`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Strengthen brownfield onboarding in workflows/onboard.md: preserve existing PROMPTKIT.md and DESIGN.md human rules and invariants, and accurately label extracted commands as discovered/unverified until executed under a quality gate.`
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Antigravity (executor)`
- **Execution Scope**: `promptkit-os repository; onboarding workflow, contract tests, benchmarks, and changelog`
- **Approval Boundary**: `User confirmed task. Branch push and PR creation authorized upon complete verification. Merge remains human-only.`
- **Created**: `2026-10-02`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Eliminate profile overwrite risks during brownfield onboarding by requiring explicit preservation of existing user-written rules and invariants in PROMPTKIT.md and DESIGN.md, and enforce evidence truthfulness by labeling extracted project commands as discovered/unverified until physically executed under a quality gate.`
- **In Scope**:
  - `docs/tasks/TASK-2026-10-02-brownfield-onboard-preservation.md` (this record)
  - `workflows/onboard.md` (Phase 1 command extraction, Phase 3 preservation rules, and Completion Criteria)
  - `docs/BENCHMARKS.md` (re-measured token payloads and reproducible diff hash)
  - `scripts/tests/run-behavioral-contract-tests.sh` (Scenario N assertions)
  - `scripts/tests/run-behavioral-contract-tests.ps1` (Scenario N assertions)
  - `CHANGELOG.md` (record [Unreleased] entry)
- **Explicit Non-Goals**:
  - `No changes to consumer applications or runtime code.`
  - `No merge, tag, or release action in this task (merge remains strictly human-only per protocols/code-quality-gate.md; branch push and PR creation were authorized by user confirmation).`
- **Dependencies**: `User review and approval of brownfield onboarding risks.`
- **Risk**: `Low — workflow documentation refinement safeguarding existing project profiles and aligning command claims with Bounded Oracle principles.`
- **Verification Condition**: `Bash behavioral contract tests pass with new assertions; dual-OS Bash and PowerShell syntax checks pass; strict token and per-task budget measurements pass; execution control validation passes; reference validation passes; staged secret and changelog gates pass.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Onboarding protocol in workflows/onboard.md.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-02-brownfield-onboard-preservation; workflows/onboard.md.`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-10-02-brownfield-onboard-preservation.md (this record).`
- **User-Observable Before Behavior**: `Onboarding Phase 3 directed unconditional template copy to PROMPTKIT.md risking loss of existing rules; completion criteria claimed commands were working despite passive non-execution.`
- **User-Observable After Behavior**: `Onboarding explicitly updates detected fields while preserving existing human-written rules and invariants in PROMPTKIT.md and DESIGN.md; extracted commands are truthfully labeled as discovered and unverified until executed under a quality gate.`
- **Impact Classification**: `User-Facing Additive Contract Change`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `Prevents accidental loss of user configurations and aligns onboarding claims with truthfulness standards.`
- **Migration and Upgrade Guidance**: `N/A - additive safe guidance.`
- **Maintenance Commit Declaration**: `N/A - intentional contract improvement.`

## 4. Acceptance Criteria

- [x] **AC-1**: `workflows/onboard.md Phase 1 Step 3 specifies that extracted commands are discovered and mapped (unverified until executed under a quality gate).`
- [x] **AC-2**: `workflows/onboard.md Phase 3 Step 2 specifies that existing PROMPTKIT.md files have detected fields updated while strictly preserving all existing human-written rules, invariants, and overrides.`
- [x] **AC-3**: `workflows/onboard.md Phase 3 Step 3 specifies that existing DESIGN.md files are preserved rather than overwritten.`
- [x] **AC-4**: `workflows/onboard.md Completion Criteria replaces "working project commands" with truthful discovered/unverified phrasing.`
- [x] **AC-5**: `Behavioral contract tests in both Bash and PowerShell assert the profile preservation and unverified command labeling.`
- [x] **AC-6**: `All repository verification gates (behavioral contracts, strict token budgets, reference integrity, execution control, changelog entry) pass cleanly.`

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
- **Branch / Revision**: `feat/brownfield-onboard-preservation-and-truthfulness`
- **Next Action**: `Maintainer review and squash-merge of PR #497 into main.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-02 | Antigravity | Task initialized upon user approval of ChatGPT review finding. | User prompt |
| planned | in_progress | 2026-10-02 | Antigravity | Starting implementation of brownfield preservation and truthfulness rules. | Branch feat/brownfield-onboard-preservation-and-truthfulness |
| in_progress | awaiting_review | 2026-10-02 | Antigravity | Implementation complete, contract tests passing (391/391), token benchmarks updated, all gates passing. | Verification evidence in Section 6 |
| awaiting_review | in_progress | 2026-10-02 | Antigravity | Addressing PR #497 review findings: intake preservation conflict, DESIGN.md contract assertions, task record reconciliation. | docs/reviews/pr-497.md |
| in_progress | awaiting_review | 2026-10-02 | Antigravity | Reconciled onboarding contract, added contract assertions, updated task record and benchmarks, ready for maintainer squash-merge. | Verification evidence in Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-10-02-brownfield-onboard-preservation.md`
  - `workflows/onboard.md`
  - `docs/BENCHMARKS.md`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Bash behavioral contract tests 394/394 PASS; strict token budget PASS (Balanced 2318/2500, Lite 1274/1500); strict per-task measurements PASS (fix 9094/12861, plan 19299/24666, ship 15555/24761); reference validation PASS across 316 Markdown files; execution control validation VALID across 48 records; staged secret scan PASS.`
- **CI Evidence**: `GitHub Actions run 36885299400 on PR #497: Lint & Validate (Linux) PASS in 3m37s; Lint & Validate (Windows) PASS in 4m48s at commit feea276; follow-up verification pending.`
- **Review Evidence**: `Addresses ChatGPT review findings in docs/reviews/pr-497.md: eliminated brownfield intake overwrite conflict by preserving confirmed size/intake-status and giving human overrides precedence; added DESIGN.md and confirmed-intake contract test assertions; reconciled task record commit, PR, and CI evidence.`
- **Commit Evidence**: `Branch commit feea276, plus follow-up review-reconciliation commit on feat/brownfield-onboard-preservation-and-truthfulness.`
- **Pull Request Evidence**: `Pull Request #497 (https://github.com/lowqualityloey/promptkit-os/pull/497) targeting main; initial CI checks passed.`
- **Release Evidence**: `N/A - no release action in scope.`
- **Blocker and Resume Condition**: `No implementation blocker. Awaiting maintainer review and squash-merge.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass; AC-5 Pass; AC-6 Pass.`
- **Changed-File Summary**: `Tighten brownfield onboarding preservation and command truthfulness across onboard workflow, contract tests, benchmarks, and changelog; reconcile task record and intake preservation instructions.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `All implementation criteria and review findings satisfied on 2026-10-02; ready for maintainer squash-merge.`
