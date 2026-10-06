### Metadata

* **Related Spec:** `workflows/checkpoint.md` (anchor: `### Phase 4: docs/STATE.md Sync & Handover Prompt Generation`), `protocols/context-sync.md`, `scripts/validate-execution-control.sh`, `scripts/check-harness-security.sh` (anchor: `for table in harness-security-paths.txt harness-security-rules.txt; do`) + `scripts/check-harness-security.sh` (anchor: `while IFS='|' read -r rule scope pattern; do`) + `scripts/harness-security-paths.txt` (externalized-rules precedent), `.gitignore` (anchor: `# Local/internal Kiro specs are ignored and not published. Public specifications`)
* **Priority:** `priority/p2`
* **Labels:** `type:bug`, `area:tooling`, `priority/p2`
* **Work Classification:** `L1` (diagnostics + report-only workflow change; **proposed SemVer impact `patch`** — was `L2`/`minor` while it force-staged, no longer so now that it does not)

--------

## User Story & Context

As a developer whose checkpoint artifacts sit behind an ignore rule (or in a repo with no ignore rule at all),
I want `pk:checkpoint` Phase 4 to **tell me** that its output is invisible to Git,
So that "docs silently not written / not recoverable for 1.5 days" can never happen silently again.

### Premise correction (why this was rewritten) — READ FIRST

The previous draft of this issue asserted, as *verified mechanism*:

> `git check-ignore -v docs/STATE.md → .gitignore:44:docs/`

**That evidence is false and was never reproduced.** Measured in this repository:

* `git check-ignore -v docs/STATE.md` → exits `1` (i.e. **not ignored**)
* `.gitignore` line 44 is **blank**; line 43 is `.worktrees/`
* `grep -n '^docs' .gitignore` → no match (exit 1). There is no `docs/` rule.

The failure this issue addresses is real, but it was **not** caused by a `docs/` ignore rule in this repository, and the previous draft was filed `priority/p1` / `type:bug` on that false premise. The priority and label are corrected below, and the fabricated citation is removed rather than restated.

The correct, still-valid observation is the one recorded in the local scratch draft `scratch/issue-draft-09-progressive-compliance.md` (a gitignored local file, not committed): an agent that judged the checkpoint gate unsatisfiable chose to write **nothing** rather than something partial, for 1.5 days.

### Two distinct failure modes — do not conflate them

| Mode | Symptom | Does `git add -f` help? |
| :--- | :--- | :--- |
| **A — Git cannot see the file** | File written to disk, but ignored/untracked, so absent from `git status` and never committed; a fresh session cannot discover it | Yes, staging is relevant |
| **B — The agent stopped writing the file** | Agent evaluates the gate, judges it unsatisfiable, emits nothing | **No.** There is no file to stage |

The previous draft's force-add invariant addressed Mode A while the observed incident was Mode B. Mode B is a ceremony-design failure owned by #553 (progressive compliance), and this issue explicitly does not claim to fix it.

### Why force-staging is removed

`git add -f` deliberately overrides an author-declared publication boundary. This repository's `.gitignore` states that boundary explicitly:

* `.gitignore` (anchor: `# Preserved untracked local artifacts (not for publication)`) — `semantic-review/`
* `.gitignore` (anchor: `# Local/internal Kiro specs are ignored and not published. Public specifications`) — `# live in docs/specs/`

It also does not deliver the durability the invariant promised:

