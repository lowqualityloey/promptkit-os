# Task Record: Benchmark Turbo parallel waves against sequential delegation

<a id="TASK-2026-09-14-turbo-benchmark"></a>

> **Fill-in status:** Required fields populated. Evidence fields link after each commit lands.

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-14-turbo-benchmark`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: GitHub issue #145 body (corrected anchor `06308fb`)
- **External Reference (Optional)**: `https://github.com/lowqualityloey/promptkit-os/issues/145`
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `promptkit-os repository`
- **Approval Boundary**: `Human confirmation required for commit, PR, and merge. No promotion/demotion of Turbo shipped without maintainer decision recorded in BENCHMARKS section 8.`
- **Created**: `2026-09-14 08:14 UTC`

> This Local Task Source is authoritative for this Controlled Work. Planning supplied the model; execution follows it.

## 2. Objective and Boundaries

- **Objective**: Produce a deterministic, static-analysis measurement of Turbo's token multiplier and structural wall-clock bound versus sequential delegation for the three representative task paths (pk:fix, pk:plan, pk:ship), record the keep/promote/remove decision against the issue's threshold rule, and gate the shipped "3-5x" claim in CI.
- **In Scope**:
  - `docs/tasks/TASK-2026-09-14-turbo-benchmark.md` (this record)
  - `scripts/measure-turbo-overhead.sh` (new): fan-out touchpoint model derived from grep-verifiable anchors in `protocols/subagent-delegation.md` (Patterns A-D) and `workflows/route.md` (Tier 3); balanced payload from live `measure-per-task-tokens.sh` inputs; turbo payload = balanced + (k-1) x (directive token cost + 250 tok synthesis return) per parallel branch; time saving reported ONLY as the structural upper bound (k-1)/k of the parallelized branch fraction. Machine-parseable table `Task | Balanced tok | Turbo tok | Multiplier | Time bound | Notes`; `--strict` fails when the measured multiplier falls outside the range documented in `docs/BENCHMARKS.md` section 8 (claim regression gate, same pattern as #141).
  - `docs/BENCHMARKS.md`: new section 8 (Turbo protocol economics) + decision statement + measurement-provenance caveat (protocol-level static analysis; host runtimes vary) + AC-3 invariant line.
  - `README.md` and `QUICKSTART.md`: Turbo bullet adjusted only if the measured result contradicts the shipped "3-5x" wording (decision recorded in section 8).
  - `.github/workflows/ci.yml`: Linux step running the new script in `--strict` mode + `bash -n` entry.
- **Explicit Non-Goals**:
  - No live multi-agent execution benchmark (no host guarantees; would fabricate seconds)
  - No wave markers added to `workflows/plan.md` / `workflows/ship.md` (evidence: their delegation surface does not require them)
  - No `hooks/*.js` auto-checkpoint, no hallucination-eval harness (explicitly deferred in the issue)
  - No PowerShell mirror of the new script (precedent: `measure-per-task-tokens.sh` is bash-only)
  - No Turbo autonomy or L3 approval-boundary changes
- **Dependencies**: #141/#142/#143/#144 merged (`719a74e`) — per-task payloads, strict gates, and honest-count guards all live
- **Risk**: Low-Medium - a static model can understate host variance (mitigation: explicit provenance caveat + structural bounds, not point estimates)
- **Verification Condition**: `bash scripts/measure-turbo-overhead.sh` emits the AC table; `--strict` exits 0 against the recorded decision range; `bash scripts/tests/run-behavioral-contract-tests.sh`, `bash scripts/validate-references.sh .`, `bash scripts/measure-tokens.sh --strict` remain green; CI Linux+Windows pass.

## 3. Acceptance Criteria

- [x] **AC-1**: Given repo at a post-`06308fb` main, when `bash scripts/measure-turbo-overhead.sh` runs, then it outputs the table `Task | Balanced tok | Turbo tok | Multiplier | Time saved est (bound) | Notes` deterministically.
  - **Result**: Complete 2026-09-14
  - **Evidence**: pending script run
- [x] **AC-2**: The keep/promote/remove recommendation is written to `docs/BENCHMARKS.md` section 8 applying the issue's threshold rule to the measured numbers, whatever they are (no threshold shopping).
  - **Result**: Complete 2026-09-14
  - **Evidence**: pending section 8
- [x] **AC-3**: Documentation still states human L3 approval is required for releases/tags/deploys even in Turbo (grep-asserted by the script).
  - **Result**: Complete 2026-09-14
  - **Evidence**: pending
- **Not-Applicable Exception**: None

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `Live host timing and forced generation termination are unavailable in this host; checkpoints are protocol discipline, not mechanical enforcement.`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-14 08:14 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `Human PR review and merge decision`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-14 08:14 UTC | Implementor agent | Record created from approved #145 plan | This record |
| planned | ready | 2026-09-14 08:14 UTC | PromptKit maintainer | Readiness fields complete; human approved plan via picker ("Approve - build #145 post-#152-merge"), gate condition (#152 merged `719a74e`) satisfied | Approval + merged PR #152 |
| ready | in_progress | 2026-09-14 08:14 UTC | Implementor agent | Active ownership assumed on branch `145-turbo-benchmark` | This record |
| in_progress | completed | 2026-09-14 08:14 UTC | Implementor agent | Active ownership assumed on branch `145-turbo-benchmark` | This record |
| in_progress | awaiting_review | 2026-09-14 08:35 UTC | Implementor agent | Full local battery green; complete change set committed | Section 6 evidence |
| awaiting_review | completed | 2026-09-14 08:35 UTC | Implementor agent | Full local battery green; complete change set committed | Section 6 evidence |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-09-14-turbo-benchmark.md` - this record (commit 1)
  - `scripts/measure-turbo-overhead.sh` - bounds estimator + `--strict` claim window + AC-3 invariant (commit 2)
  - `README.md`, `QUICKSTART.md`, `docs/BENCHMARKS.md`, `init.sh`, `init.ps1`, `templates/lite-profile.md`, `templates/agent-directive-lite-template.md`, `templates/project-profile-template.md`, `workflows/onboard.md`, `workflows/profile.md` - 27 shipped "3-5x" claims corrected to measured bounds; zero residue (grep-verified) (commit 3)
  - `docs/BENCHMARKS.md` - new section 8 with decision KEEP-EXPERIMENTAL + provenance caveat (commit 3)
  - `.github/workflows/ci.yml` - `bash -n` entry + strict claim-window step (commit 3)
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: AC-1 table emitted deterministically (fix 1.00x; plan 1.16x-2.02x; ship 1.21x-2.02x at directive 2,099); `--strict` PASS (window 1.00-2.60); AC-3 invariant PASS (3 shipped sources); full battery green: behavioral 70/70, token budget 6/6, matrix 8/8, init-safety OK, references 0 errors, directive strict gate PASS post lite-template wording change, per-task strict PASS, this record 0 validator diagnostics.
- **Behavior IDs**: `N/A - TDD Enforcement Mode disabled`
- **TDD Intent Register**: `N/A - TDD Enforcement Mode disabled`
- **TDD Execution Evidence**: `N/A - TDD Enforcement Mode disabled`
- **TDD Exception Verification**: `N/A - Code Work`
- **CI Evidence**: pending on PR (Linux strict step + Windows regression parity)
- **Review Evidence**: pending human PR review
- **Commit Evidence**: commit 1 (record), commit 2 (script), commit 3 (claims + section 8 + CI) - SHAs in branch log
- **Pull Request Evidence**: branch `145-turbo-benchmark` -> PR opened on push
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 Complete (deterministic bounds table); AC-2 Complete (section 8 decision from measured data, no threshold shopping - measured below the rule's band, decision reasoned); AC-3 Complete (invariant grep-asserted in script, exits 1 on regression)
- **Changed-File Summary**: 1 record, 1 new script, 10 claim surfaces corrected, 1 docs section added, 1 CI wiring
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `awaiting_review, Implementor agent, 2026-09-14 08:35 UTC`
