# Cross-platform fixture harness for the onboarding host-documentation divergence
# contract (Issue #644).
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-onboard-divergence-fixtures.ps1
#
# Enforcement honesty: onboarding is a Markdown workflow, not an executable
# artifact generator. This harness validates the SPECIFIED sample output of the
# divergence contract and its integrity properties. It does not execute an
# onboarding engine, because none exists, and it cannot prove that a live model
# detects every semantic contradiction between a confirmed decision and a
# pre-existing project document.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd([char]92, [char]47)
$fixtureRoot = Join-Path $repoRoot 'scripts/tests/fixtures/onboard-divergence'
$tempBase = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } elseif ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
$tempRoot = Join-Path $tempBase ('promptkit-onboard-divergence-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

$script:precedencePattern = 'overrid(e|es|ing)|takes precedence|prevail(s|ed)?|supersed(e|es|ing)|precedence|wins over|takes priority over'
$script:hostDocPattern = 'ARCHITECTURE[.]md|ROADMAP[.]md|RUNBOOK[.]md|OPERATIONS[.]md|STYLE[.]md|STYLEGUIDE[.]md|host document|host-document|host documentation|project document|root document|root documentation'
$script:sourcePattern = 'DIVERGENCE-|DECISION-|policy:|docs/specs/'
$script:allowedPrecedence = @('host-doc-authority', 'decision-authority', 'unresolved')
$script:expectedColumns = 8
$script:fieldNames = @('Divergence ID', 'Document', 'Line', 'Decision ID', 'Precedence', 'Designated By', 'Owner', 'Next Action')

function Fail-Harness { param([string]$Message); throw "HARNESS_FAILURE|$Message" }

function Get-RelativePath { param([string]$Root, [string]$Path); return ($Path.Substring($Root.Length).TrimStart([char]92, [char]47) -replace '\\', '/') }

function Get-FileText { param([string]$Path); if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }; $raw = Get-Content -LiteralPath $Path -Raw; if ($null -eq $raw) { return '' }; return $raw }

function Get-FileSnapshot {
    return @(Get-ChildItem -LiteralPath $repoRoot -File -Recurse -Force | ForEach-Object {
        $relative = Get-RelativePath $repoRoot $_.FullName
        if ($relative.StartsWith('.git/')) { return }
        "$relative|$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)"
    } | Sort-Object)
}

function Get-StatusSnapshot {
    $status = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all 2>&1)
    if ($LASTEXITCODE -ne 0) { Fail-Harness 'Unable to read Git status' }
    return @($status | ForEach-Object { $_.ToString() })
}

function Assert-Unchanged { param([string[]]$BeforeFiles, [string[]]$BeforeStatus, [string]$Label)
    $afterFiles = @(Get-FileSnapshot)
    $afterStatus = @(Get-StatusSnapshot)
    if (($BeforeFiles -join "`n") -ne ($afterFiles -join "`n")) { Fail-Harness "Repository file hashes changed during $Label validation" }
    if (($BeforeStatus -join "`n") -ne ($afterStatus -join "`n")) { Fail-Harness "Git status changed during $Label validation" }
}

function Assert-Diagnostics { param([string[]]$Lines, [string]$Expected, [string]$Name)
    $actual = @($Lines | Where-Object { $_ -notmatch '^(VALID|FAILED)\|' } | ForEach-Object { $_.ToString() } | Sort-Object)
    if ($Expected -eq '-') {
        if ($actual.Count -ne 0) { Fail-Harness "$Name produced unexpected diagnostics" }
        return
    }
    $expectedLines = @($Expected -split ';;' | Sort-Object)
    if (($actual -join "`n") -ne ($expectedLines -join "`n")) { Fail-Harness "$Name complete normalized diagnostic set did not match the shared contract" }
}

function Split-RowCells { param([string]$Row)
    $text = $Row.Trim()
    if ($text.StartsWith('|')) { $text = $text.Substring(1) }
    if ($text.EndsWith('|')) { $text = $text.Substring(0, $text.Length - 1) }
    return @($text -split '\|' | ForEach-Object { $_.Trim() })
}

function Get-SectionBody { param([string]$Path, [string]$Heading)
    $result = New-Object System.Collections.Generic.List[string]
    $inside = $false
    foreach ($line in @(Get-Content -LiteralPath $Path)) {
        if (-not $inside) {
            if ([regex]::IsMatch($line, '^#+\s+' + [regex]::Escape($Heading) + '\s*$')) { $inside = $true }
            continue
        }
        if ([regex]::IsMatch($line, '^#\s')) { break }
        $result.Add($line)
    }
    return @($result)
}

