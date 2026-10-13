# Task Record: Issue #605 Terminology Consistency

## 1. Identity and Authority
- **Record Type**: Task Record
- **Task ID**: TASK-2026-10-13-issue-605-terminology-consistency
- **Ceremony Level**: Level 2 (Controlled Work)
- **PromptKit Adaptation Profile**: none
- **Work Type**: Documentation
- **Planning Record Link**: N/A — the requester-provided Issue #605 specification is the controlling formal scope
- **Planning Depth Reference**: N/A — no architecture or design decision
- **Assumption Record Links**: None
- **Specification**: User-provided Issue #605 authorization and acceptance criteria
- **External Reference (Optional)**: https://github.com/lowqualityloey/promptkit-os/issues/605 (read-only)
- **Owner / Actor**: Local coding agent; no collaborators
- **Execution Scope**: FAQ.md, docs/ADOPTION-GUIDE.md, workflows/refactor.md, CHANGELOG.md, docs/tasks/TASK-2026-10-13-issue-605-terminology-consistency.md, and docs/BENCHMARKS.md
- **Approval Boundary**: Coordinator Option 2 authorization (2026-10-13): continue only in the existing isolated worktree; update the benchmark reconciliation and complete the five-file terminology change; create up to two local commits if required by the provenance-anchor contract. No push, PR, merge, issue update, release, tag, publication, cross-project logging, or other repository changes.
- **Created**: 2026-10-13 02:07 UTC

## 2. Objective and Boundaries
- **Objective**: Remove ambiguity between Adoption Stages 0–4 and task-risk Levels 0–3; accurately state the refactor workflow's Level 0 boundary.
- **In Scope**:
  - FAQ.md: label rollout maturity as Adoption Stages 0–4 and state the taxonomy boundary.
  - docs/ADOPTION-GUIDE.md: separate adoption stages from task-ceremony model guidance without changing recommendations.
  - workflows/refactor.md: scope structural refactoring to Levels 1–3 and state the canonical Level 0 boundary.
  - CHANGELOG.md: add the required workflows/ gate entry.
  - docs/BENCHMARKS.md: update only the affected current full-workflow total and provenance anchor; preserve historical baselines, other measurements, methodology, and token-budget semantics.
  - docs/tasks/TASK-2026-10-13-issue-605-terminology-consistency.md: maintain the required execution record.
- **Explicit Non-Goals**:
  - Do not modify workflows/route.md, protocols/context-economy.md, workflows/design-system.md, or notes/skill-matrix.md.
  - Do not modify scripts/tests/, test pins, runtime routing, approval boundaries, verification tiers, security controls, or model-floor guidance. The only benchmark changes authorized are the current full-workflow measurement and its provenance.
  - Do not push, open a PR, merge, update the issue, release, tag, publish, or change any repository other than the existing isolated worktree. Local commits are limited to two and only for the provenance-anchor contract.
- **Dependencies**: Verified original baseline `d8f8936c768d3acbbd4402cb732377b3f23fbb66` on origin/main; isolated branch `docs/issue-605-terminology`; coordinator decision Option 2 authorizes the bounded benchmark/provenance reconciliation and up to two local commits.
- **Risk**: Readers could confuse adoption maturity with task ceremony or infer design/learner labels grant execution authority.
- **Verification Condition**: Preserve stage order/instructions/timing, model guidance, and authority; pass relevant contract, link, changelog, docs, and diff checks.

## 3. Acceptance Criteria
- [ ] **AC-1**: FAQ and guide use Adoption Stage 0–4 for rollout maturity; preserve all five stages, order, instructions, and estimates.
- [ ] **AC-2**: Preserve the guide's adequacy/recommendation wording and identify those bullets as task-ceremony Levels 0–3.
- [ ] **AC-3**: Refactor workflow covers Levels 1–3; Level 0 boundary cites the router and excludes actual source-code refactoring.
- [ ] **AC-4**: FAQ states D0–D3 is design procedure, T1–T4 is engineer competency, and neither grants execution permission; no model family gains/loses authority because of these labels.
- [ ] **AC-5**: No canonical definition, test pin, runtime rule, approval, verification, security, or model-floor guidance changes.
- [ ] **AC-6**: Run and report the applicable Bash/PowerShell tests, documentation validators, changelog check, and git diff --check.
- [ ] **AC-7**: Both independent full-workflow counters agree; current benchmark figures match; the benchmark provenance anchor resolves to Commit A and measured inputs do not drift through final HEAD.

