# Task Record: Documentation truthfulness and claim integrity reconciliation

<a id="TASK-2026-10-02-doc-truthfulness-reconciliation"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-02-doc-truthfulness-reconciliation`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Reconcile claim integrity and documentation truthfulness across docs/INTERESTING-FACTS.md, FAQ.md, docs/WORKFLOW-MAP.md, docs/DESIGN-MD-FAQ.md, and workflows/api.md per docs/reviews/2026-10-02-doc-truthfulness-audit.md.`
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Antigravity (executor)`
- **Execution Scope**: `promptkit-os repository; overview docs, FAQs, workflow map, API workflow, benchmarks, and changelog`
- **Approval Boundary**: `User confirmed task. Branch push and PR creation authorized upon complete verification. Merge remains human-only.`
- **Created**: `2026-10-02`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Align documentation claims with actual controls, measured evidence, and Bounded Oracle standards by qualifying security absolutes (RLS, SameSite, DB isolation), anchoring benefit and cost statements to measured benchmarks, distinguishing installer configuration support from live-host runtime fidelity, correcting the lifecycle diagram flow and duration labels in the workflow map, clarifying DESIGN.md preservation guarantees, and establishing stack-neutral schema validation in workflows/api.md and docs/INTERESTING-FACTS.md.`
- **In Scope**:
  - `docs/tasks/TASK-2026-10-02-doc-truthfulness-reconciliation.md` (this record)
  - `docs/INTERESTING-FACTS.md` (qualify RLS, CSRF, UUIDv7, cursor pagination, Zod, artifact token usage, and assistant compatibility)
  - `FAQ.md` (qualify payback/payoff claims, model cost and savings assumptions, host compatibility, documentation requirements, directive size, DB isolation, and update version/date metadata)
  - `docs/WORKFLOW-MAP.md` (reorder lifecycle diagram to begin at pk:onboard, position pk:spike/ship/checkpoint accurately, label duration figures as illustrative estimates, and refresh release baseline reference)
  - `docs/DESIGN-MD-FAQ.md` (clarify installer detection guarantees vs UI workflow referencing)
  - `workflows/api.md` (generalize Zod mentions to stack-neutral validation schemas)
  - `docs/BENCHMARKS.md` (re-measured token payloads and reproducible diff hash)
  - `CHANGELOG.md` (record [Unreleased] entry)
- **Explicit Non-Goals**:
  - `No changes to installer code (init.sh / init.ps1) or runtime script logic.`
  - `No changes to ceremony classification levels or core quality gate protocols.`
  - `No merge, tag, or release action in this task (merge remains strictly human-only per protocols/code-quality-gate.md; branch push and PR creation authorized by user confirmation).`
- **Dependencies**: `User review and approval of the documentation truthfulness audit findings.`
- **Risk**: `Low — documentation and claim refinement improving truthfulness, eliminating over-promising language, and aligning docs with existing workflow requirements.`
- **Verification Condition**: `Bash behavioral contract tests pass; reference validation passes; execution control validation passes; strict token and per-task budget measurements pass; staged secret scan and changelog checks pass.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Documentation, FAQ, Workflow Map, and API workflow guidance.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-02-doc-truthfulness-reconciliation; docs/INTERESTING-FACTS.md, FAQ.md, docs/WORKFLOW-MAP.md, docs/DESIGN-MD-FAQ.md, workflows/api.md.`
- **Supporting Planning / Review Record**: `docs/reviews/2026-10-02-doc-truthfulness-audit.md.`
- **User-Observable Before Behavior**: `Overview documents contained absolute security claims (RLS cross-tenant impossible, SameSite prevents CSRF), unmeasured payback/token savings metrics, unqualified assistant compatibility assertions, and lifecycle diagrams misordering greenfield discovery and spike placement.`
- **User-Observable After Behavior**: `Documentation accurately describes defense-in-depth security, frames cost/benefit metrics with transparent assumptions, references measured benchmarks in BENCHMARKS.md, distinguishes installer support from untested live-host runtime fidelity, and illustrates workflow ordering accurately.`
- **Impact Classification**: `Documentation and Contract Clarification`
- **Proposed SemVer Candidate Impact**: `patch`
- **Impact Rationale**: `Improves claim integrity and documentation accuracy without breaking workflow triggers or protocol semantics.`
- **Migration and Upgrade Guidance**: `N/A - purely additive and corrective documentation refinements.`
- **Maintenance Commit Declaration**: `N/A - intentional claim reconciliation.`

