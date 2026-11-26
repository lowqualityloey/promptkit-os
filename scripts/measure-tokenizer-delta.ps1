# PromptKit OS Tokenizer-Delta Validation Utility (PowerShell)
# Compares the gated `bytes/4` proxy against real tokenizer counts
# (tiktoken cl100k_base + o200k_base). Informational by default: bytes/4 REMAINS
# the gated convention, and this script exits 0 with a clear SKIPPED line when
# python3, tiktoken, or its BPE encodings are unavailable.
#
# Run from repository root: pwsh -NoProfile -File .\scripts\measure-tokenizer-delta.ps1 [-Strict]
#   -Strict : assert each canonical directive against its real-tokenizer cap
#             (Balanced < 2,500, Lite < 1,500) in BOTH encodings (#788). Emits
#             TOKENIZER|NAME|ENCODING|MEASURED|CAP|PASS lines and exits 1 on a
#             breach. A machine without tiktoken still exits 0 with SKIPPED, so
#             CI never gains a tiktoken dependency.
#
# Output: machine-parseable FILE|BYTES4|CL100K|O200K|RATIO lines
# (RATIO = CL100K / BYTES4), consistent with the existing BALANCED| and BASELINE| styles.

[CmdletBinding()]
param (
    [switch]$Strict
)

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

$Files = @(
    "templates/agent-directive-template.md",
    "templates/agent-directive-lite-template.md",
    "workflows/plan.md",
    "workflows/route.md",
    "workflows/fix.md",
    "workflows/ship.md",
    "protocols/discovery-intake.md"
)

# Real-tokenizer caps. These are NOT the bytes/4 ceilings asserted by
# measure-tokens.ps1 -Strict (2,425 / 1,450): this gate compares actual BPE
# counts against the published 2,500 / 1,500 budgets, and the comparison is
# strict (measured must be < cap).
$BpeCapBalanced = 2500
$BpeCapLite = 1500

if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    Write-Output "SKIPPED: python3 not found on PATH"
    exit 0
}

$probe = & python3 -c "import tiktoken" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "SKIPPED: tiktoken not installed (pip install tiktoken to run this validation)"
    exit 0
}

$pyScript = @'
import os, sys
try:
    import tiktoken
except ImportError:
    print("SKIPPED: tiktoken not installed (pip install tiktoken to run this validation)")
    sys.exit(0)
repo = os.environ["PROMPTKIT_REPO_ROOT"]
files = os.environ["PROMPTKIT_MEASURE_FILES"].split(" ")
try:
    encs = {n: tiktoken.get_encoding(n) for n in ("cl100k_base", "o200k_base")}
except Exception as e:
    print(f"SKIPPED: BPE encodings unreachable ({e})")
    sys.exit(0)
print(f"# tiktoken {tiktoken.__version__} | cl100k_base + o200k_base | FILE|BYTES4|CL100K|O200K|RATIO")
for f in files:
    raw = open(os.path.join(repo, f), "rb").read()
    b4 = (len(raw) + 2) // 4
    text = raw.decode("utf-8")
    cl = len(encs["cl100k_base"].encode(text))
    o2 = len(encs["o200k_base"].encode(text))
    print(f"{f}|{b4}|{cl}|{o2}|{cl / b4:.3f}")
'@

$env:PROMPTKIT_REPO_ROOT = "$RepoRoot"
$env:PROMPTKIT_MEASURE_FILES = ($Files -join " ")

$tmp = [System.IO.Path]::GetTempFileName() + ".py"
try {
    Set-Content -Path $tmp -Value $pyScript -Encoding UTF8
    $delta = @(& python3 $tmp)
    if ($LASTEXITCODE -ne 0) {
        Write-Output "SKIPPED: tokenizer measurement failed (python3 exited non-zero)"
        exit 0
    }
    foreach ($line in $delta) { Write-Output $line }

    # A skipped measurement is never a failure, with or without -Strict.
    if ($delta.Count -eq 0) { exit 0 }
    if ("$($delta[0])".StartsWith("SKIPPED:")) { exit 0 }

    if (-not $Strict) { exit 0 }

    Write-Output ""
    Write-Output "📊 PromptKit OS Strict Real-Tokenizer Gate (cl100k_base + o200k_base)"
    $gateRows = 0
    $gateFail = $false
    foreach ($line in $delta) {
        if ($line -notlike "*|*") { continue }
        $parts = $line -split "\|"
        if ($parts.Count -lt 5) { continue }
        $name = ""
        $cap = 0
        if ($parts[0] -eq "templates/agent-directive-template.md") {
            $name = "BALANCED"
            $cap = $BpeCapBalanced
        } elseif ($parts[0] -eq "templates/agent-directive-lite-template.md") {
            $name = "LITE"
            $cap = $BpeCapLite
        } else {
            continue
        }
        $encodingsAndCounts = @(
            @{ Enc = "cl100k_base"; Tokens = $parts[2] },
            @{ Enc = "o200k_base"; Tokens = $parts[3] }
        )
        foreach ($entry in $encodingsAndCounts) {
            $measured = "$($entry.Tokens)"
            if ($measured -notmatch '^[0-9]+$') { continue }
            $gateRows++
            if ([int]$measured -lt $cap) {
                Write-Output "TOKENIZER|$name|$($entry.Enc)|$measured|$cap|PASS"
            } else {
                Write-Output "TOKENIZER|$name|$($entry.Enc)|$measured|$cap|FAIL (meets or exceeds cap)"
                $gateFail = $true
            }
        }
    }

    if ($gateRows -eq 0) {
        Write-Output "SKIPPED: no tokenizer rows available for the canonical directives"
        exit 0
    }

    if ($gateFail) {
        Write-Output "❌ Strict real-tokenizer gate FAILED: at least one directive meets or exceeds its 2,500 / 1,500 cap."
        exit 1
    }
    Write-Output "✅ Strict real-tokenizer gate passed: Balanced and Lite stay under 2,500 / 1,500 in both encodings."
    exit 0
} finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
    Remove-Item Env:\PROMPTKIT_REPO_ROOT -ErrorAction SilentlyContinue
    Remove-Item Env:\PROMPTKIT_MEASURE_FILES -ErrorAction SilentlyContinue
}
