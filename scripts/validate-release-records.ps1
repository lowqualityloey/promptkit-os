# Read-only PromptKit OS release-record consistency validator.
# Usage: .\scripts\validate-release-records.ps1 [-Root PATH] [-Strict]

[CmdletBinding()]
param(
    [string]$Root = ".",
    [switch]$Strict
)

$ErrorCount = 0
$RecordCount = 0
$Diagnostics = [System.Collections.Generic.List[string]]::new()
$SeenDiagnostics = [System.Collections.Generic.HashSet[string]]::new()
$Records = [System.Collections.Generic.List[object]]::new()

function Add-Diagnostic {
    param(
        [string]$Category,
        [string]$RecordId,
        [string]$Path,
        [string]$Message,
        [string]$Remediation
    )

    $safeMessage = ($Message -replace '[\r\n|]', ' ').Trim()
    $safeRemediation = ($Remediation -replace '[\r\n|]', ' ').Trim()
    $entry = "$Category|$RecordId|$Path|$safeMessage|$safeRemediation"
    # A finding is identified by its complete tuple. Require-Labels and
    # Require-Value both assert the presence of the same label, so an absent
    # field was previously reported twice and the summary error count was
    # inflated. Distinct findings still differ in at least one tuple element.
    if (-not $script:SeenDiagnostics.Add($entry)) { return }
    [void]$Diagnostics.Add($entry)
    $script:ErrorCount++
}

try {
    $RootPath = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path
    $RootPath = [System.IO.Path]::GetFullPath($RootPath)
}
catch {
    Write-Output "INPUT_ERROR|REPOSITORY|.|Repository root does not exist|Provide a valid -Root path"
    exit 1
}

