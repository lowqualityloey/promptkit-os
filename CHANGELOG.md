# Changelog

All notable changes to PromptKit OS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

## [1.9.2] - 2026-09-27

Release evidence chain: `docs/releases/2026-09-27-v1.9.2-*.md` (`REL-2026-09-27-V1.9.2-001`) · Tag: `v1.9.2` at `d850225` — published to npm via trusted publishing (OIDC), provenance attestation verified, `NPM_TOKEN` deleted and the exposed granular token revoked · No breaking changes (patch).

### Changed
- **Courier Publish No Longer Diverts Off Trusted Publishing**: Removed the `registry-url` input from the `Setup Node` step in `.github/workflows/release-npm.yml`. That input made `actions/setup-node` write a userconfig `.npmrc` containing `//registry.npmjs.org/:_authToken=${NODE_AUTH_TOKEN}`, which is sufficient for npm to select the token authentication path even when the variable is empty — so npm never attempted the OIDC trusted-publishing exchange. The credential was gone but the mechanism that looked for one was not. Trusted publishing needs no registry configuration, so no auth entry is generated and npm has no token path to fall back to. (`init.sh`/`init.ps1` remain the single source of truth; `templates/agent-directive-template.md` is byte-unchanged.) (#417, #421)

### Fixed
- **Release Runs That Would Use Token Auth Now Fail Immediately**: Added an `Assert No Token Auth Will Be Used` step to the courier publish job, running before version sync, the minimal-tarball assertion, the AC-1 smoke test, and the publish. It fails the job with an explicit diagnostic if `NODE_AUTH_TOKEN` or `NPM_TOKEN` is present in the job environment, or if `NPM_CONFIG_USERCONFIG` points at a file containing an auth entry. The prior failure mode was a silent registry `404` after a full release run had already burned a version number; the new one is a named error in the first minute that states both the condition and the fix. Verified in all three states locally: clean environment passes, a set `NODE_AUTH_TOKEN` fails, an auth-bearing `.npmrc` fails. (#421)

## [1.9.1] - 2026-09-26 — FAILED, never published to npm

**This version was tagged and has a GitHub release, but was never published to npm.** Release run `36257849644` failed with `E404` at the publish step. `npm view promptkit-os versions` returns only `1.9.0`, which remains the live and valid courier; no consumer is affected and the git submodule path is canonical regardless. npm versions are immutable, so `1.9.1` is burned and is superseded by `1.9.2`. The `v1.9.1` tag and its GitHub release are retained deliberately as the immutable record of the attempt and must not be deleted, moved, or re-tagged. Root cause and full disposition are recorded in [`docs/releases/2026-09-27-v1.9.2-evaluation.md`](./docs/releases/2026-09-27-v1.9.2-evaluation.md).

Release evidence chain: `docs/releases/2026-09-26-v1.9.1-*.md` (`REL-2026-09-26-V1.9.1-001`) · Tag: `v1.9.1` at source `02bbfc6` — approved and tagged, publish failed · No breaking changes (patch).

> **Note on the 1.9.0 gap:** `v1.9.0` shipped on 2026-09-25 with no release-record chain in `docs/releases/`. The entries below the `1.9.1` heading that predate this release were already listed under `[Unreleased]` at the `v1.9.0` tag; they are left in place rather than retroactively re-attributed. Retro-certification of the `v1.9.0` change set is a separate record-remediation follow-up, surfaced in the v1.9.1 evaluation as an explicit coordinator-acceptance deviation.

### Changed
- **Courier Publishing via npm Trusted Publishing (OIDC)**: `.github/workflows/release-npm.yml` no longer authenticates with the long-lived `NPM_TOKEN` secret — the publish step now relies on the npmjs.com trusted publisher entry (repository `promptkit-os`, workflow `release-npm.yml`), which mints a short-lived credential from the job's `id-token`. Removes the standing write credential ahead of npm's January 2027 removal of bypass-2FA token publishing. The publish job also pins `npm install -g npm@^11.5.1`, because trusted publishing gates on npm CLI $\ge$ 11.5.1 (npm 10 never attempts the OIDC exchange) rather than on the Node version, and documents that the npmjs.com trusted-publisher Environment field must be left empty since the job declares no `environment:` key. `permissions` (`contents: read` + `id-token: write`), the AC-1 smoke test before publish, the minimal-tarball assertion, and provenance attestation are unchanged, as are `init.sh`/`init.ps1` and `templates/agent-directive-template.md`. Human steps remain: configure the trusted publisher, publish, verify `npm view promptkit-os dist.attestations`, then delete the secret and revoke the token on npmjs.com. (#417, #418)

## [1.9.0] - 2026-09-25

Courier installer, decision contract, and decision budget. Shipped without a release-record chain — see the note under `[1.9.1]`.

### Added
- **Optional `npx promptkit-os` Courier Installer**: Added a zero-dependency npm package (`package/bin/promptkit-os.js`) that fetches the GitHub release tarball matching its own package version, extracts it into `./.promptkit/`, and executes the canonical `init.sh` (POSIX) or `init.ps1` (Windows). The package is a courier, never a reimplementation — all installation logic remains in `init.sh`/`init.ps1`, and the git-submodule path stays canonical. Extraction over an existing tree is refused rather than merged, since a tarball overlay can leave stale files behind, and the error names the correct update command for whichever delivery door produced the install. Publishing is gated by `.github/workflows/release-npm.yml`, which syncs the courier version to the release tag, asserts a minimal tarball, smoke-tests AC-1 courier/canonical equivalence against that tag, and publishes with npm provenance attestation. (`init.sh`/`init.ps1` remain the single source of truth; `templates/agent-directive-template.md` is byte-unchanged.) (#413, #414)
- **Human Decision & Question Comprehensibility Contract**: Added a Decision Card format for every human-decision halt in `protocols/code-quality-gate.md` (context, fenced options with consequence and reversibility, a mandatory recommendation, and a declared "you decide" default) plus Type A–D routing — Type A (discoverable right answer) is decided and reported by the agent rather than escalated, Type B (taste among acceptable options) is presented as 2–3 options with a recommendation, and Types C (consequences the human owns) and D (accountability: ship, publish, license, privacy) always reach the human. Planning questions are converted into owned Assumption Records rather than answered arbitrarily. (`templates/agent-directive-template.md` is byte-unchanged.) (#406, #410)
- **Session Decision Budget**: Capped interactive Type B decision cards and clarification questions per session at a default of 3 (configurable in the Task Record, mirroring the TDD Enforcement Mode conditional-control shape), converting overflow into owned Assumption Records carrying the recommended default and batching them into the `pk:checkpoint` Phase 2 delegation summary. Types C and D are never capped — the budget limits fatigue-driven delegation mistakes, not human authority. (#408, #411)
- **Turbo Experimental Verdict Expiry Trigger**: Added an expiry condition to the Turbo experimental verdict in `docs/BENCHMARKS.md` — the earlier of multi-host wall-clock evidence for promotion being presented, or the next minor version release. On expiry a new dated verdict entry (promote / keep / remove, with rationale and disconfirming evidence) must be recorded and the trigger re-armed, so experimental status never persists by silence. (#412)
- **Stack Playbooks Framework, Catalog Index & Gap Roadmap**: Added `docs/stacks/README.md` defining guidance tiers (Rules vs. Playbooks vs. Recipes vs. Workflows), operational intake criteria, and Section 1 Catalog Matrix. Curated five priority stack playbooks activated JIT by detectable manifests with strict $\le$ 1,500 token budgets:
  - `web-astro.md`: Content-driven islands architecture, zero-JS baseline, and content collections (#392, #395).
  - `deploy-docker.md`: Universal containerization, multi-stage builds, non-root execution, and layer ordering (#396, #397).
  - `api-fastapi.md`: Python async backend, Pydantic v2 schemas, lifespan management, and dependency injection (#398, #399).
  - `api-node.md`: Node.js server frameworks (Express, Fastify, Hono, NestJS), runtime schema validation, non-blocking event loop discipline, and graceful shutdown (#400, #401).
  - `cms-wordpress.md`: WordPress CMS & Bedrock architecture, mandatory `$wpdb->prepare()` with explicit type specifiers, anti-CSRF nonce verification, capability authorization (`current_user_can()`), contextual late escaping, and N+1 query loop prevention (#402, #403, #404).
- **Cross-Cutting Recipe Schema & Automated Contract Gating**: Added `docs/recipes/README.md` and integrated 8 cross-cutting recipes (`auth-session.md`, `env-validation.md`, `form-mutations.md`, `test-isolation.md`, `webhook-idempotency.md`, etc.) with strict $\le$ 1,500 token budget gates and automated validation twins (`run-playbook-contract-tests.*`) wired into CI. Added direct recipe links to owning workflows (`workflows/auth.md`, `api.md`, `test.md`, `debug.md`, `onboard.md`). (#393, #394)
- **External Skill Coexistence & Precedence Contract**: Added skill coexistence and deduplication rules to `workflows/route.md`, `protocols/setup.md`, and `docs/ADOPTION-GUIDE.md`. Establishes that host skills (Claude Code, Cursor, Windsurf) provide execution capabilities while PromptKit retains exclusive authority over engineering governance, lifecycle state, and quality gates. (#385, #387)
- **Sharpened Subagent Verifier & Reviewer Briefs**: Established the Claims-Audit duty across `protocols/subagent-delegation.md` and `workflows/review.md`, requiring verification subagents to independently re-verify developer claims against diffs and exit codes. Added an adversarial verification pass to `workflows/debug.md` and trigger-based third-reviewer security brief to `workflows/review.md`. (#390, #391)
- **Static Token Headroom Recovery (ADR 0001)**: Extracted inline protocol text and redundant blocks into modular references, expanding `BALANCED` directive headroom from $< 100$ tok back to $\ge 200$ tokens (`2,254 / 2,500` tok) while keeping `LITE` at `1,146 / 1,500` tok. (#383, #386)
- **Bounded Oracle Verification & Test Integrity Guard**: Added to `protocols/code-quality-gate.md`, `workflows/fix.md`, and `templates/agent-directive-template.md`. Agents cannot self-certify completion or emit a green status card without an executed test/build command returning `exit code 0`. Strictly forbids modifying, weakening, or deleting existing tests, or writing vacuous assertions (`expect(true).toBe(true)`), to bypass failures. Enforces bounded auto-repair: max 2 retries before a hard halt with `> [!WARNING] Blocked: Awaiting Human Input`. (#230)
- **Hierarchical Workflow Composition (Primary vs. Supporting)**: Added to `workflows/route.md`. Multi-domain tasks designate exactly one Primary Workflow that owns the lifecycle state (e.g., `pk:fix`, `pk:plan`), while auxiliary concerns (e.g. data Expand-Contract migrations, quality gates) are attached as modular Supporting Checks without spawning competing parallel pipelines. (#230)
- **Invariant Handoff to STATE.md**: Added to `workflows/onboard.md`. Architectural constraints, design tokens, or stack rules discovered during greenfield intake or brownfield scans are automatically appended to Section 4 (`Locked Technical Invariants`) of `docs/STATE.md`. (#230)
- **Local Harness Preflight Inspection**: Added `scripts/check-harness-security.sh` and `check-harness-security.ps1` with shared path allowlist (`scripts/harness-security-paths.txt`) and rule tables (`scripts/harness-security-rules.txt`). Performs bounded, read-only local inspection of 20 configuration and environment files for exposed secrets, permission bypasses, and gitignore tracking gaps before installers write files. Supports independent opt-out via `PROMPTKIT_NO_PREFLIGHT=1`. (#243, #246)
- **Contributor Project Profile (`PROMPTKIT.md`)**: Added repository-root `PROMPTKIT.md` declaring PromptKit OS's own validation suites, token budgets (ADR 0001), and workflow-lifecycle rules (ADR 0002) so AI agents assisting contributors load project guardrails automatically. (#247, #251)
- **`pk:auto` Simulation Kata**: Added `activities/05-auto-orchestration.md`, providing a hands-on simulation covering the test immobility invariant, search circuit breakers, and review-ready handoff. (#248, #252)
- **Living Skill Matrix Retrospective Link**: Added an explicit step in `workflows/reflect.md` (`pk:retro`) prompting developers and contributors to identify exercised skill dimensions and update `notes/skill-matrix.md`. (#249, #253)
- **Lite Profile Quickstart Example**: Added `examples/lite-quickstart/` containing an annotated walkthrough, minimal `docs/STATE.md`, and an explicit upgrade path to Balanced. (#250, #254)
- **4-Layer AI Engineering Stack & Multi-Tool Layering Guidance**: Added to `docs/COMPARISONS.md` and `FAQ.md` (Question 19). Defines the 4-layer taxonomy (Specification ➔ Engineering Control Plane [PromptKit] ➔ Capabilities & Skills ➔ Host Runtime) and the Single Control Owner Principle to avoid control loop collisions when composing external prompt packs and skill collections alongside PromptKit. (#259)
- **Anti-Slop Aesthetic Archetypes, Visual Floor Gate & Design Study Protocol**: Integrated 4 curated aesthetic archetypes (Warm Paper / Editorial, High-Density Fintech, Clean Modern SaaS, Dark Terminal) into `workflows/design-system.md` to prevent monochrome voids when `DESIGN.md` is absent. Added `pk:design study <url | screenshot>` to extract design DNA into portable `DESIGN.md` files. Added anti-bento layout rhythm rules and recommended human-crafted Iconify families (`ph:*`, `radix-icons:*`, `tabler:*`) over generic Lucide defaults. Added a Design Vibe slot to Phase 0 greenfield intake (`protocols/discovery-intake.md`), added a UI Visual Floor Delivery Gate to `workflows/plan.md`, and updated `protocols/telemetry-cards.md` to proactively recommend `pk:design` when UI views lack a design profile. (#263)
- **Frontend Core Web Vitals & Code Simplification Heuristics**: Added comprehensive Core Web Vitals audit rules (INP $\le 200\text{ms}$ with main-thread yielding/startTransition, LCP $\le 2.5\text{s}$ with priority-hints/preloading, CLS $\le 0.1$ with reserved aspect-ratios, and $\le 150\text{kB}$ critical JS payload budget) to `workflows/perf.md`. Added an explicit Code Simplification Pass (5 deflation heuristics: flattening indirection, eliminating single-use abstractions, linearizing control flow with guard clauses, and purging speculative helpers) to `workflows/refactor.md`. (#269)
- **Turbo Suitability Check**: Added an advisory suitability question to the Turbo path of `workflows/profile.md` (and the matching `workflows/onboard.md` acknowledgement) so dependency-ordered or sequential work is warned that parallel waves buy **zero benefit on sequential work** while the experimental cost still applies, and is offered Balanced with rationale. The check links `docs/recipes/auto-waves-preflight-checklist.md` as its evidence source (never restated), is advisory and never blocking — an explicit `--turbo --experimental` override is still honored — and renders no prompt in non-interactive/CI paths, leaving refusal semantics and the Balanced/Lite paths unchanged. (#337)
- **`pk:sync` Profile Drift Audit**: Added a bounded, detection-only drift pass to `workflows/sync.md` that compares `PROMPTKIT.md` declarations (manifest presence, toolchain selection, root commands) against manifests and lockfiles actually present in the repo, reports mismatches as findings with a proposed patch, and changes nothing until the developer confirms. Detection is observation, not promotion — user-authored sections are never auto-rewritten, and a clean profile stays silent with no added ceremony. (#338)
- **Proactive Downgrade & Checkpoint Cadence Guidance**: Added a per-milestone level-fit check to `workflows/route.md` that proposes a Level-1 downgrade (single component, no schema/data migration, no auth/permission change, no public or breaking contract change, no new dependency surface) and a worked L1-vs-L2 small-MVP example, plus checkpoint-cadence guidance that treats a milestone boundary as the natural checkpoint for small single-lane projects. Downgrades stay proposed, never forced; escalation triggers, Level definitions, and the Evidence-Gated Verification Matrix are unchanged — a downgrade reduces records, never verification — and canonical cadence numbers remain in `workflows/checkpoint.md`. (#339)

### Changed
- **Courier Publishing via npm Trusted Publishing (OIDC)**: `.github/workflows/release-npm.yml` no longer authenticates with the long-lived `NPM_TOKEN` secret — the publish step now relies on the npmjs.com trusted publisher entry (repository `promptkit-os`, workflow `release-npm.yml`), which mints a short-lived credential from the job's `id-token`. Removes the standing write credential ahead of npm's January 2027 removal of bypass-2FA token publishing. `permissions` (`contents: read` + `id-token: write`), the AC-1 smoke test before publish, the minimal-tarball assertion, and provenance attestation are unchanged. Human steps remain: configure the trusted publisher on npmjs.com, publish, verify `npm view promptkit-os dist.attestations`, then delete/revoke the token. (#417)
- **Lite Directive Token Footprint**: The Lite directive now measures **1,210 tokens against its 1,500 budget** — a harness-reported value from `scripts/measure-tokens.sh --strict` (`LITE|1210|1500|PASS`), up from 1,146 after the decision-card routing line was added to `templates/agent-directive-lite-template.md`. Balanced is unchanged at **2,254 / 2,500** (`BALANCED|2254|2500|PASS`) and `templates/agent-directive-template.md` remains byte-unchanged; the Lite profile carries the decision rules instead of the Balanced one. `docs/BENCHMARKS.md` figures are updated to match the harness at all six reporting locations. (#406, #408, #410, #411)
- **Stack-Neutral Workflow & Template Hardening**: Hardened `workflows/refactor.md`, `debug.md`, `fix.md`, `test.md`, `perf.md`, `ship.md`, `tasks.md`, `pr.md`, and `commit.md` along with task templates to decouple them from Node-specific conventions, ensuring full stack neutrality across Python, Go, Rust, and CMS projects. (#349, #350, #354–#374)
- **Tone Refinement & Context-Aware Prompting (`pk:grill`)**: Refined inquiry pacing, eliminated combative framing, and adapted interrogation depth dynamically based on existing repository context. (#376)
- **Documentation Truthfulness & Token Metric Reconciliation**: Corrected token count metrics in `workflows/route.md` and synced documentation references to match live tool measurements. (#384, #388, #389)
- **Foolproof WSL & Submodule Update Instructions**: Updated 'Updating PromptKit OS' in `README.md` and `workflows/sync.md` to recommend `bash .promptkit/init.sh` (preventing permission denied and CRLF errors) and provided explicit submodule branch checkout commands (`git -C .promptkit checkout main && git -C .promptkit pull origin main`) for reliable updates across Linux, WSL, and Windows. (#265)
- **Advisory Search Circuit Breaker Semantics**: Updated `templates/agent-directive-template.md` and `agent-directive-lite-template.md` to define the breaker as an advisory instruction rather than mechanical tool control, changed the counting unit to per-call (batch tool calls count individually), carved out legitimate read-only research, and prohibited trivial edits from resetting the counter. Refreshed token counts across `docs/BENCHMARKS.md`. (#241, #255)
- **Documentation Workflow Count & Profile Framing Synchronization**: Updated historical 23-workflow references to 24 workflows across `README.md` and `docs/COMPARISONS.md`, modernized profile callouts to remove dated v1.6 phrasing, and synchronized FAQ counts (19 questions) in `README.md` and `docs/ARCHITECTURE.md`. (#259)

### Fixed
- **AC-1 Smoke Test Compared Against the Wrong Baseline**: Fixed `package/test/smoke.sh` so its courier-vs-canonical equivalence assertion is actually a courier-vs-canonical test. The canonical tree was built by copying the working tree, so the check only held when the version under test was the checked-out commit — pointed at any real tag it failed on version drift (`23-` vs `24`-workflow `PROMPTKIT.md`) instead of on the delivery-door property it exists to prove, which meant the harness could not audit a historical release at all. The canonical tree is now materialized from the tag under test via `git archive`, keeping both doors comparable (tracked files only, exec bit preserved, no VCS metadata to strip). Also normalized the `PROMPTKIT_VERSION` argument so a leading `v` is accepted — the documented `PROMPTKIT_VERSION=v1.9.0` form previously built the tag `vv1.9.0` and failed with a 404 that read like a missing tag rather than a malformed argument. The release job now checks out full history (`fetch-depth: 0`) so the tag ref is available to `git archive`; the offline contract suites still skip this network test. AC-1 equivalence verified end to end against `v1.8.0`. (#413, #414)
- **Stale Directive Figures in FAQ**: Replaced the restated directive token numbers in `FAQ.md` with a pointer to the canonical `docs/BENCHMARKS.md` figures, applying the duplication rule that benchmarks are stated once and linked thereafter. Prevents the FAQ from drifting out of sync with harness-reported values. (#407, #409)
- **WordPress Manifest Trigger False-Positive Elimination**: Removed generic `style.css` trigger from `docs/stacks/cms-wordpress.md` and `docs/stacks/README.md`, restricting automatic JIT activation to unambiguous manifests (`wp-config.php`, `theme.json`, `composer.json`) and preventing false-positive injection in generic CSS/Vite repositories. (#404, #405)
- **PowerShell Test Script Twin Parity**: Restored missing `.ps1` test scripts and synchronized assertion logic with Bash twins, achieving 100% test parity across platforms. (#374)
- **Session Spend Estimate Evidence Safety**: Bounded estimation math in `workflows/checkpoint.md` to prevent un-anchored cost extrapolations. (#378, #380)
- **Spend Ledger Fallback Estimation Heuristic**: Added deterministic fallback spend estimation instructions (`turns × ~8k–15k tok/turn`) to `workflows/checkpoint.md` and `templates/state-tracker-template.md`. Prevents agents in unmetered CLI hosts (OpenCode, Cursor, Windsurf, Copilot, Neovim) from emitting `not measured` for the estimated payload column and cumulative running totals when host token telemetry is unavailable. (#267)
- **Mechanical docs/STATE.md Scaffolding & Directory Guarantee**: Fixed `init.sh` and `init.ps1` to ensure the `docs/` directory is created before copying `templates/state-tracker-template.md`, guaranteeing all 9 canonical sections (including Section 8 Session Continuity Log and Section 9 Session Spend Ledger) are present on Day 1. Updated `workflows/onboard.md` to preserve Section 9 intact. (#261)
- **CLI Host Probe Precision**: Fixed false-positive detection in `init.sh` and `init.ps1` where stale or leftover configuration directories (e.g. `~/.claude`, `~/.copilot`) caused uninstalled CLI assistants to be marked as `[detected]`. CLI hosts now strictly probe active executable binaries in `$PATH`. (#226)

## [1.8.0] - 2026-09-16

Release evidence chain: `docs/releases/2026-09-16-v1.8.0-*.md` (`REL-2026-09-16-V1.8.0-001`) · Tag: `v1.8.0` at source `05aac50` — pending maintainer tag action after this chain's CI passes · No breaking changes (minor).

### Added
- **Bounded Discovery Intake (Greenfield & Brownfield)**: New `protocols/discovery-intake.md` protocol and conditional `Phase 0` in `workflows/onboard.md`: size-classed (S/M/L) bounded interview covering MVP intent, surfaces, deployment target, auth & data, constraints, design inputs (Figma/screenshots/docs), and integrations — asked in the context window (never modal pickers) so the user can attach links, screenshots, and documents. Intake closes with a recorded `close_reason`; unanswered slots become owned `ASSUMPTION-*` entries; AI-suggested scope goes to a **Later ledger** instead of the plan.
- **Intake Signals & Migration Safety**: `templates/project-profile-template.md` now carries machine-readable `size:` / `intake-status:` lines; placeholders are declared **intake questions, not defaults**. Existing (brownfield) installs resolve to `legacy-partial` and are never re-interviewed.
- **Planning Gate (pk:plan Step 0)**: Intake preflight gates architecture on intake status; **MVP Floor & Anti-Overengineering Gate** requires every moving part to trace to a user-stated requirement (else Later ledger) and surfaces a "Decisions I'm defaulting for you" accept-or-change list; **Picker routing rule** bounds modal pickers to closed-set, evidence-backed choices and bans them for intent questions.
- **Mid-Implementation Delta Path**: New-Requirement Interception tables in `workflows/sync.md` and `workflows/checkpoint.md` — doc-only deltas append; scope/AC changes require a Scope Change Record; architecture/data/deployment changes block execution and re-open planning.
- **Product & Design Inputs Authority**: `protocols/context-sync.md` gains an authority row for Figma links, screenshots, `STYLE.md` / `DESIGN.md`, and tracker-board links captured by intake.
- **Greenfield Routing**: `pk:onboard` registered as the first-class entry for brand-new projects across `workflows/route.md`, `docs/WORKFLOW-MAP.md`, README, and QUICKSTART.
- **Telemetry Status Cards**: New lazily-loaded `protocols/telemetry-cards.md` format spec and `status-cards: on|off` machine line in `PROMPTKIT.md` — `off` suppresses the decorative completion card (default `on`); `> [!IMPORTANT]` / `> [!WARNING]` halts always fire.
- **Behavioral Eval Harness**: New `scripts/run-behavioral-eval.sh` (+ `.ps1` twin) scoring transcripts against 15 rubric scenarios with embedded fixtures and an offline self-test wired into both CI jobs; baseline 15/15 with 5/5 regression controls in `docs/BEHAVIORAL-EVAL.md`.
- **Tokenizer Validation**: New `scripts/measure-tokenizer-delta.sh` (+ `.ps1` twin) checking the `bytes/4` convention against `tiktoken` (`bytes/4` remains the gate); results published in `docs/BENCHMARKS.md` §9.
- **LSP Diagnostics (Opt-In)**: `pk:review` gains a read-only diagnostics pull on TypeScript repos (`LSP Enabled: true`); session-endurance rules, TL;DR-first output, and tracker-picker onboarding included.
- **Contributor Governance**: New workflow-lifecycle policy (`CONTRIBUTING.md` + `docs/adrs/0002-workflow-lifecycle-policy.md`) gating additions and retirements; static-token-headroom decision recorded in `docs/adrs/0001-static-token-headroom.md`.

### Changed
- **Directive Footprint**: Balanced static directive drops 2,496 → 2,335 tok (165 tok headroom) against the unchanged 2500 budget; Lite moves 1,059 → 1,079 against 1500. Per-task payloads and benchmark figures refreshed to live tool output.
- **README Front Door**: Halved 50,146 → ~20k bytes with detail relocated to new `docs/COMPARISONS.md` (hosts, competitors) and `docs/ARCHITECTURE.md` (operating model, command reference, layout); lifecycle map consolidated in `docs/WORKFLOW-MAP.md`.

### Fixed
- **Pilot & Registry Hygiene**: Intake pilot `close_reason` corrected to the valid enum; `discovery-intake.md` registered in the progressive-loading list with a filesystem-derived drift guard; FAQ entry-count guard added (both test twins).

### Removed
- **Retired `.kiro/specs` planning bundles**: The three tracked Kiro specification bundles (`agent-execution-control-handoff/`, `conventional-commit-versioning/`, `promptkit-sdlc-skill-adaptation/` — 12 files) are removed from the published tree. Public specifications live in `docs/specs/`; tool-local planning directories are not shipped to adopters. `.gitignore` no longer carries the per-directory negations, and `CONTRIBUTING.md` §6 now states the retirement rather than the retention policy. Evidence is preserved: the bundles remain recoverable from git history, and the dated release evaluations and Task Records that cite them are left unedited as historical records. No validator read `.kiro/`, so no gate is affected.


## [1.7.0] - 2026-09-14

> **BREAKING CHANGE (documented, minor):** `pk:profile` was retired as a `pk:perf` alias and is now the runtime profile switcher. Use `pk:perf` or `pk:latency` for profiling; intent-based auto-routing is unaffected. All existing artifacts remain valid (`git submodule update --remote .promptkit` + re-run `init.sh` / `init.ps1`).

Release evidence chain: `docs/releases/2026-09-14-v1.7.0-*.md` (`REL-2026-09-14-V1.7.0-001`) · Tag: `v1.7.0` at `21a6498` · Prior untagged "v1.6.0" content (2+1 profiles) is folded into this release per the evaluation's Range Selection Rationale.


### Added
- **Dual-Compatible Telemetry Status Cards**: Standardized structured 3-line status cards (`> 📊 **Milestone**: ... \n> 🎯 **Active**: ... \n> 🟢 **Quality Gate**: ...`) across `templates/agent-directive-template.md` and all completion workflows (`workflows/commit.md`, `pr.md`, `plan.md`, `tasks.md`, `test.md`, `data.md`, `fix.md`), rendering cleanly in both rich markdown IDEs and raw terminal CLIs (OpenCode, Claude Code) without unrendered table syntax.
- **Interactive Turn Handoffs**: Added protocol instructions prompting agents to execute native interactive selection tools (e.g. OpenCode prompt picker modal, `ask_question`) as their final tool call with `(Recommended)` as Option 1 when concluding tasks with branching choices, enabling keyboard arrow navigation, 1-key `Enter` confirmation, and custom typing.
- **Project Database & Harness Isolation**: Established a strict guardrail preventing test/migration harnesses from attaching to foreign or sibling project database containers (e.g. `api-db-1`/`jobtracker`), mandating project-scoped database containers.
- **MCP Tool Precedence & Capability Protocols**: Added MCP Progressive Enhancement & Tool Precedence Matrix to `protocols/setup.md`, updated `templates/project-profile-template.md` with active MCP server tracking, and added adoption guidance in `docs/ADOPTION-GUIDE.md` defining hierarchy: Native MCP Tools $\rightarrow$ Native IDE Search/Edit Tools $\rightarrow$ Terminal CLI Commands $\rightarrow$ Manual Human Prompt.
- **Telemetry & Isolation Behavioral Contract Tests**: Added Scenarios J and K to `scripts/tests/run-behavioral-contract-tests.*` asserting dual-compatible telemetry status cards and project container isolation.
- **Release-Record Examples & Directive Budget CI Gates**: Wired `scripts/tests/release-records.examples.*` and `scripts/measure-tokens.*` budget assertions into Linux and Windows CI workflows.

### Changed
- **Inline Task Ceremony Classification**: Replaced the 26-line hardcoded workflow path list in `templates/agent-directive-template.md` with convention-based routing and a compact Level 0–3 ceremony summary, eliminating mandatory preloading of `workflows/route.md` (-28% to -54% dynamic per-task context reduction).
- **Extracted Internal Release Evaluation**: Relocated the ~4,144-token repository-internal release evaluation block from `workflows/ship.md` to `docs/internal/release-evaluation.md`, retaining a concise concept stub in `ship.md` (-44% token reduction on `ship.md`).
- **Brand Normalization**: Standardized legacy `Better-PromptKit` naming to `PromptKit OS` across all shipped workflows and template assets.
- **2+1 Profile Architecture & Token Calibration**: Added Lite (`--lite`, ~845 tokens static overhead, 96% reduction) and Turbo (`--turbo --experimental`) profiles alongside Balanced (`--balanced`, ~2,076 tokens, 89% reduction), added visual interactive TTY menu in `init.sh` / `init.ps1`, and reconciled all documentation to 24 workflows.

### Added (post-v1.6.0, included in this release)
- **`pk:profile` Runtime Profile Switcher**: In-session Lite/Balanced/Turbo switching (`workflows/profile.md`) delegating to the idempotent installer re-injection path, with router-matrix registration and Section-0 body sync on re-runs (#142).
- **Strict Dual-Profile Token Budget Gates**: `measure-tokens --strict` asserts Balanced ≤ 2,500 and Lite ≤ 1,500 on both OSes, with per-task baseline gate and negative-path regression harness (#141).
- **Execution-Record Self-Validation in CI**: `validate-execution-control --root . --strict` on Linux + Windows (42 → 0 diagnostics permanently gated); legacy v1.6.0 records completed with canonical evidence and a formal Scope Change Record (#155).
- **Ceremony Guards**: mixed-level tie-break (highest wins), announced-and-logged L2 downgrades, defined milestone boundary with task-scoped dirty-tree rule and post-init exception (#156).
- **E2E Profile Matrix Harness**: 9 deterministic installer cases per OS, including piped-stdin no-hang, `PROMPTKIT_NO_INTERACTIVE=1`, upgrade idempotency, and Aider `CONVENTIONS.md` injection (#149).
- **Trigger-Namespace Uniqueness and Validator-Warning Guards**: duplicate `pk:` triggers or orphaned alias tokens now fail CI (#152, #154).

### Changed (post-v1.6.0, included in this release)
- **Turbo Cost Claims Measured, Not Asserted**: protocol overhead measured at 1.0x–2.0x (bounds model) across 27 shipped claim surfaces, with a CI-gated claim window (#153).
- **Derived Monolithic Baselines**: the unsourced 18,500-token constant replaced by live-derived core-subset/full-set baselines in scripts and docs; directive footprint now 2,404 (Balanced) / 983 (Lite) tok.
- **Directive Endurance & Provenance Rules**: session-endurance checkpoint trigger, STATE-until-read trust, telemetry-card provenance, and trigger rename table moved into the always-loaded payload; `sync.md` recovery path made factual (#155).
- **Honest Test Naming**: "behavioral prompt-contract" surfaces documented as string-level documentation-contract suites (#156).

### Breaking (documented; shipped within minor)
- **`pk:perf` lost its legacy `pk:profile` alias** (collision with the new switcher): use `pk:perf` / `pk:latency`. No stored artifact changes; see migration note above.

---

## [1.5.1] - 2026-09-13

### Added
- **Non-Destructive Worktree Removal**: Updated `scripts/isolate-worktree.sh` and `isolate-worktree.ps1` to use non-forced `git worktree remove` and `git branch -d` by default, requiring an explicit `--force` / `-Force` flag to remove dirty worktrees or unmerged branches.
- **Post-Staging Secret Scan Behavioral Test**: Added Scenario I to `scripts/tests/run-behavioral-contract-tests.*` asserting post-staging secret scan enforcement.
- **Installer Orphaned Marker & Permission Tests**: Added test cases in `scripts/tests/run-init-safety-tests.sh` verifying orphaned `<!-- PROMPTKIT_END -->` rejection and `0600` file permission round-trip preservation.

### Changed
- **Post-Staging Secret & Probe Scan Sequencing**: Hardened `workflows/commit.md` to run `git diff --cached` secret and debug-probe scanning immediately after Phase 2 atomic staging and before Phase 4 developer confirmation, closing the TOCTOU leak gap.
- **Canonical Setup Protocol Reference**: Refactored `protocols/setup.md` to reference `templates/agent-directive-template.md` as the single canonical source of truth rather than maintaining a separate copy.
- **Risk-Before-Size Routing Escalation**: Codified explicit risk-before-size guidance in `templates/agent-directive-template.md` ensuring 1-line security or authorization edits escalate beyond Level 0 fast-path immediately.
- **Empirical Benchmark Terminology**: Replaced absolute guarantee phrasing in `docs/BENCHMARKS.md` with empirical test and safeguard language.

### Fixed
- **Bash Installer Orphaned Marker Handling**: Updated `init.sh` to check for both `has_start` and `has_end`, preventing orphaned `PROMPTKIT_END` markers from silently appending duplicate blocks.
- **Bash Installer Permission Preservation**: Added `chmod --reference` in `init.sh` to preserve original target file permissions when overwriting.

---

## [1.5.0] - 2026-09-12

### Added
- **Automated Property Test Suites in CI**: Integrated execution-control (`run-execution-control-properties.*`) and release-record (`run-release-record-properties.*`) property harnesses into `.github/workflows/ci.yml`, running 1,700 property iterations across Linux and Windows on every push and pull request.
- **Guarded Release-Record Self-Validation in CI**: Added automated validation of all files in `docs/releases/` to CI with legacy v1.0.0 grandfathering exemption, permanently preventing invalid release records from merging.

### Changed
- **Reconciled Directive Token Figures**: Normalized CRLF/LF line endings in `scripts/measure-tokens.ps1` and `scripts/measure-tokens.sh`, permanently locking the canonical measurement metric at 7,672 characters $\rightarrow$ ~1,918 / ~1,920 tokens (~90% static context reduction) across all platforms. Reconciled `README.md` and `docs/BENCHMARKS.md` with explicit methodology notes.

### Fixed
- **Broadened Reference & Structural Validator Scope**: Extended `scripts/validate-references.*` to scan all Markdown files across `docs/`, `examples/`, `templates/`, and `notes/`, fixing historical drift.
- **Release-Record Diagnostic Deduplication**: Deduplicated `MISSING_FIELD` error reporting in `scripts/validate-release-records.*` to guarantee exactly one deterministic diagnostic per missing required header.
- **Locale-Independent CI-Triage Placeholder Detection**: Replaced case-sensitive regex matching in `scripts/validate-ci-triage.*` with culture-agnostic character class checks.
- **Specification Artifact & Gitignore Reconciliation**: Reconciled `.gitignore` and tracked historical `.kiro` specification artifacts per repository contributing guidelines.

---

## [1.4.0] - 2026-09-12

### Added
- **Canonical Agent Directive Template**: Created `templates/agent-directive-template.md` as the single source of truth for agent directive blocks rendered across all AI coding assistants during initialization.
- **Directory Target Support**: Updated `init.sh` and `init.ps1` to detect directory configuration targets (e.g. modern `.clinerules/` directory layout) and safely generate `.clinerules/promptkit.md`.
- **Multi-Mode Review Diff Baselines**: Added explicit branch (`git diff <base>...HEAD`), staged index (`git diff --cached`), and working-tree (`git diff HEAD`) review modes to `workflows/review.md`, eliminating stall conditions on `main`.
- **Strict Byte-Level Idempotency Tests**: Added test cases in `scripts/tests/run-init-safety-tests.*` verifying zero-diff SHA256 byte-for-byte idempotency upon repeated initialization.

### Changed
- **Codified Monorepo Import Boundaries**: Formally documented the four non-negotiable architectural import boundaries (Presentation Isolation, Client/Server Boundary, Public Package Exports Only, Explicit Workspace Protocol) in `README.md`.
- **Token Budget Assertion & Footnote**: Hardened `scripts/measure-tokens.*` with strict `<= 2000` token budget assertions and added mechanical verification footnotes in `README.md` and `docs/BENCHMARKS.md` (~1,944 tokens).
- **Host MCP Progressive Enhancement Caveats**: Added explicit host-capability caveats in `README.md` and `templates/project-profile-template.md` establishing graceful degradation to CLI tools when MCP servers are absent.
- **Sandboxed Worktree Feature**: Highlighted `scripts/isolate-worktree.sh` and `isolate-worktree.ps1` in `README.md` under Subagent Delegation.

### Fixed
- **Pre-Flight Secret Scanning**: Hardened pre-commit secret checks in `workflows/commit.md` to inspect staged diff content (`git diff --cached`) for entropy and credentials alongside allowlisted filename checks.
- **Timing-Safe Buffer Comparison**: Added buffer length equality precondition before calling `crypto.timingSafeEqual` in `workflows/auth.md`.

---

## [1.3.0] - 2026-09-12

### Added
- **Mechanical Directive Token Measurement Utilities**: Added `scripts/measure-tokens.ps1` (PowerShell) and `scripts/measure-tokens.sh` (POSIX Bash) to calculate exact character, word, and estimated token counts (~4 chars/token heuristic) of the injected agent directive block, validating the ~89.5% static context reduction vs monolithic 18.5k-token prompt packs without adding runtime dependencies.

### Changed
- **Lean Initial Directory Scaffolding**: Refactored `init.ps1` and `init.sh` to scaffold only 4 essential core directories upfront (`docs/tasks`, `docs/specs`, `docs/adrs`, `docs/tests`), deferring specialized workflow folders (`docs/auth`, `docs/data`, `docs/releases`, etc.) to on-demand creation when invoked.
- **Production-Grade First-Task Demonstration**: Replaced the toy "React calculator" prompt in `README.md` with an authenticated 24-hour expiring invite link API feature demonstrating Level 1 ceremony, RED test failure observation, and minimal workflow routing.

### Fixed
- **CI Test Harness Alignment**: Updated `.github/workflows/ci.yml` Linux and Windows dry-run initialization assertions to match streamlined core directories and integrated `scripts/measure-tokens.*` into automated script syntax verification suites.

---

## [1.2.0] - 2026-09-12

### Added
- **Ironclad Red-to-Green TDD Enforcement**: Added Step 2.5 to `workflows/test.md` mandating that agents observe and record test failure (`RED`) with the expected assertion error before touching production code.
- **Adaptive Ceremony & Model-Tiering Matrix**: Added risk-to-model mapping in `workflows/route.md` (Level 0 $\rightarrow$ Fast/Economy tier, Level 1 $\rightarrow$ Balanced tier, Level 2/3 $\rightarrow$ Frontier Reasoning tier) to eliminate token waste while preventing under-reasoning defect loops.
- **Zero-Dependency Git Worktree Sandbox Scripts**: Added `scripts/isolate-worktree.ps1` (PowerShell) and `scripts/isolate-worktree.sh` (Bash) enabling safe branch sandboxing (`create`, `list`, `merge`, `remove`) without workspace pollution. Automatically appends `.worktrees/` to `.gitignore`.
- **Pattern D Subagent Delegation Protocol**: Codified isolated worktree execution in `protocols/subagent-delegation.md` for high-risk, multi-file refactors.
- **Full-Stack Feature Blueprint**: Added `examples/fullstack-feature/README.md` showcasing an enterprise Organization Invitations feature spanning Gherkin AC, Expand-Contract migrations, 8-state tactile UI tokens, and verification proof tables.
- **Expanded IDE Runtime Auto-Detection**: Updated `init.ps1` and `init.sh` to auto-detect Cursor (`.cursor/rules/promptkit.mdc` and `.cursorrules`), Cline / Roo Code (`.clinerules`), Trae (`.traerules`), and OpenCode (`.opencode/rules.md`).
- **Pillar 2 Quality Gate Check**: Added `Observable Red-to-Green Execution` requirement in `protocols/code-quality-gate.md`.

### Changed
- Updated `README.md` Overview table with **Adaptive Ceremony & Model Tiering** dimension.
- Expanded `docs/BENCHMARKS.md` with Section 6 detailing token savings and risk mitigation by model class.

---

## [1.1.0] - 2026-09-11

### Added
- **Tactile Anti-Slop UI Aesthetic Foundations**: Codified engineered matte paper grounds, 1px ruler-drawn hairlines over blur, the 5% signal accent rule, macrostructure rhythm diversity, and honest copy standards in `workflows/design-system.md`.
- **Chromatic Dual-Mode Theme Presets**: Integrated concrete OKLCH color token palettes for *Cobalt Dev-Tool* (technical SaaS / precision dashboards) and *Hum Warm Editorial* (knowledge bases / boutique SaaS) across both light and dark modes.
- **Mandatory 8-State Component Contract**: Codified strict interaction state requirements (`default`, `hover`, `:focus-visible`, `:active`, `disabled`, `loading`, `error`, `success`) across design workflows, templates, and quality gates.
- **Zero-Byte Native Font Philosophy**: Standardized on native system font stacks (`system-ui`, `ui-monospace`, `ui-serif`) with `font-feature-settings: "tnum" 1` and `text-wrap: balance` (0 KB download, 0ms CLS).
- **Universal Iconify Catalog Guidelines**: Standardized icon lookup using the Iconify catalog with single-family consistency and `simple-icons` for tech marks without mandating npm runtime packages.
- **Pillar 6 Quality Gate Checks**: Added 8-state component contract, honest copy, and single icon family checks to `protocols/code-quality-gate.md`.

---

## [1.0.0] - 2026-09-05

### Added
- **Just-In-Time (JIT) Filesystem Architecture**: Lightweight ~40-line directive router (~650 tokens) injected into agent directives (`AGENTS.md`), saving >95% static token overhead over monolithic prompt packs.
- **Adaptive Level 0–3 Task Ceremony**: Adaptive scaling from Level 0 (direct answer, zero ceremony) to Level 3 (release-critical, full provenance).
- **Living State & Milestone Persistence**: Git-tracked markdown memory in `docs/STATE.md` and `docs/tasks/` preventing session amnesia and context rot.
- **Expand-Contract Database Migration Governance**: Safe zero-downtime schema evolution rules in `workflows/data.md` preventing destructive drops.
- **20 Specialized Engineering Workflows**: High-craft workflows covering planning (`pk:plan`), scientific debugging (`pk:debug`), surgical remediation (`pk:fix`), profiling (`pk:perf`), auth (`pk:auth`), API contracts (`pk:api`), testing (`pk:test`), atomic commits (`pk:commit`), PR descriptions (`pk:pr`), and release engineering (`pk:ship`).
- **Socratic Mentorship Engine**: Mentorship and progressive 3-tier hints via `pk:tutor`.
- **Zero-Lock-In Foundation**: 100% pure Markdown protocols and native shell scripts (`init.sh`, `init.ps1`) with zero npm runtime packages, zero binary daemons, and zero vendor lock-in.
