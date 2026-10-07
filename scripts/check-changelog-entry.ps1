# CHANGELOG entry gate: behavior-surface changes must carry a CHANGELOG.md entry.
# Usage: scripts\check-changelog-entry.ps1 [-Base REF] [-Head REF]
# Compares the committed range BASE...HEAD (default origin/main...HEAD).
# Skips cleanly when the base ref is unavailable (shallow or offline checkout).

param(
    [string]$Base = "origin/main",
    [string]$Head = "HEAD"
)

git rev-parse --verify $Base 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    if ($env:GITHUB_EVENT_NAME -eq 'pull_request') {
        Write-Host "CHANGELOG_GATE|MISSING-BASE|base ref '$Base' unavailable on a pull_request event|Ensure the base ref was fetched (fetch-depth) and the range is valid"
        exit 1
    }
    Write-Host "::warning::CHANGELOG gate skipped (no base ref '$Base')"
    Write-Host "CHANGELOG_GATE|SKIP|base ref '$Base' unavailable (shallow or offline checkout)|Fetch it or pass -Base"
    exit 0
}

# Synthetic-base preflight: a base-deriving range is meaningless when either
# endpoint is a tool-owned workspace commit. Read-only; refuses only on positive
# evidence (exit 1), fails closed when the preflight cannot measure (exit 2), and
# fails closed when the preflight file is missing rather than silently skipping.
$detector = Join-Path $PSScriptRoot 'check-synthetic-base.ps1'
if (-not (Test-Path -LiteralPath $detector -PathType Leaf)) {
    Write-Host "CHANGELOG_GATE|INCOMPLETE|synthetic-base preflight missing at '$detector'|Restore scripts/check-synthetic-base.ps1; the preflight must not be skipped"
    exit 2
}
foreach ($endpoint in @($Base, $Head)) {
    $sbOut = & $detector -Root '.' -Commit $endpoint 2>&1 | Out-String
    $sbRc = $LASTEXITCODE
    if ($sbRc -eq 1) {
        Write-Host $sbOut.TrimEnd()
        Write-Host "CHANGELOG_GATE|SYNTHETIC-BASE|refusing to derive $Base...$Head from a synthetic workspace commit ($endpoint)|Return to the carrying branch or rebase onto a real branch tip (docs/MAXIMS.md)"
        exit 1
    }
    if ($sbRc -ne 0) {
        Write-Host $sbOut.TrimEnd()
        Write-Host "CHANGELOG_GATE|INCOMPLETE|synthetic-base preflight could not measure '$endpoint' (exit $sbRc)|Fix the preflight configuration or git state"
        exit 2
    }
}

$files = @(git diff --name-only "$Base...$Head")
if ($files.Count -eq 0) {
    if ($env:GITHUB_EVENT_NAME -eq 'pull_request') {
        Write-Host "CHANGELOG_GATE|EMPTY-RANGE|empty diff $Base...$Head on a pull_request event|Ensure the base ref was fetched (fetch-depth) and the range is non-empty"
        exit 1
    }
    Write-Host "CHANGELOG_GATE|PASS|empty range $Base...$Head, nothing to gate"
    exit 0
}

$behavior = @($files | Where-Object { $_ -match '^(workflows/|templates/|protocols/|package/|init\.sh$|init\.ps1$|scripts/[^/]+$)' })
if ($behavior.Count -eq 0) {
    Write-Host "CHANGELOG_GATE|PASS|no behavior-surface paths in range, entry not required"
    exit 0
}

if ($files -contains 'CHANGELOG.md') {
    Write-Host "CHANGELOG_GATE|PASS|behavior-surface changes carry a CHANGELOG.md entry"
    exit 0
}

Write-Host "CHANGELOG_GATE|MISSING|behavior-surface changes without a CHANGELOG.md entry:"
foreach ($f in $behavior) { Write-Host "  - $f" }
Write-Host "CHANGELOG_GATE|REMEDIATION|Add an [Unreleased] entry to CHANGELOG.md (Keep a Changelog)"
exit 1
