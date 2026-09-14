# Changelog

All notable changes to PromptKit OS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

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
- **2+1 Profile Architecture & Token Calibration**: Added Lite (`--lite`, ~845 tokens static overhead, 96% reduction) and Turbo (`--turbo --experimental`) profiles alongside Balanced (`--balanced`, ~2,076 tokens, 89% reduction), added visual interactive TTY menu in `init.sh` / `init.ps1`, and reconciled all documentation to 22 workflows.

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
