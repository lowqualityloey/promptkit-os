# Scan staged additions for common credential patterns without printing matched content.
param(
    [string]$Root = "."
)

$ErrorActionPreference = "Stop"

function Invoke-GitCapture {
    param([string[]]$GitArguments)

    $gitCommand = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $gitCommand) {
        $gitCommand = Get-Command git.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1
    }
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $gitCommand.Source
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $GitArguments) {
        $null = $startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $memory = [System.IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) { throw "Could not start Git." }
        $copyTask = $process.StandardOutput.BaseStream.CopyToAsync($memory)
        $errorTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $copyTask.GetAwaiter().GetResult()
        $stderr = $errorTask.GetAwaiter().GetResult()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Bytes = $memory.ToArray()
            ErrorText = $stderr
        }
    }
    finally {
        $memory.Dispose()
        $process.Dispose()
    }
}

function Stop-Scan {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
    exit 2
}

try {
    # ProviderPath (not .Path): .Path can carry the provider qualifier prefix
    # (e.g. Microsoft.PowerShell.Core\FileSystem::\\wsl.localhost\...), which
    # git cannot resolve - every scan would fail closed with no diagnostics.
    $resolvedRoot = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).ProviderPath
    $pathResult = Invoke-GitCapture @("--literal-pathspecs", "-C", $resolvedRoot, "diff", "--cached", "--name-only", "--diff-filter=ACMRT", "-z")
    if ($pathResult.ExitCode -ne 0) {
        Stop-Scan "Staged secret scan could not enumerate staged paths; stop before committing."
    }
    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    $pathText = $utf8.GetString($pathResult.Bytes)
    $stagedPaths = @($pathText.Split([char]0, [System.StringSplitOptions]::RemoveEmptyEntries))
}
catch {
    Stop-Scan "Staged secret scan could not enumerate staged paths; stop before committing."
}

# Narrative-surface detectors and their allowlist are externalized data files
# modeled on scripts/harness-security-*.txt. A missing or unreadable file fails
# the scan closed (exit 2), mirroring the Bash twin and check-harness-security.ps1.
$narrativeRulesPath = Join-Path $PSScriptRoot 'narrative-surface-rules.txt'
$narrativePathsPath = Join-Path $PSScriptRoot 'narrative-surface-paths.txt'
$narrativeRulesExtra = $env:PROMPTKIT_NARRATIVE_RULES_EXTRA
$narrativePathsExtra = $env:PROMPTKIT_NARRATIVE_PATHS_EXTRA
if (-not (Test-Path -LiteralPath $narrativeRulesPath -PathType Leaf) -or -not (Test-Path -LiteralPath $narrativePathsPath -PathType Leaf)) {
    Stop-Scan "Staged secret scan could not read its narrative-surface rules; stop before committing."
}
if ($narrativeRulesExtra -and -not (Test-Path -LiteralPath $narrativeRulesExtra -PathType Leaf)) {
    Stop-Scan "Staged secret scan could not read its narrative-surface rules extension; stop before committing."
}
if ($narrativePathsExtra -and -not (Test-Path -LiteralPath $narrativePathsExtra -PathType Leaf)) {
    Stop-Scan "Staged secret scan could not read its narrative-surface allowlist extension; stop before committing."
}

$narrativeRules = @()
foreach ($rulesFile in @($narrativeRulesPath, $narrativeRulesExtra)) {
    if (-not $rulesFile) { continue }
    foreach ($line in (Get-Content -LiteralPath $rulesFile)) {
        $line = $line.TrimEnd([char]13)
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
        $fields = $line -split '\|'
        if ($fields.Count -ne 3 -or [string]::IsNullOrWhiteSpace($fields[0]) -or [string]::IsNullOrWhiteSpace($fields[1]) -or [string]::IsNullOrWhiteSpace($fields[2])) {
            Stop-Scan "Staged secret scan found a malformed narrative-surface rules row; stop before committing."
        }
        $narrativeRules += [pscustomobject]@{ Rule = $fields[0]; Regex = $fields[1]; Severity = $fields[2] }
    }
}

$narrativeAllow = @()
foreach ($pathsFile in @($narrativePathsPath, $narrativePathsExtra)) {
    if (-not $pathsFile) { continue }
    foreach ($line in (Get-Content -LiteralPath $pathsFile)) {
        $line = $line.TrimEnd([char]13)
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
        $fields = $line -split '\|'
        if ($fields.Count -ne 2 -or [string]::IsNullOrWhiteSpace($fields[0]) -or $fields[1] -ne 'allow') {
            Stop-Scan "Staged secret scan found a malformed narrative-surface allowlist row; stop before committing."
        }
        $narrativeAllow += $fields[0]
    }
}

