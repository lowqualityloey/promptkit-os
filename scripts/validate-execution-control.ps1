# Read-only Agent Execution Control validator.
# Usage: .\scripts\validate-execution-control.ps1 [-Root PATH] [-Strict]

[CmdletBinding()]
param(
    [string]$Root = ".",
    [switch]$Strict
)

$ErrorCount = 0
$RecordCount = 0
$Diagnostics = @()
$TaskById = @{}
$TaskStateById = @{}
$TaskRevisionById = @{}

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
    $script:Diagnostics += "$Category|$RecordId|$Path|$safeMessage|$safeRemediation"
    $script:ErrorCount++
}

function Get-RelativePath {
    param([string]$FilePath)
    if ($FilePath -eq $RootPath) { return "." }
    return $FilePath.Substring($RootPath.Length).TrimStart('\', '/') -replace '\\', '/'
}

function Trim-Value {
    param([AllowEmptyString()][string]$Value)
    if ($null -eq $Value) { return "" }
    return $Value.Trim()
}

function Test-Label {
    param([string]$FilePath, [string]$Label)
    $needle = "- **$Label**:"
    foreach ($line in (Get-Content -LiteralPath $FilePath)) {
        if ($line.StartsWith($needle, [System.StringComparison]::Ordinal)) { return $true }
    }
    return $false
}

function Get-FieldValue {
    param([string]$FilePath, [string]$Label)
    $needle = "- **$Label**:"
    foreach ($line in (Get-Content -LiteralPath $FilePath)) {
        if ($line.StartsWith($needle, [System.StringComparison]::Ordinal)) {
            $value = Trim-Value $line.Substring($needle.Length)
            if ($value.Length -ge 2 -and $value.StartsWith('`') -and $value.EndsWith('`')) {
                return $value.Substring(1, $value.Length - 2)
            }
            return $value
        }
    }
    return ""
}

function Get-ListItems {
    param([string]$FilePath, [string]$Label)
    $needle = "- **$Label**:"
    $inside = $false
    $items = @()
    foreach ($line in (Get-Content -LiteralPath $FilePath)) {
        if ($line.StartsWith($needle, [System.StringComparison]::Ordinal)) {
            $inside = $true
            continue
        }
        if ($inside -and $line.StartsWith("- **", [System.StringComparison]::Ordinal)) { break }
        if ($inside -and $line -match '^\s+- ') { $items += $line }
    }
    return $items
}

function Test-Placeholder {
    param([AllowEmptyString()][string]$Value)
    $value = Trim-Value $Value
    if ([string]::IsNullOrWhiteSpace($value)) { return $true }
    switch -Regex ($value) {
        '^(N/A|n/a|None|none|Not applicable|not applicable|\[N/A\]|\[None\]|\[Pending\]|Pending)$' { return $true }
        '^\[.*\]$' { return $true }
        default { return $false }
    }
}

function Require-Label {
    param([string]$FilePath, [string]$RecordId, [string]$Label, [string]$Category = "MISSING_FIELD")
    if (-not (Test-Label $FilePath $Label)) {
        Add-Diagnostic $Category $RecordId (Get-RelativePath $FilePath) "Missing field: $Label" "Add the labeled field to the canonical record"
        return $false
    }
    return $true
}

function Require-Value {
    param([string]$FilePath, [string]$RecordId, [string]$Label, [string]$Category = "MISSING_FIELD", [string]$Remediation = "Provide a non-placeholder value for the labeled field")
    $present = Require-Label $FilePath $RecordId $Label $Category
    if (-not $present) { return $false }
    $value = Get-FieldValue $FilePath $Label
    if (Test-Placeholder $value) {
        Add-Diagnostic $Category $RecordId (Get-RelativePath $FilePath) "Missing usable value: $Label" $Remediation
        return $false
    }
    return $true
}

function Test-TaskId {
    param([string]$Value, [string]$Profile = 'legacy')
    if ($Profile -ceq 'sdlc-overlay-v1') {
        return ($Value -cmatch '^TASK-[a-z0-9]+(-[a-z0-9]+)*$' -and $Value -cnotmatch '^TASK-\d{4}-\d{2}-\d{2}-')
    }
    return $Value -match '^TASK-\d{4}-\d{2}-\d{2}-[a-z0-9][a-z0-9-]*$'
}

function Test-AdaptationLink {
    param([string]$FilePath, [string]$RecordId, [string]$Link, [string]$Kind)
    $path = Get-RelativePath $FilePath
    $prefix = "$Kind-<slug>"
    $remediation = "Use [$prefix](relative/path#$prefix) pointing to an existing explicit anchor"
    $match = [regex]::Match($Link, '^\[([A-Za-z0-9._-]+)\]\(([^)#]+)#([A-Za-z0-9._-]+)\)$')
    if (-not $match.Success) {
        Add-Diagnostic 'INVALID_LINK' $RecordId $path "Invalid $Kind link: $Link" $remediation
        return $false
    }

    $linkedId = $match.Groups[1].Value
    $targetPath = $match.Groups[2].Value
    $anchor = $match.Groups[3].Value
    if ($linkedId -cne $anchor) {
        Add-Diagnostic 'INVALID_LINK' $RecordId $path "Invalid $Kind link: displayed ID and anchor differ" $remediation
        return $false
    }
    $validId = if ($Kind -eq 'PLAN') {
        $linkedId -cmatch '^PLAN-[a-z0-9]+(-[a-z0-9]+)*$'
    } elseif ($Kind -ceq 'ASSUMPTION') {
        $linkedId -cmatch '^ASSUMPTION-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}$'
    } else {
        $false
    }
    if (-not $validId) {
        Add-Diagnostic 'INVALID_LINK' $RecordId $path "Invalid $Kind link ID: $linkedId" $remediation
        return $false
    }
    if ([string]::IsNullOrWhiteSpace($targetPath) -or $targetPath -match '^(\\|/|[A-Za-z]:|[A-Za-z][A-Za-z0-9+.-]*://)') {
        Add-Diagnostic 'INVALID_LINK' $RecordId $path "Invalid $Kind link target: $targetPath" $remediation
        return $false
    }

    try {
        $recordDirectory = Split-Path -Parent $FilePath
        $targetFile = [System.IO.Path]::GetFullPath((Join-Path $recordDirectory $targetPath))
    } catch {
        Add-Diagnostic 'INVALID_LINK' $RecordId $path "Missing $Kind link target: $targetPath" $remediation
        return $false
    }
    $rootPrefix = $RootPath.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $targetFile.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Add-Diagnostic 'INVALID_LINK' $RecordId $path "Invalid $Kind link target: $targetPath" $remediation
        return $false
    }
    $anchorText = '<a id="' + $anchor + '"></a>'
    if (-not (Test-Path -LiteralPath $targetFile -PathType Leaf) -or -not (Get-Content -LiteralPath $targetFile -Raw).Contains($anchorText, [System.StringComparison]::Ordinal)) {
        Add-Diagnostic 'INVALID_LINK' $RecordId $path "Missing $Kind link target or anchor: $targetPath#$anchor" $remediation
        return $false
    }
    return $true
}

