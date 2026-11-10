#!/usr/bin/env pwsh
<#
.SYNOPSIS
    PromptKit OS Ceremony Artifact Overhead Measurement (PowerShell twin).
.DESCRIPTION
    Byte-for-byte behavioural twin of scripts/measure-ceremony-overhead.sh.
    Measures the ceremony artifacts each task level requires (workflows/route.md
    is the canonical authority for Level 0-3 ceremony) and reports their static
    byte and token load. Uses the bytes/4 convention of measure-tokens.ps1:
        tokens = floor((bytes after CR stripping + 2) / 4)

    TWO UNITS, deliberately kept apart:
      1. Per-task artifacts -- a template the level obliges an agent to fill for
         each task. Repeated cost: paid once per task.
      2. Shared setup -- a template filled once per project and updated in place
         afterwards (docs/STATE.md). Paid once, then amortised; charging it at
         every level would count the same bytes once per task forever.

    PLANNING DEPTH IS PART OF THE MODEL. workflows/plan.md:67-69 makes "Minimal
    Planning (Level 2 default)" stop before the full RFC, so a Level 2 task does
    NOT necessarily produce a specification file. The per-level baseline is the
    Minimal Planning set; the specification family is published as a band.

    ONE REQUIRED ARTIFACT HAS NO SHIPPED TEMPLATE: workflows/review.md:19 gives
    pk:review "one durable two-axis report at docs/reviews/<review-slug>.md".
    It is listed as required and reported as not measurable from repository
    bytes -- never silently dropped, never estimated.

    Membership is a CURATED SELECTION, not a parse. POLICY_ANCHORS pins the
    WHOLE ceremony line by SHA-256, so an added requirement inside a cited
    paragraph fails the run. It cannot see a requirement added elsewhere in a
    workflow file; docs/BENCHMARKS.md states that limit.

    Modes:
      default  : informational report.
      -Strict  : CI gate mode. Asserts every measured figure EQUALS its recorded
                 baseline -- growth and reduction both fail. Coverage is every
                 published number: four per-level totals, shared setup, all four
                 specification variants, all five optional artifacts, and both
                 band endpoints for Level 2 and Level 3.

    Exit codes: 0 pass, 1 strict gate failure, 2 policy drift or missing file.
#>

