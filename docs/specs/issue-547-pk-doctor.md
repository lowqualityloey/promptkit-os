### Metadata

* **Related Spec:** `workflows/sync.md` (anchor: `### Phase 1: Engine & Rule Audit`), `scripts/validate-execution-control.sh` (anchor: `diagnostic POLICY_LIMITATION`), `scripts/check-harness-security.sh` (anchor: `if [[ "$kind" == sensitive && "$git_ready" == 1 ]]; then`), `scripts/measure-tokens.sh` (anchor: `TOKEN_BUDGET_BALANCED=2500`), `docs/WORKFLOW-MAP.md`, `templates/agent-directive-template.md` (anchor: `Activate workflows anytime with these namespaced triggers:`), `workflows/route.md` (anchor: `## The Engineering Lifecycle Decision Matrix`), `protocols/setup.md` (anchor: `### Workflows & Protocols Reference`), `docs/ARCHITECTURE.md` (anchor: `| Command | Workflow File | Status | Output Target | Description |`), `docs/adrs/0002-workflow-lifecycle-policy.md` (anchor: `### 1. Adding a workflow (the 24th-workflow gate)`), `scripts/tests/run-behavioral-contract-tests.sh` (anchor: `WF_COUNT=$(ls "$REPO_ROOT"/workflows/*.md | wc -l`), `docs/BENCHMARKS.md` (anchor: `| Full workflow set | 25 | **112,660 tok** |`)
* **Priority:** `priority/p2`
* **Labels:** `type:feature`, `area:tooling`, `priority/p2`
* **Work Classification:** `L2` (new workflow = public contract surface; proposed SemVer impact `minor`)

> **Sequencing dependency:** the version rows depend on #545's stamp and its six-state result table. Land #545 first, or this workflow reports `SKIP(no engine stamp)` until it does. The `DIVERGED` rows depend on the three-store precedence contract that #550 and #553 jointly settle; until then they report `SKIP(no precedence contract)`.

--------

## User Story & Context

As a developer whose governance silently rotted — stale engine, ignored paths, diverged state stores, none of it detected,
I want one command, `pk:doctor`, that checks hosts × version × install-mode × ignore-state × docs-drift and tells me exactly what rotted,
So that "pk stopped working and nobody noticed for 1.5 days" becomes impossible.

### What already exists (do not duplicate)

* `scripts/validate-references.sh` checks reference integrity but runs only in CI, never in-session. It also defaults its kit root to `.promptkit` and exits 1 when that directory is absent — so it must be invoked with an explicit root.
* `workflows/sync.md` (anchor: `### Phase 1: Engine & Rule Audit`) Phase 1 performs read-only detection but performs **no** version or tag comparison today; the version-record step `workflows/sync.md` (anchor: `4. **Check Version & Release Records**:`) is the natural hook.
* No validator compares the live state stores against each other.
* `POLICY_LIMITATION` already exists as a diagnostic category — `scripts/validate-execution-control.sh` (anchor: `diagnostic POLICY_LIMITATION`); reuse it.
* Graceful-degradation precedent for unavailable checks: `scripts/measure-per-task-tokens.sh` (anchor: `echo "Repo SHA: $(git -C "$KIT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"`), `scripts/check-changelog-entry.sh` (anchor: `# Skips cleanly when the base ref is unavailable (shallow or offline checkout).`).
* Structural template for a new workflow: `workflows/verify-bootstrap.md` (the 25th workflow, admitted under ADR 0002), with `workflows/sync.md`'s read-only framing as the behavioral model.

### Non-Negotiable Invariants