function Test-AdaptationFields {
    param([string]$FilePath, [string]$RecordId)
    $path = Get-RelativePath $FilePath
    if (Require-Value $FilePath $RecordId 'Work Type' 'ADAPTATION_FIELD') {
        $workType = Get-FieldValue $FilePath 'Work Type'
        if ($workType -cnotin @('Code Work', 'Documentation Work', 'Configuration Work', 'Research Work')) {
            Add-Diagnostic 'ADAPTATION_FIELD' $RecordId $path "Invalid Work Type: $workType" 'Use Code Work, Documentation Work, Configuration Work, or Research Work'
        }
    }

    [void](Require-Value $FilePath $RecordId 'Planning Record Link' 'ADAPTATION_FIELD')
    $planningLink = Get-FieldValue $FilePath 'Planning Record Link'
    if (-not (Test-Placeholder $planningLink)) { [void](Test-AdaptationLink $FilePath $RecordId $planningLink 'PLAN') }

    if (Test-Label $FilePath 'Planning Depth Reference') {
        $depth = Get-FieldValue $FilePath 'Planning Depth Reference'
        if ($depth -cnotin @('Minimal', 'Full', 'N/A')) {
            Add-Diagnostic 'ADAPTATION_FIELD' $RecordId $path "Invalid Planning Depth Reference: $depth" 'Use Minimal, Full, or N/A'
        }
    }

    if (Test-Label $FilePath 'Assumption Record Links') {
        $assumptions = Get-FieldValue $FilePath 'Assumption Record Links'
        if ($assumptions -cnotin @('None', 'N/A')) {
            foreach ($assumptionLink in ($assumptions -split ',')) {
                $assumptionLink = Trim-Value $assumptionLink
                if ([string]::IsNullOrWhiteSpace($assumptionLink)) {
                    Add-Diagnostic 'INVALID_LINK' $RecordId $path "Invalid ASSUMPTION link collection: $assumptions" 'Use comma-separated [ASSUMPTION-<spec-slug>-<nnn>](relative/path#ASSUMPTION-<spec-slug>-<nnn>) links, None, or N/A'
                    continue
                }
                [void](Test-AdaptationLink $FilePath $RecordId $assumptionLink 'ASSUMPTION')
            }
        }
    }

    if (Require-Value $FilePath $RecordId 'TDD Enforcement Mode' 'ADAPTATION_FIELD') {
        $tddMode = Get-FieldValue $FilePath 'TDD Enforcement Mode'
        if ($tddMode -cnotin @('disabled', 'enabled')) {
            Add-Diagnostic 'ADAPTATION_FIELD' $RecordId $path "Invalid TDD Enforcement Mode: $tddMode" 'Use disabled or enabled'
        }
    }
}

function Test-ChildId {
    param([string]$Value)
    return $Value -match '^(SCOPE|CHECKPOINT|HANDOFF)-\d{4}-\d{2}-\d{2}-.+-\d+$'
}

