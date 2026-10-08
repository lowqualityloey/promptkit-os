# Regression harness for the thin `pk` entry-point shim (issue #546).
# Mirrors run-pk-entry-points-tests.sh: Scenarios 1, 2, 5, and the help contract.
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-pk-entry-points-tests.ps1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd('\', '/')
$pk = Join-Path $repoRoot 'scripts/pk.ps1'

$script:PASS = 0
$script:FAIL = 0
$script:SCENARIO_OK = $true
$script:STATUS = 0
$script:OUT = ''

function Write-Pass { param([string]$Label) Write-Output "PASS: $Label"; $script:PASS++ }
function Write-Fail { param([string]$Label) Write-Output "FAIL: $Label"; $script:FAIL++ }
function Begin-Scenario { $script:SCENARIO_OK = $true }
function Report-Scenario { param([string]$Label) if ($script:SCENARIO_OK) { Write-Pass $Label } else { Write-Fail $Label } }
function Assert-Scenario {
    param([bool]$Condition, [string]$Description)
    if (-not $Condition) { Write-Output "  - $Description"; $script:SCENARIO_OK = $false }
}

function Invoke-Pk {
    param([string[]]$ExtraArgs = @())
    $saved = @{}
    foreach ($key in @('AI_GATEWAY_API_KEY', 'TYPESAFE_API_KEY')) {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, $null, 'Process')
    }
    try {
        $raw = @(& pwsh -NoProfile -File $pk @ExtraArgs 2>&1)
        $script:STATUS = $LASTEXITCODE
    } finally {
        foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key], 'Process') }
    }
    $script:OUT = ((@($raw | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '')
}

# Scenario 5 parity lock: run-pk-entry-points-tests.sh asserts this identical literal.
$expected = "[PromptKit OS: Level 2 (Controlled) — Offline fallback (no AI_GATEWAY_API_KEY nor TYPESAFE_API_KEY). Task Record required.]`nRecommended Workflow: pk:route"

$probe = Join-Path ([IO.Path]::GetTempPath()) ('pk-entry-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $probe -Force | Out-Null

try {
    # E1 (Scenario 1): route classifies offline, exits 0, and writes nothing.
    Begin-Scenario
    $before = @(Get-ChildItem -LiteralPath $probe -Force -Name)
    Push-Location $probe
    try { Invoke-Pk -ExtraArgs @('route', 'the checkout endpoint returns 500') } finally { Pop-Location }
    $after = @(Get-ChildItem -LiteralPath $probe -Force -Name)
    Assert-Scenario ($script:STATUS -eq 0) "expected exit 0, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('[PromptKit OS: Level ')) 'stdout missing the level banner'
    Assert-Scenario ($script:OUT.Contains('Recommended Workflow: pk:')) 'stdout missing Recommended Workflow'
    Assert-Scenario (($before -join ',') -eq ($after -join ',')) 'shim wrote files into the working directory'
    Report-Scenario 'E1 pk route classifies and exits 0 without side effects'

    # E2 (Scenario 2): a mistyped subcommand exits 2 and names workflows/<cmd>.md.
    Begin-Scenario
    Invoke-Pk -ExtraArgs @('commti')
    Assert-Scenario ($script:STATUS -eq 2) "expected exit 2, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('workflows/commti.md')) 'stderr missing the file-level contract path'
    Report-Scenario 'E2 unknown subcommand exits 2 naming workflows/<cmd>.md'

    # E3 (Scenario 5): output matches the shared parity literal exactly.
    Begin-Scenario
    Invoke-Pk -ExtraArgs @('route', 'the checkout endpoint returns 500')
    Assert-Scenario ($script:STATUS -eq 0) "expected exit 0, got $($script:STATUS)"
    Assert-Scenario ($script:OUT -eq $expected) "output differs from the shared parity literal:`n--- got ---`n$($script:OUT)`n--- expected ---`n$expected"
    Report-Scenario 'E3 route output matches the shared Bash/PowerShell parity literal'

    # E4: --help exits 0; no arguments exits 2.
    Begin-Scenario
    Invoke-Pk -ExtraArgs @('--help')
    Assert-Scenario ($script:STATUS -eq 0) "--help expected exit 0, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('pk route')) "--help usage missing 'pk route'"
    Invoke-Pk -ExtraArgs @()
    Assert-Scenario ($script:STATUS -eq 2) "no-args expected exit 2, got $($script:STATUS)"
    Report-Scenario 'E4 --help exits 0; no arguments exits 2'
} finally {
    Remove-Item -LiteralPath $probe -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "Passed: $($script:PASS) | Failed: $($script:FAIL)"
if ($script:FAIL -ne 0) { exit 1 }
exit 0