function Get-RelativePath {
    param([string]$FilePath)

    $relative = [System.IO.Path]::GetRelativePath($RootPath, $FilePath)
    if ($relative -eq '.') { return '.' }
    return $relative.Replace('\', '/')
}

function Unwrap-Value {
    param([AllowEmptyString()][string]$Value)

    if ($null -eq $Value) { return '' }
    $trimmed = $Value.Trim()
    if ($trimmed.Length -ge 2 -and $trimmed[0] -eq [char]96 -and $trimmed[$trimmed.Length - 1] -eq [char]96) {
        return $trimmed.Substring(1, $trimmed.Length - 2).Trim()
    }
    return $trimmed
}

function Test-Placeholder {
    param([AllowEmptyString()][string]$Value)

    $normalized = Unwrap-Value $Value
    if ([string]::IsNullOrWhiteSpace($normalized)) { return $true }
    switch -Regex ($normalized) {
        '^(?i:N/A|None|Not applicable|Pending|Not approved)$' { return $true }
        '^\[.*\]$' { return $true }
        default { return $false }
    }
}

function Test-Usable {
    param([AllowEmptyString()][string]$Value)
    return -not (Test-Placeholder $Value)
}

function Get-ParsedRecord {
    param([string]$FilePath)

    $fields = @{}
    $duplicates = @{}
    foreach ($line in @(Get-Content -LiteralPath $FilePath -ErrorAction Stop)) {
        $match = [regex]::Match($line, '^- \*\*(?<label>[^*]+)\*\*:\s*(?<value>.*)$')
        if (-not $match.Success) { continue }

        $label = $match.Groups['label'].Value.Trim()
        $value = $match.Groups['value'].Value.Trim()
        if ($fields.ContainsKey($label)) {
            if (-not $duplicates.ContainsKey($label)) { $duplicates[$label] = 1 }
            $duplicates[$label]++
            continue
        }
        $fields[$label] = $value
    }

    $recordType = if ($fields.ContainsKey('Record Type')) { Unwrap-Value $fields['Record Type'] } else { '' }
    $evaluationId = if ($fields.ContainsKey('Evaluation ID')) { Unwrap-Value $fields['Evaluation ID'] } else { 'UNKNOWN' }
    if (Test-Placeholder $evaluationId) { $evaluationId = 'UNKNOWN' }

    $canonicalType = switch ($recordType.ToLowerInvariant()) {
        'release evaluation' { 'Release Evaluation'; break }
        'semver candidate record' { 'SemVer Candidate Record'; break }
        'qa review record' { 'QA Review Record'; break }
        'qa/reviewer review record' { 'QA Review Record'; break }
        'approved release record' { 'Approved Release Record'; break }
        'release notes record' { 'Release Notes Record'; break }
        default { '' }
    }

    return [pscustomobject]@{
        Path = $FilePath
        RelativePath = Get-RelativePath $FilePath
        Fields = $fields
        Duplicates = $duplicates
        RecordType = $recordType
        CanonicalType = $canonicalType
        EvaluationId = $evaluationId
    }
}

function Get-FieldValue {
    param([object]$Record, [string]$Label)
    if ($Record.Fields.ContainsKey($Label)) { return Unwrap-Value $Record.Fields[$Label] }
    return ''
}

function Test-Field {
    param([object]$Record, [string]$Label)
    return $Record.Fields.ContainsKey($Label)
}

function Require-Label {
    param(
        [object]$Record,
        [string]$Label,
        [string]$Category = 'MISSING_FIELD'
    )

    if (-not (Test-Field $Record $Label)) {
        Add-Diagnostic $Category $Record.EvaluationId $Record.RelativePath "Missing field: $Label" 'Add the labeled field to the canonical record'
        return $false
    }
    return $true
}

function Require-Value {
    param(
        [object]$Record,
        [string]$Label,
        [string]$Category = 'MISSING_FIELD',
        [string]$Remediation = 'Provide a non-placeholder value for the labeled field'
    )

    if (-not (Require-Label $Record $Label $Category)) { return $false }
    if (-not (Test-Usable (Get-FieldValue $Record $Label))) {
        Add-Diagnostic $Category $Record.EvaluationId $Record.RelativePath "Missing usable value: $Label" $Remediation
        return $false
    }
    return $true
}

function Require-Labels {
    param([object]$Record, [string[]]$Labels)
    foreach ($label in $Labels) { [void](Require-Label $Record $label) }
}

function Get-FirstFieldValue {
    param([object]$Record, [string[]]$Labels)
    foreach ($label in $Labels) {
        if (Test-Field $Record $label) { return Get-FieldValue $Record $label }
    }
    return ''
}

function Split-References {
    param([AllowEmptyString()][string]$Value)

    $clean = Unwrap-Value $Value
    $clean = $clean -replace '[\[\](){}]', ' '
    $parts = @($clean -split '[,\s/]+' | ForEach-Object { Unwrap-Value $_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return $parts
}

function Get-SemVer {
    param([AllowEmptyString()][string]$Value)

    $normalized = (Unwrap-Value $Value) -replace '^v', ''
    $match = [regex]::Match($normalized, '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$')
    if (-not $match.Success) { return $null }
    return [pscustomobject]@{
        Text = $normalized
        Major = [int64]$match.Groups[1].Value
        Minor = [int64]$match.Groups[2].Value
        Patch = [int64]$match.Groups[3].Value
    }
}

function Compare-SemVerCore {
    param([object]$Left, [object]$Right)

    foreach ($property in @('Major', 'Minor', 'Patch')) {
        if ($Left.$property -gt $Right.$property) { return 1 }
        if ($Left.$property -lt $Right.$property) { return -1 }
    }
    return 0
}

function Test-Pass {
    param([AllowEmptyString()][string]$Value)
    return (Unwrap-Value $Value).ToLowerInvariant() -eq 'pass'
}

function Validate-BaseRecord {
    param([object]$Record)

    foreach ($label in @($Record.Duplicates.Keys)) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Duplicate field: $label" 'Keep one canonical field label per record'
    }

    [void](Require-Label $Record 'Record Type')
    [void](Require-Value $Record 'Evaluation ID' 'INVALID_ID' 'Provide one stable Evaluation ID shared by linked records')
}

function Validate-EvaluationRecord {
    param([object]$Record)

    Require-Labels $Record @(
        'Repository Scope', 'Evaluation Owner / Role', 'QA/Reviewer', 'Release Coordinator',
        'Created', 'Evaluation Status', 'Consumer Repository Applicability', 'Evaluation Objective',
        'Latest Approved Release Record', 'Version Source of Truth', 'Prior Approved Release Version',
        'Prior Approved Release Commit', 'First Release', 'Release Range Start', 'Release Range End',
        'Release Candidate Commit', 'Candidate-Inclusive Membership Result', 'Range Selection Rationale',
        'Ordered Range Commit References', 'Effective Change Set Summary', 'Empty Eligible Range',
        'Empty-Range Decision', 'Normalization Blockers'
    )

    foreach ($label in @('Repository Scope', 'Evaluation Owner / Role', 'QA/Reviewer', 'Created', 'Evaluation Status', 'Evaluation Objective', 'Release Range Start', 'Release Range End', 'Release Candidate Commit', 'Candidate-Inclusive Membership Result', 'Range Selection Rationale', 'Ordered Range Commit References', 'Effective Change Set Summary', 'Empty Eligible Range')) {
        [void](Require-Value $Record $label)
    }

    $scope = Get-FieldValue $Record 'Repository Scope'
    if ($scope -notin @('Better-PromptKit only', 'PromptKit OS only')) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Repository Scope must be PromptKit OS only (or Better-PromptKit only for legacy records): $scope" 'Limit release-record validation to PromptKit OS records'
    }

    $status = (Get-FieldValue $Record 'Evaluation Status').ToLowerInvariant()
    if ($status -notin @('preliminary', 'blocked', 'deferred', 'approved')) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Unsupported Evaluation Status: $status" 'Use preliminary, blocked, deferred, or approved'
    }

    $firstRelease = (Get-FieldValue $Record 'First Release').ToLowerInvariant()
    if ($firstRelease -notin @('yes', 'no', 'true', 'false')) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Unsupported First Release value: $firstRelease" 'Use Yes or No'
    }

    $membership = (Get-FieldValue $Record 'Candidate-Inclusive Membership Result').ToLowerInvariant()
    if ($membership -notin @('pass', 'fail', 'pending')) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Unsupported candidate membership result: $membership" 'Use Pass, Fail, or Pending'
    }

    $empty = (Get-FieldValue $Record 'Empty Eligible Range').ToLowerInvariant()
    if ($empty -notin @('yes', 'no', 'true', 'false')) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Unsupported Empty Eligible Range value: $empty" 'Use Yes or No'
    }

    $priorCommit = Get-FieldValue $Record 'Prior Approved Release Commit'
    $firstReleaseIsTrue = $firstRelease -in @('yes', 'true')
    if (-not $firstReleaseIsTrue -and -not (Test-Usable $priorCommit)) {
        Add-Diagnostic 'MISSING_FIELD' $Record.EvaluationId $Record.RelativePath 'Prior Approved Release Commit is required when First Release is No' 'Record the latest approved exclusive baseline commit'
    }

    if ($empty -in @('yes', 'true')) {
        $decision = (Get-FieldValue $Record 'Empty-Range Decision').ToLowerInvariant()
        if ((Test-Placeholder $decision) -or (($decision -notlike '*defer*') -and ($decision -notlike '*no-contract-change*'))) {
            Add-Diagnostic 'EMPTY_RANGE_DECISION' $Record.EvaluationId $Record.RelativePath 'Empty Eligible Range requires an explicit defer or no-contract-change decision' 'Record Defer or a documented no-contract-change release approval'
        }
    }

    $allValues = ($Record.Fields.Values -join ' ')
    $guidance = Get-FirstFieldValue $Record @('Migration and Upgrade Guidance', 'Migration / Upgrade Guidance')
    if ($allValues -match '(?i)breaking' -and -not (Test-Usable $guidance)) {
        Add-Diagnostic 'BREAKING_GUIDANCE_MISSING' $Record.EvaluationId $Record.RelativePath 'Breaking impact has no Migration and Upgrade Guidance' 'Add affected consumers, required actions, and a supported transition path'
    }
}

