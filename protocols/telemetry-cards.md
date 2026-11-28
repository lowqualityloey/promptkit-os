# Telemetry Status Cards & Visual Formatting Protocol

## Purpose
Canonical visual formatting specification for telemetry status lines, human-action callouts, and turn structures. Routine progress, completion, and advisory next-step telemetry is **compact Markdown**: three concise bullet lines and no box. Genuine stops (`🛑ACTION REQUIRED`, `🚫BLOCKED`) and decision probes render as a **borderless CommonMark callout** — a `---` divider plus a `>` blockquote — because that shape renders identically in every CommonMark and GFM host, with no alert tokens to leak as literal text and no box borders to shear when an emoji is double-width. `card-style: clean` is therefore the shipped default; GitHub alerts (`card-style: gfm`) and CLI monospace boxes (`card-style: framed`) remain opt-in styles.

---

## The Single-Callout Invariant (Strict Anti-Flooding)

**At most ONE human callout block per turn.** Never emit multiple alert boxes or stacked callouts in the same turn (e.g. never stack `[!IMPORTANT]` with `[!TIP]`).

Callout types are strictly tiered by priority; only the highest applicable level fires:
1. **Priority 1 (Hard Stop)**: Human sign-off, PR review ready, release authorization, or milestone boundary (`🛑ACTION REQUIRED`).
2. **Priority 2 (Blocked)**: Two failed repair attempts, missing secrets/env, or execution blocker (`🚫BLOCKED`).
3. **Priority 3 (Advisory Next Steps)**: Normal turn progression with numbered choices (`💡NEXT STEPS`).

If a higher-priority callout is active, it carries the next action; a separate advisory TIP is strictly forbidden.

**Precedence:** this document is canonical for callout *format*; `protocols/code-quality-gate.md` is canonical for *when-to-halt and Type A-D routing*; `protocols/setup.md` defers to both. The canonical turn-close order in every style is **TL;DR opening → telemetry card → callout**; any workflow restating a close order must match this sequence.

---

## Universal Square Progress Bar Contract

Progress bars across all environments must use square geometric Unicode characters with exact 1:1 monospaced width parity:
- **Filled**: `■` (U+25A0)
- **Empty**: `□` (U+25A1)
- **Format**: `[■■■■■■■■□□] 80% (8/10)`

**Conditional, never decorative.** A bar is permitted only when the canonical record holds a real countable list this turn — named milestones, or an `AC-*` acceptance-criteria checklist with a fixed denominator. When no countable list exists (one open task, an unstarted phase, a review pending), emit plain status text: `awaiting sign-off`, `in progress`, or `2 of 3 gates passed` only when those three gates are enumerated. Never derive a fraction from intuition, and never render a denominator the record does not contain — a fabricated `9/10` is a provenance violation, and `not measured` is always better than an invented fraction.

> **Anti-Glitch Invariant**: Shaded textured blocks (`▓`, `▒`, `░`) and solid vertical blocks (`█`) are strictly banned from progress bars because they produce font width collisions and yellow scanline rendering artifacts in IDE themes.

---

## Mandatory Reply Hint Contract (`👉 Reply: Type '...'`)

Every human callout block (`NEXT STEPS`, `ACTION REQUIRED`, `BLOCKED`, `DECISION NEEDED`, `GRILL PROBE`) in every style must conclude with an unambiguous, single-keystroke or single-word **Reply Hint** line. In the default style the hint is bolded inside the blockquote (`> **👉 Reply:** Type ...`); in GFM and framed styles the plain `👉 Reply:` form below is equally valid.

The developer must never wonder what to type or whether they have to write an essay:
- **Numbered choices**: `👉 Reply: Type '1' (or press Enter) for recommended.`
- **Action / Review ready**: `👉 Reply: Type 'merged' or 'done' after merging to continue.`
- **Blocked (mandatory stops / verification / security)**: `👉 Reply: Type 'retry' once resolved, or describe instructions.` (Skip is strictly forbidden on mandatory verification or security stops).
- **Blocked (waivable external prerequisites only)**: `👉 Reply: Type 'retry' once freed, or 'skip' to bypass if non-blocking.`
- **Decision cards**: `👉 Reply: Type 'A' for recommended, or 'you decide' to delegate.`

