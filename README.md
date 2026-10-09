# PromptKit OS

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![CI](https://github.com/lowqualityloey/promptkit-os/actions/workflows/ci.yml/badge.svg)](https://github.com/lowqualityloey/promptkit-os/actions)
[![npm version](https://img.shields.io/npm/v/promptkit-os.svg)](https://www.npmjs.com/package/promptkit-os)
[![npm provenance](https://img.shields.io/badge/provenance-attested-brightgreen.svg)](https://search.sigstore.dev/?logIndex=3029590466)
[![GitHub](https://img.shields.io/badge/GitHub-lowqualityloey%2Fpromptkit--os-black.svg)](https://github.com/lowqualityloey/promptkit-os)

The open-source engineering control plane for AI coding agents.  
A lightweight, repository-native system for risk, context, state, autonomy, and verification.

No runtime. No daemon. No model lock-in. No required API.

Generates native instructions and directives for nine installer targets — `claude`, `gemini`, `cursor`, `windsurf`, `copilot`, `cline`, `trae`, `opencode`, `aider` (Claude Code, Gemini CLI/Antigravity, Cursor, Windsurf, GitHub Copilot, Cline/Roo Code, Trae IDE, OpenCode, and Aider) — with `AGENTS.md` created as the universal fallback for any other AGENTS.md-reading host, such as Codex CLI. See [docs/HOST-CONFORMANCE.md](./docs/HOST-CONFORMANCE.md) for the host matrix and its runtime-validated status.

---

## ⚡ Quick Start (10 Seconds)

Add PromptKit OS to any new or existing repository:

```bash
# Recommended (zero prerequisite setup):
npx promptkit-os

# Or via Git submodule:
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh
# (Windows PowerShell: .\.promptkit\init.ps1)
```

In an interactive terminal, the wizard uses arrow keys and Enter for profile and task-tracker choices, then Space and Enter to choose AI-host files. A final review lets you edit a choice, install, or cancel. Existing settings are kept on reruns; command-line flags remain available for automated installs.

To refresh installed directives after updating PromptKit OS, update the kit using the same installation method and rerun its canonical `init.sh` or `init.ps1` installer. The installer regenerates the managed directive block from the selected profile template; custom content outside that block is preserved.

*(For CI pipelines or headless scripts, pass flags directly: `--balanced`, `--lite`, `--host=<name>`.)*

---

## The Problem

AI coding agents are increasingly capable of writing code.  
The harder problem is controlling everything around the code:

- How much context should the agent load for this task?
- How much process does this task actually need?
- What project constraints must survive across sessions?
- How do you prevent architectural decisions from disappearing after context compaction?
- How do you verify that the claimed result was actually executed?
- When should the agent stop instead of continuing unchecked?
- What happens when the scope changes halfway through implementation?
- How do you keep the instruction layer small enough that it does not become another source of token waste?

PromptKit OS is designed around those problems.

---

## The Core Idea

PromptKit separates **engineering control** from **engineering capability**.

```
        HUMAN
          │
          ▼
  ┌───────────────┐
  │  PROMPTKIT OS │  ← Risk · Context · State · Autonomy · Verification
  └───────┬───────┘
          │  JIT workflows + stack knowledge loaded only when relevant
          ▼
  ┌───────────────┐
  │  AI CODING    │  ← The agent executes
  │  AGENT        │
  └───────┬───────┘
          │  edit / run / verify
          ▼
  ┌───────────────┐
  │  EVIDENCE     │  ← tests · builds · checks · diffs
  └───────┬───────┘
          │
          ▼
  ┌───────────────┐
  │ QUALITY GATE  │  ← exit code 0 required — not a claim
  └───────────────┘
```

PromptKit does not try to become the model, IDE, compiler, or autonomous runtime.  
It provides the engineering rules around them.

---

## Start Here: Most Work Is Level 1

You do not need to learn all 26 workflows. Most everyday engineering tasks — bug fixes, small features, isolated component changes — are **Level 1 (Standard)** and need only `pk:route` or `pk:debug` to get started. Heavier ceremony kicks in only when the task warrants it.

> [!TIP]
> Start with two workflows: `pk:debug` (stops guess-and-patch loops) and `pk:checkpoint` (preserves project state and active tasks across context compaction and resets). You do not need to learn all 26 before getting value.

### Everyday Triggers Cheat-Sheet

Prompt your assistant naturally or invoke fast shorthand triggers:

| Command | Purpose | When to Use |
|:---|:---|:---|
| `pk:route` | **Task Intake** | Classifies incoming tasks into Ceremony Levels 0–3 and routes to the right workflow |
| `pk:onboard` | **Project Discovery** | First install on greenfield or brownfield codebases; detects stack & sets rules |
| `pk:plan` | **Feature RFC** | Designing architectural changes, data contracts, and schema boundaries |
| `pk:test` | **Test Strategy & TDD** | Allocating seams, mocking boundaries, and writing tests before code |
| `pk:debug` | **Root-Cause Analysis** | Systematic 5-step falsifiable debugging (stops infinite hallucinated edits) |
| `pk:commit` | **Pre-Commit Gate** | Secret scanning, running test suites, and authoring atomic conventional commits |
| `pk:checkpoint` | **Session Handover** | Saving active tasks and state to Git before ending your chat session |

### What PromptKit Looks Like in Chat

PromptKit standardizes agent telemetry into clean 3-line status cards without verbose conversational fluff:

```text
> 📊 **Milestone**: 02-user-auth [■■■■□□] 4/6 — source: STATE.md read this turn
> 🎯 **Active**: Task 2.3 — Implement JWT refresh token rotation
> 🟢 **Quality Gate**: measured this turn (flutter test: 14 passed, exit 0)
```

---

## What PromptKit Controls

### Task Ceremony Levels (Level 0–3 Execution)

Every task is routed through four ceremony levels before work begins:

- **Level 0 — Direct**: Questions, explanations, doc typos, formatting, or syntax lookups. Zero overhead.
- **Level 1 — Standard**: Localized bug fixes or small self-contained features. Level 1 does NOT require a Task Record file (`docs/tasks/<task-id>.md`).
- **Level 2 — Controlled**: Schema, auth, multi-component, or public contract changes. Level 2 Requires a canonical Local Task Record at `docs/tasks/<task-id>.md` before implementation.
- **Level 3 — Release-Critical**: Releases, deployments, high-impact contract changes. Level 3 Requires Level 2 evidence and Task Record readiness, plus human authorization.

The principle: use the minimum ceremony appropriate to the risk.

For authoritative Level 0–3 classification, escalation, downgrade, and Task Record rules, see [`workflows/route.md`](./workflows/route.md).

### Context — Just-In-Time Loading & Context Economy

The core instruction layer stays small. Workflows, stack playbooks, and boundary recipes are loaded only when the task requires them.

- **Balanced** profile: ~2,341 tok static footprint (~93% static saving vs. ~32.0k current core-subset baseline; 2,500 tok budget cap)
- **Lite** profile: ~1,436 tok static footprint (~96% static saving vs. the current baseline; 1,500 tok budget cap)

PromptKit couples JIT loading with the **Context Economy Protocol** ([`protocols/context-economy.md`](./protocols/context-economy.md)), governing **Minimum Sufficient Context** and adaptive **Z0–Z4 context zoom** (decoupled from L0–L3 task risk ceremony). Retrieval confidence is treated as evidence rather than authority, and high-risk boundaries direct the agent to zoom out. These are advisory agent instructions: CI asserts that the invariant text is present and that the directive token budgets hold, but PromptKit does not enforce this protocol at runtime — see the enforcement boundary recorded in that file.

Full workflows are read from local files only when triggered. See [`docs/BENCHMARKS.md`](./docs/BENCHMARKS.md) and [`docs/BENCHMARK-METHODOLOGY.md`](./docs/BENCHMARK-METHODOLOGY.md) for Cost Per Accepted Change (CPAC) methodology.

### State — Durable Across Sessions

AI sessions are temporary. Repositories are not.

PromptKit stores engineering state in Git-tracked project files: `PROMPTKIT.md`, `docs/STATE.md`, `docs/tasks/`, `docs/specs/`, `docs/adrs/`. Active milestones, task state, and architectural invariants survive context compaction, new sessions, and agent changes.

### Autonomy — Bounded, Not Unlimited

PromptKit introduces explicit limits around investigation loops, repeated repair attempts, scope changes, and high-risk operations. When a boundary is exceeded, the system records state and escalates rather than continuing unchecked.

### Verification — Evidence, Not Claims

An agent saying *"the implementation is complete"* is not evidence.

PromptKit's quality gate protocols instruct the agent to execute real verification commands (`exit code 0` required) before marking tasks complete. Bounded repair is capped at 2 automated attempts before escalating to the developer. The human remains the sole authority for acceptance, commit approval, and release decisions.

---

## Architecture

```
.promptkit/
├── protocols/       # Core control — risk routing, evidence gates, context sync
├── workflows/       # 26 engineering procedures (pk:route → pk:ship)
├── docs/
│   ├── stacks/      # JIT stack playbooks — Next.js, Supabase, Vercel, Expo, Flutter, Rust, Go, Python
│   ├── recipes/     # Boundary contracts — auth sessions, form mutations, webhooks, env, test isolation
│   └── adrs/        # Architecture decisions
├── templates/       # 29 durable engineering artifact schemas (.md files; the one non-schema asset, `terminal-banner.txt`, is excluded)
├── scripts/         # Validation, token measurement, CPAC benchmarking (.sh + .ps1 twins)
└── examples/        # Reference implementations
```

The architectural boundary: **PromptKit owns engineering policy and control. The host agent owns capability and execution.**

---

## Getting Started

### 1. Install

Run in your project root:

```bash
# Recommended (zero prerequisite setup):
npx promptkit-os

# Or via Git submodule:
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh
# (Windows PowerShell: .\.promptkit\init.ps1)
```

In an interactive terminal, use ↑/↓ and Enter for profile and task-tracker choices, then Space and Enter to toggle AI-host files. The final review lets you edit a choice, install, or cancel. Existing settings are kept on reruns.

<details>
<summary>Non-Interactive / CI Flags</summary>

Pass flags directly to bypass the interactive prompts in automated environments:

```bash
# Balanced profile (full 26 workflows)
./.promptkit/init.sh --balanced
# Lite profile (smallest footprint, 6 workflows)
./.promptkit/init.sh --lite
# Specify assistant directly
./.promptkit/init.sh --balanced --host=cursor
# Or via npx
npx promptkit-os@latest --balanced
npx promptkit-os@latest --lite
```

</details>

> [!NOTE]
> The git submodule flow above is canonical. The npm package is a **courier, not a dependency** — it fetches the release tarball matching its version into `.promptkit/` and runs the same installer, producing an identical tree. `npx promptkit-os@X.Y.Z` always resolves to release tag `vX.Y.Z`. It requires Node 18+ (and PowerShell 7 on Windows), and it refuses to overlay a non-empty `.promptkit/`, printing the update command that matches how the existing install was made. Removal: delete `.promptkit/` (plus generated `PROMPTKIT.md` / `docs/STATE.md` if unwanted) — no daemon, nothing left behind.

Already installed? To pull updates, see [Updating PromptKit](./QUICKSTART.md#updating-promptkit).

### 2. Configure

The installer creates `PROMPTKIT.md` (your project profile — test commands, stack constraints, architectural invariants) and `docs/STATE.md` (living project state). Run `pk:onboard` for a guided setup interview.

### 3. Work normally

You do not need to memorize commands. Prompt your agent naturally:

> *"The checkout endpoint is returning 500 errors."*

PromptKit routes the task to the appropriate ceremony level and workflow. Explicit routing: `pk:route`.

---

## Documentation

| Document | Audience |
| :--- | :--- |
| **[QUICKSTART.md](./QUICKSTART.md)** | I want to use it — 5-minute guided tour |
| **[FAQ.md](./FAQ.md)** | I have a specific question — 20 common questions |
| **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** | I want to understand how it works |
| **[docs/BENCHMARKS.md](./docs/BENCHMARKS.md)** | I want static token budget evidence |
| **[docs/BENCHMARK-METHODOLOGY.md](./docs/BENCHMARK-METHODOLOGY.md)** | I want the CPAC engineering benchmark methodology |
| **[docs/COMPARISONS.md](./docs/COMPARISONS.md)** | I want to compare it with other tools |
| **[docs/stacks/](./docs/stacks/)** | I want JIT stack playbooks (23 — Web, DB, Cloud, Mobile, Systems, CLI) |
| **[docs/recipes/](./docs/recipes/)** | I want reusable boundary contracts (10 — Auth, Forms, Webhooks, Env, Testing, State, Realtime + 3 pk:auto utilities) |
| **[docs/ADOPTION-GUIDE.md](./docs/ADOPTION-GUIDE.md)** | I want to add it to an existing project gradually |
| **[docs/MAXIMS.md](./docs/MAXIMS.md)** | I want the quotable invariants — 9 one-line maxims with canonical links |
| **[CONTRIBUTING.md](./CONTRIBUTING.md)** | I want to extend or contribute |

---

## Validation

PromptKit's own CI validates on every PR across Linux and Windows:

- Workflow and documentation reference integrity (`validate-references.sh`)
- Static token budget gates — Balanced ≤ 2,500 tok, Lite ≤ 1,500 tok (`measure-tokens.sh --strict`)
- Behavioral contract compliance — all behavioral contract tests pass (live count in CI) (`run-behavioral-contract-tests.sh`)
- Playbook & recipe contracts — 33/33 (23 stack playbooks + 10 boundary recipes) (`run-playbook-contract-tests.sh`)

PromptKit applies its own engineering principles to itself.

---

## Why Deliberately Small

The temptation in AI tooling is to add more agents, more skills, more prompts, more context.

PromptKit takes the opposite approach. Its core question is:

> *What is the minimum context, ceremony, and autonomy required to safely complete this task?*

That is why workflows, stack knowledge, and recipes are separate and loaded just in time. The goal is not the largest AI engineering framework. The goal is a small control plane that makes many different AI engineering capabilities safer and more efficient to use.

---

## Support

If you find PromptKit OS valuable for your engineering workflow, consider supporting its open-source development:

<a href="https://buymeacoffee.com/itsjonellmb" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50"></a>

---

## License

Released under the [MIT License](./LICENSE). Created by [Jonell (lowqualityloey)](https://github.com/lowqualityloey).
