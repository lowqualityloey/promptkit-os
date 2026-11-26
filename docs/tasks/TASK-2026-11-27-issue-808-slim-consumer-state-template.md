# Task Record: Slim the consumer STATE template and clean up the PROMPTKIT.md template
<a id="TASK-2026-11-27-issue-808-slim-consumer-state-template"></a>

## Identity
- **Record Type**: `Task Record`
- **Record Form**: `Lite`
- **Task ID**: `TASK-2026-11-27-issue-808-slim-consumer-state-template`
- **Ceremony Level**: `Level 2 (Controlled)`
- **Specification**: `https://github.com/lowqualityloey/promptkit-os/issues/808`
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: `promptkit-os repository on branch refactor/808-slim-consumer-state-template; the consumer STATE and project-profile templates, the checkpoint workflow that becomes the importer mapping's canonical home, both ceremony-overhead measurement twins, docs/BENCHMARKS.md, CHANGELOG.md and this record. Local implementation, verification and commits on the dedicated branch only.`
- **Approval Boundary**: `Local implementation, verification and commits on a dedicated branch only. Push, PR creation, merge, force-push, squash/rebase/amend, tag, release and issue closure remain unauthorized until the operator approves a review checkpoint.`
- **Created**: `2026-11-27 08:30 UTC`

## Boundaries
- **Objective**: `Ship issue #808: reduce a fresh consumer docs/STATE.md from 180 lines / 3,078 tok to a clean usable ~50-70 lines / <=1,000 tok by moving the PromptKit-internal checkpoint-importer parser specs and the Release-Evaluation Handoff out of the consumer template to their canonical workflow home, while keeping every State Mutation Contract section and pk:checkpoint / pk:doctor invariant intact; fix the project-profile Turbo wording and raw arrow; and restate the measured SETUP and workflow-inventory baselines.`
- **In Scope**:
  - `templates/state-tracker-template.md`
  - `templates/project-profile-template.md`
  - `workflows/checkpoint.md`
  - `scripts/measure-ceremony-overhead.sh`
  - `scripts/measure-ceremony-overhead.ps1`
  - `docs/BENCHMARKS.md`
  - `CHANGELOG.md`
  - `docs/tasks/TASK-2026-11-27-issue-808-slim-consumer-state-template.md`
- **Explicit Non-Goals**:
  - `No push, PR creation, merge, tag or release in this task.`
  - `No change to the State Mutation Contract, validator rules, checkpoint labels or task-record labels: only the consumer template's duplicate reference material moves.`
  - `No deletion or rename of templates/state-tracker-template.md: the manifest coverage exemption and the docs/STATE.md seeding path both depend on it.`
  - `No test-file changes: every existing behavioral, doctor, init-safety and execution-control assertion must keep passing unchanged.`
  - `No Windows CI run here: the PowerShell twins are executed locally with the available pwsh when present, otherwise reviewed for parity.`
- **Dependencies**: `Issue #807 at commit dadb62a supplies the strip-mode lifecycle docs this branch does not reopen; the #808 branch is cut from it.`
- **Risk**: `Medium` - `The template is the seed for every consumer docs/STATE.md, so cutting a section that a workflow or validator silently needs would break fresh installs rather than this repository. Mitigated by grepping every test assertion first, keeping all section headers and every string the behavioral suite pins, keeping the §3A fields the execution-control validator compares, keeping the §4 illustrative/empty-state semantics, and pinning the new size through the SETUP baseline in the ceremony measurement.`
- **Verification Condition**: `bash scripts/tests/run-init-safety-tests.sh, bash scripts/tests/run-terminal-picker-tests.sh, bash scripts/tests/run-courier-integrity-pin-fixtures.sh, bash scripts/tests/run-behavioral-contract-tests.sh, bash scripts/tests/run-doctor-tests.sh, bash scripts/validate-references.sh . --strict, bash scripts/validate-execution-control.sh --root . --strict, bash scripts/measure-ceremony-overhead.sh, bash scripts/scan-staged-secrets.sh ., bash scripts/check-changelog-entry.sh and git diff --check all exit 0.`

## Acceptance Criteria
- [ ] **AC-1**: `templates/state-tracker-template.md contains no checkpoint-importer field-mapping table, no REFUSED-L0/QUICK-VALID/FULL-VALID/DRAFT-INCOMPLETE verdict rules and no Release-Evaluation Handoff block; a fresh docs/STATE.md measures <=1,000 tokens (bytes/4), keeps the §1-§9 headers, the State Mutation Contract sections, the §3A projection fields, the §4 illustrative-source and empty-state semantics, the §4A promotion rule, the §8 Table Invariant comment and the §9 spend-ledger shape.`
  - **Result**: `Pass`
  - **Evidence**: `Template is 70 lines / 3,999 B / 1,000 tok; run-behavioral-contract-tests.sh keeps every pinned substring and assert_invariant_section_verdict PASS; measure-ceremony-overhead.sh --strict reports CEREMONY_BASELINE|SETUP|1000|1000|PASS`
