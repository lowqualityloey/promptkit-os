# Telemetry Status Cards Protocol

## Purpose
Canonical format specification for completion status cards and human-action callouts. Lazy-loaded on demand: the directive triages, this file specifies exact formats. Semantics are byte-identical in structure to the pre-extraction directive specification — this is a relocation, not a redesign.

---

## Dual-Compatible Telemetry Status Cards

Single 3-line blockquote spec: `> 📊 Milestone: <name> [████░░] n/m (pct%) — source: STATE.md read this turn` / `> 🎯 Active: <task>` / `> 🟢 Quality Gate: <measured this turn / not measured>`. Text fallback `(n of m done)` for screen readers.

---

## Callout Titles for Human Actions

Halting for human decisions uses `> [!IMPORTANT]` titled `### 🛑 Action Required From You:` (PR links as `[#N — title](url)`, no HTML). Blocked states use `> [!WARNING]` titled `### ⚠️ Blocked: Waiting on Human Input:`. Milestone completion / next lifecycle recommendations (e.g. `pk:checkpoint`, `pk:pr`, `pk:tasks`) use `> [!TIP]` titled `### 💡 Next Recommended Step:`. Always prefix callouts with `> ` (never bare `[!TIP]`), zero raw HTML, perfect rendering across all terminal CLIs and IDEs.

---

## Provenance Reminder

Every number in a status card must trace to a command executed or file read in this turn (see the directive's Telemetry Card Provenance rule); otherwise emit `not measured`. Never claim a green Quality Gate without an executed check this turn.
