# PromptKit OS Tokenizer-Delta Validation Utility (PowerShell)
# Compares the gated `bytes/4` proxy against real tokenizer counts
# (tiktoken cl100k_base + o200k_base). Informational only: bytes/4 REMAINS
# the gated convention. Never fails the build — exits 0 with a clear
# SKIPPED line when python3, tiktoken, or its BPE encodings are unavailable.
#
# Run from repository root: pwsh -NoProfile -File .\scripts\measure-tokenizer-delta.ps1
# Output: machine-parseable FILE|BYTES4|CL100K|O200K|RATIO lines
# (RATIO = CL100K / BYTES4), consistent with the existing BALANCED| and BASELINE| styles.

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
    & python3 $tmp
} finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
    Remove-Item Env:\PROMPTKIT_REPO_ROOT -ErrorAction SilentlyContinue
    Remove-Item Env:\PROMPTKIT_MEASURE_FILES -ErrorAction SilentlyContinue
}
