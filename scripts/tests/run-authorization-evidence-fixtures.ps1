$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$validator = Join-Path $repoRoot 'scripts/validate-authorization-evidence.ps1'
$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
$taskDir = Join-Path $fixtureRoot 'docs/tasks'
New-Item -ItemType Directory -Path $taskDir -Force | Out-Null

function Invoke-Git([string[]]$Arguments) {
    $output = & git.exe -C $fixtureRoot @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git failed: $($Arguments -join ' '): $output" }
}

function Write-Task([string]$Boundary, [string]$BatchPath = 'N/A', [string]$BatchMode = 'Gated Mode', [bool]$IncludeFields = $true) {
    $lines = @('# Task Record', "- **Mode**: ``$BatchMode``", "- **Batch Authorization**: ``$BatchPath``")
    $lines += '<a id="AUTHZ-example-001"></a>'
    if ($IncludeFields) {
        $lines += "- **Declared Boundary**: ``$Boundary``"
        $lines += '- **Verbatim Human Instruction**: ``Run M1 through review only``'
        $lines += '- **Instruction Source**: ``user message 1``'
        $lines += '- **Frozen Task and Milestone Scope**: ``M1 files only``'
    }
    $lines += "- **Batch Authorization Reference**: ``$BatchPath``"
    $lines += '- **Commit Evidence Entry**: ``abc123 message; Authorization Checkpoint Reference: AUTHZ-example-001; Authorization Source: user message 1``'
    Set-Content -LiteralPath (Join-Path $taskDir 'TASK-2026-01-01-example.md') -Value $lines -Encoding utf8
}

function Assert-Case([string]$Name, [int]$Expected) {
    $output = & pwsh -ExecutionPolicy Bypass -NoProfile -File $validator -Root $fixtureRoot -Baseline $script:baseline 2>&1 | Out-String
    $actual = $LASTEXITCODE
    if ($actual -ne $Expected) { throw "$Name expected exit $Expected, got ${actual}: $output" }
    Write-Output "PASS|$Name"
}

try {
    Invoke-Git @('init', '-q')
    Invoke-Git @('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '--allow-empty', '-qm', 'baseline')
    Write-Task 'review'
    Invoke-Git @('add', 'docs/tasks/TASK-2026-01-01-example.md')
    Invoke-Git @('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'seed legacy evidence')
    $script:baseline = (& git.exe -C $fixtureRoot rev-parse HEAD).Trim()
    Assert-Case 'valid run checkpoint' 0

    $taskPath = Join-Path $taskDir 'TASK-2026-01-01-example.md'
    (Get-Content -LiteralPath $taskPath -Raw).Replace('Authorization Source: user message 1', 'Authorization Source:') | Set-Content -LiteralPath $taskPath -Encoding utf8
    Assert-Case 'missing authorization source' 1

    Write-Task 'review'
    (Get-Content -LiteralPath $taskPath -Raw).Replace('<a id="AUTHZ-example-001"></a>', '<a id="AUTHZ-other-001"></a>') | Set-Content -LiteralPath $taskPath -Encoding utf8
    Assert-Case 'unresolved checkpoint' 1

    Write-Task 'review' 'docs/tasks/batch-example.md' 'Approved Batch Mode'
    Set-Content -LiteralPath (Join-Path $taskDir 'batch-example.md') -Value @('# Batch', '- **Declared Boundary**: `pr`', '- **Permitted Actions**: `local commits`', '- **Milestone Scope**: `M1`') -Encoding utf8
    Assert-Case 'conflicting batch boundary' 1

    Write-Task 'review' 'docs/tasks/batch-example.md' 'Approved Batch Mode'
    Set-Content -LiteralPath (Join-Path $taskDir 'batch-example.md') -Value @('# Batch', '- **Declared Boundary**: `review`', '- **Permitted Actions**: `local commits`', '- **Milestone Scope**: `M1`') -Encoding utf8
    Assert-Case 'valid batch authorization' 0
    $batchPath = Join-Path $taskDir 'batch-example.md'
    (Get-Content -LiteralPath $batchPath -Raw).Replace('`review`', 'review') | Set-Content -LiteralPath $batchPath -Encoding utf8
    Assert-Case 'batch boundary without required markup' 1
    (Get-Content -LiteralPath $batchPath -Raw).Replace('Declared Boundary**: review', 'Declared Boundary**: `final`') | Set-Content -LiteralPath $batchPath -Encoding utf8
    Assert-Case 'unsupported batch boundary' 1
    (Get-Content -LiteralPath $batchPath -Raw).Replace('`final`', '`review`') | Set-Content -LiteralPath $batchPath -Encoding utf8
    Assert-Case 'restored valid batch boundary' 0

    Set-Content -LiteralPath $batchPath -Value @('# Batch', '- **Declared Boundary**: `review`', '- **Permitted Actions**: `N/A`', '- **Milestone Scope**: `None`') -Encoding utf8
    Assert-Case 'placeholder batch actions and scope fail' 1

    Write-Task 'review'
    Set-Content -LiteralPath (Join-Path $taskDir 'TASK-2026-01-02-foreign.md') -Value @('# Foreign Task', '<a id="AUTHZ-foreign-001"></a>', '- **Declared Boundary**: `review`', '- **Verbatim Human Instruction**: `Run M1 through review only`', '- **Instruction Source**: `user message 1`', '- **Frozen Task and Milestone Scope**: `M1 files only`') -Encoding utf8
    Set-Content -LiteralPath (Join-Path $taskDir 'TASK-2026-01-03-borrowed.md') -Value @('# Borrowed Checkpoint', '- **Mode**: `Gated Mode`', '- **Batch Authorization**: `N/A`', '- **Commit Evidence Entry**: `abc123 message; Authorization Checkpoint Reference: AUTHZ-foreign-001; Authorization Source: user message 1`') -Encoding utf8
    Assert-Case 'checkpoint cannot be borrowed from another Task Record' 1
    Write-Output 'AUTHORIZATION_FIXTURES|PASS|10 scenarios'
} finally {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
