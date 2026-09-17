# Lite Quickstart — Reference Example (Lite Profile)

A minimal Lite-profile project: `profile: lite`, 6 utility workflows (`pk:route`, `pk:debug`, `pk:commit`, `pk:checkpoint`, `pk:sync`, `pk:profile`), and an on-demand `docs/` layout. For the full Balanced reference, see [`saas-dashboard/`](../saas-dashboard/).

## Minimal `docs/` Structure

```text
lite-quickstart/
├── PROMPTKIT.md        # profile: lite + commands + guardrails
├── README.md           # this walkthrough
└── docs/
    ├── STATE.md        # living project state (only required file)
    └── adrs/           # created when the first ADR is written
```

Lite keeps specialized dirs (`specs/`, `tasks/`, `auth/`, `data/`, `api/`, …) on-demand only — they appear when a workflow needs them, not up front.

## Annotated Session: L0 → L1

> `[PromptKit OS Lite: Level 0 — question, direct answer, no ceremony]`

**You**: "Where does the empty-notes validation live?"

**Agent** (TL;DR first, ≤40 words): "In `src/notes.ts:42` — `isValidNote()` rejects empty titles. Next: tell me the failing input and I'll fix it."

> `[PromptKit OS Lite: Level 1 — localized bug fix, inline planning, no Task Record file]`

**You**: "Empty titles with only spaces slip through. Fix it."

**Agent**:
1. `pk:debug` — reproduces with `"   "` → confirms `trim()` is missing.
2. Edits `src/notes.ts` (source only — test assertions untouched).
3. Runs `pnpm test` → green.
4. `pk:commit` — atomic Conventional Commit + secret-leak scan.
5. `pk:checkpoint` — syncs `docs/STATE.md`, hands over a resume prompt.

## When to Upgrade to Balanced

Lite covers ~80% of work, but L2/L3 need Balanced:

- **L2 Controlled** (schema, auth, permissions, public contracts, multi-component): Lite answers with *"Recommend switching to Balanced (`init.sh --balanced`)"* because L2 requires `docs/tasks/<task-id>.md` + spec ceremony Lite does not scaffold.
- **L3 Release-Critical** (release, tag, deploy): *"Requires Balanced or Turbo"* — `pk:ship` plus human approval.

Upgrade any time without losing state:

```bash
.promptkit/init.sh --balanced
# or in-session:
pk:profile
```

Your `docs/STATE.md` carries over; only the workflow set and ceremony expand.

## What L2 Looks Like on Lite (Explicit)

**You**: "Add OAuth login with per-workspace roles."

**Agent**: `[PromptKit OS Lite: Level 2 — auth + multi-component, recommend Balanced]`

> This is L2 Controlled work (auth, permissions, public contract). Lite recommends switching to Balanced for the full task-record + spec ceremony:
>
> ```bash
> .promptkit/init.sh --balanced
> ```
>
> I can still answer questions about the design here, but I won't scaffold L2 artifacts on Lite.

## Files in This Example

- [`PROMPTKIT.md`](./PROMPTKIT.md) — `profile: lite` with commands and guardrails
- [`docs/STATE.md`](./docs/STATE.md) — minimal state tracker after the L1 fix