function Validate-CandidateRecord {
    param([object]$Record)

    Require-Labels $Record @(
        'Candidate Status', 'Candidate Core Version', 'Prerelease Identifier', 'Display Candidate Version',
        'Greatest Effective Impact', 'Impact Precedence Rationale', 'Supporting Eligible Commits',
        'Candidate Provenance', 'First Release Candidate Rule', 'Prerelease / Promotion Record', 'Candidate Blockers'
    )

    [void](Require-Value $Record 'Candidate Status' 'CANDIDATE_PROVENANCE')
    [void](Require-Value $Record 'Greatest Effective Impact' 'INVALID_STATE')
    [void](Require-Value $Record 'Impact Precedence Rationale')
    [void](Require-Value $Record 'Supporting Eligible Commits' 'CANDIDATE_PROVENANCE')
    [void](Require-Value $Record 'Candidate Provenance' 'CANDIDATE_PROVENANCE')

    $status = (Get-FieldValue $Record 'Candidate Status').ToLowerInvariant()
    if ($status -ne 'preliminary') {
        Add-Diagnostic 'CANDIDATE_PROVENANCE' $Record.EvaluationId $Record.RelativePath "Candidate Status must be preliminary: $status" 'Keep candidate status preliminary until a separate approval record exists'
    }

    $impact = (Get-FieldValue $Record 'Greatest Effective Impact').ToLowerInvariant()
    if ($impact -notin @('major', 'minor', 'patch', 'none', 'blocked')) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Unsupported Greatest Effective Impact: $impact" 'Use major, minor, patch, none, or blocked'
    }

    $candidateVersion = Get-FieldValue $Record 'Candidate Core Version'
    if ($impact -notin @('none', 'blocked') -and -not (Get-SemVer $candidateVersion)) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath 'Candidate Core Version is not valid SemVer' 'Record a major.minor.patch candidate or use N/A while blocked'
    }

    $allValues = ($Record.Fields.Values -join ' ')
    $guidance = Get-FirstFieldValue $Record @('Migration and Upgrade Guidance', 'Migration / Upgrade Guidance')
    if ($allValues -match '(?i)breaking' -and -not (Test-Usable $guidance)) {
        Add-Diagnostic 'BREAKING_GUIDANCE_MISSING' $Record.EvaluationId $Record.RelativePath 'Breaking impact has no Migration and Upgrade Guidance' 'Add migration and upgrade guidance before approval'
    }
}

