# PromptKit OS

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![CI](https://github.com/lowqualityloey/promptkit-os/actions/workflows/ci.yml/badge.svg)](https://github.com/lowqualityloey/promptkit-os/actions)
[![GitHub](https://img.shields.io/badge/GitHub-lowqualityloey%2Fpromptkit--os-black.svg)](https://github.com/lowqualityloey/promptkit-os)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Donate-orange?style=flat&logo=buy-me-a-coffee&logoColor=white)](https://buymeacoffee.com/itsjonellmb)

The open-source engineering control plane for AI coding agents.  
A lightweight, repository-native system for risk, context, state, autonomy, and verification.

No runtime. No daemon. No model lock-in. No required API.

Works with Claude Code, Gemini CLI, Cursor, Windsurf, GitHub Copilot, Cline, Roo Code, Trae, OpenCode, Aider, and Antigravity.

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

You do not need to learn all 24 workflows. Most everyday engineering tasks — bug fixes, small features, isolated component changes — are **Level 1 (Standard)** and need only `pk:route` or `pk:debug` to get started. Heavier ceremony kicks in only when the task warrants it.

> [!TIP]
> Start with two workflows: `pk:debug` (stops guess-and-patch loops) and `pk:checkpoint` (eliminates session amnesia). You do not need to learn all 24 before getting value.

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

### Context — Just-In-Time Loading

The core instruction layer stays small. Workflows, stack playbooks, and boundary recipes are loaded only when the task requires them.

- **Balanced** profile: 2,498 tok static footprint (87% reduction vs ~19.8k derived core-subset baseline)
- **Lite** profile: 1,146 tok static footprint (94% reduction)

Full workflows are read from local files only when triggered. See [`docs/BENCHMARKS.md`](./docs/BENCHMARKS.md) and [`docs/BENCHMARK-METHODOLOGY.md`](./docs/BENCHMARK-METHODOLOGY.md) for Cost Per Accepted Change (CPAC) methodology.

### State — Durable Across Sessions

AI sessions are temporary. Repositories are not.

PromptKit stores engineering state in Git-tracked project files: `PROMPTKIT.md`, `docs/STATE.md`, `docs/tasks/`, `docs/specs/`, `docs/adrs/`. Active milestones, task state, and architectural invariants survive context compaction, new sessions, and agent changes.

### Autonomy — Bounded, Not Unlimited

PromptKit introduces explicit limits around investigation loops, repeated repair attempts, scope changes, and high-risk operations. When a boundary is exceeded, the system records state and escalates rather than continuing unchecked.

### Verification — Evidence, Not Claims

An agent saying *"the implementation is complete"* is not evidence.

PromptKit requires a verification command to execute and return `exit code 0` before a quality gate is marked passed. Bounded repair is capped at 2 automatic attempts before requiring human intervention. The human remains the authority for acceptance and release decisions.

---

## Architecture

```
.promptkit/
├── protocols/       # Core control — risk routing, evidence gates, context sync
├── workflows/       # 24 engineering procedures (pk:route → pk:ship)
├── docs/
│   ├── stacks/      # JIT stack playbooks — Next.js, Supabase, Vercel, Expo, Flutter, Rust, Go, Python
│   ├── recipes/     # Boundary contracts — auth sessions, form mutations, webhooks, env, test isolation
│   └── adrs/        # Architecture decisions
├── templates/       # 28 durable engineering artifact schemas
├── scripts/         # Validation, token measurement, CPAC benchmarking (.sh + .ps1 twins)
└── examples/        # Reference implementations
```

The architectural boundary: **PromptKit owns engineering policy and control. The host agent owns capability and execution.**

---

## Getting Started

### 1. Install

```bash
# macOS / Linux — Balanced profile (default)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --balanced

# Lite profile (smallest footprint, 80% value — good for onboarding)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --lite

# Windows (PowerShell)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --balanced
```

> [!TIP]
> Start with two workflows: `pk:debug` (stops guess-and-patch loops) and `pk:checkpoint` (eliminates session amnesia). You do not need to learn all 24 before getting value.

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
| **[docs/stacks/](./docs/stacks/)** | I want JIT stack playbooks (11 — Web, DB, Cloud, Mobile, Systems) |
| **[docs/recipes/](./docs/recipes/)** | I want reusable boundary contracts (5 — Auth, Forms, Webhooks, Env, Testing) |
| **[docs/ADOPTION-GUIDE.md](./docs/ADOPTION-GUIDE.md)** | I want to add it to an existing project gradually |
| **[CONTRIBUTING.md](./CONTRIBUTING.md)** | I want to extend or contribute |

---

## Validation

PromptKit's own CI validates on every PR across Linux and Windows:

- Workflow and documentation reference integrity (`validate-references.sh`)
- Static token budget gates — Balanced ≤ 2,500 tok, Lite ≤ 1,500 tok (`measure-tokens.sh --strict`)
- Behavioral contract compliance — 178/178 tests (`run-behavioral-contract-tests.sh`)
- Playbook contracts — 11/11 (`run-playbook-contract-tests.sh`)

PromptKit applies its own engineering principles to itself.

---

## Why Deliberately Small

The temptation in AI tooling is to add more agents, more skills, more prompts, more context.

PromptKit takes the opposite approach. Its core question is:

> *What is the minimum context, ceremony, and autonomy required to safely complete this task?*

That is why workflows, stack knowledge, and recipes are separate and loaded just in time. The goal is not the largest AI engineering framework. The goal is a small control plane that makes many different AI engineering capabilities safer and more efficient to use.

---

## License

Released under the [MIT License](./LICENSE). Created by [Jonel (lowqualityloey)](https://github.com/lowqualityloey).
