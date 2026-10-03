param(
    [Parameter(Mandatory = $true)][string]$Baseline,
    [string]$Root = "."
)

$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $Root).Path
git.exe -C $rootPath rev-parse --verify "$Baseline^{commit}" *> $null
if ($LASTEXITCODE -ne 0) { Write-Output 'INVALID|AUTHORIZATION_BASELINE|A resolvable -Baseline git ref is required'; exit 2 }
$diffLines = @(git.exe -C $rootPath diff --unified=0 $Baseline -- docs/tasks 2>&1)
if ($LASTEXITCODE -ne 0) { Write-Output 'INVALID|AUTHORIZATION_DIFF|Unable to compare docs/tasks with the declared baseline'; exit 2 }
$untrackedFiles = @(git.exe -C $rootPath ls-files --others --exclude-standard -- docs/tasks)
foreach ($untrackedFile in $untrackedFiles) {
    $diffLines += "+++ b/$untrackedFile"
    foreach ($addedLine in (Get-Content -LiteralPath (Join-Path $rootPath $untrackedFile))) { $diffLines += "+$addedLine" }
}
$errors = 0
$record = ''
foreach ($line in $diffLines) {
    if ($line -match '^\+\+\+ b/docs/tasks/(.+)$') { $record = "docs/tasks/$($Matches[1])"; continue }
    if ($line -notmatch '^\+(?!\+)' -or $line -notmatch 'Commit Evidence Entry') { continue }
    $id = [regex]::Match($line, 'AUTHZ-[A-Za-z0-9._-]+').Value
    $sourceMatch = [regex]::Match($line, 'Authorization Source:[ \t]*([^;}]+)')
    $source = if ($sourceMatch.Success) { $sourceMatch.Groups[1].Value.Trim(' ', '`') } else { '' }
    if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($source) -or $source.StartsWith('[')) {
        Write-Output "MISSING_AUTHORIZATION|$record|New Commit Evidence Entry must cite an AUTHZ checkpoint and Authorization Source"
        $errors++
        continue
    }
    $matches = @(Get-ChildItem -LiteralPath (Join-Path $rootPath 'docs/tasks') -Filter '*.md' -Recurse | Where-Object { Select-String -LiteralPath $_.FullName -SimpleMatch "<a id=`"$id`"></a>" -Quiet })
    if ($matches.Count -eq 0) {
        Write-Output "UNRESOLVED_AUTHORIZATION|$record|Checkpoint $id does not resolve in a Task Record"
        $errors++
        continue
    }
    $content = Get-Content -LiteralPath $matches[0].FullName
    $anchor = "<a id=`"$id`"></a>"
    $start = [Array]::IndexOf($content, $anchor)
    $end = $content.Count
    for ($i = $start + 1; $i -lt $content.Count; $i++) { if ($content[$i] -match '<a id=') { $end = $i; break } }
    $section = $content[($start + 1)..($end - 1)] -join "`n"
    foreach ($field in @('Declared Boundary', 'Verbatim Human Instruction', 'Instruction Source', 'Frozen Task and Milestone Scope')) {
        $fieldPattern = '(?m)^-[ \t]+\*\*' + [regex]::Escape($field) + '\*\*:[ \t]*`([^`]+)`'
        $valueMatch = [regex]::Match($section, $fieldPattern)
        if (-not $valueMatch.Success -or $valueMatch.Groups[1].Value.StartsWith('[') -or $valueMatch.Groups[1].Value -in @('N/A', 'None')) { Write-Output "MISSING_AUTHORIZATION|$record|Checkpoint $id lacks $field"; $errors++ }
    }
    $boundaryMatch = [regex]::Match($section, '(?m)^-[ \t]+\*\*Declared Boundary\*\*:[ \t]*`([^`]+)`')
    if (-not $boundaryMatch.Success -or $boundaryMatch.Groups[1].Value -cnotin @('review', 'pr', 'full')) { Write-Output "INVALID_AUTHORIZATION_BOUNDARY|$record|Checkpoint $id must declare review, pr, or full"; $errors++ }
    $taskText = Get-Content -LiteralPath (Join-Path $rootPath $record) -Raw
    if ($taskText -match '(?m)^-[ \t]+\*\*Mode\*\*:[^\r\n]*Approved Batch Mode') {
        $batchMatch = [regex]::Match($taskText, '(?m)^-[ \t]+\*\*Batch Authorization\*\*:[^\r\n]*`([^`]+)`')
        if (-not $batchMatch.Success -or -not (Test-Path -LiteralPath (Join-Path $rootPath $batchMatch.Groups[1].Value))) {
            Write-Output "MISSING_BATCH_AUTHORIZATION|$record|Approved Batch Mode link does not resolve"
            $errors++
        } else {
            $batchText = Get-Content -LiteralPath (Join-Path $rootPath $batchMatch.Groups[1].Value) -Raw
            foreach ($field in @('Declared Boundary', 'Permitted Actions', 'Milestone Scope')) {
                if ($batchText -notmatch "(?m)^[-*]?[ \t]*\*\*$([regex]::Escape($field))\*\*:[ \t]*[^\[\r\n]+") {
                    Write-Output "MISSING_BATCH_AUTHORIZATION|$record|Batch Authorization lacks $field"
                    $errors++
                }
            }
            $checkpointBoundaryMatch = [regex]::Match($section, '(?m)^-[ \t]+\*\*Declared Boundary\*\*:[ \t]*`([^`]+)`')
            $batchBoundaryMatch = [regex]::Match($batchText, '(?m)^[-*]?[ \t]*\*\*Declared Boundary\*\*:[ \t]*`([^`]+)`')
            if ($checkpointBoundaryMatch.Success -and $batchBoundaryMatch.Success -and $checkpointBoundaryMatch.Groups[1].Value -cne $batchBoundaryMatch.Groups[1].Value) {
                Write-Output "CONFLICTING_AUTHORIZATION|$record|Run boundary '$($checkpointBoundaryMatch.Groups[1].Value)' conflicts with batch boundary '$($batchBoundaryMatch.Groups[1].Value)'"
                $errors++
            }
        }
    }
}
$changedRecords = @(git.exe -C $rootPath diff --name-only $Baseline -- docs/tasks)
if ($LASTEXITCODE -ne 0) { Write-Output 'INVALID|AUTHORIZATION_DIFF|Unable to list changed Task Records'; exit 2 }
$changedRecords += $untrackedFiles
foreach ($candidate in ($changedRecords | Sort-Object -Unique)) {
    $taskPath = Join-Path $rootPath $candidate
    if (-not (Test-Path -LiteralPath $taskPath)) { continue }
    $taskText = Get-Content -LiteralPath $taskPath -Raw
    if ($taskText -notmatch '(?m)^-[ \t]+\*\*Mode\*\*:[^\r\n]*Approved Batch Mode') { continue }
    $candidateDiff = if ($untrackedFiles -contains $candidate) { Get-Content -LiteralPath $taskPath } else { @(git.exe -C $rootPath diff --unified=0 $Baseline -- $candidate) }
    if (-not ($candidateDiff | Where-Object { $_ -match '^\+[^+].*\*\*(Mode|Batch Authorization)\*\*:' })) { continue }
    $batchMatch = [regex]::Match($taskText, '(?m)^-[ \t]+\*\*Batch Authorization\*\*:[^\r\n]*`([^`]+)`')
    if (-not $batchMatch.Success -or -not (Test-Path -LiteralPath (Join-Path $rootPath $batchMatch.Groups[1].Value))) {
        Write-Output "MISSING_BATCH_AUTHORIZATION|$candidate|Approved Batch Mode link does not resolve"
        $errors++
        continue
    }
    $batchText = Get-Content -LiteralPath (Join-Path $rootPath $batchMatch.Groups[1].Value) -Raw
    foreach ($field in @('Declared Boundary', 'Permitted Actions', 'Milestone Scope')) {
        if ($batchText -notmatch "(?m)^[-*]?[ \t]*\*\*$([regex]::Escape($field))\*\*:[ \t]*[^\[\r\n]+") {
            Write-Output "MISSING_BATCH_AUTHORIZATION|$candidate|Batch Authorization lacks $field"
            $errors++
        }
    }
}
if ($errors -eq 0) { Write-Output 'VALID|AUTHORIZATION_EVIDENCE=COMPLETE'; exit 0 }
Write-Output "FAILED|AUTHORIZATION_ERRORS=$errors"
exit 1
