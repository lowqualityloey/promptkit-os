$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$scanner = Join-Path $repoRoot "scripts\scan-staged-secrets.ps1"
$gitCommand = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $gitCommand) { $gitCommand = Get-Command git.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1 }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("promptkit-scan-test-" + [guid]::NewGuid().ToString("N"))
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Fail([string]$Message) {
    [Console]::Error.WriteLine("FAIL: $Message")
    exit 1
}

function Invoke-GitSetup {
    param([string]$Repository, [string[]]$Arguments)
    & $script:gitCommand.Source -C $Repository @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { Fail "Git fixture setup failed." }
}

function Invoke-ScannerProcess {
    param([string]$Root)
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $pwshCommand = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $pwshCommand) { $pwshCommand = Get-Command pwsh.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1 }
    $startInfo.FileName = $pwshCommand.Source
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @("-NoProfile", "-File", $scanner, "-Root", $Root)) {
        $null = $startInfo.ArgumentList.Add($argument)
    }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) { Fail "Could not start scanner process." }
        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output = $outputTask.GetAwaiter().GetResult()
            ErrorText = $errorTask.GetAwaiter().GetResult()
        }
    }
    finally { $process.Dispose() }
}

try {
    $positive = Join-Path $tempRoot "positive"
    $clean = Join-Path $tempRoot "clean"
    $invalid = Join-Path $tempRoot "not-a-repository"
    $null = New-Item -ItemType Directory -Path $tempRoot -Force
    $null = New-Item -ItemType Directory -Path $positive -Force
    $null = New-Item -ItemType Directory -Path $clean -Force
    $null = New-Item -ItemType Directory -Path $invalid -Force

    foreach ($repository in @($positive, $clean)) {
        Invoke-GitSetup $repository @("init", "-q")
        Invoke-GitSetup $repository @("config", "user.name", "PromptKit scanner fixture")
        Invoke-GitSetup $repository @("config", "user.email", "scanner-fixture@example.invalid")
    }

    [System.IO.File]::WriteAllLines((Join-Path $positive "context.txt"), @("one", "two", "three", "four", "five", "six", "seven"), $utf8NoBom)
    Invoke-GitSetup $positive @("add", "--", "context.txt")
    Invoke-GitSetup $positive @("commit", "-q", "-m", "baseline")

    $privateMarker = '-----BEGIN RSA' + ' PRIVATE KEY-----'
    $awsKey = 'AKIA' + ('0' * 16)
    $classicToken = 'gh' + 'p_' + ('0' * 36)
    $fineToken = 'github' + '_pat_' + ('0' * 82)
    $stripeKey = 'sk' + '_live_' + ('0' * 24)
    $jwt = 'eyJ' + 'abcdefghij.' + 'klmnopqrst.' + 'uvwxyzABCD'
    $passwordName = 'pass' + 'word'
    $passwordAssignment = $passwordName + '="synthetic-value-only"'
    $awsKeyOnLaterLine = 'AKIA' + ('1' * 16)
    [System.IO.File]::WriteAllLines((Join-Path $positive "context.txt"), @("one", "two", "three", "four", $awsKeyOnLaterLine, "six", "seven"), $utf8NoBom)
    $ordinaryLines = @($privateMarker, $awsKey, $classicToken, $fineToken, $stripeKey, $jwt, $passwordAssignment)
    [System.IO.File]::WriteAllLines((Join-Path $positive "ordinary.txt"), $ordinaryLines, $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $positive "path[credential].txt"), ($classicToken + "`n"), $utf8NoBom)
    Invoke-GitSetup $positive @("add", "--", ".")

    [System.IO.File]::WriteAllText((Join-Path $clean "README.md"), "ordinary staged content`n", $utf8NoBom)
    Invoke-GitSetup $clean @("add", "--", "README.md")

    $positiveResult = Invoke-ScannerProcess $positive
    if ($positiveResult.ExitCode -ne 1) { Fail "Scanner should return 1 when supported patterns are found." }
    foreach ($category in @(
        "private-key marker",
        "AWS access-key pattern",
        "GitHub token pattern",
        "GitHub fine-grained token pattern",
        "Stripe live-key pattern",
        "JWT-like token pattern",
        "password-assignment pattern"
    )) {
        if ($positiveResult.Output -notlike "*$category*") { Fail "Scanner missed the $category detector." }
    }
    if (($positiveResult.Output -split "GitHub token pattern").Count - 1 -ne 2) { Fail "Scanner missed the bracket-path positive control." }
    if ($positiveResult.Output -notlike '*"path[credential].txt":1*') { Fail "Scanner did not report the literal bracket path." }
    foreach ($lineNumber in 1..7) {
        if ($positiveResult.Output -notlike "*ordinary.txt`:$lineNumber*") { Fail "Scanner reported an incorrect ordinary.txt line number." }
    }
    if ($positiveResult.Output -notlike "*context.txt:5*") { Fail "Scanner reported an incorrect line number for a modified file." }
    if (($positiveResult.Output -split "`n" | Where-Object { $_ -like "Potential *" }).Count -ne 9) {
        Fail "Scanner returned an unexpected detection count."
    }
    $secretValues = @($ordinaryLines) + @($awsKeyOnLaterLine)
    foreach ($secretValue in $secretValues) {
        if ($positiveResult.Output.Contains($secretValue)) { Fail "Scanner leaked a matching value." }
    }

    $cleanResult = Invoke-ScannerProcess $clean
    if ($cleanResult.ExitCode -ne 0 -or $cleanResult.Output.Length -ne 0) { Fail "Clean staged content should pass without output." }

    $invalidResult = Invoke-ScannerProcess $invalid
    if ($invalidResult.ExitCode -ne 2) { Fail "Scanner should fail closed when the repository cannot be scanned." }
    if ($invalidResult.ErrorText -notlike "*stop before committing*") { Fail "Scanner did not explain that incomplete scans must stop." }

    Write-Host "PASS: PowerShell scanner detected nine redacted matches, handled Git pathspecs and modified-file line numbers, passed clean input, and failed closed on scan errors."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
