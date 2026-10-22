#!/usr/bin/env pwsh
# Cross-platform fixture harness for the onboarding artifact-provenance
# consistency contract (protocols/discovery-intake.md section G).
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-onboarding-provenance-fixtures.ps1
#
# Enforcement honesty: onboarding is a Markdown workflow, not an executable
# artifact generator. This harness validates the SPECIFIED classification of
# generated onboarding artifacts against the provenance contract. It does not
# execute an onboarding engine, and it cannot prove that a live model produces
# consistent artifacts.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd([char]92, [char]47)
$fixtureRoot = Join-Path $repoRoot 'scripts/tests/fixtures/onboarding-provenance'

if ($env:RUNNER_TEMP) { $tempBase = $env:RUNNER_TEMP }
elseif ($env:TMPDIR) { $tempBase = $env:TMPDIR }
else { $tempBase = [System.IO.Path]::GetTempPath() }
$tempRoot = Join-Path $tempBase ('promptkit-onboarding-provenance.' + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

$nl = [Environment]::NewLine
$pipe = [char]124
$tab = [char]9
$sectionSign = [char]167

function Fail-Harness([string]$Message) { throw ('HARNESS_FAILURE|' + $Message) }

function Test-Placeholder([string]$Value) {
    if ($null -eq $Value) { return $true }
    if ($Value -eq '') { return $true }
    return (@('-', 'none', 'None', 'NONE', 'n/a', 'N/A', 'TBD', 'not tracked', '?') -contains $Value)
}

function Test-Member([string]$List, [string]$Target) {
    if ($null -eq $List) { return $false }
    foreach ($part in ($List -split '[,;\s]+')) {
        if ($part -eq $Target) { return $true }
    }
    return $false
}

function Get-TrimmedCells([string]$Line) {
    $parts = $Line.Split($pipe)
    $cells = New-Object System.Collections.Generic.List[string]
    for ($i = 1; $i -le $parts.Count - 2; $i++) { $cells.Add($parts[$i].Trim()) }
    return ,$cells
}

function Sort-Diagnostics($Items) {
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($item in $Items) { $list.Add($item) }
    $list.Sort([System.StringComparer]::OrdinalIgnoreCase)
    return $list
}

function Get-RepoFileLines {
    $items = Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $relative = $_.FullName.Substring($repoRoot.Length).TrimStart([char]92, [char]47) -replace '\\', '/'
            -not ($relative -eq '.git' -or $relative.StartsWith('.git/'))
        } |
        Sort-Object -Property FullName
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($item in $items) {
        $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        $lines.Add($item.FullName + '|' + $hash)
    }
    return ($lines -join $nl)
}

function Get-GitStatus {
    $status = git -C $repoRoot status --porcelain=v1 --untracked-files=all
    if ($LASTEXITCODE -ne 0) { Fail-Harness 'Unable to read Git status' }
    return ($status -join $nl)
}

function Assert-Unchanged([string]$BeforeFiles, [string]$BeforeStatus, [string]$Label) {
    $afterFiles = Get-RepoFileLines
    $afterStatus = Get-GitStatus
    Set-Content -LiteralPath (Join-Path $tempRoot ($Label + '-after-files.txt')) -Value $afterFiles
    Set-Content -LiteralPath (Join-Path $tempRoot ($Label + '-after-status.txt')) -Value $afterStatus
    if ($afterFiles -cne $BeforeFiles) { Fail-Harness ('Repository file hashes changed during ' + $Label + ' validation') }
    if ($afterStatus -cne $BeforeStatus) { Fail-Harness ('Git status changed during ' + $Label + ' validation') }
}

