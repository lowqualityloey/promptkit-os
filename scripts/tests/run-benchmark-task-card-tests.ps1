# Regression harness for scripts\check-benchmark-task-cards.ps1.
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-benchmark-task-card-tests.ps1
#
# Each case writes throwaway cards under a temp root shaped like the repository
# (<root>\benchmarks\tasks\TASK-*.md) and asserts the lint's exit status and
# machine lines. The last case runs the lint against the real card set, so the
# published cards are pinned to the convention the template states.

$ErrorActionPreference = 'Stop'
$invariant = [System.Globalization.CultureInfo]::InvariantCulture
[System.Threading.Thread]::CurrentThread.CurrentCulture = $invariant

$checker = Join-Path $PSScriptRoot '..\check-benchmark-task-cards.ps1'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$tempRoot = Join-Path $env:TEMP ("taskcard-" + [guid]::NewGuid().ToString("N").Substring(0, 8))

$script:Pass = 0
$script:Fail = 0
$script:Status = 0
$script:Out = ""

function Write-Pass([string]$Name) { Write-Host "PASS: $Name"; $script:Pass += 1 }
function Write-Fail([string]$Name) { Write-Host "FAIL: $Name"; $script:Fail += 1 }

function Invoke-Check {
    param([string]$Root, [string[]]$Extra = @())
    $script:Status = 0
    $script:Out = ""
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $script:Out = (& $checker -Root $Root @Extra 6>&1 | Out-String)
        if ($null -ne $LASTEXITCODE) { $script:Status = $LASTEXITCODE }
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

function New-Root([string]$Name) {
    $root = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'benchmarks/tasks') | Out-Null
    return $root
}

function New-Card {
    param(
        [string]$Root,
        [string]$Id,
        [string]$Value,
        [bool]$IncludeVerify = $true
    )
    $lines = @(
        '# Task Spec: fixture',
        '',
        ('- **Task ID**: `' + $Id + '`'),
        '- **Level**: `L1`'
    )
    if ($IncludeVerify) { $lines += ('- **Verify**: `' + $Value + '`') }
    $file = Join-Path $Root ("benchmarks/tasks/TASK-" + $Id + ".md")
    Set-Content -LiteralPath $file -Value $lines
}

function Test-Status([string]$Expected) {
    $want = [int]$Expected
    if ($script:Status -eq $want) { return $true }
    Write-Host "  - expected exit $want, got $($script:Status)"
    Write-Host "  - output: $($script:Out.Trim())"
    return $false
}

function Test-Contains([string]$Needle) {
    if ($script:Out.Contains($Needle)) { return $true }
    Write-Host "  - stdout missing: $Needle"
    Write-Host "  - output: $($script:Out.Trim())"
    return $false
}

function Test-NotContains([string]$Needle) {
    if (-not $script:Out.Contains($Needle)) { return $true }
    Write-Host "  - stdout unexpectedly contains: $Needle"
    Write-Host "  - output: $($script:Out.Trim())"
    return $false
}

function Invoke-Scenario {
    param([string]$Name, [scriptblock]$Body)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $ok = & $Body
    }
    finally {
        $ErrorActionPreference = $previous
    }
    if ($ok) { Write-Pass $Name } else { Write-Fail $Name }
}

