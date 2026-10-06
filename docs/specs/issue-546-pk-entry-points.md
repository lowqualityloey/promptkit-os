### Metadata

* **Related Spec:** `scripts/pk-route.sh` + `.ps1` twin, `workflows/commit.md`, `docs/HOST-CONFORMANCE.md` Honesty Contract (`docs/HOST-CONFORMANCE.md` (anchor: `## 1. Honesty Contract & Division of Labor`)), Untested Hosts registry (`docs/HOST-CONFORMANCE.md` (anchor: `## 4. Untested Hosts Registry`)), maintainer runbook (`docs/HOST-CONFORMANCE.md` (anchor: `## 5. Execution & Scoring Runbook`)); `protocols/setup.md` host→file map (`protocols/setup.md` (anchor: `Gemini CLI / Antigravity`)), host-file checklist (`protocols/setup.md` (anchor: `existing agent configuration files`)), `init.sh` (anchor: `host_file() {`) + `init.ps1` (host→file map), `scripts/tests/run-playbook-contract-tests.sh`
* **Priority:** `priority/p2`
* **Labels:** `type:feature`, `area:tooling`, `priority/p2`
* **Work Classification:** `L2` (public contract change; proposed SemVer impact `minor`)

--------

## User Story & Context

As a developer opening a supported host in a repository,
I want `pk:route` to resolve to something real — an actual command with an actual exit code — rather than prompt-text convention alone,
So that agents never silently stop recognizing `pk:` triggers mid-project. Observed in a downstream consumer repo: OpenCode sessions ignored `pk:` and wrote no docs for ~1.5 days while the harness kept running.

### Two corrections to the previous draft

1. **The "five hosts vs all four files" mismatch is not an arithmetic error.** "Four" consistently means four *files* throughout the previous draft, enumerated once and referenced as "four host files" thereafter. However, the enumeration was genuinely incomplete: **Cursor was named in the user story but appeared in no file list, no task, and no acceptance criterion.** Fixed below.
2. **`CODEX.md` is not an installer target.** `init.sh` (anchor: `host_file() {`) maps 9 host ids plus `agents`; there is no `codex` id and no `CODEX.md` path. `docs/HOST-CONFORMANCE.md` (anchor: `**Codex CLI**`) maps Codex CLI to `AGENTS.md`. The previous draft's Scenario 2 asserted a `CODEX.md` requirement that cannot be satisfied. Replaced below with a Cursor scenario, which is a real gap.

### Proof standard: installer-level, not live-runtime

This issue deliberately proves **installer-level landing only**. That is not a weakening — it is the repository's established division of labor:

* `docs/HOST-CONFORMANCE.md` (anchor: `installer supports 10 distinct AI coding host configurations`) — "installer compatibility (verifying that templates, configurations, and directives land cleanly on disk) is an **install-time** claim, not a **behavioral runtime** claim."
* `docs/HOST-CONFORMANCE.md` (anchor: `Division of Labor`) — **Agent-owned**: probe specifications, mechanical evaluation rubrics, matrix framework, initial validation fixtures. **Maintainer-owned**: live host accounts, provider subscriptions, executing fresh sessions, capturing live transcripts.
* `docs/HOST-CONFORMANCE.md` (anchor: `Untested Boundaries Are Never Implied`) — "Untested Boundaries Are Never Implied": hosts without published live transcripts are registered Untested for live runtime fidelity, and "compatibility is unknown and must never be implied."

Nine of the 10 host configurations are registered Untested (`docs/HOST-CONFORMANCE.md` (anchor: `**Claude Code CLI**`)); OpenCode is **PARTIAL** (1 of 5 probes live), so "all 10 Untested" is already false. Requiring live host invocation evidence here would place this issue in violation of that contract; live fidelity is deferred to the maintainer-owned sweep in `docs/HOST-CONFORMANCE.md` (anchor: `**Aider**`).

