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
    Write-Host "::warning::CHANGELOG gate skipped (no base ref '$Base')"
    Write-Host "CHANGELOG_GATE|SKIP|base ref '$Base' unavailable (shallow or offline checkout)|Fetch it or pass -Base"
    exit 0
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
