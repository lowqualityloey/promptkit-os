# Validation Script: Verify all workflow→template references exist
# Run from repository root: .\.promptkit\scripts\validate-references.ps1

param(
    [string]$PromptKitDir = ".promptkit",
    [switch]$Strict
)

$ErrorActionPreference = "Continue"
$script:ErrorCount = 0
$script:WarningCount = 0

Write-Host "`n🔍 PromptKit OS Reference Validation`n" -ForegroundColor Cyan

# Resolve paths
if (-not (Test-Path $PromptKitDir)) {
    Write-Host "❌ ERROR: PromptKit directory not found: $PromptKitDir" -ForegroundColor Red
    exit 1
}

$PromptKitRoot = Resolve-Path $PromptKitDir

# Define directories to scan
$WorkflowsDir = Join-Path $PromptKitRoot "workflows"
$ProtocolsDir = Join-Path $PromptKitRoot "protocols"
$TemplatesDir = Join-Path $PromptKitRoot "templates"
$ActivitiesDir = Join-Path $PromptKitRoot "activities"
$DocsDir = Join-Path $PromptKitRoot "docs"
$ExamplesDir = Join-Path $PromptKitRoot "examples"
$NotesDir = Join-Path $PromptKitRoot "notes"

Write-Host "📂 Scanning directories:" -ForegroundColor Yellow
Write-Host "   - $WorkflowsDir"
Write-Host "   - $ProtocolsDir"
Write-Host "   - $TemplatesDir"
Write-Host "   - $ActivitiesDir"
Write-Host "   - $DocsDir"
Write-Host "   - $ExamplesDir"
Write-Host "   - $NotesDir"
Write-Host "   - $PromptKitRoot (top level)`n"

# Find all markdown files. The content directories are scanned recursively and
# the repository root only at its top level.
$AllMarkdownFiles = @()
foreach ($dir in @($WorkflowsDir, $ProtocolsDir, $TemplatesDir, $ActivitiesDir, $DocsDir, $ExamplesDir, $NotesDir)) {
    $AllMarkdownFiles += Get-ChildItem -Path $dir -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue
}
$AllMarkdownFiles += Get-ChildItem -Path (Join-Path $PromptKitRoot "*.md") -File -ErrorAction SilentlyContinue

Write-Host "📄 Found $($AllMarkdownFiles.Count) markdown files to validate`n" -ForegroundColor Cyan

# Anti-typo check for setup script commands. Scope parity with the Bash twin:
# scan every file under the root (not only *.md), excluding VCS/worktree internals.
Write-Host "🔍 Checking for setup script typos..." -ForegroundColor Cyan
$typoPattern = 'i' + ' nit\.ps1'
$typoFiles = Get-ChildItem -Path $PromptKitRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '[\\/]\.git([\\/]|$)' -and $_.FullName -notmatch '[\\/]\.worktrees([\\/]|$)' } |
    Select-String -Pattern $typoPattern
if ($typoFiles) {
    Write-Host "  ❌ BROKEN: Setup typo found in repository:" -ForegroundColor Red
    $typoFiles | ForEach-Object { Write-Host "     $($_.Path):$($_.LineNumber)" -ForegroundColor Red }
    $script:ErrorCount++
} else {
    Write-Host "  ✅ No setup script typos found" -ForegroundColor Green
}
Write-Host ""

# Validation patterns
$Patterns = @{
    "Template Reference" = '\.promptkit/templates/([a-zA-Z0-9_-]+\.md)'
    "Workflow Reference" = '\.promptkit/workflows/([a-zA-Z0-9_-]+\.md)'
    "Protocol Reference" = '\.promptkit/protocols/([a-zA-Z0-9_-]+\.md)'
    "Relative Template" = 'templates/([a-zA-Z0-9_-]+\.md)'
}