## 4. Acceptance Criteria

- [x] **AC-1**: `docs/INTERESTING-FACTS.md replaces security absolutes with defense-in-depth controls (qualifying RLS superuser/owner bypass and CSRF multi-layer protection), qualifies artifact referencing token consumption, frames UUIDv7/cursor-pagination/Zod as context-appropriate choices, and qualifies assistant compatibility.`
- [x] **AC-2**: `FAQ.md labels payback/payoff and dollar figures as illustrative assumptions, anchors token discussions to docs/BENCHMARKS.md, qualifies host compatibility per HOST-CONFORMANCE.md, clarifies that pk:checkpoint persists docs/STATE.md, updates measured static directive sizing, qualifies DB isolation as instruction-level guardrails, and updates version metadata to v1.10.0.`
- [x] **AC-3**: `docs/WORKFLOW-MAP.md lifecycle diagram starts greenfield discovery at pk:onboard, positions pk:spike at planning/design uncertainty resolution, presents pk:ship and pk:checkpoint with accurate scope, marks duration figures as illustrative estimates, and updates release baseline text.`
- [x] **AC-4**: `docs/DESIGN-MD-FAQ.md separates installer zero-write preservation from UI workflow referencing without overpromising universal safety.`
- [x] **AC-5**: `workflows/api.md generalizes Zod schemas to stack-neutral validation schemas, aligning with templates/api-contract-spec.md.`
- [x] **AC-6**: `All repository verification gates (behavioral contracts, token budgets, reference validation, execution control, changelog entry) pass cleanly.`

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
- **Current Actor**: `Antigravity (executor)`
- **Branch / Revision**: `docs/reconcile-truthfulness-and-claim-integrity`
- **Next Action**: `Push branch docs/reconcile-truthfulness-and-claim-integrity, open PR, and await human review.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-02 | Antigravity | Task initialized upon user approval of documentation truthfulness audit. | User prompt |
| planned | in_progress | 2026-10-02 | Antigravity | Starting document edits and claim reconciliations. | Branch docs/reconcile-truthfulness-and-claim-integrity |
| in_progress | awaiting_review | 2026-10-02 | Antigravity | All document reconciliations completed and validated against behavioral contract suite, reference validator, execution control validator, token budget suites, and changelog gate. | Local test suite pass |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-10-02-doc-truthfulness-reconciliation.md`
  - `docs/INTERESTING-FACTS.md`
  - `FAQ.md`
  - `docs/WORKFLOW-MAP.md`
  - `docs/DESIGN-MD-FAQ.md`
  - `workflows/api.md`
  - `docs/BENCHMARKS.md`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**:
  - `bash scripts/tests/run-behavioral-contract-tests.sh` passed (394/394 passed).
  - `bash scripts/validate-references.sh .` passed (0 broken links).
  - `bash scripts/validate-execution-control.sh --root .` passed (VALID, 49 records).
  - `bash scripts/measure-tokens.sh --strict` passed (BALANCED 2318/2500, LITE 1274/1500).
  - `bash scripts/measure-per-task-tokens.sh --strict` passed (all baselines passed).
  - `bash scripts/check-changelog-entry.sh` passed.
- **CI Evidence**: `Pending branch push and PR creation.`
- **Review Evidence**: `Addresses docs/reviews/2026-10-02-doc-truthfulness-audit.md.`
- **Commit Evidence**: `Pending commit.`
- **Pull Request Evidence**: `Pending branch push.`
- **Release Evidence**: `N/A - no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `All acceptance criteria AC-1 through AC-6 verified.`
- **Changed-File Summary**: `Reconcile claim integrity and truthfulness across docs, FAQs, workflow map, benchmarks, and API workflow.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `2026-10-02T05:31:00+13:00`
