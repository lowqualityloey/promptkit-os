---
name: auto-phrase-boundary-sheet
category: recipe
version: 1
token_budget: 1500
description: Plain-English phrase to pk:auto stop-boundary mapping, paste-ready for consumer PROMPTKIT.md files.
---

# `pk:auto` Phrase → Boundary Sheet

Plain English reliably **starts** `pk:auto` (Smart Auto-Route); explicit flags are only needed when you want a stop boundary other than the default. Paste the table into your project's `PROMPTKIT.md` to make routing deterministic for your team without memorizing flags.

---

## 1. Trigger phrases (no `pk:` prefix required)

| Say this | Routes to | Announced as |
|---|---|---|
| "handle this end-to-end" | `workflows/auto.md` | Turn-1 leash banner, default stop `review ready` |
| "leave it in automation" / "hands-off" | `workflows/auto.md` | Same banner, default stop `review ready` |
| "run everything, all tasks" | `workflows/auto.md` (`--full`) | Standing authorization for this run only, scope frozen at invocation |
| "handle it end-to-end and open a draft PR" | `workflows/auto.md` (`--until pr`) | Standing authorization for push + draft-PR creation within this run; merge stays human |

## 2. Boundary flags (for when words are ambiguous)

| Flag | Stopping condition | Behavior at stop |
|---|---|---|
| `--until review` (default) | `review ready` | Planning, coding, testing, review. Halts before any commit, PR, or push |
| `--until test` | `tests green` | Halts once tests pass, before review audits |
| `--until task` | `task done` | Single active subtask only, then halt |
| `--until pr` | `pr ready` | Atomic commits, push feature branch, open draft PR. Halts before merge |
| `--full` | `all tasks completed` | Iterates uncompleted tasks at invocation snapshot, commits atomically, opens PR, halts |

## 3. Standing rules (paste with the table)

- Invocation **is** the authorization, scoped to the declared boundary only; it does not survive the run's stop conditions.
- Any circuit-breaker trip, failed review gate, or scope growth halts for human resume.
- Merge, tag, publish, deploy, and rollback are never included — always a separate explicit human action.

---

## Related references

- Boundaries: [`workflows/auto.md`](../workflows/auto.md)
- Authority table: [`protocols/code-quality-gate.md`](../protocols/code-quality-gate.md)
