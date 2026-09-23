# Task Record: Salvage GPT-draft diagrams into specialist docs

<a id="TASK-2026-09-18-docs-salvage"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-18-docs-salvage`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub Issue #285 — salvage GPT-draft diagrams and content into specialist docs
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/285`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-18 01:00 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Relocate the reusable parts of the discarded GPT README draft (ASCII diagrams, stronger problem questions) into the docs layer without re-inflating the README. Follow-up to PR #284 discussion.
- **In Scope**:
  - `docs/WORKFLOW-MAP.md` - JIT routing tree, VERIFY/bounded-repair loop, search-discipline visual (skip already-covered)
  - `docs/ARCHITECTURE.md` - stack fan-out diagram, token philosophy visual (skip already-covered)
  - `README.md` - merge only 2 stronger problem questions (stop condition, mid-scope change)
  - `QUICKSTART.md` - Updating PromptKit section (via SCOPE-2026-09-18-docs-salvage-1)
  - `README.md` - one-line update pointer (via SCOPE-2026-09-18-docs-salvage-1)
  - `docs/tasks/TASK-2026-09-18-docs-salvage.md` (this record)
- **Explicit Non-Goals**:
  - No README restructure or re-inflation with relocated detail
  - No storing the GPT draft as a separate file (no second source of truth)
  - No changes to workflows, protocols, templates, or scripts
  - No release, tag, or deployment actions
- **Dependencies**: PR #284 merged (`a40218d`); Issue #285 approved scope
- **Risk**: Low - documentation-only relocation; illustrative diagrams create no new authority
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; `validate-references.sh` 0 warnings; `measure-tokens.sh --strict` PASS; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: No duplicate source of truth - GPT draft not stored as a file
- [x] **AC-2**: `bash scripts/validate-references.sh .` exits 0
- [x] **AC-3**: `bash scripts/measure-tokens.sh --strict` passes (README static footprint unaffected)
- [x] **AC-4**: `bash scripts/validate-execution-control.sh --root . --strict` VALID

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `Live host timing and forced generation termination are unavailable in this host; checkpoint thresholds are protocol discipline, not mechanical enforcement.`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-18 01:00 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `None - task complete; PR #286 merged`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-18 01:00 UTC | Implementor agent | Record created for Issue #285 Controlled Work | Issue #285 |
| planned | ready | 2026-09-18 01:00 UTC | Implementor agent | Readiness complete; scope pre-approved in Issue #285 | This record |
| ready | in_progress | 2026-09-18 01:00 UTC | Implementor agent | Branch `docs/salvage-gpt-diagrams-285`; pointer assumed | This record |
| in_progress | completed | 2026-09-18 01:00 UTC | Implementor agent | Branch `docs/salvage-gpt-diagrams-285`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-18 01:30 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |
| awaiting_review | completed | 2026-09-18 01:30 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |
| awaiting_review | in_progress | 2026-09-18 02:00 UTC | Implementor agent | Approved scope expansion SCOPE-2026-09-18-docs-salvage-1; pointer reassumed | This record |
| in_progress | awaiting_review | 2026-09-18 02:15 UTC | Implementor agent | Scope expansion delivered; battery green | Section 6 |
| awaiting_review | completed | 2026-09-18 02:15 UTC | Implementor agent | Scope expansion delivered; battery green | Section 6 |


## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/WORKFLOW-MAP.md` - Execution Visuals section (JIT routing, verification loop, search discipline)
  - `docs/ARCHITECTURE.md` - Knowledge and Token Architecture section (stack fan-out, token philosophy)
  - `README.md` - two stronger problem questions (stop condition, mid-scope change)
  - `QUICKSTART.md` - Updating PromptKit section (via scope change record)
  - `README.md` - one-line update pointer (via scope change record)
  - `docs/tasks/TASK-2026-09-18-docs-salvage.md` - this record
  - `docs/tasks/TASK-2026-09-18-docs-salvage.scope-1.md` - scope change record
- **Scope Change Records**: `SCOPE-2026-09-18-docs-salvage-1`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=14 (0 diagnostics); behavioral 178/178; playbook 11/11; references 0 warnings incl. new QUICKSTART anchor; measure-tokens --strict PASS (Balanced 2498<=2500, Lite 1146<=1500)
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Documentation Work`
- **CI Evidence**: PR #286 CI green both OSes at merge (Lint and Validate Linux SUCCESS, Windows SUCCESS)
- **Review Evidence**: Maintainer-merged PR #286 on 2026-09-18; no separate review record
- **Commit Evidence**: Branch commits a9d9d57, a45c436, 389f30c squash-merged as a716958
- **Pull Request Evidence**: PR #286 merged 2026-09-18T00:58:41Z, closes Issue #285
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 Complete (no draft file stored, relocation only); AC-2 Complete (references 0 warnings incl. new anchor); AC-3 Complete (Balanced 2498, Lite 1146); AC-4 Complete (VALID|RECORDS=14, 0 diagnostics)
- **Changed-File Summary**: 6 files; Execution Visuals + Knowledge and Token Architecture sections, 2 README problem questions, QUICKSTART update section plus README pointer (via scope-1), decision-tree mermaid repair, Task Record plus scope record
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `completed; PromptKit maintainer; 2026-09-18 03:00 UTC`
