### Metadata

* **Related Spec:** `PROMPTKIT.md` (anchor: `## 7. Non-Negotiable Architecture Rules & Guardrails`), `docs/MAXIMS.md`, `workflows/sync.md` (anchor: `### Phase 1: Engine & Rule Audit`), `workflows/review.md` (anchor: `git rev-parse <fixed-point>`), `workflows/review.md` (anchor: `produces an empty diff`), `workflows/pr.md` (anchor: `BASE_REF="${BASE_REMOTE}/${TARGET_BASE}"`), `scripts/check-changelog-entry.sh` (anchor: `CHANGELOG_GATE|MISSING-BASE`), `docs/ADOPTION-GUIDE.md`
* **Priority:** `priority/p3`
* **Labels:** `type:feature`, `area:tooling`, `priority/p3`
* **Work Classification:** `L1` (invariant + read-only preflight, no workflow semantics change)

--------

## User Story & Context

As a developer using GitButler,
I want PromptKit to refuse deriving a base from a `gitbutler/workspace` synthetic commit and to detect stale Butler state,
So that the base-divergence class of incident cannot silently re-break installs, submodule links, or PR diffs.

### Scope: this issue now owns the GitButler guard exclusively

The guard previously appeared in **two** issues with contradictory claims about who owned it. This issue is now the single owner:

* **#549 task 2** previously specified "`pk:sync` preflight: detect workspace HEAD, refuse with recovery steps." That task was a strict subset of this issue's task 2 and has been **removed from #549**, which is now scoped to install-time structural asserts only.
* This issue's original line claiming complementary coverage ("`05-setup-assert` covers the install-time assert; this issue covers the standing invariant + sync-time detection") was accurate in principle but described an overlap that did not exist in the tasks. Now resolved: #549 owns install-time; this issue owns sync-time detection and the standing invariant.

### Two corrections to the previous draft

* **"Pinned-unpushed commit" is not a defect signal.** An unpushed commit is normal mid-workflow state and fires on every ordinary WIP commit. This issue previously listed `pinned-unpushed commit` as a detection target; that is removed. It may be reported as *context* when a base-deriving operation is refused, but never as a fault in its own right.
* **No repository precedent exists for this detection.** A repo-wide search for `gitbutler`, `virtual_branches`, `write-lock`, and `Butler` returns **zero** matches outside `.git`. The only `workspace` hits under `scripts/` and `.github/` are GitHub Actions' `${{ github.workspace }}` and test-fixture prose. This is greenfield tooling with no existing detector, fixture, or harness — which is why it is scoped as `p3` and why the detector, its fixture, and its harness must land together.

### What already exists (do not duplicate)

* **The base-deriving operations are enumerable and few.** Only three consume a base: `workflows/review.md` (anchor: `git rev-parse <fixed-point>`) (fixed-point diffs), `workflows/pr.md` (anchor: `BASE_REF="${BASE_REMOTE}/${TARGET_BASE}"`) (`BASE_REF`), and `scripts/check-changelog-entry.sh` (anchor: `git diff --name-only "$BASE...$HEAD"`) (`BASE...HEAD` range). `workflows/review.md` (anchor: `produces an empty diff`) already documents the empty-diff stall that a synthetic base produces.
* Detection is read-only by construction here: the preflight inspects Git state and reports. It never writes Butler state.

### Non-Negotiable Invariants

* **[ ] Linkable invariant:** one maxim-grade line in `docs/MAXIMS.md` ("never derive a base from a synthetic workspace commit") that `PROMPTKIT.md` and error messages can cite. Follow the existing maxim format with a canonical link.
* **[ ] Scope to base-deriving operations only.** The guard applies to `pk:sync`, `pk:review`, `pk:pr`, and the changelog range check. It does **not** gate ordinary commits, staging, or status reads — those do not derive a base and must remain unaffected.
* **[ ] Read-only detect:** the preflight never touches Butler state, never runs `but` commands, never rebases, and never writes to `virtual_branches.toml`. It reports and redirects.
* **[ ] Evidence-based refusal:** refuse only when a base is actually synthetic. A normal branch HEAD is silent (Scenario 1). If detection cannot establish evidence, report `UNKNOWN` and proceed — do not fail closed on a normal repository.
* **[ ] Never treat unpushed as corruption.** See corrections above.
* **[ ] Token figures repropagated:** this issue adds a reference row to `workflows/sync.md`, one of the six files summed into the core-six measurement. Run `bash scripts/measure-tokens.sh` (no `--strict`) and read its `Monolithic (core-6 subset derived)` and `Monolithic (full N-workflow set)` lines — even a prose-only addition moves the total. `scripts/tests/run-behavioral-contract-tests.sh` asserts the published cells equal measurement output, so re-measure and update `docs/BENCHMARKS.md` in the same PR (`docs/BENCHMARKS.md` (anchor: `| Core-six Lite subset | 6 | **30,966 tok** |`)).
* **[ ] Zero-runtime:** markdown invariant plus read-only evidence commands.

