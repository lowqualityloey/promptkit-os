# Regression tests for non-destructive init.ps1 directive updates (PowerShell).
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-init-safety-tests.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# ProviderPath strips the 'Microsoft.PowerShell.Core\FileSystem::' prefix that
# Resolve-Path adds for UNC script locations (e.g. \\wsl.localhost\...); a
# child 'pwsh -File' refuses the provider-qualified form as a script path.
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "../..")).ProviderPath

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Create a temporary working directory
$TestDirItem = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())) -Force
$TestRoot = $TestDirItem.FullName

try {
    $CrlfRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "crlf") -Force).FullName
    $LfRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "lf") -Force).FullName
    $DupStartRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "dupstart") -Force).FullName
    $DupEndRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "dupend") -Force).FullName
    $ReversedRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "reversed") -Force).FullName
    $MalformedRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "malformed") -Force).FullName
    $Utf8Root = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "utf8") -Force).FullName

    $initScriptPath = Join-Path $RepoRoot "init.ps1"

    # Test 1 & 3 & 8 & 10: Successful replacement in a CRLF file, user content before/after survives, literal $, idempotency
    $crlfAgentsPath = Join-Path $CrlfRoot "AGENTS.md"
    $crlfInitialContent = "Header with `$1 literal dollar reference`r`n`r`nKeep content before.`r`n`r`n<!-- PROMPTKIT_START -->`r`nold directive`r`n<!-- PROMPTKIT_END -->`r`n`r`nKeep content after."
    [System.IO.File]::WriteAllText($crlfAgentsPath, $crlfInitialContent, $utf8NoBom)

    # -Tracking github keeps the .github PR/issue template scaffolding
    # assertions below meaningful: those templates are gated on GitHub tracking
    # (Test 34 covers the local-tracking SKIP path).
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $CrlfRoot -Tracking github | Out-Null
    $crlfUpdated = [System.IO.File]::ReadAllText($crlfAgentsPath, [System.Text.Encoding]::UTF8)

    if (-not $crlfUpdated.Contains('Header with $1 literal dollar reference')) {
        throw "Failed Test 1 (CRLF): User header with literal $ was lost or corrupted."
    }
    if (-not $crlfUpdated.Contains('Keep content before.')) {
        throw "Failed Test 1 (CRLF): User content before directive was lost."
    }
    if (-not $crlfUpdated.Contains('Keep content after.')) {
        throw "Failed Test 1 (CRLF): User content after directive was lost."
    }
    if (-not $crlfUpdated.Contains('## PromptKit OS: Engineering Operating System')) {
        throw "Failed Test 1 (CRLF): New directive content was not injected."
    }

    $crlfLines = $crlfUpdated -split "\r?\n"
    $crlfStartCount = @($crlfLines | Where-Object { $_ -eq '<!-- PROMPTKIT_START -->' }).Count
    $crlfEndCount = @($crlfLines | Where-Object { $_ -eq '<!-- PROMPTKIT_END -->' }).Count
    if ($crlfStartCount -ne 1 -or $crlfEndCount -ne 1) {
        throw "Failed Test 1 (CRLF): Expected 1 START and 1 END marker, found start=$crlfStartCount, end=$crlfEndCount."
    }

    # CRLF EOL purity (issue #666): every line ending must remain CRLF after the
    # update — no lone LF may be spliced into a CRLF host file. count(LF) == count(CR).
    $crlfLfCount = ([regex]::Matches($crlfUpdated, "`n")).Count
    $crlfCrCount = ([regex]::Matches($crlfUpdated, "`r")).Count
    if ($crlfLfCount -ne $crlfCrCount) {
        throw "Failed Test 1 (CRLF): mixed line endings after update (LF=$crlfLfCount, CR=$crlfCrCount)."
    }

    $crlfPrTemplate = Join-Path $CrlfRoot ".github/pull_request_template.md"
    if (-not (Test-Path $crlfPrTemplate)) {
        throw "Failed Test 1 (CRLF): .github/pull_request_template.md was not scaffolded."
    }
    $prTemplateContent = [System.IO.File]::ReadAllText($crlfPrTemplate, [System.Text.Encoding]::UTF8)
    if (-not $prTemplateContent.Contains('## Acceptance Criteria Checklist')) {
        throw "Failed Test 1 (CRLF): .github/pull_request_template.md does not contain expected template content."
    }

    $crlfIssueTemplate = Join-Path $CrlfRoot ".github/ISSUE_TEMPLATE/task.md"
    if (-not (Test-Path $crlfIssueTemplate)) {
        throw "Failed Test 1 (CRLF): .github/ISSUE_TEMPLATE/task.md was not scaffolded."
    }
    $issueTemplateContent = [System.IO.File]::ReadAllText($crlfIssueTemplate, [System.Text.Encoding]::UTF8)
    if (-not $issueTemplateContent.Contains('name: Task Specification')) {
        throw "Failed Test 1 (CRLF): .github/ISSUE_TEMPLATE/task.md does not contain expected template frontmatter."
    }

    # Test 10: Idempotency re-run on CRLF file (same GitHub tracking as Test 1,
    # so the already-scaffolded .github templates take the already-exist path).
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $CrlfRoot -Tracking github | Out-Null
    $reRunContent = [System.IO.File]::ReadAllText($crlfAgentsPath, [System.Text.Encoding]::UTF8)
    $reRunLines = $reRunContent -split "\r?\n"
    $reRunStartCount = @($reRunLines | Where-Object { $_ -eq '<!-- PROMPTKIT_START -->' }).Count
    if ($reRunStartCount -ne 1) {
        throw "Failed Test 10 (Idempotency): Expected 1 PROMPTKIT_START after re-run, found ${reRunStartCount}."
    }

    # Test: CRLF inject (issue #666) — a CRLF host file WITHOUT a directive block
    # must receive the directive in CRLF as well, matching init.ps1's inject semantics.
    $CrlfInjectRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "crlf_inject") -Force).FullName
    $crlfInjectPath = Join-Path $CrlfInjectRoot "AGENTS.md"
    [System.IO.File]::WriteAllText($crlfInjectPath, "CRLF host file without a directive block.`r`nSecond line.`r`n", $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $CrlfInjectRoot | Out-Null
    $crlfInjectUpdated = [System.IO.File]::ReadAllText($crlfInjectPath, [System.Text.Encoding]::UTF8)
    if (-not $crlfInjectUpdated.Contains('## PromptKit OS: Engineering Operating System')) {
        throw "Failed Test (CRLF inject): directive was not injected."
    }
    $injectLfCount = ([regex]::Matches($crlfInjectUpdated, "`n")).Count
    $injectCrCount = ([regex]::Matches($crlfInjectUpdated, "`r")).Count
    if ($injectLfCount -ne $injectCrCount) {
        throw "Failed Test (CRLF inject): mixed line endings after inject (LF=$injectLfCount, CR=$injectCrCount)."
    }

    # Test: CRLF inject rerun must be byte-stable — the update path on a file
    # whose END marker sits at EOF must not append a dangling CR.
    $injectLen = (Get-Item -LiteralPath $crlfInjectPath).Length
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $CrlfInjectRoot *> $null
    $crlfRerun = [System.IO.File]::ReadAllText($crlfInjectPath, [System.Text.Encoding]::UTF8)
    $rerunLen = (Get-Item -LiteralPath $crlfInjectPath).Length
    $rerunCr = ([regex]::Matches($crlfRerun, "`r")).Count
    $rerunLf = ([regex]::Matches($crlfRerun, "`n")).Count
    if ($rerunLen -ne $injectLen -or $rerunCr -ne $injectCrCount -or $rerunLf -ne $injectLfCount) {
        throw "Failed Test (CRLF inject rerun): not byte-stable (inject len=$injectLen CR=$injectCrCount LF=$injectLfCount; rerun len=$rerunLen CR=$rerunCr LF=$rerunLf)."
    }
    if ($crlfRerun.EndsWith("`r")) {
        throw "Failed Test (CRLF inject rerun): dangling CR at EOF."
    }

    # Test: destination symlink escaping the project root (sibling prefix) must
    # be refused and the external target must not be touched.
    $SiblingRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "sibling") -Force).FullName
    $SiblingEvil = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "sibling-evil") -Force).FullName
    $victimPath = Join-Path $SiblingEvil "victim.md"
    [System.IO.File]::WriteAllText($victimPath, "PRECIOUS SIBLING FILE", $utf8NoBom)
    $siblingLinkCreated = $false
    try {
        New-Item -ItemType SymbolicLink -Path (Join-Path $SiblingRoot "AGENTS.md") -Target $victimPath -ErrorAction Stop | Out-Null
        $siblingLinkCreated = $true
    } catch {
        Write-Output "  SKIP: symbolic link creation unsupported on this host"
    }
    if ($siblingLinkCreated) {
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $SiblingRoot *> $null
        if ($LASTEXITCODE -eq 0) {
            throw "Failed Test (sibling containment): installer did not refuse an external destination symlink."
        }
        if (-not ([System.IO.File]::ReadAllText($victimPath)).Contains('PRECIOUS SIBLING FILE')) {
            throw "Failed Test (sibling containment): external symlink target was modified."
        }
    }

    # Test 2: Successful replacement in an LF file
    $lfAgentsPath = Join-Path $LfRoot "AGENTS.md"
    $lfInitialContent = "Header LF`n`nKeep content before.`n`n<!-- PROMPTKIT_START -->`nold directive`n<!-- PROMPTKIT_END -->`n`nKeep content after."
    [System.IO.File]::WriteAllText($lfAgentsPath, $lfInitialContent, $utf8NoBom)

    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $LfRoot | Out-Null
    $lfUpdated = [System.IO.File]::ReadAllText($lfAgentsPath, [System.Text.Encoding]::UTF8)

    if (-not $lfUpdated.Contains('## PromptKit OS: Engineering Operating System')) {
        throw "Failed Test 2 (LF): New directive content was not injected."
    }
    $lfLines = $lfUpdated -split "\r?\n"
    $lfStartCount = @($lfLines | Where-Object { $_ -eq '<!-- PROMPTKIT_START -->' }).Count
    if ($lfStartCount -ne 1) {
        throw "Failed Test 2 (LF): Expected 1 PROMPTKIT_START marker, found ${lfStartCount}."
    }

    # Test 4: Duplicate START markers fail and preserve file
    $dupStartPath = Join-Path $DupStartRoot "AGENTS.md"
    $dupStartContent = "Header`r`n<!-- PROMPTKIT_START -->`r`nBlock 1`r`n<!-- PROMPTKIT_START -->`r`nBlock 2`r`n<!-- PROMPTKIT_END -->"
    [System.IO.File]::WriteAllText($dupStartPath, $dupStartContent, $utf8NoBom)
    $dupStartHashBefore = (Get-FileHash -Path $dupStartPath -Algorithm SHA256).Hash

    $failedDupStart = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-ProjectRoot", "`"$DupStartRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $failedDupStart = $true }
    } catch {
        $failedDupStart = $true
    }
    if (-not $failedDupStart) {
        throw "Failed Test 4: Expected duplicate START markers to fail loudly."
    }
    $dupStartHashAfter = (Get-FileHash -Path $dupStartPath -Algorithm SHA256).Hash
    if ($dupStartHashBefore -ne $dupStartHashAfter) {
        throw "Failed Test 4: File was modified despite duplicate START failure."
    }

    # Test 5: Duplicate END markers fail and preserve file
    $dupEndPath = Join-Path $DupEndRoot "AGENTS.md"
    $dupEndContent = "Header`r`n<!-- PROMPTKIT_START -->`r`nBlock 1`r`n<!-- PROMPTKIT_END -->`r`n<!-- PROMPTKIT_END -->"
    [System.IO.File]::WriteAllText($dupEndPath, $dupEndContent, $utf8NoBom)
    $dupEndHashBefore = (Get-FileHash -Path $dupEndPath -Algorithm SHA256).Hash

    $failedDupEnd = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-ProjectRoot", "`"$DupEndRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $failedDupEnd = $true }
    } catch {
        $failedDupEnd = $true
    }
    if (-not $failedDupEnd) {
        throw "Failed Test 5: Expected duplicate END markers to fail loudly."
    }
    $dupEndHashAfter = (Get-FileHash -Path $dupEndPath -Algorithm SHA256).Hash
    if ($dupEndHashBefore -ne $dupEndHashAfter) {
        throw "Failed Test 5: File was modified despite duplicate END failure."
    }

    # Test 6: Reversed END-before-START markers fail and preserve file
    $reversedPath = Join-Path $ReversedRoot "AGENTS.md"
    $reversedContent = "Header`r`n<!-- PROMPTKIT_END -->`r`nReversed body`r`n<!-- PROMPTKIT_START -->`r`nFooter"
    [System.IO.File]::WriteAllText($reversedPath, $reversedContent, $utf8NoBom)
    $reversedHashBefore = (Get-FileHash -Path $reversedPath -Algorithm SHA256).Hash

    $failedReversed = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-ProjectRoot", "`"$ReversedRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $failedReversed = $true }
    } catch {
        $failedReversed = $true
    }
    if (-not $failedReversed) {
        throw "Failed Test 6: Expected reversed END-before-START markers to fail loudly."
    }
    $reversedHashAfter = (Get-FileHash -Path $reversedPath -Algorithm SHA256).Hash
    if ($reversedHashBefore -ne $reversedHashAfter) {
        throw "Failed Test 6: File was modified despite reversed markers failure."
    }

    # Test 7: Incomplete marker blocks fail and preserve file
    $malformedPath = Join-Path $MalformedRoot "AGENTS.md"
    $malformedContent = "Header`r`n<!-- PROMPTKIT_START -->`r`nincomplete directive without end marker"
    [System.IO.File]::WriteAllText($malformedPath, $malformedContent, $utf8NoBom)
    $malformedHashBefore = (Get-FileHash -Path $malformedPath -Algorithm SHA256).Hash

    $failedMalformed = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-ProjectRoot", "`"$MalformedRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $failedMalformed = $true }
    } catch {
        $failedMalformed = $true
    }
    if (-not $failedMalformed) {
        throw "Failed Test 7: Expected incomplete marker block to fail loudly."
    }
    $malformedHashAfter = (Get-FileHash -Path $malformedPath -Algorithm SHA256).Hash
    if ($malformedHashBefore -ne $malformedHashAfter) {
        throw "Failed Test 7: File was modified despite incomplete marker failure."
    }

    # Test 9: UTF-8 content containing emoji and CJK characters survives update
    $utf8Path = Join-Path $Utf8Root "AGENTS.md"
    $utf8Content = "Header 🚀 🧪 漢字 テスト`r`n`r`n<!-- PROMPTKIT_START -->`r`nold directive`r`n<!-- PROMPTKIT_END -->`r`n`r`nFooter ✨ 祝日"
    [System.IO.File]::WriteAllText($utf8Path, $utf8Content, $utf8NoBom)

    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $Utf8Root | Out-Null
    $utf8Updated = [System.IO.File]::ReadAllText($utf8Path, [System.Text.Encoding]::UTF8)

    if (-not $utf8Updated.Contains('🚀 🧪 漢字 テスト')) {
        throw "Failed Test 9: Emoji and CJK characters in header were corrupted or lost."
    }
    if (-not $utf8Updated.Contains('✨ 祝日')) {
        throw "Failed Test 9: Emoji and CJK characters in footer were corrupted or lost."
    }

    # Test 11: Directory-based target (.clinerules/ directory layout) creates/updates .clinerules/promptkit.md
    $DirLayoutRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "dirlayout") -Force).FullName
    $ClineDir = New-Item -ItemType Directory -Path (Join-Path $DirLayoutRoot ".clinerules") -Force
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $DirLayoutRoot | Out-Null
    $clineTarget = Join-Path $ClineDir.FullName "promptkit.md"
    if (-not (Test-Path $clineTarget)) {
        throw "Failed Test 11: .clinerules/promptkit.md was not created when .clinerules is a directory."
    }
    $clineContent = [System.IO.File]::ReadAllText($clineTarget, [System.Text.Encoding]::UTF8)
    if (-not $clineContent.Contains('## PromptKit OS: Engineering Operating System')) {
        throw "Failed Test 11: .clinerules/promptkit.md does not contain expected directive."
    }

    # Test 12: Byte-for-byte idempotency on repeated initialization
    $IdempotentRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "idempotent") -Force).FullName
    $idempotentAgent = Join-Path $IdempotentRoot "AGENTS.md"
    [System.IO.File]::WriteAllText($idempotentAgent, "# User instructions`n`nKeep me.`n", $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $IdempotentRoot | Out-Null
    $firstPassHash = (Get-FileHash -Path $idempotentAgent -Algorithm SHA256).Hash
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $IdempotentRoot | Out-Null
    $secondPassHash = (Get-FileHash -Path $idempotentAgent -Algorithm SHA256).Hash
    if ($firstPassHash -ne $secondPassHash) {
        throw "Failed Test 12: Repeated initialization was not byte-idempotent (hash mismatch)."
    }

    # Test 13: --host=opencode on empty dir creates host file, keeps AGENTS.md, skips CLAUDE.md
    # (Probing is environment-dependent, so flag-driven paths are asserted here;
    # the single-hit probe rule is covered by the Bash twin with a hermetic PATH.)
    $HostSelRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "hostsel") -Force).FullName
    $env:PROMPTKIT_NO_INTERACTIVE = "1"
    try {
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $HostSelRoot --host=opencode --balanced | Out-Null
    } finally {
        Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
    }
    $opencodeRules = Join-Path $HostSelRoot ".opencode/rules.md"
    if (-not (Test-Path $opencodeRules)) {
        throw "Failed Test 13: .opencode/rules.md was not created for --host=opencode."
    }
    if (-not (Test-Path (Join-Path $HostSelRoot "AGENTS.md"))) {
        throw "Failed Test 13: AGENTS.md universal fallback was not created."
    }
    if (Test-Path (Join-Path $HostSelRoot "CLAUDE.md")) {
        throw "Failed Test 13: CLAUDE.md should not exist for an opencode-only selection."
    }
    $rulesContent = [System.IO.File]::ReadAllText($opencodeRules, [System.Text.Encoding]::UTF8)
    if (-not $rulesContent.Contains('## PromptKit OS: Engineering Operating System')) {
        throw "Failed Test 13: .opencode/rules.md does not contain the injected directive."
    }

    # Test 13b: --host=cursor writes the managed block into .cursorrules (Scenario 4)
    $CursorRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "cursorhost") -Force).FullName
    $env:PROMPTKIT_NO_INTERACTIVE = "1"
    try {
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $CursorRoot --host=cursor --balanced | Out-Null
    } finally {
        Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
    }
    $cursorRules = Join-Path $CursorRoot ".cursorrules"
    if (-not (Test-Path $cursorRules)) {
        throw "Failed Test 13b: .cursorrules was not created for --host=cursor."
    }
    $cursorContent = [System.IO.File]::ReadAllText($cursorRules, [System.Text.Encoding]::UTF8)
    if (-not $cursorContent.Contains('<!-- PROMPTKIT_START -->')) {
        throw "Failed Test 13b: .cursorrules does not contain the managed block."
    }

    # Test 13c: a multi-host install carries the managed block in every host file (Scenario 3)
    $MultiHostRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "multihost") -Force).FullName
    $env:PROMPTKIT_NO_INTERACTIVE = "1"
    try {
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $MultiHostRoot --host=claude,cursor,opencode,gemini,windsurf,copilot,cline,trae,aider --balanced | Out-Null
    } finally {
        Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
    }
    $multiHostFiles = @(
        "CLAUDE.md", ".cursorrules", ".opencode/rules.md", "GEMINI.md", ".windsurfrules",
        ".github/copilot-instructions.md", ".clinerules/promptkit.md", ".traerules", "CONVENTIONS.md"
    )
    foreach ($rel in $multiHostFiles) {
        $path = Join-Path $MultiHostRoot $rel
        if (-not (Test-Path $path)) {
            throw "Failed Test 13c: multi-host install missing $rel."
        }
        $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        if (($content.Split('<!-- PROMPTKIT_START -->').Count - 1) -ne 1) {
            throw "Failed Test 13c: managed block missing or duplicated in $rel."
        }
    }

    # Test 14: --add-host injects exactly once; pre-existing content preserved
    $AddHostRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "addhost") -Force).FullName
    [System.IO.File]::WriteAllText((Join-Path $AddHostRoot "AGENTS.md"), "# Mine`n", $utf8NoBom)
    $env:PROMPTKIT_NO_INTERACTIVE = "1"
    try {
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $AddHostRoot --balanced | Out-Null
        $beforeHash = (Get-FileHash -Path (Join-Path $AddHostRoot "AGENTS.md") -Algorithm SHA256).Hash
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $AddHostRoot --balanced --add-host=claude | Out-Null
    } finally {
        Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
    }
    $claudePath = Join-Path $AddHostRoot "CLAUDE.md"
    if (-not (Test-Path $claudePath)) {
        throw "Failed Test 14: CLAUDE.md was not created by --add-host=claude."
    }
    $afterHash = (Get-FileHash -Path (Join-Path $AddHostRoot "AGENTS.md") -Algorithm SHA256).Hash
    if ($beforeHash -ne $afterHash) {
        throw "Failed Test 14: pre-existing AGENTS.md changed during --add-host."
    }
    $claudeBlocks = ([regex]::Matches([System.IO.File]::ReadAllText($claudePath, [System.Text.Encoding]::UTF8), "PROMPTKIT_START")).Count
    if ($claudeBlocks -ne 1) {
        throw "Failed Test 14: CLAUDE.md should contain exactly one directive block."
    }

    # Test 15: --target custom path is idempotent; traversal and unknown hosts rejected
    $TargetRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "customtarget") -Force).FullName
    $env:PROMPTKIT_NO_INTERACTIVE = "1"
    try {
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $TargetRoot --balanced --target=docs/AI.md | Out-Null
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $TargetRoot --balanced --target=docs/AI.md | Out-Null
    } finally {
        Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
    }
    $aiPath = Join-Path $TargetRoot "docs/AI.md"
    if (-not (Test-Path $aiPath)) {
        throw "Failed Test 15: docs/AI.md was not created by --target."
    }
    $aiBlocks = ([regex]::Matches([System.IO.File]::ReadAllText($aiPath, [System.Text.Encoding]::UTF8), "PROMPTKIT_START")).Count
    if ($aiBlocks -ne 1) {
        throw "Failed Test 15: docs/AI.md should contain exactly one directive block after re-runs."
    }
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $TargetRoot --target=../evil 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        throw "Failed Test 15: traversal --target=../evil was accepted; expected rejection."
    }
    # Test 15b: a file path is rejected as the project root (-PathType Container parity with init.sh -d).
    $plainFile = Join-Path $TestRoot "plainfile.txt"
    [System.IO.File]::WriteAllText($plainFile, "placeholder", $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $plainFile 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        throw "Failed Test 15b: a file path was accepted as the project root; expected rejection."
    }
    # Test 15c: '..' inside a legitimate filename is accepted (segment matching, not substring).
    $dotdotRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "dotdotname") -Force).FullName
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $dotdotRoot --balanced --target=docs/v1..v2.md | Out-Null
    $dotdotPath = Join-Path $dotdotRoot "docs/v1..v2.md"
    if (-not (Test-Path -LiteralPath $dotdotPath)) {
        throw "Failed Test 15c: docs/v1..v2.md was not created by --target (substring '..' rejection is too broad)."
    }
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $dotdotRoot --balanced --target=docs/v1..v2.md | Out-Null
    $dotdotBlocks = ([regex]::Matches([System.IO.File]::ReadAllText($dotdotPath, [System.Text.Encoding]::UTF8), "PROMPTKIT_START")).Count
    if ($dotdotBlocks -ne 1) {
        throw "Failed Test 15c: docs/v1..v2.md should contain exactly one directive block after re-runs."
    }
    # Test 15d: trailing '..' segment and -Target parameter binding are both rejected.
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $TargetRoot --target=docs/.. 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        throw "Failed Test 15d: trailing --target=docs/.. was accepted; expected rejection."
    }
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $TargetRoot -Target "..\outside.md" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        throw "Failed Test 15d: -Target parameter binding bypassed the '..' check; expected rejection."
    }
    # Test 15e: PROMPTKIT.md is byte-idempotent across re-runs. The profile/tracking/
    # projection split-filter-append passes used to keep the split's trailing empty
    # element and grow one blank line per pass per rerun; smoke.sh §3 compares
    # PROMPTKIT.md byte-for-byte between the courier and canonical doors, so the
    # accumulation broke the windows release leg on the first real tag.
    $profileRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "profileidempotent") -Force).FullName
    $env:PROMPTKIT_NO_INTERACTIVE = "1"
    try {
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $profileRoot --balanced | Out-Null
        $profileFirst = [System.IO.File]::ReadAllBytes((Join-Path $profileRoot "PROMPTKIT.md"))
        & pwsh -NoProfile -File $initScriptPath -ProjectRoot $profileRoot --balanced | Out-Null
        $profileSecond = [System.IO.File]::ReadAllBytes((Join-Path $profileRoot "PROMPTKIT.md"))
    } finally {
        Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
    }
    if (-not $profileFirst -or -not $profileSecond) {
        throw "Failed Test 15e: PROMPTKIT.md was not created by init.ps1."
    }
    if ([System.Convert]::ToBase64String($profileFirst) -ne [System.Convert]::ToBase64String($profileSecond)) {
        throw "Failed Test 15e: PROMPTKIT.md changed across re-runs (trailing-newline split accumulation)."
    }
    # Test 16: Inline marker example in preamble survives update without deletion of intervening user prose
    $InlineRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "inlineexample") -Force).FullName
    $inlineAgent = Join-Path $InlineRoot "AGENTS.md"
    $inlineInitial = "# Project Instructions`n`nNote: do not remove <!-- PROMPTKIT_START --> manually.`n`nIntervening critical user prose that must be preserved.`n`n<!-- PROMPTKIT_START -->`nold directive`n<!-- PROMPTKIT_END -->`n`nTrailing footer prose."
    [System.IO.File]::WriteAllText($inlineAgent, $inlineInitial, $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $InlineRoot | Out-Null
    $inlineUpdated = [System.IO.File]::ReadAllText($inlineAgent, [System.Text.Encoding]::UTF8)
    if (-not $inlineUpdated.Contains("Note: do not remove <!-- PROMPTKIT_START --> manually.")) {
        throw "Failed Test 16: Inline marker example in user preamble was deleted or corrupted."
    }
    if (-not $inlineUpdated.Contains("Intervening critical user prose that must be preserved.")) {
        throw "Failed Test 16: Intervening user prose between inline marker example and managed block was deleted."
    }
    if (-not $inlineUpdated.Contains("Trailing footer prose.")) {
        throw "Failed Test 16: Trailing footer prose was lost."
    }

    # Test 17: Directive block at the very beginning of the file (startIndex == 0)
    $StartZeroRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "startzero") -Force).FullName
    $startZeroAgent = Join-Path $StartZeroRoot "AGENTS.md"
    $startZeroInitial = "<!-- PROMPTKIT_START -->`nold directive`n<!-- PROMPTKIT_END -->`n`nUser postamble content."
    [System.IO.File]::WriteAllText($startZeroAgent, $startZeroInitial, $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $StartZeroRoot | Out-Null
    $startZeroUpdated = [System.IO.File]::ReadAllText($startZeroAgent, [System.Text.Encoding]::UTF8)
    if (-not $startZeroUpdated.StartsWith("<!-- PROMPTKIT_START -->")) {
        throw "Failed Test 17: Block starting at line 0 was not placed at beginning of updated file."
    }
    if (-not $startZeroUpdated.Contains("User postamble content.")) {
        throw "Failed Test 17: Postamble content lost when directive block is at line 0."
    }

    # Test 18: Directive block at the very end of the file with no trailing newline
    $EndNoNlRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "endnonl") -Force).FullName
    $endNoNlAgent = Join-Path $EndNoNlRoot "AGENTS.md"
    $endNoNlInitial = "User preamble content.`n`n<!-- PROMPTKIT_START -->`nold directive`n<!-- PROMPTKIT_END -->"
    [System.IO.File]::WriteAllText($endNoNlAgent, $endNoNlInitial, $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $EndNoNlRoot | Out-Null
    $endNoNlUpdated = [System.IO.File]::ReadAllText($endNoNlAgent, [System.Text.Encoding]::UTF8)
    if (-not $endNoNlUpdated.Contains("User preamble content.")) {
        throw "Failed Test 18: Preamble content lost when directive block is at end of file."
    }
    if (-not $endNoNlUpdated.EndsWith("<!-- PROMPTKIT_END -->")) {
        throw "Failed Test 18: File ending without newline gained unintended trailing characters."
    }

    # Test 19: Mixed line endings (CRLF preamble, LF footer) preserve exact original terminator bytes
    $MixedEolRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "mixedeol") -Force).FullName
    $mixedAgent = Join-Path $MixedEolRoot "AGENTS.md"
    $preambleCrlf = "Header CRLF`r`nMore header`r`n"
    $footerLf = "`nFooter with LF separator`n"
    $mixedInitial = $preambleCrlf + "<!-- PROMPTKIT_START -->`r`nold directive`r`n<!-- PROMPTKIT_END -->" + $footerLf
    [System.IO.File]::WriteAllText($mixedAgent, $mixedInitial, $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $MixedEolRoot | Out-Null
    $mixedUpdated = [System.IO.File]::ReadAllText($mixedAgent, [System.Text.Encoding]::UTF8)
    if (-not $mixedUpdated.StartsWith($preambleCrlf)) {
        throw "Failed Test 19: CRLF preamble was altered during mixed-EOL update."
    }
    if (-not $mixedUpdated.EndsWith($footerLf)) {
        throw "Failed Test 19: LF footer separator was altered (e.g. converted to CRLF) during mixed-EOL update."
    }

    # Test 20: Markers indented with Unicode whitespace (non-breaking space) are updated without creating duplicates
    $NbspRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "nbsp") -Force).FullName
    $nbspAgent = Join-Path $NbspRoot "AGENTS.md"
    $nbsp = [char]0x00A0
    $nbspInitial = "Header`n${nbsp}${nbsp}<!-- PROMPTKIT_START -->`nold directive`n${nbsp}<!-- PROMPTKIT_END -->`nFooter`n"
    [System.IO.File]::WriteAllText($nbspAgent, $nbspInitial, $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $NbspRoot | Out-Null
    $nbspUpdated = [System.IO.File]::ReadAllText($nbspAgent, [System.Text.Encoding]::UTF8)
    $startCount = ([regex]::Matches($nbspUpdated, "PROMPTKIT_START")).Count
    $endCount = ([regex]::Matches($nbspUpdated, "PROMPTKIT_END")).Count
    if ($startCount -ne 1 -or $endCount -ne 1) {
        throw "Failed Test 20: Unicode whitespace indented markers resulted in duplicate directive blocks (start=$startCount, end=$endCount)."
    }
    if (-not $nbspUpdated.Contains("Header`n") -or -not $nbspUpdated.EndsWith("Footer`n")) {
        throw "Failed Test 20: Header or footer was corrupted during Unicode indented marker update."
    }

    # Test 21: Orphan marker with Unicode whitespace is rejected loudly and preserves file
    $OrphanNbspRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "orphannbsp") -Force).FullName
    $orphanNbspAgent = Join-Path $OrphanNbspRoot "AGENTS.md"
    $orphanInitial = "Header`n${nbsp}<!-- PROMPTKIT_START -->`nOrphan body without end marker`n"
    [System.IO.File]::WriteAllText($orphanNbspAgent, $orphanInitial, $utf8NoBom)
    $orphanHashBefore = (Get-FileHash -Path $orphanNbspAgent -Algorithm SHA256).Hash
    $failedOrphan = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-ProjectRoot", "`"$OrphanNbspRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $failedOrphan = $true }
    } catch {
        $failedOrphan = $true
    }
    if (-not $failedOrphan) {
        throw "Failed Test 21: Expected orphan Unicode-indented marker to be rejected loudly."
    }
    $orphanHashAfter = (Get-FileHash -Path $orphanNbspAgent -Algorithm SHA256).Hash
    if ($orphanHashBefore -ne $orphanHashAfter) {
        throw "Failed Test 21: File was modified despite orphan Unicode-indented marker failure."
    }

    # Test 22: Destination escape containment and relay link resolution (F04 - P2, R3 - P2)
    $EscapeRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "escape_project") -Force).FullName
    $OutsideDir = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "outside") -Force).FullName
    $secretFile = Join-Path $OutsideDir "secret.md"
    [System.IO.File]::WriteAllText($secretFile, "sensitive external content", $utf8NoBom)
    $escapeFailed = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-Target", "`"../outside/secret.md`"", "-ProjectRoot", "`"$EscapeRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $escapeFailed = $true }
    } catch {
        $escapeFailed = $true
    }
    if (-not $escapeFailed) {
        throw "Failed Test 22: Escaping target was accepted; expected rejection."
    }
    if ([System.IO.File]::ReadAllText($secretFile, [System.Text.Encoding]::UTF8) -ne "sensitive external content") {
        throw "Failed Test 22: External file was modified despite escape rejection."
    }

    # Relay symlink escape (R3 - P2)
    $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
    $relayDir = Join-Path $EscapeRoot "relay"
    New-Item -ItemType $linkType -Path $relayDir -Target $OutsideDir | Out-Null
    $relayFailed = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-Target", "`"relay/secret.md`"", "-ProjectRoot", "`"$EscapeRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $relayFailed = $true }
    } catch {
        $relayFailed = $true
    }
    if (-not $relayFailed) {
        throw "Failed Test 22: Relay link destination escaping project was accepted; expected rejection."
    }

    # Test 23: Multiple custom targets with spaces, brackets, literal commas, and rejected overlaps (F06, R6, R7, R8)
    $SpacesRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "spaces_and_globs") -Force).FullName
    New-Item -ItemType Directory -Path (Join-Path $SpacesRoot "docs") -Force | Out-Null
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $SpacesRoot --target="docs/path with spaces/custom instructions.md" --target="docs/[special-rules]/ai.md" | Out-Null
    $spacedTarget = Join-Path $SpacesRoot "docs/path with spaces/custom instructions.md"
    $globTarget = Join-Path $SpacesRoot "docs/[special-rules]/ai.md"
    if (-not (Test-Path -LiteralPath $spacedTarget)) {
        throw "Failed Test 23: Target with spaces was not created."
    }
    if (-not (Test-Path -LiteralPath $globTarget)) {
        throw "Failed Test 23: Target with glob characters [special-rules] was not created."
    }
    $spacedContent = [System.IO.File]::ReadAllText($spacedTarget, [System.Text.Encoding]::UTF8)
    if (-not $spacedContent.Contains("<!-- PROMPTKIT_START -->")) {
        throw "Failed Test 23: Target with spaces missing directive."
    }
    $globContent = [System.IO.File]::ReadAllText($globTarget, [System.Text.Encoding]::UTF8)
    if (-not $globContent.Contains("<!-- PROMPTKIT_START -->")) {
        throw "Failed Test 23: Target with glob characters missing directive."
    }

    # Verify native PowerShell array with spaces, brackets, and literal comma filename (R8 - P2)
    $DirectRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "direct_targets") -Force).FullName
    & $initScriptPath -ProjectRoot $DirectRoot -Target "docs/path with spaces/custom2.md","docs/[bracket-dir]/ai2.md","docs/AI,Rules.md" | Out-Null
    $directSpaced = Join-Path $DirectRoot "docs/path with spaces/custom2.md"
    $directGlob = Join-Path $DirectRoot "docs/[bracket-dir]/ai2.md"
    $directComma = Join-Path $DirectRoot "docs/AI,Rules.md"
    if (-not (Test-Path -LiteralPath $directSpaced)) {
        throw "Failed Test 23: Direct -Target with spaces was not created."
    }
    if (-not (Test-Path -LiteralPath $directGlob)) {
        throw "Failed Test 23: Direct -Target with glob characters was not created."
    }
    if (-not (Test-Path -LiteralPath $directComma)) {
        throw "Failed Test 23: Direct -Target with literal comma was not created."
    }

    # Verify managed target overlap rejection (R6 - P2)
    $managedFailed = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-Target", "PROMPTKIT.md", "-ProjectRoot", "`"$SpacesRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $managedFailed = $true }
    } catch {
        $managedFailed = $true
    }
    if (-not $managedFailed) {
        throw "Failed Test 23: Target overlapping with PROMPTKIT.md was accepted; expected rejection."
    }

    # Verify directory target rejection (R7 - P2)
    $dirFailed = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-Target", "docs", "-ProjectRoot", "`"$SpacesRoot`"" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $dirFailed = $true }
    } catch {
        $dirFailed = $true
    }
    if (-not $dirFailed) {
        throw "Failed Test 23: Directory target was accepted; expected rejection."
    }

    # Test 24: Cline existing file layout, update, and -AddHost cline rerun (F05 - P2)
    $ClineRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "cline_file_layout") -Force).FullName
    $clineFile = Join-Path $ClineRoot ".clinerules"
    $clineInitial = "# Cline instructions`n<!-- PROMPTKIT_START -->`nold directive`n<!-- PROMPTKIT_END -->`n"
    [System.IO.File]::WriteAllText($clineFile, $clineInitial, $utf8NoBom)
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $ClineRoot -AddHost "cline" | Out-Null
    if (-not (Test-Path -LiteralPath $clineFile -PathType Leaf)) {
        throw "Failed Test 24: .clinerules should remain a leaf file."
    }
    $clineUpdated = [System.IO.File]::ReadAllText($clineFile, [System.Text.Encoding]::UTF8)
    if (-not $clineUpdated.Contains("# Cline instructions") -or -not $clineUpdated.Contains("## PromptKit OS: Engineering Operating System")) {
        throw "Failed Test 24: .clinerules was not safely updated."
    }

    # Test 25: Transactional atomicity: pre-validation and commit-time rollback (F07 - P2, R5 - P2)
    $TxRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "transactional_preservation") -Force).FullName
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $TxRoot -Profile "lite" | Out-Null
    $txProfile = Join-Path $TxRoot "PROMPTKIT.md"
    $txAgents = Join-Path $TxRoot "AGENTS.md"
    $txClaude = Join-Path $TxRoot "CLAUDE.md"
    $claudeReversed = "# Claude instructions`n<!-- PROMPTKIT_END -->`nreversed body`n<!-- PROMPTKIT_START -->`n"
    [System.IO.File]::WriteAllText($txClaude, $claudeReversed, $utf8NoBom)

    $profileHashBefore = (Get-FileHash -Path $txProfile -Algorithm SHA256).Hash
    $agentsHashBefore = (Get-FileHash -Path $txAgents -Algorithm SHA256).Hash
    $claudeHashBefore = (Get-FileHash -Path $txClaude -Algorithm SHA256).Hash

    $txFailed = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-ProjectRoot", "`"$TxRoot`"", "-Profile", "balanced" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $txFailed = $true }
    } catch {
        $txFailed = $true
    }
    if (-not $txFailed) {
        throw "Failed Test 25: Expected update with malformed target to fail."
    }

    $profileHashAfter = (Get-FileHash -Path $txProfile -Algorithm SHA256).Hash
    $agentsHashAfter = (Get-FileHash -Path $txAgents -Algorithm SHA256).Hash
    $claudeHashAfter = (Get-FileHash -Path $txClaude -Algorithm SHA256).Hash

    if ($profileHashBefore -ne $profileHashAfter) {
        throw "Failed Test 25: PROMPTKIT.md was modified despite transaction failure."
    }
    if ($agentsHashBefore -ne $agentsHashAfter) {
        throw "Failed Test 25: AGENTS.md was modified despite transaction failure."
    }
    if ($claudeHashBefore -ne $claudeHashAfter) {
        throw "Failed Test 25: CLAUDE.md was modified despite transaction failure."
    }
    $txProfContent = [System.IO.File]::ReadAllText($txProfile, [System.Text.Encoding]::UTF8)
    if (-not $txProfContent.Contains("profile: lite")) {
        throw "Failed Test 25: PROMPTKIT.md profile changed from lite."
    }

    # Part B: Commit-time write failure rollback (R5 - P2)
    Remove-Item -LiteralPath $txClaude -Force
    $readonlyTarget = Join-Path $TxRoot "readonly_target.md"
    [System.IO.File]::WriteAllText($readonlyTarget, "# Readonly target`n", $utf8NoBom)
    (Get-Item -LiteralPath $readonlyTarget).IsReadOnly = $true

    $agentsHashPre = (Get-FileHash -Path $txAgents -Algorithm SHA256).Hash
    $profileHashPre = (Get-FileHash -Path $txProfile -Algorithm SHA256).Hash

    $commitFail = $false
    try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", "`"$initScriptPath`"", "-ProjectRoot", "`"$TxRoot`"", "-Profile", "balanced", "-Target", "readonly_target.md" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { $commitFail = $true }
    } catch {
        $commitFail = $true
    }
    (Get-Item -LiteralPath $readonlyTarget).IsReadOnly = $false
    if (-not $commitFail) {
        throw "Failed Test 25: Expected commit-time write failure on readonly target to fail."
    }
    $agentsHashPost = (Get-FileHash -Path $txAgents -Algorithm SHA256).Hash
    $profileHashPost = (Get-FileHash -Path $txProfile -Algorithm SHA256).Hash
    if ($agentsHashPre -ne $agentsHashPost) {
        throw "Failed Test 25: AGENTS.md was modified despite commit-time write failure."
    }
    if ($profileHashPre -ne $profileHashPost) {
        throw "Failed Test 25: PROMPTKIT.md was modified despite commit-time write failure."
    }
    if (-not ([System.IO.File]::ReadAllText($txProfile, [System.Text.Encoding]::UTF8)).Contains("profile: lite")) {
        throw "Failed Test 25: PROMPTKIT.md did not roll back to lite profile."
    }

    # Test 26: Explicit -Profile balanced parameter overrides installed profile: lite in PROMPTKIT.md (F08 - P2)
    $OverrideRoot = (New-Item -ItemType Directory -Path (Join-Path $TestRoot "override_profile") -Force).FullName
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $OverrideRoot -Profile "lite" | Out-Null
    $overrideProfile = Join-Path $OverrideRoot "PROMPTKIT.md"
    $prof1 = [System.IO.File]::ReadAllText($overrideProfile, [System.Text.Encoding]::UTF8)
    if (-not $prof1.Contains("profile: lite")) {
        throw "Failed Test 26: Initial profile was not lite."
    }
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $OverrideRoot -Profile "balanced" | Out-Null
    $prof2 = [System.IO.File]::ReadAllText($overrideProfile, [System.Text.Encoding]::UTF8)
    if (-not $prof2.Contains("profile: balanced")) {
        throw "Failed Test 26: Explicit -Profile balanced failed to override installed profile: lite."
    }

    # Test 27-33: Install-door structural assert. init.ps1 calls
    # scripts/check-setup-assert.ps1 after the rollback block and before the
    # banner; a non-zero result exits without printing the success banner.
    function New-AssertKitCopy {
        param([string]$Destination)
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        Get-ChildItem -LiteralPath $RepoRoot -Force |
            Where-Object { $_.Name -notin @('.git', '.codegraph') } |
            ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force }
    }

    function Invoke-InitAssert {
        param([string]$InitPath, [string]$ProjectPath, [string]$InstallProfile = 'balanced', [string[]]$ExtraArgs = @())
        $captured = & pwsh -NoProfile -File $InitPath -Profile $InstallProfile -ProjectRoot $ProjectPath @ExtraArgs 2>&1 | Out-String
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $captured }
    }

    # Stage a COMPLETE kit at <project>/.promptkit: the installer plus every row
    # of scripts/setup-assert-files.txt. That manifest is the single definition
    # of a complete kit - the installer reads it to decide whether a staged copy
    # is usable, and scripts/check-setup-assert.ps1 validates the same rows - so
    # the fixtures derive the staged set from it instead of hard-coding a second
    # list that could drift out of step with the installer.
    function Add-CompleteKitStage {
        param([string]$ProjectPath, [string]$KitPath)
        $stagedRoot = Join-Path $ProjectPath '.promptkit'
        New-Item -ItemType Directory -Path $stagedRoot -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $KitPath 'init.ps1') -Destination (Join-Path $stagedRoot 'init.ps1') -Force
        foreach ($row in [System.IO.File]::ReadAllLines((Join-Path $KitPath 'scripts/setup-assert-files.txt'))) {
            $line = $row.Trim()
            if ($line -eq '' -or $line.StartsWith('#')) { continue }
            $parts = $line.Split('|')
            $rel = $parts[0].Trim()
            $kind = $parts[1].Trim()
            $source = Join-Path $KitPath $rel
            $target = Join-Path $stagedRoot $rel
            if ($kind -eq 'dir') {
                New-Item -ItemType Directory -Path $target -Force | Out-Null
                Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force
            } else {
                New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
                Copy-Item -LiteralPath $source -Destination $target -Force
            }
        }
    }

    $savedNoInteractive = $env:PROMPTKIT_NO_INTERACTIVE
    $savedNoPreflight = $env:PROMPTKIT_NO_PREFLIGHT
    $env:PROMPTKIT_NO_INTERACTIVE = '1'
    Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue
    try {
        # Test 27: Courier door - a complete kit copy with no .git asserts tree OK.
        $courierKit = Join-Path $TestRoot 'assert-courier-kit'
        New-AssertKitCopy $courierKit
        $courierProj = Join-Path $TestRoot 'assert-courier-proj'
        New-Item -ItemType Directory -Path $courierProj -Force | Out-Null
        $courier = Invoke-InitAssert -InitPath (Join-Path $courierKit 'init.ps1') -ProjectPath $courierProj
        if ($courier.ExitCode -ne 0) { throw "Failed Test 27 (courier): expected exit 0, got $($courier.ExitCode)." }
        if (-not $courier.Output.Contains('ASSERT|courier|tree|OK')) { throw "Failed Test 27 (courier): missing ASSERT|courier|tree|OK." }
        if (-not $courier.Output.Contains('PromptKit OS successfully configured')) { throw "Failed Test 27 (courier): missing success banner." }

        # Test 28: Partial-copy door - missing engine files FAIL, exit 1, no banner, no rollback.
        $partialKit = Join-Path $TestRoot 'assert-partial-kit'
        New-AssertKitCopy $partialKit
        Remove-Item -LiteralPath (Join-Path $partialKit 'workflows/route.md') -Force
        Remove-Item -LiteralPath (Join-Path $partialKit 'templates/project-profile-template.md') -Force
        $partialProj = Join-Path $TestRoot 'assert-partial-proj'
        New-Item -ItemType Directory -Path $partialProj -Force | Out-Null
        $partial = Invoke-InitAssert -InitPath (Join-Path $partialKit 'init.ps1') -ProjectPath $partialProj
        if ($partial.ExitCode -ne 1) { throw "Failed Test 28 (partial-copy): expected exit 1, got $($partial.ExitCode)." }
        if (-not $partial.Output.Contains('ASSERT|partial-copy|missing:workflows/route.md|FAIL')) { throw "Failed Test 28 (partial-copy): missing route.md FAIL line." }
        if (-not $partial.Output.Contains('ASSERT|partial-copy|missing:templates/project-profile-template.md|FAIL')) { throw "Failed Test 28 (partial-copy): missing template FAIL line." }
        if (-not $partial.Output.Contains('ASSERT|partial-copy|remedy|')) { throw "Failed Test 28 (partial-copy): missing remedy line." }
        if ($partial.Output.Contains('PromptKit OS successfully configured')) { throw "Failed Test 28 (partial-copy): success banner printed on failure." }
        if (-not (Test-Path -LiteralPath (Join-Path $partialProj 'PROMPTKIT.md'))) { throw "Failed Test 28 (partial-copy): install rolled back (PROMPTKIT.md missing)." }

        # Test 29: Direct-clone door - the kit carries its own .git and resolves to itself.
        $directKit = Join-Path $TestRoot 'assert-direct-kit'
        New-AssertKitCopy $directKit
        & git -C $directKit init -q
        $directProj = Join-Path $TestRoot 'assert-direct-proj'
        New-Item -ItemType Directory -Path $directProj -Force | Out-Null
        $direct = Invoke-InitAssert -InitPath (Join-Path $directKit 'init.ps1') -ProjectPath $directProj
        if ($direct.ExitCode -ne 0) { throw "Failed Test 29 (direct-clone): expected exit 0, got $($direct.ExitCode)." }
        if (-not $direct.Output.Contains('ASSERT|direct-clone|repository|OK')) { throw "Failed Test 29 (direct-clone): missing ASSERT line." }
        if (-not $direct.Output.Contains('PromptKit OS successfully configured')) { throw "Failed Test 29 (direct-clone): missing banner." }

        # Test 30: Submodule door - a real local-git submodule asserts status OK.
        $subKitRepo = Join-Path $TestRoot 'assert-sub-kitrepo'
        New-AssertKitCopy $subKitRepo
        & git -C $subKitRepo init -q
        & git -C $subKitRepo -c user.name=Fixture -c user.email=fixture@example.invalid add -A
        & git -C $subKitRepo -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m 'fixture kit'
        if ($LASTEXITCODE -ne 0) { throw "Failed Test 30 (submodule): kit repo commit failed with exit $LASTEXITCODE." }
        $subHost = Join-Path $TestRoot 'assert-sub-host'
        New-Item -ItemType Directory -Path $subHost -Force | Out-Null
        & git -C $subHost init -q
        $subKitUrl = $subKitRepo -replace '\\', '/'
        & git -c protocol.file.allow=always -C $subHost submodule add -q $subKitUrl .promptkit
        if ($LASTEXITCODE -ne 0) { throw "Failed Test 30 (submodule): 'git submodule add' failed with exit $LASTEXITCODE." }
        $sub = Invoke-InitAssert -InitPath (Join-Path $subHost '.promptkit/init.ps1') -ProjectPath $subHost
        if ($sub.ExitCode -ne 0) { throw "Failed Test 30 (submodule): expected exit 0, got $($sub.ExitCode)." }
        if (-not $sub.Output.Contains('ASSERT|submodule|status|OK')) { throw "Failed Test 30 (submodule): missing ASSERT line." }
        if (-not $sub.Output.Contains('PromptKit OS successfully configured')) { throw "Failed Test 30 (submodule): missing banner." }
        # The submodule door stages the kit at .promptkit/, so the relative
        # upgrade hint must still be advertised there (dangling-kit coverage
        # lives in Test 36).
        if (-not $sub.Output.Contains('.promptkit/init.ps1')) { throw "Failed Test 30 (submodule): missing relative upgrade hint." }

        # Test 31: Standalone door - the kit directory is the project root.
        $standaloneKit = Join-Path $TestRoot 'standalone_kit'
        New-AssertKitCopy $standaloneKit
        $standalone = Invoke-InitAssert -InitPath (Join-Path $standaloneKit 'init.ps1') -ProjectPath $standaloneKit
        if ($standalone.ExitCode -ne 0) { throw "Failed Test 31 (standalone): expected exit 0, got $($standalone.ExitCode)." }
        if (-not $standalone.Output.Contains('ASSERT|standalone|tree|OK')) { throw "Failed Test 31 (standalone): missing ASSERT line." }
        if (-not $standalone.Output.Contains('PromptKit OS successfully configured')) { throw "Failed Test 31 (standalone): missing banner." }

        # Test 31a: kit root == project root renders the relative root reference.
        # An absolute value is emitted as './/abs/path', which is not a path.
        $standaloneAgents = [System.IO.File]::ReadAllText((Join-Path $standaloneKit 'AGENTS.md'), [System.Text.Encoding]::UTF8)
        if (-not $standaloneAgents.Contains('(`./.`)')) { throw 'Failed Test 31a (standalone): kit reference is not the relative root.' }
        if ($standaloneAgents.Contains('.//') -or $standaloneAgents.Contains($standaloneKit)) { throw 'Failed Test 31a (standalone): kit reference rendered an absolute path.' }

        # Test 31b: the kit reference is path-bounded: kit '...\kitref_project-kit'
        # merely starts with project root '...\kitref_project', so a bare
        # StartsWith plus Substring emitted a truncated reference ('ject').
        $kitRefProj = Join-Path $TestRoot 'kitref_project'
        $kitRefKit = Join-Path $TestRoot 'kitref_project-kit'
        New-AssertKitCopy $kitRefKit
        New-Item -ItemType Directory -Path $kitRefProj -Force | Out-Null
        $kitRef = Invoke-InitAssert -InitPath (Join-Path $kitRefKit 'init.ps1') -ProjectPath $kitRefProj
        if ($kitRef.ExitCode -ne 0) { throw 'Failed Test 31b (kit reference): expected exit 0.' }
        $kitRefAgents = [System.IO.File]::ReadAllText((Join-Path $kitRefProj 'AGENTS.md'), [System.Text.Encoding]::UTF8)
        if (-not $kitRefAgents.Contains('(`./.promptkit`)')) { throw 'Failed Test 31b (kit reference): sibling kit did not fall back to .promptkit.' }
        if ($kitRefAgents.Contains('.//') -or $kitRefAgents.Contains($kitRefKit)) { throw 'Failed Test 31b (kit reference): sibling kit path leaked into the directive.' }
        if ($kitRef.Output.Contains((Join-Path $kitRefKit 'init.ps1'))) { throw 'Failed Test 31b (kit reference): sibling kit path leaked into the upgrade hint.' }
        # The sibling-kit scenario leaves .promptkit/ unstaged in the project, so
        # the summary warns about the dangling kit reference instead of
        # advertising an upgrade path that does not exist there.
        if (-not $kitRef.Output.Contains('not staged at .promptkit/')) { throw 'Failed Test 31b (kit reference): missing dangling-kit warning.' }

        # Test 32: Opt-out - PROMPTKIT_NO_PREFLIGHT=1 yields SKIP and proceeds.
        $env:PROMPTKIT_NO_PREFLIGHT = '1'
        $optout = Invoke-InitAssert -InitPath (Join-Path $courierKit 'init.ps1') -ProjectPath $courierProj
        Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue
        if ($optout.ExitCode -ne 0) { throw "Failed Test 32 (opt-out): expected exit 0, got $($optout.ExitCode)." }
        if (-not $optout.Output.Contains('ASSERT|skipped|USER_OPT_OUT|SKIP')) { throw "Failed Test 32 (opt-out): missing SKIP line." }
        if (-not $optout.Output.Contains('PromptKit OS successfully configured')) { throw "Failed Test 32 (opt-out): missing banner." }

        # Test 33: Unexpected git status is fail-closed to INCOMPLETE (exit 2, no banner).
        $fakeGitDir = Join-Path $TestRoot 'assert-fakegit'
        New-Item -ItemType Directory -Path $fakeGitDir -Force | Out-Null
        if ($IsWindows) {
            [System.IO.File]::WriteAllText((Join-Path $fakeGitDir 'git.cmd'), "@echo off`r`nexit /b 42`r`n", $utf8NoBom)
        } else {
            $fakeGit = Join-Path $fakeGitDir 'git'
            [System.IO.File]::WriteAllText($fakeGit, "#!/usr/bin/env bash`nexit 42`n", $utf8NoBom)
            & chmod +x $fakeGit
        }
        $gitfailProj = Join-Path $TestRoot 'assert-gitfail-proj'
        New-Item -ItemType Directory -Path $gitfailProj -Force | Out-Null
        $savedPath = $env:PATH
        $env:PATH = $fakeGitDir + [System.IO.Path]::PathSeparator + $savedPath
        try {
            $gitfail = Invoke-InitAssert -InitPath (Join-Path $directKit 'init.ps1') -ProjectPath $gitfailProj
        } finally {
            $env:PATH = $savedPath
        }
        if ($gitfail.ExitCode -ne 2) { throw "Failed Test 33 (unexpected git): expected exit 2, got $($gitfail.ExitCode)." }
        if (-not $gitfail.Output.Contains('ASSERT|unknown|host_git|INCOMPLETE')) { throw "Failed Test 33 (unexpected git): missing INCOMPLETE line." }
        if ($gitfail.Output.Contains('PromptKit OS successfully configured')) { throw "Failed Test 33 (unexpected git): banner printed on INCOMPLETE." }

        # Test 34: GitHub template gate - .github PR/issue templates are created
        # only when tracking is GitHub (or GitHub projection); a local-tracking
        # install skips them instead of adding .github noise to a non-GitHub project.
        $gateProj = Join-Path $TestRoot 'template-gate-proj'
        $gateKit = Join-Path $TestRoot 'template-gate-kit'
        New-AssertKitCopy $gateKit
        New-Item -ItemType Directory -Path $gateProj -Force | Out-Null
        $gate = Invoke-InitAssert -InitPath (Join-Path $gateKit 'init.ps1') -ProjectPath $gateProj
        if ($gate.ExitCode -ne 0) { throw "Failed Test 34 (template gate): expected exit 0, got $($gate.ExitCode)." }
        if (Test-Path -LiteralPath (Join-Path $gateProj '.github')) { throw 'Failed Test 34 (template gate): .github created under local tracking.' }
        if (-not $gate.Output.Contains('Skipped: .github PR/issue templates')) { throw 'Failed Test 34 (template gate): missing SKIP line.' }
        $gateGhProj = Join-Path $TestRoot 'template-gate-github-proj'
        $gateGhKit = Join-Path $TestRoot 'template-gate-github-kit'
        New-AssertKitCopy $gateGhKit
        New-Item -ItemType Directory -Path $gateGhProj -Force | Out-Null
        $gateGh = Invoke-InitAssert -InitPath (Join-Path $gateGhKit 'init.ps1') -ProjectPath $gateGhProj -ExtraArgs @('-Tracking', 'github')
        if ($gateGh.ExitCode -ne 0) { throw "Failed Test 34 (template gate): expected exit 0, got $($gateGh.ExitCode)." }
        if (-not (Test-Path -LiteralPath (Join-Path $gateGhProj '.github/pull_request_template.md'))) { throw 'Failed Test 34 (template gate): PR template not created under GitHub tracking.' }
        if (-not (Test-Path -LiteralPath (Join-Path $gateGhProj '.github/ISSUE_TEMPLATE/task.md'))) { throw 'Failed Test 34 (template gate): issue template not created under GitHub tracking.' }
        if (-not $gateGh.Output.Contains('Created: .github/pull_request_template.md')) { throw 'Failed Test 34 (template gate): missing PR Created line.' }
        if (-not $gateGh.Output.Contains('Created: .github/ISSUE_TEMPLATE/task.md')) { throw 'Failed Test 34 (template gate): missing issue Created line.' }

        # Test 35: freshness-aware hint - a fresh project (no tracked files) is
        # told about pk:onboard repo intake; a project with committed code is not.
        $freshProj = Join-Path $TestRoot 'fresh-hint-proj'
        $freshKit = Join-Path $TestRoot 'fresh-hint-kit'
        New-AssertKitCopy $freshKit
        New-Item -ItemType Directory -Path $freshProj -Force | Out-Null
        & git -C $freshProj init -q
        $fresh = Invoke-InitAssert -InitPath (Join-Path $freshKit 'init.ps1') -ProjectPath $freshProj
        if ($fresh.ExitCode -ne 0) { throw "Failed Test 35 (freshness): expected exit 0, got $($fresh.ExitCode)." }
        if (-not $fresh.Output.Contains('Fresh project (no code yet)?')) { throw 'Failed Test 35 (freshness): missing fresh-project hint.' }
        if (-not $fresh.Output.Contains('pk:onboard')) { throw 'Failed Test 35 (freshness): missing pk:onboard hint.' }
        $busyProj = Join-Path $TestRoot 'busy-hint-proj'
        $busyKit = Join-Path $TestRoot 'busy-hint-kit'
        New-AssertKitCopy $busyKit
        New-Item -ItemType Directory -Path $busyProj -Force | Out-Null
        & git -C $busyProj init -q
        [System.IO.File]::WriteAllText((Join-Path $busyProj 'main.rs'), "fn main() {}`n", $utf8NoBom)
        & git -C $busyProj -c user.name=Fixture -c user.email=fixture@example.invalid add -A
        & git -C $busyProj -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m 'fixture code'
        $busy = Invoke-InitAssert -InitPath (Join-Path $busyKit 'init.ps1') -ProjectPath $busyProj
        if ($busy.ExitCode -ne 0) { throw "Failed Test 35 (freshness): expected exit 0, got $($busy.ExitCode)." }
        if ($busy.Output.Contains('Fresh project (no code yet)?')) { throw 'Failed Test 35 (freshness): project with committed code treated as fresh.' }

        # Test 35b: courier door freshness - the courier extracts the kit into
        # .promptkit/ and stages it before running the installer, so the project
        # is empty of project content even though .promptkit/ is tracked. The
        # hint must still fire; counting the installer-owned tree as "code"
        # would hide it in the flow a fresh project actually uses.
        $courierFreshProj = Join-Path $TestRoot 'courier-fresh-proj'
        $courierFreshKit = Join-Path $TestRoot 'courier-fresh-kit'
        New-AssertKitCopy $courierFreshKit
        Add-CompleteKitStage -ProjectPath $courierFreshProj -KitPath $courierFreshKit
        & git -C $courierFreshProj init -q
        & git -C $courierFreshProj -c user.name=Fixture -c user.email=fixture@example.invalid add -A
        $courierFresh = Invoke-InitAssert -InitPath (Join-Path $courierFreshKit 'init.ps1') -ProjectPath $courierFreshProj
        if ($courierFresh.ExitCode -ne 0) { throw "Failed Test 35b (courier freshness): expected exit 0, got $($courierFresh.ExitCode)." }
        if (-not $courierFresh.Output.Contains('Fresh project (no code yet)?')) { throw 'Failed Test 35b (courier freshness): staged kit suppressed the fresh-project hint.' }
        if (-not $courierFresh.Output.Contains('pk:onboard')) { throw 'Failed Test 35b (courier freshness): missing pk:onboard hint.' }

        # Test 35c: submodule door freshness - a submodule install adds a
        # .promptkit gitlink and a .gitmodules entry, which are installer-owned
        # rather than project content. The hint must still fire.
        $subFreshProj = Join-Path $TestRoot 'submodule-fresh-proj'
        $subFreshKit = Join-Path $TestRoot 'submodule-fresh-kit'
        New-AssertKitCopy $subFreshKit
        New-Item -ItemType Directory -Path $subFreshProj -Force | Out-Null
        & git -C $subFreshProj init -q
        & git -C $subFreshProj -c user.name=Fixture -c user.email=fixture@example.invalid commit -q --allow-empty -m 'fixture root'
        $subFreshSha = (& git -C $subFreshProj rev-parse HEAD).Trim()
        [System.IO.File]::WriteAllText((Join-Path $subFreshProj '.gitmodules'), "[submodule `".promptkit`"]`n`tpath = .promptkit`n`turl = https://example.invalid/kit.git`n", $utf8NoBom)
        & git -C $subFreshProj add .gitmodules
        & git -C $subFreshProj update-index --add --cacheinfo "160000,$subFreshSha,.promptkit"
        $subFresh = Invoke-InitAssert -InitPath (Join-Path $subFreshKit 'init.ps1') -ProjectPath $subFreshProj
        if ($subFresh.ExitCode -ne 0) { throw "Failed Test 35c (submodule freshness): expected exit 0, got $($subFresh.ExitCode)." }
        if (-not $subFresh.Output.Contains('Fresh project (no code yet)?')) { throw 'Failed Test 35c (submodule freshness): gitlink suppressed the fresh-project hint.' }
        if (-not $subFresh.Output.Contains('pk:onboard')) { throw 'Failed Test 35c (submodule freshness): missing pk:onboard hint.' }

        # Test 36: dangling-kit warning - when the engine runs from outside the
        # project and nothing staged the kit at .promptkit/, the summary warns
        # and suppresses the upgrade hint that points at the unstaged path.
        $dangleProj = Join-Path $TestRoot 'dangle-hint-proj'
        $dangleKit = Join-Path $TestRoot 'dangle-hint-kit'
        New-AssertKitCopy $dangleKit
        New-Item -ItemType Directory -Path $dangleProj -Force | Out-Null
        # Lite profile so the suppressed "Upgrade anytime" hint is genuinely
        # exercised (it is a lite-only summary line).
        $dangle = Invoke-InitAssert -InitPath (Join-Path $dangleKit 'init.ps1') -ProjectPath $dangleProj -InstallProfile lite
        if ($dangle.ExitCode -ne 0) { throw "Failed Test 36 (dangling kit): expected exit 0, got $($dangle.ExitCode)." }
        if (-not $dangle.Output.Contains('not staged at .promptkit/')) { throw 'Failed Test 36 (dangling kit): missing warning.' }
        if (-not $dangle.Output.Contains('Stage the kit:')) { throw 'Failed Test 36 (dangling kit): missing staging hint.' }
        if ($dangle.Output.Contains('Upgrade anytime: .promptkit/init.ps1')) { throw 'Failed Test 36 (dangling kit): upgrade hint points at an unstaged kit path.' }

        # Test 36b: staged kit - when .promptkit/ carries a COMPLETE kit (the
        # installer plus every row of scripts/setup-assert-files.txt), the
        # relative upgrade hint is advertised and no warning prints.
        $stagedProj = Join-Path $TestRoot 'staged-hint-proj'
        $stagedKit = Join-Path $TestRoot 'staged-hint-kit'
        New-AssertKitCopy $stagedKit
        Add-CompleteKitStage -ProjectPath $stagedProj -KitPath $stagedKit
        # Lite profile so the "Upgrade anytime" hint is genuinely exercised.
        $staged = Invoke-InitAssert -InitPath (Join-Path $stagedKit 'init.ps1') -ProjectPath $stagedProj -InstallProfile lite
        if ($staged.ExitCode -ne 0) { throw "Failed Test 36b (staged kit): expected exit 0, got $($staged.ExitCode)." }
        if (-not $staged.Output.Contains('Upgrade anytime: .promptkit/init.ps1')) { throw 'Failed Test 36b (staged kit): missing relative upgrade hint.' }
        if ($staged.Output.Contains('not staged at .promptkit/')) { throw 'Failed Test 36b (staged kit): dangling warning printed for a staged kit.' }
        if ($staged.Output.Contains('incomplete copy of the kit')) { throw 'Failed Test 36b (staged kit): incomplete-copy warning printed for a complete kit.' }

        # Test 36c: partial kit - a .promptkit/ holding the installer but not the
        # workflow entry point is a partial copy: the upgrade hint would point at
        # pk:* commands that cannot resolve, so the warning must fire and the
        # hint must be suppressed. The recovery advice must also match the state
        # AND the door: this copy has no .git, so it is a courier install, which
        # has no upstream to pull from and must be replaced - and the advice must
        # warn that the removal deletes local edits and untracked files.
        $partialProj = Join-Path $TestRoot 'partial-hint-proj'
        $partialKit = Join-Path $TestRoot 'partial-hint-kit'
        New-AssertKitCopy $partialKit
        New-Item -ItemType Directory -Path (Join-Path $partialProj '.promptkit') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $partialKit 'init.ps1') -Destination (Join-Path $partialProj '.promptkit/init.ps1') -Force
        $partial = Invoke-InitAssert -InitPath (Join-Path $partialKit 'init.ps1') -ProjectPath $partialProj -InstallProfile lite
        if ($partial.ExitCode -ne 0) { throw "Failed Test 36c (partial kit): expected exit 0, got $($partial.ExitCode)." }
        if (-not $partial.Output.Contains('incomplete copy of the kit')) { throw 'Failed Test 36c (partial kit): missing incomplete-copy warning.' }
        if (-not $partial.Output.Contains('Replace it: Remove-Item -Recurse -Force .promptkit')) { throw 'Failed Test 36c (partial kit): missing PowerShell removal advice.' }
        if ($partial.Output.Contains('rm -rf .promptkit')) { throw 'Failed Test 36c (partial kit): printed a bash command from the PowerShell installer.' }
        if (-not $partial.Output.Contains('check .promptkit/ for local edits and untracked files first')) { throw 'Failed Test 36c (partial kit): missing the data-loss warning before removal.' }
        if (-not $partial.Output.Contains('--force overlays the existing directory without cleaning it')) { throw 'Failed Test 36c (partial kit): missing --force caveat.' }
        if ($partial.Output.Contains('Restore it in place:')) { throw 'Failed Test 36c (partial kit): courier-door copy printed the submodule restore advice.' }
        if ($partial.Output.Contains('Upgrade anytime: .promptkit/init.ps1')) { throw 'Failed Test 36c (partial kit): upgrade hint advertised from a partial kit copy.' }
        if ($partial.Output.Contains('Stage the kit:')) { throw 'Failed Test 36c (partial kit): printed stage-from-scratch advice, which cannot succeed on a non-empty .promptkit/.' }

        # Test 36d: the reviewer's tree - .promptkit/ holding exactly the
        # installer and the workflow entry point. Both files exist, so a two-file
        # check called this staged and advertised an upgrade path whose scripts/
        # directory was absent; the manifest-driven check must call it incomplete.
        $twoFileProj = Join-Path $TestRoot 'twofile-hint-proj'
        $twoFileKit = Join-Path $TestRoot 'twofile-hint-kit'
        New-AssertKitCopy $twoFileKit
        New-Item -ItemType Directory -Path (Join-Path $twoFileProj '.promptkit/workflows') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $twoFileKit 'init.ps1') -Destination (Join-Path $twoFileProj '.promptkit/init.ps1') -Force
        Copy-Item -LiteralPath (Join-Path $twoFileKit 'workflows/route.md') -Destination (Join-Path $twoFileProj '.promptkit/workflows/route.md') -Force
        $twoFile = Invoke-InitAssert -InitPath (Join-Path $twoFileKit 'init.ps1') -ProjectPath $twoFileProj -InstallProfile lite
        if ($twoFile.ExitCode -ne 0) { throw "Failed Test 36d (two-file kit): expected exit 0, got $($twoFile.ExitCode)." }
        if (-not $twoFile.Output.Contains('incomplete copy of the kit')) { throw 'Failed Test 36d (two-file kit): two-file copy treated as a complete kit.' }
        if ($twoFile.Output.Contains('Upgrade anytime: .promptkit/init.ps1')) { throw 'Failed Test 36d (two-file kit): upgrade hint advertised from a two-file kit copy.' }

        # Test 36e: a complete kit minus one manifest row is still incomplete.
        # The scripts/ directory is the row a two-file copy misses, so removing
        # it from an otherwise complete stage must flip the verdict back.
        $missingRowProj = Join-Path $TestRoot 'missingrow-hint-proj'
        $missingRowKit = Join-Path $TestRoot 'missingrow-hint-kit'
        New-AssertKitCopy $missingRowKit
        Add-CompleteKitStage -ProjectPath $missingRowProj -KitPath $missingRowKit
        Remove-Item -LiteralPath (Join-Path $missingRowProj '.promptkit/scripts') -Recurse -Force
        $missingRow = Invoke-InitAssert -InitPath (Join-Path $missingRowKit 'init.ps1') -ProjectPath $missingRowProj -InstallProfile lite
        if ($missingRow.ExitCode -ne 0) { throw "Failed Test 36e (missing manifest row): expected exit 0, got $($missingRow.ExitCode)." }
        if (-not $missingRow.Output.Contains('incomplete copy of the kit')) { throw 'Failed Test 36e (missing manifest row): kit missing a manifest row treated as complete.' }
        if ($missingRow.Output.Contains('Upgrade anytime: .promptkit/init.ps1')) { throw 'Failed Test 36e (missing manifest row): upgrade hint advertised from an incomplete kit copy.' }

        # Test 36f: submodule door - the same incomplete copy, but installed as a
        # git submodule. A submodule DOES have an upstream, so the recovery is an
        # in-place restore, not a replacement: "git submodule update --init
        # --force" checks the recorded commit out again, which brings back deleted
        # kit files. The plain "--init" form does nothing once the recorded commit
        # is already checked out, which is why the advice carries --force. The
        # scenario runs the advertised command and asserts it restores the file.
        $subDoorKitRepo = Join-Path $TestRoot 'subdoor-kitrepo'
        $subDoorHost = Join-Path $TestRoot 'subdoor-host'
        $subDoorRunner = Join-Path $TestRoot 'subdoor-runner'
        New-AssertKitCopy $subDoorKitRepo
        & git -C $subDoorKitRepo init -q
        & git -C $subDoorKitRepo -c user.name=Fixture -c user.email=fixture@example.invalid add -A
        & git -C $subDoorKitRepo -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m 'fixture kit'
        New-Item -ItemType Directory -Path $subDoorHost -Force | Out-Null
        & git -C $subDoorHost init -q
        $subDoorUrl = $subDoorKitRepo -replace '\\', '/'
        & git -c protocol.file.allow=always -C $subDoorHost submodule add -q $subDoorUrl .promptkit
        if ($LASTEXITCODE -ne 0) { throw 'Failed Test 36f (submodule door): fixture submodule add failed.' }
        # A real submodule records .git as a file (a gitdir pointer), not a directory.
        if (-not (Test-Path -LiteralPath (Join-Path $subDoorHost '.promptkit/.git') -PathType Leaf)) { throw 'Failed Test 36f (submodule door): expected .promptkit/.git to be a file.' }
        Remove-Item -LiteralPath (Join-Path $subDoorHost '.promptkit/workflows/debug.md') -Force
        New-AssertKitCopy $subDoorRunner
        $subDoor = Invoke-InitAssert -InitPath (Join-Path $subDoorRunner 'init.ps1') -ProjectPath $subDoorHost -InstallProfile lite
        if ($subDoor.ExitCode -ne 0) { throw "Failed Test 36f (submodule door): expected exit 0, got $($subDoor.ExitCode)." }
        if (-not $subDoor.Output.Contains('incomplete copy of the kit')) { throw 'Failed Test 36f (submodule door): incomplete submodule kit treated as complete.' }
        if (-not $subDoor.Output.Contains('Restore it in place: git submodule update --init --force .promptkit')) { throw 'Failed Test 36f (submodule door): missing in-place restore advice.' }
        if (-not $subDoor.Output.Contains('untracked files such as notes are kept')) { throw 'Failed Test 36f (submodule door): missing the --force explanation.' }
        if ($subDoor.Output.Contains('Remove-Item -Recurse -Force .promptkit')) { throw 'Failed Test 36f (submodule door): told to delete a copy that can be restored in place.' }
        if ($subDoor.Output.Contains('Upgrade anytime: .promptkit/init.ps1')) { throw 'Failed Test 36f (submodule door): upgrade hint advertised from an incomplete submodule kit.' }
        if (Test-Path -LiteralPath (Join-Path $subDoorHost '.promptkit/workflows/debug.md')) { throw 'Failed Test 36f (submodule door): fixture did not actually remove the workflow.' }
        & git -c protocol.file.allow=always -C $subDoorHost submodule update --init --force .promptkit 2>&1 | Out-Null
        if (-not (Test-Path -LiteralPath (Join-Path $subDoorHost '.promptkit/workflows/debug.md'))) { throw 'Failed Test 36f (submodule door): the advertised restore command did not bring the file back.' }

        # Test 36g: an EMPTY scripts/ directory satisfies the "scripts|dir" row and
        # nothing else. The installer sources scripts/terminal-picker.ps1 before it
        # parses an argument, so such a copy cannot run - it must be called
        # incomplete instead of advertising an upgrade command that dies.
        $emptyScriptsProj = Join-Path $TestRoot 'emptyscripts-hint-proj'
        $emptyScriptsKit = Join-Path $TestRoot 'emptyscripts-hint-kit'
        New-AssertKitCopy $emptyScriptsKit
        Add-CompleteKitStage -ProjectPath $emptyScriptsProj -KitPath $emptyScriptsKit
        Remove-Item -LiteralPath (Join-Path $emptyScriptsProj '.promptkit/scripts') -Recurse -Force
        New-Item -ItemType Directory -Path (Join-Path $emptyScriptsProj '.promptkit/scripts') -Force | Out-Null
        if (Test-Path -LiteralPath (Join-Path $emptyScriptsProj '.promptkit/scripts/terminal-picker.ps1')) { throw 'Failed Test 36g (empty scripts): fixture still holds the picker.' }
        $emptyScripts = Invoke-InitAssert -InitPath (Join-Path $emptyScriptsKit 'init.ps1') -ProjectPath $emptyScriptsProj -InstallProfile lite
        if ($emptyScripts.ExitCode -ne 0) { throw "Failed Test 36g (empty scripts): expected exit 0, got $($emptyScripts.ExitCode)." }
        if (-not $emptyScripts.Output.Contains('incomplete copy of the kit')) { throw 'Failed Test 36g (empty scripts): empty scripts/ directory treated as a complete kit.' }
        if ($emptyScripts.Output.Contains('Upgrade anytime: .promptkit/init.ps1')) { throw 'Failed Test 36g (empty scripts): upgrade hint advertised from a kit copy with an empty scripts/ directory.' }

        # Test 36h: a missing Lite workflow is incomplete too. The summary tells
        # the user to run pk:route, pk:debug, pk:commit, pk:checkpoint, pk:sync
        # and pk:profile, so a copy without workflows/debug.md cannot deliver what
        # it advertises.
        $missingWfProj = Join-Path $TestRoot 'missingwf-hint-proj'
        $missingWfKit = Join-Path $TestRoot 'missingwf-hint-kit'
        New-AssertKitCopy $missingWfKit
        Add-CompleteKitStage -ProjectPath $missingWfProj -KitPath $missingWfKit
        Remove-Item -LiteralPath (Join-Path $missingWfProj '.promptkit/workflows/debug.md') -Force
        $missingWf = Invoke-InitAssert -InitPath (Join-Path $missingWfKit 'init.ps1') -ProjectPath $missingWfProj -InstallProfile lite
        if ($missingWf.ExitCode -ne 0) { throw "Failed Test 36h (missing Lite workflow): expected exit 0, got $($missingWf.ExitCode)." }
        if (-not $missingWf.Output.Contains('incomplete copy of the kit')) { throw 'Failed Test 36h (missing Lite workflow): kit missing a Lite workflow treated as complete.' }
        if ($missingWf.Output.Contains('Upgrade anytime: .promptkit/init.ps1')) { throw 'Failed Test 36h (missing Lite workflow): upgrade hint advertised from an incomplete kit copy.' }
    } finally {
        if ($null -eq $savedNoInteractive) { Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue } else { $env:PROMPTKIT_NO_INTERACTIVE = $savedNoInteractive }
        if ($null -eq $savedNoPreflight) { Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue } else { $env:PROMPTKIT_NO_PREFLIGHT = $savedNoPreflight }
    }

    Write-Host "init.ps1 non-destructive update, CRLF/LF compatibility, duplicate/reversed/incomplete markers, literal $, UTF-8 emoji/CJK, directory target, strict byte-idempotency, host selection, add-host, custom-target, containment, transaction rollback, GitHub-template tracking gate, freshness-aware hint (empty, busy, courier-staged, submodule-staged), dangling-kit warning (unstaged, complete, partial, two-file, missing-manifest-row, empty-scripts, missing-lite-workflow) with install-door-matched recovery advice (courier replace with a data-loss warning, submodule in-place restore verified end to end), and install-door structural-assert tests passed." -ForegroundColor Green
} finally {
    Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
}
