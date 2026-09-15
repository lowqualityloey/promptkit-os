# Issue LSP-03: LSP Evidence Validator + Adoption Docs

### Metadata
- **Related Spec**: Plan session 2026-09-15 (LSP-aware pk:review MVP)
- **Depends On**: LSP-01
- **Milestone**: `Unassigned (remote has no open feature milestone; maintainer triage)`
- **Priority**: `#priority/p2`
- **Labels**: `area:tooling, type:feature`
- **Kanban Status**: `To Do`

## User Story & Context
**As a** reviewer consuming `docs/reviews/*.md`
**I want** a read-only validator that proves every cited diagnostic location exists in the reviewed diff
**So that** injected LSP/CLI evidence cannot be hallucinated, matching `Telemetry Card Provenance`.

## Technical Scope & Invariants
- **Files**: `scripts/validate-lsp-evidence.sh` / `.ps1` (new), `scripts/tests/fixtures/lsp-evidence/` (new), `docs/ADOPTION-GUIDE.md` (Scenario 7), `docs/BENCHMARKS.md` (token note)
- **Invariants**: Strictly read-only, stable diagnostic categories + exit-code contract shared across Bash/PowerShell (mirrors `validate-execution-control.*`); no file repair, no remote calls.

### Out of Scope
- Auto-correcting reports, live LSP server communication, CI wiring beyond an optional job.

## Implementation Tasks
- [ ] 1. Implement `scripts/validate-lsp-evidence.sh`: parse Diagnostics Evidence tables in `docs/reviews/*.md`, cross-check each `file:line:col` against the recorded fixed-point diff/revision or fixture baseline.
- [ ] 2. Port parity `.ps1` version; add fixture matrix (valid, hallucinated path, out-of-range line, `not measured` pass-through).
- [ ] 3. Add `docs/ADOPTION-GUIDE.md` Scenario 7: Supercharging `pk:review` with LSP/CLI Diagnostics (opt-in, fallback note).
- [ ] 4. Add `docs/BENCHMARKS.md` row for measured evidence-table token cost.

## Acceptance Criteria
### Scenario 1: Validator pass
- **Given** a review report whose cited `file:line:col` locations exist in the fixture diff
- **When** `bash scripts/validate-lsp-evidence.sh --root .` runs
- **Then** exit code `0`, one summary line

### Scenario 2: Hallucinated citation
- **Given** a report citing `src/missing.ts:99` outside the recorded diff
- **When** the validator runs
- **Then** exit code `1` with an `INVALID_EVIDENCE` diagnostic naming the REVIEW ID and path

### Scenario 3: `not measured` pass-through
- **Given** a report recording `not measured` for diagnostics
- **When** the validator runs
- **Then** exit code `0` with `N/A` note — absence is never a failure

## Automated Verification Command
```bash
bash scripts/tests/run-behavioral-contract-tests.sh
bash scripts/validate-references.sh
```

## GitHub CLI Recipe
```bash
gh issue create \
  --title "feat(tooling): LSP evidence validator + adoption docs" \
  --body-file docs/tasks/issue-lsp-03-validator-docs.md \
  --label "type:feature,priority/p2,area:tooling"
```
