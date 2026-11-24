# Local example/schema checks for release-record evidence.
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\release-records.examples.ps1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$ValidRoot = Join-Path $RepoRoot 'scripts\tests\fixtures\release-records\valid'
$DeferredRoot = Join-Path $RepoRoot 'scripts\tests\fixtures\release-records\empty-range-deferred'
$Validator = Join-Path $RepoRoot 'scripts\validate-release-records.ps1'
$PropertyHarness = Join-Path $RepoRoot 'scripts\tests\run-release-record-properties.ps1'

function Fail-Example {
    param([string]$Message)
    [Console]::Error.WriteLine("EXAMPLE_FAILURE|$Message")
    exit 1
}

function Assert-FileText {
    param([string]$File, [string]$Text)
    if (-not (Select-String -LiteralPath $File -Pattern ([regex]::Escape($Text)) -Quiet)) { Fail-Example "Missing '$Text' in $File" }
}

function Run-InvalidValidatorCase {
    param([string]$CaseName, [string]$ExpectedCategory)
    $caseRoot = Join-Path $RepoRoot "scripts\tests\fixtures\release-records\cases\$CaseName"
    $output = (& pwsh -NoProfile -File $script:Validator -Root $caseRoot -Strict 2>&1 | Out-String)
    $code = $LASTEXITCODE
    if ($code -eq 0) { Fail-Example "$CaseName unexpectedly passed" }
    if ($output -notmatch [regex]::Escape($ExpectedCategory)) { Fail-Example "$CaseName did not emit $ExpectedCategory" }
}

Assert-FileText (Join-Path $RepoRoot 'workflows\commit.md') 'Conventional Commit'
Assert-FileText (Join-Path $RepoRoot 'workflows\checkpoint.md') 'checkpoint'
Assert-FileText (Join-Path $RepoRoot 'workflows\ship.md') 'release'

$documentationExamples = @(
    'commit-contract|workflows\commit.md|Contract Impact Evidence|Proposed SemVer Candidate Impact',
    'commit-blocked|workflows\commit.md|blocked|evidence',
    'checkpoint-candidate|workflows\checkpoint.md|Preliminary SemVer Candidate|Requested Release Coordinator Decision',
    'checkpoint-blocked|workflows\checkpoint.md|Unresolved Blockers|Handoff Status',
    'ship-record|workflows\ship.md|Approved Release Record|Draft Changelog Entries',
    'ship-blocked|workflows\ship.md|unresolved blocker|unapproved',
    'qa-rereview|workflows\ship.md|correction/re-review|Blocker review',
    'approval-alignment|workflows\ship.md|Approved Release Tag|Approved Release Version',
    'note-coverage|workflows\ship.md|Public Release Notes|exactly one',
    'no-side-effect|workflows\ship.md|External-action decisions|must not automatically run tag commands'
)
foreach ($example in $documentationExamples) {
    $parts = $example -split '\|', 4
    if ($parts.Count -ne 4 -or [string]::IsNullOrWhiteSpace($parts[0]) -or [string]::IsNullOrWhiteSpace($parts[1]) -or [string]::IsNullOrWhiteSpace($parts[2]) -or [string]::IsNullOrWhiteSpace($parts[3])) { Fail-Example 'Malformed documentation example' }
    $exampleFile = Join-Path $RepoRoot $parts[1]
    Assert-FileText -File $exampleFile -Text $parts[2]
    Assert-FileText -File $exampleFile -Text $parts[3]
}
Write-Output 'EXAMPLE|documentation-handoffs-and-schemas|PASS'

& pwsh -NoProfile -File $Validator -Root $ValidRoot -Strict | Out-Null
if ($LASTEXITCODE -ne 0) { Fail-Example 'valid fixture control failed' }
& pwsh -NoProfile -File $Validator -Root $DeferredRoot -Strict | Out-Null
if ($LASTEXITCODE -ne 0) { Fail-Example 'empty-range fixture control failed' }
Write-Output 'EXAMPLE|valid-and-empty-range-controls|PASS'

Run-InvalidValidatorCase 'missing-field' 'MISSING_FIELD'
Run-InvalidValidatorCase 'candidate-not-in-range' 'RANGE_MEMBERSHIP'
Run-InvalidValidatorCase 'approval-missing' 'APPROVAL_REQUIRED'
Run-InvalidValidatorCase 'tag-version-mismatch' 'TAG_VERSION_MISMATCH'
Run-InvalidValidatorCase 'precedence-regression' 'VERSION_PRECEDENCE'
Run-InvalidValidatorCase 'evaluation-id-mismatch' 'EVALUATION_ID_MISMATCH'
Run-InvalidValidatorCase 'qa-note-linkage' 'QA_NOTE_LINKAGE'
Run-InvalidValidatorCase 'empty-range-no-decision' 'EMPTY_RANGE_DECISION'
Run-InvalidValidatorCase 'breaking-guidance-missing' 'BREAKING_GUIDANCE_MISSING'
Run-InvalidValidatorCase 'outcome-section-not-terminal' 'OUTCOME_SECTION'
Write-Output 'EXAMPLE|malformed-validator-diagnostics|PASS'

$propertyOutput = @(& pwsh -NoProfile -File $PropertyHarness 2>&1)
if ($LASTEXITCODE -ne 0) { Fail-Example 'paired property harness control failed' }
foreach ($propertyName in @('history-normalization-effective-set', 'exact-once-unpublished-notes', 'cross-record-read-only-consistency')) {
    if (-not ($propertyOutput | ForEach-Object { [string]$_ } | Where-Object { $_ -match "^PROPERTY\\|$propertyName\\|.*\\|PASS$" })) { Fail-Example "Property control did not pass: $propertyName" }
}
Assert-FileText -File (Join-Path $RepoRoot 'scripts\tests\fixtures\release-records\property-08.tsv') -Text 'expected.effective'
Write-Output 'EXAMPLE|mixed-history-shared-normalized-set|PASS'

Assert-FileText -File (Join-Path $RepoRoot 'scripts\tests\fixtures\release-records\property-12.tsv') -Text 'CREATE_TAG'
Assert-FileText -File $PropertyHarness -Text 'Record-Action-Request'
Assert-FileText -File $PropertyHarness -Text "ConsistencyActionLog = 'NONE'"
Write-Output 'EXAMPLE|external-action-request-is-data-only|PASS'

Write-Output 'Release-record PowerShell example checks passed: examples=5 read_only=PASS.'
Write-Output 'Release-record examples are local and synthetic; they cannot authorize tags, releases, publication, remotes, deployment, or rollback actions.'
