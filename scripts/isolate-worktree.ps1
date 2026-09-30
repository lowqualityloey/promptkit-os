<#
.SYNOPSIS
    PromptKit OS Git Worktree Isolation Utility
.DESCRIPTION
    Creates, lists, merges, and safely removes isolated Git worktrees
    for risky multi-file tasks, spike explorations, or subagent runs.
    Ensures .worktrees/ is excluded from git tracking.
.PARAMETER Action
    create, list, merge, remove
.PARAMETER TaskId
    Identifier for the isolated worktree (e.g. task-123 or feat-auth)
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [ValidateSet("create", "list", "merge", "remove", "status")]
    [string]$Action = "list",

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$TaskId = "",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Verify inside git repository
try {
    $RepoRoot = (git rev-parse --show-toplevel).Trim()
} catch {
    Write-Error "Not inside a git repository."
    exit 1
}

$WorktreeBase = Join-Path $RepoRoot ".worktrees"

# Ensure .worktrees/ is in .gitignore
$GitIgnorePath = Join-Path $RepoRoot ".gitignore"
$NeedIgnore = $true
if (Test-Path $GitIgnorePath) {
    $Content = Get-Content $GitIgnorePath -Raw
    if ($Content -match "(?m)^\.worktrees/?$") {
        $NeedIgnore = $false
    }
}
if ($NeedIgnore) {
    Add-Content -Path $GitIgnorePath -Value "`n# PromptKit OS isolated worktrees`n.worktrees/`n"
    Write-Host "  [+] Added .worktrees/ to .gitignore" -ForegroundColor DarkGray
}

switch ($Action) {
    "create" {
        if ([string]::IsNullOrWhiteSpace($TaskId)) {
            Write-Error "TaskId is required for 'create'. Example: .\scripts\isolate-worktree.ps1 create task-42"
            exit 1
        }
        $BranchName = "worktree/$TaskId"
        $TargetPath = Join-Path $WorktreeBase $TaskId

        if (Test-Path $TargetPath) {
            Write-Warning "Worktree path already exists: $TargetPath"
            exit 0
        }

        if (-not (Test-Path $WorktreeBase)) {
            New-Item -ItemType Directory -Path $WorktreeBase -Force | Out-Null
        }

        Write-Host "🌿 Creating isolated worktree at $TargetPath on branch '$BranchName'..." -ForegroundColor Cyan
        git worktree add -b $BranchName $TargetPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create worktree at $TargetPath."
            exit $LASTEXITCODE
        }
        Write-Host "  ✅ Worktree created successfully." -ForegroundColor Green
        Write-Host "  To enter worktree: cd $TargetPath" -ForegroundColor DarkGray
    }

    { $_ -in @("list", "status") } {
        Write-Host "📋 Active Git Worktrees:" -ForegroundColor Cyan
        git worktree list
    }

    "merge" {
        if ([string]::IsNullOrWhiteSpace($TaskId)) {
            Write-Error "TaskId is required for 'merge'. Example: .\scripts\isolate-worktree.ps1 merge task-42"
            exit 1
        }
        $BranchName = "worktree/$TaskId"
        Write-Host "🔀 Merging branch '$BranchName' into current branch..." -ForegroundColor Cyan
        git merge $BranchName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to merge branch '$BranchName'."
            exit $LASTEXITCODE
        }
        Write-Host "  ✅ Merge completed. Remember to remove the worktree with 'remove $TaskId' when finished." -ForegroundColor Green
    }

    "remove" {
        if ([string]::IsNullOrWhiteSpace($TaskId)) {
            Write-Error "TaskId is required for 'remove'. Example: .\scripts\isolate-worktree.ps1 remove task-42"
            exit 1
        }
        $BranchName = "worktree/$TaskId"
        $TargetPath = Join-Path $WorktreeBase $TaskId

        Write-Host "🧹 Removing worktree at $TargetPath..." -ForegroundColor Cyan
        if (Test-Path $TargetPath) {
            if ($Force) {
                git worktree remove $TargetPath --force
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Failed to forcefully remove worktree at $TargetPath."
                    exit $LASTEXITCODE
                }
            } else {
                try {
                    $originalEAP = $ErrorActionPreference
                    $ErrorActionPreference = "Continue"
                    $result = git worktree remove $TargetPath 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Worktree has uncommitted changes or unmerged branches.`nUse -Force to forcefully remove it."
                        exit 1
                    }
                } finally {
                    $ErrorActionPreference = $originalEAP
                }
            }
        } else {
            git worktree prune
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to prune git worktree."
                exit $LASTEXITCODE
            }
        }

        # Optional branch deletion
        $branchExists = git branch --list $BranchName
        if ($branchExists) {
            if ($Force) {
                git branch -D $BranchName
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Failed to forcefully delete branch $BranchName."
                    exit $LASTEXITCODE
                }
                Write-Host "  [-] Force deleted branch $BranchName" -ForegroundColor DarkGray
            } else {
                try {
                    $originalEAP = $ErrorActionPreference
                    $ErrorActionPreference = "Continue"
                    $result = git branch -d $BranchName 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Branch $BranchName is not fully merged.`nUse -Force to forcefully delete it."
                        exit 1
                    }
                    Write-Host "  [-] Deleted branch $BranchName" -ForegroundColor DarkGray
                } finally {
                    $ErrorActionPreference = $originalEAP
                }
            }
        }
        Write-Host "  ✅ Worktree cleaned up successfully." -ForegroundColor Green
    }
}
