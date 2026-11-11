# The PromptKit OS Enforcement Ladder

<a id="DOC-ENFORCEMENT"></a>

PromptKit OS governs agent behavior through markdown instructions, and it is frequently asked what actually *enforces* that governance. The honest answer is layered: different mechanisms bind in different places, and none of them follows a user project out of the kit repository by default. This document maps the full ladder — what is enforced, by what, and where — so that neither the project's claims nor a user's assumptions outrun the mechanics.

> *"Markdown instructs; it cannot stop tools by itself."* ([`docs/BENCHMARKS.md`](./BENCHMARKS.md))

---

## 1. The Ladder at a Glance

| Tier | Where it binds | Mechanism | What it can actually do | Default posture in a user project |
| :--- | :--- | :--- | :--- | :--- |
| **1 — CI-enforced** | The PromptKit OS kit repository only | GitHub Actions workflow ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)) | Block a change to the kit itself: docs contracts, token budgets, reference links, behavioral contract text, installer safety, twin parity | **Never applies.** A user project inherits none of it; the checks run against the kit's own tree, not the user's. |
| **2 — Auditable on demand** | An installed project, when someone runs it | `pk:doctor` and the validation scripts shipped in `.promptkit/scripts/` | Read-only audit and measurement: report rot, drift, version skew, token budgets, ceremony baselines. Never writes, never blocks | **Dormant.** Nothing schedules, hooks, or invokes these; they run only when the user or the agent chooses to. |
| **3 — Advisory directive** | The host agent's context window | The managed directive block injected into `AGENTS.md` / `CLAUDE.md` / host files | Direct the agent: ceremony levels, workflow routing, context economy, checkpoint discipline. No executor exists | **Always present** (that is the product), and **always advisory**: whether the agent follows it is decided by the host assistant, not by PromptKit OS. |

The ladder is strictly ordered by enforcement strength, and it **descends** as it leaves the kit repository: CI can reject a commit; `pk:doctor` can only report; the directive can only instruct.

---

## 2. Tier 1 — CI-Enforced (Kit Repository Only)

The kit's own CI is the only place where PromptKit OS governance is *mechanically* enforced. The workflow gates changes to the kit itself across both Linux and Windows runners, including:

- **Documentation contracts**: reference-link harness, structural validator, prompt hygiene, fragile-math-label and CHANGELOG-entry gates.
- **Token budgets**: directive token budget (Balanced ≤ 2,500 / Lite ≤ 1,500 tokens), per-task token baselines, and ceremony artifact baselines (asserted by [`scripts/measure-ceremony-overhead.sh`](../scripts/measure-ceremony-overhead.sh) and its PowerShell twin).
- **Behavioral contract text**: the behavioral-contract test suite asserts that policy files still contain their required invariant sentences — text presence, not agent compliance.
- **Installer safety**: `init.sh` / `init.ps1` safety regression twins, profile matrix, dry-run and idempotency, doctor twins, changelog gate, harness security scan.
- **Execution-control records**: the repository self-validates its own Task Records with [`scripts/validate-execution-control.sh`](../scripts/validate-execution-control.sh).

**Scope boundary.** Every one of these checks inspects the kit's tree. A user project that installs PromptKit OS gets **zero** of these gates: its CI (if any) knows nothing about PromptKit, and nothing in the install wires these scripts into the user's pipelines. Tier 1 exists to keep the *kit* honest; it does not travel.

---

## 3. Tier 2 — Auditable on Demand (Installed Projects)

An installed project carries the kit at `.promptkit/`, and with it the audit surface:

- **`pk:doctor`** — a read-only audit of host directives, engine version, ignore-state, docs drift, intake provenance, and submodule registration. It reports rot and never writes ([`README.md`](../README.md)). It is the engine-run self-audit: meaningful exactly when someone runs it, and silent otherwise.
- **Validation and measurement scripts** — `validate-execution-control`, `measure-tokens`, `measure-ceremony-overhead`, `check-changelog-entry`, and the rest of `.promptkit/scripts/` are shipped to the installed project and *can* be run there (for example, to check the project's own Task Records or token budgets). They are the same scripts CI runs in the kit repo — but in a user project **nothing schedules them**. No hook, no pipeline, no pre-commit wiring exists by default; the courier and the installer stage the files and stop.

Tier 2 is therefore an *capability*, not an *enforcement*: the tools are present and honest, and using them is a choice made per session.

---

## 4. Tier 3 — Advisory Directive (Agent Behavior)

The managed directive block (and the JIT-loaded workflow files it points at) is the layer users actually experience. It directs ceremony levels, routing, checkpoints, and the Context Economy Protocol ([`protocols/context-economy.md`](../protocols/context-economy.md)). Its constraints are obligations addressed to the agent:

- PromptKit OS ships **no daemon, hook, or interceptor** that can block an edit, abort a turn, or force a zoom-out.
- The host assistant decides whether the directive is followed; fidelity varies by host ([`docs/HOST-CONFORMANCE.md`](./HOST-CONFORMANCE.md) tracks which hosts are validated and which remain untested for live runtime fidelity).
- CI's text-presence assertions (Tier 1) observe the *files*, never the *agent*.

---

## 5. The One Opt-In Executable: the Attribution Hook

PromptKit OS ships exactly one piece of opt-in executable enforcement, and it is deliberately narrow: the AI-attribution `commit-msg` hook ([`scripts/install-attribution-hook.sh`](../scripts/install-attribution-hook.sh) and its PowerShell twin). It is installed only on explicit request, is reversible, preserves any pre-existing hook, and checks one thing — attribution disclosure in commit messages. It demonstrates the pattern any future executable enforcement would have to follow: **opt-in, reversible, managed-block, single-purpose**. It does not generalize into a governance daemon, and none is planned.

---

## 6. What This Ladder Claims — and What It Does Not

**Claims:**

- The kit's own behavior surface is mechanically gated (Tier 1), on both shell and PowerShell twins.
- An installed project can *audit itself* at any time with read-only tools (Tier 2).
- Every user-facing rule is written down and directed at the agent (Tier 3).

**Does not claim:**

- That a user project has any automatic enforcement of PromptKit OS rules. It does not; the default posture is Tier 3 alone.
- That `pk:doctor` or the shipped scripts run unless someone runs them.
- That any directive statement is runtime-enforced. The Context Economy boundary statement in [`protocols/context-economy.md`](../protocols/context-economy.md) applies to the whole product: PromptKit OS contains no mechanism that executes or enforces its `MUST` / `MUST NOT` statements.

When evaluating PromptKit OS against a governance requirement, locate the requirement on this ladder first. If the requirement needs Tier 1 strength in *your* project, the honest current answer is that PromptKit OS does not provide it — wiring the shipped validators into your own CI is possible (they are plain scripts), but it is a user-side integration, not a shipped feature.
