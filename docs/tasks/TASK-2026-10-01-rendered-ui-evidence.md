# Task Record: Rendered browser UI evidence for Issue #494

<a id="TASK-2026-10-01-rendered-ui-evidence"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-01-rendered-ui-evidence`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `GitHub Issue #494 — require rendered browser UI evidence before UI completion`
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/494`
- **Owner / Actor**: `PromptKit maintainer (approver) + Codex (executor)`
- **Execution Scope**: `promptkit-os repository; documentation and workflow contract only`
- **Approval Boundary**: `Human confirmation required for the final local commit. Push, PR creation, merge, and release actions require separate authorization; merge remains human-only.`
- **Created**: `2026-10-01`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Define proportionate, observable browser evidence for UI completion, including honest Not verified reporting when browser verification is unavailable, and wire the protocol into the design workflow and quality gate.`
- **In Scope**:
  - `docs/tasks/TASK-2026-10-01-rendered-ui-evidence.md` (this record)
  - `protocols/rendered-ui-evidence.md`
  - `protocols/code-quality-gate.md`
  - `protocols/setup.md`
  - `workflows/design-system.md`
  - `docs/BENCHMARKS.md` (refresh figures and reproducible input provenance)
- **Explicit Non-Goals**:
  - `No changes to a consumer application's UI, runtime code, or native mobile behavior.`
  - `No test-harness prose assertions; the browser-observation cases are reviewed manually as protocol scenarios.`
  - `No push, PR creation, merge, tag, or release action in this task.`
- **Dependencies**: `Issue #494 and the user's request to prepare the change for review.`
- **Risk**: `Low-medium — additive public workflow contract across the design workflow and completion gate.`
- **Verification Condition**: `Bash behavioral contracts, strict token and per-task measurements, reference validation, syntax/whitespace checks, and staged-content hygiene pass; PowerShell parser passes, with the full PowerShell harness limitation recorded.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Browser-rendered UI completion requirements in workflows/design-system.md and protocols/code-quality-gate.md; protocol registry in protocols/setup.md.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-01-rendered-ui-evidence; protocols/rendered-ui-evidence.md.`
- **Supporting Planning / Review Record**: `docs/tasks/TASK-2026-10-01-rendered-ui-evidence.md (this record).`
- **User-Observable Before Behavior**: `UI work could be called complete using static checks or source review without browser-rendered evidence.`
- **User-Observable After Behavior**: `UI completion requires scoped browser evidence; unavailable checks must be reported as Not verified with the limitation and follow-up stated.`
- **Impact Classification**: `User-Facing Additive Contract Change`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `The change adds an explicit, compatible evidence requirement and retains existing static checks.`
- **Migration and Upgrade Guidance**: `N/A - non-breaking additive guidance.`
- **Maintenance Commit Declaration**: `N/A - this is an intentional public contract change.`

## 4. Acceptance Criteria

- [x] **AC-1**: `The rendered UI protocol is discoverable through the design workflow, quality gate, and setup registry, and the existing UI checklist points to it.` Result: `Pass.`
- [x] **AC-2**: `The protocol covers proportionate routes and viewports, relevant states, reachability, nested clipping, keyboard/focus, rendered contrast, safe evidence, and Not verified reporting.` Result: `Pass.`
- [x] **AC-3**: `Four manual regression cases cover missing evidence, unavailable tooling, nested clipping, and scope proportionate to the UI change.` Result: `Pass; reviewed as protocol behavior, not asserted by prose-only tests.`
- [x] **AC-4**: `Current benchmark values include a reproducible measured-input base revision and digest.` Result: `Pass; recorded base fea046afecdebd0f54d47cc7078019a9b23298f0 and digest b38297dc679ba27c73392a9b2c3c3fd95d45220ea92ce94f58f2a66d48f8663c.`
- [x] **AC-5**: `Applicable repository checks and review prerequisites are recorded before commit confirmation.` Result: `Pass; verification and review summaries are in Section 6. Full PowerShell twin execution remains unverified on this WSL/Windows UNC host.`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, compaction, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion, missing approval for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically enforce checkpoint deadlines; timing remains a manual protocol limitation.`
- **Execution State**: `in_progress`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: `TASK-2026-10-01-rendered-ui-evidence`
- **Start Time**: `2026-10-01`
- **Current Actor**: `Codex; implementation and review preparation complete, updated commit confirmation pending.`
- **Branch / Revision**: `codex/issue-494-rendered-ui-evidence at base fea046afecdebd0f54d47cc7078019a9b23298f0; changes staged.`
- **Next Action**: `Present the updated staged file list and full commit message; create the local commit only after the user's confirmation.`

### Process note

The Level 2 classification was identified during final commit preparation, after implementation and verification had already begun. This record was formalized at that gate and does not claim that the record existed before implementation. The current scope, results, and remaining authorization boundary are recorded here for an accurate handoff.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-01 | Codex | Issue #494 scope formalized when the Controlled Work requirement was identified at the commit gate. | User request and Issue #494 |
| planned | in_progress | 2026-10-01 | Codex | Existing implementation and verification were recorded honestly; the task record now owns the remaining commit-preparation scope. | Staged change and Section 6 evidence |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-10-01-rendered-ui-evidence.md` — this Level 2 Task Record
  - `protocols/rendered-ui-evidence.md` — browser evidence contract and manual regression scenarios
  - `protocols/code-quality-gate.md` — rendered evidence completion requirement
  - `protocols/setup.md` — lazy-loaded protocol registration
  - `workflows/design-system.md` — UI workflow and completion checklist wiring
  - `docs/BENCHMARKS.md` — refreshed values and reproducible provenance
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Bash behavioral contracts 385/385 PASS; strict token budget PASS (Balanced 2318/2500, Lite 1274/1500); strict per-task measurements PASS (fix 9094/8050, plan 19167/18123, ship 15555/14511); reference validation PASS across 316 Markdown files; Bash syntax, PowerShell parser, diff check, benchmark digest, staged secret scan, and staged debug-probe scan PASS. PowerShell full contract twin: 363 passed / 25 environment-driven failures because Windows PowerShell cannot resolve nested bash/pwsh from the WSL UNC path; native Windows verification remains follow-up.`
- **CI Evidence**: `Pending PR; no commit or remote run exists.`
- **Review Evidence**: `The implementation diff before this Task Record was added received PASS from goal, code, security, context, and QA review lanes. The Task Record is commit-gate bookkeeping and was not part of those reviews. Exact-commit-SHA review evidence remains pending until a commit exists.`
- **Commit Evidence**: `Pending updated human confirmation; proposed message and staged file list are presented for approval.`
- **Pull Request Evidence**: `N/A - no PR created; separate remote-write authorization remains required.`
- **Release Evidence**: `N/A - no release action in scope.`
- **Blocker and Resume Condition**: `Await the user's decision on the updated commit message, which now includes this required Task Record. Push or PR creation remains outside the current authorization.`
- **Completion State**: `in_progress`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass; AC-5 Pass with the full PowerShell execution limitation disclosed.`
- **Changed-File Summary**: `Add rendered browser evidence contract and wire it into UI completion; refresh benchmark provenance; record Level 2 scope and evidence.`
- **Completion Exception**: `Full PowerShell behavioral twin was not verified because the WSL/Windows UNC host cannot resolve nested bash/pwsh commands; native Windows execution is follow-up.`
- **Completion Decision and Timestamp**: `Pending local commit and PR review.`
