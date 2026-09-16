# Contributing to PromptKit OS

Thank you for contributing to PromptKit OS! We welcome contributions that help improve engineering discipline, assistant workflow protocols, platform setup scripts, and quality gates.

---

## Contribution Expectations & Guidelines

When contributing to PromptKit OS, adhere to the following core principles:

1. **JIT (Just-In-Time) Specification**: Inspect and classify each issue before editing. Write a concise implementation spec (problem, root cause, affected files, public behavior impact, compatibility, verification, release impact) before implementing logical changes.
2. **Ceremony Model Alignment**: Follow PromptKit OS's 4-level task ceremony model defined in [`workflows/route.md`](./workflows/route.md):
   - **Level 0 (Direct)**: Trivial questions, doc fixes, formatting.
   - **Level 1 (Standard)**: Localized fixes and small self-contained features modifying source files directly without Task Record overhead.
   - **Level 2 (Controlled)**: Relational schema/data migrations, auth, permissions, breaking API contracts, or multi-component changes requiring a Local Task Record (`docs/tasks/<task-id>.md`).
   - **Level 3 (Release-Critical)**: Production releases, tag generation, or high-impact public contract changes requiring release candidate evaluation (`pk:ship`) and human approval.
3. **Atomic Conventional Commits**: Every change set must be staged as single-concern atomic commits following Conventional Commits format (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `perf:`, `chore:`). See [`workflows/commit.md`](./workflows/commit.md).
4. **Behavioral Contract & Parity**: Script fixes must maintain full behavioral parity between Linux/macOS (`init.sh`, Bash scripts) and Windows (`init.ps1`, PowerShell scripts).
5. **Non-Destructive Safety**: Setup scripts and workflows must preserve existing user content, fail loudly on malformed or duplicate marker blocks, and leave original files byte-for-byte unchanged on failure.
6. **Internal Specification Hygiene**: Public specifications live in `docs/specs/[specification].md`. Tool-local planning directories such as `.kiro/` are ignored and never published. Three `.kiro/specs` bundles (`agent-execution-control-handoff/`, `conventional-commit-versioning/`, `promptkit-sdlc-skill-adaptation/`) were tracked as historical planning evidence and have since been retired; they remain recoverable from git history. Dated release evaluations and Task Records that cite them are historical records and are deliberately left unedited.

---

## Validation Commands & Verification

Run these validation commands before opening a pull request. All verification gates must pass in both Bash and PowerShell environments.

### Bash (macOS / Linux / WSL)

```bash
# Validate Bash script syntax
bash -n init.sh
bash -n scripts/validate-execution-control.sh
bash -n scripts/validate-release-records.sh
bash -n scripts/validate-ci-triage.sh
bash -n scripts/tests/run-behavioral-contract-tests.sh
bash -n scripts/tests/run-init-safety-tests.sh

# Run safety & contract test suites
bash scripts/tests/run-init-safety-tests.sh
bash scripts/tests/run-behavioral-contract-tests.sh
bash scripts/tests/run-execution-control-fixtures.sh
bash scripts/tests/run-ci-triage-fixtures.sh

# Validate reference links and release records
bash scripts/validate-references.sh .
bash scripts/validate-release-records.sh --root scripts/tests/fixtures/release-records/valid --strict
bash scripts/validate-execution-control.sh --root .

# Self-application: this repository's own release records (see the exemption note below)
bash scripts/validate-release-records.sh --root . --strict
```

### PowerShell (Windows / Cross-Platform PowerShell 7)

```powershell
# Validate PowerShell script syntax
$syntaxFiles = @(
  "init.ps1",
  "scripts/validate-execution-control.ps1",
  "scripts/tests/run-execution-control-fixtures.ps1",
  "scripts/validate-release-records.ps1",
  "scripts/validate-ci-triage.ps1",
  "scripts/tests/run-ci-triage-fixtures.ps1",
  "scripts/tests/run-behavioral-contract-tests.ps1",
  "scripts/tests/run-init-safety-tests.ps1"
)
foreach ($file in $syntaxFiles) {
  $errors = @()
  [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $file), [ref]$null, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) { throw $errors }
}

# Run safety & contract test suites
pwsh -NoProfile -File .\scripts\tests\run-init-safety-tests.ps1
pwsh -NoProfile -File .\scripts\tests\run-behavioral-contract-tests.ps1
pwsh -NoProfile -File .\scripts\tests\run-execution-control-fixtures.ps1
pwsh -NoProfile -File .\scripts\tests\run-ci-triage-fixtures.ps1

# Validate reference links and release records
pwsh -NoProfile -File .\scripts\validate-references.ps1 -PromptKitDir .
pwsh -NoProfile -File .\scripts\validate-release-records.ps1 -Root .\scripts\tests\fixtures\release-records\valid -Strict

# Self-application: this repository's own release records (see the exemption note below)
pwsh -NoProfile -File .\scripts\validate-release-records.ps1 -Root . -Strict
```

