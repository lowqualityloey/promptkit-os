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
            return $false
        }
        return $true
    }

    if (-not (Assert-Field "(?m)^name:\s+[a-zA-Z0-9_-]+" "name: <string>")) { $errors++ }
    if (-not (Assert-Field "(?m)^version:\s+[0-9]+" "version: <integer>")) { $errors++ }
    if (-not (Assert-Field "(?m)^token_budget:\s+[0-9]+" "token_budget: <integer <= 1500>")) { $errors++ }

    if ($frontmatterText -match "(?m)^token_budget:\s+([0-9]+)") {
        $declaredBudget = [int]$Matches[1]
        if ($declaredBudget -gt 1500) {
            Write-Host "[FAIL] ${fileName}: Declared token_budget ($declaredBudget) exceeds 1500 limit" -ForegroundColor Red
            $errors++
        }
    }

    $category = $null
    if ($frontmatterText -match "(?m)^category:\s+([a-zA-Z0-9_-]+)") {
        $category = $Matches[1].Trim()
    }

    if ($category -eq "recipe") {
        if (-not (Assert-Field "(?m)^description:\s+.+" "description: <string>")) { $errors++ }
    } elseif ($category -match "^(web|database|cloud|mobile|systems|cli)$") {
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
        $verificationBlock = ""
        if ($frontmatterText -match "(?ms)^verification:\r?\n(.*?)(?=^[a-zA-Z0-9_-]+:|\Z)") {
            $verificationBlock = $Matches[1]
        }
        if ($verificationBlock -match "(?m)-\s+.*(&&|\|\||;)") {
            Write-Host "[FAIL] ${fileName}: Prohibited shell composition (&&, ||, ;) found in verification arrays. Use discrete array items." -ForegroundColor Red
            $errors++
        }
    } else {
        $displayCategory = if ([string]::IsNullOrWhiteSpace($category)) { "<empty>" } else { $category }
        Write-Host "[FAIL] ${fileName}: Invalid or missing category '$displayCategory': must be 'recipe' or one of (web|database|cloud|mobile|systems|cli)" -ForegroundColor Red
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
    Write-Host "[TEST] Running Playbook & Recipe Contract Schema Self-Tests (PowerShell)..." -ForegroundColor Cyan
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tmpDir | Out-Null

    try {
        $validStackLines = @(
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
        $validStackPath = Join-Path $tmpDir "valid-stack.md"
        [System.IO.File]::WriteAllText($validStackPath, ($validStackLines -join "`n"))

        $invalidStackLines = @(
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
        $invalidStackPath = Join-Path $tmpDir "invalid-stack.md"
        [System.IO.File]::WriteAllText($invalidStackPath, ($invalidStackLines -join "`n"))

        $validRecipeLines = @(
            '---',
            'name: sample-recipe',
            'category: recipe',
            'version: 1',
            'token_budget: 1500',
            'description: Sample recipe description for self-test.',
            '---',
            '# Sample Recipe'
        )
        $validRecipePath = Join-Path $tmpDir "valid-recipe.md"
        [System.IO.File]::WriteAllText($validRecipePath, ($validRecipeLines -join "`n"))

        $invalidRecipeLines = @(
            '---',
            'name: invalid-recipe',
            'category: recipe',
            'version: 1',
            'token_budget: 2000',
            '---',
            '# Invalid Recipe'
        )
        $invalidRecipePath = Join-Path $tmpDir "invalid-recipe.md"
        [System.IO.File]::WriteAllText($invalidRecipePath, ($invalidRecipeLines -join "`n"))

        Write-Host "--- Testing Valid Stack Fixture ---"
        if (-not (Validate-SinglePlaybook -File $validStackPath)) {
            Write-Error "Schema Self-Test Failed: valid stack fixture was rejected"
        }

        Write-Host "--- Testing Invalid Stack Fixture (Should Fail) ---"
        $invalidStackPassed = Validate-SinglePlaybook -File $invalidStackPath
        if ($invalidStackPassed) {
            Write-Error "Schema Self-Test Failed: invalid stack fixture was incorrectly accepted"
        } else {
            Write-Host "[PASS] Invalid stack fixture properly caught and rejected" -ForegroundColor Green
        }

        Write-Host "--- Testing Valid Recipe Fixture ---"
        if (-not (Validate-SinglePlaybook -File $validRecipePath)) {
            Write-Error "Schema Self-Test Failed: valid recipe fixture was rejected"
        }

        Write-Host "--- Testing Invalid Recipe Fixture (Should Fail) ---"
        $invalidRecipePassed = Validate-SinglePlaybook -File $invalidRecipePath
        if ($invalidRecipePassed) {
            Write-Error "Schema Self-Test Failed: invalid recipe fixture was incorrectly accepted"
        } else {
            Write-Host "[PASS] Invalid recipe fixture properly caught and rejected" -ForegroundColor Green
        }

        Write-Host "[PASS] Playbook & Recipe Contract Schema Self-Tests PASSED" -ForegroundColor Green
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
        $files = Get-ChildItem -LiteralPath $TargetPath -Filter "*.md" -File | Where-Object { $_.Name -ne "README.md" }
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
        $files = Get-ChildItem -LiteralPath $stacksDir -Filter "*.md" -File | Where-Object { $_.Name -ne "README.md" }
        foreach ($f in $files) {
            $totalChecked++
            if (-not (Validate-SinglePlaybook -File $f.FullName)) { $totalFailed++ }
        }
    }
    $recipesDir = Join-Path $KitRoot "docs\recipes"
    if (Test-Path -LiteralPath $recipesDir -PathType Container) {
        $files = Get-ChildItem -LiteralPath $recipesDir -Filter "*.md" -File | Where-Object { $_.Name -ne "README.md" }
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
