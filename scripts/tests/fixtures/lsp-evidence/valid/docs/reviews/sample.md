# Senior Code Review: LSP Evidence Fixture (Valid)

<a id="REVIEW-lsp-fixture-valid"></a>

## Review Record Metadata

- **Review ID [Required]**: `REVIEW-lsp-fixture-valid`
- **Resolved Diff Reference [Required]**: `scripts/tests/fixtures/lsp-evidence/baseline.diff`

## Axis 2: Standards & Code Quality

### Diagnostics Evidence (Optional — from Step 2a)
- **Evidence Source**: `tsc-cli`

| Location | Severity | Source | Message |
|----------|----------|--------|---------|
| `src/foo.ts:42:5` | 🚨 [BLOCKING] | tsc-cli | `Type 'string' is not assignable to type 'number'.` |
| `src/bar.ts:17:3` | ⚠️ [IMPORTANT] | eslint | `'a' is assigned a value but never used.` |

### 👏 [PRAISE]
- Citations verified against the fixed-point diff.
