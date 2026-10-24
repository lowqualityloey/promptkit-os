# Projection-parity harness (issue #669): the shared 3A/Task-Record projection
# definition — the pair list AND the comparison-class assignment (#671) — must be
# identical in all four engine scripts (check-doctor.sh, check-doctor.ps1,
# validate-execution-control.sh, validate-execution-control.ps1). Each script's
# definition is extracted textually and compared to the canonical sequence; a
# script that adds, renames, reorders, or reclassifies a field alone fails here
# instead of silently forking the doctor/validator verdicts.
#
# Offline and read-only: parses four repo files, no git, no fixtures.

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Fail([string]$msg) {
    Write-Error "HARNESS_FAILURE|$msg"
    exit 1
}

function Get-Lines([string]$path, [string]$startPattern, [string]$endPattern, [scriptblock]$transform) {
    $inside = $false
    $out = @()
    foreach ($line in (Get-Content -LiteralPath $path)) {
        if (-not $inside -and $line -match $startPattern) { $inside = $true; continue }
        if ($inside -and $line -match $endPattern) { break }
        if ($inside) { $out += (& $transform $line) }
    }
    return @($out | Where-Object { $_ -ne $null -and $_ -ne '' })
}

$doctorSh = Get-Lines (Join-Path $RepoRoot 'scripts/check-doctor.sh') `
    '^SHARED_PROJECTION_FIELDS=\(' '^\)' `
    { param($l) ($l -replace '^\s+', '').Trim("'", '"').Replace('`', '').Replace('\', '').TrimEnd(',') }

$doctorPs1 = Get-Lines (Join-Path $RepoRoot 'scripts/check-doctor.ps1') `
    'sharedProjectionFields = @\(' '^\)' `
    { param($l) $l.Trim().TrimEnd(',').Trim("'").Replace('`', '').Replace('\', '') }

$validatorShRaw = (Select-String -LiteralPath (Join-Path $RepoRoot 'scripts/validate-execution-control.sh') -Pattern 'compare_pairs=\(.*\)').Matches.Value
$validatorSh = @()
foreach ($tok in (($validatorShRaw -replace '^compare_pairs=\(', '' -replace '\)$', '') -split '" "' -replace '"', '')) {
    $t = $tok.Replace('`', '').Replace('\', '')
    if ($t -ne '') { $validatorSh += $t }
}

$validatorPs1 = Get-Lines (Join-Path $RepoRoot 'scripts/validate-execution-control.ps1') `
    'foreach \(\$pair in @\(' '^\s*\)\)\s*\{' `
    { param($l) if ($l -match "^\s*@\('([^']*)', '([^']*)', '([^']*)'\),?$") { return ("$($Matches[1])|$($Matches[2])|$($Matches[3])").Replace('`', '').Replace('\', '') } return $null }

$definitions = @{ 'check-doctor.sh' = $doctorSh; 'check-doctor.ps1' = $doctorPs1; 'validate-execution-control.sh' = $validatorSh; 'validate-execution-control.ps1' = $validatorPs1 }
foreach ($name in $definitions.Keys) {
    if ($definitions[$name].Count -ne 10) { Fail "$name does not declare exactly 10 projection fields (got $($definitions[$name].Count))" }
}
foreach ($name in @('check-doctor.ps1', 'validate-execution-control.sh', 'validate-execution-control.ps1')) {
    if ((($definitions['check-doctor.sh'] | ForEach-Object { $_ }) -join "`n") -ne (($definitions[$name] | ForEach-Object { $_ }) -join "`n")) {
        Fail "projection definition diverges between check-doctor.sh and $name"
    }
}
$prose = @($definitions['check-doctor.sh'] | ForEach-Object { ($_ -split '\|')[2] } | Where-Object { $_ -eq 'prose' }).Count
$machine = @($definitions['check-doctor.sh'] | ForEach-Object { ($_ -split '\|')[2] } | Where-Object { $_ -eq 'machine' }).Count
$level = @($definitions['check-doctor.sh'] | ForEach-Object { ($_ -split '\|')[2] } | Where-Object { $_ -eq 'level' }).Count
if ($prose -ne 3) { Fail "prose class must cover exactly 3 fields, got $prose" }
if ($machine -ne 6) { Fail "machine class must cover exactly 6 fields, got $machine" }
if ($level -ne 1) { Fail "level class must cover exactly Ceremony Level, got $level" }

Write-Output 'PASS|projection definition identical across check-doctor and validate-execution-control twins (10 fields; prose=Execution Scope,Next Action,Specification; level=Ceremony Level; machine=6)'