- [ ] **AC-2**: `The importer field mapping and verdict rules are preserved verbatim in their canonical reference location, and the §3B release-evaluation handoff remains available from the checkpoint workflow rather than the consumer template.`
  - **Result**: `Pass`
  - **Evidence**: `workflows/checkpoint.md now carries #### Checkpoint Importer Field Mapping with the 20-row table and the moved verdict paragraph; its existing ### Optional Release-Evaluation Handoff remains the canonical §3B fragment`
- [ ] **AC-3**: `templates/project-profile-template.md describes Turbo as "parallel write waves" instead of "parallel subagent waves" and renders the Execution Precedence chain with the Unicode arrow instead of raw \$\rightarrow\$.`
  - **Result**: `Pass`
  - **Evidence**: `Line 12 reads "Balanced + parallel write waves"; line 113 reads Native MCP Tools → Native IDE Search/Edit Tools → Terminal CLI Commands → Structured Markdown Fallback`
- [ ] **AC-4**: `Both ceremony-overhead twins publish the re-measured SETUP baseline (3,999 B / 1,000 tok) and docs/BENCHMARKS.md restates the SETUP, full-set and core-six figures plus the provenance anchor required by the behavioral guard.`
  - **Result**: `Pass`
  - **Evidence**: `scripts/measure-ceremony-overhead.sh and .ps1 pin SETUP=1000; docs/BENCHMARKS.md rows read 3,999 B / 1,000 tok, 34,646 tok and 122,741 tok; the documentation-only follow-up commit restates the anchor to the implementation commit`
- [ ] **AC-5**: `Every required local gate exits 0, the record lists every touched path with no brace shorthand, CHANGELOG.md carries exactly one [Unreleased] entry for the branch, and no raw host path appears in code, docs or this record.`
  - **Result**: `Pending`
  - **Evidence**: `Final gate run recorded in Verification Evidence after the docs-only anchor commit`

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
- **Start Time**: `2026-11-27 08:12 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: `Review the local diff, then ask the operator for the push/PR checkpoint.`

### Transition History
| Previous State | New State | Timestamp | Actor | Reason | Evidence |
|---|---|---|---|---|---|
| `N/A` | `planned` | `2026-11-27 08:12 UTC` | `DeepSeek Harness agent (lead)` | `Created` | `N/A` |
| `planned` | `in_progress` | `2026-11-27 08:14 UTC` | `DeepSeek Harness agent (lead)` | `Template measurement and canonical-home analysis started` | `Issue #808` |
| `in_progress` | `awaiting_review` | `2026-11-27 08:30 UTC` | `DeepSeek Harness agent (lead)` | `Slim template, canonical mapping, profile fixes and measurements are in place; full gates and commits pending` | `Gate transcripts in Verification Evidence` |

## Evidence and Completion
- **Changed Files**:
  - `templates/state-tracker-template.md` - slimmed from 180 lines / 12,312 B to 70 lines / 3,999 B / 1,000 tok; importer table, verdict rules and §3B removed while every section header, projection field and pinned contract string stays
  - `workflows/checkpoint.md` - new #### Checkpoint Importer Field Mapping section carrying the moved 20-row table and verdict paragraph verbatim; the existing optional release-evaluation handoff remains the canonical §3B home
  - `templates/project-profile-template.md` - Turbo description now says "parallel write waves"; Execution Precedence uses the Unicode arrow
  - `scripts/measure-ceremony-overhead.sh` - SETUP baseline 3,078 → 1,000 tokens
  - `scripts/measure-ceremony-overhead.ps1` - PowerShell twin SETUP baseline 3,078 → 1,000 tokens
  - `docs/BENCHMARKS.md` - SETUP row 12,312 B / 3,078 tok → 3,999 B / 1,000 tok; inventory rows 34,646 and 122,741 tok; banner and §11.1 anchor restated by the follow-up docs commit
  - `CHANGELOG.md` - one [Unreleased] entry for issue #808
  - `docs/tasks/TASK-2026-11-27-issue-808-slim-consumer-state-template.md` - this Level 2 Lite record
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Pending the final gate run on the documentation-only anchor tree`
- **CI Evidence**: `N/A - local branch, not pushed`
- **Review Evidence**: `N/A`
- **Commit Evidence**: `N/A before commit`
- **Pull Request Evidence**: `N/A`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 pass; AC-2 pass; AC-3 pass; AC-4 pass; AC-5 pending`
- **Changed-File Summary**: `The consumer STATE template lost the PromptKit-internal importer and release-handoff material and now measures 1,000 tokens; that material lives canonically in the checkpoint workflow; the project-profile wording and arrow are fixed; the ceremony baseline and published benchmarks reflect the new setup size and workflow inventory.`
- **Completion Exception**: `None`
- **Completion Decision and Timestamp**: `Pending review, DeepSeek Harness agent (lead), 2026-11-27 08:30 UTC`

Transition rows use the canonical edges from the full template; the last row matches Execution State.