[CmdletBinding()]
param (
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KitDir = Split-Path -Parent $ScriptDir

# Recorded baselines, keyed by unit. -Strict compares by EQUALITY: these are not
# ceilings and not targets, they are the published numbers, and they must be
# restated when a measured template legitimately changes.
$Baseline = [ordered]@{
    "L0" = 0
    "L1" = 0
    "L2" = 5639
    "L3" = 13458
    "SETUP" = 3021
    "SPEC:templates/tech-spec-template.md" = 5480
    "SPEC:templates/data-model-spec.md" = 1825
    "SPEC:templates/auth-matrix-template.md" = 979
    "SPEC:templates/api-contract-spec.md" = 1347
    "OPT:templates/execution-checkpoint-template.md" = 827
    "OPT:templates/execution-handoff-template.md" = 978
    "OPT:templates/execution-scope-change-template.md" = 782
    "OPT:templates/ci-triage-template.md" = 1603
    "OPT:templates/code-review-checklist.md" = 1534
    "BAND:L2:min" = 6618
    "BAND:L2:max" = 11119
    "BAND:L3:min" = 14437
    "BAND:L3:max" = 18938
}

# Policy the artifact model rests on: <file>|<literal fragment>|<sha256 prefix>.
$PolicyAnchors = @(
    @{ File = "workflows/route.md"; Phrase = "Direct execution. Zero task records"; Hash = "bfb62859635b83d7" },
    @{ File = "workflows/route.md"; Phrase = "Natural workflow routing"; Hash = "164e9e3470607701" },
    @{ File = "workflows/route.md"; Phrase = "Requires a Local Task Record"; Hash = "cef964ae7430feb8" },
    @{ File = "workflows/route.md"; Phrase = "Uses full release candidate evaluation"; Hash = "8edb52f8602095c1" },
    @{ File = "workflows/checkpoint.md"; Phrase = "Level 1 (Standard) work updates"; Hash = "88aabdd5e32c660a" },
    @{ File = "workflows/plan.md"; Phrase = "Minimal Planning (Level 2 default)"; Hash = "201483077233b647" },
    @{ File = "workflows/plan.md"; Phrase = "Full Planning (Level 2 triggering work)"; Hash = "2eac98e5feb5025e" },
    @{ File = "workflows/review.md"; Phrase = "owns one durable two-axis report"; Hash = "2deb075a198f7e9c" }
)

$SharedSetup = "templates/state-tracker-template.md"

$LevelRequired = [ordered]@{
    "L0" = @()
    "L1" = @()
    "L2" = @("templates/execution-task-record-template.md", "templates/execution-checkpoint-template.md")
    "L3" = @(
        "templates/execution-task-record-template.md",
        "templates/execution-checkpoint-template.md",
        "templates/release-checklist.md",
        "templates/release-evaluation-template.md",
        "templates/contract-impact-evidence-template.md"
    )
}

$LevelUntemplated = [ordered]@{
    "L0" = @()
    "L1" = @()
    "L2" = @("docs/reviews/<review-slug>.md")
    "L3" = @("docs/reviews/<review-slug>.md")
}

$LevelOptional = [ordered]@{
    "L0" = @()
    "L1" = @("templates/execution-checkpoint-template.md")
    "L2" = @("templates/execution-handoff-template.md", "templates/execution-scope-change-template.md")
    "L3" = @(
        "templates/execution-handoff-template.md",
        "templates/execution-scope-change-template.md",
        "templates/ci-triage-template.md",
        "templates/code-review-checklist.md"
    )
}

$LevelLabel = [ordered]@{
    "L0" = "Direct"
    "L1" = "Standard"
    "L2" = "Controlled"
    "L3" = "Release-Critical"
}

$SpecPinned = "templates/tech-spec-template.md"
$SpecFamily = @(
    "templates/tech-spec-template.md",
    "templates/data-model-spec.md",
    "templates/auth-matrix-template.md",
    "templates/api-contract-spec.md"
)

$OptionalUnion = @(
    "templates/execution-checkpoint-template.md",
    "templates/execution-handoff-template.md",
    "templates/execution-scope-change-template.md",
    "templates/ci-triage-template.md",
    "templates/code-review-checklist.md"
)

function Measure-Bytes {
    param([string]$RelativePath)
    $full = Join-Path $KitDir $RelativePath
    if (-not (Test-Path -LiteralPath $full)) {
        [Console]::Error.WriteLine("MEASURE_ERROR|MISSING|$RelativePath")
        exit 2
    }
    $raw = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    # Match Bash tr -d '\r': normalize line endings without dropping the final LF.
    $norm = $raw -replace "\r", ""
    return [System.Text.Encoding]::UTF8.GetByteCount($norm)
}

function Measure-Tokens {
    param([int]$Bytes)
    return [Math]::Floor(($Bytes + 2) / 4)
}

function Get-LineHash {
    param([string]$Line)
    $norm = $Line -replace "\r", ""
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($norm)
        $hash = $sha.ComputeHash($bytes)
        $hex = -join ($hash | ForEach-Object { $_.ToString("x2") })
        return $hex.Substring(0, 16)
    } finally {
        $sha.Dispose()
    }
}

$Sha = "unknown"
try {
    $Sha = (& git -C $KitDir rev-parse --short HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Sha)) { $Sha = "unknown" }
    else { $Sha = $Sha.Trim() }
} catch {
    $Sha = "unknown"
}
$Datestamp = Get-Date -Format "yyyy-MM-dd"

Write-Host ""
Write-Host "PromptKit OS Ceremony Artifact Overhead by Task Level"
Write-Host "===================================================="
Write-Host "Repo SHA: $Sha"
Write-Host "Date: $Datestamp"
Write-Host "Convention: tokens = floor((bytes after CR stripping + 2) / 4)"