function Invoke-AnalyseIntake([string]$Path) {
    $section = ''
    $decisions = New-Object System.Collections.Generic.List[string]
    $decStatus = @{}
    $decProv = @{}
    $defaults = New-Object System.Collections.Generic.List[string]
    $defResolves = @{}
    $assumptions = New-Object System.Collections.Generic.List[string]
    $asmStatus = @{}
    $asmLink = @{}
    $asmRisk = @{}
    $asmDest = @{}
    $obligations = New-Object System.Collections.Generic.List[string]
    $oblOwner = @{}
    $oblStatus = @{}
    $oblDest = @{}
    $meta = @{}
    $seenSections = @{}
    $rounds = 0
    $qsum = 0

    $headerSeen = @{}
    $sepSeen = @{}
    $columnCount = @{}
    $headerCells = @{}
    $registerCanonical = @{}
    $registerClean = @{}

    $out = New-Object System.Collections.Generic.List[string]

    $expectedColumns = @{
        'Intake metadata' = 2
        'Decisions' = 4
        'Accepted defaults' = 6
        'Assumption records' = 8
        'Verification obligations' = 5
        'Round log' = 3
    }
    # Expected complete header row for each register, taken from the canonical
    # baseline fixture (cases/valid-baseline). A register must match every
    # header cell in order, not merely the first cell and the column count.
    $expectedHeader = @{
        'Intake metadata' = @('Field', 'Value')
        'Decisions' = @('Decision ID', 'Status', 'Statement', 'Provenance')
        'Accepted defaults' = @('Default ID', 'Status', 'Accepted value', 'Scope', 'Resolves', 'Adjacent decisions that stay open')
        'Assumption records' = @('Assumption ID', 'Statement', 'Owner', 'Validation action', 'Status', 'Linked decision', 'Residual risk', 'Destination')
        'Verification obligations' = @('Obligation ID', 'Statement', 'Owner', 'Status', 'Destination')
        'Round log' = @('Round', 'Questions', 'Closed by')
    }

    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match '^##\s+(.*)$') {
            $section = $Matches[1].Trim()
            $seenSections[$section] = $true
            continue
        }
        if ($line -notmatch '^\|') { continue }
        if ($section -eq '') { continue }
        $cells = Get-TrimmedCells $line
        if ($cells.Count -eq 0) { continue }
        if (-not $headerSeen.ContainsKey($section)) {
            $headerSeen[$section] = $true
            $columnCount[$section] = $cells.Count
            $headerCells[$section] = @($cells)
            continue
        }
        if (-not $sepSeen.ContainsKey($section)) {
            $isSeparator = $true
            foreach ($cell in $cells) { if ($cell -notmatch '^:?-+:?$') { $isSeparator = $false; break } }
            if ($isSeparator -and $cells.Count -eq $columnCount[$section]) {
                $sepSeen[$section] = $true
                # The register is canonical only when its complete ordered
                # header row and declared width both match the contract.
                $actualHeader = (@($headerCells[$section]) -join '|')
                $expectedHeaderText = (@($expectedHeader[$section]) -join '|')
                if ($cells.Count -eq $expectedColumns[$section] -and $actualHeader -ceq $expectedHeaderText) {
                    $registerCanonical[$section] = $true
                    $registerClean[$section] = $true
                }
            }
            continue
        }
        if ($cells[0] -match '^:?-+:?$') { continue }
        if (-not ($registerCanonical.ContainsKey($section) -and $registerCanonical[$section])) { continue }
        # One documented malformed-row convention: the register name, the
        # declared and observed widths, and the row's leading identifying
        # value. A short or over-wide row is reported and skipped, never
        # truncated or padded, and the register is marked incomplete so
        # dependent checks do not cascade.
        if ($cells.Count -ne $expectedColumns[$section]) {
            $rowId = [string]$cells[0]
            if ([string]::IsNullOrWhiteSpace($rowId)) { $rowId = 'none' }
            $out.Add('ROW_WIDTH|' + $section + '|expected=' + $expectedColumns[$section] + '|actual=' + $cells.Count + '|row=' + $rowId)
            $registerClean[$section] = $false
            continue
        }
        # Width was validated above, so every parsed row indexes safely.
        switch ($section) {
            'Decisions' {
                $decisions.Add($cells[0])
                $decStatus[$cells[0]] = $cells[1].ToLowerInvariant()
                $decProv[$cells[0]] = $cells[3]
            }
            'Accepted defaults' {
                $defaults.Add($cells[0])
                $defResolves[$cells[0]] = $cells[4]
            }
            'Assumption records' {
                $assumptions.Add($cells[0])
                $asmStatus[$cells[0]] = $cells[4].ToLowerInvariant()
                $asmLink[$cells[0]] = $cells[5]
                $asmRisk[$cells[0]] = $cells[6]
                $asmDest[$cells[0]] = $cells[7]
            }
            'Verification obligations' {
                $obligations.Add($cells[0])
                $oblOwner[$cells[0]] = $cells[2]
                $oblStatus[$cells[0]] = $cells[3]
                $oblDest[$cells[0]] = $cells[4]
            }
            'Intake metadata' {
                $meta[$cells[0]] = $cells[1]
            }
            'Round log' {
                $rounds = $rounds + 1
                if ($cells[1] -match '^[0-9]+$') { $qsum = $qsum + [int]$cells[1] }
            }
        }
    }

    $usable = @{}
    foreach ($required in @('Intake metadata', 'Decisions', 'Accepted defaults', 'Assumption records', 'Verification obligations', 'Round log')) {
        if (-not $seenSections.ContainsKey($required)) {
            $out.Add('REGISTER_MISSING|' + $required)
            continue
        }
        # A register is canonical only when its complete ordered header row and
        # separator matched the contract (set during parsing).
        $ok = ($registerCanonical.ContainsKey($required) -and $registerCanonical[$required])
        if (-not $ok) { $out.Add('REGISTER_NOT_TABULAR|' + $required) }
        # Dependent (cross-register) checks are suppressed when a register is
        # non-canonical OR carried a malformed data row, so one structural
        # defect cannot cascade into misleading lifecycle or count verdicts.
        if ($ok -and $registerClean.ContainsKey($required) -and $registerClean[$required]) { $usable[$required] = $true }
    }

    if ($usable['Assumption records']) {
        foreach ($id in $assumptions) {
            $st = $asmStatus[$id]
            $lk = $asmLink[$id]
            # Blank and the shared placeholder set mean "no linked decision".
            # Every other value must use the accepted DECISION-* identifier
            # syntax; malformed syntax is reported even when the Decisions
            # register is unusable, because it is intrinsic to this row.
            if (-not (Test-Placeholder $lk)) {
                if ($lk -notmatch '^DECISION-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}$') {
                    $out.Add('ASSUMPTION_LINK_INVALID|' + $id + '|' + $lk)
                }
                elseif ($usable['Decisions']) {
                    if (-not $decStatus.ContainsKey($lk)) {
                        $out.Add('ASSUMPTION_LINK_UNRESOLVED|' + $id + '|' + $lk)
                    }
                    elseif ($decStatus[$lk] -eq 'confirmed' -and $st -notmatch '^(accepted|superseded)') {
                        $out.Add('ASSUMPTION_STILL_OPEN|' + $id + '|' + $lk)
                    }
                }
            }
            if ($null -ne $st -and $st -match '^(accepted|superseded)' -and -not (Test-Placeholder $asmRisk[$id]) -and (Test-Placeholder $asmDest[$id])) {
                $out.Add('RESIDUAL_RISK_UNTRACKED|' + $id)
            }
        }
    }

    if ($usable['Decisions'] -and $usable['Accepted defaults']) {
        foreach ($id in $decisions) {
            $match = [regex]::Match([string]$decProv[$id], 'DEFAULT-[a-z0-9-]+-[0-9]{3}')
            if ($match.Success) {
                $defaultId = $match.Value
                if (-not (Test-Member $defResolves[$defaultId] $id)) {
                    $out.Add('DEFAULT_WIDENED|' + $defaultId + '|' + $id)
                }
            }
        }
    }

    if ($usable['Intake metadata'] -and $usable['Round log']) {
        $size = ''
        if ($meta.ContainsKey('Size')) { $size = $meta['Size'].ToLowerInvariant() }
        $questionCeiling = 0
        if ($size -eq 'small') { $questionCeiling = 5 }
        elseif ($size -eq 'medium') { $questionCeiling = 8 }
        elseif ($size -eq 'large') { $questionCeiling = 12 }

        $roundsStated = $null
        $questionsStated = $null
        if ($meta.ContainsKey('Rounds used')) { $roundsStated = $meta['Rounds used'] }
        if ($meta.ContainsKey('Questions asked')) { $questionsStated = $meta['Questions asked'] }

        if ($null -ne $roundsStated -and $roundsStated -match '^[0-9]+$') {
            if ([int]$roundsStated -ne $rounds) {
                $out.Add('COUNT_CONTRADICTION|rounds|stated=' + $roundsStated + '|recorded=' + $rounds)
            }
        }
        if ($null -ne $questionsStated -and $questionsStated -match '^[0-9]+$') {
            if ([int]$questionsStated -ne $qsum) {
                $out.Add('COUNT_CONTRADICTION|questions|stated=' + $questionsStated + '|recorded=' + $qsum)
            }
            if ($questionCeiling -gt 0 -and [int]$questionsStated -gt $questionCeiling) {
                $out.Add('QUESTION_BUDGET_EXCEEDED|size=' + $size + '|ceiling=' + $questionCeiling + '|asked=' + $questionsStated)
            }
        }
    }

    if ($usable['Verification obligations']) {
        foreach ($id in $obligations) {
            if (Test-Placeholder $oblOwner[$id]) { $out.Add('OBLIGATION_UNTRACKED|' + $id + '|owner') }
            if (Test-Placeholder $oblStatus[$id]) { $out.Add('OBLIGATION_UNTRACKED|' + $id + '|status') }
            if (Test-Placeholder $oblDest[$id]) { $out.Add('OBLIGATION_UNTRACKED|' + $id + '|destination') }
            else { $out.Add('DESTCHECK|' + $id + '|' + $oblDest[$id]) }
        }
    }

    $out.Add('COUNTS|DECISIONS=' + $decisions.Count + '|DEFAULTS=' + $defaults.Count + '|ASSUMPTIONS=' + $assumptions.Count + '|OBLIGATIONS=' + $obligations.Count + '|ROUNDS=' + $rounds)
    return $out
}

