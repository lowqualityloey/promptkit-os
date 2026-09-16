# Regression tests for non-destructive init.ps1 directive updates (PowerShell).
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-init-safety-tests.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "../..")).Path

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

    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $CrlfRoot | Out-Null
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

    # Test 10: Idempotency re-run on CRLF file
    & pwsh -NoProfile -File $initScriptPath -ProjectRoot $CrlfRoot | Out-Null
    $reRunContent = [System.IO.File]::ReadAllText($crlfAgentsPath, [System.Text.Encoding]::UTF8)
    $reRunLines = $reRunContent -split "\r?\n"
    $reRunStartCount = @($reRunLines | Where-Object { $_ -eq '<!-- PROMPTKIT_START -->' }).Count
    if ($reRunStartCount -ne 1) {
        throw "Failed Test 10 (Idempotency): Expected 1 PROMPTKIT_START after re-run, found ${reRunStartCount}."
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

    Write-Host "init.ps1 non-destructive update, CRLF/LF compatibility, duplicate/reversed/incomplete markers, literal $, UTF-8 emoji/CJK, directory target, strict byte-idempotency, host selection, add-host, and custom-target tests passed." -ForegroundColor Green
} finally {
    Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
}
