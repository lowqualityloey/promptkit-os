# Read-only validator for Diagnostics Evidence tables in docs/reviews/*.md.
# Proves every cited file:line:col location falls inside the recorded fixed-point diff.
# Run from repository root: pwsh -NoProfile -File .\scripts\validate-lsp-evidence.ps1 -Root . -DiffFile baseline.diff
#
# Exit codes: 0 = all citations verified or no citations present; 1 = violations found.
# Diagnostic format: CATEGORY|REVIEW_ID|FILE|MESSAGE|REMEDIATION (stable across Bash/PowerShell).

param(
    [string]$Root = ".",
    [string]$DiffFile = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Write-Output "ERROR|UNKNOWN|$Root|Root directory not found|Pass -Root pointing at the repository root"
    exit 1
}
$Root = (Resolve-Path -LiteralPath $Root).Path
$ReviewsDir = Join-Path $Root "docs/reviews"

if (-not (Test-Path -LiteralPath $ReviewsDir -PathType Container)) {
    Write-Output "PASSED|RECORDS=0|CITED=0|note=no-reviews-directory"
    exit 0
}

$citations = @()
$records = @(Get-ChildItem -LiteralPath $ReviewsDir -Filter *.md -File)

foreach ($report in $records) {
    $section = $false
    foreach ($line in (Get-Content -LiteralPath $report.FullName)) {
        if ($line -match '^#{2,3} ') {
            $section = ($line -match 'Diagnostics Evidence')
            continue
        }
        if (-not $section) { continue }
        if ($line -notmatch '\|\s*.`?[A-Za-z0-9_./@-]+\.[A-Za-z0-9]+:[0-9]+') { continue }
        foreach ($m in [regex]::Matches($line, '[A-Za-z0-9_./@-]+\.[A-Za-z0-9]+:[0-9]+(:[0-9]+)?')) {
            $citations += [pscustomobject]@{ Report = $report; Location = $m.Value }
        }
    }
}

if ($citations.Count -eq 0) {
    Write-Output "PASSED|RECORDS=$($records.Count)|CITED=0|note=not-measured-or-no-diagnostics-section"
    exit 0
}

if ([string]::IsNullOrEmpty($DiffFile) -or -not (Test-Path -LiteralPath $DiffFile -PathType Leaf)) {
    Write-Output "ERROR|MISSING_DIFF|-|--diff-file is required when a report cites diagnostics|Provide the fixed-point git diff file or record not measured"
    exit 1
}

$ranges = @()
$file = ""
foreach ($line in (Get-Content -LiteralPath $DiffFile)) {
    if ($line -match '^\+\+\+ b/(.+)$') { $file = $Matches[1]; continue }
    if ($file -and $line -match '^@@ .* \+(\d+)(?:,(\d+))? @@') {
        $start = [int]$Matches[1]
        $count = if ($Matches[2]) { [int]$Matches[2] } else { 1 }
        if ($count -lt 1) { $count = 1 }
        $ranges += [pscustomobject]@{ File = $file; Start = $start; End = $start + $count - 1 }
    }
}

$errors = 0
foreach ($c in $citations) {
    $rel = $c.Report.FullName.Substring($Root.Length + 1) -replace '\\', '/'
    $anchor = (Get-Content -LiteralPath $c.Report.FullName -TotalCount 10 | Select-String -Pattern 'id="(REVIEW-[^"]+)"' | Select-Object -First 1)
    if ($anchor) {
        $reviewId = $anchor.Matches[0].Groups[1].Value
    } else {
        $reviewId = "REVIEW-" + $c.Report.BaseName
    }
    $parts = $c.Location -split ':'
    $path = $parts[0]
    $lineNo = [int]$parts[1]
    $found = $false
    foreach ($r in $ranges) {
        if ($r.File -eq $path -and $lineNo -ge $r.Start -and $lineNo -le $r.End) { $found = $true; break }
    }
    if (-not $found) {
        Write-Output "INVALID_EVIDENCE|$reviewId|$rel|Cited location $($c.Location) is not inside the recorded fixed-point diff|Remove or correct the citation, or record not measured"
        $errors++
    }
}

if ($errors -gt 0) {
    Write-Output "FAILED|ERRORS=$errors|RECORDS=$($records.Count)|CITED=$($citations.Count)"
    exit 1
}
Write-Output "PASSED|RECORDS=$($records.Count)|CITED=$($citations.Count)"
exit 0
