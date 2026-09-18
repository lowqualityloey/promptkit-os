# Telemetry Status Cards Protocol

## Purpose
Canonical format specification for completion status cards and human-action callouts. Lazy-loaded on demand: the directive triages, this file specifies exact formats. Semantics are byte-identical in structure to the pre-extraction directive specification — this is a relocation, not a redesign.

---

## Dual-Compatible Telemetry Status Cards

Single 3-line blockquote spec: `> 📊 Milestone: <name> [████░░] n/m (pct%) — source: STATE.md read this turn` / `> 🎯 Active: <task>` / `> 🟢 Quality Gate: <measured this turn / not measured>`. Text fallback `(n of m done)` for screen readers. Append a fourth line only when the host exposes per-turn usage: `> 💰 Spend: <in> / <out> (source: host usage)`; otherwise omit the line (L0 trivial turns omit it too).

---

## Callout Titles for Human Actions

At most ONE visual callout per completion, carrying both the action and the next step:

- Action required from the human uses `> [!IMPORTANT]` titled `### 🛑 Action Required From You:` (PR links as `[#N — title](url)`, command included, no HTML).
- Advisory next step only, with nothing required, uses `> [!TIP]` titled `### 💡 Next Recommended Step:`.
- Blocked states use `> [!WARNING]` titled `### ⚠️ Blocked: Waiting on Human Input:`.

The `> [!TIP]` survives only when it adds information the action callout does not; a TIP restating the callout is flooding, not guidance. If a UI milestone was completed without a `DESIGN.md`, proactively recommend `pk:design` to establish brand aesthetic archetypes, custom favicons, and icon families. Always prefix callouts with `> ` (never bare `[!TIP]`), zero raw HTML, perfect rendering across all terminal CLIs and IDEs.

---

## Completion Close: Bottom-Anchored TL;DR and Readability

In chat and terminal, the visible part is the bottom: detail scrolls away, the close stays in view. Every completion ends in this order — card, then one-line TL;DR, then the single callout:

```text
...detail above (may scroll off)...

> 📊 ... / > 🎯 ... / > 🟢 ...          (the card)
**TL;DR:** one line stating what happened.   (the takeaway)

> [!IMPORTANT]                                (the close: action + reply)
> Reply `go` to ..., or `hold` for ...
```

Readability rules (violations are format bugs, not style):

- Short lines, blank lines between sections, headers over dense paragraphs, one idea per block.
- No prose walls: any paragraph a developer must scroll up to re-read has failed.
- The recommended reply is always explicit literal text to type, never "let me know".

---

## Opt-Out

`status-cards: off` in `PROMPTKIT.md` suppresses the decorative card only (default is `on`; a missing line means `on`). It never suppresses a genuine halt: `> [!IMPORTANT]` "Action Required From You" and `> [!WARNING]` "Blocked" states still fire.

## Quiet Completion

When `docs/STATE.md` shows no open milestones, tasks, or blockers, end the turn with a completion statement (`All milestones closed — nothing pending.`) instead of a `> [!TIP]` Next-Step recommendation. This rule is independent of `status-cards: off` (decoration vs nagging are separate knobs): quiet completion suppresses recommendations, never halts.

## Provenance Reminder

Every number in a status card must trace to a command executed or file read in this turn (see the directive's Telemetry Card Provenance rule); otherwise emit `not measured`. Never claim a green Quality Gate without an executed check this turn.