---

## Pre-Response Check (Compact, Per Turn)

Before composing the reply, answer five questions from the current execution state. This is a **reasoning step, not a mandated tool call** (see *Honest Limits* below).

1. **Stop state** — genuine halt (`🛑ACTION REQUIRED` / `🚫BLOCKED`), advisory turn, or *Quiet Completion*? Silence is only correct for the third.
2. **Highest applicable callout** — exactly one, at the highest applicable tier per *The Single-Callout Invariant*.
3. **Concrete action + reply hint** — does it name one specific thing the human must do and close with a `👉 Reply:` line from the *Mandatory Reply Hint Contract*?
4. **Retention** — is every *other* unresolved human action still recorded and unchanged?
5. **Turn obligations** — TL;DR on substantive turns (informational L0 fast-path replies stay exempt), and every number traced to this turn per the *Provenance Invariant* or reported `not measured`.

### Suppression Is Not Resolution

A lower-priority action that was not shown stays **recorded, unresolved, and unchanged** in the canonical record. The Single-Callout Invariant limits how many *boxes* a turn renders; it never discharges an obligation. Re-surface the action on the turn it becomes the highest applicable one. Never state or imply that "only one callout was shown" means the others were handled, approved, or dropped.

### Reply Interpretation Is Record-Bound

`done`, `merged`, a bare number, `continue`, `retry`, and `skip` resolve **only the recorded action they were offered against**. They never authorize an unrelated protected action (commit, push, PR, release, deploy, rollback, scope change), never cross a milestone boundary, and never promote a Priority 2 blocker into a Priority 1 approval. Where an externally observable condition exists — PR merged, CI green, file written, value on disk — verify it in this turn before treating the action as met: a reply is a claim about the human's side of the world, not evidence for it.

### Resolution Requires the Recorded Condition

An action is resolved only when its recorded condition is actually met and, where one exists, verified as above. Until then it stays pending across turns, compaction, and handoff. Pending actions live in the canonical record the work already requires — never in a second parallel action ledger — and that record holds no credentials, tokens, or secret values; reference the env key or secret store instead.

### Cards-Off Still Communicates Genuine Halts

`card-style: off` / `status-cards: off` suppresses only the decorative card and advisory framing, never a genuine halt. A `🛑ACTION REQUIRED` or `🚫BLOCKED` stop still fires with its concrete action and reply hint intact, rendered in plain text when nothing decorative is shown.

### Honest Limits

The host cannot mechanically halt an agent, inspect a future turn, or detect a missing callout; this check is a stated discipline that any model may still under-apply, and no claim is made that it prevents measured session drift. It adds no mandatory disk read or tool call to a trivial reply. Where an existing protocol already requires reading the canonical record for current state (e.g. *STATE.md Untrusted Until Read*, `pk:checkpoint`), that read answers the check too — the check never mandates an additional one.

---

## Compact Status Default (Routine Telemetry)

Routine progress, completion, and advisory next-step telemetry is **three concise Markdown bullet lines — never a box, never a framed card**. The bullet markers are mandatory, not cosmetic: three consecutive bare lines collapse into a single run-on paragraph in CommonMark and GFM, because a single newline is not a line break.

```markdown
- 📊 Milestone: M2: Core Database [■■■■■■■■□□] 8/10 (80%) — source: `docs/STATE.md`
- 🎯 Active: TASK-2026-09-18-persistence (In Progress)
- 🟢 Quality Gate: 32 passed, 0 failed (`vitest run`) · `tsc --noEmit` exit code 0
```

