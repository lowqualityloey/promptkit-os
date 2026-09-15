# Pilot B: Mid-Implementation Requirement Delta (Scenario Walkthrough)

- **Date**: 2026-09-16 · **Baseline**: main @ `a21ed56` · **Type**: dry-run walkthrough (protocol trace, not a live agent session)
- **Continues Pilot A**: implementation underway when the user says: "actually, also add cloud sync across devices."

## Walkthrough (per shipped docs)

1. **Interception point** (`workflows/sync.md` New-Requirement Interception table / `workflows/checkpoint.md` delta rule): new requirement during execution is **never silently absorbed**.
2. **Classification**: cloud sync = new architecture + data-model + deployment implications → **not** doc-only, **not** a mere Scope Change Record.
3. **Required handling**: execution blocks (`checkpoint_due`); `pk:plan` re-opens with `intake-status: partial`; Step 0 asks **only the missing critical slots** for sync (provider, conflict resolution, identity) — never a full re-interview (Scenario 4 boundary) — and records results **without downgrading** the status.
4. **Simulated user pushback**: "skip sync for v1" → recorded in the **Later ledger** with trigger condition ("when >1 device becomes real"); plan resumes at original scope; Task Record unchanged; Scope Change Record not required because scope reverted to the recorded baseline.

## Measured cost (bytes/4)

| Item | Tokens |
|:---|---:|
| Interception guidance added to `workflows/sync.md` (+17 lines) | ~700 |
| Re-planning reload (`plan.md` payload, gated ≤ 24,666) | 16,333 |
| Avoided waste (pre-wave: sync likely built inline mid-task, then reworked) | unquantified — trace only |

## Outcome vs. prior behavior
- Pre-wave: the delta had no interception rule; risk was silent scope growth or an unrecorded rejection.
- Post-wave: explicit classify → block/append/defer table; the rejection is **recorded with a trigger**, so v1 scope is protected and the idea survives.
- **Not measured (honest)**: live interception fidelity in a real agent session.
