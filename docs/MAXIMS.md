# PromptKit OS Maxims

Quotable one-line invariants that distill existing doctrine. This page **summarizes, never legislates** — a maxim without a canonical home is a proposed change, not a summary. Each line links its canonical source; where this page and the source differ, the source wins.

- **Evidence before completion.** Completion claims require executed evidence with `exit code 0`. ([code-quality-gate.md § Bounded Oracle](../protocols/code-quality-gate.md))
- **Risk before ceremony.** Every task is classified Level 0–3 before work begins; ceremony follows risk. ([route.md](../workflows/route.md))
- **Scope before mutation.** Lock scope to one load-bearing concern before editing. ([fix.md Step 1](../workflows/fix.md))
- **Context expands with uncertainty.** Acquire minimum sufficient context, then escalate when risk or uncertainty requires it. ([context-economy.md](../protocols/context-economy.md))
- **Retrieval confidence is evidence, not authority.** High retrieval confidence never bypasses Hard Escalation Triggers. ([context-economy.md §2](../protocols/context-economy.md))
- **Persist decisions, not transcripts.** Task Records own execution state; `docs/STATE.md` is the synchronized projection. ([checkpoint.md](../workflows/checkpoint.md), [context-sync.md](../protocols/context-sync.md))
- **Use the smallest verified change.** One concern per fix, one concern per commit. ([fix.md](../workflows/fix.md), [commit.md](../workflows/commit.md))
- **Reversible is not the same as authorized.** Silence is denial for remote actions; merge, tag, publish, deploy, and rollback always need explicit human action. ([code-quality-gate.md authorization table](../protocols/code-quality-gate.md))
- **Never derive a base from a synthetic workspace commit.** Return to the carrying branch or rebase before resolving a comparison base. ([sync.md Phase 1](../workflows/sync.md), [review.md](../workflows/review.md))
