# Reference-link regression harness (PowerShell): mirrors
# run-reference-link-tests.sh, proving validate-references.ps1 resolves
# reader-facing markdown links, honors historical exemptions, skips placeholders
# and inline code examples, and fails closed on a broken link.
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-reference-link-tests.ps1

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$Validator = Join-Path $RepoRoot "scripts/validate-references.ps1"

$script:PassCount = 0
$script:FailCount = 0
$FixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pk-ref-links-" + [System.Guid]::NewGuid().ToString("N"))

Write-Host "`n🔗 Running validate-references Link-Resolution Tests (PowerShell)" -ForegroundColor Cyan
Write-Host "==========================================================="

try {
    New-Item -ItemType Directory -Path $FixtureRoot -Force | Out-Null

    # Seed the fixture root with the real content directories so the validator's
    # completeness checks pass and only link resolution is under test.
    foreach ($dir in @("workflows", "protocols", "templates", "activities")) {
        Copy-Item -Path (Join-Path $RepoRoot $dir) -Destination (Join-Path $FixtureRoot $dir) -Recurse -Force
    }

    # Minimal stubs for the cross-tree targets the copied workflow files link to.
    foreach ($sub in @("docs/adrs", "docs/internal", "docs/recipes", "docs/stacks", "docs/archive", "notes")) {
        New-Item -ItemType Directory -Path (Join-Path $FixtureRoot $sub) -Force | Out-Null
    }
    $stubs = @(
        "docs/BENCHMARKS.md", "docs/TURBO-WAVES-GUIDE.md", "docs/WORKFLOW-MAP.md", "docs/MAXIMS.md",
        "docs/adrs/0002-workflow-lifecycle-policy.md", "docs/internal/release-evaluation.md",
        "docs/recipes/auto-phrase-boundary-sheet.md", "docs/recipes/auto-wave-pause-resume.md",
        "docs/recipes/auto-waves-preflight-checklist.md", "docs/recipes/websocket-realtime.md", "docs/recipes/state-management.md",
        "docs/stacks/mobile-kmp.md", "docs/stacks/systems-java-spring.md", "docs/stacks/systems-csharp-dotnet.md",
        "docs/stacks/database-postgres.md", "docs/stacks/database-mysql.md", "docs/stacks/deploy-aws.md", "docs/stacks/deploy-gcp.md",
        "notes/learning-plan.md", "notes/progress-journal.md", "notes/skill-matrix.md"
    )
    foreach ($stub in $stubs) {
        Set-Content -Path (Join-Path $FixtureRoot $stub) -Value "# Fixture stub" -NoNewline
    }

    function Invoke-Case {
        param(
            [string]$Description,
            [string]$Expectation,
            [string]$Token
        )
        $output = & pwsh -NoProfile -File $Validator $FixtureRoot 2>&1 | Out-String
        $status = $LASTEXITCODE

        if ($Expectation -eq "fail") {
            if (($status -ne 0) -and ($output -match [regex]::Escape($Token))) {
                Write-Host "  ✅ PASS: $Description" -ForegroundColor Green
                $script:PassCount++
            } else {
                Write-Host "  ❌ FAIL: $Description (exit=$status, token '$Token' not reported)" -ForegroundColor Red
                $script:FailCount++
            }
        } else {
            if ($status -eq 0) {
                Write-Host "  ✅ PASS: $Description" -ForegroundColor Green
                $script:PassCount++
            } else {
                Write-Host "  ❌ FAIL: $Description (exit=$status)" -ForegroundColor Red
                $script:FailCount++
                ($output -split "`n" | Where-Object { $_ -match "BROKEN|MISSING" } | Select-Object -First 5) | ForEach-Object { Write-Host "    $_" }
            }
        }
    }

    $fixtureFile = Join-Path $FixtureRoot "docs/link-fixture.md"
    $historicFile = Join-Path $FixtureRoot "docs/archive/historic-fixture.md"

    # Case 1: root-relative link in docs/ (the pre-fix MAXIMS class) must fail.
    Set-Content -Path $fixtureFile -Value "# Link Fixture`n`n- Root-relative link: [route](workflows/route.md)"
    Invoke-Case "Root-relative docs link fails closed" "fail" "BROKEN LINK"

    # Case 2: same link written relative to the source file must pass.
    Set-Content -Path $fixtureFile -Value "# Link Fixture`n`n- Resolved link: [route](../workflows/route.md)"
    Invoke-Case "Relative ../ link resolves" "pass" ""

    # Case 3: broken link inside an inline code span is illustrative, not a target.
    Set-Content -Path $fixtureFile -Value "# Link Fixture`n`nFor example, ``[CHECK-123](../tests/checks.md#CHECK-123)`` is stronger than a bare claim."
    Invoke-Case "Inline code example is ignored" "pass" ""

    # Case 4: placeholder target is skipped.
    Set-Content -Path $fixtureFile -Value "# Link Fixture`n`n- Report path: [review](../reviews/<review-slug>.md)"
    Invoke-Case "Placeholder link target is skipped" "pass" ""

    # Case 5: historical records are exempt (same policy as the count drift guard).
    Set-Content -Path $historicFile -Value "# Historic Fixture`n`n- Legacy link: [gone](../tasks/TASK-1999-01-01-removed.md)"
    Remove-Item -Path $fixtureFile -Force
    Invoke-Case "Historical record exempt from link resolution" "pass" ""

    # Case 6: external and anchor-only targets are skipped.
    Remove-Item -Path $historicFile -Force
    Set-Content -Path $fixtureFile -Value "# Link Fixture`n`n- Absolute target: [site](https://example.com/docs/page.md)`n- Anchor-only target: [top](#link-fixture)"
    Invoke-Case "External and anchor-only targets are skipped" "pass" ""

    Write-Host "`n==========================================================="
    Write-Host "Reference-Link Harness Summary"
    Write-Host "Passed: $script:PassCount | Failed: $script:FailCount"
    Write-Host "==========================================================="

    if ($script:FailCount -gt 0) {
        Write-Host "❌ Reference-link harness failed.`n" -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ All reference-link tests passed successfully!`n" -ForegroundColor Green
    exit 0
} finally {
    if (Test-Path $FixtureRoot) {
        Remove-Item -Path $FixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