function Validate-QARecord {
    param([object]$Record)

    Require-Labels $Record @(
        'Range Boundary Result', 'Candidate Membership Result', 'Eligibility and Maintenance Classification Result',
        'Complex-History Normalization Result', 'SemVer Precedence Result', 'Breaking-Guidance Result',
        'Every Release Note Has Supporting Contract Impact Evidence',
        'Every Effective User-Observable Contract Change Has Exactly One Public Release Note',
        'QA/Reviewer Findings', 'Named Release Blockers', 'QA Review Decision',
        'Coordinator-Handoff Gate', 'Review Date and Attestation', 'Re-Review Result'
    )

    [void](Require-Label $Record 'Breaking-Guidance Result')
    $guidanceResult = (Get-FieldValue $Record 'Breaking-Guidance Result').ToLowerInvariant()
    if ($guidanceResult -notin @('pass', 'n/a', 'pending')) {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Unsupported Breaking-Guidance Result: $guidanceResult" 'Use Pass, N/A, or Pending'
    }

    foreach ($label in @('Range Boundary Result', 'Candidate Membership Result', 'Eligibility and Maintenance Classification Result', 'Complex-History Normalization Result', 'SemVer Precedence Result', 'Every Release Note Has Supporting Contract Impact Evidence', 'Every Effective User-Observable Contract Change Has Exactly One Public Release Note', 'QA Review Decision', 'Review Date and Attestation')) {
        [void](Require-Value $Record $label)
    }

    foreach ($label in @('Range Boundary Result', 'Candidate Membership Result', 'Eligibility and Maintenance Classification Result', 'Complex-History Normalization Result', 'SemVer Precedence Result')) {
        $value = Get-FieldValue $Record $label
        if (-not (Test-Pass $value)) {
            Add-Diagnostic 'APPROVAL_REQUIRED' $Record.EvaluationId $Record.RelativePath "QA result is not Pass: $label=$value" 'Correct the QA finding and record a re-review before approval'
        }
    }

    foreach ($label in @('Every Release Note Has Supporting Contract Impact Evidence', 'Every Effective User-Observable Contract Change Has Exactly One Public Release Note')) {
        if (-not (Test-Pass (Get-FieldValue $Record $label))) {
            Add-Diagnostic 'QA_NOTE_LINKAGE' $Record.EvaluationId $Record.RelativePath "QA note-coverage attestation is not Pass: $label" 'Link every note to evidence and every effective public change to exactly one note'
        }
    }

    $decision = (Get-FieldValue $Record 'QA Review Decision').ToLowerInvariant()
    if ($decision -notlike '*accepted*' -and $decision -notlike '*deferred*' -and $decision -notlike '*blocked*') {
        Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath "Unsupported QA Review Decision: $decision" 'Record Accepted for coordinator decision, Blocked pending correction, or Deferred'
    }
}