Write-Host ""
Write-Host "Policy anchors (whole cited line pinned by SHA-256):"
foreach ($anchor in $PolicyAnchors) {
    $full = Join-Path $KitDir $anchor.File
    if (-not (Test-Path -LiteralPath $full)) {
        [Console]::Error.WriteLine("CEREMONY_ANCHOR|$($anchor.File)|MISSING")
        [Console]::Error.WriteLine("ANCHOR_ERROR|POLICY_DRIFT|$($anchor.File) does not exist")
        [Console]::Error.WriteLine("ANCHOR_ERROR|ACTION|re-derive the artifact selection in this script and docs/BENCHMARKS.md before trusting any figure")
        exit 2
    }
    $lines = [System.IO.File]::ReadAllLines($full, [System.Text.Encoding]::UTF8)
    $line = $null
    foreach ($candidate in $lines) {
        if ($candidate.Contains($anchor.Phrase)) { $line = $candidate; break }
    }
    if ($null -eq $line) {
        [Console]::Error.WriteLine("CEREMONY_ANCHOR|$($anchor.File)|MISSING")
        [Console]::Error.WriteLine("ANCHOR_ERROR|POLICY_DRIFT|$($anchor.File) no longer contains: $($anchor.Phrase)")
        [Console]::Error.WriteLine("ANCHOR_ERROR|ACTION|re-derive the artifact selection in this script and docs/BENCHMARKS.md before trusting any figure")
        exit 2
    }
    $got = Get-LineHash -Line $line
    if ($got -ne $anchor.Hash) {
        [Console]::Error.WriteLine("CEREMONY_ANCHOR|$($anchor.File)|CHANGED")
        [Console]::Error.WriteLine("ANCHOR_ERROR|POLICY_DRIFT|$($anchor.File) line containing '$($anchor.Phrase)' changed (expected $($anchor.Hash), found $got)")
        [Console]::Error.WriteLine("ANCHOR_ERROR|ACTION|re-read the cited line, re-derive the artifact selection, then restate the hash here and the figures in docs/BENCHMARKS.md")
        exit 2
    }
    Write-Host "CEREMONY_ANCHOR|$($anchor.File)|OK"
}

$SetupBytes = 0
$SetupTokens = 0
$SetupCount = 0
foreach ($path in @($SharedSetup)) {
    $bytes = Measure-Bytes -RelativePath $path
    $tokens = Measure-Tokens -Bytes $bytes
    $SetupBytes += $bytes
    $SetupTokens += $tokens
    $SetupCount += 1
}

$ReqBytes = @{}
$ReqTokens = @{}
$ReqCount = @{}
$UntCount = @{}
$OptCount = @{}
foreach ($level in @("L0", "L1", "L2", "L3")) {
    $ReqBytes[$level] = 0
    $ReqTokens[$level] = 0
    $ReqCount[$level] = 0
    $UntCount[$level] = 0
    $OptCount[$level] = 0
    foreach ($path in $LevelRequired[$level]) {
        $bytes = Measure-Bytes -RelativePath $path
        $tokens = Measure-Tokens -Bytes $bytes
        $ReqBytes[$level] += $bytes
        $ReqTokens[$level] += $tokens
        $ReqCount[$level] += 1
    }
    foreach ($path in $LevelUntemplated[$level]) {
        $UntCount[$level] += 1
    }
    foreach ($path in $LevelOptional[$level]) {
        $OptCount[$level] += 1
    }
}

$SpecTokens = @{}
$OptTokens = @{}
$SpecMin = 0
$SpecMax = 0
foreach ($path in $SpecFamily) {
    $bytes = Measure-Bytes -RelativePath $path
    $tokens = Measure-Tokens -Bytes $bytes
    $SpecTokens[$path] = $tokens
    if ($SpecMin -eq 0 -or $tokens -lt $SpecMin) { $SpecMin = $tokens }
    if ($tokens -gt $SpecMax) { $SpecMax = $tokens }
}
foreach ($path in $OptionalUnion) {
    $bytes = Measure-Bytes -RelativePath $path
    $OptTokens[$path] = Measure-Tokens -Bytes $bytes
}

$BandMin = @{}
$BandMax = @{}
foreach ($level in @("L2", "L3")) {
    $BandMin[$level] = $ReqTokens[$level] + $SpecMin
    $BandMax[$level] = $ReqTokens[$level] + $SpecMax
}

Write-Host ""
Write-Host "Shared one-time setup (paid once per project, then updated in place):"
Write-Host ("  {0,-52} {1,6} B  {2,5} tok" -f $SharedSetup, $SetupBytes, $SetupTokens)
Write-Host ""

Write-Host "Per-task required ceremony artifacts per level (Minimal Planning set):"
foreach ($level in @("L0", "L1", "L2", "L3")) {
    Write-Host ("  {0,-2} {1,-17} {2,2} file(s)  {3,6} bytes  {4,6} tok" -f $level, $LevelLabel[$level], $ReqCount[$level], $ReqBytes[$level], $ReqTokens[$level])
}
Write-Host ""

