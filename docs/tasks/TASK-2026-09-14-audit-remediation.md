# Task Record: Audit remediation — validator self-enforcement, record completion, claim provenance

<a id="TASK-2026-09-14-audit-remediation"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-audit-remediation`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: External audit report (parallel review session, 2026-09-14) with reproducible probes; maintainer-approved PR-A plan (ROI items 1, 3, 4, 8)
- **External Reference (Optional)**: audit findings #1/#3/#4/#8; PR #151 closure context
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. Completed legacy records receive appended canonical completion evidence + repaired transition tables ONLY (original narrative preserved; pre-repair states recoverable at c296473).`
- **Created**: `2026-09-14 09:05 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Close the verified gap where main fails `validate-execution-control.sh --root .` with 42 diagnostics while CI stays green; repair the audit's confirmed factual defects (sync.md recovery-path errors, monolithic 18.5k baseline without derivation, FAQ/matrix/claims mismatches); move the exhaustion and telemetry-provenance rules into the always-loaded directive; widen drift guards past their proven false negatives.
- **In Scope**:
  - `docs/tasks/TASK-2026-09-14-audit-remediation.md` (this record)
  - `docs/tasks/TASK-2026-09-14-lite-profile.md` (canonical completion addendum + repaired transition table)
  - `docs/tasks/TASK-2026-09-14-lite-profile.scope-1.md` (new approved Scope Change Record for `workflows/onboard.md`)
  - `docs/tasks/TASK-2026-09-14-empirical-benchmarks.md` (canonical completion addendum + repaired transitions)
  - `docs/tasks/TASK-2026-09-14-cross-ref-tails.md` (canonical completion addendum + repaired transitions)
  - `.github/workflows/ci.yml` (self-validation steps: `validate-execution-control.sh --root . --strict` bash + ps1)
  - `scripts/tests/run-behavioral-contract-tests.sh` + `scripts/tests/run-behavioral-contract-tests.ps1` (widen stale-count grep coverage to `docs/BENCHMARKS.md`, `templates/lite-profile.md`; add zero-diagnostics self-check note; trigger-convention mapping assertion)
  - `workflows/sync.md` (derived counts instead of hardcoded `19 workflows`, 3-line card alignment, rendered `.promptkit/` paths, honest purge wording)
  - `README.md`, `QUICKSTART.md`, `FAQ.md`, `docs/BENCHMARKS.md`, `templates/lite-profile.md` (FAQ count unification, 22->23 residues, dual monolithic baseline, §3 model-scope note)
  - `scripts/measure-tokens.sh` + `scripts/measure-tokens.ps1` (documented derivation of both baselines: core-6 subset live-measured + full-set measured)
  - `templates/agent-directive-template.md` + `templates/agent-directive-lite-template.md` (session-endurance rule, STATE-until-read trust rule, telemetry provenance clause, trigger rename table)
  - `init.sh` + `init.ps1` (add `CONVENTIONS.md` to injection candidates) + `protocols/setup.md` (list sync)
- **Explicit Non-Goals**:
  - L2 downgrade logging, milestone definition, dirty-tree scoping (PR-B)
  - Runtime compliance judge harness (strategic decision, PR-B or later)
  - Renaming behavioral-contract suites (PR-B wording sweep candidate)
  - No rewriting of legacy record narratives or original evidence rows; repair only adds canonical fields and legalizes the transition table with clearly-labeled reconstruction
- **Dependencies**: merged `c296473` (all #14x work); audit report findings (reproducible)
- **Risk**: Medium - touching merged governance artifacts (mitigation: append-only evidence, labeled repairs, full git history at `c296473`)
- **Verification Condition**: `bash scripts/validate-execution-control.sh --root . --strict` exits `PASSED|ERRORS=0`; full suite battery green; directive strict gate PASS; new guards exercised by CI both OSes.

## 3. Acceptance Criteria

- [ ] **AC-1**: Repository self-validation is wired into both CI jobs and main passes it with zero diagnostics.
- [ ] **AC-2**: The three legacy v1.6.0 records carry canonical completion evidence (8 fields), legal transition tables, usable Host Timer Capability, and a linked approved Scope Change Record where scope grew; original narratives unaltered.
- [ ] **AC-3**: `workflows/sync.md` ships zero hardcoded counts, zero unrendered `$KIT_DIR_REL`, 3-line card alignment, and honest re-read (not "discard memory") wording.
- [ ] **AC-4**: Monolithic baseline claims are derived and dual-stated (core-6 subset + full 23-file set, both measured); every cited reduction % matches its named baseline.
- [ ] **AC-5**: Directive gains session-endurance, STATE-untrusted-until-read, telemetry provenance, and trigger rename mapping; budgets hold (Balanced ≤ 2,500, Lite ≤ 1,500).
- [ ] **AC-6**: FAQ/Aider-host/count factual mismatches corrected (17 questions; `CONVENTIONS.md` injectable by both installers).
- [ ] **AC-7**: Drift guards now cover `docs/BENCHMARKS.md` + `templates/lite-profile.md` phrases that escaped the proven false-negative.

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

- **Execution State**: `in_progress`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: `TASK-2026-09-14-audit-remediation`
- **Start Time**: `2026-09-14 09:05 UTC`
- **Current Actor**: `Implementor agent`
- **Next Action**: `Commit 1: complete three legacy records + scope-1 record`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 09:05 UTC | Implementor agent | Record created from maintainer-approved PR-A plan | This record |
| planned | ready | 2026-09-14 09:05 UTC | PromptKit maintainer | All readiness fields populated; approval via picker "Approve PR-A as scoped" | Picker approval + validator clean at ready |
| ready | in_progress | 2026-09-14 09:05 UTC | Implementor agent | Branch `audit-remediation-151a`; pointer assumed | This record |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-09-14-audit-remediation.md` - this record
  - `docs/tasks/TASK-2026-09-14-lite-profile.md` - canonical completion addendum + repaired transitions
  - `docs/tasks/TASK-2026-09-14-lite-profile.scope-1.md` - approved scope change for onboard.md
  - `docs/tasks/TASK-2026-09-14-empirical-benchmarks.md` - canonical completion addendum + repaired transitions
  - `docs/tasks/TASK-2026-09-14-cross-ref-tails.md` - canonical completion addendum + repaired transitions
  - `.github/workflows/ci.yml` - self-validation steps both OSes
  - `scripts/tests/run-behavioral-contract-tests.sh` - widened stale-claim coverage + convention mapping assertion
  - `scripts/tests/run-behavioral-contract-tests.ps1` - PS parity of same
  - `workflows/sync.md` - recovery-path factual repair
  - `README.md` - counts, FAQ links, monolithic dual baseline, matrix truth
  - `QUICKSTART.md` - count residues
  - `FAQ.md` - count unification, enforcement-phrasing alignment
  - `docs/BENCHMARKS.md` - 22->23, dual baselines with derivation, §3 model-scope note
  - `templates/lite-profile.md` - counts, dual baseline note
  - `scripts/measure-tokens.sh` - baseline derivation comments
  - `scripts/measure-tokens.ps1` - PS parity
  - `templates/agent-directive-template.md` - endurance, trust, provenance, rename table
  - `templates/agent-directive-lite-template.md` - lite-appropriate subset of same rules
  - `init.sh` - CONVENTIONS.md candidate
  - `init.ps1` - CONVENTIONS.md candidate parity
  - `protocols/setup.md` - Aider target confirmed
- **Scope Change Records**: `docs/tasks/TASK-2026-09-14-lite-profile.scope-1.md`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: pending
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: pending
- **Review Evidence**: pending
- **Commit Evidence**: pending
- **Pull Request Evidence**: pending
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `in_progress`
- **Acceptance Results**: pending
- **Changed-File Summary**: 21 files: 4 governance records completed, 1 scope record created, CI self-gate wired, guards widened, sync.md repaired, claims derived/corrected, 4 directive endurance+provenance rules, installer parity
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: pending
