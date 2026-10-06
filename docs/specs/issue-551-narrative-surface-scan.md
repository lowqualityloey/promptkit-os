### Metadata

* **Related Spec:** `workflows/commit.md`, `scripts/scan-staged-secrets.sh` + `.ps1` twin, `scripts/check-harness-security.sh` + `scripts/harness-security-paths.txt` + `scripts/harness-security-rules.txt` (externalized-rules precedent), `scripts/tests/run-staged-secret-scan-tests.sh` + `.ps1` twin, `.github/workflows/ci.yml`, `docs/ADOPTION-GUIDE.md`
* **Priority:** `priority/p2`
* **Labels:** `type:bug`, `area:tooling`, `priority/p2`
* **Work Classification:** `L1` (staged-index scan extension, no workflow semantics change)

--------

## User Story & Context

As a developer with narrative files tracked on a public branch,
I want the `pk:commit` staged gate to flag tracked narrative surface — absolute local paths, machine names, internal roadmaps —
So that `.gitignore` asymmetry cannot leak me. Observed in a downstream consumer repo: a tracked `memory.md` published an absolute `/home/<user>/…` path, and `handoff.md` narrated releases on public `main`, while `.gitignore` protects only *untracked* files and silently conceals the rest.

### Scope correction (why this was rewritten)

The previous draft's title promised **pre-push** protection while its tasks wired only `pk:commit` + CI, and its Out of Scope section covered only history rewriting — so pre-push was never explicitly excluded. It also specified detector *categories* with no patterns, and required an allowlist that no existing mechanism provides.

This issue is therefore scoped to the **staged index only**, matching what the repo actually implements.

### What already exists (do not duplicate)

* `scripts/scan-staged-secrets.sh` scans **secrets only**, and its boundary is the staged diff: `scripts/scan-staged-secrets.sh` (anchor: `diff --cached --name-only --diff-filter=ACMRT -z`) and `scripts/scan-staged-secrets.sh` (anchor: `diff --cached --no-ext-diff --no-textconv --unified=0 -- "$path"`). Neither twin reads the working tree; the `.ps1` twin mirrors this at `scripts/scan-staged-secrets.ps1` (anchor: `"diff", "--cached", "--name-only", "--diff-filter=ACMRT", "-z"`) and `scripts/scan-staged-secrets.ps1` (anchor: `"diff", "--cached", "--no-ext-diff", "--no-textconv", "--unified=0", "--", $path`). `workflows/commit.md` (anchor: `This working-tree scan does not replace the staged-index checks below.`) draws the line explicitly.
* Exit semantics are established and fail-closed: `exit 1` on detection (`scripts/scan-staged-secrets.sh` (anchor: `if ((scan_found)); then`); `scripts/scan-staged-secrets.ps1` (anchor: `if ($scanFound) { exit 1 }`)), `exit 2` on scan-incomplete (`scripts/scan-staged-secrets.sh` (anchor: `Staged secret scan could not run: AWK is unavailable.`); `scripts/scan-staged-secrets.ps1` (anchor: `function Stop-Scan {`)). Documented at `workflows/commit.md` (anchor: `no supported patterns were detected; continue.`).
* CI runs the scanner as the final command of a step (`.github/workflows/ci.yml` (anchor: `bash scripts/scan-staged-secrets.sh .`)), so any non-zero exit fails the job. There is **no** `continue-on-error` and no `|| true` anywhere under `.github/`.
* Externalized-rules precedent to copy: `scripts/harness-security-paths.txt` (`path|kind`) and `scripts/harness-security-rules.txt` (`RULE|scope|regex`), loaded by `scripts/check-harness-security.sh` (anchor: `for table in harness-security-paths.txt harness-security-rules.txt; do`). A missing rules file is fail-closed (`INCOMPLETE` → `exit 2`, `scripts/check-harness-security.sh` (anchor: `report INCOMPLETE RULES .; exit 2`)) and findings `exit 1` (`scripts/check-harness-security.sh` (anchor: `if [[ "$findings" -ne 0 ]]; then exit 1; fi`)).
* The only existing exemptions are hardcoded inline: the bracketed-placeholder pattern `^[<\[]` (`scripts/scan-staged-secrets.sh` (anchor: `if (password_val !~ /^[<\[]/) {`)) and an `.env.(example|template|sample|dist)` list embedded in a workflow snippet (`workflows/commit.md` (anchor: `excluding exact approved public templates like`)).
* Tracked markdown in this repo already contains absolute local paths — `docs/reviews/2026-10-02-pr495-review.md` (anchor: `/home/heyloey/.codex/worktrees/review-pr-495/promptkit-os`) and `docs/reviews/2026-10-02-pr496-review.md` (anchor: `/home/heyloey/.codex/worktrees/review-pr-496/promptkit-os`) (`/home/heyloey/.codex/worktrees/…`). They do not fire today because only *added* lines are scanned, but any edit touching those lines will re-fire. This repo tracks no `handoff.md` or `memory.md`; the leak being fixed is a downstream consumer problem.