Write-Host "Artifact detail:"
foreach ($level in @("L0", "L1", "L2", "L3")) {
    if ($LevelRequired[$level].Count -eq 0 -and $LevelOptional[$level].Count -eq 0 -and $LevelUntemplated[$level].Count -eq 0) {
        Write-Host ("  {0}: none per task (deliberate - zero per-task ceremony artifacts)" -f $level)
        continue
    }
    foreach ($path in $LevelRequired[$level]) {
        $bytes = Measure-Bytes -RelativePath $path
        Write-Host ("  {0,-2} required     {1,-52} {2,6} B  {3,5} tok" -f $level, $path, $bytes, (Measure-Tokens -Bytes $bytes))
    }
    foreach ($path in $LevelUntemplated[$level]) {
        Write-Host ("  {0,-2} required     {1,-52} {2,6} B  {3,5} tok  (no shipped template)" -f $level, $path, "-", "-")
    }
    foreach ($path in $LevelOptional[$level]) {
        $bytes = Measure-Bytes -RelativePath $path
        Write-Host ("  {0,-2} optional     {1,-52} {2,6} B  {3,5} tok" -f $level, $path, $bytes, (Measure-Tokens -Bytes $bytes))
    }
}
Write-Host ""

Write-Host "Level 2 planning depth (workflows/plan.md:67-69):"
Write-Host ("  {0,-34} {1,6} tok  (Task Record + checkpoint; no specification file)" -f "Minimal Planning (default)", $ReqTokens["L2"])
Write-Host ("  {0,-34} {1,6}-{2} tok  (adds exactly one specification family member)" -f "Full Planning (triggering)", $BandMin["L2"], $BandMax["L2"])
Write-Host ""
Write-Host "Level 3 planning depth (Level 2 planning plus release evidence):"
Write-Host ("  {0,-34} {1,6} tok  (Task Record + checkpoint + release evidence)" -f "Minimal Planning (default)", $ReqTokens["L3"])
Write-Host ("  {0,-34} {1,6}-{2} tok  (adds exactly one specification family member)" -f "Full Planning (triggering)", $BandMin["L3"], $BandMax["L3"])
Write-Host ""

Write-Host "Specification family (one member per task, selected by sub-trigger):"
foreach ($path in $SpecFamily) {
    Write-Host ("  {0,-52} {1,5} tok  L2 total {2,6} tok" -f $path, $SpecTokens[$path], ($ReqTokens["L2"] + $SpecTokens[$path]))
}
Write-Host ""

Write-Host "Optional artifacts (required only in the condition named):"
foreach ($path in $OptionalUnion) {
    Write-Host ("  {0,-52} {1,5} tok" -f $path, $OptTokens[$path])
}
Write-Host ""

Write-Host "CEREMONY_ARTIFACT|SETUP|$SharedSetup|setup|$SetupBytes|$SetupTokens"
foreach ($level in @("L0", "L1", "L2", "L3")) {
    if ($LevelRequired[$level].Count -eq 0 -and $LevelUntemplated[$level].Count -eq 0 -and $LevelOptional[$level].Count -eq 0) {
        Write-Host "CEREMONY_ARTIFACT|$level|-|required|0|0"
        continue
    }
    foreach ($path in $LevelRequired[$level]) {
        $bytes = Measure-Bytes -RelativePath $path
        Write-Host "CEREMONY_ARTIFACT|$level|$path|required|$bytes|$(Measure-Tokens -Bytes $bytes)"
    }
    foreach ($path in $LevelUntemplated[$level]) {
        Write-Host "CEREMONY_ARTIFACT|$level|$path|untemplated|0|0"
    }
    foreach ($path in $LevelOptional[$level]) {
        $bytes = Measure-Bytes -RelativePath $path
        Write-Host "CEREMONY_ARTIFACT|$level|$path|optional|$bytes|$(Measure-Tokens -Bytes $bytes)"
    }
}
foreach ($path in $SpecFamily) {
    $bytes = Measure-Bytes -RelativePath $path
    Write-Host "CEREMONY_ARTIFACT|SPEC|$path|variant|$bytes|$($SpecTokens[$path])"
}

Write-Host ""

