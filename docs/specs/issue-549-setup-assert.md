### Metadata

* **Related Spec:** `protocols/setup.md`, `init.sh` **+ `init.ps1` twin**, `package/bin/promptkit-os.js`, `scripts/check-harness-security.sh`, `docs/ADOPTION-GUIDE.md`, `scripts/tests/run-init-safety-tests.sh`
* **Priority:** `priority/p2`
* **Labels:** `type:bug`, `area:tooling`, `priority/p2`
* **Work Classification:** `L1` (installer hardening, no workflow semantics change)

--------

## User Story & Context

As a developer installing or restoring PromptKit OS by **any** documented method,
I want the installer to verify that its own engine tree is structurally sound and complete,
So that a broken or partial install fails loudly with the correct remedy instead of printing success.

### Scope correction (why this was rewritten)

The previous draft asserted, unconditionally, that `.gitmodules` exists, that `git ls-files -s .promptkit` shows a gitlink, and that `git submodule status` is clean. That assertion is valid for exactly **one** of the five documented install doors and would falsely reject the other four — including the one the README recommends. It also hardcoded `.promptkit` while `promptkit/` is an equally supported layout.

The original synthetic-base guard ("refuse a workspace-HEAD that is not a real branch tip") was removed from this issue: it is a strict subset of #552 task 2, and #552 owns it. This issue is now purely the install-time structural assert.

### Documented install modes (all five must pass)

| Mode | Evidence |
| :--- | :--- |
| Git submodule (canonical) | `README.md` (anchor: `git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh`); `QUICKSTART.md` (anchor: `git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit`); `docs/ADOPTION-GUIDE.md` (anchor: `Add PromptKit as a tracked submodule and initialize`); `FAQ.md` (anchor: `git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --balanced`) |
| npx courier (**recommended default**) | `README.md` (anchor: `# Recommended (zero prerequisite setup):`); `README.md` (anchor: `The npm package is a **courier, not a dependency**`); `QUICKSTART.md` (anchor: `# Recommended (zero prerequisite setup):`); `QUICKSTART.md` (anchor: `The npm package is a **courier, not a dependency**`); `package/README.md` (anchor: `This npm package is the **courier**, not the product`) |
| Personal/local clone, untracked | `docs/ADOPTION-GUIDE.md` (anchor: `submodule (can be personal, not tracked)`); `FAQ.md` (anchor: `# Install locally (not committed to repo)`); `QUICKSTART.md` (anchor: `git -C .promptkit pull origin main && bash .promptkit/init.sh`); `FAQ.md` (anchor: `**Fix**: Try manual installation:`) |
| Running from a checkout / standalone vault | `protocols/setup.md` (anchor: `the directory containing the installed kit`); `protocols/setup.md` (anchor: `vs *standalone vault*`); `init.sh` (anchor: `PROJECT_ROOT="$(pwd -P)"`) |
| Partial copy (copy individual protocols) | `docs/ADOPTION-GUIDE.md` (anchor: `Copy to your project root`); `docs/ADOPTION-GUIDE.md` (anchor: `**"Can I adopt partially?"** Yes.`); `protocols/setup.md` (anchor: `Kit templates and scripts are read-only sources`) |

Additionally, the kit directory may be `.promptkit/` **or** `promptkit/` (`protocols/setup.md` (anchor: `PromptKit OS is located in`); `init.sh` (anchor: `KIT_DIR_REL="${SCRIPT_DIR#$PROJECT_ROOT/}"`)), and `init.sh` resolves `KIT_DIR_REL` from `SCRIPT_DIR`, so the assert must use the resolved kit path — never a hardcoded `.promptkit`.

### What already exists (do not duplicate)

* `init.sh` (anchor: `if grep -qE "^[[:space:]]*<!-- PROMPTKIT_START -->[[:space:]]*${CR}?$" "$target" 2>/dev/null; then has_start=1; fi`) detects installs by grepping `PROMPTKIT_START`. It contains **no** reference to `gitmodules`, `git ls-files`, or `git submodule` — install-mode detection does not exist yet.
* `package/bin/promptkit-os.js` (anchor: `const isSubmoduleInstall = fs.existsSync(path.join(kitDir, ".git"))`) already discriminates install modes via that check and branches its error text on the result. **Reuse this discriminator; do not invent a second one.**
* `scripts/check-harness-security.sh` (anchor: `GIT_OPTIONAL_LOCKS=0 git --git-dir="$root/.git" --work-tree="$root"`); `scripts/check-harness-security.sh` (anchor: `if [[ "$status" != 0 ]]; then report INCOMPLETE GIT_TRACKING "$relative"`) — the house pattern for git probes: a scoped git helper with explicit `--git-dir`/`--work-tree`, a three-way exit-status branch (0 / 1 / unexpected), and a fail-closed `INCOMPLETE` result for unexpected status.
* `init.sh` (anchor: `if [[ "${PROMPTKIT_NO_PREFLIGHT:-}" == "1" ]]; then`); `init.sh` (anchor: `Preflight opt-out: PROMPTKIT_NO_PREFLIGHT=1 skips advisory local security inspection`) — the existing advisory preflight gate with the `PROMPTKIT_NO_PREFLIGHT=1` opt-out, the natural home and opt-out for this assert.

