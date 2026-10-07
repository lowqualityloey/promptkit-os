# Task Record: pk:doctor read-only installed-governance audit

<a id="TASK-2026-10-08-pk-doctor"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-08-pk-doctor`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `docs/specs/issue-547-pk-doctor.md`
- **External Reference (Optional)**: `GitHub issue #547`
- **Owner / Actor**: `PromptKit maintainer (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; workflows/doctor.md and its read-only engine twins, the registration surfaces (directive, router, setup reference, architecture table, workflow map), every live-surface workflow-count claim, the changelog, CI wiring, and this record`
- **Approval Boundary**: `Implementation and local verification are authorized. Commit, push, and pull-request creation remain pending explicit user approval.`
- **Created**: `2026-10-08`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Ship a read-only pk:doctor that audits hosts x engine version x install-mode x ignore-state x docs-drift and reports rot without ever upgrading, register it in every required location, and move the locked workflow count from 25 to 26.`
- **In Scope**:
  - `workflows/doctor.md, scripts/check-doctor.sh, scripts/check-doctor.ps1, scripts/tests/run-doctor-tests.sh, scripts/tests/run-doctor-tests.ps1 (shipped on the branch; read-only twins)`
  - `Registration surfaces: templates/agent-directive-template.md, workflows/route.md, protocols/setup.md, docs/ARCHITECTURE.md, docs/WORKFLOW-MAP.md`
  - `Count 25 to 26 across README.md, QUICKSTART.md, FAQ.md, PROMPTKIT.md, docs/WORKFLOW-MAP.md, docs/ARCHITECTURE.md, docs/COMPARISONS.md, docs/INTERESTING-FACTS.md, CONTRIBUTING.md, init.sh, init.ps1, templates/lite-profile.md, templates/project-profile-template.md, workflows/onboard.md, workflows/profile.md, docs/adrs/0002-workflow-lifecycle-policy.md`
  - `Published token-figure re-propagation: docs/BENCHMARKS.md, protocols/setup.md, README.md, FAQ.md, templates/lite-profile.md`
  - `Behavioral-contract assertion: scripts/tests/run-behavioral-contract-tests.sh and scripts/tests/run-behavioral-contract-tests.ps1 (count literal 25 to 26 plus Scenario AR for pk:doctor)`
  - `CHANGELOG.md [Unreleased] entry; .github/workflows/ci.yml doctor syntax checks and both doctor test twins; docs/specs/issue-547-pk-doctor.md normative amendment (engine root, shared docs-drift fields, deleted universal host)`
  - `docs/tasks/TASK-2026-10-08-pk-doctor.md (this record)`
- **Explicit Non-Goals**:
  - `No enactment of #545/#550/#553 logic: the version and docs-drift rows delegate to those contracts and degrade to SKIP(<reason>) where an input is unavailable; they never re-derive or repair.`
  - `No repair or upgrade behavior; pk:doctor reports only, and --fix is limited to re-emitting a host directive block.`
  - `No live host runtime verification (maintainer-owned, docs/HOST-CONFORMANCE.md).`
  - `No merge: commit, push, and PR were explicitly authorized; merging PR #581 remains human-only.`
