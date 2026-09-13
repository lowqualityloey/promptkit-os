<#
.SYNOPSIS
    PromptKit OS Directive Token Measurement Utility
.DESCRIPTION
    Extracts the active PromptKit OS directive block from your agent
    instructions file (AGENTS.md, CLAUDE.md, etc.) and calculates the exact
    character, word, and estimated token counts (using industry standard 4 chars/token).
    Compares against typical monolithic AI prompt packs (~18,500 tokens).
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$TargetFile = ""
)

$ErrorActionPreference = "Stop"

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
$MonolithicTokens = 18500
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
Write-Host "  │ Monolithic Prompt Packs            ~18,500 tokens           │" -ForegroundColor Red
Write-Host "  │ PromptKit OS JIT Router            ~$EstimatedTokens tokens (measured)      │" -ForegroundColor Green
Write-Host "  ├─────────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
Write-Host "  │ Static Context Reduction:          $SavingsPercent% reduction             │" -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray

$TokenBudget = 2500
Write-Host "`nBudget Assertion Verification:" -ForegroundColor Yellow
Write-Host "  • Configured Token Budget:  $TokenBudget tokens"
Write-Host "  • Measured Estimate:        $EstimatedTokens tokens"

if ($EstimatedTokens -le $TokenBudget) {
    Write-Host "`n✅ Verification Passed: Directive ($EstimatedTokens tokens) adheres to the <= $TokenBudget token budget.`n" -ForegroundColor Green
} else {
    Write-Error "`n❌ Verification Failed: Directive ($EstimatedTokens tokens) exceeds the $TokenBudget token budget by $($EstimatedTokens - $TokenBudget) tokens.`n"
    exit 1
}
