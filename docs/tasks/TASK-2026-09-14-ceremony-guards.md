# Task Record: Ceremony guards — L2 downgrade logging, higher-level tie-break, milestone definition, contract-test naming

<a id="TASK-2026-09-14-ceremony-guards"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-ceremony-guards`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: Audit findings #5 and #6 (fact-checked against live main after PR-A merge); maintainer directive "do the recommendation" 2026-09-14
- **External Reference (Optional)**: `N/A`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No release or tag actions.`
- **Created**: `2026-09-14 10:45 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Close the self-issued L2 downgrade bypass, add a deterministic tie-break for mixed-level requests, make the milestone git-boundary rule meaningful (define milestone start, scope to the current task's changes, add the post-init exception), and rename overclaimed "behavioral" test terminology to what the harnesses actually are.
- **In Scope**:
  - `docs/tasks/TASK-2026-09-14-ceremony-guards.md` (this record)
  - `workflows/route.md` - L2 downgrade announcement requirement + tie-break rule
  - `templates/agent-directive-template.md` - ceremony summary tie-break + announced downgrades; milestone bullet scoping
  - `templates/agent-directive-lite-template.md` - one-line tie-break clause in Lite ceremony section
  - `protocols/code-quality-gate.md` - milestone-boundary definition, task-scope qualifier, pre-existing-dirt exception
  - `templates/project-profile-template.md` - aligned milestone checklist wording
  - `README.md` - done-gates row scoping; documentation-contract naming (legend + CI description bullet)
  - `CONTRIBUTING.md` - validation-commands naming line
  - `FAQ.md` - Q13 enforcement phrasing aligned with the README honesty section
  - `.github/workflows/ci.yml` - display-name updates for contract-test steps
- **Explicit Non-Goals**:
  - No runtime compliance-judge harness (strategic decision deferred to maintainer)
  - No file renames of the contract-test scripts themselves (name the concept, not the paths)
  - No release, tag, or deployment actions
- **Dependencies**: PR-A merged (`75a0f3a`)
- **Risk**: Low-Medium - ceremony wording is public contract; kept additive (budget +~25 tok, headroom ~156)
- **Verification Condition**: `validate-execution-control.sh --root . --strict` VALID; behavioral + budget + matrix suites green; `measure-tokens.sh --strict` PASS; references 0 warnings; CI both OSes.

## 3. Acceptance Criteria

- [x] **AC-1**: route.md requires announced, one-line-reason L2 downgrades; silent downgrade is explicitly a protocol violation.
- [x] **AC-2**: "Ties take the higher level" rule shipped in route.md and both directives' ceremony summaries.
- [x] **AC-3**: "Milestone boundary" defined; dirty-tree rule scoped to current-task changes with a documented post-init/pre-existing exception in code-quality-gate.md, directive, and project-profile checklist.
- [x] **AC-4**: README/CONTRIBUTING/FAQ/ci.yml describe the suites as documentation-contract (string-level) tests; the FAQ enforcement answer matches the README "How Enforcement Actually Works" honesty section.
- [x] **AC-5**: All gates green including the new record (zero validator diagnostics), budgets hold.

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
- **Start Time**: `2026-09-14 10:45 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 10:45 UTC | Implementor agent | Record created under standing maintainer directive "do the recommendation" | This record |
| planned | ready | 2026-09-14 10:45 UTC | Implementor agent | Readiness complete; scope pre-approved verbatim on the recommendation card (reviewable at merge gate) | Prior turn's PR-B scope listing |
| ready | in_progress | 2026-09-14 10:45 UTC | Implementor agent | Branch `155-prb-ceremony-guards`; pointer assumed | This record |
| in_progress | completed | 2026-09-14 10:45 UTC | Implementor agent | Branch `155-prb-ceremony-guards`; pointer assumed | This record |
| in_progress | awaiting_review | 2026-09-14 11:10 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |
| awaiting_review | completed | 2026-09-14 11:10 UTC | Implementor agent | All ACs satisfied; battery green | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-09-14-ceremony-guards.md` - this record
  - `workflows/route.md` - downgrade logging + tie-break
  - `templates/agent-directive-template.md` - ceremony + milestone updates
  - `templates/agent-directive-lite-template.md` - Lite tie-break
  - `protocols/code-quality-gate.md` - milestone definition + scoping + exception
  - `templates/project-profile-template.md` - aligned checklist wording
  - `README.md` - done-gates scoping + documentation-contract naming
  - `CONTRIBUTING.md` - naming alignment
  - `FAQ.md` - Q13 enforcement-model alignment
  - `.github/workflows/ci.yml` - step display names
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Local battery green at HEAD: self-validator VALID|RECORDS=12 incl. this record (0 diagnostics); behavioral 81/81 (3 new ceremony assertions); token budget harness 6/6; profile matrix 9/9; init-safety OK; references 0 warnings; strict directive gate PASS (Balanced 2,404<=2,500, Lite 983<=1,500); milestone compression recovered 11 tok vs first draft
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: pending on PR run (Linux + Windows)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: see branch commits (ceremony, terminology, assertions, record)
- **Pull Request Evidence**: branch `155-prb-ceremony-guards` -> PR opened on push
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 Complete (announced-downgrade requirement + silent-downgrade violation text); AC-2 Complete (route.md 4b + both directives, asserted); AC-3 Complete (definition + task-scope + post-init exception in gate/directive/checklist/README, asserted); AC-4 Complete (README legend+CI bullet, FAQ Q13, ci.yml display names); AC-5 Complete (zero validator diagnostics, budgets hold)
- **Changed-File Summary**: 10 governance/contract surfaces; additive ceremony rules + definitional repairs + terminology honesty pass
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review; Implementor agent; 2026-09-14 11:10 UTC`
