---
status: Shipped
---

# Issue LSP-01: LSP-Aware Diagnostics Injection for pk:review (TS CLI MVP)

### Metadata
- **Related Spec**: Plan session 2026-09-15 (LSP-aware pk:review MVP)
- **Depends On**: LSP-02 (context-sync detection + `PROMPTKIT.md §5a` opt-in fields must exist first)
- **Milestone**: `Unassigned (remote has no open feature milestone; maintainer triage)`
- **Priority**: `#priority/p1`
- **Labels**: `area:backend, type:feature`
- **Kanban Status**: `In Review`

## User Story & Context
**As a** developer running `pk:review`
**I want** range-accurate TypeScript diagnostics (`file:line:col`) from `tsc`/`biome`/`eslint` JSON output injected into Axis 2 as evidence
**So that** findings cite verifiable locations instead of prose guesses, without requiring an LSP daemon.

## Technical Scope & Invariants
- **Files**: `workflows/review.md` (Axis 2 pre-flight + report table), `protocols/code-quality-gate.md` (step 1a/1b split)
- **Bridge**: CLI JSON first (`pnpm tsc --noEmit --pretty false`, `biome check --json`, `eslint --format json`). `lsp-mcp stdio` deferred until a measured spike proves value.
- **Invariants**: Diagnostics are read-only evidence; never auto-fix. `lsp: disabled` default keeps Lite profile at 961 tok. Tier-3 CLI always wins if LSP absent (Progressive Enhancement).

### Out of Scope
- `lsp-mcp` daemon/bridge, polyglot languages (pyright/rust-analyzer), `pk:debug`/`pk:refactor`/`pk:fix` integration.

## Implementation Tasks
- [x] 1. Add pre-Axis 2 step `2a. Pull Diagnostics Evidence (optional, read-only)` to `workflows/review.md` gated on `PROMPTKIT.md §5a`.
- [x] 2. Filter diagnostics to the resolved fixed-point diff (`git diff <base>...HEAD`); map `error -> 🚨 [BLOCKING]`, `warn -> ⚠️ [IMPORTANT]`.
- [x] 3. Inject `Diagnostics Evidence` table into `docs/reviews/<slug>.md` Axis 2: `| file:line:col | severity | source | message |`.
- [x] 4. Split `code-quality-gate.md` step 1 into `1a. Optional LSP pull` / `1b. Mandatory CLI verification`.

## Acceptance Criteria
### Scenario 1: Happy — diagnostics available
- **Given** `PROMPTKIT.md` has `lsp: optional` and `pnpm tsc --noEmit` reports an error at `src/foo.ts:42:5`
- **When** `pk:review` runs on a diff containing `src/foo.ts`
- **Then** the report's Axis 2 contains a table row `src/foo.ts:42:5 | error | tsc-cli | <message>` mapped to `🚨 [BLOCKING]`

### Scenario 2: Negative — no LSP/CLI configured
- **Given** no LSP and no typecheck command in `PROMPTKIT.md`
- **When** `pk:review` runs
- **Then** the section records `not measured` and the review proceeds via existing standards audit — zero block, zero errors

### Scenario 3: Invariant — provenance
- **Given** diagnostics captured this turn
- **When** the report is finalized
- **Then** every cited `file:line:col` exists within the fixed-point diff; values not executed this turn are reported as `not measured`

## Automated Verification Command
```bash
bash scripts/validate-references.sh
bash scripts/tests/run-behavioral-contract-tests.sh
```

## GitHub CLI Recipe
```bash
gh issue create \
  --title "feat(review): LSP-aware diagnostics injection for pk:review (TS CLI MVP)" \
  --body-file docs/tasks/issue-lsp-01-review-mvp.md \
  --label "type:feature,priority/p1,area:backend"
```
