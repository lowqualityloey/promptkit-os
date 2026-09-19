---
name: auto-waves-preflight-checklist
category: recipe
version: 1
token_budget: 1500
description: Pre-flight eligibility checklist for pk:auto Turbo wave execution (--waves N).
---

# `pk:auto` Wave Pre-Flight Checklist

Tick every box **before** running `pk:auto --waves N`. One unticked box means sequential execution — a wave with hidden dependencies is sequential work mislabeled parallel (`workflows/auto.md`).

---

## 1. Eligibility (all required — hard invariant)

- [ ] **Independent task contracts** — no shared mutable contract surface between workers in the same wave.
- [ ] **Disjoint file ownership** — no two workers create or modify the same file.
- [ ] **No shared generated artifacts, migrations, or schema ownership** — one owner per artifact per wave.
- [ ] **No dependency between workers in the same wave** — dependent tasks belong to later waves; no worker consumes another worker's unreviewed output.
- [ ] **Needs/produces declared (one line each, evidence not proof)** — every worker states what it needs satisfied before launch and what files/contracts it produces; anything unconfident stays sequential.
- [ ] **Task size justifies coordination** — skip waves for fewer than 2 genuinely independent tasks, trivial/L0 work, or lanes cheaper than dispatch + synthesis; run those sequentially.

## 2. Host & profile

- [ ] **Turbo profile active with explicit `--experimental` acknowledgement** — otherwise the run falls back to sequential review-ready.
- [ ] **Host runs N lanes concurrently** — if unsupported, expect sequential execution with identical correctness and zero wall-clock benefit.

## 3. Leash (confirm, do not renegotiate mid-run)

- [ ] **Terminal boundary declared** (`--until review` default, or `test` / `task` / `pr` / `--full`) and recorded in the first `docs/STATE.md` micro-checkpoint.
- [ ] **Failure budget understood**: Strike 1 = initial failure, Strikes 2–3 = refines, then park with diagnostics (one park/resume boundary per wave).
- [ ] **Review checkpoint after every wave**; merge, tag, publish, deploy, and rollback stay human-only.

---

## Related references

- Wave rules: [`workflows/auto.md`](../workflows/auto.md)
- Delegation patterns: [`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md)
- Autonomy budgets: [#258](https://github.com/lowqualityloey/promptkit-os/issues/258)
