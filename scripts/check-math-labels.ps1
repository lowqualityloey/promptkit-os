# Math label guard: reject backslash-escaped underscores inside \text{...}.
# Usage: scripts\check-math-labels.ps1 [-Root PATH]
# Why: `\_` is a markdown backslash escape. Renderers that resolve markdown
# escapes before handing math to KaTeX deliver a bare `_` into \text{} (text
# mode), which KaTeX rejects with "`_` allowed only in math mode". Observed on
# GitHub for docs/BENCHMARK-METHODOLOGY.md. Use hyphens in \text{} labels.
# Scope: git-tracked plus untracked-but-not-ignored *.md files when the root is
# a git work tree, so a local run and a CI run see the same set; otherwise
# every *.md under the root recursively. Historical records are exempt by class
# (dated evidence, like other sweeps).
# Limitation: detects \text{ and a later \_ on the same line only.

param(
    [string]$Root = "."
)

$ErrorActionPreference = 'Continue'

if (-not (Test-Path -LiteralPath $Root)) {
    Write-Host "MATH_LABEL_GATE|MISSING_ROOT|Repository root does not exist|Provide a valid -Root path"
    exit 1
}

try {
    $RootAbs = (Resolve-Path -LiteralPath $Root).ProviderPath
} catch {
    Write-Host "MATH_LABEL_GATE|MISSING_ROOT|Repository root is not readable|Provide a valid -Root path"
    exit 1
}

$relativePaths = New-Object System.Collections.Generic.List[string]
$scopeMode = 'scan'

$gitDir = Join-Path $RootAbs '.git'
$gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
if ((Test-Path -LiteralPath $gitDir) -and $gitAvailable) {
    $env:GIT_OPTIONAL_LOCKS = '0'
    $listed = @(& git -C $RootAbs -c core.fsmonitor=false -c core.quotepath=false `
        ls-files --cached --others --exclude-standard -- '*.md' 2>$null)
    $gitExit = $LASTEXITCODE
    Remove-Item Env:\GIT_OPTIONAL_LOCKS -ErrorAction SilentlyContinue
    if ($gitExit -eq 0) {
        $scopeMode = 'git'
        foreach ($rel in $listed) {
            if ([string]::IsNullOrWhiteSpace($rel)) { continue }
            $candidate = Join-Path $RootAbs $rel
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { $relativePaths.Add($rel) }
        }
    }
}

if ($scopeMode -eq 'scan') {
    foreach ($file in (Get-ChildItem -LiteralPath $RootAbs -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue)) {
        $full = $file.FullName
        if ($full -match '[\\/]\.git[\\/]') { continue }
        $relativePaths.Add($full.Substring($RootAbs.Length).TrimStart('\', '/'))
    }
}

Write-Host ("MATH_LABEL_GATE|SCOPE|mode={0}|files={1}" -f $scopeMode, $relativePaths.Count)

$findings = @()
foreach ($rel in $relativePaths) {
    $exempt = ($rel -match '(^|/)docs/releases/') -or ($rel -match '(^|/)docs/archive/') `
        -or ($rel -match '(^|/)docs/internal/') -or ($rel -match '(^|/)docs/tasks/') `
        -or ($rel -match '(^|/)CHANGELOG\.md$')
    if ($exempt) { continue }
    $path = Join-Path $RootAbs $rel
    $lines = @(Get-Content -LiteralPath $path -ErrorAction SilentlyContinue)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $idx = $lines[$i].IndexOf('\text{')
        if ($idx -lt 0) { continue }
        $rest = $lines[$i].Substring($idx)
        if ($rest.Contains('\_')) {
            $findings += ("{0}:{1}:{2}" -f $rel, ($i + 1), $lines[$i])
        }
    }
}

if ($findings.Count -gt 0) {
    Write-Host "MATH_LABEL_GATE|FAIL|backslash-escaped underscore inside \text{} label:"
    foreach ($f in $findings) { Write-Host "  - $f" }
    Write-Host 'MATH_LABEL_GATE|REMEDIATION|Use a hyphen or space in \text{} labels (e.g. \text{dev-hourly}); \_ is a markdown escape and breaks text-mode math on some renderers'
    exit 1
}

Write-Host 'MATH_LABEL_GATE|PASS|no fragile \_ inside \text{} labels'
exit 0
