# ADR 0001: Static Token Headroom (Option B — Extract, Don't Raise)

- **Status**: Accepted (decision only; extraction is a follow-up)
- **Date**: 2026-09-16
- **Context**: `scripts/measure-tokens.sh --strict` reports `BALANCED|2495|2500|PASS` — 5 tokens of headroom (0.2%). The planning-intake wave was already forced to route `size:` / `intake-status:` signals through `PROMPTKIT.md` instead of the directive. Related issues: #195 (headroom), #200 (protocol registry), #196 (status-cards opt-out, blocked).
- **Measured at**: `37fb866` — `templates/agent-directive-template.md` 9980 B (~2495 tok), `templates/agent-directive-lite-template.md` 4237 B (~1059 tok).

## Decision

**Option B**: extract the Dual-Compatible Telemetry Status Card format spec from the directive into a lazily-loaded protocol (e.g. `protocols/telemetry-cards.md`), leaving a one-line pointer in the directive. **Do not raise `TOKEN_BUDGET_BALANCED`** (Option A rejected: it weakens the efficiency claim and only moves the cliff).

This PR implements the decision record only. Budget constants, directive semantics, and card format are unchanged.

## Consequences

- Follow-up extraction must preserve card semantics byte-for-byte in structure (3-line blockquote, provenance rule, text fallback, callout titles) and move any affected `run-behavioral-contract-tests.sh/.ps1` assertions with the text (both twins, never delete).
- The new protocol must be registered in `protocols/setup.md` so the Scenario O drift guard stays green.
- `docs/BENCHMARKS.md` figures are refreshed after the extraction lands, measured at the merge SHA.
- #196 (`status-cards: off`) stays blocked until the extraction restores ≥150 tok headroom against the unchanged 2500 cap.

## Directive Exclusion Note (resolves #200 ambiguity)

`templates/agent-directive-template.md:68` intentionally lists only four protocols. `protocols/discovery-intake.md` (12,635 B, ~3,158 tok) is deliberately lazy-loaded via `workflows/onboard.md` Phase 0 and `workflows/plan.md` Step 0 — not inlined — to preserve the static budget. The canonical registry is `protocols/setup.md`, which now lists all five protocols with this rationale in-place. The directive file itself was left untouched in this PR to avoid breaching the 2500 cap (only ~18 spare bytes remain).