* **[ ] Read-only by default:** `pk:doctor` reports. It never edits, stages, commits, or writes unless an explicit `--fix` is passed, and `--fix` is limited to re-emitting a host block. It never runs an upgrade (owned by #545).
* **[ ] Exit codes are part of the contract:**

  | Code | Meaning |
  | :--- | :--- |
  | `0` | Every configured check is `OK`, `IGNORED`, or `SKIP` |
  | `1` | At least one `STALE`, `MISSING`, `DIVERGED`, or `INCOMPLETE` finding |
  | `2` | `pk:doctor` could not run at all (missing prerequisite) |

  `IGNORED` **never** contributes to exit `1`. A path the developer intentionally ignores is a valid configuration, not a health failure — this is the difference between reporting a fact and passing a judgment.

  **`INCOMPLETE` is fail-closed and contributes to exit `1`** — never `0`, and never `2`. The distinction from exit `2` is what makes the mapping decidable: exit `2` means no check ran because `pk:doctor` itself lacked a prerequisite, whereas `INCOMPLETE` means a check *did* run and could not establish its answer. Precedence when both apply: `2` only when no check could run at all, otherwise `1`. An implementation that lets `INCOMPLETE` reach `0` fails Scenario 6, and one that maps it to `2` fails it too, so both twins must implement this line identically.
* **[ ] Machine-readable output:** one line per check, tab-separated, fields in stable order, parseable by `grep`/`awk`:
  `<scope>\t<STATUS>\t<detail>\t<remediation>`
  Status vocabulary: `OK` | `STALE` | `MISSING` | `IGNORED` | `DIVERGED` | `SKIP` | `INCOMPLETE`.
* **[ ] Unavailable checks degrade to `SKIP(<reason>)`:** when an input is absent or a tool is missing (`handoff.md`, Task Records, `git`, `jq`), report `SKIP` and do not affect the exit code. Never report `OK` for a check that did not run.
* **[ ] Declared installation mode scopes the checks:** profile and install door come from the installer-written profile (`profile:` in `PROMPTKIT.md`) and the courier's own discriminator — `package/bin/promptkit-os.js` (anchor: `const isSubmoduleInstall = fs.existsSync(path.join(kitDir, ".git"));`), which tests for `<kit>/.git`. Lite installs must not be flagged for absent heavy workflows.
* **[ ] Zero-runtime:** markdown workflow plus local evidence scripts. No daemon, no required API.
* **[ ] Token budget:** exactly **one** trigger line added to `templates/agent-directive-template.md`. BALANCED is measured at **2,312 tok** against a 2,500 cap — 188 tok of headroom (measured with `bash scripts/measure-tokens.sh --strict`; re-measure rather than trusting the number, since any directive edit moves it). Do not add a section heading or extend the trigger-to-file exception list — `templates/agent-directive-template.md` (anchor: `- Trigger-to-file exceptions (the convention alone would misresolve these):`); `pk:doctor` → `workflows/doctor.md` follows the naming convention and needs no exception. Re-run `bash scripts/measure-tokens.sh --strict` immediately after editing.
* **[ ] Lite profile untouched:** the Lite directive ships exactly 6 triggers and `scripts/tests/run-behavioral-contract-tests.sh` (anchor: `assert_contains "templates/agent-directive-lite-template.md" "Lite - 6 workflows"`) asserts the literal string `Lite - 6 workflows`. `pk:doctor` is **not** added to the Lite template.
* **[ ] No bare `pk:` alias without a workflow file:** any alias added must also be registered in the alias allowlist at `scripts/validate-references.sh` (anchor: `db|profile|research|reflect|handoff|issue|kanban|scan|latency|grill|spike|retro|design|init|init-repo|task|update|refresh)`) (and its `.ps1` twin), because the orphan-trigger check warns and `scripts/tests/run-behavioral-contract-tests.sh` (anchor: `orphaned trigger aliases shipped`) requires **zero** warnings.

### Out of Scope

* Upgrade execution (owned by #545).
* Synthetic-base detection (owned by #552).
* Auto-fix beyond `--fix` re-emitting a host block.
* Live host runtime verification — maintainer-owned per `docs/HOST-CONFORMANCE.md` (anchor: `- **Division of Labor**:`).

--------

## Implementation Tasks (The Build)

* [ ] 1. Create `workflows/doctor.md` following the section order of `workflows/verify-bootstrap.md` and the read-only framing of `workflows/sync.md` (anchor: `│ Phase 1: Engine & Rule Audit │ Phase 2: Disk Re-Read & Diff │`) (including the Provenance Invariant: no executed proof → no green claim). Must begin with an H1 (`.github/workflows/ci.yml` (anchor: `TEST_DIR="/tmp/test-project"`) requires `^# `).
* [ ] 2. Implement the checks:
  * **hosts** — enumerate expected host files from the installer-written profile; report `OK` when `<!-- PROMPTKIT_START -->` is present, `MISSING` when absent. Scope by declared mode so Lite is not flagged for Balanced-only workflows.
  * **version** — delegate to #545's six-state table (`unknown` / `ok` / `behind(+n)` / `diverged` / `shallow-or-offline` / `not-a-git-install`). Until #545 lands, report `SKIP(no engine stamp)`.
  * **ignore-state** — run `git check-ignore -v` on the kit directory, `PROMPTKIT.md`, `docs/`, and installed host files; report `IGNORED(<rule source>)` or `OK`. Use the three-way status branch from `scripts/check-harness-security.sh` (anchor: `if [[ "$kind" == sensitive && "$git_ready" == 1 ]]; then`); unexpected git status → `INCOMPLETE`, never `OK`.
  * **docs-drift** — compare `docs/STATE.md §3A` ↔ latest canonical Task Record ↔ harness handoff store. Report `DIVERGED(<pair>)` with the exact differing field. `SKIP` until #550/#553 settle precedence.
* [ ] 3. Wire `pk:doctor` into CI as a `scripts/validate-references.sh` companion. **There is no `init.sh --check` mode** — the previous draft cited one; `init.sh` has no `--check` / `--validate` / doctor flag, and it would reject the argument at its unknown-flag branch. Either add a real flag in this issue or wire into installer completion and CI only.
* [ ] 4. Register the workflow in every required location (ADR 0002 gate, `docs/adrs/0002-workflow-lifecycle-policy.md` (anchor: `### 1. Adding a workflow (the 24th-workflow gate)`)):
  * `templates/agent-directive-template.md` (anchor: `Switch Lite/Balanced/Turbo profile at runtime.`) — exactly one trigger line after the last entry in the trigger list
  * `workflows/route.md` (anchor: `## The Engineering Lifecycle Decision Matrix`) — one matrix row
  * `protocols/setup.md` (anchor: `### Workflows & Protocols Reference`) — one reference row
  * `docs/ARCHITECTURE.md` (anchor: `| Command | Workflow File | Status | Output Target | Description |`) — one command-table row
  * `docs/WORKFLOW-MAP.md` (anchor: `| Workflow | Typical Duration (Illustrative Estimate) | Complexity | Frequency |`) — one complexity-matrix row, plus the cross-cutting note `docs/WORKFLOW-MAP.md` (anchor: `**Cross-Cutting Utilities, Session Boundaries & Meta-Orchestration**:`)
* [ ] 5. Bump the workflow count **25 → 26** everywhere it is asserted. Fail-closed guards that will otherwise fire:
  * `scripts/tests/run-behavioral-contract-tests.sh` (anchor: `WF_COUNT=$(ls "$REPO_ROOT"/workflows/*.md | wc -l`) (and its `.ps1` twin) — on-disk workflow count
  * `PROMPTKIT.md` (anchor: `- [ ] **Locked workflow count (ADR 0002)**: 25 workflows.`) — ADR 0002 locked count
  * `templates/project-profile-template.md` (anchor: `the full 25-workflow set, Level 0-3 adaptive ceremony`) — `full 25-workflow set`
  * `init.sh` (anchor: `PromptKit OS successfully configured for`) / `init.ps1` (anchor: `PromptKit OS successfully configured for`) — user-facing banner
  * `docs/BENCHMARKS.md` (anchor: `| Full workflow set | 25 | **112,660 tok** |`) — inventory row; re-measure the token total via `bash scripts/measure-tokens.sh` and update the `Full workflow set` inventory row
  * the stale-claim scan at `scripts/tests/run-behavioral-contract-tests.sh` (anchor: `STALE_CLAIMS=$(grep -rnE`) sweeps a fixed file list — update every surviving `25` claim, including `README.md`, `QUICKSTART.md`, `FAQ.md`, `docs/WORKFLOW-MAP.md` (anchor: `New users start here with an introductory 5-node mental model`), `docs/ARCHITECTURE.md` (anchor: `*Status Legend: All 25 workflows pass CI structural link validation`) and `docs/ARCHITECTURE.md` (anchor: `Step-by-step engineering lifecycle procedures (25 workflows)`), `docs/INTERESTING-FACTS.md` (anchor: `25 workflow files`), `CONTRIBUTING.md` (anchor: `## Workflow Lifecycle: Addition & Retirement Policy`), `templates/lite-profile.md`, `workflows/profile.md` (anchor: `Option 3: Balanced — full 25 workflows`), `workflows/onboard.md` (anchor: `Choose PromptKit OS profile for this project`), and `docs/adrs/0002-workflow-lifecycle-policy.md` (anchor: `the live surface is 25 workflows`)
* [ ] 6. Add a `Scenario AP` assertion to `run-behavioral-contract-tests.sh` **and its `.ps1` twin** (ADR 0002 requires both), covering: trigger uniqueness for `pk:doctor`, the 26-file count, and the exit-code contract.
* [ ] 7. Update `CHANGELOG.md` (`[Unreleased]`) — required for any `workflows/` change by `scripts/check-changelog-entry.sh`.

--------

## Acceptance Criteria (The Verifiable Proof)

### Scenario 1: Healthy install

* Given a Balanced install whose engine stamp matches, all host files carry the block, no managed path is ignored, and state stores agree,
* When `pk:doctor` runs,
* Then every row reports `OK` and the exit code is `0`.

### Scenario 2: The loey_space replay

* Given a checkout with an 8-commit-stale engine, a `docs/` path ignored by the developer's own rule, and `STATE.md §3A` holding placeholders while §8/§9 hold real rows,
* When `pk:doctor` runs,
* Then it reports `STALE(+8)` on the version row, `IGNORED(<rule source>)` naming the actual ignore rule and its source line, and `DIVERGED(STATE §3A vs …)` with the specific field — plus the remediation for each. Exit code is `1`.

### Scenario 3: Intentionally ignored path does not fail health

* Given an otherwise healthy install where the developer deliberately ignores a local-only path,
* When `pk:doctor` runs,
* Then that row reports `IGNORED(<rule source>)` and **the exit code remains `0`** — an intentional ignore is a valid configuration, not a defect.

### Scenario 4: Unavailable check degrades honestly

* Given no `handoff.md` and no canonical Task Record,
* When `pk:doctor` runs,
* Then the docs-drift row reports `SKIP(<reason>)` rather than `DIVERGED` or `OK`, and the exit code is unaffected.

### Scenario 5: Mode-scoped host expectations

* Given a Lite install,
* When `pk:doctor` runs,
* Then only the 6 Lite workflows are expected, and no row reports `MISSING` for Balanced-only workflows.

### Scenario 6: Unmeasurable state is fail-closed

* Given a git invocation returning an unexpected exit status,
* When the ignore-state check runs,
* Then the row reports `INCOMPLETE` — never `OK` — and the exit code is exactly **`1`**, per the exit-code contract above: fail-closed, and distinct from the `2` that means the check never ran.

--------

## Automated Verification Command

```bash
bash scripts/measure-tokens.sh --strict
bash scripts/validate-references.sh .
bash scripts/tests/run-behavioral-contract-tests.sh
bash scripts/tests/run-reference-link-tests.sh
pwsh -NoProfile -File scripts/tests/run-behavioral-contract-tests.ps1
```

> Correction from the previous draft: the script is `scripts/validate-references.sh`, not `scripts/tests/validate-references.sh` — no file exists at the latter path. It also requires the kit-root argument (`.` in-repo): it defaults to `.promptkit`, which does not exist in this repository, and exits 1 if that directory is absent. `.github/workflows/ci.yml` (anchor: `run: bash scripts/validate-references.sh .`) passes `.` explicitly.

> When adding relative links from `workflows/doctor.md`, prefer targets already stubbed by `scripts/tests/run-reference-link-tests.sh` (it copies the real `workflows/` tree and stubs a fixed set of `docs/` targets) — `docs/WORKFLOW-MAP.md`, `docs/BENCHMARKS.md`, `docs/adrs/0002-*`, `notes/*` — or existing `protocols/` and sibling `workflows/*.md` files. `workflows/` is **not** exempt from link resolution.