function Test-DestinationResolves([string]$Destination, [string]$OutputRoot) {
    $path = $Destination
    $rest = ''
    $index = $path.IndexOf($sectionSign)
    if ($index -ge 0) {
        $rest = $path.Substring($index + 1)
        $path = $path.Substring(0, $index)
    }
    $path = $path.TrimEnd()
    if ($path -eq 'docs/STATE.md' -or $path -eq './docs/STATE.md') {
        $stateFile = Join-Path (Join-Path $OutputRoot 'docs') 'STATE.md'
        if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) { return $false }
        $content = @(Get-Content -LiteralPath $stateFile)
        foreach ($match in [regex]::Matches($rest, '[0-9]+')) {
            $heading = '^##\s+' + $match.Value + '[.]\s'
            $found = $false
            foreach ($contentLine in $content) {
                if ($contentLine -match $heading) { $found = $true; break }
            }
            if (-not $found) { return $false }
        }
        return $true
    }
    if ($path -like 'docs/tasks/*') {
        $candidate = Join-Path $OutputRoot ($path.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        return (Test-Path -LiteralPath $candidate -PathType Leaf)
    }
    return $false
}

function Invoke-ValidateCase([string]$CaseRoot) {
    $outputRoot = Join-Path $CaseRoot 'expected-output'
    $counts = 'DECISIONS=0|DEFAULTS=0|ASSUMPTIONS=0|OBLIGATIONS=0|ROUNDS=0'
    $diagnostics = New-Object System.Collections.Generic.List[string]
    $specDir = Join-Path (Join-Path $outputRoot 'docs') 'specs'
    $intakes = @()
    if (Test-Path -LiteralPath $specDir -PathType Container) {
        $intakes = @(Get-ChildItem -LiteralPath $specDir -File -Filter '*.md' | Sort-Object -Property Name)
    }
    if ($intakes.Count -ne 1) {
        $diagnostics.Add('MISSING_INTAKE_RECORD|the fixture does not contain exactly one Intake Record under expected-output/docs/specs')
        return [pscustomobject]@{ Diagnostics = @(Sort-Diagnostics $diagnostics); Summary = ('FAILED|ERRORS=1|' + $counts); ExitCode = 1 }
    }
    $stateFile = Join-Path (Join-Path $outputRoot 'docs') 'STATE.md'
    if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
        $diagnostics.Add('MISSING_STATE|the fixture has no generated docs/STATE.md')
        return [pscustomobject]@{ Diagnostics = @(Sort-Diagnostics $diagnostics); Summary = ('FAILED|ERRORS=1|' + $counts); ExitCode = 1 }
    }

    $analysis = @(Invoke-AnalyseIntake $intakes[0].FullName)
    $parsedCounts = $null
    foreach ($entry in $analysis) {
        if ($entry.StartsWith('COUNTS|')) { $parsedCounts = $entry.Substring('COUNTS|'.Length) }
    }
    if ($null -ne $parsedCounts -and $parsedCounts -ne '') { $counts = $parsedCounts }
    foreach ($entry in $analysis) {
        if ($entry.StartsWith('COUNTS|')) { continue }
        if ($entry.StartsWith('DESTCHECK|')) { continue }
        $diagnostics.Add($entry)
    }
    foreach ($entry in $analysis) {
        if (-not $entry.StartsWith('DESTCHECK|')) { continue }
        $rest = $entry.Substring('DESTCHECK|'.Length)
        $cut = $rest.IndexOf($pipe)
        $obligationId = $rest.Substring(0, $cut)
        $destination = $rest.Substring($cut + 1)
        if (-not (Test-DestinationResolves $destination $outputRoot)) {
            $diagnostics.Add('OBLIGATION_DESTINATION_MISSING|' + $obligationId + '|' + $destination)
        }
    }

    $sorted = @(Sort-Diagnostics $diagnostics)
    if ($sorted.Count -gt 0) {
        return [pscustomobject]@{ Diagnostics = $sorted; Summary = ('FAILED|ERRORS=' + $sorted.Count + '|' + $counts); ExitCode = 1 }
    }
    return [pscustomobject]@{ Diagnostics = @(); Summary = ('VALID|' + $counts); ExitCode = 0 }
}