- One bullet per signal: milestone/progress, active work, quality gate or verification. Append a `- 💰 Spend: <in> / <out>` bullet only when the host exposes per-turn usage; otherwise omit it or write `not measured`.
- Never rely on a hard-break hack (two trailing spaces, `<br>`) as the separator; the `- ` marker keeps the three lines distinct in every renderer, and an empty line between them is unnecessary.
- No ceiling/floor borders, no `╔═` framing, no alert block, and no extra decoration around routine lines. Plain text or a single blockquote both qualify; the shape stays three bullet lines.
- The `📊 Milestone` bullet carries a progress bar **only per the *Universal Square Progress Bar Contract*** — a real countable list this turn; otherwise plain status text such as `awaiting sign-off` or `in progress`.
- A **borderless CommonMark callout (Mode 1) is the shipped default for a genuine stop** — `🛑ACTION REQUIRED`, `🚫BLOCKED`, `🎯GRILL PROBE`, `DECISION NEEDED` — where the human must act or decide. `gfm` alerts and `framed` boxes are opt-in and never appear on a routine turn.
- The expanded telemetry card (blockquote or boxed form) is opt-in: render it only when the human asks for it or an explicit workflow step requires the expanded layout for evidence review.
- `status-cards: off` suppresses these routine lines; halt callouts and their reply hints still fire (see *Cards-Off Still Communicates Genuine Halts*).

---

## Dual-Compatible Telemetry Status Cards

Provides the expanded-callout renderings selected by `card-style:` for turns that legitimately render one — genuine stops, decision probes, and a human-requested expanded telemetry card. Routine turns use the *Compact Status Default* above. `clean` (Mode 1) is the shipped default; `framed` (Mode 2) and `gfm` (Mode 3) are opt-in.

### Mode 1: Borderless CommonMark (Shipped Default — `card-style: clean`)

Every host that parses CommonMark or GFM renders this identically: a `---` thematic break, a `>` blockquote, a bold stop label, and one reply hint. No `[!IMPORTANT]`/`[!WARNING]` tokens (which render as literal text outside GitHub), no `╔═ ║ ╚` borders, and no trailing two-space hard breaks.

#### 1. Opening: TL;DR & Two-Column Table
```markdown
> **📌 TL;DR:** Landed M2 persistence layer behind TDD contract (`TDD-EXEC-004`). All 32 tests pass; ready for M3.

| What Changed | Verification Evidence |
| :--- | :--- |
| `migrations/20260918_m2_persistence.sql` | `pnpm vitest run` → **32 passed** (6 files) |
| `src/db/repo.ts` (Tenant-isolated repository) | `pnpm tsc --noEmit` → **exit code 0** (clean) |
```

#### 2. Expanded Telemetry Card (Single 3-Line Blockquote)

Expanded form only. Routine completion uses the compact default (three bullet lines, no blockquote callout).
```markdown
> - 📊 Milestone: M2: Core Database `[■■■■■■■■□□]` 8/10 (80%) — source: `docs/STATE.md`
> - 🎯 Active: TASK-2026-09-18-persistence (In Progress)
> - 🟢 Quality Gate: 32 passed, 0 failed (`vitest run`) · `tsc --noEmit` exit code 0
```
*(Append a 4th line `> 💰 Spend: <in> / <out> (source: host usage)` only when the host exposes per-turn token usage).*

#### 3. Human Action Callouts (Default Style)

The callout is fenced top and bottom by `---` so it separates cleanly from prose even in renderers that ignore blockquote styling. One callout per turn.

- **Hard Stop / Review Ready**:
  ```markdown
  ---

  > **🛑 ACTION REQUIRED — PR #284 is review-ready (CI green: Linux & Windows)**
  >
  > 👉 [Pull request #284](https://github.com/lowqualityloey/promptkit-os/pull/284)
  >
  > **👉 Reply:** Type `merged` or `done` after merging to continue.

  ---
  ```

- **Blocked State**:
  ```markdown
  ---

  > **🚫 BLOCKED — `DATABASE_URL` is unset and no test database exists**
  >
  > - **Error**: `ERR_DATABASE_CONNECTION_REFUSED` on port 5432
  > - **Tried**: 2 bounded repair attempts, both failed at connect
  > - **Action needed**: Start local Postgres via `docker compose up -d`
  >
  > **👉 Reply:** Type `retry` once freed (or `skip` only if this dependency is explicitly waivable).

  ---
  ```