### What already exists (do not duplicate)

* `scripts/pk-route.{sh,ps1}` are the only real executables. There is no `pk` binary, npm bin, shell shim, or `.claude/commands/` entry anywhere in the repository.
* `scripts/pk-route.sh` (anchor: `echo "Recommended Workflow: ${JEV_WORKFLOW}"`) classifies free text to a ceremony level and prints `Recommended Workflow: pk:X`. It executes nothing. `docs/WORKFLOW-MAP.md` (anchor: `Solely classifies requests into the canonical 4-level task ceremony model`) codifies this: `pk:route` "**Solely classifies** requests into the canonical 4-level task ceremony model … and routes to existing workflows."
* Host → directive-file map: `init.sh` (anchor: `host_file() {`) and `protocols/setup.md` (anchor: `Gemini CLI / Antigravity`). `init.sh` (anchor: `KNOWN_HOSTS=`) and `init.ps1` list the same 9 ids plus `agents`; Cursor maps to `.cursorrules` / `.cursor/rules/promptkit.mdc`.
* The directive block is emitted from `templates/agent-directive-template.md` by the installer, so content is already uniform; only *delivery* is at issue.

### Non-Negotiable Invariants

* **[ ] Zero-runtime preserved:** policy text plus thin shims only. No daemon, no required API, no model lock-in. Consistent with `PROMPTKIT.md` §7.
* **[ ] Zero-Lock-In ruling for the shim, recorded rather than paraphrased.** §7 states `PROMPTKIT.md` (anchor: `**Zero-Lock-In**: Pure markdown protocols; no CLI binary, npm dependency, or daemon.`). A hand-written `pk` shim is none of the three things that rule bans — it is not a binary, not an npm dependency, and not a daemon — and it ships as reviewed source, not as a committed generated artifact. That is the whole basis on which this is permitted, so it is recorded here in the rule's own terms instead of the looser phrase "policy text plus thin shims only". If the shim ever grows a dependency, a build step, a background process, or a committed artifact, it has crossed §7 and this issue's approach — not §7 — is what must change.
* **[ ] Bounded trigger parity — state it honestly:** `pk:route` resolves in shell **and** every installed host file. The remaining triggers are **file-level prompt contracts**, not shell executables; shell behavior for them is explicitly out of scope. (The previous draft claimed "every documented `pk:*` trigger resolves in shell" while specifying exactly one shell implementation — an over-promise of roughly 26 triggers.)
* **[ ] Wrapper is a router, never an executor:** the shim classifies and prints. It never loads a model, never writes files, and never runs a workflow.
* **[ ] Nonzero exit on unknown subcommand**, so a mistyped trigger fails loudly rather than silently doing nothing.
* **[ ] Token budget:** directive additions measured; BALANCED ≤ 2,500, Lite ≤ its budget (`scripts/measure-tokens.sh` (anchor: `TOKEN_BUDGET_BALANCED=2500`)).
* **[ ] Proof tier stated explicitly** per `docs/HOST-CONFORMANCE.md` (anchor: `Division of Labor`); this issue does not claim live runtime fidelity.

### Out of Scope

* Changing trigger names or ceremony semantics (`workflows/route.md` Levels 0–3 unchanged).
* Live host session verification — maintainer-owned per `docs/HOST-CONFORMANCE.md` (anchor: `Division of Labor`).
* The `pk:doctor` health matrix — owned by #547.
* Shell executables for triggers other than `pk:route`.

--------

## Implementation Tasks (The Build)

* [ ] 1. Add a thin `pk` shell shim (+ `.ps1` twin). Contract:
  * `pk route "<free text>"` invokes `scripts/pk-route.sh` verbatim and exits with its code, printing `[PromptKit OS: Level N] Recommended Workflow: pk:X`.
  * Any other subcommand exits `2` with a message naming `workflows/<cmd>.md` as the file-level contract.
  * No daemon, no network beyond `pk-route.sh`'s existing optional probe.