### Out of Scope

* GitButler integration, `but` command invocation, or Butler-state repair automation.
* Install-time structural asserts — owned by #549.
* Refusing commits or staging.

--------

## Implementation Tasks (The Build)

* [ ] 1. Add the invariant to `PROMPTKIT.md` §7 and `docs/MAXIMS.md`, with canonical links matching the existing maxim format. Record the ADR 0002 non-overlap statement if the invariant changes workflow semantics.
* [ ] 2. Implement a **read-only** synthetic-base detector. Establish what evidence is actually available and sufficient before coding:
  * the current HEAD is not reachable from any carrying branch (`git branch --contains HEAD` is empty for all real branches), and/or
  * the commit has no upstream and does not appear in any local branch tip.
  * Do **not** treat "unpushed" as sufficient evidence.
* [ ] 3. Apply the detector only at base-deriving points: `workflows/sync.md` (anchor: `### Phase 1: Engine & Rule Audit`), `workflows/review.md` (anchor: `git rev-parse <fixed-point>`), `workflows/pr.md` (anchor: `BASE_REF="${BASE_REMOTE}/${TARGET_BASE}"`), and `scripts/check-changelog-entry.sh` (anchor: `CHANGELOG_GATE|MISSING-BASE`). Print recovery steps (return to the carrying branch; rebase) with the invariant citation.
* [ ] 4. When detection yields insufficient evidence, report `UNKNOWN` and proceed — never block a normal repository.
* [ ] 5. Ship the detector, a fixture, and a test harness **in this issue**, since no precedent exists. Add the fixture to the shared manifests and both `.sh` / `.ps1` twins per `CONTRIBUTING.md` (anchor: `Behavioral Contract & Parity`).
* [ ] 6. Document in `docs/ADOPTION-GUIDE.md` (GitButler section) and `CHANGELOG.md` (`[Unreleased]`).

--------

## Acceptance Criteria (The Verifiable Proof)

### Scenario 1: Normal repository is silent

* Given a normal branch HEAD that is an ancestor of, or contained by, a carrying branch,
* When `pk:sync` runs and `pk:review` derives a diff,
* Then no Butler warning appears and no operation is refused.

### Scenario 2: Synthetic base is refused with recovery

* Given a HEAD that is a synthetic workspace commit with no carrying branch and no upstream,
* When `pk:review` attempts to derive a diff base,
* Then it refuses, cites the `docs/MAXIMS.md` invariant, and prints recovery steps. `pk:sync` reports the same finding.

### Scenario 3: Unpushed-but-valid commit is not a fault

* Given a normal carrying branch with unpushed commits,
* When `pk:review` derives a base,
* Then the operation proceeds normally. Unpushed state alone must never trigger refusal.

### Scenario 4: Insufficient evidence does not block

* Given a repository where the detector cannot establish synthetic-base evidence,
* When a base-deriving operation runs,
* Then it reports `UNKNOWN` and proceeds — no refusal, no false alarm.

### Scenario 5: Staging and committing stay unaffected

* Given any of the above repositories,
* When `pk:commit` runs,
* Then behavior is identical to today; the guard never gates staging or commit.

--------

## Automated Verification Command

```bash
bash scripts/tests/run-behavioral-contract-tests.sh
bash scripts/tests/run-pk-route-tests.sh
bash scripts/validate-references.sh .
pwsh -NoProfile -File scripts/tests/run-behavioral-contract-tests.ps1
```