- **Next Steps (`💡 NEXT STEPS`) — expanded advisory card (opt-in)**:
  Under the compact default, advisory next steps are plain numbered lines in the closing prose; render this callout only when the human asks for the expanded layout. Advisory next step only, with nothing required.
  ```markdown
  ---

  > **💡 NEXT STEPS — pick one to continue**
  >
  > 1. **(Recommended)** Proceed to M3: Implement Stripe webhook receiver.
  > 2. Run stress/concurrency benchmark on new connection pool.
  > 3. Stop here — create session checkpoint (`pk:checkpoint`) to resume in a fresh chat.
  >
  > **👉 Reply:** Type `1` (or press Enter) for recommended.

  ---
  ```

- **Pre-Implementation Grilling (1-by-1 Decision Probes)**:
  ```markdown
  ---

  > **🎯 GRILL PROBE 2/5 — Session storage trade-off**
  >
  > <1-2 line context on why this design decision matters>
  >
  > 1. **(Recommended)** <First-choice option with trade-off rationale>
  > 2. <Viable alternative option>
  > 3. <Alternative option or explicit non-goal>
  >
  > **👉 Reply:** Type `1` for recommended, or write custom answer.

  ---
  ```

---

## Mode 2: CLI / Terminal Mode — Open-Right Framed Boxes (Opt-In)

Opt-in via `card-style: framed`, and the preferred rendering for genuinely monospaced hosts (Windows Terminal, PowerShell, Bash, plain `less`/`cat` output, and CLI agents such as Cline, OpenCode, and Aider). Ceiling-and-floor framing only: the right-hand corners (`╗`, `╝`) and any right-side `║` wall are deliberately absent, so a double-width emoji, a wide CJK label, or a long path can never shear the border open. Body lines are indented two spaces; the left edge carries no wall either, which keeps the output copy-pasteable as plain text.

In a proportional-font chat renderer prefer Mode 1; if you must show Mode 2 there, fence it as ````text```` so the border columns stay aligned.

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

### 2. Expanded Telemetry Card (Open-Right Ceiling & Floor)

Expanded form only; routine turns use the compact default. A bar appears only with a real countable list (*Universal Square Progress Bar Contract*).

```text
╔═ 📊TELEMETRY ════════════════════════════════════════════════
  Milestone:    [■■■■■■■■□□] 80% · M2: Core Database (8/10)
  Active Task:  TASK-2026-09-18-persistence
  Quality Gate: 32 passed · tsc exit 0 (VERIFIED)
╚══════════════════════════════════════════════════════════════
```

### 3. Human Action Callouts (Open-Right Framing)

- **Hard Stop / Review Ready**:
  ```text
  ╔═ 🛑ACTION REQUIRED ══════════════════════════════════════════
    Pull Request is Review Ready (CI passed: Linux & Windows):
    👉 [Review and Merge PR #284](https://github.com/lowqualityloey/promptkit-os/pull/284)

    Action: Review diff and merge PR to main to close milestone.

    👉 Reply: Type 'merged' or 'done' after merging to continue.
  ╚══════════════════════════════════════════════════════════════
  ```

- **Blocked State**:
  ```text
  ╔═ 🚫BLOCKED ══════════════════════════════════════════════════
    Waiting on human input:
    - Error: ERR_DATABASE_CONNECTION_REFUSED on port 5432
    - Bounded Repair: 2 automatic attempts failed
    - Action: Start local Postgres container (`docker compose up -d`)

    👉 Reply: Type 'retry' once freed (or 'skip' only if explicitly waivable).
  ╚══════════════════════════════════════════════════════════════
  ```

- **Next Steps (Interactive Numbered Choice) — expanded advisory card (opt-in)**:
  Under the compact default these are plain numbered lines; the box is opt-in.
  ```text
  ╔═ 💡NEXT STEPS ═══════════════════════════════════════════════
    [1] (Recommended) Proceed to M3: Implement Stripe webhook
    [2] Run stress/concurrency benchmark on connection pool
    [3] Stop here — create session checkpoint (pk:checkpoint)

    👉 Reply: Type '1' (or press Enter) for recommended.
  ╚══════════════════════════════════════════════════════════════
  ```

