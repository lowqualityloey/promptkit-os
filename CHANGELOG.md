# Changelog

All notable changes to PromptKit OS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
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
- **Foolproof WSL & Submodule Update Instructions**: Updated 'Updating PromptKit OS' in `README.md` and `workflows/sync.md` to recommend `bash .promptkit/init.sh` (preventing permission denied and CRLF errors) and provided explicit submodule branch checkout commands (`git -C .promptkit checkout main && git -C .promptkit pull origin main`) for reliable updates across Linux, WSL, and Windows. (#265)
- **Advisory Search Circuit Breaker Semantics**: Updated `templates/agent-directive-template.md` and `agent-directive-lite-template.md` to define the breaker as an advisory instruction rather than mechanical tool control, changed the counting unit to per-call (batch tool calls count individually), carved out legitimate read-only research, and prohibited trivial edits from resetting the counter. Refreshed token counts across `docs/BENCHMARKS.md`. (#241, #255)
- **Documentation Workflow Count & Profile Framing Synchronization**: Updated historical 23-workflow references to 24 workflows across `README.md` and `docs/COMPARISONS.md`, modernized profile callouts to remove dated v1.6 phrasing, and synchronized FAQ counts (19 questions) in `README.md` and `docs/ARCHITECTURE.md`. (#259)

### Fixed
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