function Get-ArtifactDiagnostics { param([string]$Path, [string]$Relative)
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($line in @(Get-Content -LiteralPath $Path)) {
        if ([regex]::IsMatch($line, $script:precedencePattern) -and [regex]::IsMatch($line, $script:hostDocPattern) -and -not [regex]::IsMatch($line, $script:sourcePattern)) {
            $found.Add("UNTRACEABLE_PRECEDENCE_CLAIM|$Relative|$line")
        }
    }
    return @($found)
}

function Test-DivergenceRow { param([string]$Row, [int]$RowIndex, [string]$ProjectRoot, [string]$Profile, [string[]]$IntakeLines)
    $diagnostics = New-Object System.Collections.Generic.List[string]
    $cells = @(Split-RowCells $Row)
    if ($cells.Count -ne $script:expectedColumns) {
        $diagnostics.Add("ROW_COLUMN_COUNT|row $RowIndex has $($cells.Count) columns, expected $($script:expectedColumns)")
        return @($diagnostics)
    }
    for ($i = 0; $i -lt $script:expectedColumns; $i++) {
        if ([string]::IsNullOrEmpty($cells[$i])) { $diagnostics.Add("EMPTY_FIELD|row $RowIndex field $($script:fieldNames[$i]) is empty") }
    }
    $divergenceId = $cells[0]
    $document = $cells[1]
    $line = $cells[2]
    $decisionId = $cells[3]
    $precedence = $cells[4]
    $designatedBy = $cells[5]
    if (-not [regex]::IsMatch($divergenceId, '^DIVERGENCE-[a-z0-9-]+-[0-9]{3}$')) { $diagnostics.Add("INVALID_DIVERGENCE_ID|row $RowIndex has an invalid Divergence ID '$divergenceId'") }
    if (-not [regex]::IsMatch($decisionId, '^DECISION-[a-z0-9-]+-[0-9]{3}$')) { $diagnostics.Add("INVALID_DECISION_ID|row $RowIndex has an invalid Decision ID '$decisionId'") }
    $docPath = Join-Path $ProjectRoot $document
    if (-not (Test-Path -LiteralPath $docPath -PathType Leaf)) {
        $diagnostics.Add("DOCUMENT_NOT_FOUND|row $RowIndex references '$document', which does not exist in the project")
    } elseif (-not [regex]::IsMatch($line, '^[0-9]+$')) {
        $diagnostics.Add("LINE_INVALID|row $RowIndex line '$line' is not a positive integer")
    } else {
        $docLines = @(Get-Content -LiteralPath $docPath)
        $total = $docLines.Count
        $lineNumber = [int]$line
        if ($lineNumber -lt 1 -or $lineNumber -gt $total) {
            $diagnostics.Add("LINE_OUT_OF_RANGE|row $RowIndex line $lineNumber is outside '$document' (1-$total)")
        } elseif ([string]::IsNullOrEmpty($docLines[$lineNumber - 1])) {
            $diagnostics.Add("LINE_BLANK|row $RowIndex line $lineNumber of '$document' is blank")
        }
    }
    $confirmed = $false
    foreach ($intakeLine in $IntakeLines) {
        if ($intakeLine.Contains($decisionId) -and $intakeLine.ToLower().Contains('confirmed')) { $confirmed = $true; break }
    }
    if (-not $confirmed) { $diagnostics.Add("DECISION_NOT_CONFIRMED|row $RowIndex Decision ID '$decisionId' has no confirmed decision in the Intake Record") }
    if (-not ($script:allowedPrecedence -ccontains $precedence)) { $diagnostics.Add("PRECEDENCE_NOT_IN_ENUM|row $RowIndex precedence '$precedence' is outside the allowed set") }
    if ($precedence -ceq 'unresolved') {
        if ($designatedBy -cne 'not designated') { $diagnostics.Add("DESIGNATION_WITHOUT_PRECEDENCE|row $RowIndex names a designator while the precedence stays 'unresolved'") }
    } else {
        if (($designatedBy -ceq 'not designated') -or (-not [regex]::IsMatch($designatedBy, '[0-9]{4}-[0-9]{2}-[0-9]{2}')) -or (-not $designatedBy.Contains('docs/specs/'))) {
            $diagnostics.Add("MISSING_HUMAN_DESIGNATION|row $RowIndex precedence $precedence has no explicit human designation (approver, date, record path)")
        }
    }
    if (Test-Path -LiteralPath $Profile -PathType Leaf) {
        if (-not (Get-FileText $Profile).Contains($divergenceId)) { $diagnostics.Add("PROFILE_POINTER_MISSING|the generated PROMPTKIT.md does not reference the divergence row '$divergenceId'") }
    }
    return @($diagnostics)
}