- **Pre-Implementation Grilling (1-by-1 Decision Probes)**:
  ```text
  ╔═ 🎯GRILL PROBE M/N: <Title> ═════════════════════════════════
    <1-2 line context on why this design decision matters>

    [1] (Recommended) <First-choice option with trade-off rationale>
    [2] <Viable alternative option>
    [3] <Alternative option or explicit non-goal>

    👉 Reply: Type '1' for recommended, or write custom answer.
  ╚══════════════════════════════════════════════════════════════
  ```

---

## Mode 3: GFM Alerts (Opt-In — `card-style: gfm`)

Use only on hosts known to render GitHub-flavored alerts (github.com, GitHub Mobile, and the GitHub-authored markdown viewers). Outside GitHub the `[!IMPORTANT]` token arrives as literal bracket text, which is why this style is no longer the default. At most one alert per turn; `markdown` is an accepted legacy alias for `gfm`.

- **Hard Stop / Review Ready (`[!IMPORTANT]`)** titled `### 🛑ACTION REQUIRED:`
- **Blocked State (`[!WARNING]`)** titled `### 🚫BLOCKED:`
- **Advisory Next Step (`[!TIP]`) — opt-in** titled `### 💡 Next Recommended Step:` or `### 💡NEXT STEPS (Type number & Enter):`

```markdown
> [!WARNING]
> ### 🚫BLOCKED:
> Two automated repair attempts failed on `tests/auth.test.ts`.
> - **Error**: `ERR_DATABASE_CONNECTION_REFUSED` on port 5432
> - **Action needed**: Start local Postgres container via `docker compose up -d`.
>
> 👉 **Reply**: Type `retry` once freed (or `skip` only if this dependency is explicitly waivable).
```

---

## Descriptive Link Contract (`👉 [text](url)`)

Raw unformatted URLs (e.g. `https://github.com/...`) are prohibited in turn completions. All links to PRs, milestones, or external trackers must be formatted as descriptive Markdown links preceded by a pointer:
`👉 [Review and Merge PR #N](url)`

---

## Opt-Out & Configuration

- **`status-cards` in `PROMPTKIT.md`**: Controls the routine status lines.
  - `status-cards: on` (default) — Emits the compact three-bullet routine status on completion. Never a box.
  - `status-cards: off` — Suppresses the routine lines and decorative framing. Genuine halts (`🛑ACTION REQUIRED` or `🚫BLOCKED`) still fire with their reply hints.
- **`card-style` in `PROMPTKIT.md`**: Controls the visual style of the expanded callouts that do render — halt callouts, decision probes, and a human-requested expanded telemetry card:
  - `card-style: clean` (default) — Borderless CommonMark: `---` divider plus `>` blockquote, bold stop label, one bolded reply hint. Renders identically in every CommonMark/GFM host, which is why it shipped as the default in v2.7.0.
  - `card-style: gfm` — GitHub-style alerts (`> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`) with explicit reply hints. Opt-in. `card-style: markdown` is a deprecated alias for `gfm`: it keeps the pre-v2.7.0 meaning, so an existing install that already set `markdown` does not silently switch styles.
  - `card-style: framed` — Opt-in CLI/terminal ceiling-and-floor boxes with open right edges (`╔═` / `╚═`, no `╗` / `╝`, no right `║` wall) so variable-width emoji never misalign the border.
  - `card-style: off` (or `status-cards: off`) — Suppresses decorative telemetry and advisory framing. Genuine halts (`🛑ACTION REQUIRED` or `🚫BLOCKED`) still fire.
- **Quiet Completion**: When `docs/STATE.md` shows no open milestones, tasks, or blockers, end the turn with a quiet completion statement instead of an advisory next-step callout:
  - Markdown: `> ✅ **All milestones closed · Worktree clean · Zero open tasks.**`
  - CLI: `[COMPLETE] ✅ All milestones closed · Worktree clean · Zero open tasks.`

---

## Provenance Invariant

Every *measured* number in a status card must trace to a command executed or file read in this turn (exit code 0 or STATE.md read); otherwise emit `not measured`. Never claim a green Quality Gate without executed proof in the active turn. Estimated columns (e.g. context-payload ranges in the state tracker) are explicitly heuristic per `workflows/checkpoint.md` — never blend them into measured claims.