function Get-ExpectedStatus {
    param([string]$State)
    switch ($State) {
        { $_ -in @('planned', 'ready', 'aborted') } { return 'To Do' }
        { $_ -in @('in_progress', 'checkpoint_due', 'blocked', 'paused', 'handoff_ready') } { return 'In Progress' }
        'awaiting_review' { return 'In Review' }
        'completed' { return 'Done' }
        default { return '' }
    }
}

function Test-AllowedTransition {
    param([string]$From, [string]$To)
    $key = "$From|$To"
    $allowed = @(
        'N/A|planned', 'None|planned', 'planned|ready', 'planned|aborted',
        'ready|in_progress', 'ready|blocked', 'ready|paused', 'ready|aborted',
        'in_progress|checkpoint_due', 'in_progress|blocked', 'in_progress|paused',
        'in_progress|handoff_ready', 'in_progress|awaiting_review', 'in_progress|completed', 'in_progress|aborted',
        'checkpoint_due|in_progress', 'checkpoint_due|blocked', 'checkpoint_due|paused', 'checkpoint_due|handoff_ready', 'checkpoint_due|aborted',
        'blocked|ready', 'blocked|in_progress', 'blocked|paused', 'blocked|aborted',
        'paused|ready', 'paused|in_progress', 'paused|aborted',
        'handoff_ready|in_progress', 'handoff_ready|checkpoint_due', 'handoff_ready|blocked', 'handoff_ready|aborted',
        'awaiting_review|in_progress', 'awaiting_review|completed', 'awaiting_review|blocked'
    )
    return $allowed -contains $key
}

function Get-RevisionToken {
    param([string]$Value)
    $match = [regex]::Match($Value, 'REV-[A-Za-z0-9._-]+')
    if ($match.Success) { return $match.Value }
    $match = [regex]::Match($Value, '[0-9a-fA-F]{7,40}')
    if ($match.Success) { return $match.Value }
    return ""
}

function Test-Transitions {
    param([string]$FilePath, [string]$RecordId, [string]$State)
    $count = 0
    $lastNew = ""
    foreach ($line in (Get-Content -LiteralPath $FilePath | Where-Object { $_ -match '^\s*\|' })) {
        if ([string]::IsNullOrWhiteSpace((Trim-Value $line))) { continue }
        if ($line -match 'Previous State' -or $line -match '---') { continue }
        $parts = $line.Split('|')
        if ($parts.Count -lt 3) { continue }
        $previous = Trim-Value $parts[1]
        $new = Trim-Value $parts[2]
        $initialTransition = ($previous -in @('N/A', 'None') -and $new -eq 'planned')
        if (((Test-Placeholder $previous) -or (Test-Placeholder $new)) -and -not $initialTransition) {
            Add-Diagnostic 'INVALID_TRANSITION' $RecordId (Get-RelativePath $FilePath) 'Transition history contains a placeholder' 'Record a concrete previous and new execution state'
            continue
        }
        $count++
        if (-not (Test-AllowedTransition $previous $new)) {
            Add-Diagnostic 'INVALID_TRANSITION' $RecordId (Get-RelativePath $FilePath) "Illegal transition: $previous -> $new" 'Use the documented execution-state transition graph'
        }
        $lastNew = $new
    }
    if ($count -eq 0) {
        Add-Diagnostic 'INVALID_TRANSITION' $RecordId (Get-RelativePath $FilePath) 'No concrete transition history found' 'Record at least the initial transition and current state'
    } elseif ($lastNew -ne $State) {
        Add-Diagnostic 'INVALID_TRANSITION' $RecordId (Get-RelativePath $FilePath) "Last transition state '$lastNew' does not match current state '$State'" 'Reconcile transition history with Execution State'
    }
}

