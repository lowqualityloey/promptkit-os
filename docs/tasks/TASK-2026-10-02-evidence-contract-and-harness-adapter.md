# Task Record: Standardized Verification Evidence Contract, Runtime Harness Adapter Positioning, and Tiered Cognition

<a id="TASK-2026-10-02-evidence-contract-and-harness-adapter"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-02-evidence-contract-and-harness-adapter`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Resolve Issue #505 by standardizing a machine-verifiable Verification Evidence Block schema in protocols/code-quality-gate.md and task templates, adding mechanical parser validation in scripts/validate-execution-control.sh (.ps1), defining the 3-Layer Model (Policy, Harness, Execution) and Runtime Harness Adapter pattern in docs/ARCHITECTURE.md, and documenting Tiered Model Specialization in protocols/subagent-delegation.md.`
- **External Reference (Optional)**: `Issue #505 (https://github.com/lowqualityloey/promptkit-os/issues/505)`
- **Owner / Actor**: `PromptKit maintainer (approver) + Antigravity (executor)`
- **Execution Scope**: `promptkit-os repository; protocols/code-quality-gate.md, templates/execution-task-record-template.md, templates/issue-task-template.md, scripts/validate-execution-control.sh, scripts/validate-execution-control.ps1, docs/ARCHITECTURE.md, protocols/subagent-delegation.md, docs/tasks/TASK-2026-10-02-evidence-contract-and-harness-adapter.md, CHANGELOG.md`
- **Approval Boundary**: `User confirmed task. Branch push and PR creation authorized upon complete verification. Merge remains human-only.`
- **Created**: `2026-10-02`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Elevate PromptKit OS's architectural interface without adding runtime dependencies: (1) Standardize a structured, machine-verifiable Verification Evidence Block contract ('evidence:verification' schema) so hosts, external runtimes (OmO, Sureflow), and pre-commit/CI harnesses can emit tamper-evident verification proof. (2) Update execution-control validators to validate structured evidence blocks when present. (3) Formally document the 3-Layer Architecture (Policy, Harness, Execution) and the Runtime Harness Adapter pattern in docs/ARCHITECTURE.md, crystalizing PromptKit OS as the universal engineering policy layer. (4) Standardize Tiered Model Specialization (fast/cheap triage vs. frontier reasoning) in protocols/subagent-delegation.md.`
- **In Scope**:
  - `protocols/code-quality-gate.md` (Verification Evidence Block schema definition)
  - `templates/execution-task-record-template.md` (structured verification evidence template slot)
  - `templates/issue-task-template.md` (structured verification evidence template slot)
  - `scripts/validate-execution-control.sh` (mechanical validation of structured evidence blocks)
  - `scripts/validate-execution-control.ps1` (PowerShell parity for structured evidence block validation)
  - `docs/ARCHITECTURE.md` (3-Layer Model and Runtime Harness Adapter specification)
  - `protocols/subagent-delegation.md` (Tiered Model Specialization & Lightweight Cognition section)
  - `docs/BENCHMARKS.md` (refreshed per-task measurements and digest)
  - `docs/tasks/TASK-2026-10-02-evidence-contract-and-harness-adapter.md` (this task record)
  - `CHANGELOG.md` (record entry under [Unreleased])
- **Explicit Non-Goals**:
  - `No runtime daemons, background process managers, tmux runners, or model API routers added to PromptKit OS.`
  - `No breaking changes to existing legacy task records (unstructured prose remains supported).`
  - `No changes to static directive token budgets.`
  - `No automated merge or tagging actions (human retains merge authority).`
- **Dependencies**: `Issue #505 discussion and architectural comparison review.`
- **Risk**: `Low — purely additive architectural clarity, template refinement, and non-breaking validator enhancement preserving backward compatibility.`
- **Verification Condition**: `Behavioral contract tests pass (394/394); reference validation passes (0 broken links); token budget gates pass; execution control passes; staged secret scan passes; changelog check passes.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Quality Gate protocol (verification evidence contract), Architecture specification (3-Layer Model and Harness Adapter), Subagent Delegation protocol (tiered cognition guidelines), Task Record templates.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-02-evidence-contract-and-harness-adapter; protocols/code-quality-gate.md, docs/ARCHITECTURE.md, protocols/subagent-delegation.md.`
- **Supporting Planning / Review Record**: `Issue #505; docs/tasks/TASK-2026-10-02-evidence-contract-and-harness-adapter.md.`
- **User-Observable Before Behavior**: `Verification evidence was entirely freeform unstructured text; architectural documentation did not explicitly formalize the 3-Layer Model distinguishing PromptKit from agent runtimes; subagent delegation lacked explicit tiered model guidance.`
- **User-Observable After Behavior**: `Hosts and runtimes can emit structured, machine-checkable 'evidence:verification' blocks validated by CI; ARCHITECTURE.md cleanly positions PromptKit as the policy plane above agent runtimes; subagent delegation defines tiered model specialization to preserve tokens.`
- **Impact Classification**: `Workflow & Protocol Contract Enhancement`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `Improves verification determinism and architectural positioning without breaking backward compatibility or adding runtime bloat.`
- **Migration and Upgrade Guidance**: `N/A - structured evidence blocks are backward-compatible with freeform evidence strings. Existing task records continue to pass.`
- **Maintenance Commit Declaration**: `N/A`

