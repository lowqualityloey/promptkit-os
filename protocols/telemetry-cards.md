# Telemetry Status Cards & Visual Formatting Protocol

## Purpose
Canonical visual formatting specification for telemetry cards, human-action callouts, and turn structures. Provides dual-mode rendering: **Markdown Mode** (for rich Web/IDE renderers like Cursor, VS Code, and Antigravity) and **CLI / Terminal Mode** (for non-markdown terminals like Cline, OpenCode, Aider, and shell CLIs).

---

## The Single-Callout Invariant (Strict Anti-Flooding)

**At most ONE human callout block per turn.** Never emit multiple alert boxes or stacked callouts in the same turn (e.g. never stack `[!IMPORTANT]` with `[!TIP]`).

Callout types are strictly tiered by priority; only the highest applicable level fires:
1. **Priority 1 (Hard Stop)**: Human sign-off, PR review ready, release authorization, or milestone boundary (`🛑ACTION REQUIRED`).
2. **Priority 2 (Blocked)**: Two failed repair attempts, missing secrets/env, or execution blocker (`🚫BLOCKED`).
3. **Priority 3 (Advisory Next Steps)**: Normal turn progression with numbered choices (`💡NEXT STEPS`).

If a higher-priority callout is active, it carries the next action; a separate advisory TIP is strictly forbidden.

---

## Universal Square Progress Bar Contract

Progress bars across all environments must use square geometric Unicode characters with exact 1:1 monospaced width parity:
- **Filled**: `■` (U+25A0)
- **Empty**: `□` (U+25A1)
- **Format**: `[■■■■■■■■□□] 80% (8/10)`

> [!CAUTION]
> **Anti-Glitch Invariant**: Shaded textured blocks (`▓`, `▒`, `░`) and solid vertical blocks (`█`) are strictly banned from progress bars because they produce font width collisions and yellow scanline rendering artifacts in IDE themes.

---

## Dual-Compatible Telemetry Status Cards

Provides dual-mode rendering: **Markdown Mode** (for rich Web/IDE renderers like Cursor, VS Code, and Antigravity) and **CLI / Terminal Mode** (for non-markdown terminals like Cline, OpenCode, Aider, and shell CLIs).

### 1. Opening: TL;DR & Two-Column Table
```markdown
> **📌 TL;DR:** Landed M2 persistence layer behind TDD contract (`TDD-EXEC-004`). All 32 tests pass; ready for M3.

| What Changed | Verification Evidence |
| :--- | :--- |
| `migrations/20260918_m2_persistence.sql` | `pnpm vitest run` → **32 passed** (6 files) |
| `src/db/repo.ts` (Tenant-isolated repository) | `pnpm tsc --noEmit` → **exit code 0** (clean) |
```

### 2. Telemetry Card (Single 3-Line Blockquote)
```markdown
> 📊 Milestone: M2: Core Database `[■■■■■■■■□□]` 8/10 (80%) — source: `docs/STATE.md`  
> 🎯 Active: TASK-2026-09-18-persistence (In Progress)  
> 🟢 Quality Gate: 32 passed, 0 failed (`vitest run`) · `tsc --noEmit` exit code 0  
```
*(Append a 4th line `> 💰 Spend: <in> / <out> (source: host usage)` only when host exposes per-turn token usage).*

### 3. Human Action Callouts (Tight Headers & Descriptive Links)

- **Hard Stop / Review Ready (`[!IMPORTANT]`)**:
  ```markdown
  > [!IMPORTANT]
  > ### 🛑ACTION REQUIRED:
  > Pull Request is **Review Ready** and CI checks are green (Linux & Windows).
  > 
  > 👉 **[Review and Merge PR #284](https://github.com/lowqualityloey/promptkit-os/pull/284)** to close this milestone.
  ```

- **Blocked State (`[!WARNING]`)**:
  ```markdown
  > [!WARNING]
  > ### 🚫BLOCKED:
  > Two automated repair attempts failed on `tests/auth.test.ts`.
  > - **Error**: `ERR_DATABASE_CONNECTION_REFUSED` on port 5432
  > - **Action needed**: Start local Postgres container via `docker compose up -d`.
  ```

