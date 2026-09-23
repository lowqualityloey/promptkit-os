---
status: Shipped
---

# Issue LSP-02: LSP Detection + Setup Matrix Row + Profile Opt-In

### Metadata
- **Related Spec**: Plan session 2026-09-15 (LSP-aware pk:review MVP)
- **Blocks**: LSP-01
- **Milestone**: `Unassigned (remote has no open feature milestone; maintainer triage)`
- **Priority**: `#priority/p2`
- **Labels**: `area:backend, type:feature`
- **Kanban Status**: `In Review`

## User Story & Context
**As a** team adopting PromptKit OS
**I want** passive LSP capability detection and an explicit opt-in flag in `PROMPTKIT.md`
**So that** `pk:review` knows whether range-accurate diagnostics are available, with zero config for teams that skip it.

## Technical Scope & Invariants
- **Files**: `protocols/context-sync.md` (§4 detection), `protocols/setup.md` (MCP precedence matrix), `templates/project-profile-template.md` (§5a new LSP section)
- **Invariants**: LSP never auto-enabled (human config, mirrors `issue-02-mcp-flags` rule); non-blocking advise only; Lite profile defaults to `lsp: disabled`.

### Out of Scope
- Auto-starting language servers, `.vscode` mutation, host runtime guarantees.

## Implementation Tasks
- [x] 1. Extend `context-sync.md §4` MCP & Native Tooling inspection to detect `tsserver`/`pyright`/`rust-analyzer` from `.vscode/settings.json`, editor configs, and `PROMPTKIT.md §5a`.
- [x] 2. Add `Diagnostics & Type Integrity` row to the `protocols/setup.md` Tool Precedence Matrix: `1. lsp-mcp (future) | 2. Native IDE tools | 3. tsc/biome/eslint JSON | 4. Manual`.
- [x] 3. Add `§5a LSP Capabilities (Optional)` to `project-profile-template.md`: `LSP Enabled [false default]`, `Servers [tsserver | none]`, `Evidence Source [lsp-mcp | tsc-cli | not measured]`.
- [x] 4. Add graceful-degradation rule: `Never block on missing LSP` (mirrors rule 3 of the MCP matrix).

## Acceptance Criteria
### Scenario 1: Detection
- **Given** an editor config enables `typescript-language-server` and `PROMPTKIT.md §5a` is unset
- **When** `pk:onboard` / context-sync runs
- **Then** `§5a` is proposed with `LSP Enabled: true`, `Evidence Source: lsp-mcp` — advise only, session continues regardless

### Scenario 2: Disabled default
- **Given** `init.sh --lite` on a fresh repo
- **When** `PROMPTKIT.md` is scaffolded
- **Then** `§5a` reads `LSP Enabled: false` and directive token overhead is unchanged (0 additional tokens)

### Scenario 3: CI / non-interactive
- **Given** `PROMPTKIT_NO_INTERACTIVE=1`
- **When** onboard runs
- **Then** `§5a` records `not measured` without prompting

## Automated Verification Command
```bash
bash scripts/validate-references.sh
```

## GitHub CLI Recipe
```bash
gh issue create \
  --title "feat(context-sync): LSP detection + setup matrix row + profile opt-in" \
  --body-file docs/tasks/issue-lsp-02-context-matrix.md \
  --label "type:feature,priority/p2,area:backend"
```
