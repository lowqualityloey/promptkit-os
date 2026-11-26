# Task Record: Release-archive export packaging (issue #787)

<a id="TASK-2026-11-26-issue-787-archive-export-packaging"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-26-issue-787-archive-export-packaging`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Ship the consumer install surface only in release archives: mark the maintainer-only trees plus .gitattributes itself export-ignore, rewire every relative Markdown link that a shipped document points into an excluded tree to a canonical GitHub URL, and add Bash and PowerShell fixture twins that extract git archive HEAD, assert the exclusions and the absence of dangling relative links, install from the extracted tree, and run the setup, doctor, and reference validators inside it. Preserve scripts/verify-release-archive.py's commit-binding comparison and make no retroactive change to historical tags.`
- **External Reference (Optional)**: `GitHub issue #787`
- **Owner / Actor**: `Release Coordinator (approver) + Sisyphus (executor)`
- **Execution Scope**: `promptkit-os repository; .gitattributes, the ten shipped Markdown files that carried links into maintainer-only trees, scripts/tests/run-release-archive-export-tests.sh + .ps1 twin, .github/workflows/ci.yml wiring, docs/BENCHMARKS.md figure restatement, CHANGELOG.md, and this record. Local implementation and verification, then one implementation commit and one documentation-only provenance commit on a dedicated branch.`
- **Approval Boundary**: `Local implementation, verification, and commits on a dedicated branch only. Push, PR, merge, force-push, squash/rebase/amend, tag, release, npm publication, and issue closure remain unauthorized.`
- **Created**: `2026-11-26`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Make a tagged release archive a clean consumer artefact: exclude every maintainer-only tree, leave no dangling relative link in the shipped documents, and prove by fixture that the extracted tree installs and validates on its own.`
- **In Scope**:
  - `.gitattributes` — export-ignore block for `benchmarks/`, `docs/internal/`, `docs/releases/`, `docs/tasks/`, `docs/reviews/`, `docs/archive/`, `docs/tests/`, `scripts/tests/`, `.github/`, and `.gitattributes` itself
  - `.github/workflows/ci.yml` — fixture wiring in the `linux-code-b` and `windows-code-a` jobs
  - `docs/HOST-CONFORMANCE.md` — relative-link rewiring (30 links)
  - `docs/BENCHMARKS.md` — relative-link rewiring, re-propagated figures, and the documentation-only provenance restatement
  - `docs/BEHAVIORAL-EVAL.md` — relative-link rewiring (2 links)
  - `docs/ENFORCEMENT.md` — relative-link rewiring (1 link)
  - `docs/MIGRATION.md` — relative-link rewiring (1 link)
  - `docs/token-efficiency-review.md` — relative-link rewiring (1 link)
  - `SECURITY.md` — relative-link rewiring (1 link)
  - `protocols/context-economy.md` — relative-link rewiring (1 link)
  - `workflows/ship.md` — relative-link rewiring (1 link)
  - `CHANGELOG.md` — one `[Unreleased]` / `### Fixed` entry plus relative-link rewiring (3 links)
  - `scripts/tests/run-release-archive-export-tests.sh` — Bash archive-export fixture
  - `scripts/tests/run-release-archive-export-tests.ps1` — PowerShell twin of the archive-export fixture
  - `docs/tasks/TASK-2026-11-26-issue-787-archive-export-packaging.md` — this record
- **Explicit Non-Goals**:
  - `No retroactive mutation of historical tags or their archives.`
  - `No change to install behaviour, workflow routing, protocol content, or template inventories.`
  - `No new dependency, network service, or release-tooling subsystem.`
  - `No edit to scripts/verify-release-archive.py, whose archive comparison already honours export-ignore on both sides.`
- **Dependencies**: `Issue #783's ci.yml edits (staged-secret-scan and windows-code-d) do not touch linux-code-b or windows-code-a, so the wiring merges without conflict; issue #788 must land after this change because it is the last content change to the measured directive templates.`
- **Risk**: `Medium — an over-broad export-ignore pattern could strip a file the installer needs, and the link rewiring changes a measured input (workflows/ship.md), which moves the published token figures.`
- **Verification Condition**: `git archive HEAD excludes the nine trees and .gitattributes while retaining init.sh, init.ps1, PROMPTKIT.md and the workflow/protocol/template trees; the extracted file count is at least 80% below the tracked count; no relative Markdown link in any extracted file resolves into an excluded prefix; the extracted tree installs with init.sh and init.ps1 and passes check-setup-assert, check-doctor, and validate-references --strict; both archive-export fixture twins report 32/32; run-release-archive-verification-fixtures.sh, run-reference-link-tests.sh, run-init-safety-tests.sh, validate-references.sh --strict, the behavioral-contract twins, the changelog gate, and git diff --check are all green.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `The contents of a released PromptKit archive and the resolvability of links in the consumer-facing documentation set.`
- **Contract Impact Evidence ID / Path**: `.gitattributes, scripts/tests/run-release-archive-export-tests.sh, scripts/tests/run-release-archive-export-tests.ps1, scripts/verify-release-archive.py.`
- **Supporting Planning / Review Record**: `This record; GitHub issue #787.`
- **User-Observable Before Behavior**: `A tarball built from a tag carried benchmarks/, docs/internal/ (including a session transcript and a repository bundle), docs/releases/, docs/tasks/, docs/reviews/, docs/archive/, docs/tests/, scripts/tests/ (including evaluation answer keys), and .github/ into the consumer .promptkit/, and 49 relative links in ten shipped documents pointed into those trees, so every one of them dangled after extraction.`
- **User-Observable After Behavior**: `A tarball built from a tag carries the consumer install surface only — 284 files against 2,885 tracked, a reduction above the issue's 80% bar — and every relative link in the shipped documents resolves.`
- **Impact Classification**: `User-Facing Packaging Change`
- **Proposed SemVer Candidate Impact**: `patch`
- **Impact Rationale**: `The archive loses files that no consumer path referenced and the surviving documents link to canonical URLs instead of relative ones; no command, protocol, template, or install step changes.`
- **Migration and Upgrade Guidance**: `N/A — existing installs are unaffected; a fresh archive simply contains less.`
- **Maintenance Commit Declaration**: `N/A — an intentional packaging correction, not debt.`