function Test-FileReference {
    param(
        [string]$SourceFile,
        [string]$RefType,
        [string]$RefPath,
        [int]$LineNumber
    )
    
    $baseDir = $PromptKitRoot
    $fullPath = Join-Path $baseDir $RefPath
    
    if (-not (Test-Path $fullPath)) {
        $relSource = $SourceFile.Substring($PromptKitRoot.Path.Length).TrimStart("\", "/")
        Write-Host "  ❌ BROKEN: ${relSource}:$LineNumber" -ForegroundColor Red
        Write-Host "     Type: $RefType" -ForegroundColor DarkGray
        Write-Host "     Missing: $RefPath`n" -ForegroundColor DarkGray
        $script:ErrorCount++
        return $false
    }
    return $true
}

# Generic markdown-link resolution: a reader-facing relative link in a scanned
# file must resolve. Historical records are exempt (same policy as the
# canonical-count drift guard), placeholder/anchor/absolute/external targets are
# skipped, and inline code spans are ignored so illustrative examples cannot
# trip the gate. Without this, a root-relative link inside docs/ passes every
# gate while 404ing for readers on the host.
$script:LinkExemptDirs = @("docs/releases/", "docs/tasks/", "docs/archive/", "docs/internal/", "docs/spikes/")

# The trigger/workflow correspondence check cannot be applied to public
# specifications: a spec's subject is frequently the trigger it proposes to add, so
# issue-547 legitimately names `pk:doctor` while `workflows/doctor.md` does not exist
# yet. Without this, committing an accurate spec fails the build for being accurate,
# and the only ways out are to mangle the trigger token out of the prose or to ship the
# workflow early. The correspondence is still enforced where triggers actually ship --
# the directive templates and protocols/setup.md -- and by the behavioral contract that
# asserts zero warnings. Same exemption policy as LinkExemptDirs.
$script:TriggerScanExemptDirs = @("docs/specs/")

function Test-TriggerScanExempt {
    param([string]$RelPath)
    $normalizedRelPath = $RelPath.Replace('\', '/')
    foreach ($exempt in $script:TriggerScanExemptDirs) {
        if ($normalizedRelPath.StartsWith($exempt)) { return $true }
    }
    return $false
}

function Test-LinkExempt {
    param([string]$RelPath)
    $normalizedRelPath = $RelPath.Replace('\', '/')
    foreach ($exempt in $script:LinkExemptDirs) {
        if ($normalizedRelPath.StartsWith($exempt)) { return $true }
    }
    return $false
}

function Test-MarkdownLinks {
    param(
        [string]$SourceFile,
        [string]$RelSource
    )
    $dir = Split-Path -Parent $SourceFile
    $failed = $false
    $lines = @(Get-Content -Path $SourceFile -ErrorAction SilentlyContinue)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = [string]$lines[$i]
        if ($line -notmatch '\]\([^)]+\.md') { continue }
        # Drop inline code spans so example links written inside backticks are ignored.
        $sanitized = [regex]::Replace($line, '`[^`]*`', '')
        $linkMatches = [regex]::Matches($sanitized, '\]\(([^)]+\.md)(#[^)]*)?\)')
        foreach ($m in $linkMatches) {
            $target = $m.Groups[1].Value
            if ($target -match '^(https?:|/|#)') { continue }
            if ($target -match '[<{$]') { continue }
            if ($target -match '^[A-Za-z]:') { continue }
            $candidate = [System.IO.Path]::GetFullPath((Join-Path $dir $target))
            if (-not (Test-Path -LiteralPath $candidate)) {
                Write-Host "  ❌ BROKEN LINK: ${RelSource}:$($i + 1)" -ForegroundColor Red
                Write-Host "     Link: $target" -ForegroundColor DarkGray
                Write-Host ""
                $script:ErrorCount++
                $failed = $true
            }
        }
    }
    return $failed
}

# Scan each file
foreach ($file in $AllMarkdownFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $lines = Get-Content -Path $file.FullName
    
    $relPath = $file.FullName.Substring($PromptKitRoot.Path.Length).TrimStart("\", "/")
    $fileHasIssues = $false
    
    # Check template references
    $templateMatches = [regex]::Matches($content, $Patterns["Template Reference"])
    foreach ($match in $templateMatches) {
        $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
        $templatePath = "templates/$($match.Groups[1].Value)"
        if (-not (Test-FileReference $file.FullName "Template" $templatePath $lineNum)) {
            $fileHasIssues = $true
        }
    }
    
    # Check workflow references
    $workflowMatches = [regex]::Matches($content, $Patterns["Workflow Reference"])
    foreach ($match in $workflowMatches) {
        $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
        $workflowPath = "workflows/$($match.Groups[1].Value)"
        if (-not (Test-FileReference $file.FullName "Workflow" $workflowPath $lineNum)) {
            $fileHasIssues = $true
        }
    }
    
    # Check protocol references
    $protocolMatches = [regex]::Matches($content, $Patterns["Protocol Reference"])
    foreach ($match in $protocolMatches) {
        $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
        $protocolPath = "protocols/$($match.Groups[1].Value)"
        if (-not (Test-FileReference $file.FullName "Protocol" $protocolPath $lineNum)) {
            $fileHasIssues = $true
        }
    }
    
    # Check relative template references
    $relTemplateMatches = [regex]::Matches($content, $Patterns["Relative Template"])
    foreach ($match in $relTemplateMatches) {
        $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
        $templatePath = "templates/$($match.Groups[1].Value)"
        if (-not (Test-FileReference $file.FullName "Template (relative)" $templatePath $lineNum)) {
            $fileHasIssues = $true
        }
    }
    
    # Warn about workflow trigger references that may be outdated
    # Capture the whole trigger token. A pattern that stops at the first hyphen
    # truncates names such as pk:init-repo to "init", which hides the real token
    # behind an unrelated alias match.
    if (-not (Test-TriggerScanExempt $relPath) -and $content -match 'pk:([a-z][a-z0-9-]*)') {
        $triggers = [regex]::Matches($content, 'pk:([a-z][a-z0-9-]*)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        foreach ($trigger in $triggers) {
            $expectedWorkflow = Join-Path $WorkflowsDir "$trigger.md"
            if (-not (Test-Path $expectedWorkflow)) {
                # Check common aliases
                $aliases = @{
                    "db" = "data.md"
                    "profile" = "perf.md"
                    "research" = "research.md"
                    "reflect" = "reflect.md"
                    "handoff" = "checkpoint.md"
                    "issue" = "tasks.md"
                    "kanban" = "tasks.md"
                    "scan" = "onboard.md"
                    "init-repo" = "onboard.md"
                    "latency" = "perf.md"
                    "grill" = "tutor.md"
                    "spike" = "research.md"
                    "retro" = "reflect.md"
                    "design" = "design-system.md"
                    "init" = "onboard.md"
                    "task" = "tasks.md"
                    "update" = "sync.md"
                    "refresh" = "sync.md"
                    # A name that is deliberately NOT a trigger. The
                    # execution-control design records reject a top-level
                    # pk:execution-control command; existing workflows retain
                    # ownership.
                    "execution-control" = "route.md"
                }
                
                if (-not $aliases.ContainsKey($trigger)) {
                    Write-Host "  ⚠️  WARNING: $relPath" -ForegroundColor Yellow
                    Write-Host "     Trigger 'pk:$trigger' may not have matching workflow" -ForegroundColor DarkGray
                    Write-Host "     Expected: workflows/$trigger.md`n" -ForegroundColor DarkGray
                    $script:WarningCount++
                }
            }
        }
    }
    
    # Generic markdown links (reader-facing 404 guard). Historical records are
    # exempt, matching the canonical-count drift guard's exemption policy.
    if (-not (Test-LinkExempt $relPath)) {
        if (Test-MarkdownLinks $file.FullName $relPath) {
            $fileHasIssues = $true
        }
    }

    if (-not $fileHasIssues) {
        Write-Host "  ✅ $relPath" -ForegroundColor Green
    }
}

# Validate template directory completeness from the filesystem inventory
Write-Host "`n📋 Checking template directory completeness..." -ForegroundColor Cyan

$ExpectedTemplateCount = 29
$TemplateInventory = @(Get-ChildItem -Path $TemplatesDir -Filter *.md -File | Sort-Object Name)

if ($TemplateInventory.Count -ne $ExpectedTemplateCount) {
    Write-Host "  ❌ MISSING templates: expected $ExpectedTemplateCount markdown templates, found $($TemplateInventory.Count)" -ForegroundColor Red
    $script:ErrorCount++
}

foreach ($template in $TemplateInventory) {
    $path = Join-Path $TemplatesDir $template.Name
    if ((Get-Item $path).Length -gt 0) {
        Write-Host "  ✅ templates/$($template.Name)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ EMPTY: templates/$($template.Name)" -ForegroundColor Red
        $script:ErrorCount++
    }
}

# Workflows: the inventory is the directory itself; ADR 0002 requires each one
# to carry a reference row in protocols/setup.md.
Write-Host "`n🔄 Checking core workflow files..." -ForegroundColor Cyan

$SetupProtocolPath = Join-Path $ProtocolsDir "setup.md"
$ExpectedWorkflowCount = 26
$WorkflowInventory = @(Get-ChildItem -Path $WorkflowsDir -Filter *.md -File | Sort-Object Name)

if ($WorkflowInventory.Count -ne $ExpectedWorkflowCount) {
    Write-Host "  ❌ MISSING workflows: expected $ExpectedWorkflowCount workflows, found $($WorkflowInventory.Count)" -ForegroundColor Red
    $script:ErrorCount++
}

foreach ($workflow in $WorkflowInventory) {
    $path = Join-Path $WorkflowsDir $workflow.Name
    if ((Get-Item $path).Length -eq 0) {
        Write-Host "  ❌ EMPTY: workflows/$($workflow.Name)" -ForegroundColor Red
        $script:ErrorCount++
        continue
    }
    if (Select-String -Path $SetupProtocolPath -SimpleMatch -Quiet -Pattern ("workflows/" + $workflow.Name)) {
        Write-Host "  ✅ workflows/$($workflow.Name)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ UNREGISTERED in protocols/setup.md: workflows/$($workflow.Name)" -ForegroundColor Red
        $script:ErrorCount++
    }
}

# Protocols: same derivation, same registration requirement, setup.md included.
Write-Host "`n📜 Checking protocol files..." -ForegroundColor Cyan

$ExpectedProtocolCount = 9
$ProtocolInventory = @(Get-ChildItem -Path $ProtocolsDir -Filter *.md -File | Sort-Object Name)

if ($ProtocolInventory.Count -ne $ExpectedProtocolCount) {
    Write-Host "  ❌ protocols/: expected $ExpectedProtocolCount protocols, found $($ProtocolInventory.Count)" -ForegroundColor Red
    $script:ErrorCount++
}

foreach ($protocol in $ProtocolInventory) {
    $path = Join-Path $ProtocolsDir $protocol.Name
    if ((Get-Item $path).Length -eq 0) {
        Write-Host "  ❌ EMPTY: protocols/$($protocol.Name)" -ForegroundColor Red
        $script:ErrorCount++
        continue
    }
    if (Select-String -Path $SetupProtocolPath -SimpleMatch -Quiet -Pattern ("protocols/" + $protocol.Name)) {
        Write-Host "  ✅ protocols/$($protocol.Name)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ UNREGISTERED in protocols/setup.md: protocols/$($protocol.Name)" -ForegroundColor Red
        $script:ErrorCount++
    }
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "📊 Validation Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

if ($script:ErrorCount -eq 0 -and $script:WarningCount -eq 0) {
    Write-Host "`n✅ All references valid! No broken links found." -ForegroundColor Green
    Write-Host "   PromptKit OS is ready for production use.`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    if ($script:ErrorCount -gt 0) {
        Write-Host "  ❌ Errors: $script:ErrorCount" -ForegroundColor Red
    }
    if ($script:WarningCount -gt 0) {
        Write-Host "  ⚠️  Warnings: $script:WarningCount" -ForegroundColor Yellow
    }
    Write-Host ""
    
    if ($script:ErrorCount -gt 0) {
        Write-Host "❌ Validation failed. Fix broken references before deployment.`n" -ForegroundColor Red
        exit 1
    } elseif ($Strict) {
        Write-Host "❌ Validation failed (strict): $script:WarningCount warning(s). Fix or justify them before deployment.`n" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "⚠️  Validation passed with warnings. Review recommended.`n" -ForegroundColor Yellow
        exit 0
    }
}
