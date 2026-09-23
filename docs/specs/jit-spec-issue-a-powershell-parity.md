---
status: Superseded
---

# JIT Implementation Spec: Issue A — PowerShell Parity with init.sh

## Problem and Evidence
`init.ps1` performs directive block injection/replacement using `[regex]::Replace($content, $pattern, $Directive)` without checking for malformed or duplicate marker blocks.
- If duplicate `<!-- PROMPTKIT_START -->` or `<!-- PROMPTKIT_END -->` markers exist, or an incomplete marker block is present, `init.ps1` modifies the file unsafely.
- `$Directive` contains `$` variable references (e.g., `$KitDirRel`), which `[regex]::Replace` treats as regex capture group substitution tokens (e.g. `$1`, `$2`), corrupting injected content.
- File read/write operations with `Get-Content`/`Set-Content`/`Add-Content` without explicit encoding controls can produce UTF-8 BOM on Windows PowerShell 5.1 or corrupt multibyte UTF-8 characters (emojis, CJK).

## Root Cause
- Lack of marker count verification (`PROMPTKIT_START` count == 1 and `PROMPTKIT_END` count == 1) prior to updating.
- Using regex replacement with raw string `$Directive` without escaping `$` replacement tokens (`$Directive.Replace('$', '$$')` or non-regex replacement).
- Absence of atomic write-and-replace mechanism to ensure original file remains untouched on error.
- Default PowerShell file encoding behavior across PowerShell 5.1 and 7.

## Files / Symbols Affected
- `init.ps1`: Update Section 5 directive replacement/injection logic.
- `scripts/tests/run-init-safety-tests.ps1`: New PowerShell regression test suite.
- `.github/workflows/ci.yml`: Add `run-init-safety-tests.ps1` execution to Windows CI job.

## Public Behavior Impact
- `init.ps1` will now validate PromptKit block markers before replacement. If markers are malformed or duplicated, `init.ps1` errors loudly to stderr/error stream and leaves the original file byte-for-byte unchanged.
- Literal `$` characters in directive templates are preserved without regex token substitution.
- UTF-8 characters (including emojis and CJK characters) survive updates intact.
- Preserves idempotency: running `init.ps1` multiple times results in exactly one PromptKit block.

## Compatibility Considerations
- Compatible with Windows PowerShell 5.1 and PowerShell 7+.
- Retains existing behavior for new AGENTS.md creation and block appending when no PromptKit block exists.

## Verification Commands
- `pwsh -NoProfile -File .\scripts\tests\run-init-safety-tests.ps1`
- `bash scripts/tests/run-init-safety-tests.sh`
- Windows setup dry-run and idempotency test step in CI.

## Release Impact
- Patch candidate (bugfix & behavioral parity).
