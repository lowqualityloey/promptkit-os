# PromptKit OS Playbook Contract Validator (PowerShell)
# Validates that stack playbooks (docs/stacks/*.md) conform to the Playbook Contract:
# - Required YAML frontmatter fields (name, category, version, token_budget, activation, verification, invariants, anti_patterns)
# - Clean YAML arrays (no shell composition operators like '&&', '||', ';')
# - Strict token budget ceiling (<= 1,500 tokens using bytes/4 convention)

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$TargetPath = "",
    [switch]$TestSchema
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KitRoot = Split-Path -Parent $ScriptDir

function Validate-SinglePlaybook {
    param ([string]$File)

    $errors = 0
    $fileName = Split-Path -Leaf $File

    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Write-Host "[FAIL] ERROR: File not found: $File" -ForegroundColor Red
        return $false
    }

    $lines = Get-Content -LiteralPath $File
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne "---") {
        Write-Host "[FAIL] ${fileName}: Missing opening frontmatter delimiter (--- on line 1)" -ForegroundColor Red
        return $false
    }

    $endLine = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") {
            $endLine = $i
            break
        }
    }

    if ($endLine -le 1) {
        Write-Host "[FAIL] ${fileName}: Missing closing frontmatter delimiter (---)" -ForegroundColor Red
        return $false
    }

    $frontmatterLines = $lines[1..($endLine - 1)]
    $frontmatterText = $frontmatterLines -join "`n"

    function Assert-Field {
        param ([string]$Pattern, [string]$Description)
        if ($frontmatterText -notmatch $Pattern) {
            Write-Host "[FAIL] ${fileName}: Missing required frontmatter field: $Description" -ForegroundColor Red
            $script:errors++
        }
    }

    Assert-Field "(?m)^name:\s+[a-zA-Z0-9_-]+" "name: <string>"
    Assert-Field "(?m)^category:\s+(web|database|cloud|mobile|systems|cli)" "category: <web|database|cloud|mobile|systems|cli>"
    Assert-Field "(?m)^version:\s+[0-9]+" "version: <integer>"
    Assert-Field "(?m)^token_budget:\s+[0-9]+" "token_budget: <integer <= 1500>"

    if ($frontmatterText -notmatch "(?m)^activation:") {
        Write-Host "[FAIL] ${fileName}: Missing 'activation:' block" -ForegroundColor Red
        $errors++
    }
    if ($frontmatterText -notmatch "(?m)manifests:") {
        Write-Host "[FAIL] ${fileName}: Missing 'manifests:' array under activation" -ForegroundColor Red
        $errors++
    }

    if ($frontmatterText -notmatch "(?m)^verification:") {
        Write-Host "[FAIL] ${fileName}: Missing 'verification:' block" -ForegroundColor Red
        $errors++
    }
    if ($frontmatterText -notmatch "(?m)fast:") {
        Write-Host "[FAIL] ${fileName}: Missing 'fast:' verification tier" -ForegroundColor Red
        $errors++
    }
    if ($frontmatterText -notmatch "(?m)required:") {
        Write-Host "[FAIL] ${fileName}: Missing 'required:' verification tier" -ForegroundColor Red
        $errors++
    }
    if ($frontmatterText -notmatch "(?m)extended:") {
        Write-Host "[FAIL] ${fileName}: Missing 'extended:' verification tier" -ForegroundColor Red
        $errors++
    }

    if ($frontmatterText -notmatch "(?m)^invariants:") {
        Write-Host "[FAIL] ${fileName}: Missing 'invariants:' block" -ForegroundColor Red
        $errors++
    }
    if ($frontmatterText -notmatch "(?m)^anti_patterns:") {
        Write-Host "[FAIL] ${fileName}: Missing 'anti_patterns:' block" -ForegroundColor Red
        $errors++
    }

    # Shell composition anti-patterns in verification
    if ($frontmatterText -match "(?m)-\s+.*(&&|\|\||;)") {
        Write-Host "[FAIL] ${fileName}: Prohibited shell composition (&&, ||, ;) found in verification arrays. Use discrete array items." -ForegroundColor Red
        $errors++
    }

    # Token budget calculation
    $rawContent = [System.IO.File]::ReadAllText($File).Replace("`r`n", "`n")
    $tokens = [math]::Floor(($rawContent.Length + 2) / 4)
    if ($tokens -gt 1500) {
        Write-Host "[FAIL] ${fileName}: Exceeds token budget ($tokens tok > 1500 limit)" -ForegroundColor Red
        $errors++
    }

    if ($errors -eq 0) {
        Write-Host "[PASS] ${fileName}: PASS ($tokens tok, schema valid)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[FAIL] ${fileName}: FAILED with $errors error(s)" -ForegroundColor Red
        return $false
    }
}

