$ErrorActionPreference = 'Stop'
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$scanner = Join-Path $repo 'scripts/check-harness-security.ps1'
$PSDefaultParameterValues['Remove-Item:Force'] = $true

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('pk-harness-' + [guid]::NewGuid())
$root = Join-Path $tmp 'project with spaces'
$utf8 = [Text.UTF8Encoding]::new($false)
function Write-Fixture($relative, $content) {
    [IO.File]::WriteAllText((Join-Path $root $relative), $content, $utf8)
}
function Assert-Scan($expected, $rule = '') {
    $script:output = (& pwsh -NoProfile -File $scanner -Root $root 2>&1) -join "`n"
    if ($LASTEXITCODE -ne $expected) { throw "Expected exit $expected, got $LASTEXITCODE" }
    if ($rule -and -not $output.Contains($rule)) { throw "Missing rule $rule" }
    if ($secret -and $output.Contains($secret)) { throw 'Secret value leaked' }
}
try {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    Assert-Scan 0 'FIXED_SCOPE_ONLY'
    Write-Fixture '.env.example' 'API_KEY=replace_me'
    Assert-Scan 0
    $secret = 'AKIA' + ('0' * 16)
    Write-Fixture '.env' $secret
    $hash = (Get-FileHash (Join-Path $root '.env')).Hash
    Assert-Scan 1 'SUSPECTED_SECRET|.env'
    if ((Get-FileHash (Join-Path $root '.env')).Hash -ne $hash) { throw 'Scanner modified content' }
    Remove-Item (Join-Path $root '.env')
    New-Item -ItemType Directory -Path (Join-Path $root '.env') | Out-Null
    Assert-Scan 2 'UNREADABLE_OR_SPECIAL|.env'
    Remove-Item (Join-Path $root '.env')
    Write-Fixture '.env' ('x' * 65537)
    Assert-Scan 2 'SIZE_LIMIT|.env'
    Write-Fixture '.env' ('x' * 65536)
    Assert-Scan 0
    Remove-Item (Join-Path $root '.env')
    Write-Fixture '.mcp.json' "{`"autoApprove`":`ntrue}"
    Assert-Scan 1 'BROAD_APPROVAL|.mcp.json'
    Remove-Item (Join-Path $root '.mcp.json')
    New-Item -ItemType Directory -Path (Join-Path $root '.claude') | Out-Null
    Write-Fixture '.claude/settings.json' '{"permissions":{"defaultMode":"bypassPermissions","allow":["Bash(*)"]}}'
    Assert-Scan 1 'PERMISSION_BYPASS|.claude/settings.json'
    if (-not $output.Contains('BROAD_PERMISSION|.claude/settings.json')) { throw 'Missing broad permission warning' }
    Remove-Item (Join-Path $root '.claude/settings.json')
    [IO.File]::WriteAllBytes((Join-Path $root '.env'), [byte[]]@(0))
    Assert-Scan 2 'UNSUPPORTED_ENCODING|.env'
    Remove-Item (Join-Path $root '.env')
    & git -C $root init -q
    Write-Fixture '.env' 'API_KEY=replace_me'
    & git -C $root add -- .env
    Write-Fixture '.gitignore' ".env`n"
    $hash = (Get-FileHash (Join-Path $root '.git/index')).Hash
    Assert-Scan 1 'TRACKED_SENSITIVE|.env'
    if ($output.Contains('IGNORE_GAP|.env')) { throw 'Tracked ignored path incorrectly reported as uncovered' }
    if ((Get-FileHash (Join-Path $root '.git/index')).Hash -ne $hash) { throw 'Index changed' }
    Write-Fixture '.gitignore' ''
    Assert-Scan 1 'IGNORE_GAP|.env'
    & git -C $root rm --cached -q -- .env
    Write-Fixture '.gitignore' ".env`n"
    Assert-Scan 0
    Remove-Item (Join-Path $root '.env')
    # Windows directory junctions require no symlink privilege; Unix uses a link.
    $outside = New-Item -ItemType Directory -Path (Join-Path $tmp 'outside')
    $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $linkType -Path (Join-Path $root '.cursor') -Target $outside.FullName | Out-Null
    Assert-Scan 2 'SYMLINK|.cursor/mcp.json'
    Remove-Item (Join-Path $root '.cursor')
    $env:PROMPTKIT_NO_INTERACTIVE = '1'
    $install = (& pwsh -NoProfile -File (Join-Path $repo 'init.ps1') -ProjectRoot $root) -join "`n"
    if ($LASTEXITCODE -ne 0 -or -not $install.Contains('PREFLIGHT|SCOPE|')) { throw 'Noninteractive preflight did not run' }
    $env:PROMPTKIT_NO_PREFLIGHT = '1'
    $install = (& pwsh -NoProfile -File (Join-Path $repo 'init.ps1') -ProjectRoot $root) -join "`n"
    if ($LASTEXITCODE -ne 0 -or -not $install.Contains('PREFLIGHT|SKIPPED|USER_OPT_OUT') -or $install.Contains('PREFLIGHT|SCOPE|')) { throw 'Independent opt-out failed' }
    Write-Output 'Harness security regression tests passed.'
} finally {
    Remove-Item Env:PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
    Remove-Item Env:PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue
    if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}
