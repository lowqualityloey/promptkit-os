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

## 5. The Two Opt-In Executables

PromptKit OS ships two pieces of opt-in executable enforcement. Both are deliberately narrow, both are installed only on explicit request, both are reversible, and both preserve any pre-existing hook. Neither hook is installed by the installer, the courier, or CI — a clone that never asks for one has no hook at all. (CI does exercise both checkers against the kit's own tree — as a direct gate for the benchmark cards and as a test-suite subject for attribution — which is Tier 1, not a hook.)

### 5a. The AI-attribution `commit-msg` hook

[`scripts/install-attribution-hook.sh`](../scripts/install-attribution-hook.sh) and its PowerShell twin add a managed block to the repository's `commit-msg` hook that runs [`scripts/check-ai-attribution.sh`](../scripts/check-ai-attribution.sh) against the pending message.

What it does is narrower than "checks attribution disclosure", and the direction matters. The checker reads the optional `ai-attribution: off|host-default` preference from `PROMPTKIT.md`, and the hook it feeds is **fail-closed**: the installed line ends `|| exit 1`, so *any* non-zero checker result blocks the commit, not only a detected signature.

| Outcome | Exit | Effect on the commit |
| :--- | :--- | :--- |
| `ai-attribution: off` and the message carries an unsolicited AI signature — one the human did not ask for | 1 (`PROHIBITED`) | **Blocks.** This is the intended failure. |
| `ai-attribution: off` and the message carries no unsolicited signature | 0 (`OK`) | Passes. |
| `ai-attribution: host-default`, or the line is absent | 0 (`SKIP`) | Passes, leaving the host assistant's own attribution convention alone. |
| Invalid preference value, missing or unreadable rules file, missing message payload, or bad arguments | 2 (`INCOMPLETE`) | **Blocks.** The checker cannot decide, so it refuses rather than guessing. |

That last row is the honest part of the design and the reason the hook is described as fail-closed rather than as a signature detector: a misconfigured preference value, a rules file that moved, or a payload it cannot read stops commits until the configuration is fixed. The remedy is to correct `PROMPTKIT.md` or restore the rules file — or to run the installer with `--remove`, which deletes the managed block and leaves the original hook as it was.

So the hook is not a disclosure *requirement*; it is an opt-out guard for users who do not want AI signatures on their commits, and it fails closed when it cannot tell. It never stages, commits, amends, or rewrites history, and `--remove` restores the original hook byte-for-byte and mode-for-mode.

### 5b. The benchmark task-card `pre-commit` hook

[`scripts/install-benchmark-task-card-hook.sh`](../scripts/install-benchmark-task-card-hook.sh) adds a managed block to the `pre-commit` hook that runs [`scripts/check-benchmark-task-cards.sh`](../scripts/check-benchmark-task-cards.sh) when the staged set touches a `benchmarks/tasks/TASK-*.md` card. It fails a card whose `Verify` command orders the suite before the probe, or chains them with `&&`, so the mistake surfaces locally instead of in CI.

This one is **contributor-facing kit tooling**, not a user-project feature: it guards the benchmark task cards that live in this repository, and it is a no-op for a commit that touches no card. It is documented here because it is the second piece of opt-in executable enforcement the kit ships, and leaving it out would overstate how singular the attribution hook is.

### The pattern, and its limit

Both hooks follow the same shape: **opt-in, reversible, managed-block, single-purpose, scoped to one artifact class**. That is the pattern any future executable enforcement would have to follow. Neither generalizes into a governance daemon, and none is planned.

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
- That untrusted repository content is filtered. The Untrusted Content Boundary in [`protocols/context-sync.md`](../protocols/context-sync.md) §3.3 is Tier 3 advisory text: the kit ships no sanitizer, no content scanner, and no runtime interception, so a prompt-injection attempt reaches the agent unfiltered and the boundary only tells the agent how to treat it.

When evaluating PromptKit OS against a governance requirement, locate the requirement on this ladder first. If the requirement needs Tier 1 strength in *your* project, the honest current answer is that PromptKit OS does not provide it — wiring the shipped validators into your own CI is possible (they are plain scripts), but it is a user-side integration, not a shipped feature.
