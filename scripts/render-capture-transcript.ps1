<#
.SYNOPSIS
    Render a capture transcript and its write log from an Antigravity CLI (agy)
    --output-format stream-json event stream.

.DESCRIPTION
    Thin forwarder. The renderer itself lives in scripts/render-capture-transcript.mjs,
    which the Bash twin (scripts/render-capture-transcript.sh) invokes as well.
    Keeping one implementation is what makes the Linux/macOS and Windows behaviour
    identical by construction rather than by review: there is no second copy to drift.

    The transcript format, the two load-bearing properties (the two-space body indent
    that keeps ^-anchored scorer patterns anchored, and the tool-name to scorer-verb
    mapping), and the reconstructed-timeline caveat are documented in the module.

.EXAMPLE
    pwsh -NoProfile -File scripts/render-capture-transcript.ps1 session.jsonl transcript.md observed-writes.log --probe halt-callout --prompt "Run the migration." --model gemini-3.8-flash-high
#>
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Renderer = Join-Path $ScriptDir "render-capture-transcript.mjs"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine("render-capture-transcript: node is required but was not found on PATH")
    exit 2
}

if (-not (Test-Path -LiteralPath $Renderer -PathType Leaf)) {
    [Console]::Error.WriteLine("render-capture-transcript: renderer module not found: $Renderer")
    exit 2
}

& node $Renderer @args
exit $LASTEXITCODE