function Test-Task {
    param([string]$FilePath)
    $id = Get-FieldValue $FilePath 'Task ID'
    if ([string]::IsNullOrWhiteSpace($id)) { $id = 'UNKNOWN' }
    $script:RecordCount++
    $path = Get-RelativePath $FilePath
    $profile = Get-FieldValue $FilePath 'PromptKit Adaptation Profile'
    if (-not [string]::IsNullOrWhiteSpace($profile) -and $profile -cnotin @('none', 'sdlc-overlay-v1')) {
        Add-Diagnostic 'INVALID_PROFILE' $id $path "Unknown PromptKit Adaptation Profile: $profile" 'Use none or sdlc-overlay-v1'
    }
    $idProfile = if ($profile -ceq 'sdlc-overlay-v1') { 'sdlc-overlay-v1' } else { 'legacy' }

    if (-not (Test-TaskId $id $idProfile)) {
        $remediation = if ($idProfile -eq 'sdlc-overlay-v1') { 'Use TASK-<task-slug>' } else { 'Use TASK-YYYY-MM-DD-slug' }
        Add-Diagnostic 'INVALID_ID' $id $path "Task ID is not stable: $id" $remediation
    } elseif ($TaskById.ContainsKey($id)) {
        Add-Diagnostic 'INVALID_ID' $id $path "Duplicate Task ID: $id" 'Keep one canonical Task Record per stable task identifier'
    } else {
        $TaskById[$id] = $FilePath
    }

    if ($profile -ceq 'sdlc-overlay-v1') { Test-AdaptationFields $FilePath $id }

    $requiredLabels = @(
        'Record Type', 'Task ID', 'Specification', 'Owner / Actor', 'Execution Scope',
        'Approval Boundary', 'Created', 'Objective', 'Explicit Non-Goals', 'Dependencies',
        'Risk', 'Verification Condition', 'Mode', 'Batch Authorization', 'Soft Checkpoint',
        'Hard Checkpoint', 'Event-Driven Checkpoints', 'Stop Conditions', 'Host Timer Capability',
        'Execution State', 'Mapped `pk:tasks` Status', 'Active Task Pointer', 'Start Time',
        'Current Actor', 'Next Action', 'Changed Files', 'Scope Change Records',
        'Checkpoint Records', 'Handoff Records', 'Verification Evidence', 'CI Evidence',
        'Review Evidence', 'Commit Evidence', 'Pull Request Evidence', 'Release Evidence',
        'Blocker and Resume Condition', 'Completion State', 'Acceptance Results',
        'Changed-File Summary', 'Completion Exception', 'Completion Decision and Timestamp'
    )
    foreach ($label in $requiredLabels) { [void](Require-Label $FilePath $id $label) }
    [void](Require-Value $FilePath $id 'Record Type')
    if ((Get-FieldValue $FilePath 'Record Type') -ne 'Task Record') { Add-Diagnostic 'INVALID_STATE' $id $path 'Record Type is not Task Record' 'Use the canonical Task Record type' }
    foreach ($label in @('Specification', 'Owner / Actor', 'Execution Scope', 'Approval Boundary', 'Created', 'Risk')) { [void](Require-Value $FilePath $id $label) }
    [void](Require-Value $FilePath $id 'Objective' 'READINESS_FAILURE')
    [void](Require-Label $FilePath $id 'Dependencies' 'READINESS_FAILURE')
    [void](Require-Value $FilePath $id 'Verification Condition' 'READINESS_FAILURE')
    [void](Require-Value $FilePath $id 'Mode' 'READINESS_FAILURE')
    [void](Require-Value $FilePath $id 'Host Timer Capability' 'POLICY_LIMITATION')

    $inScope = (Get-ListItems $FilePath 'In Scope') -join "`n"
    $nonGoals = (Get-ListItems $FilePath 'Explicit Non-Goals') -join "`n"
    if ([string]::IsNullOrWhiteSpace((Trim-Value $inScope)) -or $inScope.Contains('[File')) { Add-Diagnostic 'READINESS_FAILURE' $id $path 'In Scope must contain at least one concrete item' 'List the bounded files, behaviors, or deliverables' }
    if ([string]::IsNullOrWhiteSpace((Trim-Value $nonGoals)) -or $nonGoals.Contains('[File')) { Add-Diagnostic 'READINESS_FAILURE' $id $path 'Explicit Non-Goals must contain a concrete boundary' 'Record what is deliberately excluded' }
    $timer = Get-FieldValue $FilePath 'Host Timer Capability'
    if ($timer -notmatch '(?i)limitation|cannot|unavailable|not[\s-]*(mechanically|guaranteed|observe|terminate|enforce)|n/?a') { Add-Diagnostic 'POLICY_LIMITATION' $id $path 'Host timer capability does not record an enforcement limitation' 'State that live host timing or forced termination is unavailable or limited' }

    $state = Get-FieldValue $FilePath 'Execution State'
    $mapped = Get-FieldValue $FilePath 'Mapped `pk:tasks` Status'
    $active = Get-FieldValue $FilePath 'Active Task Pointer'
    $TaskStateById[$id] = $state
    $expected = Get-ExpectedStatus $state
    if ($state -notin @('planned', 'ready', 'in_progress', 'checkpoint_due', 'blocked', 'paused', 'handoff_ready', 'awaiting_review', 'completed', 'aborted')) { Add-Diagnostic 'INVALID_STATE' $id $path "Unknown execution state: $state" 'Use one of the documented execution states' }
    if (-not [string]::IsNullOrWhiteSpace($expected) -and $mapped -ne $expected) { Add-Diagnostic 'INVALID_STATE' $id $path "Mapped board status '$mapped' does not match execution state '$state'" 'Use the established pk:tasks status mapping' }
    if ($state -eq 'in_progress') {
        if ($active -ne $id) { Add-Diagnostic 'ACTIVE_TASK_CONFLICT' $id $path 'In-progress task does not own its active pointer' 'Set Active Task Pointer to this Task ID' }
        [void](Require-Value $FilePath $id 'Start Time')
    } elseif (-not (Test-Placeholder $active)) {
        Add-Diagnostic 'ACTIVE_TASK_CONFLICT' $id $path 'Non-active task retains an active pointer' 'Clear Active Task Pointer before leaving in_progress'
    }
    [void](Require-Value $FilePath $id 'Current Actor')
    [void](Require-Value $FilePath $id 'Next Action')
    Test-Transitions $FilePath $id $state

    $acCount = @(Select-String -LiteralPath $FilePath -Pattern 'AC-[A-Za-z0-9._-]+' -AllMatches).Count
    if ($acCount -eq 0) { Add-Diagnostic 'READINESS_FAILURE' $id $path 'No stable acceptance criterion ID found' 'Add at least one AC-* acceptance criterion' }

    $revision = Get-FieldValue $FilePath 'Branch / Revision'
    if ([string]::IsNullOrWhiteSpace($revision)) { $revision = Get-FieldValue $FilePath 'Validated Revision' }
    $TaskRevisionById[$id] = Get-RevisionToken $revision

    if ($state -in @('blocked', 'paused', 'aborted')) {
        $blocker = Get-FieldValue $FilePath 'Blocker and Resume Condition'
        if (Test-Placeholder $blocker) { Add-Diagnostic 'BLOCKER_UNRESOLVED' $id $path 'Stop state lacks a blocker or resume condition' 'Record the owner, evidence, and precise resume condition' }
    }
    if ($state -eq 'checkpoint_due' -and (Test-Placeholder (Get-FieldValue $FilePath 'Checkpoint Records'))) { Add-Diagnostic 'CHECKPOINT_INCOMPLETE' $id $path 'checkpoint_due task has no checkpoint record reference' 'Create and link a checkpoint record before resuming' }

    $changedItems = @(Get-ListItems $FilePath 'Changed Files')
    $scopeChange = Get-FieldValue $FilePath 'Scope Change Records'
    if ($state -eq 'completed') {
        if ($changedItems.Count -eq 0 -or (($changedItems -join "`n").Contains('[path]'))) { Add-Diagnostic 'COMPLETION_EVIDENCE_MISSING' $id $path 'Completed task has no concrete Changed Files evidence' 'List the changed files and summaries' }
        foreach ($label in @('Verification Evidence', 'CI Evidence', 'Review Evidence', 'Commit Evidence', 'Pull Request Evidence', 'Acceptance Results', 'Changed-File Summary', 'Completion Decision and Timestamp')) {
            $value = Get-FieldValue $FilePath $label
            if (Test-Placeholder $value) { Add-Diagnostic 'COMPLETION_EVIDENCE_MISSING' $id $path "Completed task lacks usable $label" 'Record observable completion evidence or an explicit approved exception' }
        }
        if ((Get-FieldValue $FilePath 'Completion State') -ne 'completed') { Add-Diagnostic 'COMPLETION_EVIDENCE_MISSING' $id $path 'Completion State does not confirm completed' 'Set the completion gate only after evidence is linked' }
    }

    if ($changedItems.Count -gt 0) {
        foreach ($item in $changedItems) {
            if ($item -match '`([^`]+)`') {
                $changedPath = $Matches[1]
                if (-not $inScope.Contains($changedPath)) {
                    if ((Test-Placeholder $scopeChange) -or $scopeChange -notmatch '(?i)scope-') { Add-Diagnostic 'SCOPE_CHANGE_MISSING' $id $path "Changed file '$changedPath' is outside the recorded In Scope boundary" 'Link an approved Scope Change Record or keep the change within scope' }
                }
            }
        }
    }
}