$detectors = @(
    [pscustomobject]@{ Pattern = 'BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY'; Category = 'private-key marker' },
    [pscustomobject]@{ Pattern = 'AKIA[0-9A-Z]+'; Category = 'AWS access-key pattern' },
    [pscustomobject]@{ Pattern = 'ghp_[A-Za-z0-9]+'; Category = 'GitHub token pattern' },
    [pscustomobject]@{ Pattern = 'github_pat_[A-Za-z0-9_]+'; Category = 'GitHub fine-grained token pattern' },
    [pscustomobject]@{ Pattern = 'sk_live_[0-9a-zA-Z]+'; Category = 'Stripe live-key pattern' },
    [pscustomobject]@{ Pattern = 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'; Category = 'JWT-like token pattern' },
    [pscustomobject]@{ Pattern = 'gho_[A-Za-z0-9]+'; Category = 'GitHub OAuth token pattern' },
    [pscustomobject]@{ Pattern = 'ghu_[A-Za-z0-9]+'; Category = 'GitHub user token pattern' },
    [pscustomobject]@{ Pattern = 'ghs_[A-Za-z0-9]+'; Category = 'GitHub server token pattern' },
    [pscustomobject]@{ Pattern = 'ghr_[A-Za-z0-9]+'; Category = 'GitHub refresh token pattern' },
    [pscustomobject]@{ Pattern = 'xox[baprs]-[A-Za-z0-9-]+'; Category = 'Slack token pattern' },
    [pscustomobject]@{ Pattern = 'AIza[0-9A-Za-z_-]+'; Category = 'Google API key pattern' },
    [pscustomobject]@{ Pattern = 'password\s*[:=]\s*["''][^"'']+["'']'; Category = 'password-assignment pattern' }
)

$scanFound = $false
$narrativeFound = $false
foreach ($path in $stagedPaths) {
    $narrativeAllowed = $false
    foreach ($glob in $narrativeAllow) {
        if ($path -like $glob) { $narrativeAllowed = $true; break }
    }
    $redactedPath = $path
    $pathPatterns = @($detectors.Pattern) + 'password\s*[:=]\s*[^\s/\\]+'
    foreach ($pattern in $pathPatterns) {
        $redactedPath = [System.Text.RegularExpressions.Regex]::Replace($redactedPath, $pattern, "REDACTED")
    }
    $escapedPath = ConvertTo-Json -Compress -InputObject $redactedPath

    try {
        $diffResult = Invoke-GitCapture @("--literal-pathspecs", "-C", $resolvedRoot, "diff", "--cached", "--no-ext-diff", "--no-textconv", "--unified=0", "--", $path)
        if ($diffResult.ExitCode -ne 0) {
            Stop-Scan "Staged secret scan could not read a staged diff; stop before committing."
        }
        $diffText = [System.Text.Encoding]::UTF8.GetString($diffResult.Bytes)
    }
    catch {
        Stop-Scan "Staged secret scan could not read a staged diff; stop before committing."
    }

    if ($diffText -match '(?m)^(?:Binary files .* differ|GIT binary patch)\r?$') {
        Stop-Scan "Staged secret scan could not inspect a binary diff; stop before committing."
    }

    $inHunk = $false
    $lineNumber = 0
    foreach ($diffLine in ($diffText -split "`n")) {
        if ($diffLine.StartsWith("@@ ")) {
            if ($diffLine -notmatch '^@@ .*\+([0-9]+)(?:,[0-9]+)? @@') {
                Stop-Scan "Staged secret scan failed while parsing a staged diff; stop before committing."
            }
            $lineNumber = [int]$Matches[1]
            $inHunk = $true
            continue
        }
        if (-not $inHunk -or -not $diffLine.StartsWith("+")) {
            continue
        }

        $content = $diffLine.Substring(1)
        $passwordHit = $false
        foreach ($detector in $detectors) {
            if ($content -cmatch $detector.Pattern) {
                $scanFound = $true
                if ($detector.Category -eq 'password-assignment pattern') { $passwordHit = $true }
                [Console]::Out.WriteLine(('Potential {0} in staged additions: {1}:{2} (matching content suppressed).' -f $detector.Category, $escapedPath, $lineNumber))
            }
        }
        # Bare assignments with no quotes are just as exfiltrating; bracketed
        # placeholders (e.g. <change-me>) stay silent.
        if ($content -cmatch 'password\s*[:=]\s*([^\s''""/\\]+)') {
            if ($Matches[1] -notmatch '^[<\[]') {
                $scanFound = $true
                $passwordHit = $true
                [Console]::Out.WriteLine(('Potential {0} in staged additions: {1}:{2} (matching content suppressed).' -f 'password-assignment pattern', $escapedPath, $lineNumber))
            }
        }
        # A line already reported as a password assignment is not also
        # reported as entropy — one leak, one diagnostic.
        if (-not $passwordHit -and $content -cmatch '(api[_-]?key|secret|token|password)\s*[:=]\s*["'']?([A-Za-z0-9_/+=\.-]+)') {
            $entropyVal = $Matches[2]
            if ($entropyVal.Length -ge 20 -and $entropyVal -notmatch '^[<\[]') {
                $scanFound = $true
                [Console]::Out.WriteLine(('Potential {0} in staged additions: {1}:{2} (matching content suppressed).' -f 'high-entropy secret-assignment pattern', $escapedPath, $lineNumber))
            }
        }
        if (-not $narrativeAllowed) {
            foreach ($rule in $narrativeRules) {
                if ($content -cmatch $rule.Regex) {
                    $narrativeFound = $true
                    [Console]::Out.WriteLine(('Narrative surface {0} ({1}) in staged additions: {2}:{3} (relativize the path to a $HOME-relative form, or untrack the file).' -f $rule.Rule, $rule.Severity, $escapedPath, $lineNumber))
                }
            }
        }
        $lineNumber++
    }
}

if ($scanFound) { exit 1 }
if ($narrativeFound) { exit 3 }
