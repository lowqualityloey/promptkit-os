<#
.SYNOPSIS
    PromptKit OS Directive Token Measurement Utility
.DESCRIPTION
    Extracts the active PromptKit OS directive block from your agent
    instructions file (AGENTS.md, CLAUDE.md, etc.) and calculates the exact
    character, word, and estimated token counts (using industry standard 4 chars/token).
    Compares against derived monolithic baselines (core-6 subset ~19.6k; full set ~75.3k).
    In -Strict mode (CI gate parity with measure-tokens.sh), host detection is
    skipped and BOTH canonical directive templates are asserted against their
    profile budgets: Balanced <= 2,500 tokens and Lite <= 1,500 tokens.
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$TargetFile = "",

    [switch]$Strict
)

$ErrorActionPreference = "Stop"

# Single source of truth for budget constants (documented in docs/BENCHMARKS.md section 2).
$TokenBudgetBalanced = 2500
$TokenBudgetLite = 1500

if ($Strict) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $targets = @(
        @{ Name = "BALANCED"; Path = (Join-Path $ScriptDir "..\templates\agent-directive-template.md"); Budget = $TokenBudgetBalanced },
        @{ Name = "LITE"; Path = (Join-Path $ScriptDir "..\templates\agent-directive-lite-template.md"); Budget = $TokenBudgetLite }
    )
    Write-Host "`n📊 PromptKit OS Strict Token Budget Gate (bytes/4 convention)" -ForegroundColor Cyan
    $gateFail = $false
    foreach ($t in $targets) {
        if (-not (Test-Path $t.Path)) {
            Write-Host "$($t.Name)|MISSING|$($t.Budget)|FAIL" -ForegroundColor Red
            $gateFail = $true
            continue
        }
        $raw = [System.IO.File]::ReadAllText($t.Path, [System.Text.Encoding]::UTF8)
        $norm = ($raw -replace "\r\n", "`n").TrimEnd("`r", "`n")
        $bytes = [System.Text.Encoding]::UTF8.GetByteCount($norm)
        $tokens = [Math]::Floor(($bytes + 2) / 4)
        if ($tokens -le $t.Budget) {
            Write-Host "$($t.Name)|$tokens|$($t.Budget)|PASS" -ForegroundColor Green
        } else {
            Write-Host "$($t.Name)|$tokens|$($t.Budget)|FAIL (exceeds budget by $($tokens - $t.Budget) tokens)" -ForegroundColor Red
            $gateFail = $true
        }
    }
    if ($gateFail) {
        Write-Error "`n❌ Strict token budget gate FAILED. Budgets: docs/BENCHMARKS.md section 2.`n"
        exit 1
    }
    Write-Host "`n✅ Strict token budget gate passed: Balanced <= $TokenBudgetBalanced, Lite <= $TokenBudgetLite.`n" -ForegroundColor Green
    exit 0
}

Write-Host "`n📊 PromptKit OS Static Directive Token Analysis" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# 1. Discover target directive file
$Candidates = @(
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    ".cursorrules",
    ".cursor/rules/promptkit.mdc",
    ".windsurfrules",
    ".github/copilot-instructions.md",
    ".clinerules"
)

$DirectiveText = ""
$SourceDescription = ""

if ($TargetFile -ne "" -and (Test-Path $TargetFile)) {
    $FoundFile = Resolve-Path $TargetFile
    $Content = Get-Content $FoundFile -Raw
    $Pattern = '(?s)<!-- PROMPTKIT_START -->.*?<!-- PROMPTKIT_END -->'
    $Match = [regex]::Match($Content, $Pattern)
    if ($Match.Success) {
        $DirectiveText = $Match.Value
        $SourceDescription = $FoundFile
    }
} else {
    foreach ($cand in $Candidates) {
        if (Test-Path $cand) {
            $Content = Get-Content $cand -Raw
            $Pattern = '(?s)<!-- PROMPTKIT_START -->.*?<!-- PROMPTKIT_END -->'
            $Match = [regex]::Match($Content, $Pattern)
            if ($Match.Success) {
                $DirectiveText = $Match.Value
                $SourceDescription = (Resolve-Path $cand).Path
                break
            }
        }
    }
}

