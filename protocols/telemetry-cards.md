# Telemetry Status Cards & Visual Formatting Protocol

## Purpose
Canonical visual formatting specification for telemetry cards, human-action callouts, and turn structures. Provides dual-mode rendering: **Framed Mode** (tactile ceiling-and-floor Unicode boxes, default) and **Markdown Mode** (for GitHub-style blockquote alerts), plus CLI/Terminal support across Cline, OpenCode, Aider, Cursor, VS Code, and Antigravity.

---

## The Single-Callout Invariant (Strict Anti-Flooding)

**At most ONE human callout block per turn.** Never emit multiple alert boxes or stacked callouts in the same turn (e.g. never stack `[!IMPORTANT]` with `[!TIP]`).

Callout types are strictly tiered by priority; only the highest applicable level fires:
1. **Priority 1 (Hard Stop)**: Human sign-off, PR review ready, release authorization, or milestone boundary (`🛑ACTION REQUIRED`).
2. **Priority 2 (Blocked)**: Two failed repair attempts, missing secrets/env, or execution blocker (`🚫BLOCKED`).
3. **Priority 3 (Advisory Next Steps)**: Normal turn progression with numbered choices (`💡NEXT STEPS`).

If a higher-priority callout is active, it carries the next action; a separate advisory TIP is strictly forbidden.

**Precedence:** this document is canonical for callout *format*; `protocols/code-quality-gate.md` is canonical for *when-to-halt and Type A-D routing*; `protocols/setup.md` defers to both.

---

## Universal Square Progress Bar Contract

Progress bars across all environments must use square geometric Unicode characters with exact 1:1 monospaced width parity:
- **Filled**: `■` (U+25A0)
- **Empty**: `□` (U+25A1)
- **Format**: `[■■■■■■■■□□] 80% (8/10)`

> [!CAUTION]
> **Anti-Glitch Invariant**: Shaded textured blocks (`▓`, `▒`, `░`) and solid vertical blocks (`█`) are strictly banned from progress bars because they produce font width collisions and yellow scanline rendering artifacts in IDE themes.

---

## Mandatory Reply Hint Contract (`👉 Reply: Type '...'`)

Every human callout block (`NEXT STEPS`, `ACTION REQUIRED`, `BLOCKED`, `DECISION NEEDED`, `GRILL PROBE`) across all modes must conclude with an unambiguous, single-keystroke or single-word **Reply Hint** line.

The developer must never wonder what to type or whether they have to write an essay:
- **Numbered choices**: `👉 Reply: Type '1' (or press Enter) for recommended.`
- **Action / Review ready**: `👉 Reply: Type 'merged' or 'done' after merging to continue.`
- **Blocked repair**: `👉 Reply: Type 'retry' once freed, or 'skip' to bypass.`
- **Decision cards**: `👉 Reply: Type 'A' for recommended, or 'you decide' to delegate.`

---

## Dual-Compatible Telemetry Status Cards

Provides dual-mode rendering: **Framed Mode** (ceiling-and-floor boxes, default) and **Markdown Mode** (for GitHub-style blockquote alerts in rich renderers).

### Mode 1: Markdown Mode (Rich Web & IDE Renderers)

#### 1. Opening: TL;DR & Two-Column Table
```markdown
> **📌 TL;DR:** Landed M2 persistence layer behind TDD contract (`TDD-EXEC-004`). All 32 tests pass; ready for M3.

| What Changed | Verification Evidence |
| :--- | :--- |
| `migrations/20260918_m2_persistence.sql` | `pnpm vitest run` → **32 passed** (6 files) |
| `src/db/repo.ts` (Tenant-isolated repository) | `pnpm tsc --noEmit` → **exit code 0** (clean) |
```

#### 2. Telemetry Card (Single 3-Line Blockquote)
```markdown
> 📊 Milestone: M2: Core Database `[■■■■■■■■□□]` 8/10 (80%) — source: `docs/STATE.md`  
> 🎯 Active: TASK-2026-09-18-persistence (In Progress)  
> 🟢 Quality Gate: 32 passed, 0 failed (`vitest run`) · `tsc --noEmit` exit code 0  
```
*(Append a 4th line `> 💰 Spend: <in> / <out> (source: host usage)` only when host exposes per-turn token usage).*

#### 3. Human Action Callouts (Tight Headers & Descriptive Links)

- **Hard Stop / Review Ready (`[!IMPORTANT]`)**:
  ```markdown
  > [!IMPORTANT]
  > ### 🛑ACTION REQUIRED:
  > Pull Request is **Review Ready** and CI checks are green (Linux & Windows).
  > 
  > 👉 **[Review and Merge PR #284](https://github.com/lowqualityloey/promptkit-os/pull/284)** to close this milestone.
  > 
  > 👉 **Reply**: Type `merged` or `done` after merging to continue.
  ```