function Invoke-DivergenceValidation { param([string]$CaseRoot, [int]$ExpectedRows)
    $projectRoot = Join-Path $CaseRoot 'project'
    $outputRoot = Join-Path $CaseRoot 'expected-output'
    $diagnostics = New-Object System.Collections.Generic.List[string]
    $errors = 0
    $rows = 0
    $hostUnchanged = 1

    $intake = ''
    $intakeCount = 0
    $specDir = Join-Path $outputRoot 'docs/specs'
    if (Test-Path -LiteralPath $specDir) {
        foreach ($candidate in @(Get-ChildItem -LiteralPath $specDir -File -Filter '*.md' | Sort-Object FullName)) {
            $intakeCount++
            if ($intakeCount -eq 1) { $intake = $candidate.FullName }
        }
    }
    if ($intakeCount -eq 0) {
        $diagnostics.Add('MISSING_INTAKE_RECORD|the fixture has no Intake Record under expected-output/docs/specs')
        $errors++
    } elseif ($intakeCount -gt 1) {
        $diagnostics.Add('MULTIPLE_INTAKE_RECORDS|the fixture has more than one Intake Record under expected-output/docs/specs')
        $errors++
    }

    $profile = Join-Path $outputRoot 'PROMPTKIT.md'
    $state = Join-Path $outputRoot 'docs/STATE.md'
    if (-not (Test-Path -LiteralPath $profile -PathType Leaf)) {
        $diagnostics.Add('MISSING_PROFILE|the fixture has no generated PROMPTKIT.md')
        $errors++
    }
    if (-not (Test-Path -LiteralPath $state -PathType Leaf)) {
        $diagnostics.Add('MISSING_STATE|the fixture has no generated docs/STATE.md')
        $errors++
    } elseif ((Get-FileText $state).Contains('DIVERGENCE-')) {
        $diagnostics.Add('STATE_DIVERGENCE_ROW|the generated docs/STATE.md references a divergence row instead of the Intake Record')
        $errors++
    }

    if ($intake) {
        $sectionBody = @(Get-SectionBody $intake 'Host Documentation Divergence')
        if (@($sectionBody | Where-Object { $_.Contains('Divergence ID') }).Count -eq 0) {
            $diagnostics.Add('MISSING_DIVERGENCE_TABLE|the Intake Record has no Host Documentation Divergence table')
            $errors++
        }
        $rowLines = @($sectionBody | Where-Object { $_ -match '^\|' } | Where-Object { $_ -notmatch '^\|\s*[-:][-:|:\s]*$' } | Where-Object { -not $_.Contains('Divergence ID') })
        $rows = $rowLines.Count
        if ($rows -ne $ExpectedRows) {
            $diagnostics.Add("ROW_COUNT_MISMATCH|expected $ExpectedRows divergence row(s), found $rows")
            $errors++
        }
        $intakeLines = @(Get-Content -LiteralPath $intake)
        $rowIndex = 0
        foreach ($rowLine in $rowLines) {
            $rowIndex++
            foreach ($diag in @(Test-DivergenceRow $rowLine $rowIndex $projectRoot $profile $intakeLines)) {
                $diagnostics.Add($diag)
                $errors++
            }
        }
        $recordName = Split-Path -Leaf $intake
        if ((Test-Path -LiteralPath $profile -PathType Leaf) -and -not (Get-FileText $profile).Contains($recordName)) {
            $diagnostics.Add("PROFILE_POINTER_MISSING|the generated PROMPTKIT.md does not reference the Intake Record '$recordName'")
            $errors++
        }
    }

    foreach ($artifact in @(Get-ChildItem -LiteralPath $outputRoot -File -Recurse -Force | Where-Object { $_.Extension -eq '.md' } | Sort-Object FullName)) {
        $relative = Get-RelativePath $outputRoot $artifact.FullName
        if ($relative.Contains('docs/specs/')) { continue }
        foreach ($diag in @(Get-ArtifactDiagnostics $artifact.FullName $relative)) {
            $diagnostics.Add($diag)
            $errors++
        }
    }

    $hostBefore = @{}
    foreach ($hostFile in @(Get-ChildItem -LiteralPath $projectRoot -File -Recurse -Force | Sort-Object FullName)) {
        $rel = Get-RelativePath $projectRoot $hostFile.FullName
        $hostBefore[$rel] = (Get-FileHash -LiteralPath $hostFile.FullName -Algorithm SHA256).Hash
    }
    $writeFiles = @(Get-ChildItem -LiteralPath $outputRoot -File -Recurse -Force | Sort-Object FullName)
    foreach ($writeFile in $writeFiles) {
        $rel = Get-RelativePath $outputRoot $writeFile.FullName
        if (Test-Path -LiteralPath (Join-Path $projectRoot $rel) -PathType Leaf) {
            $diagnostics.Add("HOST_DOCUMENT_IN_WRITE_SET|the onboarding write set contains the pre-existing project document '$rel'")
            $errors++
        }
    }

    $sim = Join-Path $tempRoot 'simulated-project'
    if (Test-Path -LiteralPath $sim) { Remove-Item -LiteralPath $sim -Recurse -Force }
    New-Item -ItemType Directory -Path $sim -Force | Out-Null
    foreach ($hostFile in @(Get-ChildItem -LiteralPath $projectRoot -File -Recurse -Force)) {
        $rel = Get-RelativePath $projectRoot $hostFile.FullName
        $dest = Join-Path $sim $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
        Copy-Item -LiteralPath $hostFile.FullName -Destination $dest -Force
    }
    foreach ($writeFile in $writeFiles) {
        $rel = Get-RelativePath $outputRoot $writeFile.FullName
        $dest = Join-Path $sim $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
        Copy-Item -LiteralPath $writeFile.FullName -Destination $dest -Force
    }
    foreach ($rel in @($hostBefore.Keys | Sort-Object)) {
        $simPath = Join-Path $sim $rel
        if (-not (Test-Path -LiteralPath $simPath -PathType Leaf)) {
            $diagnostics.Add("HOST_DOCUMENT_MUTATED|the onboarding write removed the pre-existing project document '$rel'")
            $errors++
            $hostUnchanged = 0
            continue
        }
        $afterHash = (Get-FileHash -LiteralPath $simPath -Algorithm SHA256).Hash
        if ($afterHash -ne $hostBefore[$rel]) {
            $diagnostics.Add("HOST_DOCUMENT_MUTATED|the onboarding write changed the pre-existing project document '$rel'")
            $errors++
            $hostUnchanged = 0
        }
    }

    if ($errors -eq 0) {
        $diagnostics.Add("VALID|DIVERGENCES=$rows|HOST_DOC_UNCHANGED=$hostUnchanged")
        return @{ ExitCode = 0; Lines = @($diagnostics) }
    }
    $diagnostics.Add("FAILED|ERRORS=$errors|DIVERGENCES=$rows|HOST_DOC_UNCHANGED=$hostUnchanged")
    return @{ ExitCode = 1; Lines = @($diagnostics) }
}