function Test-ScopeChange {
    param([string]$FilePath)
    $id = Get-FieldValue $FilePath 'Scope Change ID'; if ([string]::IsNullOrWhiteSpace($id)) { $id = 'UNKNOWN' }
    $script:RecordCount++; $path = Get-RelativePath $FilePath
    if (-not (Test-ChildId $id)) { Add-Diagnostic 'INVALID_ID' $id $path "Scope Change ID is not stable: $id" 'Use SCOPE-YYYY-MM-DD-task-id-sequence' }
    $labels = @('Record Type', 'Scope Change ID', 'Task ID', 'Specification', 'Proposer / Actor', 'Created', 'Approval Boundary', 'Reason or Discovery', 'Current Task Value', 'Proposed Value', 'Affected Objective', 'Affected Files or Artifacts', 'Affected Acceptance Criteria', 'Affected Dependencies', 'New or Changed Non-Goals', 'Risk / Estimate Impact', 'Changed Verification Condition', 'Disposition', 'Independent Work Discovered', 'Required Human Confirmation', 'Required New Task Record', 'Block Until Resolved', 'Decision', 'Approver', 'Decision Timestamp', 'Approval Evidence', 'Related Checkpoint', 'Related Handoff', 'Branch / Revision', 'Verification Plan or Result', 'Blocker and Resume Condition', 'Previous Task State', 'Resulting Task State', 'Task Record Updated', 'New Task / Exception Links', 'Changed Scope Summary', 'Next Action', 'Recorded By and Timestamp')
    foreach ($label in $labels) { [void](Require-Label $FilePath $id $label) }
    $valueLabels = @('Reason or Discovery', 'Current Task Value', 'Proposed Value', 'Affected Objective', 'Affected Files or Artifacts', 'Affected Acceptance Criteria', 'Risk / Estimate Impact', 'Changed Verification Condition', 'Disposition', 'Required Human Confirmation', 'Block Until Resolved', 'Decision', 'Decision Timestamp', 'Branch / Revision', 'Verification Plan or Result', 'Changed Scope Summary', 'Next Action', 'Recorded By and Timestamp')
    foreach ($label in $valueLabels) { [void](Require-Value $FilePath $id $label) }
    if ((Get-FieldValue $FilePath 'Record Type') -ne 'Scope Change Record') { Add-Diagnostic 'INVALID_STATE' $id $path 'Record Type is not Scope Change Record' 'Use the canonical Scope Change Record type' }
    $taskId = Get-FieldValue $FilePath 'Task ID'
    if (-not $TaskById.ContainsKey($taskId)) { Add-Diagnostic 'TRACEABILITY_MISSING' $id $path "Scope Change Record references unknown Task ID: $taskId" 'Link the record to an existing canonical Task Record' }
    if ((Get-FieldValue $FilePath 'Decision') -eq 'Approved') {
        [void](Require-Value $FilePath $id 'Approver')
        [void](Require-Value $FilePath $id 'Approval Evidence')
    }
    [void](Require-Value $FilePath $id 'Next Action')
}

