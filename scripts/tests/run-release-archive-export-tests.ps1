#!/usr/bin/env pwsh
# Release-archive export fixture (issue #787) - PowerShell twin.
#
# Extracts `git archive HEAD` - which honours the .gitattributes export-ignore
# rules - and asserts the consumer contract of the extracted archive through
# init.ps1 and the PowerShell checkers: excluded trees absent, >80% slimming,
# no shipped relative link into an excluded tree, and a healthy install.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "../..")).Path
$TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("promptkit-archive-export-" + [guid]::NewGuid().ToString("N"))
$Kit = Join-Path $TempRoot "kit"
$Project = Join-Path $TempRoot "project"
New-Item -ItemType Directory -Path $Kit, $Project -Force | Out-Null
$script:Pass = 0
$script:Fail = 0
function Pass([string]$Message) { $script:Pass++; Write-Host "PASS|$Message" }
function Fail([string]$Message) { $script:Fail++; Write-Host "FAIL|$Message" -ForegroundColor Red }

$HostExe = (Get-Process -Id $PID).Path
if (-not $HostExe) { $HostExe = "pwsh" }

try {
    $Archive = Join-Path $TempRoot "kit.zip"
    & git -C $RepoRoot archive --format=zip -o $Archive HEAD
    if ($LASTEXITCODE -ne 0) { throw "git archive failed with exit code $LASTEXITCODE" }
    Expand-Archive -LiteralPath $Archive -DestinationPath $Kit -Force

    $Excluded = @("benchmarks", "docs/internal", "docs/releases", "docs/tasks", "docs/reviews", "docs/archive", "docs/tests", "scripts/tests", ".github")
    foreach ($Path in $Excluded) {
        if (Test-Path -LiteralPath (Join-Path $Kit $Path)) {
            Fail "excluded tree present in the archive: $Path"
        } else {
            Pass "excluded from the archive: $Path"
        }
    }
    if (Test-Path -LiteralPath (Join-Path $Kit ".gitattributes")) {
        Fail "the archive carries .gitattributes"
    } else {
        Pass "excluded from the archive: .gitattributes"
    }

    foreach ($Path in @("init.sh", "init.ps1", "PROMPTKIT.md", "README.md", "QUICKSTART.md", "FAQ.md", "LICENSE", "SECURITY.md")) {
        if (Test-Path -LiteralPath (Join-Path $Kit $Path) -PathType Leaf) {
            Pass "consumer path retained: $Path"
        } else {
            Fail "consumer path missing from the archive: $Path"
        }
    }
    foreach ($Path in @("workflows", "protocols", "templates", "package", "docs/stacks", "docs/recipes", "docs/adrs")) {
        if (Test-Path -LiteralPath (Join-Path $Kit $Path) -PathType Container) {
            Pass "consumer directory retained: $Path"
        } else {
            Fail "consumer directory missing from the archive: $Path"
        }
    }

    $Tracked = @(& git -C $RepoRoot ls-tree -r --name-only HEAD).Count
    $Extracted = @(Get-ChildItem -LiteralPath $Kit -Force -Recurse -File).Count
    if ($Extracted -gt [math]::Floor($Tracked / 5)) {
        Fail "archive reduction is below 80%: extracted=$Extracted tracked=$Tracked"
    } else {
        Pass "archive reduction above 80%: extracted=$Extracted tracked=$Tracked"
    }

    $Bad = New-Object System.Collections.Generic.List[string]
    Get-ChildItem -LiteralPath $Kit -Force -Recurse -File -Filter *.md | ForEach-Object {
        $Full = $_.FullName
        $Rel = $Full.Substring($Kit.Length + 1).Replace('\', '/')
        $Text = Get-Content -LiteralPath $Full -Raw
        foreach ($Match in [regex]::Matches($Text, '\]\(([^)\s]+)')) {
            $Target = $Match.Groups[1].Value.Split('#')[0]
            if (-not $Target -or $Target.StartsWith('/') -or $Target -match '^[A-Za-z][A-Za-z0-9+.-]*:') { continue }
            $Resolved = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $Full) $Target))
            if (-not $Resolved.StartsWith($Kit, [StringComparison]::OrdinalIgnoreCase)) { continue }
            $RelTarget = $Resolved.Substring($Kit.Length + 1).Replace('\', '/')
            foreach ($Entry in $Excluded) {
                if ($RelTarget -eq $Entry -or $RelTarget.StartsWith("$Entry/")) { $Bad.Add("$Rel -> $Target") }
            }
        }
    }
    if ($Bad.Count -eq 0) {
        Pass "no shipped relative link targets an excluded tree"
    } else {
        foreach ($Entry in $Bad) { Fail "relative link targets an excluded tree: $Entry" }
    }

    Copy-Item -LiteralPath $Kit -Destination (Join-Path $Project ".promptkit") -Recurse
    $env:PROMPTKIT_NO_INTERACTIVE = "1"
    $InitLog = Join-Path $TempRoot "init.log"
    Push-Location $Project
    try {
        & $HostExe -NoProfile -File (Join-Path $Project ".promptkit/init.ps1") -TargetDir $Project -Hosts agents -Balanced *> $InitLog
    } finally {
        Pop-Location
    }
    if ($LASTEXITCODE -eq 0) {
        Pass "init.ps1 installed the extracted archive"
    } else {
        Fail "init.ps1 failed against the extracted archive"
        Get-Content -LiteralPath $InitLog -TotalCount 40 | Write-Host
    }

    $AssertLog = Join-Path $TempRoot "assert.log"
    & $HostExe -NoProfile -File (Join-Path $Project ".promptkit/scripts/check-setup-assert.ps1") -ProjectRoot $Project -KitDir (Join-Path $Project ".promptkit") -KitDirRel ".promptkit" *> $AssertLog
    if ($LASTEXITCODE -eq 0) {
        Pass "check-setup-assert.ps1 passed inside the extracted tree"
    } else {
        Fail "check-setup-assert.ps1 failed inside the extracted tree"
        Get-Content -LiteralPath $AssertLog -TotalCount 40 | Write-Host
    }
    if (Select-String -LiteralPath $AssertLog -Pattern '^ASSERT\|[^|]+\|tree\|OK' -Quiet) {
        Pass "check-setup-assert.ps1 classified the install door and its tree as OK"
    } else {
        Fail "check-setup-assert.ps1 did not report a passing install door"
    }

    $DoctorLog = Join-Path $TempRoot "doctor.log"
    & $HostExe -NoProfile -File (Join-Path $Project ".promptkit/scripts/check-doctor.ps1") -KitRoot $Project *> $DoctorLog
    if ($LASTEXITCODE -eq 0) {
        Pass "check-doctor.ps1 reported a healthy install"
    } else {
        Fail "check-doctor.ps1 reported an unhealthy install"
        Get-Content -LiteralPath $DoctorLog -TotalCount 40 | Write-Host
    }

    $RefsLog = Join-Path $TempRoot "references.log"
    & $HostExe -NoProfile -File (Join-Path $Project ".promptkit/scripts/validate-references.ps1") -PromptKitDir (Join-Path $Project ".promptkit") -Strict *> $RefsLog
    if ($LASTEXITCODE -eq 0) {
        Pass "validate-references.ps1 -Strict passed inside the extracted tree"
    } else {
        Fail "validate-references.ps1 -Strict failed inside the extracted tree"
        Get-Content -LiteralPath $RefsLog -TotalCount 40 | Write-Host
    }
} finally {
    Remove-Item Env:PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $TempRoot) { [IO.Directory]::Delete($TempRoot, $true) }
}

Write-Host "SUMMARY|passed=$Pass|failed=$Fail"
if ($Fail -ne 0) { exit 1 }