### Non-Negotiable Invariants

* **[ ] Mode-aware, never mode-assuming:** the assert classifies the install door first and asserts only what is true for that door. A wrong-mode assertion is a defect, not a warning.
* **[ ] Never print success on an unmeasured result:** an unexpected git exit status is `INCOMPLETE`, never `PASS`.
* **[ ] Resolved kit path only:** all probes use `SCRIPT_DIR` / `KIT_DIR_REL` (`init.sh` (anchor: `KIT_DIR_REL="${SCRIPT_DIR#$PROJECT_ROOT/}"`)), so both `.promptkit/` and `promptkit/` layouts work.
* **[ ] Advisory opt-out honored:** `PROMPTKIT_NO_PREFLIGHT=1` downgrades this check to advisory, consistent with the existing preflight.
* **[ ] Token figures repropagated:** this issue adds a reference row to `workflows/route.md`, one of the six files summed into the core-six measurement. Run `bash scripts/measure-tokens.sh` (no `--strict`) and read its `Monolithic (core-6 subset derived)` and `Monolithic (full N-workflow set)` lines — even a prose-only addition moves the total. `scripts/tests/run-behavioral-contract-tests.sh` asserts the published cells equal measurement output, so re-measure and update `docs/BENCHMARKS.md` in the same PR (`docs/BENCHMARKS.md` (anchor: `| Core-six Lite subset | 6 | **30,966 tok** |`)).
* **[ ] Twin parity:** identical behavior in `init.ps1` (`CONTRIBUTING.md` (anchor: `**Behavioral Contract & Parity**`); `PROMPTKIT.md` (anchor: `Bash/PowerShell twin parity`)).

### Out of Scope

* Synthetic-base and base-derivation guards — owned by #552.
* Changing `.gitignore` defaults or documented install guidance.
* Repairing a broken install automatically; this issue reports and prints the remedy.

--------

## Implementation Tasks (The Build)

* [ ] 1. Classify the install door in `init.sh` (+ `init.ps1` twin), using the resolved kit path and mirroring `package/bin/promptkit-os.js` (anchor: `const isSubmoduleInstall = fs.existsSync(path.join(kitDir, ".git"))`):
  * **courier** — `<kit>/.git` absent (tarball extract, `package/bin/promptkit-os.js` (anchor: `spawnSync("tar", ["-xzf", tarPath, "-C", dest, "--strip-components=1"], { stdio: "inherit" });`))
  * **direct clone** — `<kit>/.git` present, kit path absent from the host index
  * **submodule** — `.gitmodules` contains the kit path **and** `git ls-files -s <kit>` reports mode `160000`
  * **standalone / checkout** — kit root equals the project root (`protocols/setup.md` (anchor: `the directory containing the installed kit`))
  * **partial copy** — expected PromptKit files absent from the kit tree
* [ ] 2. Assert per door, and only per door:
  * **courier** → assert tree completeness (`templates/project-profile-template.md`, `workflows/route.md`, `scripts/`). Do **not** assert `.gitmodules` or a gitlink; neither exists by construction.
  * **direct clone** → assert `<kit>` is a valid repo and print `git -C <kit> pull origin main` as the update path. Do **not** assert `.gitmodules`.
  * **submodule** → assert `git submodule status` reports in-sync for the kit path.
  * **standalone / checkout** → skip submodule asserts entirely; assert tree completeness only.
  * **partial copy** → report the missing PromptKit files explicitly rather than asserting Git structure.