# Fallback to measuring the canonical template inside templates/agent-directive-template.md if running standalone
if ([string]::IsNullOrWhiteSpace($DirectiveText)) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $TemplatePath = Join-Path $ScriptDir "..\templates\agent-directive-template.md"
    if (Test-Path $TemplatePath) {
        $DirectiveText = [System.IO.File]::ReadAllText($TemplatePath, [System.Text.Encoding]::UTF8)
        $SourceDescription = "Canonical template in templates/agent-directive-template.md"
    }
}

if ([string]::IsNullOrWhiteSpace($DirectiveText)) {
    Write-Error "No PromptKit OS directive block found. Run init.ps1 first or pass a file path."
    exit 1
}
$NormalizedDirective = ($DirectiveText -replace "\r\n", "`n").TrimEnd("`r", "`n")
$LineCount = ($NormalizedDirective -split "\n").Count
$CharCount = $NormalizedDirective.Length
$WordCount = ($NormalizedDirective -split '\s+' | Where-Object { $_ -ne "" }).Count
$EstimatedTokens = [Math]::Floor(($CharCount + 2) / 4)
# Monolithic baselines derived live (issue #145 audit): core-6 subset + full set.
$KitRoot = Split-Path -Parent $PSScriptRoot
function Measure-BytesNoCR([string]$p) {
    if (-not (Test-Path $p)) { return 0 }
    [System.Text.Encoding]::UTF8.GetByteCount(((Get-Content $p -Raw) -replace "`r", ""))
}
$subsetBytes = 0
foreach ($s in @("route", "debug", "commit", "checkpoint", "sync", "profile")) { $subsetBytes += Measure-BytesNoCR (Join-Path $KitRoot "workflows\$s.md") }
$MonolithicTokens = [Math]::Floor(($subsetBytes + 2) / 4)
$fullBytes = 0
foreach ($f in (Get-ChildItem (Join-Path $KitRoot "workflows") -Filter *.md)) { $fullBytes += Measure-BytesNoCR $f.FullName }
$FullsetTokens = [Math]::Floor(($fullBytes + 2) / 4)
$SavingsPercent = [Math]::Round((1 - ($EstimatedTokens / $MonolithicTokens)) * 100, 1)

Write-Host "Target File: $SourceDescription" -ForegroundColor DarkGray
Write-Host "`nMeasurement Results:" -ForegroundColor Yellow
Write-Host "  • Lines:            $LineCount"
Write-Host "  • Characters:       $CharCount"
Write-Host "  • Words:            $WordCount"
Write-Host "  • Estimated Tokens: ~$EstimatedTokens tokens (at ~4 chars/token)" -ForegroundColor Green

Write-Host "`nToken Economics Comparison:" -ForegroundColor Yellow
Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
Write-Host "  │ Model Architecture                 Static Overhead          │" -ForegroundColor DarkGray
Write-Host "  ├─────────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
Write-Host "  │ Monolithic (core-6 subset derived)   ~$MonolithicTokens tokens           │" -ForegroundColor Red
Write-Host "  │ Monolithic (full 24-workflow set)    ~$FullsetTokens tokens           │" -ForegroundColor Red
Write-Host "  │ PromptKit OS JIT Router            ~$EstimatedTokens tokens (measured)      │" -ForegroundColor Green
Write-Host "  ├─────────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
Write-Host "  │ Static Context Reduction:          $SavingsPercent% reduction             │" -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray

# Profile-aware budget: the Lite template is asserted against the Lite budget;
# everything else against the Balanced budget.
$TokenBudget = $TokenBudgetBalanced
$BudgetProfile = "Balanced"
if ($TargetFile -match "agent-directive-lite-template\.md$") {
    $TokenBudget = $TokenBudgetLite
    $BudgetProfile = "Lite"
}

Write-Host "`nBudget Assertion Verification:" -ForegroundColor Yellow
Write-Host "  • Profile:                $BudgetProfile"
Write-Host "  • Configured Token Budget:  $TokenBudget tokens"
Write-Host "  • Measured Estimate:        $EstimatedTokens tokens"

if ($EstimatedTokens -le $TokenBudget) {
    Write-Host "`n✅ Verification Passed: Directive ($EstimatedTokens tokens) adheres to the <= $TokenBudget token budget.`n" -ForegroundColor Green
} else {
    Write-Error "`n❌ Verification Failed: Directive ($EstimatedTokens tokens) exceeds the $TokenBudget token budget by $($EstimatedTokens - $TokenBudget) tokens.`n"
    exit 1
}