* [ ] 2. Bind Cursor explicitly in the installer-facing docs and tests: assert that a `--host=cursor` install writes `<!-- PROMPTKIT_START -->` into `.cursorrules` (or `.cursor/rules/promptkit.mdc` when that directory exists, per the existing `ensure_target` logic). Cite `init.sh` (anchor: `host_file() {`) and `protocols/setup.md` (anchor: `Gemini CLI / Antigravity`).
* [ ] 3. Ship tracked host defaults separate from local overrides so a fresh clone receives working rules. Note that `.opencode/rules.md` and `.clinerules/promptkit.md` are commonly gitignored in consumer repos — that asymmetry is the delivery fragility this task addresses, and it must be handled with tracked defaults rather than by force-adding.
* [ ] 4. Register the shim in `CONTRIBUTING.md` CI syntax lists if new scripts are added, and mirror both twins.
* [ ] 5. Update `docs/HOST-CONFORMANCE.md` (keep the Untested registry accurate — this issue does **not** move any host to verified), `docs/WORKFLOW-MAP.md` trigger table, and `CHANGELOG.md` (`[Unreleased]`).

### Reference corrections

* The Related Spec entry naming `AGENTS.md` has been removed. **No tracked `AGENTS.md` exists in this repository**, and a repo-wide search for an "exception table" matches only these draft lines. The trigger-to-file convention lives in `templates/agent-directive-template.md` (anchor: `### Workflows & Protocols Reference`) and `protocols/setup.md`.
* Do not add a `CODEX.md` installer path. `docs/HOST-CONFORMANCE.md` (anchor: `**Codex CLI**`) maps Codex CLI to `AGENTS.md`; verify that mapping holds and add it to `protocols/setup.md` if it is missing.

--------

## Acceptance Criteria (The Verifiable Proof)

### Scenario 1: Shell routing works and exits truthfully

* Given a fresh install,
* When `pk route "the checkout endpoint returns 500"` is executed,
* Then it exits `0` and prints a Level line plus a `Recommended Workflow: pk:X` line, and **executes nothing**.

### Scenario 2: Unknown subcommand fails loudly

* Given the same install,
* When `pk commti` (typo) is executed,
* Then it exits `2` and names the file-level contract to read, rather than silently succeeding.

### Scenario 3: Every installed host file carries the block

* Given a fresh clone plus a non-interactive install configured for multiple hosts,
* When the installer completes,
* Then every installed host file contains `<!-- PROMPTKIT_START -->`, verified at file level. Proof is installer-level only; live runtime fidelity is deferred to `docs/HOST-CONFORMANCE.md` (anchor: `**Aider**`).

### Scenario 4: Cursor is configured (replaces the invalid `CODEX.md` scenario)

* Given an install configured with `--host=cursor`,
* When the installer runs,
* Then `.cursorrules` — or `.cursor/rules/promptkit.mdc` when that directory exists — contains the `<!-- PROMPTKIT_START -->` block, and `pk route` resolves in shell.

### Scenario 5: Bash/PowerShell parity

* Given both twins available,
* When the shim is exercised on Bash and PowerShell,
* Then both produce identical classification output and identical exit codes.

--------

## Automated Verification Command

```bash
bash scripts/validate-references.sh .
bash scripts/tests/run-playbook-contract-tests.sh
bash scripts/tests/run-behavioral-contract-tests.sh
pwsh -NoProfile -File scripts/tests/run-playbook-contract-tests.ps1
```

> Correction from the previous draft: the script is `scripts/validate-references.sh`, not `scripts/tests/validate-references.sh` — no file exists at the latter path. It also requires the kit-root argument (`.` in-repo): it defaults to `.promptkit`, which does not exist in this repository, and exits 1 if that directory is absent. `.github/workflows/ci.yml` (anchor: `bash scripts/validate-references.sh .`) passes `.` explicitly.