* [ ] 3. Follow the probe style at `scripts/check-harness-security.sh` (anchor: `GIT_OPTIONAL_LOCKS=0 git --git-dir="$root/.git" --work-tree="$root"`); `scripts/check-harness-security.sh` (anchor: `if [[ "$status" != 0 ]]; then report INCOMPLETE GIT_TRACKING "$relative"`): scoped git invocation, three-way status branch, fail-closed `INCOMPLETE` on unexpected status. Never a bare boolean.
* [ ] 4. Place the assert **after** `COMMIT_SUCCESS=1` (`init.sh` (anchor: `COMMIT_SUCCESS=1`)) and before the success banner (`init.sh` (anchor: `PromptKit OS successfully configured for $PROJECT_ROOT!`)) so a failing assert cannot trigger the `EXIT` rollback trap (`init.sh` (anchor: `trap 'if [[ "$COMMIT_SUCCESS" -eq 0 ]]; then rollback; else rm -rf "$BACKUP_DIR" "$STAGING_DIR"; fi' EXIT`)) on an otherwise-complete install. PowerShell equivalent: after the `try/catch/finally` block closes (`init.ps1` (anchor: `Remove-Item -LiteralPath $backupDir -Recurse -Force -ErrorAction SilentlyContinue`)), outside the rollback region (`init.ps1` (anchor: `# 7. Transactional Commit with Rollback (F07 - P2)`)), before the success banner (`init.ps1` (anchor: `PromptKit OS successfully configured for $ProjectRoot!`)). The `.sh` and `.ps1` placements are structurally asymmetric by necessity — do not paper over that.
* [ ] 5. Emit machine-readable pipe-delimited output matching the existing `PREFLIGHT|` convention (`init.sh` (anchor: `PREFLIGHT|SKIPPED|USER_OPT_OUT`); `init.sh` (anchor: `PREFLIGHT|ADVISORY|Review findings or incomplete checks; installation continues`); `init.ps1` (anchor: `PREFLIGHT|INCOMPLETE|SCANNER_UNAVAILABLE`)), e.g. `ASSERT|<door>|<check>|<OK|FAIL|INCOMPLETE|SKIP>`.
* [ ] 6. Cover all five doors in `scripts/tests/run-init-safety-tests.sh` (+ `.ps1` twin), including the courier and partial-copy fixtures that the previous draft would have failed.
* [ ] 7. Keep `scripts/tests/run-behavioral-contract-tests.sh` (anchor: `assert_contains "README.md" "courier, not a dependency" "README states the courier contract"`); `scripts/tests/run-behavioral-contract-tests.sh` (anchor: `assert_contains "README.md" "git submodule add" "Submodule path stays first-documented and canonical"`) green — it pins the README strings "courier, not a dependency" and "git submodule add". Any documentation edit in this issue must preserve them.
* [ ] 8. Update `CHANGELOG.md` (`[Unreleased]`).

### Documentation corrections required by this issue

* `PROMPTKIT.md` has **no** restore recipe and **no** `engine pinned at v1.11.0` line (`PROMPTKIT.md` (anchor: `## 7. Non-Negotiable Architecture Rules & Guardrails`) is that heading). The previous draft's task 3 targeted a nonexistent recipe. Drop it, or add a genuinely new recipe section — do not "correct" text that does not exist.
* The documented submodule update recipe is `git submodule update --remote --merge .promptkit` (`QUICKSTART.md` (anchor: `git submodule update --remote --merge .promptkit`)). The previously cited `git submodule update --init --recursive` does not appear anywhere in the repository.

--------

## Acceptance Criteria (The Verifiable Proof)

### Scenario 1: Every documented door passes

* Given one install of each of the five documented modes, including the npx courier and a `promptkit/` (non-dot) submodule layout,
* When the installer finishes,
* Then each install reports `OK` for its own door and none reports a false failure.

### Scenario 2: Genuinely broken kit tree fails loudly

* Given a kit directory missing `workflows/route.md` and `templates/project-profile-template.md`,
* When the installer finishes,
* Then it reports `FAIL` naming each missing file and prints the remedy — and never prints the success banner.

### Scenario 3: Unexpected git status is fail-closed

* Given a git invocation that exits with an unexpected status (not 0, not 1),
* When the assert runs,
* Then it reports `INCOMPLETE`, not `OK`, per `scripts/check-harness-security.sh` (anchor: `if [[ "$status" != 0 ]]; then report INCOMPLETE GIT_TRACKING "$relative"`).

### Scenario 4: Opt-out honored

* Given `PROMPTKIT_NO_PREFLIGHT=1`,
* When the installer runs,
* Then the assert is reported as advisory and installation proceeds.

--------

## Automated Verification Command

```bash
bash scripts/tests/run-init-safety-tests.sh
bash scripts/tests/run-behavioral-contract-tests.sh
bash scripts/validate-references.sh .
pwsh -NoProfile -File scripts/tests/run-init-safety-tests.ps1
```

> Note: `scripts/validate-references.sh` (anchor: `PROMPTKIT_DIR="${1:-.promptkit}"`); `scripts/validate-references.sh` (anchor: `echo "❌ ERROR: PromptKit directory not found: $PROMPTKIT_DIR"`) — requires the kit-root argument (`.` in-repo). It defaults to `.promptkit`, which does not exist in this repository, and exits 1 if that directory is absent. `.github/workflows/ci.yml` (anchor: `bash scripts/validate-references.sh .`) passes `.` explicitly.