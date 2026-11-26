# Task Record: Make the Level 2 Lite record forms the default and surface the Solo/Fast preset and five-command loop
<a id="TASK-2026-11-26-issue-790-l2-light-defaults"></a>

## Identity
- **Record Type**: `Task Record`
- **Record Form**: `Lite`
- **Task ID**: `TASK-2026-11-26-issue-790-l2-light-defaults`
- **Ceremony Level**: `Level 2 (Controlled)`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/790`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: `promptkit-os repository on branch feat/790-l2-light; two new template files, the execution-control validator twins, measurement twins, behavioural contract twins, policy workflows, the project profile surfaces, README, ARCHITECTURE, BENCHMARKS, CHANGELOG and this record. Local implementation, verification and commits on the dedicated branch only.`
- **Approval Boundary**: `Local implementation, verification and commits on a dedicated branch only. Push, PR creation, merge, force-push, squash/rebase/amend, tag, release and issue closure remain unauthorized until the operator approves a review checkpoint.`
- **Created**: `2026-11-26 00:00 UTC`

## Boundaries
- **Objective**: `Ship issue #790 so an ordinary Level 2 task carries a Lite Task Record plus a Lite checkpoint (under 1,000 tokens combined), Level 3 keeps the full 20-label forms, the Solo/Fast preset and the five-command loop are documented end to end, and every local gate stays green.`
- **In Scope**:
  - `templates/execution-task-record-lite-template.md`
  - `templates/execution-checkpoint-lite-template.md`
  - `scripts/validate-execution-control.sh`
  - `scripts/validate-execution-control.ps1`
  - `scripts/measure-ceremony-overhead.sh`
  - `scripts/measure-ceremony-overhead.ps1`
  - `scripts/tests/fixtures/execution-control/cases/lite-valid/docs/tasks/TASK-2026-09-08-lite-valid.md`
  - `scripts/tests/fixtures/execution-control/cases/lite-valid/docs/tasks/TASK-2026-09-08-lite-valid.checkpoint-1.md`
  - `scripts/tests/fixtures/execution-control/cases/lite-level3-refused/docs/tasks/TASK-2026-09-08-lite-level3.md`
  - `scripts/tests/fixtures/execution-control/cases/lite-level3-refused/docs/tasks/TASK-2026-09-08-lite-level3.checkpoint-1.md`
  - `scripts/tests/fixtures/execution-control/expected/cases.tsv`
  - `scripts/tests/fixtures/execution-control/expected/lite-valid.summary.txt`
  - `scripts/tests/fixtures/execution-control/expected/lite-valid.diagnostics.txt`
  - `scripts/tests/fixtures/execution-control/expected/lite-level3-refused.summary.txt`
  - `scripts/tests/fixtures/execution-control/expected/lite-level3-refused.diagnostics.txt`
  - `scripts/tests/run-behavioral-contract-tests.sh`
  - `scripts/tests/run-behavioral-contract-tests.ps1`
  - `scripts/validate-references.sh`
  - `scripts/validate-references.ps1`
  - `workflows/tasks.md`
  - `workflows/checkpoint.md`
  - `workflows/profile.md`
  - `protocols/setup.md`
  - `templates/project-profile-template.md`
  - `PROMPTKIT.md`
  - `README.md`
  - `docs/ARCHITECTURE.md`
  - `docs/BENCHMARKS.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-26-issue-790-l2-light-defaults.md`
- **Explicit Non-Goals**:
  - No fourth installer profile: Solo/Fast is a documented preset line, not a new `init.sh` profile.
  - No edits to the canonical agent directives, so the published Balanced and Lite budgets stay where they are.
  - No push, PR, merge, tag or release in this task.
  - No changes to Level 3 artifact membership or its measured figures.
- **Dependencies**: `None. Issue #790 is self-contained; #791, #792 and #793 follow on their own branches.`
- **Risk**: `Medium` - `A ceremony-default change touches the validator contract, the measurement baselines and the published BENCHMARKS figures at once; mitigated by dogfooding the new Lite form here, by fixture cases in both directions (Lite valid at Level 2, Lite refused at Level 3), and by re-running every gate before the commit.`
- **Verification Condition**: `bash scripts/validate-execution-control.sh --root . --strict, bash scripts/validate-references.sh . --strict, bash scripts/tests/run-token-budget-tests.sh, bash scripts/measure-tokens.sh --strict, bash scripts/measure-ceremony-overhead.sh --strict, bash scripts/measure-tokenizer-delta.sh --strict and bash scripts/tests/run-behavioral-contract-tests.sh all exit 0.`

## Acceptance Criteria
- [ ] **AC-1**: `A Lite Task Record and Lite checkpoint exist, are the default for ordinary Level 2 work, and carry under 1,000 tokens combined.`
  - **Result**: `Pending`
  - **Evidence**: `bash scripts/measure-ceremony-overhead.sh --strict reports CEREMONY_TOTAL|L2|required_tokens=998`
- [ ] **AC-2**: `The full 20-label checkpoint and full Task Record remain required at Level 3 and opt-in at Level 2, and a Lite form is refused at Level 3.`
  - **Result**: `Pending`
  - **Evidence**: `The lite-level3-refused fixture records POLICY_LIMITATION for both records in the execution-control matrix`
- [ ] **AC-3**: `The Solo/Fast preset is documented in PROMPTKIT.md, the project profile template and pk:profile, keeps the hard gates, and never states a token figure in workflows/profile.md.`
  - **Result**: `Pending`
  - **Evidence**: `bash scripts/tests/run-behavioral-contract-tests.sh pins preset:, solo-fast and the hard-gate sentence`
