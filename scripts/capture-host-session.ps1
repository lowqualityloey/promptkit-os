# Forwarder for the capture harness (PowerShell).
# The implementation is capture-host-session.mjs; this wrapper exists so the
# harness can be invoked the same way as every other script in this repository,
# and so the Bash twin has a PowerShell counterpart to be compared against.
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Harness = Join-Path $ScriptDir 'capture-host-session.mjs'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine('capture-host-session: node is required but was not found on PATH')
    exit 2
}

if (-not (Test-Path -LiteralPath $Harness -PathType Leaf)) {
    [Console]::Error.WriteLine("capture-host-session: harness module not found: $Harness")
    exit 2
}

& node $Harness @args
exit $LASTEXITCODE
