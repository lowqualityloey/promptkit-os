# Senior Code Review: LSP Evidence Fixture (Hallucinated)

<a id="REVIEW-lsp-fixture-hallucinated"></a>

## Review Record Metadata

- **Review ID [Required]**: `REVIEW-lsp-fixture-hallucinated`
- **Resolved Diff Reference [Required]**: `scripts/tests/fixtures/lsp-evidence/baseline.diff`

## Axis 2: Standards & Code Quality

### Diagnostics Evidence (Optional — from Step 2a)
- **Evidence Source**: `tsc-cli`

| Location | Severity | Source | Message |
|----------|----------|--------|---------|
| `src/missing.ts:99:1` | 🚨 [BLOCKING] | tsc-cli | `Cannot find module './ghost'.` |
