<#
.SYNOPSIS
    PromptKit OS Benchmark Run Aggregator (PowerShell)
.DESCRIPTION
    Merges §5 telemetry records (as scored by scripts/measure-cpac.ps1) with a
    blind-grading TSV into per-run rows and per-arm aggregates. The arm is each
    record's `condition`; CPAC semantics come from measure-cpac itself (records
    carry their final accepted flag — set by the operator at re-extraction after
    grading — and the grading TSV's accepted column is a fail-closed cross-check:
    a mismatch exits 2 rather than being silently reconciled). The Bash twin
    reaches identical verdicts from identical inputs.

    Usage: aggregate-benchmark-runs.ps1 -Grading sheet.tsv -Records a.json,b.json
    Grading TSV (tab-separated, header optional):
      run_id <TAB> rubric_passed <TAB> rubric_total <TAB> accepted
    Output: RUN|... per record (input order) and BENCH|SUMMARY|... per arm.
    CPAC aggregates cover accepted runs only (INF is excluded by definition).
#>
[CmdletBinding()]
param (
    [string]$Grading = "",
    # Comma-separated record paths: `pwsh -File` does not split array values,
    # so the records arrive as one string and are split here.
    [string]$Records = ""
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: aggregate-benchmark-runs.ps1 -Grading <sheet.tsv> -Records 'record1.json,record2.json'"
    Write-Host "Grading TSV: run_id <TAB> rubric_passed <TAB> rubric_total <TAB> accepted"
    Write-Host "Prints RUN|... rows and BENCH|SUMMARY|... per-arm aggregate machine lines."
}

function Write-BenchError {
    param ([string]$Kind, [string]$Detail)
    [Console]::Error.WriteLine("BENCH|ERROR|$Kind|$Detail")
    exit 2
}

$recordList = @($Records -split ',' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim().Trim('"') })
if ($recordList.Count -eq 0) {
    Show-Usage
    exit 2
}
if ([string]::IsNullOrWhiteSpace($Grading) -or -not (Test-Path $Grading) -or (Get-Item $Grading).Length -eq 0) {
    Write-BenchError "UNREADABLE" $Grading
}

$gAccepted = @{}
$gPassed = @{}
$gTotal = @{}
$gLine = 0
foreach ($row in (Get-Content $Grading)) {
    $gLine++
    if ([string]::IsNullOrWhiteSpace($row)) { continue }
    $cells = $row -split "`t"
    if ($cells[0] -eq "run_id") { continue }
    if ($cells.Count -lt 4 -or $cells[1] -notmatch '^[0-9]+$' -or $cells[2] -notmatch '^[0-9]+$' -or ($cells[3] -ne "true" -and $cells[3] -ne "false")) {
        Write-BenchError "BAD_GRADING" "$gLine"
    }
    $gAccepted[$cells[0]] = $cells[3]
    $gPassed[$cells[0]] = [int]$cells[1]
    $gTotal[$cells[0]] = [int]$cells[2]
}

$measureScript = Join-Path (Split-Path -Parent (Split-Path -Parent $PSCommandPath)) "scripts\measure-cpac.ps1"
if (-not (Test-Path $measureScript)) {
    # repo layout: scripts/tests/.. is scripts/ — resolve relative to this file
    $measureScript = Join-Path (Split-Path -Parent $PSCommandPath) "measure-cpac.ps1"
}

$flat = @()
foreach ($rec in $recordList) {
    if ([string]::IsNullOrWhiteSpace($rec) -or -not (Test-Path $rec) -or (Get-Item $rec).Length -eq 0) {
        Write-BenchError "UNREADABLE" "$rec"
    }
    $out = & pwsh -NoProfile -File $measureScript -TargetPath $rec 2>$null
    $line = ($out | Where-Object { $_ -is [string] -and $_.StartsWith("CPAC|MEASURED|") } | Select-Object -First 1)
    if ($null -eq $line) {
        Write-BenchError "BAD_RECORD" "$rec"
    }
    $fields = @{}
    foreach ($part in ($line -split '\|') | Select-Object -Skip 2) {
        $kv = $part -split '=', 2
        $fields[$kv[0]] = $kv[1]
    }
    $scenario = $fields["scenario"]
    $condition = $fields["condition"]
    $model = $fields["model"]
    $cpac = $fields["cpac_usd"]
    $wall = $fields["wall_clock_seconds"]
    $loops = $fields["rework_loops"]
    $tt = [int]$fields["tokens_in"] + [int]$fields["tokens_out"] + [int]$fields["rework_tokens_in"] + [int]$fields["rework_tokens_out"]
    $acc = 0; if ($cpac -ne "INF") { $acc = 1 }
    $graded = 0
    $rubric = "-"
    if ($gAccepted.ContainsKey($scenario)) {
        $graded = 1
        $rubric = "$($gPassed[$scenario])/$($gTotal[$scenario])"
        $want = 0; if ($gAccepted[$scenario] -eq "true") { $want = 1 }
        if ($want -ne $acc) {
            Write-BenchError "ACCEPTED_MISMATCH" "$scenario"
        }
    }
    $flat += [pscustomobject]@{
        Scenario = $scenario; Arm = $condition; Model = $model; Acc = $acc
        Graded = $graded; Tokens = $tt; Wall = [double]$wall; Loops = [double]$loops
        Rubric = $rubric; Cpac = $cpac; Rec = $rec
    }
    Write-Output ("RUN|{0}|arm={1}|model={2}|accepted={3}|graded={4}|rubric={5}|tokens_total={6}|wall_clock_seconds={7}|rework_loops={8}|cpac_usd={9}" -f $scenario, $condition, $model, $acc, $graded, $rubric, $tt, $wall, $loops, $cpac)
}

