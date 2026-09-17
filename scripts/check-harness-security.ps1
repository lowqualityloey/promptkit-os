param([string]$Root = '.')
$ErrorActionPreference = 'Stop'
$findings = $false
$incomplete = $false
try {
    $item = Get-Item -LiteralPath $Root -Force
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid root' }
    $rootPath = $item.FullName
} catch {
    Write-Output 'PREFLIGHT|INCOMPLETE|ROOT'
    exit 2
}
function Report($severity, $rule, $location) {
    Write-Output "PREFLIGHT|$severity|$rule|$location"
    if ($severity -eq 'WARNING') { $script:findings = $true }
    if ($severity -eq 'INCOMPLETE') { $script:incomplete = $true }
}
try {
    $paths = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'harness-security-paths.txt')
    $rules = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'harness-security-rules.txt')
} catch { Report INCOMPLETE RULES '.'; exit 2 }
Write-Output 'PREFLIGHT|SCOPE|20 fixed paths; 65536 bytes per file; no recursive scan or credential validation'
$gitReady = $false
$gitDir = Join-Path $rootPath '.git'
if (Test-Path -LiteralPath $gitDir) {
    try {
        $gitItem = Get-Item -LiteralPath $gitDir -Force
        if (-not $gitItem.PSIsContainer -or ($gitItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            Report INCOMPLETE GIT_LAYOUT '.'
        } elseif (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Report INCOMPLETE GIT_UNAVAILABLE '.'
        } else {
            $gitReady = $true
            $index = Join-Path $gitDir 'index'
            if (Test-Path -LiteralPath $index) {
                $indexItem = Get-Item -LiteralPath $index -Force
                if ($indexItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    Report INCOMPLETE GIT_LAYOUT '.'; $gitReady = $false
                } elseif ($indexItem.PSIsContainer -or $indexItem.Length -gt 4194304) {
                    Report INCOMPLETE GIT_INDEX_LIMIT '.'; $gitReady = $false
                }
            }
        }
    } catch { Report INCOMPLETE GIT_LAYOUT '.' }
} else { Write-Output 'PREFLIGHT|NOT_APPLICABLE|GIT_METADATA|.' }
function Local-Git([string[]]$GitArgs) {
    # No hooks, configured MCP commands, optional index writes, or network calls.
    & git --no-optional-locks "--git-dir=$gitDir" "--work-tree=$rootPath" -c core.fsmonitor=false @GitArgs 2>$null
    $script:gitStatus = $LASTEXITCODE
}
foreach ($entry in $paths) {
    $relative, $kind = $entry -split '\|', 2
    $stream = $null
    try {
        $path = Join-Path $rootPath $relative
        $parent = Split-Path $relative -Parent
        if ($parent) {
            $parentPath = Join-Path $rootPath $parent
            if (Test-Path -LiteralPath $parentPath) {
                $parentItem = Get-Item -LiteralPath $parentPath -Force
                if ($parentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    Write-Output "PREFLIGHT|INCOMPLETE|SYMLINK|$relative"
                    $incomplete = $true
                    continue
                }
            }
        }
        if ($kind -eq 'sensitive' -and $gitReady) {
            $trackedPath = @(Local-Git @('ls-files', '--', $relative))
            if ($gitStatus -ne 0) { Report INCOMPLETE GIT_TRACKING $relative }
            elseif ($trackedPath.Count -gt 0) { Report WARNING TRACKED_SENSITIVE $relative }
            if ((Test-Path -LiteralPath $path) -or $trackedPath.Count -gt 0) {
                Local-Git @('check-ignore', '--no-index', '-q', '--', $relative) | Out-Null
                if ($gitStatus -eq 1) { Report WARNING IGNORE_GAP $relative }
                elseif ($gitStatus -ne 0) { Report INCOMPLETE GIT_IGNORE $relative }
            }
        }
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $file = Get-Item -LiteralPath $path -Force
        if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Write-Output "PREFLIGHT|INCOMPLETE|SYMLINK|$relative"
            $incomplete = $true
            continue
        }
        if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::Device)) {
            Write-Output "PREFLIGHT|INCOMPLETE|UNREADABLE_OR_SPECIAL|$relative"
            $incomplete = $true
            continue
        }
        if ($file.Length -gt 65536) {
            Write-Output "PREFLIGHT|INCOMPLETE|SIZE_LIMIT|$relative"
            $incomplete = $true
            continue
        }
        $stream = [IO.File]::OpenRead($path)
        $buffer = New-Object byte[] 65537
        $count = 0
        while ($count -lt $buffer.Length) {
            $read = $stream.Read($buffer, $count, $buffer.Length - $count)
            if ($read -eq 0) { break }
            $count += $read
        }
        if ($count -gt 65536) {
            Write-Output "PREFLIGHT|INCOMPLETE|SIZE_LIMIT|$relative"
            $incomplete = $true
            continue
        }
        if ([Array]::IndexOf($buffer, [byte]0, 0, $count) -ge 0) {
            Report INCOMPLETE UNSUPPORTED_ENCODING $relative
            continue
        }
        $content = [Text.Encoding]::UTF8.GetString($buffer, 0, $count) -replace '[\r\n\t]', ' '
        foreach ($entry in $rules) {
            $rule, $scope, $pattern = $entry -split '\|', 3
            if ($scope -ne 'all' -and $scope -ne $kind) { continue }
            if ($content -cmatch $pattern) { Report WARNING $rule $relative }
        }
    } catch {
        Write-Output "PREFLIGHT|INCOMPLETE|UNREADABLE_OR_SPECIAL|$relative"
        $incomplete = $true
    } finally {
        if ($stream) { $stream.Dispose() }
        $content = $null
    }
}
if ($incomplete) { exit 2 }
if ($findings) { exit 1 }
Write-Output 'PREFLIGHT|NO_FINDINGS|FIXED_SCOPE_ONLY'
exit 0