### Release-Record Self-Application & Historical Exemption

`validate-release-records` validates every `docs/releases/*.md` in the target
root, which includes this repository's own release evidence. Run it against `.`
before opening a pull request.

Two records are exempt and are expected to report findings:

| Record | Reason |
| :--- | :--- |
| `docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md` | Written against the pre-1.1.0 record schema, before the repository rename. It uses retired field labels (`Approved SemVer`, `Approved Release Commit`) and a retired `Evaluation Status` vocabulary. |
| `docs/releases/2026-09-08-v1.0.0-release-notes-draft.md` | A v1.0.0 working draft predating the canonical `Release Notes Record` field set. |

These are retained verbatim as immutable historical evidence. Backfilling them
would mean inventing release evidence that was never recorded, and
`2026-09-10-v1.1.0-evaluation.md` links the first of them by path as
`Latest Approved Release Record`, so relocating them would break a live
cross-record link. Treat findings against these two files as expected; treat
findings against any other record as a regression.

Every release from v1.1.0 onward must pass cleanly, including the human-readable
`*-release-notes.md` files, which carry the same canonical field set as their
companion `*-release-notes-record.md`.

---

## Workflow Ownership & Authority Matrix

| Stage / Purpose | Owning Workflow | Canonical Authority |
| :--- | :--- | :--- |
| **Ceremony Classification & Routing** | [`workflows/route.md`](./workflows/route.md) | Canonical guide for Levels 0–3, escalation, upgrade/downgrade rules |
| **Code Review & Quality Smells** | [`workflows/review.md`](./workflows/review.md) | Senior two-axis code review (Spec Fidelity vs Technical Standards) |
| **Atomic Git Staging & Commits** | [`workflows/commit.md`](./workflows/commit.md) | Conventional Commits & secret leak scanning |
| **Pull Requests & Evidence** | [`workflows/pr.md`](./workflows/pr.md) | PR body compilation & verification evidence audit |
| **State Compaction & Handoffs** | [`workflows/checkpoint.md`](./workflows/checkpoint.md) | `docs/STATE.md` synchronization & session continuity |
| **Release Evaluation & Approval** | [`workflows/ship.md`](./workflows/ship.md) | PromptKit OS release candidate evaluation & evidence review |

---

## Workflow Lifecycle: Addition & Retirement Policy

The surface is 23 workflows by design, not by accident. Growth is gated and retirement has a path — see [ADR 0002](./docs/adrs/0002-workflow-lifecycle-policy.md) for the full policy and the v1.7.0 `pk:profile` worked example.

- **Proposing the 24th workflow**: state non-overlap (which existing workflows were considered and why not), ceremony fit, all artifacts shipped in the same PR (workflow file, `setup.md` row, directive entry or recorded omission, WORKFLOW-MAP/README/FAQ updates, assertions in both test twins), and strict token-gate results.
- **Retiring a workflow or alias**: breaking-change path — justification plus `CHANGELOG.md` `BREAKING CHANGE` notice with migration path, count-guard updates in both twins (suite stays green), directive exception-list sync, and reference cleanup (`setup.md`, README, WORKFLOW-MAP, FAQ, QUICKSTART) with `validate-references.sh` passing.
- **This policy retires nothing.** Count stays at 23; the drift guard is untouched.

---

## Maintainer Guidance: Release-Evidence Lifecycle

The release-evidence policy applies only to maintainers evaluating candidates for the PromptKit OS repository. It documents how PromptKit OS evaluates a candidate and records an approval decision; it does not impose PromptKit OS Conventional Commit, SemVer, release-note, changelog, tag, remote, publication, deployment, or rollback requirements on repositories that consume PromptKit OS.

### Accountable lifecycle and handoffs

The lifecycle is an accountable handoff, not an automatic release pipeline:

`Planner/Architect → Engineer → QA/Reviewer → Release Coordinator`

