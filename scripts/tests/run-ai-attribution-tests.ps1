# Regression harness for the AI-attribution policy (issue #554) — PowerShell twin.
# Mirrors run-ai-attribution-tests.sh: detector gating and the commit-msg hook.
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-ai-attribution-tests.ps1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd('\', '/')
$detector = Join-Path $repoRoot 'scripts/check-ai-attribution.ps1'
$hookInstaller = Join-Path $repoRoot 'scripts/install-attribution-hook.ps1'
$utf8 = [Text.UTF8Encoding]::new($false)

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('pk-ai-attr-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$script:PASS = 0
$script:FAIL = 0
$script:SCENARIO_OK = $true
$script:STATUS = 0
$script:OUT = ''

function Write-Pass { param([string]$Label) Write-Output "PASS: $Label"; $script:PASS++ }
function Write-Fail { param([string]$Label) Write-Output "FAIL: $Label"; $script:FAIL++ }
function Begin-Scenario { $script:SCENARIO_OK = $true }
function Report-Scenario { param([string]$Label) if ($script:SCENARIO_OK) { Write-Pass $Label } else { Write-Fail $Label } }
function Assert-Scenario { param([bool]$Condition, [string]$Description) if (-not $Condition) { Write-Output "  - $Description"; $script:SCENARIO_OK = $false } }

function Invoke-Det {
    param([string[]]$ExtraArgs = @())
    $raw = @(& pwsh -NoProfile -File $detector @ExtraArgs 2>&1)
    $script:STATUS = $LASTEXITCODE
    $script:OUT = ((@($raw | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '')
}

function New-Repo {
    param([string]$Name, [string]$Pref)
    $dir = Join-Path $tmp $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    & git -C $dir init -q | Out-Null
    & git -C $dir config user.name Fixture | Out-Null
    & git -C $dir config user.email fixture@example.invalid | Out-Null
    $profile = if ([string]::IsNullOrEmpty($Pref)) { "profile: balanced`n" } else { "profile: balanced`nai-attribution: $Pref`n" }
    [IO.File]::WriteAllText((Join-Path $dir 'PROMPTKIT.md'), $profile, $utf8)
    [IO.File]::WriteAllText((Join-Path $dir 'f.txt'), "x`n", $utf8)
    & git -C $dir add -A | Out-Null
    & git -C $dir commit -qm base | Out-Null
    return $dir
}

try {
    # D1: host-default (missing) never newly blocks.
    Begin-Scenario
    $rootD1 = New-Repo 'd1' ''
    $d1msg = Join-Path $tmp 'd1.txt'
    [IO.File]::WriteAllText($d1msg, "feat: x`n`nCo-authored-by: Claude <n@x>`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD1, '-MessageFile', $d1msg)
    Assert-Scenario ($script:STATUS -eq 0) "expected exit 0, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|SKIP|host-default')) 'missing host-default SKIP'
    Report-Scenario 'D1 host-default/missing preference never newly blocks'

    # D2: off + AI trailer is prohibited with diagnostics.
    Begin-Scenario
    $rootD2 = New-Repo 'd2' 'off'
    $d2msg = Join-Path $tmp 'd2.txt'
    [IO.File]::WriteAllText($d2msg, "feat: x`n`nCo-authored-by: Claude <n@x>`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD2, '-MessageFile', $d2msg)
    Assert-Scenario ($script:STATUS -eq 1) "expected exit 1, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|PROHIBITED|COAUTHORED_AI_CLAUDE|trailer')) 'missing rule diagnostic'
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|REMEDIATION|')) 'missing remediation'
    Report-Scenario 'D2 off: AI co-author trailer prohibited with diagnostics'

    # D3: off + AI promotional footer is prohibited.
    Begin-Scenario
    $rootD3 = New-Repo 'd3' 'off'
    $d3body = Join-Path $tmp 'd3.md'
    [IO.File]::WriteAllText($d3body, "## Summary`n`nGenerated with Claude Code`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD3, '-BodyFile', $d3body)
    Assert-Scenario ($script:STATUS -eq 1) "expected exit 1, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|PROHIBITED|GENERATED_WITH_CLAUDE|footer')) 'missing footer rule'
    Report-Scenario 'D3 off: AI promotional footer prohibited'

    # D4: human co-authors and ordinary discussion stay intact.
    Begin-Scenario
    $rootD4 = New-Repo 'd4' 'off'
    $d4human = Join-Path $tmp 'd4human.txt'
    [IO.File]::WriteAllText($d4human, "feat: x`n`nCo-authored-by: Jane Doe <jane@example.com>`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD4, '-MessageFile', $d4human)
    Assert-Scenario ($script:STATUS -eq 0) "human co-author was blocked (exit $($script:STATUS))"
    $d4disc = Join-Path $tmp 'd4disc.md'
    [IO.File]::WriteAllText($d4disc, "This PR discusses how Co-authored-by: trailers and AI tools are used.`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD4, '-BodyFile', $d4disc)
    Assert-Scenario ($script:STATUS -eq 0) "ordinary discussion was blocked (exit $($script:STATUS))"
    Report-Scenario 'D4 human co-authors and ordinary discussion preserved'

    # D5: malformed rules and missing payload fail closed.
    Begin-Scenario
    $rootD5 = New-Repo 'd5' 'off'
    $d5bad = Join-Path $tmp 'd5-bad.txt'
    [IO.File]::WriteAllText($d5bad, "BADROW`n", $utf8)
    $d5msg = Join-Path $tmp 'd5.txt'
    [IO.File]::WriteAllText($d5msg, "feat: x`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD5, '-RulesFile', $d5bad, '-MessageFile', $d5msg)
    Assert-Scenario ($script:STATUS -eq 2) "malformed rules expected exit 2, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|INCOMPLETE|RULES')) 'missing RULES INCOMPLETE'
    Invoke-Det -ExtraArgs @('-Root', $rootD5, '-MessageFile', (Join-Path $tmp 'd5-missing.txt'))
    Assert-Scenario ($script:STATUS -eq 2) "missing payload expected exit 2, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|INCOMPLETE|PAYLOAD')) 'missing PAYLOAD INCOMPLETE'
    Report-Scenario 'D5 malformed rules and missing payload fail closed'

    # H1: install blocks an AI-trailer commit.
    Begin-Scenario
    $rootH1 = New-Repo 'h1' 'off'
    & pwsh -NoProfile -File $hookInstaller -Root $rootH1 | Out-Null
    $h1hook = Join-Path $rootH1 '.git/hooks/commit-msg'
    Assert-Scenario (@(Get-Content -LiteralPath $h1hook | Where-Object { $_ -ceq '# >>> PROMPTKIT_AI_ATTRIBUTION >>>' }).Count -eq 1) 'managed block not installed'
    $h1before = ((& git -C $rootH1 rev-parse HEAD | Out-String)).Trim()
    [IO.File]::WriteAllText((Join-Path $rootH1 'f.txt'), "y`n", $utf8)
    & git -C $rootH1 add f.txt | Out-Null
    & git -C $rootH1 commit -qm 'feat: change' -m 'Co-authored-by: Claude <n@x>' 2>&1 | Out-Null
    $h1after = ((& git -C $rootH1 rev-parse HEAD | Out-String)).Trim()
    Assert-Scenario ($h1before -eq $h1after) 'AI trailer commit was not blocked'
    Report-Scenario 'H1 install blocks an AI-trailer commit'

    # H2: human co-author commit passes.
    Begin-Scenario
    $rootH2 = New-Repo 'h2' 'off'
    & pwsh -NoProfile -File $hookInstaller -Root $rootH2 | Out-Null
    [IO.File]::WriteAllText((Join-Path $rootH2 'f.txt'), "y`n", $utf8)
    & git -C $rootH2 add f.txt | Out-Null
    & git -C $rootH2 commit -qm 'feat: change' -m 'Co-authored-by: Jane <jane@example.com>' 2>&1 | Out-Null
    $h2subj = ((& git -C $rootH2 log -1 --format=%s | Out-String)).Trim()
    Assert-Scenario ($h2subj -eq 'feat: change') 'human co-author commit did not land'
    Report-Scenario 'H2 human co-author commit passes the hook'

    # H3: pre-existing hook body preserved and chained.
    Begin-Scenario
    $rootH3 = New-Repo 'h3' 'off'
    New-Item -ItemType Directory -Path (Join-Path $rootH3 '.git/hooks') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $rootH3 '.git/hooks/commit-msg'), "#!/bin/sh`ntouch `"`$(git rev-parse --show-toplevel)/.existing-hook-ran`"`nexit 0`n", $utf8)
    & pwsh -NoProfile -File $hookInstaller -Root $rootH3 | Out-Null
    $h3content = Get-Content -LiteralPath (Join-Path $rootH3 '.git/hooks/commit-msg') -Raw
    Assert-Scenario ($h3content.Contains('existing-hook-ran')) 'pre-existing hook body was dropped'
    [IO.File]::WriteAllText((Join-Path $rootH3 'f.txt'), "y`n", $utf8)
    & git -C $rootH3 add f.txt | Out-Null
    & git -C $rootH3 commit -qm 'feat: change' -m 'Co-authored-by: Jane <jane@example.com>' 2>&1 | Out-Null
    Assert-Scenario (Test-Path -LiteralPath (Join-Path $rootH3 '.existing-hook-ran')) 'pre-existing hook did not run'
    Report-Scenario 'H3 pre-existing hook preserved and chained'

    # H4: idempotent install; remove strips only the block.
    Begin-Scenario
    $rootH4 = New-Repo 'h4' 'off'
    New-Item -ItemType Directory -Path (Join-Path $rootH4 '.git/hooks') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $rootH4 '.git/hooks/commit-msg'), "#!/bin/sh`n# keep-me`nexit 0`n", $utf8)
    & pwsh -NoProfile -File $hookInstaller -Root $rootH4 | Out-Null
    & pwsh -NoProfile -File $hookInstaller -Root $rootH4 | Out-Null
    $h4content = Get-Content -LiteralPath (Join-Path $rootH4 '.git/hooks/commit-msg') -Raw
    Assert-Scenario (@(Get-Content -LiteralPath (Join-Path $rootH4 '.git/hooks/commit-msg') | Where-Object { $_ -ceq '# >>> PROMPTKIT_AI_ATTRIBUTION >>>' }).Count -eq 1) 're-install did not stay single-block'
    & pwsh -NoProfile -File $hookInstaller -Root $rootH4 -Remove | Out-Null
    $h4after = Get-Content -LiteralPath (Join-Path $rootH4 '.git/hooks/commit-msg') -Raw
    Assert-Scenario ($h4after.Contains('keep-me')) 'remove dropped pre-existing content'
    Assert-Scenario (-not $h4after.Contains('# >>> PROMPTKIT_AI_ATTRIBUTION >>>')) 'remove left the managed block'
    Report-Scenario 'H4 idempotent install; remove strips only the block'

    # D6: an invalid-regex rules row fails closed; a multi-MB payload with a
    # leading AI trailer is still prohibited.
    Begin-Scenario
    $rootD6 = New-Repo 'd6' 'off'
    $d6bad = Join-Path $tmp 'd6-badrules.txt'
    [IO.File]::WriteAllText($d6bad, "BADREGEX|[|trailer`n", $utf8)
    $d6msg = Join-Path $tmp 'd6.txt'
    [IO.File]::WriteAllText($d6msg, "feat: x`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD6, '-RulesFile', $d6bad, '-MessageFile', $d6msg)
    Assert-Scenario ($script:STATUS -eq 2) "invalid regex expected exit 2, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|INCOMPLETE|RULES')) 'invalid regex did not fail closed as RULES'
    $d6big = Join-Path $tmp 'd6-big.txt'
    [IO.File]::WriteAllText($d6big, ("Co-authored-by: Claude <n@x>`n" + ('a' * 3000000) + "`n"), $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD6, '-MessageFile', $d6big)
    Assert-Scenario ($script:STATUS -eq 1) "multi-MB payload expected exit 1, got $($script:STATUS)"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|PROHIBITED|COAUTHORED_AI_CLAUDE|trailer')) 'multi-MB payload did not report the leading AI trailer'
    Report-Scenario 'D6 invalid regex fails closed; multi-MB payload prohibited'

    # D7: a human "Claude Martin" co-author passes; bot trailers stay prohibited.
    Begin-Scenario
    $rootD7 = New-Repo 'd7' 'off'
    $d7human = Join-Path $tmp 'd7-human.txt'
    [IO.File]::WriteAllText($d7human, "feat: x`n`nCo-authored-by: Claude Martin <martin@example.com>`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD7, '-MessageFile', $d7human)
    Assert-Scenario ($script:STATUS -eq 0) "human Claude Martin was blocked (exit $($script:STATUS))"
    $d7bot = Join-Path $tmp 'd7-bot.txt'
    [IO.File]::WriteAllText($d7bot, "feat: x`n`nCo-authored-by: Claude <n@x>`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD7, '-MessageFile', $d7bot)
    Assert-Scenario ($script:STATUS -eq 1) "bot Claude trailer was not prohibited (exit $($script:STATUS))"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|PROHIBITED|COAUTHORED_AI_CLAUDE|trailer')) 'missing COAUTHORED_AI_CLAUDE rule'
    $d7code = Join-Path $tmp 'd7-code.txt'
    [IO.File]::WriteAllText($d7code, "feat: x`n`nCo-authored-by: Claude Code <n@x>`n", $utf8)
    Invoke-Det -ExtraArgs @('-Root', $rootD7, '-MessageFile', $d7code)
    Assert-Scenario ($script:STATUS -eq 1) "Claude Code trailer was not prohibited (exit $($script:STATUS))"
    Assert-Scenario ($script:OUT.Contains('AI_ATTRIBUTION|PROHIBITED|COAUTHORED_AI_CLAUDE_CODE|trailer')) 'missing COAUTHORED_AI_CLAUDE_CODE rule'
    Report-Scenario 'D7 human Claude Martin passes; bot Claude trailers prohibited'

    # H5: -Remove preserves the exec bit; the restored hook still runs and Git
    # no longer reports it as ignored.
    Begin-Scenario
    $rootH5 = New-Repo 'h5' 'off'
    $h5Hook = Join-Path $rootH5 '.git/hooks/commit-msg'
    [IO.File]::WriteAllText($h5Hook, "#!/bin/sh`ntouch `"`$(git rev-parse --show-toplevel)/.restored-ran`"`nexit 0`n", $utf8)
    try { & chmod 755 $h5Hook 2>$null } catch { }
    $h5ModeBefore = 0
    if (-not $IsWindows) { $h5ModeBefore = [int](Get-Item -LiteralPath $h5Hook).UnixFileMode }
    & pwsh -NoProfile -File $hookInstaller -Root $rootH5 | Out-Null
    & pwsh -NoProfile -File $hookInstaller -Root $rootH5 -Remove | Out-Null
    if (-not $IsWindows) {
        $h5ModeAfter = 0
        if (Test-Path -LiteralPath $h5Hook) { $h5ModeAfter = [int](Get-Item -LiteralPath $h5Hook).UnixFileMode }
        Assert-Scenario ($h5ModeBefore -eq 493 -and $h5ModeAfter -eq 493) "exec bit not preserved 755: before=$h5ModeBefore after=$h5ModeAfter"
    }
    [IO.File]::WriteAllText((Join-Path $rootH5 'f.txt'), "y`n", $utf8)
    & git -C $rootH5 add f.txt | Out-Null
    $h5out = ((& git -C $rootH5 commit -m 'feat: restored hook' 2>&1 | Out-String))
    Assert-Scenario (Test-Path -LiteralPath (Join-Path $rootH5 '.restored-ran')) 'restored hook did not run'
    Assert-Scenario (-not $h5out.Contains('was ignored')) "git reported the restored hook as ignored: $h5out"
    Report-Scenario 'H5 remove preserves exec bit; restored hook runs'

    # H6: install honors core.hooksPath.
    Begin-Scenario
    $rootH6 = New-Repo 'h6' 'off'
    & git -C $rootH6 config core.hooksPath .githooks | Out-Null
    & pwsh -NoProfile -File $hookInstaller -Root $rootH6 | Out-Null
    $h6Hook = Join-Path $rootH6 '.githooks/commit-msg'
    Assert-Scenario (Test-Path -LiteralPath $h6Hook -PathType Leaf) "hook not installed at core.hooksPath ($h6Hook)"
    Assert-Scenario (-not (Test-Path -LiteralPath (Join-Path $rootH6 '.git/hooks/commit-msg') -PathType Leaf)) 'hook leaked into the default .git/hooks'
    $h6before = ((& git -C $rootH6 rev-parse HEAD | Out-String)).Trim()
    [IO.File]::WriteAllText((Join-Path $rootH6 'f.txt'), "y`n", $utf8)
    & git -C $rootH6 add f.txt | Out-Null
    & git -C $rootH6 commit -qm 'feat: change' -m 'Co-authored-by: Claude <n@x>' 2>&1 | Out-Null
    $h6after = ((& git -C $rootH6 rev-parse HEAD | Out-String)).Trim()
    Assert-Scenario ($h6before -eq $h6after) 'AI trailer commit was not blocked at hooksPath'
    Report-Scenario 'H6 install honors core.hooksPath'

    # H7: a pre-existing python hook survives install, chains on ordinary
    # commits, and still blocks an AI-trailer commit (a tiny python3 shim keeps
    # the fixture hermetic).
    Begin-Scenario
    $rootH7 = New-Repo 'h7' 'off'
    $h7ShimDir = Join-Path $tmp 'shim'
    New-Item -ItemType Directory -Path $h7ShimDir -Force | Out-Null
    $h7Shim = Join-Path $h7ShimDir 'python3'
    [IO.File]::WriteAllText($h7Shim, "#!/bin/sh`n[ -n `"`$PK_PY_MARKER`" ] && : > `"`$PK_PY_MARKER`"`nexit 0`n", $utf8)
    try { & chmod +x $h7Shim 2>$null } catch { }
    $h7Marker = Join-Path $tmp 'h7.py-ran'
    $h7OldPath = $env:PATH
    $env:PATH = $h7ShimDir + [IO.Path]::PathSeparator + $env:PATH
    $env:PK_PY_MARKER = $h7Marker
    try {
        $h7Hook = Join-Path $rootH7 '.git/hooks/commit-msg'
        [IO.File]::WriteAllText($h7Hook, "#!/usr/bin/env python3`n# pre-existing python hook`n", $utf8)
        try { & chmod +x $h7Hook 2>$null } catch { }
        & pwsh -NoProfile -File $hookInstaller -Root $rootH7 | Out-Null
        $h7Orig = "$h7Hook.promptkit-orig"
        $h7OrigText = ''
        if (Test-Path -LiteralPath $h7Orig -PathType Leaf) { $h7OrigText = Get-Content -LiteralPath $h7Orig -Raw }
        Assert-Scenario ($h7OrigText.Contains('#!/usr/bin/env python3')) 'python original was not preserved with its shebang'
        $h7First = ''
        if (Test-Path -LiteralPath $h7Hook -PathType Leaf) { $h7First = @(Get-Content -LiteralPath $h7Hook)[0] }
        Assert-Scenario ($h7First -ceq '#!/bin/sh') 'non-shell hook was not wrapped in sh'
        [IO.File]::WriteAllText((Join-Path $rootH7 'f.txt'), "y`n", $utf8)
        & git -C $rootH7 add f.txt | Out-Null
        & git -C $rootH7 commit -qm 'feat: change' -m 'Co-authored-by: Jane <jane@example.com>' 2>&1 | Out-Null
        Assert-Scenario (Test-Path -LiteralPath $h7Marker) 'preserved python hook did not run on an ordinary commit'
        $h7before = ((& git -C $rootH7 rev-parse HEAD | Out-String)).Trim()
        [IO.File]::WriteAllText((Join-Path $rootH7 'f.txt'), "z`n", $utf8)
        & git -C $rootH7 add f.txt | Out-Null
        & git -C $rootH7 commit -qm 'feat: change' -m 'Co-authored-by: Claude <n@x>' 2>&1 | Out-Null
        $h7after = ((& git -C $rootH7 rev-parse HEAD | Out-String)).Trim()
        Assert-Scenario ($h7before -eq $h7after) 'AI trailer was not blocked through the wrapper'
    } finally {
        $env:PATH = $h7OldPath
        Remove-Item Env:PK_PY_MARKER -ErrorAction SilentlyContinue
    }
    Report-Scenario 'H7 non-shell python hook preserved, chained, and enforced'
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "Passed: $($script:PASS) | Failed: $($script:FAIL)"
if ($script:FAIL -ne 0) { exit 1 }
exit 0