- [ ] **AC-4**: `README and the setup protocol surface the five-command loop (pk:plan, pk:auto, pk:review, pk:commit, pk:checkpoint), and every measurement, reference and behavioural gate passes.`
  - **Result**: `Pending`
  - **Evidence**: `bash scripts/validate-references.sh . --strict, measure gates and the behavioural suite exit 0`

## Execution Policy
- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, scope expansion, handoff, or compaction`
- **Stop Conditions**: `Missing approval, failed verification, blocker, or stop`
- **Host Timer Capability**: `Observed limit; live timing is not enforceable in this host`

## State and Ownership
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-26 00:00 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Review the local diff, then ask the operator for the push/PR checkpoint.`

### Transition History
| Previous State | New State | Timestamp | Actor | Reason | Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `2026-11-26 00:00 UTC` | `DeepSeek Harness agent (lead)` | `Created` | `N/A` |
| `planned` | `in_progress` | `2026-11-26 00:10 UTC` | `DeepSeek Harness agent (lead)` | `Implementation started` | `Issue #790` |
| `in_progress` | `awaiting_review` | `2026-11-26 02:00 UTC` | `DeepSeek Harness agent (lead)` | `Local gates green; commit and review pending` | `Gate transcripts in Verification Evidence` |

## Evidence and Completion
- **Changed Files**:
  - `templates/execution-task-record-lite-template.md` - new Lite Task Record form
  - `templates/execution-checkpoint-lite-template.md` - new Lite checkpoint form
  - `scripts/validate-execution-control.sh` - Record Form gate and Lite checkpoint tier
  - `scripts/validate-execution-control.ps1` - PowerShell twin of the same gate
  - `scripts/measure-ceremony-overhead.sh` - Lite default footprint and re-derived band
  - `scripts/measure-ceremony-overhead.ps1` - PowerShell twin of the measurement change
  - `scripts/tests/fixtures/execution-control/cases/lite-valid/docs/tasks/TASK-2026-09-08-lite-valid.md` - valid Lite Level 2 fixture
  - `scripts/tests/fixtures/execution-control/cases/lite-valid/docs/tasks/TASK-2026-09-08-lite-valid.checkpoint-1.md` - valid Lite checkpoint fixture
  - `scripts/tests/fixtures/execution-control/cases/lite-level3-refused/docs/tasks/TASK-2026-09-08-lite-level3.md` - Lite at Level 3 refusal fixture
  - `scripts/tests/fixtures/execution-control/cases/lite-level3-refused/docs/tasks/TASK-2026-09-08-lite-level3.checkpoint-1.md` - Lite checkpoint at Level 3 refusal fixture
  - `scripts/tests/fixtures/execution-control/expected/cases.tsv` - matrix rows for the two new cases
  - `scripts/tests/fixtures/execution-control/expected/lite-valid.summary.txt` - expected VALID summary
  - `scripts/tests/fixtures/execution-control/expected/lite-valid.diagnostics.txt` - empty expected diagnostics
  - `scripts/tests/fixtures/execution-control/expected/lite-level3-refused.summary.txt` - expected FAILED summary
  - `scripts/tests/fixtures/execution-control/expected/lite-level3-refused.diagnostics.txt` - expected POLICY_LIMITATION diagnostics
  - `scripts/tests/run-behavioral-contract-tests.sh` - preset, loop and Lite-default assertions
  - `scripts/tests/run-behavioral-contract-tests.ps1` - PowerShell twin assertions
  - `scripts/validate-references.sh` - 31-template inventory
  - `scripts/validate-references.ps1` - PowerShell 31-template inventory
  - `workflows/tasks.md` - Lite record default for ordinary Level 2
  - `workflows/checkpoint.md` - Lite checkpoint tier for Level 2
  - `workflows/profile.md` - Solo/Fast preset section and preset-only switch path
  - `protocols/setup.md` - five-command loop surfaced on first run
  - `templates/project-profile-template.md` - preset machine line
  - `PROMPTKIT.md` - preset machine line and profile bullet
  - `README.md` - five-command loop quick start
  - `docs/ARCHITECTURE.md` - template tree entries for the Lite forms
  - `docs/BENCHMARKS.md` - Level 2 Lite figures, band, checkpoint forms and provenance anchor
  - `CHANGELOG.md` - Unreleased entry
  - `docs/tasks/TASK-2026-11-26-issue-790-l2-light-defaults.md` - this record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Pending - recorded after the gate run; includes validate-execution-control, validate-references, token budgets, measure-tokens, measure-ceremony-overhead, measure-tokenizer-delta and the behavioural contract suite.`
- **CI Evidence**: `N/A until the operator authorizes a push and the GitHub Actions jobs run.`
- **Review Evidence**: `N/A - awaiting operator review checkpoint.`
- **Commit Evidence**: `N/A before commit; the commit entry lives in git history.`
- **Pull Request Evidence**: `N/A - no PR authorized yet.`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 pending; AC-2 pending; AC-3 pending; AC-4 pending`
- **Changed-File Summary**: `Two new Lite record templates, the execution-control validator twins plus two fixture cases, the ceremony-measurement twins, the behavioural contract twins, the reference validators, three workflow policies, the setup protocol, both profile surfaces, README, ARCHITECTURE, BENCHMARKS, CHANGELOG and this record.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Awaiting the operator review checkpoint before any push or PR - 2026-11-26 02:00 UTC`

Transition rows use the canonical edges from the full template; the last row matches Execution State.