$Profile = "unknown"
$promptkitPath = Join-Path $KitDir "PROMPTKIT.md"
if (Test-Path -LiteralPath $promptkitPath) {
    $profileLine = $null
    foreach ($candidate in [System.IO.File]::ReadAllLines($promptkitPath, [System.Text.Encoding]::UTF8)) {
        if ($candidate.StartsWith("- **Profile**:")) { $profileLine = $candidate; break }
    }
    if ($null -ne $profileLine) {
        $stripped = $profileLine -replace "^- \*\*Profile\*\*: *", ""
        $stripped = $stripped -replace "\x60", ""
        $m = [regex]::Match($stripped, "^[a-z]+")
        if ($m.Success) { $Profile = $m.Value }
    }
}
Write-Host "CEREMONY_PROVENANCE|sha=$Sha|date=$Datestamp|convention=floor((bytes+2)/4)|profile=$Profile|units=per-task+shared-setup|selection=curated-not-parsed|anchors=whole-line-sha256"
Write-Host "CEREMONY_UNMEASURED|live-telemetry|not-measured|tool calls, elapsed time, model/host identity and interventions per level need host telemetry this repository does not capture"
Write-Host "CEREMONY_UNMEASURED|sample-count|not-measured|static artifact measurement is deterministic; no repeated live runs were executed for this number"
Write-Host "CEREMONY_UNMEASURED|fill-cost|not-measured|filling a template costs generation; the figures here are the size of the template text, not the cost of producing a record"
Write-Host "CEREMONY_UNMEASURED|review-report|not-measured|workflows/review.md:19 requires one durable report at docs/reviews/<review-slug>.md and no template for it ships in this repository, so its size is not derivable from repository bytes"

Write-Host "CEREMONY_SHARED_SETUP|files=$SetupCount|bytes=$SetupBytes|tokens=$SetupTokens|amortisation=once-per-project"
foreach ($level in @("L0", "L1", "L2", "L3")) {
    Write-Host "CEREMONY_TOTAL|$level|required_files=$($ReqCount[$level])|untemplated_files=$($UntCount[$level])|optional_files=$($OptCount[$level])|required_bytes=$($ReqBytes[$level])|required_tokens=$($ReqTokens[$level])"
}
foreach ($level in @("L2", "L3")) {
    Write-Host "CEREMONY_SPEC_BAND|$level|$($BandMin[$level])|$($BandMax[$level])|pinned=$SpecPinned"
}

if ($Strict) {
    Write-Host ""
    Write-Host "Strict mode: measured figures vs recorded baselines (equality required)"
    $Failed = $false
    $StrictUnits = @("L0", "L1", "L2", "L3", "SETUP")
    foreach ($path in $SpecFamily) { $StrictUnits += "SPEC:$path" }
    foreach ($path in $OptionalUnion) { $StrictUnits += "OPT:$path" }
    $StrictUnits += @("BAND:L2:min", "BAND:L2:max", "BAND:L3:min", "BAND:L3:max")
    foreach ($unit in $StrictUnits) {
        $measured = $null
        if ($unit -in @("L0", "L1", "L2", "L3")) { $measured = $ReqTokens[$unit] }
        elseif ($unit -eq "SETUP") { $measured = $SetupTokens }
        elseif ($unit.StartsWith("SPEC:")) { $measured = $SpecTokens[$unit.Substring(5)] }
        elseif ($unit.StartsWith("OPT:")) { $measured = $OptTokens[$unit.Substring(4)] }
        elseif ($unit -eq "BAND:L2:min") { $measured = $BandMin["L2"] }
        elseif ($unit -eq "BAND:L2:max") { $measured = $BandMax["L2"] }
        elseif ($unit -eq "BAND:L3:min") { $measured = $BandMin["L3"] }
        elseif ($unit -eq "BAND:L3:max") { $measured = $BandMax["L3"] }
        if (-not $Baseline.Contains($unit)) {
            Write-Host "CEREMONY_BASELINE|$unit|$measured|unrecorded|FAIL"
            $Failed = $true
            continue
        }
        $limit = $Baseline[$unit]
        if ($measured -eq $limit) {
            Write-Host "CEREMONY_BASELINE|$unit|$measured|$limit|PASS"
        } else {
            Write-Host "CEREMONY_BASELINE|$unit|$measured|$limit|FAIL"
            $Failed = $true
        }
    }
    if ($Failed) {
        [Console]::Error.WriteLine("CEREMONY_GATE|FAIL|a measured figure differs from its recorded baseline; restate the baseline here and in docs/BENCHMARKS.md when a template change is legitimate")
        exit 1
    }
    Write-Host "CEREMONY_GATE|PASS"
}