function Format-Inv {
    param ([double]$Value, [string]$Format)
    return $Value.ToString($Format, [System.Globalization.CultureInfo]::InvariantCulture)
}

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$arms = $flat | ForEach-Object { $_.Arm } | Sort-Object -Unique
foreach ($arm in $arms) {
    $rows = @($flat | Where-Object { $_.Arm -eq $arm })
    $n = $rows.Count
    $accepted = @($rows | Where-Object { $_.Acc -eq 1 }).Count
    $gradedN = @($rows | Where-Object { $_.Graded -eq 1 }).Count
    $rate = if ($n -gt 0) { $accepted / $n } else { 0.0 }
    $tokensMean = ($rows | Measure-Object -Property Tokens -Average).Average
    $wallMean = ($rows | Measure-Object -Property Wall -Average).Average
    $loopsMean = ($rows | Measure-Object -Property Loops -Average).Average
    $tokensSorted = @($rows | Sort-Object -Property Tokens | ForEach-Object { [double]$_.Tokens })
    $tokensMedian = if ($n % 2 -eq 1) { $tokensSorted[[int][Math]::Floor($n / 2)] } else { ($tokensSorted[$n / 2 - 1] + $tokensSorted[$n / 2]) / 2 }
    $wallSorted = @($rows | Sort-Object -Property Wall | ForEach-Object { $_.Wall })
    $wallMedian = if ($n % 2 -eq 1) { $wallSorted[[int][Math]::Floor($n / 2)] } else { ($wallSorted[$n / 2 - 1] + $wallSorted[$n / 2]) / 2 }
    $accRows = @($rows | Where-Object { $_.Acc -eq 1 -and $_.Cpac -ne "INF" })
    if ($accRows.Count -gt 0) {
        $cpacVals = @($accRows | ForEach-Object { [double]$_.Cpac })
        $cpacMean = ($cpacVals | Measure-Object -Average).Average
        $cpacSorted = @($cpacVals | Sort-Object)
        $cpacMedian = if ($cpacVals.Count % 2 -eq 1) { $cpacSorted[[int][Math]::Floor($cpacVals.Count / 2)] } else { ($cpacSorted[$cpacVals.Count / 2 - 1] + $cpacSorted[$cpacVals.Count / 2]) / 2 }
        Write-Output ("BENCH|SUMMARY|arm={0}|n={1}|accepted={2}|accept_rate={3}|tokens_mean={4}|tokens_median={5}|wall_mean={6}|wall_median={7}|rework_mean={8}|cpac_n={9}|cpac_mean={10}|cpac_median={11}" -f `
            $arm, $n, $accepted, (Format-Inv $rate "0.00"), (Format-Inv $tokensMean "0.0"), (Format-Inv $tokensMedian "0.0"), (Format-Inv $wallMean "0.0"), (Format-Inv $wallMedian "0.0"), (Format-Inv $loopsMean "0.00"), $accRows.Count, (Format-Inv $cpacMean "0.0000"), (Format-Inv $cpacMedian "0.0000"))
    } else {
        Write-Output ("BENCH|SUMMARY|arm={0}|n={1}|accepted={2}|accept_rate={3}|tokens_mean={4}|tokens_median={5}|wall_mean={6}|wall_median={7}|rework_mean={8}|cpac_n=0|cpac_mean=N/A|cpac_median=N/A" -f `
            $arm, $n, $accepted, (Format-Inv $rate "0.00"), (Format-Inv $tokensMean "0.0"), (Format-Inv $tokensMedian "0.0"), (Format-Inv $wallMean "0.0"), (Format-Inv $wallMedian "0.0"), (Format-Inv $loopsMean "0.00"))
    }
}
exit 0