## 4. Acceptance Criteria

- [x] **AC-1**: `protocols/code-quality-gate.md defines the canonical Verification Evidence Block schema ('evidence:verification') with fields for status, exit_code, checks_passed, checks_failed, suite, diff_digest, and timestamp.`
- [x] **AC-2**: `templates/execution-task-record-template.md and templates/issue-task-template.md document the structured Verification Evidence Block format.`
- [x] **AC-3**: `scripts/validate-execution-control.sh and scripts/validate-execution-control.ps1 validate that when a task record contains an 'evidence:verification' block, status is PASS and exit_code is 0.`
- [x] **AC-4**: `docs/ARCHITECTURE.md defines the 3-Layer Architecture (Policy, Harness, Execution) and provides the Runtime Harness Adapter specification for integrating runtimes like OmO, Claude Code, Cursor, and Sureflow.`
- [x] **AC-5**: `protocols/subagent-delegation.md standardizes Tiered Model Specialization (Tier 1 fast/cheap triage vs. Tier 2 frontier reasoning).`
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
- **Branch / Revision**: `feat/issue-505-evidence-contract-and-harness-adapter`
- **Next Action**: `Create PR for Issue #505 and await human review/merge.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-02 | Antigravity | Task initialized upon user approval of Issue #505. | Issue #505 |
| planned | in_progress | 2026-10-02 | Antigravity | Starting protocol, template, validator, and architecture documentation updates. | Branch feat/issue-505-evidence-contract-and-harness-adapter |
| in_progress | awaiting_review | 2026-10-02 | Antigravity | Implementation complete; full verification battery green. | Local battery run |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `protocols/code-quality-gate.md`
  - `templates/execution-task-record-template.md`
  - `templates/issue-task-template.md`
  - `scripts/validate-execution-control.sh`
  - `scripts/validate-execution-control.ps1`
  - `docs/ARCHITECTURE.md`
  - `protocols/subagent-delegation.md`
  - `docs/BENCHMARKS.md`
  - `docs/tasks/TASK-2026-10-02-evidence-contract-and-harness-adapter.md`
  - `CHANGELOG.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**:
  ```evidence:verification
  status: PASS
  exit_code: 0
  checks_passed: 394
  checks_failed: 0
  suite: bash scripts/tests/run-behavioral-contract-tests.sh
  diff_digest: fd6e347326f71b4e4566bbb25be47e1bd5a1789f1f4761fe8a6e577e8457d398
  timestamp: 2026-10-02T17:15:00Z
  ```
  - `bash scripts/validate-references.sh .` passed (0 broken links).
  - `bash scripts/validate-execution-control.sh --root . --strict` passed (52 records).
  - `bash scripts/measure-tokens.sh --strict` passed (Balanced 2350/2500, Lite 1286/1500).
  - `bash scripts/measure-per-task-tokens.sh --strict` passed (all baselines passed).
  - `bash scripts/tests/run-execution-control-fixtures.sh` passed (24/24 contracts).
  - `bash scripts/check-changelog-entry.sh` passed.
- **CI Evidence**: `Pending PR creation and GitHub Actions run.`
- **Review Evidence**: `Addresses Issue #505: standardized evidence block, 3-layer architecture, runtime harness adapter, and tiered cognition.`
- **Commit Evidence**: `Pending commit.`
- **Pull Request Evidence**: `Pending PR creation.`
- **Release Evidence**: `N/A - no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `All acceptance criteria AC-1 through AC-6 verified.`
- **Changed-File Summary**: `Standardize Verification Evidence Block schema in quality gate and templates, add parser validation in execution-control scripts, define 3-Layer Architecture in docs/ARCHITECTURE.md, and document Tiered Model Specialization in protocols/subagent-delegation.md.`
- **Completion Exception**: `None.`
- **Completion Decision and Timestamp**: `2026-10-02T17:15:00+13:00`