if ($TestSchema) {
    Write-Host "[TEST] Running Playbook Contract Schema Self-Tests (PowerShell)..." -ForegroundColor Cyan
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tmpDir | Out-Null

    try {
        $validLines = @(
            '---',
            'name: sample-rust',
            'category: systems',
            'version: 1',
            'token_budget: 1500',
            'activation:',
            '  manifests:',
            '    - Cargo.toml',
            'verification:',
            '  fast:',
            '    - cargo check',
            '  required:',
            '    - cargo test',
            '  extended:',
            '    - cargo clippy -- -D warnings',
            'invariants:',
            '  - "Prefer borrowed references over cloning"',
            '  - "Errors must be propagated explicitly"',
            'anti_patterns:',
            '  - "Unnecessary cloning"',
            '  - "Broad unwrap usage"',
            '---',
            '# Sample Rust Stack Playbook'
        )
        $validPath = Join-Path $tmpDir "valid.md"
        [System.IO.File]::WriteAllText($validPath, ($validLines -join "`n"))

        $invalidLines = @(
            '---',
            'name: invalid-stack',
            'category: unknown-category',
            'version: 1',
            'token_budget: 2000',
            'activation:',
            '  manifests:',
            '    - package.json',
            'verification:',
            '  fast:',
            '    - pnpm tsc && pnpm lint',
            'invariants:',
            '  - "Do something"',
            'anti_patterns:',
            '  - "Avoid something"',
            '---',
            '# Invalid Stack Playbook'
        )
        $invalidPath = Join-Path $tmpDir "invalid.md"
        [System.IO.File]::WriteAllText($invalidPath, ($invalidLines -join "`n"))

        Write-Host "--- Testing Valid Fixture ---"
        if (-not (Validate-SinglePlaybook -File $validPath)) {
            Write-Error "Schema Self-Test Failed: valid fixture was rejected"
        }

        Write-Host "--- Testing Invalid Fixture (Should Fail) ---"
        $invalidPassed = Validate-SinglePlaybook -File $invalidPath
        if ($invalidPassed) {
            Write-Error "Schema Self-Test Failed: invalid fixture was incorrectly accepted"
        } else {
            Write-Host "[PASS] Invalid fixture properly caught and rejected" -ForegroundColor Green
        }

        Write-Host "[PASS] Playbook Contract Schema Self-Tests PASSED" -ForegroundColor Green
        exit 0
    }
    finally {
        Remove-Item -Recurse -Force -LiteralPath $tmpDir -ErrorAction SilentlyContinue
    }
}

$totalChecked = 0
$totalFailed = 0

if ($TargetPath) {
    if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
        $totalChecked++
        if (-not (Validate-SinglePlaybook -File $TargetPath)) { $totalFailed++ }
    } elseif (Test-Path -LiteralPath $TargetPath -PathType Container) {
        $files = Get-ChildItem -LiteralPath $TargetPath -Filter "*.md" -File
        foreach ($f in $files) {
            $totalChecked++
            if (-not (Validate-SinglePlaybook -File $f.FullName)) { $totalFailed++ }
        }
    } else {
        Write-Host "[FAIL] ERROR: Target path not found: $TargetPath" -ForegroundColor Red
        exit 1
    }
} else {
    $stacksDir = Join-Path $KitRoot "docs\stacks"
    if (Test-Path -LiteralPath $stacksDir -PathType Container) {
        $files = Get-ChildItem -LiteralPath $stacksDir -Filter "*.md" -File
        foreach ($f in $files) {
            $totalChecked++
            if (-not (Validate-SinglePlaybook -File $f.FullName)) { $totalFailed++ }
        }
    }
}

Write-Host ""
Write-Host "[SUMMARY] Playbook Contract Validation: $totalChecked checked, $totalFailed failed."
if ($totalFailed -gt 0) {
    exit 1
}
exit 0