- **Blocked State (`[!WARNING]`)**:
  ```markdown
  > [!WARNING]
  > ### 🚫BLOCKED:
  > Two automated repair attempts failed on `tests/auth.test.ts`.
  > - **Error**: `ERR_DATABASE_CONNECTION_REFUSED` on port 5432
  > - **Action needed**: Start local Postgres container via `docker compose up -d`.
  > 
  > 👉 **Reply**: Type `retry` once freed, or `skip` to bypass.
  ```

- **Next Steps (`[!TIP]`)**:
  Advisory next step only, with nothing required, uses `> [!TIP]` titled `### 💡 Next Recommended Step:` or `### 💡NEXT STEPS (Type number & Enter):`.
  ```markdown
  > [!TIP]
  > ### 💡 Next Recommended Step:
  > 1. **(Recommended)** Proceed to M3: Implement Stripe webhook receiver.
  > 2. Run stress/concurrency benchmark on new connection pool.
  > 3. Stop here — create session checkpoint (`pk:checkpoint`) to resume in a fresh chat.
  > 
  > 👉 **Reply**: Type `1` (or press Enter) for recommended.
  ```

---

## Mode 2: CLI / Terminal Mode & Framed Mode (Ceiling & Floor Boxes)

Default across all hosts when `card-style: framed` is active in `PROMPTKIT.md` (the shipped default), and standard for terminal tools (Cline, OpenCode, Aider, Windows Terminal, PowerShell, Bash). In rich markdown/web IDE chats (e.g. Antigravity, Cursor, Copilot), Mode 1 GFM alerts (`card-style: markdown`) can alternatively be selected for native styled UI cards. When rendering Mode 2 in chat interfaces, wrap in code blocks (````text ... ````) or keep widths bounded (≤60 chars) so variable-width fonts do not wrap ceiling and floor borders.

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

    👉 Reply: Type 'merged' or 'done' after merging to continue.
  ╚══════════════════════════════════════════════════════════════╝
  ```

- **Blocked State**:
  ```text
  ╔═ 🚫BLOCKED ══════════════════════════════════════════════════╗
    Waiting on human input:
    - Error: ERR_DATABASE_CONNECTION_REFUSED on port 5432
    - Bounded Repair: 2 automatic attempts failed
    - Action: Start local Postgres container (`docker compose up -d`)

    👉 Reply: Type 'retry' once freed, or 'skip' to bypass.
  ╚══════════════════════════════════════════════════════════════╝
  ```

- **Next Steps (Interactive Numbered Choice)**:
  ```text
  ╔═ 💡NEXT STEPS ═══════════════════════════════════════════════╗
    [1] (Recommended) Proceed to M3: Implement Stripe webhook
    [2] Run stress/concurrency benchmark on connection pool
    [3] Stop here — create session checkpoint (pk:checkpoint)

    👉 Reply: Type '1' (or press Enter) for recommended.
  ╚══════════════════════════════════════════════════════════════╝
  ```

- **Pre-Implementation Grilling (1-by-1 Decision Probes)**:
  ```text
  ╔═ 🎯GRILL PROBE M/N: <Title> ═════════════════════════════════╗
    <1-2 line context on why this design decision matters>

    [1] (Recommended) <First-choice option with trade-off rationale>
    [2] <Viable alternative option>
    [3] <Alternative option or explicit non-goal>

    👉 Reply: Type '1' for recommended, or write custom answer.
  ╚══════════════════════════════════════════════════════════════╝
  ```

---

## Descriptive Link Contract (`👉 [text](url)`)

Raw unformatted URLs (e.g. `https://github.com/...`) are prohibited in turn completions. All links to PRs, milestones, or external trackers must be formatted as descriptive Markdown links preceded by a pointer:
`👉 [Review and Merge PR #N](url)`

---

## Opt-Out & Configuration

- **`card-style` in `PROMPTKIT.md`**: Controls the visual style of cards and callouts:
  - `card-style: framed` (default) — Uses ceiling-and-floor Unicode boxes (`╔═ ... ╚═`) with indented body lines and explicit reply hints.
  - `card-style: markdown` — Uses GitHub-style markdown blockquotes and alerts (`> [!TIP]`, `> [!IMPORTANT]`) with explicit reply hints.
  - `card-style: off` (or `status-cards: off`) — Suppresses decorative telemetry and advisory framing. Genuine halts (`🛑ACTION REQUIRED` or `🚫BLOCKED`) still fire.
- **Quiet Completion**: When `docs/STATE.md` shows no open milestones, tasks, or blockers, end the turn with a quiet completion statement instead of an advisory next-step callout:
  - Markdown: `> ✅ **All milestones closed · Worktree clean · Zero open tasks.**`
  - CLI: `[COMPLETE] ✅ All milestones closed · Worktree clean · Zero open tasks.`

---

## Provenance Invariant

Every number in a status card must trace to a command executed or file read in this turn (exit code 0 or STATE.md read); otherwise emit `not measured`. Never claim a green Quality Gate without executed proof in the active turn.
