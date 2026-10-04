<!-- PROMPTKIT_START -->
## PromptKit OS Lite: Engineering Operating System (Lite Profile)

PromptKit OS Lite is active in this workspace (`./$KIT_DIR_REL`). Lightweight mode: 6 utility workflows, <1,500 tok, 80% value. For the full Balanced profile, run `init.sh --balanced`.

### Fast Shorthand Triggers (Lite - 6 workflows)
- `pk:route`: Workflow router — what workflow do I need?
- `pk:debug`: Scientific debugging — hypothesis-driven, 5 Whys, regression test
- `pk:commit`: Atomic Conventional Commits + secret leak scan
- `pk:checkpoint`: Session state sync to `docs/STATE.md` + handover prompt
- `pk:sync`: Hot-reload protocols from disk (purge stale memory)
- `pk:profile`: Switch Lite/Balanced/Turbo profile at runtime via installer re-injection

### Smart Guardrails (Lite)
- **Fast-Path**: Questions, typos, 1-line tweaks → answer directly, no ceremony. 1-line security/data edits escalate to L2.
- **No Secret Leak**: Never output/request raw secrets. Use `.env.example` + local `.env`.
- **Context Economy**: Lowest-cost context first; escalate on Hard Triggers. Anti-Starvation: halt before guessing.
- **Circuit Breaker (advisory)**: 1 unit=1 read. Halt >6 w/o edit: ask for paths. Trivial edits do not reset. Read-only tasks exempt; static budget only.
- **Anti-Slop**: TL;DR 1-3 bullets (≤40w) → Details (tables/checklists) → Next. No essay walls. L0 exempt.
- **Choices**: max 3-4 options (action+outcome+time+req) + safe exit for Type A/B choices under Next Steps per `card-style:` in `PROMPTKIT.md` (framed box default; `> [!TIP]` when markdown), Option 1 `(Recommended + why)`. Single number executes. Type C/D choices halt with ACTION REQUIRED (framed or `> [!IMPORTANT]`) instead — never a TIP.
- **Decisions**: recommendation mandatory on every choice; owner may reply "you decide" to delegate Type A/B choices (recorded, agent-owned); Type C/D choices require a human decision with no delegation; unanswerable questions become Assumption Records, never guesses (see Decision routing rule in `protocols/code-quality-gate.md`).
- **Telemetry Cards & Callout**: format card and callouts per `card-style:` (framed ceiling/floor box default; GFM alert when markdown per `protocols/telemetry-cards.md`; `[■■■■■■■■□□]` n/m · quality gate measured/not measured). Max 1 callout/turn (IMPORTANT > WARNING > TIP). Suppress on `status-cards: off` (default on). Halting → ACTION REQUIRED (PR links `👉 [#N](url)`).
- **Disk-First**: Always read `$KIT_DIR_REL/workflows/<trigger>.md` fresh from disk, never rely on memory. `pk:sync` refreshes. Nudge at ~15 substantive turns, hard checkpoint ~30 turns; when `docs/STATE.md` invariants cannot be recited fresh, run `pk:checkpoint` and recommend a fresh session; unpopulated STATE.md fields report `not tracked`, never computed-looking numbers.
- **Context Recovery**: After handover, compaction/continuation, task-invariant loss, or status interruption, pause writes; read `$KIT_DIR_REL/workflows/sync.md` before resuming.
- **DB Isolation**: Use project-scoped containers, never foreign DBs.
- **Git Boundaries**: Never start new milestone with dirty tree. At milestone end: verify, `pk:commit`, update `docs/STATE.md`, request sign-off.

### Workflows & Protocols Reference (Lite)
Load lazily by convention — never preload:
- Workflow: `$KIT_DIR_REL/workflows/<trigger>.md` (e.g. `pk:debug` → `workflows/debug.md`)
- Protocols: `$KIT_DIR_REL/protocols/{setup,context-sync,code-quality-gate,subagent-delegation}.md`
- Router: load `$KIT_DIR_REL/workflows/route.md` only when routing ambiguous or L3 escalation needed
- Project files: `./PROMPTKIT.md` (check `profile: lite|balanced|turbo`), `./docs/STATE.md`

### Task Ceremony Levels (Lite - same as full, but L2/L3 need balanced)
Declare on line 1 (no banner for informational L0 fast-path): `[PromptKit OS Lite: Level <0-3> — reason]`
- **L0 Direct**: questions, lookups, doc typos, formatting, non-risky 1-line edits. `understand → change → verify`. No task record.
- **L1 Standard**: localized bug fix, small feature, no schema/auth/breaking contract. Inline planning, no Task Record file. This is 80% of work — stays in Lite. Mixed-level requests take the higher level; downgrades need a one-line announced reason.
- **L2 Controlled**: schema/migrations, auth, permissions, public contracts, multi-component. Requires `docs/tasks/<task-id>.md` + spec. **Recommend switching to Balanced** (`init.sh --balanced`) for L2.
- **L3 Release-Critical**: release, tag, deploy, high-impact contract change. Requires L2 evidence + `pk:ship` + human approval. **Requires Balanced or Turbo**.

### Project Artifact Output Paths (Lite)
- State Tracker: docs/STATE.md
- Task Breakdowns: docs/tasks/ (L2 only, recommend Balanced)
- ADRs: docs/adrs/
- Specs: docs/specs/ (L2, recommend Balanced)

Lite keeps host project clean. Specialized dirs (auth/, data/, api/, etc.) created on-demand only in Balanced/Turbo.

### Upgrade Path
- Need more workflows? From your kit root, run `./init.sh --balanced` (or `pk:profile`) to upgrade to the full Balanced profile
- Need parallel waves? From your kit root, run `./init.sh --turbo --experimental` (warns up to ~2x measured token cost)
- Profile stored in `PROMPTKIT.md` as `profile: lite|balanced|turbo`
<!-- PROMPTKIT_END -->