try {
    if (-not (Test-Path -LiteralPath (Join-Path $fixtureRoot 'cases') -PathType Container)) { Fail-Harness 'Missing onboarding provenance fixture root' }
    $manifest = Join-Path $fixtureRoot 'expected/cases.tsv'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { Fail-Harness 'Missing onboarding provenance case manifest' }

    $caseCount = 0
    $manifestLines = @(Get-Content -LiteralPath $manifest)
    $declaredCases = @{}
    foreach ($manifestLine in $manifestLines) {
        if ([string]::IsNullOrWhiteSpace($manifestLine)) { continue }
        if ($manifestLine.StartsWith('#')) { continue }
        $declaredFields = $manifestLine.Split($tab)
        if ($declaredFields.Count -ge 1) { $declaredCases[$declaredFields[0]] = $true }
    }
    foreach ($caseDirectory in @(Get-ChildItem -LiteralPath (Join-Path $fixtureRoot 'cases') -Directory | Sort-Object -Property Name)) {
        if (-not $declaredCases.ContainsKey($caseDirectory.Name)) {
            Fail-Harness ('Case directory not declared in expected/cases.tsv: ' + $caseDirectory.Name)
        }
    }
    foreach ($line in $manifestLines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.StartsWith('#')) { continue }
        $fields = $line.Split($tab)
        if ($fields.Count -ne 4) { Fail-Harness ('Malformed manifest row for case ' + $fields[0] + ': expected 4 tab-separated fields') }
        $name = $fields[0]
        if ([string]::IsNullOrWhiteSpace($name)) { Fail-Harness 'Malformed manifest row: empty case name' }
        $expectedExit = 0
        if (-not [int]::TryParse($fields[1], [ref]$expectedExit)) { Fail-Harness ('Malformed manifest row for case ' + $name + ": expected exit '" + $fields[1] + "' is not numeric") }
        $expectedSummary = $fields[2]
        $expectedDiagnostics = $fields[3]
        if ([string]::IsNullOrWhiteSpace($expectedSummary)) { Fail-Harness ('Missing expected summary for case ' + $name) }
        if ([string]::IsNullOrWhiteSpace($expectedDiagnostics)) { Fail-Harness ('Missing diagnostic contract for case ' + $name) }
        $caseRoot = Join-Path (Join-Path $fixtureRoot 'cases') $name
        if (-not (Test-Path -LiteralPath $caseRoot -PathType Container)) { Fail-Harness ('Missing case root: ' + $caseRoot) }

        $expectedErrors = $null
        if ($expectedSummary -match 'ERRORS=([0-9]+)') { $expectedErrors = [int]$Matches[1] }
        if ($expectedDiagnostics -eq '-') {
            if ($null -ne $expectedErrors) { Fail-Harness ('Case ' + $name + ' claims a valid summary but lists diagnostics') }
            if ($expectedExit -ne 0) { Fail-Harness ('Case ' + $name + ' declares no diagnostics but a failing expected exit') }
        } else {
            if ($null -eq $expectedErrors) { Fail-Harness ('Case ' + $name + ' must state an ERRORS count in its expected summary') }
            $contractCount = @($expectedDiagnostics -split ';;').Count
            if ($contractCount -ne $expectedErrors) {
                Fail-Harness ('Case ' + $name + ' manifest disagreement: the summary claims ' + $expectedErrors + ' diagnostic(s), the contract lists ' + $contractCount)
            }
        }

        $beforeFiles = Get-RepoFileLines
        $beforeStatus = Get-GitStatus
        $result = Invoke-ValidateCase $caseRoot
        if ($result.ExitCode -ne $expectedExit) {
            foreach ($item in $result.Diagnostics) { [Console]::Error.WriteLine($item) }
            [Console]::Error.WriteLine($result.Summary)
            Fail-Harness ($name + ' expected exit ' + $expectedExit + ' but received ' + $result.ExitCode)
        }
        if ($result.Summary -cne $expectedSummary) {
            foreach ($item in $result.Diagnostics) { [Console]::Error.WriteLine($item) }
            [Console]::Error.WriteLine($result.Summary)
            Fail-Harness ($name + ' did not contain the exact expected summary ' + $expectedSummary)
        }
        if ($expectedDiagnostics -eq '-') {
            if (@($result.Diagnostics).Count -ne 0) { Fail-Harness 'Unexpected diagnostics in a valid case' }
        } else {
            $expectedList = New-Object System.Collections.Generic.List[string]
            foreach ($expectedLine in ($expectedDiagnostics -split ';;')) { $expectedList.Add($expectedLine) }
            $expectedList.Sort([System.StringComparer]::OrdinalIgnoreCase)
            $actualList = New-Object System.Collections.Generic.List[string]
            foreach ($item in $result.Diagnostics) { $actualList.Add($item) }
            if (($actualList -join $nl) -cne ($expectedList -join $nl)) {
                Fail-Harness 'Complete normalized diagnostic set did not match the shared contract'
            }
        }
        Assert-Unchanged $beforeFiles $beforeStatus $name
        $caseCount = $caseCount + 1
    }

    Write-Output ('Onboarding provenance PowerShell matrix cases passed: ' + $caseCount + ' isolated contracts.')
    Write-Output 'Onboarding provenance validation is deterministic, network-free, and read-only; it validates the specified classification of generated Intake Records and their obligation destinations.'
    Write-Output 'Onboarding provenance validation does not execute an onboarding engine; it cannot prove that a live model produces consistent artifacts.'
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