try {
    foreach ($required in @((Join-Path $fixtureRoot 'cases'), (Join-Path $fixtureRoot 'expected/cases.tsv'))) {
        if (-not (Test-Path -LiteralPath $required)) { Fail-Harness "Missing harness input: $required" }
    }
    $caseCount = 0
    foreach ($line in @(Get-Content -LiteralPath (Join-Path $fixtureRoot 'expected/cases.tsv'))) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
        $parts = $line -split "`t", 4
        if ($parts.Count -ne 4) { Fail-Harness "Invalid case manifest row: $line" }
        $name = $parts[0]
        $expectedExit = [int]$parts[1]
        $expectedSummary = $parts[2]
        $expectedDiagnostics = $parts[3]
        if ([string]::IsNullOrWhiteSpace($expectedDiagnostics)) { Fail-Harness "Missing diagnostic contract for case $name" }
        $caseRoot = Join-Path $fixtureRoot "cases/$name"
        if (-not (Test-Path -LiteralPath $caseRoot)) { Fail-Harness "Missing case root: $caseRoot" }
        $rowMatch = [regex]::Match($expectedSummary, 'DIVERGENCES=(\d+)')
        if (-not $rowMatch.Success) { Fail-Harness "Missing expected divergence count for case $name" }
        $expectedRows = [int]$rowMatch.Groups[1].Value
        $beforeFiles = @(Get-FileSnapshot)
        $beforeStatus = @(Get-StatusSnapshot)
        $result = Invoke-DivergenceValidation $caseRoot $expectedRows
        $text = ($result.Lines -join "`n")
        if ($result.ExitCode -ne $expectedExit) { Write-Output $text; Fail-Harness "$name expected exit $expectedExit but received $($result.ExitCode)" }
        if (-not ($result.Lines | Where-Object { $_ -ceq $expectedSummary })) { Write-Output $text; Fail-Harness "$name did not contain the exact expected summary $expectedSummary" }
        Assert-Diagnostics $result.Lines $expectedDiagnostics $name
        Assert-Unchanged $beforeFiles $beforeStatus $name
        $caseCount++
    }
    Write-Output "Onboarding divergence PowerShell matrix cases passed: $caseCount isolated contracts."
    Write-Output 'Onboarding divergence validation is deterministic, network-free, and read-only; it validates the specified sample output, the exact divergence-row count, and the host-document integrity property.'
    Write-Output 'Onboarding divergence validation does not execute an onboarding engine; it cannot prove that a live model detects every semantic contradiction.'
}
finally { if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force } }