- **Dependencies**: `The version row delegates to #545's six-state engine-stamp table; the DIVERGED docs-drift row depends on the #550/#553 three-store precedence contract. Both degrade to SKIP(<reason>) until those land.`
- **Risk**: `Low - additive workflow plus registration and count/documentation synchronization; the only behavioral surface touched is the injected directive trigger list, which is token-budget-gated.`
- **Verification Condition**: `bash scripts/validate-references.sh . exits 0 with zero errors and zero warnings; bash -n on touched scripts is clean; the stale-count scan finds no live "25" workflow claim; bash scripts/tests/run-doctor-tests.sh passes.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `The pk: trigger surface (one new trigger), the injected directive block, workflow-count claims across the live documentation surface, and CI validation jobs.`
- **Contract Impact Evidence ID / Path**: `This record (Section 6); workflows/doctor.md, scripts/check-doctor.sh / .ps1, scripts/tests/run-doctor-tests.sh / .ps1.`
- **Supporting Planning / Review Record**: `docs/specs/issue-547-pk-doctor.md; docs/adrs/0002-workflow-lifecycle-policy.md`
- **User-Observable Before Behavior**: `No command audited installed governance; a stale engine, a missing host directive block, a managed path silently hidden by an ignore rule, or diverged state stores went undetected until a governance failure surfaced by hand.`
- **User-Observable After Behavior**: `pk:doctor emits one tab-separated row per check (hosts, version, ignore-state, docs-drift) with a status from OK / STALE / MISSING / IGNORED / DIVERGED / SKIP / INCOMPLETE, plus a remediation, and returns the documented exit code without ever upgrading.`
- **Impact Classification**: `User-Facing Additive Contract Change`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `Adds a new read-only trigger and its registrations; no existing workflow, alias, directive rule, or installation path is removed or altered.`
- **Migration and Upgrade Guidance**: `N/A - no migration required; existing installs gain the trigger on the next installer run or directorate refresh.`
- **Maintenance Commit Declaration**: `N/A - intentional additive contract change.`

## 4. Acceptance Criteria

- [x] **AC-1**: `pk:doctor is registered in the directive trigger list, the route decision matrix, the setup reference list, the architecture command table, and the workflow map.`
- [x] **AC-2**: `Every live-surface workflow-count claim reads 26 and the next-workflow ordinal reads 27th, with no stale 25 workflow claim remaining.`
- [x] **AC-3**: `scripts/check-doctor.sh / .ps1 and scripts/tests/run-doctor-tests.sh / .ps1 exist and are wired into both CI legs; both regression harnesses pass (Bash 14/14, PowerShell 14/14).`
- [x] **AC-4**: `CHANGELOG.md carries an [Unreleased] entry describing the new workflow.`
- [x] **AC-5**: `validate-references.sh . reports zero errors and zero warnings after the edits.`
- [x] **AC-6**: `Both behavioral-contract twins assert pk:doctor trigger uniqueness, the 26-file count, and the exit-code contract (healthy 0 / missing block 1 / deleted universal host 1 / absent prerequisite 2) in "Scenario AR" — the spec labels it "Scenario AP", but that label was already taken by #519-#523, so the next free label is used. Both twins pass with zero failures (Bash 450, PowerShell 448).`
- [x] **AC-7**: `Every published token figure is re-measured and re-propagated (docs/BENCHMARKS.md, protocols/setup.md, README.md, FAQ.md, templates/lite-profile.md); the strict budget gate passes (Balanced 2,341 / Lite 1,436).`
- [x] **AC-8**: `PR #581 review round 1: the four P2 findings are fixed in both twins — version/ignore scoped to the engine directory, --fix renders the engine-relative path and verifies it, docs-drift compares the shared canonical fields and never emits a bare OK, and a deleted universal AGENTS.md is MISSING. New nested-install fixtures N1-N4 pass in both harnesses; measured inputs are untouched, so the provenance anchor stays valid.`
- [x] **AC-9**: `PR #581 review round 2 (arena): the "direct self-audit step" claim is made true by a safe nested self-contained fixture step in CI (a TEST_DIR-style self-audit would false-fail because the version check audits the PR checkout and reports DIVERGED); the ADR 0002 25th/26th admission attribution is corrected; and an out-of-project engine reports the kit-directory ignore row as SKIP(engine outside project root) instead of a phantom OK, locked by fixture N5. Doctor harness 15/15 in both twins.`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion, missing authorization for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically enforce checkpoint deadlines; timing remains a manual protocol limitation.`
- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-10-08`
- **Current Actor**: `Sisyphus`
- **Next Action**: `None - merged as 9e0d939; this re-arm PR restates the provenance anchor to the squash commit.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-10-08 | Sisyphus | Task initialized for the issue #547 registration, count, and CI-wiring workstream. | User request |
| planned | in_progress | 2026-10-08 | Sisyphus | Applying registration, count, changelog, and CI edits, then running the local verification gates. | Section 6 |
| in_progress | awaiting_review | 2026-10-08 | Sisyphus | Implementation and local verification complete; commit, push, and PR await explicit approval. | Section 6 |
| awaiting_review | in_progress | 2026-10-08 | Sisyphus | Codex review of PR #581 returned four P2 findings; fixing them in both twins. | Section 6 |
| in_progress | awaiting_review | 2026-10-08 | Sisyphus | All four review findings fixed and re-verified in both twins; ready for merge. | Section 6 |
| awaiting_review | in_progress | 2026-10-08 | Sisyphus | Second review round (arena.ai): one required fix (self-audit claim) and three minors; resolving. | Section 6 |
| in_progress | awaiting_review | 2026-10-08 | Sisyphus | Round-2 findings resolved and re-verified (15/15 both twins); ready for merge. | Section 6 |
| awaiting_review | completed | 2026-10-08 | Sisyphus | PR #581 merged to main as 9e0d939; re-arm PR restates the provenance anchor to the squash commit. | Section 6, PR #581 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `templates/agent-directive-template.md` - one pk:doctor trigger line after pk:auto.
  - `workflows/route.md` - one lifecycle decision matrix row.
  - `protocols/setup.md` - one Workflows & Protocols Reference row; re-measured Balanced budget `2500` denominator line.
  - `docs/ARCHITECTURE.md` - one command-table row (`New 🧪`, now that Scenario AR covers it); "All 26 workflows"; layout count.
  - `docs/WORKFLOW-MAP.md` - one complexity-matrix row; cross-cutting utilities note; "Full 26-workflow map".
  - `README.md`, `QUICKSTART.md`, `FAQ.md`, `PROMPTKIT.md`, `docs/COMPARISONS.md`, `docs/INTERESTING-FACTS.md`, `CONTRIBUTING.md`, `init.sh`, `init.ps1`, `templates/lite-profile.md`, `templates/project-profile-template.md`, `workflows/onboard.md`, `workflows/profile.md`, `docs/adrs/0002-workflow-lifecycle-policy.md` - count 25 to 26 (and 26th to 27th); Balanced directive figures re-propagated where published.
  - `docs/BENCHMARKS.md` - re-measured Inventory rows (core-six 31,946 tok; full set 26 files / 116,136 tok), component/directive rows, reduction percentages, per-task payloads, tokenizer-delta rows, and the historical descriptor rewritten to avoid a stale count pattern. Provenance anchor stays `3e9710e`.
  - `scripts/tests/run-behavioral-contract-tests.sh` and `.ps1` - count literal 25 to 26 plus "Scenario AR" (pk:doctor trigger uniqueness, 26-file count, exit-code contract 0/1/2).
  - `CHANGELOG.md` - one [Unreleased] Added bullet.
  - `.github/workflows/ci.yml` - doctor bash -n checks and both doctor test twins wired into the Linux and Windows legs, plus a direct `pk:doctor` self-audit step that runs the detector against a nested self-contained fixture (companion to the reference validator). A bare repo-level self-audit was rejected: the kit repository ships no `AGENTS.md`, and a TEST_DIR-style run audits the PR's own checkout (DIVERGED).
  - `docs/adrs/0002-workflow-lifecycle-policy.md` - corrected the admission attribution (#440 made the surface 25; #547 `doctor.md` made it 26).
  - `docs/specs/issue-547-pk-doctor.md` - normative amendment recording the engine-dir vs project-root distinction, the shared docs-drift fields, and the deleted-universal-host rule.
  - `docs/tasks/TASK-2026-10-08-pk-doctor.md` - this record.
  - `workflows/doctor.md`, `scripts/check-doctor.sh`, `scripts/check-doctor.ps1`, `scripts/tests/run-doctor-tests.sh`, `scripts/tests/run-doctor-tests.ps1` - shipped on the branch (not authored in this workstream).
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `bash scripts/validate-references.sh . -> exit 0, 0 errors, 0 warnings. bash -n on touched scripts -> clean. bash scripts/tests/run-doctor-tests.sh -> 15/15; /usr/bin/pwsh scripts/tests/run-doctor-tests.ps1 -> 15/15 (S1-S10 plus nested-install N1-N5). bash scripts/tests/run-behavioral-contract-tests.sh -> Passed: 450 | Failed: 0; /usr/bin/pwsh scripts/tests/run-behavioral-contract-tests.ps1 -> Passed: 448 | Failed: 0. bash scripts/measure-tokens.sh --strict -> BALANCED 2341/2500 PASS, LITE 1436/1500 PASS. bash scripts/tests/run-token-budget-tests.sh -> 7/0. bash scripts/tests/run-reference-link-tests.sh -> 6/0. bash scripts/validate-execution-control.sh --root . --strict --authorization-baseline origin/main -> VALID, 63 records. Independent nested-install reproductions of every review finding confirm the fixed behaviour in both twins, and the CI self-audit step exits 0.`
- **CI Evidence**: `PR #581 CI green at 1c242b9; merged to main as 9e0d939.`
- **Review Evidence**: `Round 1 (Codex, PR #581, head 699b530): REQUEST CHANGES, four P2 findings. All four independently reproduced in both twins, fixed, and re-verified. Round 2 (arena.ai, head 2096717): APPROVE with one required fix plus three minors. Agreed with the stale "self-audit step" claim (made true via a safe nested fixture step rather than the unsafe TEST_DIR run, which would report DIVERGED), the ADR 25th/26th misattribution, the stale body numbers, and the phantom out-of-project ignore row; all resolved and re-verified.`
- **Commit Evidence**: `549f3c6 (feature), 6c17332 (anchor restate), 699b530 (Windows S6 fix), 2096717 (review round 1), 1c242b9 (review round 2); squashed to 9e0d939 on main.`
- **Pull Request Evidence**: `https://github.com/lowqualityloey/promptkit-os/pull/581`
- **Release Evidence**: `N/A - no release action in scope.`
- **Blocker and Resume Condition**: `None. The provenance anchor is restated to the squash commit 9e0d939 by this re-arm PR.`
- **Completion State**: `completed`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass (both harnesses 15/15); AC-4 Pass; AC-5 Pass; AC-6 Pass; AC-7 Pass; AC-8 Pass; AC-9 Pass.`
- **Changed-File Summary**: `Ship the read-only pk:doctor workflow and detector twins, register pk:doctor across the five required surfaces, bump the locked workflow count to 26 (next ordinal 27th) everywhere it is claimed, re-measure and re-propagate every published token figure, add the Scenario AR behavioral assertion and the CI wiring (syntax checks and both test twins), then fix the four review findings (engine-vs-project root scoping, engine-relative --fix paths, shared docs-drift field comparison, deleted-universal-host detection) with new nested-install fixtures.`
- **Completion Exception**: `The spec names the behavioral assertion "Scenario AP"; that label is already used by #519-#523, so it is implemented as "Scenario AR" (the next free label).`
- **Completion Decision and Timestamp**: `Merged via PR #581 as 9e0d939; both review rounds resolved; the provenance anchor is re-armed by this PR - 2026-10-08.`