try {
    # --- 1. compliant shape: probe first, suite second, gate last ----------
    $r = New-Root 'pass'
    New-Card -Root $r -Id 'BENCH-T-01' -Value 'node --input-type=module -e "console.log(1)"; probe=$?; node --test; tests=$?; printf "VERIFY|probe=%s|tests=%s\n" "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]'
    Invoke-Check -Root $r
    Invoke-Scenario 'compliant probe-first card passes' {
        (Test-Status 0) -and (Test-Contains 'TASKCARD|OK|BENCH-T-01') -and (Test-Contains 'cards=1|failed=0')
    }

    # --- 2. the defect this gate exists for: suite && probe ----------------
    $r = New-Root 'suite-and'
    New-Card -Root $r -Id 'BENCH-T-02' -Value 'node --test && node --input-type=module -e "console.log(1)"'
    Invoke-Check -Root $r
    Invoke-Scenario 'suite chained before the probe fails' {
        (Test-Status 1) -and (Test-Contains 'TASKCARD|FAIL|BENCH-T-02') -and (Test-Contains 'runs before the behavioral probe')
    }

    # --- 3. probe joined to the suite with a connector ---------------------
    $r = New-Root 'probe-and'
    New-Card -Root $r -Id 'BENCH-T-03' -Value 'node --input-type=module -e "console.log(1)" && node --test'
    Invoke-Check -Root $r
    Invoke-Scenario 'probe chained to the suite fails' {
        (Test-Status 1) -and (Test-Contains 'TASKCARD|FAIL|BENCH-T-03') -and (Test-Contains 'chained to the probe')
    }

    # --- 4. right halves, wrong order, separated by a semicolon -----------
    $r = New-Root 'suite-first'
    New-Card -Root $r -Id 'BENCH-T-04' -Value 'node --test; node --input-type=module -e "console.log(1)"; probe=$?; tests=$?'
    Invoke-Check -Root $r
    Invoke-Scenario 'suite first with a semicolon still fails on order' {
        (Test-Status 1) -and (Test-Contains 'TASKCARD|FAIL|BENCH-T-04') -and (Test-Contains 'runs before the behavioral probe')
    }

    # --- 5. a bare suite has nothing to order -----------------------------
    $r = New-Root 'bare'
    New-Card -Root $r -Id 'BENCH-T-05' -Value 'npm test'
    Invoke-Check -Root $r
    Invoke-Scenario 'bare suite card passes' {
        (Test-Status 0) -and (Test-Contains 'TASKCARD|OK|BENCH-T-05')
    }

    # --- 6. setup chained to a suite is not a probe boundary --------------
    $r = New-Root 'setup'
    New-Card -Root $r -Id 'BENCH-T-06' -Value 'npm ci && npm test'
    Invoke-Check -Root $r
    Invoke-Scenario 'setup joined to the suite is allowed' {
        (Test-Status 0) -and (Test-Contains 'TASKCARD|OK|BENCH-T-06')
    }

    # --- 7. no Verify command ---------------------------------------------
    $r = New-Root 'none'
    New-Card -Root $r -Id 'BENCH-T-07' -Value 'None'
    Invoke-Check -Root $r
    Invoke-Scenario 'Verify None is skipped' {
        (Test-Status 0) -and (Test-Contains 'TASKCARD|SKIP|BENCH-T-07')
    }

    # --- 8. Verify field absent entirely ----------------------------------
    $r = New-Root 'absent'
    New-Card -Root $r -Id 'BENCH-T-08' -Value '' -IncludeVerify $false
    Invoke-Check -Root $r
    Invoke-Scenario 'absent Verify field is skipped' {
        (Test-Status 0) -and (Test-Contains 'TASKCARD|SKIP|BENCH-T-08')
    }

    # --- 9. unusable root -------------------------------------------------
    Invoke-Check -Root (Join-Path $tempRoot 'does-not-exist')
    Invoke-Scenario 'missing root fails closed' {
        (Test-Status 1) -and (Test-Contains 'TASKCARD|MISSING_ROOT')
    }

    # --- 10. no cards -----------------------------------------------------
    $r = New-Root 'empty'
    Invoke-Check -Root $r
    Invoke-Scenario 'empty card directory fails closed' {
        (Test-Status 1) -and (Test-Contains 'TASKCARD|MISSING_CARDS')
    }

    # --- 11. usage error --------------------------------------------------
    Invoke-Check -Root (Join-Path $tempRoot 'pass') -Extra @('--bogus')
    Invoke-Scenario 'unknown argument is a usage error' {
        (Test-Status 2) -and (Test-Contains 'TASKCARD|USAGE')
    }

    # --- 12. the real card set --------------------------------------------
    Invoke-Check -Root $repoRoot
    Invoke-Scenario 'repository cards satisfy the convention' {
        (Test-Status 0) -and (Test-Contains 'TASKCARD|OK|BENCH-L2-01') -and
        (Test-Contains 'TASKCARD|OK|BENCH-L1-02') -and
        (Test-Contains 'TASKCARD|SKIP|BENCH-L1-01') -and
        (Test-Contains 'failed=0')
    }
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "RESULTS|passed=$script:Pass|failed=$script:Fail"
if ($script:Fail -gt 0) { exit 1 }
exit 0