### Non-Negotiable Invariants

* **[ ] Two-tier exit codes, never `0` on a finding:**

  | Finding class | Exit | CI effect | `pk:commit` effect |
  | :--- | :--- | :--- | :--- |
  | Secret (existing detectors) | `1` (unchanged) | job fails | halt (`workflows/commit.md` (anchor: `potential credential patterns were detected; halt and ask the developer to inspect and remove them locally.`)) |
  | Narrative surface (absolute path / hostname / internal roadmap) | `3` (**new**) | job fails | print `file:line` + remediation, then halt |
  | Scan could not complete | `2` (unchanged) | job fails | halt (`workflows/commit.md` (anchor: `the scan could not complete; halt and resolve the scan failure before committing.`)) |

  `exit 0` on a detected finding is prohibited. This is deliberate: CI's only channel is the process exit code (`.github/workflows/ci.yml` (anchor: `bash scripts/scan-staged-secrets.sh .`)), so a warn-level "exit 0 with a printed warning" would silently downgrade the whole gate to advisory. The `3` tier is what makes narrative findings enforceable without pretending they are secrets.
* **[ ] Scan boundary is the staged index, added lines only.** Reuse the exact `git diff --cached … --unified=0` form from `scripts/scan-staged-secrets.sh` (anchor: `diff --cached --name-only --diff-filter=ACMRT -z`) and `scripts/scan-staged-secrets.sh` (anchor: `diff --cached --no-ext-diff --no-textconv --unified=0 -- "$path"`); never scan the working tree or history.
* **[ ] Rules and allowlist are externalized data files**, modeled on `scripts/harness-security-paths.txt` / `scripts/harness-security-rules.txt`. A missing or unreadable rules file is fail-closed (`exit 2`), matching `scripts/check-harness-security.sh` (anchor: `report INCOMPLETE RULES .; exit 2`).
* **[ ] Allowlist is narrow and seeded.** Only paths proven safe by evidence are allowlisted. Seed with this repo's known-safe occurrences (`docs/reviews/2026-10-02-pr495-review.md` (anchor: `/home/heyloey/.codex/worktrees/review-pr-495/promptkit-os`), `docs/reviews/2026-10-02-pr496-review.md` (anchor: `/home/heyloey/.codex/worktrees/review-pr-496/promptkit-os`)) and PromptKit's own installer/template example paths.
* **[ ] Zero false positives on untouched content:** a path-only change must not re-flag pre-existing lines outside the staged diff.
* **[ ] Token figures repropagated:** this issue edits `workflows/commit.md`, one of the six files summed into the core-six measurement. Run `bash scripts/measure-tokens.sh` (no `--strict`) and read its `Monolithic (core-6 subset derived)` and `Monolithic (full N-workflow set)` lines — even a prose-only addition moves the total. `scripts/tests/run-behavioral-contract-tests.sh` asserts the published cells equal measurement output, so re-measure and update `docs/BENCHMARKS.md` in the same PR (`docs/BENCHMARKS.md` (anchor: `| Core-six Lite subset | 6 | **30,966 tok** |`)).
* **[ ] Reference integrity:** the new `docs/ADOPTION-GUIDE.md` guidance and the `workflows/commit.md` edits add prose, not links, but `bash scripts/validate-references.sh .` must still exit 0 with zero warnings — the behavioral contract asserts a zero-warning run.
* **[ ] Twin parity:** identical behavior in `.sh` and `.ps1` (`CONTRIBUTING.md` (anchor: `Script fixes must maintain full behavioral parity between Linux/macOS`); `PROMPTKIT.md` (anchor: `Every validation/test script ships as`)); new scripts join both CI syntax lists.

### Out of Scope

* **No `git push` / pre-push hook.** This repository has no hook-install surface — repo-wide there are zero matches for `hooksPath`, `.githooks`, `husky`, or any hook installation in `init.sh` / `init.ps1`. A pre-push gate is a separate concern.
* Rewriting history that already published paths (owner decision, force-push — surface as guidance only).
* Scanning git history, branches, or the working tree.
* Changing existing secret-detection semantics or exit codes `1` / `2`.

--------

## Implementation Tasks (The Build)

* [ ] 1. Add narrative-surface detectors to the staged scan (extend `scripts/scan-staged-secrets.sh` + `.ps1` twin, **or** add a `scan-narrative-surface` companion with both twins — do not replace the secret scanner):
  * absolute filesystem paths (`/home/…`, `/Users/…`, `/mnt/c/Users/…`, `C:\Users\…`)
  * machine/host names (must be project-configurable — see task 2; do **not** hardcode a hostname list)
  * internal roadmap / release-narration markers
