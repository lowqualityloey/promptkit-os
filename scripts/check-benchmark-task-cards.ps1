# Benchmark task-card lint: a card's Verify command must run its behavioral
# probe BEFORE the test suite, and must not chain the two halves with && / ||.
# Usage: scripts\check-benchmark-task-cards.ps1 [-Root PATH]
#
# Why: `<suite> && <probe>` makes the probe conditional on the suite. A red
# suite then short-circuits it, B<nnn>.verify.txt carries only test output, and
# every rubric item that depends on behavior becomes ungradeable while
# verify_exit reports the suite's opinion alone. The reverse shape is just as
# bad: a green suite hides a red probe, and the probe's failure arrives as a
# bare exit status with no explanation. The ordering is stated in
# benchmarks/tasks/TEMPLATE-task.md and benchmarks/README.md section 5.
#
# Scope: every benchmarks/tasks/TASK-*.md card. TEMPLATE-task.md is not a card.
# A card with no Verify field, or `Verify: None`, is skipped; a card whose
# Verify is a bare suite has nothing to order and passes. Probe and suite are
# recognized from the documented marker lists below - a probe spelled some
# other way is reviewed by hand rather than guessed, so this gate cannot claim
# more than it checks.
#
# Output: one `TASKCARD|OK|`, `TASKCARD|SKIP|`, or `TASKCARD|FAIL|` line per
# card, then `TASKCARD|SUMMARY|cards=N|failed=M`. Exit 0 when no card fails,
# 1 on a finding or an unusable root, 2 on a usage error.

$Root = "."
$i = 0
while ($i -lt $args.Count) {
    $a = [string]$args[$i]
    if ($a -eq '-h' -or $a -eq '--help') {
        Write-Host "Usage: scripts/check-benchmark-task-cards.ps1 [-Root PATH]"
        exit 0
    }
    elseif ($a -eq '--root' -or $a -eq '-Root') {
        if ($i + 1 -ge $args.Count) {
            Write-Host "TASKCARD|USAGE|$a requires a path"
            exit 2
        }
        $Root = [string]$args[$i + 1]
        $i += 2
    }
    elseif ($a -like '--root=*') {
        $Root = $a.Substring(7)
        $i += 1
    }
    elseif ($a -like '-Root=*') {
        $Root = $a.Substring(6)
        $i += 1
    }
    else {
        Write-Host "TASKCARD|USAGE|Unknown argument: $a"
        exit 2
    }
}

$tasksDir = Join-Path $Root 'benchmarks/tasks'
if (-not (Test-Path -LiteralPath $tasksDir -PathType Container)) {
    Write-Host "TASKCARD|MISSING_ROOT|no benchmarks/tasks directory under '$Root'|Pass -Root at the repository root"
    exit 1
}

# The test suite: an invocation that runs the task's own tests.
$suiteMarkers = @(
    'node --test',
    'npm test',
    'npm run test',
    'pnpm test',
    'yarn test',
    'bun test',
    'pytest',
    'go test',
    'cargo test',
    'dotnet test',
    'mvn test',
    'gradle test',
    'rspec',
    'mix test',
    'swift test',
    'phpunit',
    'make test',
    'ctest'
)
# The behavioral probe: an inline check run against the artifact.
$probeMarkers = @(
    'node --input-type=module',
    'node -e',
    'node --eval',
    'python -c',
    'python3 -c'
)

function Get-CardField {
    param([string]$Path, [string]$Label)
    # Get-CardField <file> <label>: the single-line field value, backticks
    # stripped. Same semantics as the driver's parse_field.
    $prefix = "- **$Label**: "
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        if ($line.StartsWith($prefix, [System.StringComparison]::Ordinal)) {
            $value = $line.Substring($prefix.Length).TrimEnd([char]13)
            if ($value.StartsWith('`')) { $value = $value.Substring(1) }
            if ($value.EndsWith('`')) { $value = $value.Substring(0, $value.Length - 1) }
            return $value
        }
    }
    return ""
}

function Get-FirstMarker {
    param([string]$Haystack, [string[]]$Markers)
    # Index of the earliest marker, or -1. Marker is the matched text.
    $best = -1
    $bestMarker = ""
    foreach ($m in $Markers) {
        $idx = $Haystack.IndexOf($m, [System.StringComparison]::Ordinal)
        if ($idx -lt 0) { continue }
        if ($best -lt 0 -or $idx -lt $best) {
            $best = $idx
            $bestMarker = $m
        }
    }
    return @{ Index = $best; Marker = $bestMarker }
}

$cards = 0
$failed = 0
foreach ($card in @(Get-ChildItem -LiteralPath $tasksDir -File -Filter 'TASK-*.md' | Sort-Object Name)) {
    $cards += 1
    $id = Get-CardField -Path $card.FullName -Label 'Task ID'
    if ([string]::IsNullOrEmpty($id)) { $id = [System.IO.Path]::GetFileNameWithoutExtension($card.Name) }
    $verify = Get-CardField -Path $card.FullName -Label 'Verify'
    if ([string]::IsNullOrEmpty($verify) -or $verify -eq 'None') {
        Write-Host "TASKCARD|SKIP|$id|no Verify command"
        continue
    }

    $reasons = New-Object System.Collections.ArrayList
    $suite = Get-FirstMarker -Haystack $verify -Markers $suiteMarkers
    $probe = Get-FirstMarker -Haystack $verify -Markers $probeMarkers
    $suiteIdx = $suite.Index
    $suiteMarker = $suite.Marker
    $probeIdx = $probe.Index
    $probeMarker = $probe.Marker

    if ($suiteIdx -ge 0 -and $probeIdx -ge 0 -and $suiteIdx -lt $probeIdx) {
        [void]$reasons.Add("the test suite ($suiteMarker) runs before the behavioral probe ($probeMarker)")
    }

    if ($suiteIdx -ge 0) {
        $before = $verify.Substring(0, $suiteIdx)
        $after = $verify.Substring($suiteIdx + $suiteMarker.Length)
        # Probe earlier in the command: the suite must not be short-circuited
        # onto it.
        if ($probeIdx -ge 0 -and $probeIdx -lt $suiteIdx) {
            $before = $before.TrimEnd()
            if ($before.EndsWith('&&') -or $before.EndsWith('||')) {
                [void]$reasons.Add("the test suite is chained to the probe with a short-circuit connector")
            }
        }
        # Suite earlier in the command: a connector here is what makes the
        # probe conditional, i.e. the defect this gate exists for.
        if ($probeIdx -ge 0 -and $suiteIdx -lt $probeIdx) {
            $after = $after.TrimStart()
            if ($after.StartsWith('&&') -or $after.StartsWith('||')) {
                [void]$reasons.Add("the test suite is chained to the probe with a short-circuit connector")
            }
        }
    }

    if ($reasons.Count -eq 0) {
        Write-Host "TASKCARD|OK|$id"
        continue
    }
    $failed += 1
    Write-Host ("TASKCARD|FAIL|{0}|{1}" -f $id, ($reasons -join '; '))
}

if ($cards -eq 0) {
    Write-Host "TASKCARD|MISSING_CARDS|no benchmarks/tasks/TASK-*.md cards under '$Root'|Pass -Root at the repository root"
    exit 1
}

Write-Host "TASKCARD|SUMMARY|cards=$cards|failed=$failed"
if ($failed -gt 0) {
    Write-Host "TASKCARD|REMEDIATION|Run the behavioral probe first, run the test suite second with ';' between them, print VERIFY|probe=<n>|tests=<n>, and exit non-zero if either failed (benchmarks/tasks/TEMPLATE-task.md)"
    exit 1
}
exit 0
