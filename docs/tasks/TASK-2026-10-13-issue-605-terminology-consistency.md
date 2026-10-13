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
- **Approval Boundary**: Coordinator Option 2 authorization (2026-10-13) and remediation pass authorization: work only in the isolated worktree; resolve review findings F1–F4 and F7; up to three local commits (A, B, C) authorized for provenance-anchor contract and review remediation. No push, PR, merge, issue update, release, tag, publication, cross-project logging, or other repository changes.
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
  - Do not push, open a PR, merge, update the issue, release, tag, publish, or change any repository other than the existing isolated worktree. Local commits are limited to three (A, B, C) for the provenance-anchor contract and authorized review remediation.
- **Dependencies**: Verified original baseline `d8f8936c768d3acbbd4402cb732377b3f23fbb66` on origin/main; isolated branch `docs/issue-605-terminology`; coordinator Option 2 and remediation decisions authorize the benchmark reconciliation, local provenance commits, and remediation of review findings.
- **Risk**: Readers could confuse adoption maturity with task ceremony or infer design/learner labels grant execution authority.
- **Verification Condition**: Preserve stage order/instructions/timing, model guidance, and authority; pass relevant contract, link, changelog, docs, and diff checks.

## 3. Acceptance Criteria
- [x] **AC-1**: FAQ and guide use Adoption Stage 0–4 for rollout maturity; preserve all five stages, order, instructions, and estimates.
- [x] **AC-2**: Preserve the guide's adequacy/recommendation wording and identify those bullets as task-ceremony Levels 0–3.
- [x] **AC-3**: Refactor workflow covers Levels 1–3; Level 0 boundary cites the router and excludes actual source-code refactoring.
- [x] **AC-4**: FAQ states D0–D3 is design procedure, T1–T4 is engineer competency, and neither grants execution permission; no model family gains/loses authority because of these labels.
- [x] **AC-5**: No canonical definition, test pin, runtime rule, approval, verification, security, or model-floor guidance changes.
- [x] **AC-6**: Run and report the applicable Bash/PowerShell tests, documentation validators, changelog check, and git diff --check.
- [x] **AC-7**: Both independent full-workflow counters agree; current benchmark figures match; the benchmark provenance anchor resolves to Commit A and measured inputs do not drift through final HEAD.

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
| in_progress | awaiting_review | 2026-10-13 18:27 UTC | Local coding agent | Option 2 reconciliation complete; Commits A and B created locally | Six-file scope, independent 116,906 measurements, Commit A provenance anchor |
| awaiting_review | in_progress | 2026-10-13 19:00 UTC | Local coding agent | Independent review reported blocking findings F1/F2; coordinator authorized remediation pass | Coordinator decision and remediation authorization |
| in_progress | completed | 2026-10-13 19:20 UTC | Local coding agent | Remediated F1/F2/F3/F4/F7; local checks green; Commit C created | Section 6 verification and Commit C record |

## 6. Evidence and Completion Gate
- **Changed Files**:
  - `FAQ.md` — adoption-stage terminology and the taxonomy boundary.
  - `docs/ADOPTION-GUIDE.md` — adoption stages separated from task-ceremony model guidance, including resolution of review finding F1.
  - `workflows/refactor.md` — Levels 1–3 scope with the explicit Level 0 boundary.
  - `CHANGELOG.md` — `[Unreleased]` Changed entry for the terminology work.
  - `docs/BENCHMARKS.md` — current full-workflow total remeasured to 116,906 tokens and provenance anchored to Commit A.
  - `docs/tasks/TASK-2026-10-13-issue-605-terminology-consistency.md` — this record.
- **Scope Change Records**: Coordinator Option 2 decision and subsequent remediation decision authorize only docs/BENCHMARKS.md current measurement/provenance reconciliation, the existing terminology changes, up to three local commits (A, B, C), and final verification.
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: Bash behavioral contracts 450/0 (exit 0); PowerShell behavioral contracts 448/0 (exit 0); Bash and PowerShell token measurers each independently report the full 26-workflow total as 116,906 (exit 0); reference-link suites 8/0 each (exit 0); Bash and PowerShell reference validators exit 0; Bash and PowerShell execution-control validators each report `VALID|RECORDS=65|ROOT=.` (exit 0); Bash and PowerShell CHANGELOG gates both `PASS` for base `d8f8936c768d3acbbd4402cb732377b3f23fbb66...HEAD` (exit 0); base-to-HEAD and worktree `git diff --check` both exit 0. The benchmark provenance anchor resolves to Commit A `998fc1ca347eb118ec4f81a3e779a5303e3577db`, and the measured-input diff from Commit A to final HEAD (including Commit C) is empty.
- **Behavior IDs**: N/A
- **TDD Intent Register**: N/A
- **TDD Execution Evidence**: N/A
- **TDD Exception Verification**: Documentation-only; unchanged existing contract/link tests and docs validators; no test assets changed.
- **CI Evidence**: N/A — local only; Commits A and B exist locally, and Commit C is created locally on branch docs/issue-605-terminology. No push or pull request has been performed; native CI observation awaits separate publication authorization.
- **Review Evidence**: Independent review of Commit B identified blocking findings F1 (residual adoption-stage terminology in docs/ADOPTION-GUIDE.md) and F2 (task record commit-evidence contradiction) along with non-blocking findings F3, F4, and F7. Coordinator authorized a bounded remediation pass for these findings, implemented in Commit C.
- **Commit Evidence**: Commit A (`998fc1ca347eb118ec4f81a3e779a5303e3577db`) contains approved six-file scope and 116,906 remeasurement. Commit B (`2c5c686ddfaa28db4701c16c679f44dd97f46e90`) anchors docs/BENCHMARKS.md to Commit A. Commit C resolves review findings F1–F4 and F7 in docs/ADOPTION-GUIDE.md and this Task Record on top of Commit B, preserving Commit A and Commit B unchanged. Full SHAs, parents, and trees are documented in Section 6 and the final report. No remote push has occurred.
- **Pull Request Evidence**: N/A — explicitly prohibited for this pass
- **Release Evidence**: N/A — no release authorized
- **Blocker and Resume Condition**: None. Blocking review findings F1 and F2 resolved in local remediation; no publication blockers remain.
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 PASS (all adoption stages reconciled in FAQ and guide); AC-2 PASS; AC-3 PASS; AC-4 PASS; AC-5 PASS; AC-6 PASS; AC-7 PASS.
- **Changed-File Summary**: The authorized final inventory across the worktree branch remains exactly six files: FAQ.md, docs/ADOPTION-GUIDE.md, workflows/refactor.md, CHANGELOG.md, docs/tasks/TASK-2026-10-13-issue-605-terminology-consistency.md, and docs/BENCHMARKS.md. Only docs/ADOPTION-GUIDE.md and this Task Record are modified in the remediation commit.
- **Completion Exception**: None; every authorized check passed without an exception.
- **Completion Decision and Timestamp**: Local remediation and verification completed on 2026-10-13 (UTC) / 2026-10-14 (NZDT); no push, PR, merge, issue update, release, tag, or publication action taken.