- **Next Steps (`[!TIP]`)**:
  Advisory next step only, with nothing required, uses `> [!TIP]` titled `### 💡 Next Recommended Step:` or `### 💡NEXT STEPS (Type number & Enter):`.
  ```markdown
  > [!TIP]
  > ### 💡NEXT STEPS (Type number & Enter):
  > 1. **(Recommended)** Proceed to M3: Implement Stripe webhook receiver.
  > 2. Run stress/concurrency benchmark on new connection pool.
  > 3. Stop here — create session checkpoint (`pk:checkpoint`) to resume in a fresh chat.
  ```

---

## Mode 2: CLI / Terminal Mode (Non-Markdown & Terminal Hosts)

For Cline, OpenCode, Aider, Windows Terminal, PowerShell, and Bash environments:

### 1. Opening: Clean TL;DR, Changes & Evidence
```text
📌TL;DR
- Landed database migration 20260918_m2_persistence.sql and repository.
- Verified 32 unit/integration tests (exit code 0).
- Next: M3 provider adapter implementation.

[CHANGES]
  + migrations/20260918_m2_persistence.sql
  + src/db/repo.ts (tenant-isolated repository)

[EVIDENCE]
  ✓ vitest run: 32 passed
  ✓ tsc --noEmit: exit 0
```

### 2. Telemetry Card (Ceiling & Floor Box — Zero Side-Walls)
To prevent line wrapping and jagged border breakage on long words or narrow terminals, use top ceiling and bottom floor framing with indented body lines and **no side walls (`║`)**:

```text
╔═ 📊TELEMETRY ════════════════════════════════════════════════╗
  Milestone:    [■■■■■■■■□□] 80% · M2: Core Database (8/10)
  Active Task:  TASK-2026-09-18-persistence
  Quality Gate: 32 passed · tsc exit 0 (VERIFIED)
╚══════════════════════════════════════════════════════════════╝
```

### 3. Human Action Callouts (Ceiling & Floor Framing)

- **Hard Stop / Review Ready**:
  ```text
  ╔═ 🛑ACTION REQUIRED ══════════════════════════════════════════╗
    Pull Request is Review Ready (CI passed: Linux & Windows):
    👉 [Review and Merge PR #284](https://github.com/lowqualityloey/promptkit-os/pull/284)

    Action: Review diff and merge PR to main to close milestone.
  ╚══════════════════════════════════════════════════════════════╝
  ```

- **Blocked State**:
  ```text
  ╔═ 🚫BLOCKED ══════════════════════════════════════════════════╗
    Waiting on human input:
    - Error: ERR_DATABASE_CONNECTION_REFUSED on port 5432
    - Bounded Repair: 2 automatic attempts failed
    - Action: Start local Postgres container (`docker compose up -d`)
  ╚══════════════════════════════════════════════════════════════╝
  ```

- **Next Steps (Interactive Numbered Choice)**:
  ```text
  ╔═ 💡NEXT STEPS ═══════════════════════════════════════════════╗
    [1] (Recommended) Proceed to M3: Implement Stripe webhook
    [2] Run stress/concurrency benchmark on connection pool
    [3] Stop here — create session checkpoint (pk:checkpoint)
  ╚══════════════════════════════════════════════════════════════╝
  ```

---

## Descriptive Link Contract (`👉 [text](url)`)

Raw unformatted URLs (e.g. `https://github.com/...`) are prohibited in turn completions. All links to PRs, milestones, or external trackers must be formatted as descriptive Markdown links preceded by a pointer:
`👉 [Review and Merge PR #N](url)`

---

## Opt-Out & Quiet Completion

- **`status-cards: off` in `PROMPTKIT.md`**: Suppresses the decorative telemetry card only. It never suppresses genuine halts (`🛑ACTION REQUIRED` or `🚫BLOCKED`).
- **Quiet Completion**: When `docs/STATE.md` shows no open milestones, tasks, or blockers, end the turn with a quiet completion statement instead of an advisory next-step callout:
  - Markdown: `> ✅ **All milestones closed · Worktree clean · Zero open tasks.**`
  - CLI: `[COMPLETE] ✅ All milestones closed · Worktree clean · Zero open tasks.`

---

## Provenance Invariant

Every number in a status card must trace to a command executed or file read in this turn (exit code 0 or STATE.md read); otherwise emit `not measured`. Never claim a green Quality Gate without executed proof in the active turn.