## 4. Execution Policy
- **Mode**: Gated Mode
- **TDD Enforcement Mode**: disabled; documentation-only and no test/contract edits
- **Batch Authorization**: N/A
- **Authorization Checkpoint Reference**: User authorization in Issue #605 request
- **Soft Checkpoint**: After inventory and after edits
- **Hard Checkpoint**: Stop for baseline drift, an unapproved test-pin change, or required authority-file scope expansion
- **Event-Driven Checkpoints**: Baseline and final verification
- **Stop Conditions**: Baseline drift; unapproved test/contract edits; material scope expansion; any push, PR, merge, issue update, release, tag, publication, or other repository change
- **Host Timer Capability**: Limitation — no task-wide live timer is enforced; individual tool calls have bounded timeouts only.

## 5. State and Active Ownership
- **Execution State**: completed
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: 2026-10-13T02:07:00Z
- **Current Actor**: Local coding agent
- **Next Action**: Local verification finished; stop and await separate publication authorization.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-13 02:07 UTC | Local coding agent | Accepted bounded Issue #605 scope and verified baseline/worktree | User request and baseline results |
| planned | in_progress | 2026-10-13 02:07 UTC | Local coding agent | Authority inventory complete; began authorized documentation pass | This Task Record |
| in_progress | completed | 2026-10-13 18:18 UTC | Local coding agent | Option 2 reconciliation complete; two local provenance commits created and final checks passed | Six-file scope, independent 116,906 measurements, and no measured-input drift from Commit A |

## 6. Evidence and Completion Gate
- **Changed Files**:
  - `FAQ.md` — adoption-stage terminology and the taxonomy boundary.
  - `docs/ADOPTION-GUIDE.md` — adoption stages separated from task-ceremony model guidance.
  - `workflows/refactor.md` — Levels 1–3 scope with the explicit Level 0 boundary.
  - `CHANGELOG.md` — `[Unreleased]` Changed entry for the terminology work.
  - `docs/BENCHMARKS.md` — current full-workflow total corrected to 116,906 and provenance anchored to Commit A.
  - `docs/tasks/TASK-2026-10-13-issue-605-terminology-consistency.md` — this record.
- **Scope Change Records**: Coordinator Option 2 decision authorizes only docs/BENCHMARKS.md current measurement/provenance reconciliation, the existing terminology changes, up to two local commits, and final verification.
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: Bash behavioral contracts 450/0 (exit 0); PowerShell behavioral contracts 448/0 (exit 0); Bash and PowerShell token measurers each independently report the full 26-workflow total as 116,906 (exit 0); reference-link suites 8/0 each (exit 0); Bash and PowerShell reference validators exit 0; Bash and PowerShell execution-control validators each report `VALID|RECORDS=65|ROOT=.` (exit 0); Bash and PowerShell CHANGELOG gates both `PASS` for base `d8f8936c768d3acbbd4402cb732377b3f23fbb66...HEAD` (exit 0); base-to-HEAD and worktree `git diff --check` both exit 0. The benchmark provenance anchor resolves to Commit A `998fc1ca347eb118ec4f81a3e779a5303e3577db`, and the measured-input diff from Commit A to final HEAD is empty.
- **Behavior IDs**: N/A
- **TDD Intent Register**: N/A
- **TDD Execution Evidence**: N/A
- **TDD Exception Verification**: Documentation-only; unchanged existing contract/link tests and docs validators; no test assets changed.
- **CI Evidence**: N/A — local only, no commit or PR
- **Review Evidence**: Scoped diff reviewed; Option 2 authorized the benchmark reconciliation. Terminology-only edits preserve model recommendations, adoption timing/estimates, routing, risk, authorization, and verification boundaries; no independent review requested
- **Commit Evidence**: Commit A `998fc1ca347eb118ec4f81a3e779a5303e3577db` has parent `d8f8936c768d3acbbd4402cb732377b3f23fbb66` and tree `f04e83299fcbcd1f02e2d8ed008d0a12660fa77e`; it carries the approved six-file scope and the corrected full-workflow total. Commit B anchors `docs/BENCHMARKS.md` to Commit A and records this closeout; it is parented on Commit A and its full SHA and tree are reported in the final session report. No third commit was created.
- **Pull Request Evidence**: N/A — explicitly prohibited for this pass
- **Release Evidence**: N/A — no release authorized
- **Blocker and Resume Condition**: None. The user approved Option 2 and explicitly authorized benchmark reconciliation and local provenance commits; continue within the six-file scope.
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 PASS; AC-2 PASS; AC-3 PASS; AC-4 PASS; AC-5 PASS; AC-6 PASS; AC-7 PASS.
- **Changed-File Summary**: The authorized final inventory is exactly six files: FAQ.md, docs/ADOPTION-GUIDE.md, workflows/refactor.md, CHANGELOG.md, docs/tasks/TASK-2026-10-13-issue-605-terminology-consistency.md, and docs/BENCHMARKS.md. No other tracked files are authorized.
- **Completion Exception**: None; every authorized check passed without an exception.
- **Completion Decision and Timestamp**: Completed local reconciliation and verification on 2026-10-13; no push, PR, merge, issue update, release, tag, or publication action taken.