* [ ] 2. Externalize detector patterns and the allowlist into data files mirroring the existing convention: `scripts/narrative-surface-paths.txt` (`glob|kind`) and `scripts/narrative-surface-rules.txt` (`RULE|regex|severity`). Missing/unreadable → `exit 2`. Provide a documented project-level override so a consumer repo can supply its own machine names and roadmap markers rather than editing the shipped file.
* [ ] 3. Implement the `exit 3` tier in both twins, and extend `scripts/tests/run-staged-secret-scan-tests.sh` (+ `.ps1`) with narrative cases. Note the harness currently asserts exact statuses at `scripts/tests/run-staged-secret-scan-tests.sh` (anchor: `"$status" -eq 1`) and `scripts/tests/run-staged-secret-scan-tests.sh` (anchor: `should fail closed when the repository cannot be scanned`); add explicit `exit 3` cases rather than loosening existing assertions.
* [ ] 4. Wire into the `pk:commit` gate (`workflows/commit.md`) and CI. Update `workflows/commit.md` (anchor: `no supported patterns were detected; continue.`) to document the `3` tier alongside `0/1/2`.
* [ ] 5. Register any new scripts in the `bash -n` list (`.github/workflows/ci.yml` (anchor: `bash -n init.sh`)) **and** the PowerShell `$syntaxFiles` list (`.github/workflows/ci.yml` (anchor: `$syntaxFiles = @(`)), or they ship unlinted.
* [ ] 6. Document `handoff.md` / `memory.md` local-only vs public guidance in `docs/ADOPTION-GUIDE.md`. Verified: that file currently has zero mentions of `handoff.md`, `memory.md`, or local-only narrative guidance, so this is new content rather than duplication. Keep `scripts/tests/run-behavioral-contract-tests.sh` (anchor: `assert_contains "workflows/commit.md" "Pre-Commit Secret & Hygiene Scan"`) green.
* [ ] 7. Update `CHANGELOG.md` (`[Unreleased]`), gated in CI by `scripts/check-changelog-entry.sh` (`.github/workflows/ci.yml` (anchor: `- name: Assert CHANGELOG Entry for Behavior-Surface Changes (Bash)`)).

--------

## Acceptance Criteria (The Verifiable Proof)

### Scenario 1: Happy Path

* Given a clean staged tree with no narrative-surface findings,
* When `pk:commit` runs,
* Then the scan passes silently and exits `0`.

### Scenario 2: Narrative finding blocks with a new exit code

* Given a staged tracked `.md` containing an added line with `/home/<user>/…`,
* When `pk:commit` runs,
* Then it exits `3` and prints the file, line, and remediation (relativize to a `$HOME`-relative form, or untrack). The `3` must fail the CI step (`.github/workflows/ci.yml` (anchor: `bash scripts/scan-staged-secrets.sh .`)) — assert this, do not assume it.

### Scenario 3: Allowlisted path does not fire

* Given a staged tracked `.md` whose absolute path is in the allowlist (e.g. an edit touching `docs/reviews/2026-10-02-pr495-review.md` (anchor: `/home/heyloey/.codex/worktrees/review-pr-495/promptkit-os`)),
* When `pk:commit` runs,
* Then it exits `0` with no finding.

### Scenario 4: Secrets still block at `1`

* Given a staged change containing a secret pattern,
* When `pk:commit` runs,
* Then it exits `1` exactly as before — the new tier must not alter secret semantics.

### Scenario 5: Missing rules file is fail-closed

* Given `scripts/narrative-surface-rules.txt` is absent or unreadable,
* When the scan runs,
* Then it exits `2`, matching `scripts/check-harness-security.sh` (anchor: `report INCOMPLETE RULES .; exit 2`), and never reports a pass.

### Scenario 6: Pre-existing content is not re-flagged

* Given a repository where a tracked `.md` already contains an absolute path on an unmodified line, and the staged diff does not touch it,
* When `pk:commit` runs,
* Then no finding is raised for that line.

--------

## Automated Verification Command

```bash
bash scripts/tests/run-staged-secret-scan-tests.sh
pwsh -NoProfile -File scripts/tests/run-staged-secret-scan-tests.ps1
bash scripts/tests/run-behavioral-contract-tests.sh
bash scripts/check-changelog-entry.sh
```

> Correction from the previous draft: `scripts/tests/run-behavioral-contract-tests.sh` does **not** exercise the secret scanner — its only scanner-related assertion is a documentation string check (`scripts/tests/run-behavioral-contract-tests.sh` (anchor: `assert_contains "workflows/commit.md" "Pre-Commit Secret & Hygiene Scan"`)). The harness that covers scan behavior is `scripts/tests/run-staged-secret-scan-tests.sh` (+ `.ps1`), which CI runs at `.github/workflows/ci.yml` (anchor: `run: bash scripts/tests/run-staged-secret-scan-tests.sh`) and `.github/workflows/ci.yml` (anchor: `run: pwsh -NoProfile -File .\scripts\tests\run-staged-secret-scan-tests.ps1`). The behavioral-contract suite is retained only for the `workflows/commit.md` doc contract.