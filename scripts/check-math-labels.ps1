# Math label guard: reject backslash-escaped underscores inside \text{...}.
# Usage: scripts\check-math-labels.ps1 [-Root PATH]
# Why: `\_` is a markdown backslash escape. Renderers that resolve markdown
# escapes before handing math to KaTeX deliver a bare `_` into \text{} (text
# mode), which KaTeX rejects with "`_` allowed only in math mode". Observed on
# GitHub for docs/BENCHMARK-METHODOLOGY.md. Use hyphens in \text{} labels.
# Scans every *.md under the root recursively; historical records are exempt
# by class (dated evidence, like other sweeps).
# Limitation: detects \text{ and a later \_ on the same line only.

param(
    [string]$Root = "."
)

if (-not (Test-Path -LiteralPath $Root)) {
    Write-Host "MATH_LABEL_GATE|MISSING_ROOT|Repository root does not exist|Provide a valid -Root path"
    exit 1
}

$findings = @()
foreach ($file in (Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue)) {
    $path = $file.FullName
    if ($path -match '[\\/]\.git[\\/]') { continue }
    $exempt = ($path -match 'docs[\\/]releases[\\/]') -or ($path -match 'docs[\\/]archive[\\/]') `
        -or ($path -match 'docs[\\/]internal[\\/]') -or ($path -match 'docs[\\/]tasks[\\/]') `
        -or ($file.Name -eq 'CHANGELOG.md')
    if ($exempt) { continue }
    $lines = @(Get-Content -LiteralPath $path)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $idx = $lines[$i].IndexOf('\text{')
        if ($idx -lt 0) { continue }
        $rest = $lines[$i].Substring($idx)
        if ($rest.Contains('\_')) {
            $findings += ("{0}:{1}:{2}" -f $path, ($i + 1), $lines[$i])
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
