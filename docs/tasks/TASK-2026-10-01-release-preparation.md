# Release preparation task

<a id="TASK-2026-10-01-release-preparation"></a>

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-01-release-preparation`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `docs/releases/2026-10-01-v1.10.0-evaluation.md`
- **Owner / Actor**: `Codex`
- **Execution Scope**: `Release preparation 2026-10-01; isolated candidate worktree and named draft release artifacts`
- **Approval Boundary**: `Final release approval; commits, tags, pushes, hosted release, npm and changelog publication require separate authorization`
- **Created**: `2026-10-01`
- **Objective**: `Prepare a concrete release candidate, notes, impact inventory, and verified courier evidence for coordinator decision`

## Scope

- **In Scope**:
  - docs/releases/2026-10-01-v1.10.0-*.md draft records.
  - docs/tests/2026-10-01-v1.10.0-*.md evidence and verification.
  - docs/tasks/TASK-2026-10-01-release-preparation.md.
  - Candidate runtime checks in disposable projects.
- **Explicit Non-Goals**:
  - Publication, history changes, production actions, live hosted-model evaluation, and unrelated source edits.
- **Dependencies**: Candidate checkout and local Node/npm; existing source CI evidence.
- **Risk**: Medium - verification operates only in isolated temporary projects.
- **Verification Condition**: Canonical release/reference validators and candidate courier install/refusal/reinstall/equivalence checks pass; five independent review lanes return exact-SHA verdicts.

## Acceptance Criteria

- [x] AC-1: Complete ordered range and evidence-based version with linked notes.
- [x] AC-2: Candidate courier usage and existing-tag smoke results recorded accurately.
- [x] AC-3: Independent review complete and approval package presented.

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes; advisory`
- **Hard Checkpoint**: `At or before 90 minutes; advisory`
- **Event-Driven Checkpoints**: `Milestone, scope change, compaction, or handoff`
- **Stop Conditions**: `Failed verification, scope expansion, missing approval for external action, or developer stop`
- **Host Timer Capability**: `Manual timestamps only; limitation: the host cannot mechanically enforce checkpoint deadlines`
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-01`
- **Current Actor**: `Coordinator (@heyloey)`
- **Next Action**: `Maintainer executes release branch, PR, commit, tag v1.10.0, and push for release publication`

## Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
| --- | --- | --- | --- | --- | --- |
| N/A | planned | 2026-10-01 | Codex | User accepted release preparation | User request |
| planned | in_progress | 2026-10-01 | Codex | Scope and evidence sources recorded | 2026-10-01-v1.10.0-evaluation.md |
| in_progress | awaiting_review | 2026-10-01 | AGY | Candidate verification complete; QA review deferred awaiting coordinator decision | docs/releases/2026-10-01-v1.10.0-qa-review.md |

- **Changed Files**: `docs/tests/2026-10-01-v1.10.0-impact-evidence.md, docs/releases/2026-10-01-v1.10.0-evaluation.md, docs/releases/2026-10-01-v1.10.0-candidate.md, docs/releases/2026-10-01-v1.10.0-release-notes.md, docs/releases/2026-10-01-v1.10.0-qa-review.md, docs/releases/2026-10-01-v1.10.0-approved-release.md, docs/tests/2026-10-01-v1.10.0-verification.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `docs/tests/2026-10-01-v1.10.0-verification.md`
- **TDD Intent Register**: `N/A - exception work type`
- **TDD Execution Evidence**: `N/A - exception work type`
- **TDD Exception Verification**: `Documentation-only preparation verified through canonical validators and runtime evidence`
- **CI Evidence**: `GitHub Actions 36799104652; source b34322e90d1a18d6c4355024cdd4829d40ca0253; Pass`
- **Review Evidence**: `docs/releases/2026-10-01-v1.10.0-qa-review.md (QA Accepted; Release Option A Approved by Coordinator @heyloey)`
- **Commit Evidence**: `N/A before commit; no commit authorized`
- **Pull Request Evidence**: `N/A before PR`
- **Release Evidence**: `docs/releases/2026-10-01-v1.10.0-approved-release.md`
- **Blocker and Resume Condition**: `Coordinator approved Option A; proceed with release branch, PR, tag v1.10.0, and push`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `Passed AC-1, AC-2, AC-3; candidate v1.10.0 verified across all contracts; approved by coordinator`
- **Changed-File Summary**: `Draft release, approved release record, and evidence artifacts`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Approved by Coordinator @heyloey on 2026-10-01T15:05:39+13:00`