| Handoff | Required evidence | Boundary |
| :--- | :--- | :--- |
| **Planner/Architect → Engineer** | Affected Public PromptKit Contract, observable before/after behavior, proposed impact, and Migration and Upgrade Guidance when breaking. | Planning records intent; it does not implement or approve a release. |
| **Engineer → QA/Reviewer** | One complete, reversible Conventional Commit plus Contract Impact Evidence, or an explicit Maintenance Commit declaration stating no intentional public-contract change. | Commit labels such as `feat`, `fix`, and `perf` do not determine SemVer impact. |
| **QA/Reviewer → Release Coordinator** | Verified Release Range, normalized Effective Change Set, evidence-based candidate rationale, note-coverage result, and named blockers. | QA records findings and correction requirements; a calculable candidate is still preliminary. |
| **Release Coordinator via `pk:ship`** | Evaluation ID, candidate provenance, QA result, reviewed notes, approval decision, and Release-consistency results. | Approval is an internal record; tag, release, publication, remote, deployment, and rollback actions remain separate human decisions. |

`pk:checkpoint` can project the Evaluation ID, Release Candidate Commit, preliminary candidate, QA status, blockers, source records, and requested next decision into a handoff. A checkpoint is never approval and cannot tag, publish, push, deploy, or roll back.

### Candidate evaluation and approval

1. The Release Coordinator assigns one stable **Evaluation ID** and uses the latest complete Approved Release Record as the immutable Version Source of Truth. With no prior approved record, the evaluation records `First Release: true` and its all-history start.
2. The evaluation records an exclusive prior baseline or First Release start and an inclusive **Release Candidate Commit** at the end of a reproducible Release Range. Candidate absence, duplication, or out-of-range membership is a blocker.
3. QA/Reviewer normalizes merge, squash, duplicate, full-revert, and partial-revert history into one Effective Change Set. That same set feeds both the preliminary candidate and filtered notes.
4. Contract Impact Evidence determines impact: additive is `minor`, corrective is `patch`, breaking with Migration and Upgrade Guidance is `major`, breaking without guidance is blocked, and an explicit Maintenance Commit is `none`. Greatest impact uses `major > minor > patch`. A First Release with additive public impact proposes core candidate `1.0.0`.
5. The SemVer Candidate Record remains **preliminary** and retains its Evaluation ID, candidate commit, supporting evidence, range, rationale, and any Prerelease Identifier. Promotion preserves that provenance and does not become approval automatically.
6. An empty eligible range requires an explicit Release Coordinator decision to defer or approve a documented no-contract-change release. It is never an automatic patch release.

### Release notes and changelog drafts

The filtered **Public Release Notes** contain one note for each distinct effective user-observable Public PromptKit Contract change. Breaking notes include Migration and Upgrade Guidance. **Maintenance Release Notes** are clearly labeled `Maintenance` and describe no intentional public-contract change without claiming a SemVer increment. Duplicate changes appear once, fully cancelling reverts appear in neither candidate nor public notes, and partial reverts are noted only when new evidence shows residual impact.

For each reviewed Public or Maintenance Release Note, create one explicit draft Changelog Entry labeled **unpublished** or **not published**. Draft entries are evidence only. Changelog publication is a separate human decision and is never performed by documentation, validation, QA, or a passing CI job.

### Human approval and external actions

The Approved Release Record links the same Evaluation ID across the candidate, range, QA review, notes, and consistency results. It records the approved version and tag string, candidate commit, range, candidate rationale, QA result, approval decision/date/coordinator, and Release-consistency results. A version different from the preliminary candidate requires a non-empty rationale, and the approved tag must encode the approved version.

The Release Coordinator separately and explicitly decides whether to create a tag, create a hosted release, publish a changelog, perform remote operations, trigger deployment, or execute rollback. One decision does not imply another. No candidate, QA result, checkpoint, validator, or empty blocker list authorizes any of these actions. See [`pk:commit`](./workflows/commit.md), [`pk:checkpoint`](./workflows/checkpoint.md), [`pk:ship`](./workflows/ship.md), and [`docs/WORKFLOW-MAP.md`](./docs/WORKFLOW-MAP.md) for the operating details.

---

## Release Boundaries & Storage

Release evidence for PromptKit OS is recorded in `docs/releases/`. Official release notes and tarballs are published via GitHub Releases. The project does not use a separate root `CHANGELOG.md` file to prevent competing release schemas.