## 4. Acceptance Criteria

- [x] **AC-1**: `git archive HEAD excludes benchmarks/, docs/internal/, docs/releases/, docs/tasks/, docs/reviews/, docs/archive/, docs/tests/, scripts/tests/, .github/, and .gitattributes, and cuts the extracted file count by more than 80% (284 of 2,885 tracked).`
- [x] **AC-2**: `Zero relative Markdown links in shipped documentation target an export-ignored tree, verified mechanically inside an extracted archive by both fixture twins.`
- [x] **AC-3**: `Installing from the extracted tree with init.sh and with init.ps1 passes check-setup-assert, check-doctor, and validate-references --strict inside that tree.`
- [x] **AC-4**: `scripts/tests/run-release-archive-verification-fixtures.sh and package/test/smoke.sh remain green (the courier smoke self-skips without PROMPTKIT_VERSION).`

## 5. Execution Policy and State

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion, missing authorization for a gated action, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically enforce checkpoint deadlines; timing remains a manual protocol limitation.`
- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-26`
- **Current Actor**: `Sisyphus`
- **Next Action**: `Commit the implementation with the figure updates, then land the documentation-only provenance restatement; merge remains unauthorized.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-11-26 | Sisyphus | Task initialized from the coordinator's Wave C1 authorization. | Coordinator brief |
| planned | in_progress | 2026-11-26 | Sisyphus | Measured the archive, enumerated the stranded links, and applied the export-ignore block and link rewiring. | Section 6 |
| in_progress | awaiting_review | 2026-11-26 | Sisyphus | Both fixture twins pass 32/32, the archive slimming is measured, and every gate is green; publication awaits the two commits. | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `.gitattributes`
  - `.github/workflows/ci.yml`
  - `CHANGELOG.md`
  - `SECURITY.md`
  - `docs/BEHAVIORAL-EVAL.md`
  - `docs/BENCHMARKS.md`
  - `docs/ENFORCEMENT.md`
  - `docs/HOST-CONFORMANCE.md`
  - `docs/MIGRATION.md`
  - `docs/token-efficiency-review.md`
  - `protocols/context-economy.md`
  - `workflows/ship.md`
  - `scripts/tests/run-release-archive-export-tests.sh`
  - `scripts/tests/run-release-archive-export-tests.ps1`
  - `docs/tasks/TASK-2026-11-26-issue-787-archive-export-packaging.md`
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `Archive slimming: 2,885 tracked files, 284 extracted, 90%+ excluded. Stranded-link scan over the working tree: 187 Markdown files checked, 0 relative links resolving into an excluded prefix (48 before the 49th was restored by fixing a .lstrip(./) bug that mangled .github/). Fixture twins on a throwaway tree commit: Bash SUMMARY|passed=32|failed=0 and PowerShell SUMMARY|passed=32|failed=0 (extracted=284, tracked=2884 at that commit). validate-references.sh . --strict exit 0; run-reference-link-tests.sh Passed: 10 | Failed: 0; run-release-archive-verification-fixtures.sh PASS for matching-commit archive and PASS for the different-commit rejection; run-init-safety-tests.sh exit 0; git diff --check clean. The behavioral-contract suite initially failed 3 assertions because the rewired workflows/ship.md line grew 52 bytes (+13 tok); after re-measuring, docs/BENCHMARKS.md now publishes 119,972 tok for the full set, 17,308/16,302 for pk:ship, the 7,453/8,459 savings, and the 20,046-34,866 turbo range, with the §9 tokenizer row moved to 6,014 / 4,721 / 4,724 / 0.785.`
- **CI Evidence**: `Pending — the branch is not pushed; the two new steps are wired into linux-code-b and windows-code-a and the workflow parses with 12 jobs.`
- **Review Evidence**: `Local gates only; no independent review requested.`
- **Commit Evidence**: `Two commits planned on chore/787-export-ignore-packaging: the implementation commit carrying every file and figure, then a documentation-only commit that restates the docs/BENCHMARKS.md:3 provenance anchor to the implementation SHA because a commit cannot contain its own SHA.`
- **Pull Request Evidence**: `Pending.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `None.`
- **Completion State**: `awaiting_review`
- **Acceptance Results**: `AC-1 Pass; AC-2 Pass; AC-3 Pass; AC-4 Pass (courier smoke self-skips without PROMPTKIT_VERSION, by design).`
- **Changed-File Summary**: `Mark the maintainer-only trees export-ignore, rewire the 49 stranded links to canonical URLs, add archive-export fixture twins with CI wiring, and re-propagate the token figures the rewritten workflows/ship.md line moved.`
- **Completion Exception**: `package/test/smoke.sh self-skips without PROMPTKIT_VERSION because it exercises the npm courier over the network; the archive-side contract is covered by the new fixtures, and the issue's AC-4 keeps the smoke run for release time.`
- **Completion Decision and Timestamp**: `Acceptance criteria pass on both surfaces within the environment's limits; the implementation and provenance commits remain to be created — 2026-11-26.`
