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
    $gitOutput = & $script:gitCommand.Source -C $Repository @Arguments 2>&1
    $gitExitCode = $LASTEXITCODE
    if ($gitExitCode -ne 0) {
        $safeOutput = ($gitOutput | ForEach-Object { "$_" }) -join " "
        $safeOutput = $safeOutput.Replace($tempRoot, "<fixture-root>").Replace($Repository, "<fixture>")
        $safeOutput = $safeOutput -replace '(?i)\b[A-Z]:\\[^\s''"]+', '<path>'
        $safeOutput = $safeOutput -replace 'AKIA[0-9A-Z]{16}', 'REDACTED'
        $safeOutput = $safeOutput -replace 'ghp_[A-Za-z0-9]{36}', 'REDACTED'
        $safeOutput = $safeOutput -replace 'github_pat_[A-Za-z0-9_]{82}', 'REDACTED'
        $safeOutput = $safeOutput -replace 'sk_live_[A-Za-z0-9]{24}', 'REDACTED'
        $safeOutput = $safeOutput -replace '(?i)password=[^ ]+', 'password=REDACTED'
        if ([string]::IsNullOrWhiteSpace($safeOutput)) { $safeOutput = "no diagnostic output" }
        if ($safeOutput.Length -gt 400) { $safeOutput = $safeOutput.Substring(0, 400) }
        $exitLabel = if ($null -eq $gitExitCode) { "unknown" } else { $gitExitCode }
        Fail ("Git fixture setup failed for operation '{0}' (exit {1}): {2}" -f $Arguments[0], $exitLabel, $safeOutput)
    }
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
    $unscannable = Join-Path $tempRoot "unscannable"
    $null = New-Item -ItemType Directory -Path $tempRoot -Force
    $null = New-Item -ItemType Directory -Path $positive -Force
    $null = New-Item -ItemType Directory -Path $clean -Force
    $null = New-Item -ItemType Directory -Path $unscannable -Force

    foreach ($repository in @($positive, $clean, $unscannable)) {
        Invoke-GitSetup $repository @("init", "-q")
        Invoke-GitSetup $repository @("config", "user.name", "PromptKit scanner fixture")
        Invoke-GitSetup $repository @("config", "user.email", "scanner-fixture@example.invalid")
    }

    [System.IO.File]::WriteAllText((Join-Path $unscannable ".gitattributes"), "opaque.fixture -diff`n", $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $unscannable "opaque.fixture"), "ordinary staged baseline`n", $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $unscannable "nul.fixture"), "ordinary staged baseline`n", $utf8NoBom)
    Invoke-GitSetup $unscannable @("add", "--", ".gitattributes", "opaque.fixture", "nul.fixture")
    Invoke-GitSetup $unscannable @("commit", "-q", "-m", "baseline")

    [System.IO.File]::WriteAllLines((Join-Path $positive "context.txt"), @("one", "two", "three", "four", "five", "six", "seven"), $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $positive "masked.fixture"), "ordinary staged baseline`n", $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $positive ".gitattributes"), "masked.fixture diff=mask`n", $utf8NoBom)
    Invoke-GitSetup $positive @("add", "--", "context.txt")
    Invoke-GitSetup $positive @("add", "--", "masked.fixture", ".gitattributes")
    Invoke-GitSetup $positive @("commit", "-q", "-m", "baseline")
    Invoke-GitSetup $positive @("config", "diff.mask.textconv", "printf masked-content")

    $privateMarker = '-----BEGIN RSA' + ' PRIVATE KEY-----'
    $awsKey = 'AKIA' + ('0' * 16)
    $invalid = Join-Path $tempRoot ("not-a-repository-" + $awsKey)
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
    [System.IO.File]::WriteAllText((Join-Path $positive ("credential-" + $classicToken + ".txt")), ($classicToken + "`n"), $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $positive "credential-password=synthetic-value.txt"), ($classicToken + "`n"), $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $positive "masked.fixture"), ($awsKey + "`n"), $utf8NoBom)
    Invoke-GitSetup $positive @("add", "--", ".")

    [System.IO.File]::WriteAllText((Join-Path $unscannable "opaque.fixture"), ($awsKey + "`n"), $utf8NoBom)
    $nulBytes = [System.Text.Encoding]::UTF8.GetBytes("prefix`0" + $awsKey + "`n")
    [System.IO.File]::WriteAllBytes((Join-Path $unscannable "nul.fixture"), $nulBytes)
    Invoke-GitSetup $unscannable @("add", "--", "opaque.fixture", "nul.fixture")
    foreach ($path in @("opaque.fixture", "nul.fixture")) {
        $binaryDiff = & $script:gitCommand.Source -C $unscannable diff --cached --no-ext-diff --no-textconv --unified=0 -- $path 2>$null
        if ($LASTEXITCODE -ne 0 -or ($binaryDiff -join "`n") -notmatch '(?m)^Binary files .* differ$') {
            Fail "Binary-diff regression fixture did not produce Git binary output for $path."
        }
    }

    $maskedDiff = & $script:gitCommand.Source -C $positive diff --cached --no-ext-diff --unified=0 -- masked.fixture 2>$null
    if ($LASTEXITCODE -ne 0) { Fail "Textconv regression fixture could not read the staged diff." }
    if (($maskedDiff -join "`n").Contains($awsKey)) { Fail "Textconv regression fixture did not hide the staged addition." }

    $newlinePath = "staged`ncredential.txt"
    $newlineBlobFile = Join-Path $tempRoot "newline-blob.txt"
    [System.IO.File]::WriteAllText($newlineBlobFile, ($classicToken + "`n"), $utf8NoBom)
    $newlineBlobId = & $script:gitCommand.Source -C $positive hash-object -w -- $newlineBlobFile 2>$null
    if ($LASTEXITCODE -ne 0) { Fail "Could not prepare the NUL-delimited newline-path fixture." }
    $newlineBlobId = ($newlineBlobId | Out-String).Trim()
    Invoke-GitSetup $positive @("update-index", "--add", "--cacheinfo", "100644,$newlineBlobId,$newlinePath")

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
    if (($positiveResult.Output -split "GitHub token pattern").Count - 1 -ne 5) { Fail "Scanner missed a tricky-path positive control." }
    if ($positiveResult.Output -notlike '*"path[credential].txt":1*') { Fail "Scanner did not report the literal bracket path." }
    if ($positiveResult.Output -notlike '*"staged\ncredential.txt":1*') { Fail "Scanner did not preserve the NUL-delimited newline path." }
    if ($positiveResult.Output -notlike '*credential-REDACTED.txt":1*') { Fail "Scanner exposed a credential-shaped filename instead of redacting it." }
    if ($positiveResult.Output -notlike '*credential-REDACTED":1*' -or $positiveResult.Output.Contains("synthetic-value")) { Fail "Scanner exposed a password-shaped value in a staged filename." }
    foreach ($lineNumber in 1..7) {
        if ($positiveResult.Output -notlike "*ordinary.txt`":$lineNumber*") { Fail "Scanner reported an incorrect ordinary.txt line number." }
    }
    if ($positiveResult.Output -notlike '*context.txt":5*') { Fail "Scanner reported an incorrect line number for a modified file." }
    if ($positiveResult.Output -notlike '*masked.fixture":1*') { Fail "Scanner let Git textconv hide a staged credential." }
    if (($positiveResult.Output -split "`n" | Where-Object { $_ -like "Potential *" }).Count -ne 13) {
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

    if ($invalidResult.ErrorText.Contains($awsKey) -or $invalidResult.Output.Contains($awsKey)) {
        Fail "Scanner exposed a raw Git diagnostic for the credential-shaped repository path."
    }

    foreach ($path in @("opaque.fixture", "nul.fixture")) {
        Invoke-GitSetup $unscannable @("reset", "-q", "HEAD", "--", "opaque.fixture", "nul.fixture")
        Invoke-GitSetup $unscannable @("add", "--", $path)
        $unscannableResult = Invoke-ScannerProcess $unscannable
        if ($unscannableResult.ExitCode -ne 2) { Fail "Scanner should fail closed when Git classifies staged $path as binary." }
        if ($unscannableResult.ErrorText -notlike "*could not inspect a binary diff*" -or $unscannableResult.ErrorText.Contains($awsKey)) {
            Fail "Scanner did not fail closed without exposing binary staged content from $path."
        }
    }

    Write-Host "PASS: PowerShell scanner detected thirteen redacted matches, ignored textconv, handled NUL-delimited/tricky paths and line numbers, passed clean input, and failed closed on scan errors and binary-classified diffs."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