function Test-Checkpoint {
    param([string]$FilePath)
    $id = Get-FieldValue $FilePath 'Checkpoint ID'; if ([string]::IsNullOrWhiteSpace($id)) { $id = 'UNKNOWN' }
    $script:RecordCount++; $path = Get-RelativePath $FilePath
    if (-not (Test-ChildId $id)) { Add-Diagnostic 'INVALID_ID' $id $path "Checkpoint ID is not stable: $id" 'Use CHECKPOINT-YYYY-MM-DD-task-id-sequence' }
    $labels = @('Record Type', 'Checkpoint ID', 'Task ID', 'Specification', 'Created', 'Checkpoint Type', 'Execution State', 'Objective', 'Completed Work', 'Remaining Work', 'Changed Files', 'Branch / Revision', 'Locked Decisions and Invariants', 'Verification Evidence', 'CI Evidence', 'Blockers', 'Scope Changes', 'Next Action', 'Resume Condition', 'Recorded By')
    foreach ($label in $labels) {
        if ($label -eq 'Changed Files' -or $label -eq 'Blockers' -or $label -eq 'Scope Changes') {
            [void](Require-Label $FilePath $id $label 'CHECKPOINT_INCOMPLETE')
        } else {
            [void](Require-Value $FilePath $id $label 'CHECKPOINT_INCOMPLETE')
        }
    }
    if ((Get-FieldValue $FilePath 'Record Type') -ne 'Checkpoint Record') { Add-Diagnostic 'CHECKPOINT_INCOMPLETE' $id $path 'Record Type is not Checkpoint Record' 'Use the canonical Checkpoint Record type' }
    $taskId = Get-FieldValue $FilePath 'Task ID'
    if (-not $TaskById.ContainsKey($taskId)) { Add-Diagnostic 'TRACEABILITY_MISSING' $id $path "Checkpoint references unknown Task ID: $taskId" 'Link the checkpoint to an existing Task Record' }
}