* Staging writes only to the index. It creates no commit, so it is destroyed by `git reset --hard`, `git checkout .`, `git stash drop`, or `git clean -fd`, and is absent from any fresh clone.
* Under per-agent branching (which this repository's own `AGENTS.md` mandates), an uncommitted staged change never reaches another agent's branch.

A workflow must not silently change what a repository publishes. Durability behind an ignore rule is the author's decision, surfaced — not made for them.

### What already exists (do not duplicate)

* `workflows/checkpoint.md` (anchor: `### Phase 4: docs/STATE.md Sync & Handover Prompt Generation`) Phase 4 instructs a disk write and says "preserve session progress in git" — `workflows/checkpoint.md` (anchor: `update it to preserve session progress in git`) — but contains **no** `git add` / `git commit` / `git check-ignore` instruction. There is no existing staging invariant to revise.
* Externalized-rules precedent: `scripts/harness-security-paths.txt` (`path|kind`) and `scripts/harness-security-rules.txt` (`RULE|scope|regex`), loaded at `scripts/check-harness-security.sh` (anchor: `for table in harness-security-paths.txt harness-security-rules.txt; do`), fail-closed on a missing file — `scripts/check-harness-security.sh` (anchor: `report INCOMPLETE RULES .; exit 2; fi`) — and evaluated by the rules loop `scripts/check-harness-security.sh` (anchor: `while IFS='|' read -r rule scope pattern; do`).
* Prior claim that `scripts/isolate-worktree.sh` "sets defensive-git precedent" is **false** — that script contains no `check-ignore` / `add -f` logic; its `--force` flags concern worktree/branch removal. Do not cite it.

### Non-Negotiable Invariants

* **[ ] Report, never override:** `pk:checkpoint` records ignore status as **evidence** and never stages, commits, force-adds, or un-ignores a path the repository author placed behind an ignore rule.
* **[ ] Never print success on an unmeasured result:** a failed or unexpected git status is `INCOMPLETE` / `unknown`, never `OK`.
* **[ ] Mode A only:** this issue makes invisibility *visible*. It does not change agent behavior when a gate is unsatisfiable (Mode B → #553).
* **[ ] Backward compatible:** with no ignore rule in play, behavior is unchanged and adds no ceremony.
* **[ ] Zero-runtime:** markdown workflow guidance + local evidence scripts only; no daemon, no new required dependency.
* **[ ] Token figures repropagated:** this issue edits `workflows/checkpoint.md`, one of the six files summed into the core-six measurement. Run `bash scripts/measure-tokens.sh` (no `--strict`) and read its `Monolithic (core-6 subset derived)` and `Monolithic (full N-workflow set)` lines — even a prose-only addition moves the total. `scripts/tests/run-behavioral-contract-tests.sh` asserts the published cells equal measurement output, so re-measure and update `docs/BENCHMARKS.md` in the same PR (`docs/BENCHMARKS.md` (anchor: `| Core-six Lite subset | 6 | **30,966 tok** |`)).
* **[ ] Twin parity:** every script change ships in `.sh` and `.ps1` — `CONTRIBUTING.md` (anchor: `Behavioral Contract & Parity`); `PROMPTKIT.md` (anchor: `Bash/PowerShell twin parity`).

### Out of Scope

* **Force-staging / `git add -f` / `!` negation exceptions** — rejected by design (see above), not deferred.
* Changing `.gitignore` defaults — belongs to the adoption guide / #549 territory.
* Relaxing the fail-closed validator gate for any write class.
* Agent-behavior changes for Mode B — owned by #553.
* Rewriting git history.

--------

## Implementation Tasks (The Build)

* [ ] 1. Add a **read-only** ignore preflight to `workflows/checkpoint.md` Phase 4: for each checkpoint target (`docs/STATE.md`, `docs/tasks/<task-id>.md`, checkpoint/handoff records), run `git check-ignore -v <path>` and capture the output verbatim into the checkpoint evidence block. **Never** call `git add -f`, `git add`, `git commit`, or write a `!` negation.
* [ ] 2. Define the evidence semantics per `scripts/validate-execution-control.sh` conventions: a clean non-ignored path records nothing extra; an ignored path records `POLICY_LIMITATION` naming the exact rule source (e.g. `.gitignore` (anchor: `Public specifications`)) and the **human** remedies available (`!` negation exception chosen by the author, or relocating the artifact out of the ignored path). Mirror the existing `POLICY_LIMITATION` category — `scripts/validate-execution-control.sh` (anchor: `diagnostic POLICY_LIMITATION "$id" "$path" "Host timer capability does not record an enforcement limitation"`) — rather than inventing a new one.
* [ ] 3. Fail closed on unexpected git status: non-`0`/non-`1` exit → `INCOMPLETE`, per the three-way status branch precedent at `scripts/check-harness-security.sh` (anchor: `if [[ "$status" != 0 ]]; then report INCOMPLETE GIT_TRACKING "$relative"`). Never report a pass on an unmeasured result.
* [ ] 4. Declare the ignore source in machine-readable form, following `scripts/harness-security-paths.txt` (`path|kind`) so a project can supply its own rules file instead of editing shipped policy. Missing file → `INCOMPLETE`, not silent pass.
* [ ] 5. Add fixtures to `scripts/tests/fixtures/execution-control/` covering: no ignore rule (unchanged behavior), one ignored target (`POLICY_LIMITATION` recorded, nothing staged), and a deliberately broken git invocation (`INCOMPLETE`). Both Bash and PowerShell twins.
* [ ] 6. Assert in the test harness that the checkpoint run **produced no index change**: `git diff --cached --name-only` must be unchanged by `pk:checkpoint`. This is the regression lock for the removed force-add invariant.
* [ ] 7. Document the pattern and the author's choice in `protocols/` + `QUICKSTART.md`: `.gitignore` rules are publication policy; `pk:checkpoint` reports violations and does not override them.
* [ ] 8. Update `CHANGELOG.md` (`[Unreleased]`).

--------

## Acceptance Criteria (The Verifiable Proof)

### Scenario 1: No ignore rule — unchanged behavior

* Given a repository with no ignore rule covering checkpoint targets,
* When `pk:checkpoint` runs,
* Then behavior is identical to today: the record is written, no extra evidence lines appear, and no ceremony is added.

### Scenario 2: Ignored target is reported, never staged

* Given a repository where the author has placed `docs/` behind an ignore rule,
* When `pk:checkpoint` runs,
* Then the record is still written to disk, the evidence block cites the ignore rule verbatim with its source line, a `POLICY_LIMITATION` mark is present, the validator reports rather than hard-halting, **and `git diff --cached --name-only` is unchanged** (nothing was force-added).

### Scenario 3: Unmeasurable git state is fail-closed

* Given a git invocation returning an unexpected exit status,
* When the preflight runs,
* Then the result is `INCOMPLETE` — never `OK`, never a silent pass.

### Scenario 4: The gate stays satisfiable at low ceremony

* Given an agent that cannot satisfy the full checkpoint gate,
* When it evaluates the workflow,
* Then the workflow offers a degradable record path rather than instructing the agent to write nothing. (This scenario asserts the *documented alternative exists*; actual agent-behavior change is #553's acceptance surface, and this issue must not be credited with fixing Mode B.)

--------

## Automated Verification Command

```bash
bash scripts/tests/run-execution-control-fixtures.sh
bash scripts/tests/run-behavioral-contract-tests.sh
bash scripts/validate-references.sh .
pwsh -NoProfile -File scripts/tests/run-execution-control-fixtures.ps1
```

> Note: `scripts/validate-references.sh` requires the kit-root argument (`.` in-repo). It defaults to `.promptkit`, which does not exist in this repository, and exits 1 if that directory is absent. `.github/workflows/ci.yml` (anchor: `run: bash scripts/validate-references.sh .`) passes `.` explicitly.