function Validate-NotesRecord {
    param([object]$Record)

    Require-Labels $Record @('Public Release Notes', 'Maintenance Release Notes', 'Changelog State', 'Derived Entries', 'Note-to-Changelog Coverage', 'Publication Decision')
    [void](Require-Value $Record 'Changelog State')
    [void](Require-Value $Record 'Derived Entries')
    [void](Require-Value $Record 'Note-to-Changelog Coverage')
    [void](Require-Value $Record 'Publication Decision')

    $changelog = (Get-FieldValue $Record 'Changelog State').ToLowerInvariant()
    if ($changelog -notlike '*draft*' -or $changelog -notlike '*unpublish*') {
        Add-Diagnostic 'QA_NOTE_LINKAGE' $Record.EvaluationId $Record.RelativePath 'Changelog State is not explicitly draft and unpublished' 'Mark every derived changelog entry Draft and unpublished'
    }
    if (-not (Test-Pass (Get-FieldValue $Record 'Note-to-Changelog Coverage'))) {
        Add-Diagnostic 'QA_NOTE_LINKAGE' $Record.EvaluationId $Record.RelativePath 'Note-to-Changelog Coverage is not Pass' 'Provide exactly one unpublished draft entry per reviewed release note'
    }
}

function Validate-ApprovedRecord {
    param([object]$Record)

    Require-Labels $Record @(
        'Approved Release Record', 'Approved Release Version', 'Approved Release Tag',
        'Approved Release Candidate Commit', 'Approved Release Range', 'Candidate-versus-Approved Comparison',
        'Approval Difference Rationale', 'Approval Decision', 'Approval Date', 'Release Coordinator Decision Record',
        'Public and Maintenance Release Notes', 'Changelog State', 'Note-to-Changelog Coverage',
        'Shared Evaluation ID Consistency Result', 'Candidate-Inclusive Range Consistency Result',
        'Tag/Version Alignment Result', 'Version Precedence Result', 'Approval and Rationale Result',
        'QA/Note Linkage Result', 'Overall Consistency Result', 'Consistency Blockers and Resolution',
        'Tag Creation Decision', 'Hosted Release Creation Decision', 'Changelog Publication Decision',
        'Remote Operation Decision', 'Deployment Decision', 'Rollback Decision', 'External-Action Owner and Evidence'
    )

    $decision = (Get-FieldValue $Record 'Approval Decision').ToLowerInvariant()
    if ($decision -eq 'approved') {
        foreach ($label in @('Approved Release Version', 'Approved Release Tag', 'Approved Release Candidate Commit', 'Approved Release Range', 'Approval Date', 'Release Coordinator Decision Record', 'Public and Maintenance Release Notes', 'Changelog State', 'Note-to-Changelog Coverage')) {
            [void](Require-Value $Record $label 'APPROVAL_REQUIRED' 'Record complete coordinator approval evidence before representing the release as approved')
        }

        $approvedVersion = Get-FieldValue $Record 'Approved Release Version'
        if (-not (Get-SemVer $approvedVersion)) {
            Add-Diagnostic 'INVALID_STATE' $Record.EvaluationId $Record.RelativePath 'Approved Release Version is not valid SemVer' 'Record a major.minor.patch approved version'
        }
        else {
            $approvedTag = Get-FieldValue $Record 'Approved Release Tag'
            $normalizedVersion = (Unwrap-Value $approvedVersion) -replace '^v', ''
            if ($approvedTag -ne "v$normalizedVersion" -and $approvedTag -ne $normalizedVersion) {
                Add-Diagnostic 'TAG_VERSION_MISMATCH' $Record.EvaluationId $Record.RelativePath 'Approved Release Tag does not encode Approved Release Version' 'Use v<approved-version> or the approved version as the tag string'
            }
        }

        $changelog = (Get-FieldValue $Record 'Changelog State').ToLowerInvariant()
        if ($changelog -notlike '*draft*' -or $changelog -notlike '*unpublish*') {
            Add-Diagnostic 'QA_NOTE_LINKAGE' $Record.EvaluationId $Record.RelativePath 'Approved record changelog state is not Draft and unpublished' 'Keep publication as a separate human decision'
        }
        if (-not (Test-Pass (Get-FieldValue $Record 'Note-to-Changelog Coverage'))) {
            Add-Diagnostic 'QA_NOTE_LINKAGE' $Record.EvaluationId $Record.RelativePath 'Approved record note-to-changelog coverage is not Pass' 'Link reviewed notes to exactly one unpublished draft entry each'
        }

        foreach ($label in @('Shared Evaluation ID Consistency Result', 'Candidate-Inclusive Range Consistency Result', 'Tag/Version Alignment Result', 'Version Precedence Result', 'Approval and Rationale Result', 'QA/Note Linkage Result', 'Overall Consistency Result')) {
            if (-not (Test-Pass (Get-FieldValue $Record $label))) {
                Add-Diagnostic 'APPROVAL_REQUIRED' $Record.EvaluationId $Record.RelativePath "Consistency result is not Pass: $label" 'Resolve every release-consistency finding before approval'
            }
        }
    }
}