function Test-Handoff {
    param([string]$FilePath)
    $id = Get-FieldValue $FilePath 'Handoff ID'; if ([string]::IsNullOrWhiteSpace($id)) { $id = 'UNKNOWN' }
    $script:RecordCount++; $path = Get-RelativePath $FilePath
    if (-not (Test-ChildId $id)) { Add-Diagnostic 'INVALID_ID' $id $path "Handoff ID is not stable: $id" 'Use HANDOFF-YYYY-MM-DD-task-id-sequence' }
    $labels = @('Record Type', 'Handoff ID', 'Task ID', 'Specification', 'Created', 'Sender / Current Owner', 'Intended Receiver', 'Approval Boundary', 'Execution State', 'Execution Scope', 'Objective', 'Completed Milestones', 'Remaining Acceptance Criteria', 'Blockers and Resume Conditions', 'Next Action', 'Branch', 'Validated Revision', 'Changed Files', 'Task Record', 'Related Scope Changes', 'Related Checkpoints', 'Related Exceptions', 'Verification Commands and Results', 'CI Evidence', 'Review / Commit / PR Evidence', 'Release Evidence', 'Locked Decisions', 'Non-Negotiable Invariants', 'Rejected Approaches', 'Scope and Approval Constraints', 'Host or Timer Limitations', 'Receiver', 'Acceptance Decision', 'Acceptance Timestamp', 'Receiver-Validated Revision', 'Validation Evidence', 'Scope Changed During Acceptance', 'Acceptance Blocker and Resume Condition', 'Resulting Execution State', 'Task Record Updated', 'Handoff Closed By', 'Closed Timestamp', 'Next Action')
    foreach ($label in $labels) { [void](Require-Label $FilePath $id $label) }
    $valueLabels = @('Record Type', 'Handoff ID', 'Task ID', 'Specification', 'Created', 'Sender / Current Owner', 'Intended Receiver', 'Approval Boundary', 'Execution State', 'Execution Scope', 'Objective', 'Next Action', 'Branch', 'Validated Revision', 'Task Record', 'Verification Commands and Results', 'Host or Timer Limitations', 'Receiver', 'Acceptance Decision', 'Acceptance Timestamp', 'Resulting Execution State', 'Task Record Updated', 'Handoff Closed By', 'Closed Timestamp')
    foreach ($label in $valueLabels) { [void](Require-Value $FilePath $id $label 'HANDOFF_INCOMPLETE') }
    if ((Get-FieldValue $FilePath 'Record Type') -ne 'Handoff Record') { Add-Diagnostic 'HANDOFF_INCOMPLETE' $id $path 'Record Type is not Handoff Record' 'Use the canonical Handoff Record type' }
    $taskId = Get-FieldValue $FilePath 'Task ID'
    if (-not $TaskById.ContainsKey($taskId)) { Add-Diagnostic 'TRACEABILITY_MISSING' $id $path "Handoff references unknown Task ID: $taskId" 'Link the handoff to an existing Task Record' }
    [void](Require-Value $FilePath $id 'Next Action' 'HANDOFF_INCOMPLETE')
    [void](Require-Value $FilePath $id 'Host or Timer Limitations' 'POLICY_LIMITATION')
    if ((Get-FieldValue $FilePath 'Acceptance Decision') -eq 'Accepted') {
        [void](Require-Value $FilePath $id 'Receiver-Validated Revision' 'HANDOFF_INCOMPLETE')
        [void](Require-Value $FilePath $id 'Validation Evidence' 'HANDOFF_INCOMPLETE')
    }
}

