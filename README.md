# PromptKit OS

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![CI](https://github.com/lowqualityloey/promptkit-os/actions/workflows/ci.yml/badge.svg)](https://github.com/lowqualityloey/promptkit-os/actions)
[![GitHub](https://img.shields.io/badge/GitHub-lowqualityloey%2Fpromptkit--os-black.svg)](https://github.com/lowqualityloey/promptkit-os)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Donate-orange?style=flat&logo=buy-me-a-coffee&logoColor=white)](https://buymeacoffee.com/itsjonellmb)

The open-source Engineering Operating System for AI coding assistants (Claude Code, Gemini CLI, Cursor, Windsurf, GitHub Copilot, Cline, Roo Code, Trae, OpenCode, Aider, and Antigravity).

PromptKit OS equips your coding assistant with disciplined engineering workflows: spec-driven architecture, living session state, phased Expand-Contract zero-downtime database migrations, empirical debugging, and atomic Conventional Commits without colliding with IDE slash commands.

---

## Overview: Who It Is For & Why

| Dimension | Details |
| :--- | :--- |
| **What is it?** | A modular, instruction-based engineering operating system that lives in your repository as `.promptkit/`. |
| **Who it is for** | Developers pairing with AI coding agents who want structured specs, living project state, non-breaking schema migrations, and clean git history. |
| **Who it is NOT for** | Developers looking for an autocomplete inline plugin, a CLI binary, or an npm dependency. PromptKit OS is pure markdown protocols and prompts. |
| **Why it is better** | Replaces unguided "vibe coding" and token-wasting guess-and-patch loops with systematic, hypothesis-driven development workflows. Structured workflows are designed to reduce redundant back-and-forth by enforcing one-pass planning, artifact reuse, and surgical fixes over guess-and-patch loops. |
| **Key differences** | Namespaced triggers (`pk:` prefix), Bounded Oracle Gates (machine-verified `exit code 0` required for completion with 2-attempt bounded repair), Search Circuit Breakers (>6 consecutive reads without edits/tests halts context churn), guardrails against single-step destructive schema drops (phased Expand-Contract policy), strict project-scoped database container isolation, Socratic guidance that avoids unsolicited code dumps, and monorepo workspace isolation (scoped `--filter` commands). |
| **Token Efficiency** | **Zero Static Token Bloat**: Injects only a compact router directive (~1,079 tok Lite [95% reduction] / ~2,401 tok Balanced [88% reduction] vs the ~19.8k derived core-subset baseline (v1.6.0-dated; re-derives with workflow growth, and ~97-99% vs the full 23-workflow set)). Full workflows are read Just-In-Time (JIT) from local files only when triggered. See [`docs/BENCHMARKS.md`](./docs/BENCHMARKS.md). |
| **Durable State Persistence** | **Cross-Session Memory**: State is never lost when chat sessions compact or reset. All active milestones, tasks in flight, and architectural invariants persist directly in Git-tracked markdown (`docs/STATE.md` and `docs/tasks/`). Architectural constraints discovered in `pk:onboard` are automatically synced to `STATE.md`. Run `pk:checkpoint` and resume in any fresh session via `pk:route`. |
| **Adaptive Ceremony & Model Tiering** | **Scales with Risk**: Bypasses heavy templates for daily tweaks (Level 0/1) while reserving deep reasoning, Task Records, and verification gates for schema, auth, and release risks (Level 2/3). Matches LLM model tiers to task risk to prevent token waste. |
| **Enforced Done-Gates** | **Not Inert Advice**: PromptKit OS enforces verifiable engineering done-gates: Bounded Oracle Verification (machine-verified `exit code 0` required to pass quality gates), strict milestone git boundaries (blocking milestone transitions on the task's own uncommitted changes), automated pre-commit secret leak scans (`pk:commit`), and required Gherkin Acceptance Criteria verification proof. Sampled prompt compliance is measured, not asserted: 15/15 baseline + 5/5 regression controls (see [`docs/BEHAVIORAL-EVAL.md`](./docs/BEHAVIORAL-EVAL.md)). |

---

## Start Here: Most Work Is Level 1

Getting started with PromptKit OS takes three simple steps:

1. **Install & Initialize**: Run `./.promptkit/init.sh` (or `.\.promptkit\init.ps1` on Windows) to scaffold `./docs/`, `./PROMPTKIT.md`, and host directives.
2. **Inspect `PROMPTKIT.md`**: Review or customize project-specific commands, test runners, and architectural invariants in `./PROMPTKIT.md` (or run `pk:onboard` — a greenfield discovery interview or brownfield stack scan).
3. **Prompt Naturally**: Enter your task naturally or route explicitly with `pk:route`. The assistant announces its ceremony level upfront (e.g. `[PromptKit OS: Level 1 (Standard) — Localized bug fix. No Task Record required.]`). Most ordinary engineering tasks (bug fixes, isolated component tweaks, small features) are **Level 1 (Standard)** and do **not** require a formal Task Record file (`docs/tasks/<task-id>.md`).

### First Task Example

Try pasting this copyable prompt into your AI assistant right after setup:

> "Add an authenticated API endpoint to generate 24-hour expiring invite links in our existing app. Keep this at PromptKit OS Level 1 unless inspection finds schema, public contract, or multi-component risks. Use only the minimum relevant workflow, observe RED test failure first, and run targeted verification."

For authoritative Level 0–3 classification, escalation, downgrade, and Task Record rules, see [`workflows/route.md`](./workflows/route.md). To get up and running in 5 minutes, see [Quick Start](#quick-start-60-seconds) or [`QUICKSTART.md`](./QUICKSTART.md).

---

## Quick Start (60 Seconds)

**New to PromptKit?** → See **[FAQ.md](./FAQ.md)** for the 18 most common questions  
**Getting started?** → See **[QUICKSTART.md](./QUICKSTART.md)** for a 5-minute guided tour  
**Release History?** → See **[CHANGELOG.md](./CHANGELOG.md)** for version notes and release provenance  
**Full-Stack Example?** → See **[examples/saas-dashboard/](./examples/saas-dashboard/README.md)** for a populated end-to-end feature walkthrough, or **[examples/fullstack-feature/](./examples/fullstack-feature/README.md)** for a narrative lifecycle reference  
**Existing project?** → See **[ADOPTION-GUIDE.md](./docs/ADOPTION-GUIDE.md)** for gradual adoption  
**Visual learner?** → See **[WORKFLOW-MAP.md](./docs/WORKFLOW-MAP.md)** for decision trees and diagrams  
**Token economics & benchmarks?** → See **[BENCHMARKS.md](./docs/BENCHMARKS.md)** for architecture and context window analysis  
**Want to know more?** → See **[INTERESTING-FACTS.md](./docs/INTERESTING-FACTS.md)** for unique insights and design principles

> [!TIP]
> **Start with just 2 workflows.** You do not need to learn all 23 workflows. Use `pk:debug` (stops guess-and-patch loops) and `pk:checkpoint` (eliminates session amnesia) to get 80% of the value immediately. Everything else is modular and on-demand. New in v1.6.0: **2+1 profiles** — Lite (6 utility workflows, 1,079 tok), Balanced (23 workflows, default), Turbo experimental (parallel waves, ~2x measured cost).

### 1. Add to Your Project

**One-Command Setup (Recommended)**:
Run from the root of your existing Git repository:

```bash
# macOS / Linux (Bash / Zsh) — Balanced is default (23 workflows)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --balanced

# Lite profile: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) <1,500 tok, 80% value — onboarding
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --lite

# Turbo experimental: Balanced + parallel subagent waves, up to ~2x measured token cost, still requires human L3 approval
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --turbo --experimental

# Windows (PowerShell)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --balanced
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --lite
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --turbo --experimental
```

**Profiles (v1.6.0 — 2+1 modes):**
- **Lite** (`--lite`): 6 utility workflows, 1,079 tok static (95% reduction vs ~19.8k core-subset), 80% value — new users, learning, tiny fixes
- **Balanced** (`--balanced` or no flag, default): full 23 workflows, 2,401 tok, Level 0-3 adaptive ceremony — teams, production
- **Turbo** (`--turbo --experimental`): Balanced + parallel waves, up to ~2x measured token cost, experimental, still requires human L3 approval — greenfield

Profile stored in `PROMPTKIT.md` as `profile: lite|balanced|turbo`. Upgrade anytime: `.promptkit/init.sh --balanced` or `--lite`.
When run in an interactive terminal without flags, `init.sh` / `init.ps1` probes your installed AI hosts and presents a visual menu to select both your **profile** and target **hosts**. In CI or non-interactive environments, pass flags or set `PROMPTKIT_NO_INTERACTIVE=1`.

**Host targeting:** scope the install to specific assistants and adjust it later —
```bash
./.promptkit/init.sh --host=opencode,claude   # also write directives to these hosts
./.promptkit/init.sh --add-host=cursor         # add one host to an existing install
./.promptkit/init.sh --target=docs/AI.md       # a custom directive file outside the known list
```
`AGENTS.md` is always written as the universal fallback; `--host` adds host-specific files on top (without it, the installer probes your environment). Re-running never re-asks intake and never overwrites files you already own.

<details>
<summary>Or step-by-step / direct clone</summary>

```bash
# Recommended: Git Submodule (easily upgradeable)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit

# Alternative: Direct Clone
git clone https://github.com/lowqualityloey/promptkit-os.git .promptkit

# Run platform initialization:
./.promptkit/init.sh      # macOS / Linux (Bash)
.\.promptkit\init.ps1     # Windows (PowerShell)
```

</details>

*(Or instruct your assistant: "Read `.promptkit/protocols/setup.md` to initialize PromptKit OS in this workspace.")*

### 2. What Gets Created in Your Project

The initialization script is transparent and idempotent:
- **`./docs/` directories**: Scaffolds core documentation directories (`tasks/`, `specs/`, `adrs/`, `tests/`). Specialized directories (`auth/`, `data/`, `releases/`, `perf/`, `rca/`) are generated on demand by workflows to keep new projects clean.
- **`./PROMPTKIT.md`**: Project architectural profile containing your active commands, stack constraints, task tracker selector, and monorepo workspace topology.
- **`./docs/STATE.md`**: The living project tracker recording active milestones, tasks in flight, and locked architectural invariants.
- **`.github/pull_request_template.md`**: Staff-level Pull Request template with Gherkin acceptance criteria checklists, Expand-Contract database safety gates, and automated test evidence tables.
- **`.github/ISSUE_TEMPLATE/task.md`**: Standardized task specification issue template for opening structured Gherkin work units directly in GitHub web UI or CLI.
- **Agent Directives**: Injects or updates an idempotent directive block in the hosts you selected (probed or passed via `--host`) — e.g. `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/`, `.clinerules`, `.traerules`, `.opencode/rules.md`, `.windsurfrules`, `.github/copilot-instructions.md`, or `CONVENTIONS.md` (Aider).
- **Just-In-Time (JIT) Workflow Injection**: Zero static token bloat. Workflows are loaded into agent context on-demand from local filesystem files only when triggered (avoiding 18k+ token monolithic prompt injection).
- **Zero-Token Label Provisioning (Optional)**: Provision standardized repository labels (`priority/p0-p3`, `type:*`, `area:*`) with zero token burn using `pwsh -File .promptkit/scripts/setup-github-labels.ps1` (or `bash .promptkit/scripts/setup-github-labels.sh`).
- **Zero Lock-In**: Installs zero binaries, adds zero npm dependencies, and runs zero background daemons.

---

For detailed maintainer release governance, candidate evaluation rules, workflow ownership, validation commands, and contribution expectations, see [`CONTRIBUTING.md`](./CONTRIBUTING.md).

---

## The Mental Model

PromptKit OS structures developer-AI collaboration into four distinct layers:

| Layer | Plain-English Role | Examples | Location |
| :--- | :--- | :--- | :--- |
| **Protocols** | Non-negotiable operating rules the assistant obeys at all times. | Context Sync, Definition of Done, Subagent Delegation | [`protocols/`](./protocols) |
| **Workflows** | Step-by-step engineering procedures for each phase of the dev lifecycle. | `pk:plan`, `pk:test`, `pk:debug`, `pk:commit`, `pk:ship` | [`workflows/`](./workflows) |
| **Templates** | Standardized markdown schemas the assistant fills into your `./docs/` folder. | RFC Specs, MADRs, Test Plans, RCA Post-Mortems | [`templates/`](./templates) |
| **Labs & Notes** | Interactive simulations, competency rubrics, and retro logs for skill building. | System design spikes, refactoring katas, skill matrix | [`activities/`](./activities), [`notes/`](./notes) |

---

## Lifecycle Map & Command Reference

Trigger anytime with `pk:route`. The full lifecycle ASCII map lives in [`docs/WORKFLOW-MAP.md`](./docs/WORKFLOW-MAP.md) alongside decision trees, and the complete 23-command reference (files, outputs, descriptions) in [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md#command-reference). Start with two: `pk:debug` (stops guess-and-patch loops) and `pk:checkpoint` (eliminates session amnesia).

All triggers use the `pk:` prefix to avoid collisions with native slash commands in Antigravity or Cursor.

*Status Legend: All 23 workflows pass CI structural link validation (`validate-references.sh`); 🧪 marks contract-tested workflows. Full table with file links and output targets: [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md#command-reference).*

---

## How the Assistant Operates

You do not need to memorize commands. You can prompt naturally (e.g., *"This checkout endpoint throws 500 errors"* or *"Design a multi-tenant user table"*), and the assistant auto-routes to the proper workflow.

### 1. Task Ceremony Levels (Level 0–3 Execution)

- **Level 0 — Direct**: Questions, explanations, doc typos, formatting, or syntax lookups. Executed directly with zero workflow ceremony or Task Record creation.
- **Level 1 — Standard**: Ordinary localized bug fixes, small self-contained features, or single-component changes modifying source files without schema/data, auth, authorization, public contract, or multi-component risks. Uses natural workflow routing (`pk:debug`, `pk:test`) with lightweight inline/`STATE.md` tracking; does NOT require a Task Record file (`docs/tasks/<task-id>.md`).
- **Level 2 — Controlled**: Work involving relational schema/data migrations, authentication, authorization, breaking public contracts, multiple components, or meaningful architectural risk. Requires a canonical Local Task Record at `docs/tasks/<task-id>.md` and formal specification (`pk:plan`, `pk:data`, `pk:auth`) before implementation.
- **Level 3 — Release-Critical**: Production releases, deployments, tag creation, or high-impact contract changes. Requires Level 2 evidence plus candidate evaluation (`pk:ship`), contract evidence, QA review, and explicit human authorization.
- External issues and board statuses remain optional references or mappings. They do not replace the Local Task Source, and a passing validator does not approve a remote action.

For authoritative Level 0–3 classification, escalation, downgrade, and Task Record rules, see [`workflows/route.md`](./workflows/route.md).

### 2. How It Operates Under the Hood

Subagent delegation, MCP tool precedence, telemetry status cards (opt out with `status-cards: off` in `PROMPTKIT.md`), and interactive decision handoffs — full detail in [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md#operating-model).

---

## How Enforcement Actually Works

PromptKit is an instruction layer, not a compiler or sandbox: protocol guidance, durable Markdown records, read-only local/CI validation, and human approval for every remote action. A passing validator proves evidence consistency only — never approval. Full model and CI detail: [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md#enforcement-model--ci).

---

## How PromptKit Differs from Other Tools

Headline: ~95% / ~88% static reduction vs the ~19.8k core-subset baseline, human-in-the-loop pairing, zero lock-in. Full dimension-by-dimension comparison: [`docs/COMPARISONS.md`](./docs/COMPARISONS.md#how-promptkit-differs-from-other-tools).

---

## Repository Layout

```text
promptkit-os/
├── CHANGELOG.md, FAQ.md, QUICKSTART.md, init.sh / init.ps1, LICENSE
├── docs/            # BENCHMARKS, WORKFLOW-MAP, ADOPTION-GUIDE, COMPARISONS,
│                    # ARCHITECTURE, BEHAVIORAL-EVAL, adrs/
├── protocols/       # setup, context-sync, discovery-intake, telemetry-cards,
│                    # code-quality-gate, subagent-delegation
├── workflows/       # 23 step-by-step engineering procedures (pk:route … pk:ship)
├── templates/       # 28 artifact schemas (specs, ADRs, test plans, PR/issue templates)
├── scripts/         # validators, token measurement, eval harness (.sh + .ps1 twins)
├── examples/        # production lifecycle references
└── activities/, notes/ # katas, skill matrices, journals
```

Full annotated tree: [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md#repository-layout).

---

## Customizing Your Project: The 3 Living Files

PromptKit OS keeps universal workflows separated from your repository's specific rules through three living files:

### 1. `PROMPTKIT.md` (Engineering Guardrails & Stack Constraints)
Scaffolded from `templates/project-profile-template.md`. Tells the assistant your non-negotiable boundaries: project domain and users; active test/typecheck/lint commands; pluggable task tracking (`Local Markdown`, `GitHub Issues`, `GitHub Projects v2`, `Obsidian Kanban`, `Linear`, or `Jira`); monorepo package graph with four import boundaries (presentation isolation, client/server split, public exports only, explicit `workspace:*` protocols); hard architectural invariants; and artifact storage paths (`docs/specs/`, `docs/tasks/`, `docs/data/`, `docs/auth/`, `docs/perf/`, etc.).

### 2. `DESIGN.md` (Visual Brand & Anti-Slop Authority)
Optional brand file from `templates/design-profile-template.md` (or via `pk:design`). Supreme visual authority for UI generation: color tokens, anti-slop bans (no purple-to-cyan gradients, no glowing backdrops, no uniform pill badges), typography and `tabular-nums`, surface/radii rules, 44px mobile targets with single-column reflow. An existing custom `DESIGN.md` is detected, never overwritten (see [DESIGN-MD-FAQ.md](./docs/DESIGN-MD-FAQ.md)).

### 3. `docs/STATE.md` (Synchronized Project State Projection)
Scaffolded automatically during initialization from `templates/state-tracker-template.md`. `docs/STATE.md` is a synchronized projection maintained by `pk:checkpoint`, not a competing task source. For Controlled Work, the canonical `docs/tasks/<task-id>.md` Task Record remains authoritative; external issues, dated breakdowns, and conversational claims are supporting references only.
* **Current Position & Milestone**: Active epic, overall health and status (`ACTIVE`, `BLOCKED`, `STABILIZING`), target release, and current working branch.
* **Progress Tracking**: Hierarchical checklist with atomic task status (`[x]` Done, `[/]` In Progress, `[ ]` Queued, `[!]` Blocked).
* **Locked Architectural Invariants**: Non-negotiable decisions made during pairing sessions that future sessions must not regress.
* **Session Continuity**: Updated by `pk:checkpoint`, `pk:tasks`, and `pk:onboard` to eliminate AI context degradation and maintain persistent memory across fresh chats.

---

## Host & External Tool Composition

The installer targets 9 host-specific directive files — Claude Code (`CLAUDE.md`), OpenCode (`.opencode/rules.md`), Cursor (`.cursorrules`), Gemini (`GEMINI.md`), Windsurf (`.windsurfrules`), Copilot (`.github/copilot-instructions.md`), Cline/Roo (`.clinerules`), Trae (`.traerules`), and Aider (`CONVENTIONS.md`) — plus a universal `AGENTS.md` fallback that Antigravity and other AGENTS-aware agents read. It probes installed hosts (or you choose with `--host`), so nothing you do not use gets written — plus subordinate external skills. PromptKit stays authoritative for classification, routing, and gates. Full matrix and governance boundary: [`docs/COMPARISONS.md`](./docs/COMPARISONS.md#host--external-tool-composition).

---

## Updating PromptKit OS

When new workflows, quality gates, or presets are released, pull the latest changes and re-run initialization:

**If installed via Git Submodule:**
```bash
git submodule update --remote .promptkit
./.promptkit/init.sh     # or .\.promptkit\init.ps1 on Windows
```

**If installed via Direct Clone:**
```bash
git -C .promptkit pull
./.promptkit/init.sh     # or .\.promptkit\init.ps1 on Windows
```

The initialization script is idempotent: it refreshes your agent directives in place without duplicating blocks or touching existing project specs.

---

## License
Released under the [MIT License](./LICENSE). Created by [Jonel (lowqualityloey)](https://github.com/lowqualityloey).
