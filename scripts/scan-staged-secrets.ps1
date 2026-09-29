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
    $resolvedRoot = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path
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

$detectors = @(
    [pscustomobject]@{ Pattern = 'BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY'; Category = 'private-key marker' },
    [pscustomobject]@{ Pattern = 'AKIA[0-9A-Z]+'; Category = 'AWS access-key pattern' },
    [pscustomobject]@{ Pattern = 'ghp_[A-Za-z0-9]+'; Category = 'GitHub token pattern' },
    [pscustomobject]@{ Pattern = 'github_pat_[A-Za-z0-9_]+'; Category = 'GitHub fine-grained token pattern' },
    [pscustomobject]@{ Pattern = 'sk_live_[0-9a-zA-Z]+'; Category = 'Stripe live-key pattern' },
    [pscustomobject]@{ Pattern = 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'; Category = 'JWT-like token pattern' },
    [pscustomobject]@{ Pattern = 'password\s*[:=]\s*["''][^"'']+["'']'; Category = 'password-assignment pattern' }
)

$scanFound = $false
foreach ($path in $stagedPaths) {
    try {
        $diffResult = Invoke-GitCapture @("--literal-pathspecs", "-C", $resolvedRoot, "diff", "--cached", "--no-ext-diff", "--unified=0", "--", $path)
        if ($diffResult.ExitCode -ne 0) {
            Stop-Scan "Staged secret scan could not read a staged diff; stop before committing."
        }
        $diffText = [System.Text.Encoding]::UTF8.GetString($diffResult.Bytes)
    }
    catch {
        Stop-Scan "Staged secret scan could not read a staged diff; stop before committing."
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
        foreach ($detector in $detectors) {
            if ($content -cmatch $detector.Pattern) {
                $scanFound = $true
                $escapedPath = ConvertTo-Json -Compress -InputObject $path
                [Console]::Out.WriteLine(('Potential {0} in staged additions: {1}:{2} (matching content suppressed).' -f $detector.Category, $escapedPath, $lineNumber))
            }
        }
        $lineNumber++
    }
}

if ($scanFound) { exit 1 }