try {
    $RootPath = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path.TrimEnd('\', '/')
} catch {
    Write-Output 'MISSING_FIELD|REPOSITORY|.|Repository root does not exist|Provide a valid -Root path'
    exit 1
}

$taskDir = Join-Path $RootPath 'docs/tasks'
if (-not (Test-Path -LiteralPath $taskDir -PathType Container)) {
    if ($Strict) { Add-Diagnostic 'MISSING_FIELD' 'REPOSITORY' 'docs/tasks' 'Canonical Task Source directory is missing' 'Create docs/tasks for Controlled Work or omit strict validation when no records are present' }
} else {
    $recordFiles = @(Get-ChildItem -LiteralPath $taskDir -Filter '*.md' -File | Sort-Object FullName)
    foreach ($file in $recordFiles) {
        $recordType = Get-FieldValue $file.FullName 'Record Type'
        if ([string]::IsNullOrWhiteSpace($recordType)) {
            if ($Strict) { Add-Diagnostic 'MISSING_FIELD' 'UNKNOWN' (Get-RelativePath $file.FullName) 'Record Type is missing' 'Use a recognized execution-control record type or remove the file from docs/tasks' }
            continue
        }
        if ($recordType -eq 'Task Record') { Test-Task $file.FullName }
    }
    foreach ($file in $recordFiles) {
        $recordType = Get-FieldValue $file.FullName 'Record Type'
        switch ($recordType) {
            'Scope Change Record' { Test-ScopeChange $file.FullName }
            'Checkpoint Record' { Test-Checkpoint $file.FullName }
            'Handoff Record' { Test-Handoff $file.FullName }
            'Task Record' { }
            '' { }
            default { if ($Strict) { Add-Diagnostic 'INVALID_STATE' 'UNKNOWN' (Get-RelativePath $file.FullName) "Unknown Record Type: $recordType" 'Use Task, Scope Change, Checkpoint, or Handoff Record' } }
        }
    }
    $activeCount = @($TaskStateById.GetEnumerator() | Where-Object { $_.Value -eq 'in_progress' }).Count
    if ($activeCount -gt 1) { Add-Diagnostic 'ACTIVE_TASK_CONFLICT' 'REPOSITORY' 'docs/tasks' 'More than one Task Record is in_progress' 'Leave exactly one active task in the execution scope' }
}

$stateFile = Join-Path $RootPath 'docs/STATE.md'
if (Test-Path -LiteralPath $stateFile -PathType Leaf) {
    $statePath = Get-RelativePath $stateFile

    # Validate Markdown table structural integrity and pipe hygiene in STATE.md
    $stateLines = Get-Content -LiteralPath $stateFile
    $inCodeBlock = $false
    $inTable = $false
    $headerCols = 0
    $delimLineIndex = -1

    for ($i = 0; $i -lt $stateLines.Count; $i++) {
        $lineNum = $i + 1
        $line = $stateLines[$i]

        if ($line -match '^\s*```') {
            $inCodeBlock = -not $inCodeBlock
            $inTable = $false
            continue
        }
        if ($inCodeBlock) { continue }

        $isTableLine = ($line -match '^\s*\|.*\|\s*$')

        if (-not $inTable) {
            if ($isTableLine) {
                # Check if next line is a delimiter
                $nextIsDelim = $false
                if ($i + 1 -lt $stateLines.Count) {
                    $nextIsDelim = ($stateLines[$i + 1] -match '^\s*\|(?:\s*:?-+:?\s*\|)+\s*$')
                }
                if ($nextIsDelim) {
                    $inTable = $true
                    $delimLineIndex = $i + 1
                    $cells = [regex]::Split($line.Trim(), '(?<!\\)\|')
                    $headerCols = if ($cells.Count -ge 2 -and [string]::IsNullOrWhiteSpace($cells[0]) -and [string]::IsNullOrWhiteSpace($cells[-1])) { $cells.Count - 2 } else { $cells.Count }
                } else {
                    Add-Diagnostic 'ORPHANED_TABLE_ROW' 'STATE' $statePath ("Table row at line {0} appears without a preceding table header or delimiter" -f $lineNum) 'Keep table rows contiguous without blank lines, or ensure table has a header and delimiter'
                }
            }
        } else {
            if ([string]::IsNullOrWhiteSpace($line) -or -not $isTableLine) {
                $inTable = $false
            } elseif ($i -eq $delimLineIndex) {
                $dcells = [regex]::Split($line.Trim(), '(?<!\\)\|')
                $dCols = if ($dcells.Count -ge 2 -and [string]::IsNullOrWhiteSpace($dcells[0]) -and [string]::IsNullOrWhiteSpace($dcells[-1])) { $dcells.Count - 2 } else { $dcells.Count }
                if ($dCols -ne $headerCols) {
                    Add-Diagnostic 'TABLE_COLUMN_MISMATCH' 'STATE' $statePath ("Table delimiter at line {0} has {1} columns (expected {2})" -f $lineNum, $dCols, $headerCols) 'Ensure table delimiter matches header column count'
                }
            } else {
                $rcells = [regex]::Split($line.Trim(), '(?<!\\)\|')
                $rCols = if ($rcells.Count -ge 2 -and [string]::IsNullOrWhiteSpace($rcells[0]) -and [string]::IsNullOrWhiteSpace($rcells[-1])) { $rcells.Count - 2 } else { $rcells.Count }
                if ($rCols -ne $headerCols) {
                    Add-Diagnostic 'TABLE_COLUMN_MISMATCH' 'STATE' $statePath ("Table row at line {0} has {1} columns (expected {2})" -f $lineNum, $rCols, $headerCols) 'Ensure all cells are on a single line and literal pipes are escaped with \|'
                }
            }
        }
    }

    $stateText = Get-Content -LiteralPath $stateFile -Raw
    if ($stateText -match '(?i)Execution-Control Projection|3A\. Execution-Control') {
        $stateId = Get-FieldValue $stateFile 'Task ID'
        if (-not $TaskById.ContainsKey($stateId)) { Add-Diagnostic 'STATE_PROJECTION_MISMATCH' $stateId $statePath "STATE projection references unknown Task ID: $stateId" 'Synchronize docs/STATE.md from the canonical Task Record' }
        if ($TaskById.ContainsKey($stateId)) {
            $taskFile = $TaskById[$stateId]
            foreach ($pair in @(@('Execution State', 'Execution State'), @('Mapped `pk:tasks` Status', 'Mapped `pk:tasks` Status'), @('Active Task Pointer', 'Active Task Pointer'), @('Owner / Current Actor', 'Current Actor'))) {
                $stateValue = Get-FieldValue $stateFile $pair[0]; $taskValue = Get-FieldValue $taskFile $pair[1]
                if ($stateValue -ne $taskValue) { Add-Diagnostic 'STATE_PROJECTION_MISMATCH' $stateId $statePath "STATE $($pair[0]) '$stateValue' disagrees with Task Record '$taskValue'" 'Reconcile the projection without overriding the Task Record' }
            }
            $stateRevision = Get-RevisionToken (Get-FieldValue $stateFile 'Current Revision')
            $taskRevision = $TaskRevisionById[$stateId]
            if (-not [string]::IsNullOrWhiteSpace($stateRevision) -and -not [string]::IsNullOrWhiteSpace($taskRevision) -and $stateRevision -ne $taskRevision) { Add-Diagnostic 'REVISION_MISMATCH' $stateId $statePath "STATE revision '$stateRevision' disagrees with Task Record revision '$taskRevision'" 'Use one exact validated revision across linked evidence' }
        }
    }
}

if ($ErrorCount -eq 0) {
    Write-Output ("VALID|RECORDS={0}|ROOT=." -f $RecordCount)
    exit 0
}
foreach ($diagnostic in $Diagnostics) { Write-Output $diagnostic }
Write-Output ("FAILED|ERRORS={0}|RECORDS={1}" -f $ErrorCount, $RecordCount)
exit 1