function Validate-Record {
    param([object]$Record)

    Validate-BaseRecord $Record
    switch ($Record.CanonicalType) {
        'Release Evaluation' { Validate-EvaluationRecord $Record }
        'SemVer Candidate Record' { Validate-CandidateRecord $Record }
        'QA Review Record' { Validate-QARecord $Record }
        'Release Notes Record' { Validate-NotesRecord $Record }
        'Approved Release Record' { Validate-ApprovedRecord $Record }
    }
}

function Get-RecordsOfType {
    param([object[]]$Items, [string]$CanonicalType)
    return @($Items | Where-Object { $_.CanonicalType -eq $CanonicalType })
}

function Validate-CrossRecordConsistency {
    param([object[]]$Items)

    $evaluationRecords = @(Get-RecordsOfType $Items 'Release Evaluation')
    $evaluationIds = @($evaluationRecords | Where-Object { $_.EvaluationId -ne 'UNKNOWN' } | Select-Object -ExpandProperty EvaluationId -Unique)

    foreach ($record in $Items) {
        if ($record.CanonicalType -ne 'Release Evaluation' -and $evaluationIds.Count -gt 0 -and $record.EvaluationId -notin $evaluationIds) {
            Add-Diagnostic 'EVALUATION_ID_MISMATCH' $record.EvaluationId $record.RelativePath "Evaluation ID does not match a Release Evaluation record: $($record.EvaluationId)" 'Use one shared Evaluation ID across linked evaluation artifacts'
        }
    }

    foreach ($evaluationId in $evaluationIds) {
        $evaluation = @($evaluationRecords | Where-Object { $_.EvaluationId -eq $evaluationId })
        if ($evaluation.Count -gt 1) {
            Add-Diagnostic 'INVALID_ID' $evaluationId $evaluation[1].RelativePath 'More than one Release Evaluation record uses this Evaluation ID' 'Keep one canonical evaluation record per Evaluation ID'
        }
        $evaluation = $evaluation[0]
        $candidate = @(Get-RecordsOfType $Items 'SemVer Candidate Record' | Where-Object { $_.EvaluationId -eq $evaluationId })
        $qa = @(Get-RecordsOfType $Items 'QA Review Record' | Where-Object { $_.EvaluationId -eq $evaluationId })
        $approved = @(Get-RecordsOfType $Items 'Approved Release Record' | Where-Object { $_.EvaluationId -eq $evaluationId })
        $notes = @(Get-RecordsOfType $Items 'Release Notes Record' | Where-Object { $_.EvaluationId -eq $evaluationId })

        $rangeCandidate = Get-FieldValue $evaluation 'Release Candidate Commit'
        $rangeEnd = Get-FieldValue $evaluation 'Release Range End'
        $ordered = @(Split-References (Get-FieldValue $evaluation 'Ordered Range Commit References'))
        $occurrences = @($ordered | Where-Object { $_ -eq $rangeCandidate }).Count
        if ($occurrences -ne 1 -or $ordered.Count -eq 0 -or $ordered[$ordered.Count - 1] -ne $rangeCandidate -or $rangeEnd -ne $rangeCandidate) {
            Add-Diagnostic 'RANGE_MEMBERSHIP' $evaluationId $evaluation.RelativePath 'Release Candidate Commit must appear exactly once at the inclusive end of the ordered range' 'Record the candidate in Release Range End and as the final ordered reference'
        }
        if ((Get-FieldValue $evaluation 'Candidate-Inclusive Membership Result').ToLowerInvariant() -eq 'fail') {
            Add-Diagnostic 'RANGE_MEMBERSHIP' $evaluationId $evaluation.RelativePath 'Candidate-Inclusive Membership Result is Fail' 'Correct the recorded candidate range before approval'
        }

        if ($candidate.Count -gt 1) {
            Add-Diagnostic 'INVALID_ID' $evaluationId $candidate[1].RelativePath 'More than one SemVer Candidate Record uses this Evaluation ID' 'Keep one candidate record per evaluation'
        }
        if ($candidate.Count -gt 0) {
            $candidateRecord = $candidate[0]
            $candidateCommit = Get-FieldValue $candidateRecord 'Release Candidate Commit'
            if ((Test-Field $candidateRecord 'Release Candidate Commit') -and $candidateCommit -ne $rangeCandidate) {
                Add-Diagnostic 'CANDIDATE_PROVENANCE' $evaluationId $candidateRecord.RelativePath 'Candidate record uses a different Release Candidate Commit' 'Preserve the exact evaluated candidate revision'
            }
            $provenance = Get-FieldValue $candidateRecord 'Candidate Provenance'
            if ($provenance -notlike "*$evaluationId*" -or $provenance -notlike "*$rangeCandidate*") {
                Add-Diagnostic 'CANDIDATE_PROVENANCE' $evaluationId $candidateRecord.RelativePath 'Candidate Provenance does not identify the shared evaluation and candidate commit' 'Record Evaluation ID, range, candidate commit, and supporting evidence'
            }
        }

        if ($approved.Count -gt 1) {
            Add-Diagnostic 'INVALID_ID' $evaluationId $approved[1].RelativePath 'More than one Approved Release Record uses this Evaluation ID' 'Keep one approval record per evaluation'
        }
        if ($approved.Count -gt 0) {
            $approvedRecord = $approved[0]
            $approvalDecision = (Get-FieldValue $approvedRecord 'Approval Decision').ToLowerInvariant()
            if ($approvalDecision -eq 'approved') {
                if ($qa.Count -eq 0) {
                    Add-Diagnostic 'APPROVAL_REQUIRED' $evaluationId $approvedRecord.RelativePath 'Approved Release Record has no linked QA Review Record' 'Link a completed QA review under the same Evaluation ID'
                }
                if ($candidate.Count -eq 0) {
                    Add-Diagnostic 'CANDIDATE_PROVENANCE' $evaluationId $approvedRecord.RelativePath 'Approved Release Record has no linked preliminary candidate' 'Link the preliminary candidate and retain its provenance'
                }

                $approvedCandidate = Get-FieldValue $approvedRecord 'Approved Release Candidate Commit'
                if ($approvedCandidate -ne $rangeCandidate) {
                    Add-Diagnostic 'CANDIDATE_PROVENANCE' $evaluationId $approvedRecord.RelativePath 'Approved Release Candidate Commit differs from the evaluated candidate' 'Use the same candidate revision across evaluation and approval'
                }

                $approvedRange = @(Split-References (Get-FieldValue $approvedRecord 'Approved Release Range'))
                if ($approvedRange.Count -gt 0 -and $approvedRange[$approvedRange.Count - 1] -ne $rangeCandidate) {
                    Add-Diagnostic 'RANGE_MEMBERSHIP' $evaluationId $approvedRecord.RelativePath 'Approved Release Range does not end at the evaluated candidate' 'Preserve the inclusive candidate boundary in the approval record'
                }

                $approvedVersion = Get-FieldValue $approvedRecord 'Approved Release Version'
                $approvedTag = Get-FieldValue $approvedRecord 'Approved Release Tag'
                $normalizedVersion = (Unwrap-Value $approvedVersion) -replace '^v', ''
                if ($approvedTag -ne "v$normalizedVersion" -and $approvedTag -ne $normalizedVersion) {
                    Add-Diagnostic 'TAG_VERSION_MISMATCH' $evaluationId $approvedRecord.RelativePath 'Approved Release Tag does not encode Approved Release Version' 'Use v<approved-version> or the approved version as the tag string'
                }

                $priorVersion = Get-FieldValue $evaluation 'Prior Approved Release Version'
                $approvedSemVer = Get-SemVer $approvedVersion
                $priorSemVer = Get-SemVer $priorVersion
                if ($approvedSemVer -and $priorSemVer -and (Compare-SemVerCore $approvedSemVer $priorSemVer) -lt 0) {
                    Add-Diagnostic 'VERSION_PRECEDENCE' $evaluationId $approvedRecord.RelativePath 'Approved Release Version regresses below the Version Source of Truth' 'Use a non-regressing approved SemVer or record a reviewed policy decision'
                }

                $comparison = (Get-FieldValue $approvedRecord 'Candidate-versus-Approved Comparison').ToLowerInvariant()
                $candidateVersion = if ($candidate.Count -gt 0) { Get-FieldValue $candidate[0] 'Candidate Core Version' } else { '' }
                if ($candidate.Count -gt 0 -and (Get-SemVer $candidateVersion) -and $approvedSemVer) {
                    $candidateText = ((Unwrap-Value $candidateVersion) -replace '^v', '')
                    if ($comparison -eq 'equal' -and $candidateText -ne $normalizedVersion) {
                        Add-Diagnostic 'APPROVAL_REQUIRED' $evaluationId $approvedRecord.RelativePath 'Candidate-versus-Approved Comparison says Equal but versions differ' 'Use Equal only when approved and preliminary versions match'
                    }
                    if ($candidateText -ne $normalizedVersion -and -not (Test-Usable (Get-FieldValue $approvedRecord 'Approval Difference Rationale'))) {
                        Add-Diagnostic 'APPROVAL_REQUIRED' $evaluationId $approvedRecord.RelativePath 'Approved version differs from candidate without a rationale' 'Record a non-empty Approval Difference Rationale'
                    }
                }

                if ($qa.Count -gt 0) {
                    $qaRecord = $qa[0]
                    foreach ($label in @('Range Boundary Result', 'Candidate Membership Result', 'Eligibility and Maintenance Classification Result', 'Complex-History Normalization Result', 'SemVer Precedence Result')) {
                        if (-not (Test-Pass (Get-FieldValue $qaRecord $label))) {
                            Add-Diagnostic 'APPROVAL_REQUIRED' $evaluationId $qaRecord.RelativePath "QA result is not Pass: $label" 'Resolve QA findings and re-review before approval'
                        }
                    }
                    foreach ($label in @('Every Release Note Has Supporting Contract Impact Evidence', 'Every Effective User-Observable Contract Change Has Exactly One Public Release Note')) {
                        if (-not (Test-Pass (Get-FieldValue $qaRecord $label))) {
                            Add-Diagnostic 'QA_NOTE_LINKAGE' $evaluationId $qaRecord.RelativePath "QA note linkage is not Pass: $label" 'Link every release note and effective public change to evidence'
                        }
                    }
                }

                if ($notes.Count -gt 0) {
                    $notesRecord = $notes[0]
                    if (-not (Test-Pass (Get-FieldValue $notesRecord 'Note-to-Changelog Coverage'))) {
                        Add-Diagnostic 'QA_NOTE_LINKAGE' $evaluationId $notesRecord.RelativePath 'Release Notes Record has failed note-to-changelog coverage' 'Provide one unpublished draft entry per reviewed note'
                    }
                }
            }
        }
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $RootPath 'docs/releases') -PathType Container)) {
    if ($Strict) {
        Add-Diagnostic 'MISSING_FIELD' 'REPOSITORY' 'docs/releases' 'Release-record directory does not exist' 'Provide a local docs/releases directory or use a fixture root containing one'
    }
    else {
        Write-Output 'VALID|RECORDS=0|ROOT=.'
        exit 0
    }
}
else {
    $releaseDirectory = Join-Path $RootPath 'docs/releases'
    $ciTriageDirectory = (Join-Path $releaseDirectory 'ci-triage').TrimEnd('\', '/')
    $files = @(Get-ChildItem -LiteralPath $releaseDirectory -Filter '*.md' -File -Recurse | Where-Object { (-not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) -and (-not $_.FullName.StartsWith($ciTriageDirectory + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) } | Sort-Object FullName)
    foreach ($file in $files) {
        try {
            $parsed = Get-ParsedRecord $file.FullName
        }
        catch {
            Add-Diagnostic 'READ_ERROR' 'UNKNOWN' (Get-RelativePath $file.FullName) 'Unable to read release record' 'Provide a readable local Markdown record'
            continue
        }

        if ([string]::IsNullOrWhiteSpace($parsed.RecordType)) {
            if ($Strict) {
                Add-Diagnostic 'INVALID_STATE' 'UNKNOWN' $parsed.RelativePath 'Missing Record Type' 'Use a supported canonical release-record type'
            }
            continue
        }
        if ([string]::IsNullOrWhiteSpace($parsed.CanonicalType)) {
            if ($Strict) {
                Add-Diagnostic 'INVALID_STATE' $parsed.EvaluationId $parsed.RelativePath "Unknown Record Type: $($parsed.RecordType)" 'Use Release Evaluation, SemVer Candidate Record, QA Review Record, Release Notes Record, or Approved Release Record'
            }
            continue
        }

        $script:RecordCount++
        [void]$Records.Add($parsed)
        Validate-Record $parsed
    }
}

if ($Records.Count -gt 0) {
    Validate-CrossRecordConsistency @($Records)
}

$sortedDiagnostics = @($Diagnostics | Sort-Object)
foreach ($diagnostic in $sortedDiagnostics) { Write-Output $diagnostic }
if ($ErrorCount -gt 0) {
    Write-Output "FAILED|ERRORS=$ErrorCount|RECORDS=$RecordCount"
    exit 1
}
Write-Output "VALID|RECORDS=$RecordCount|ROOT=."
exit 0
