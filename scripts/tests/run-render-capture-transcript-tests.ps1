# Regression harness for the capture-transcript renderer (PowerShell).
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-render-capture-transcript-tests.ps1
#
# The renderer is the only mechanical path from a raw agy stream-json event
# stream to the transcript format the behavioral scorer reads. Two properties
# matter and both are asserted here against the six committed Antigravity
# bundles rather than against synthetic input:
#
#   1. Round-trip fidelity. Re-rendering a bundle's own session.jsonl reproduces
#      that bundle's committed transcript and observed-writes.log. The timestamp
#      column is excluded from the comparison on purpose: agy reports no
#      per-event clock, so the renderer reconstructs the timeline from the stream
#      file's mtime and the cumulative step durations, and float accumulation can
#      move a reconstructed millisecond. Everything the scorer grades - assistant
#      text, tool verbs, targets, statuses, and the write log - must match
#      byte-for-byte.
#   2. Twin parity. The Bash and PowerShell forwarders invoke the same module, so
#      their output must be identical. This is asserted directly rather than
#      assumed from the shared implementation.
#
# A third case re-scores a re-rendered bundle and requires the same verdict line
# as the committed scorer.txt, which is what makes the round-trip meaningful:
# identical bytes that score differently would not be a pass.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd('\', '/')
$rendererSh = Join-Path $repoRoot 'scripts/render-capture-transcript.sh'
$rendererPs1 = Join-Path $repoRoot 'scripts/render-capture-transcript.ps1'
$module = Join-Path $repoRoot 'scripts/render-capture-transcript.mjs'
$scorer = Join-Path $repoRoot 'scripts/run-behavioral-eval.sh'
$bundles = Join-Path $repoRoot 'docs/internal/host-conformance/antigravity'
$probes = @('breaker-exhaustion', 'card-provenance', 'greenfield-saas-intake', 'halt-callout', 'milestone-halt', 'milestone-halt-resume')

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('pk-render-capture-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$script:PASS = 0
$script:FAIL = 0
$script:SCENARIO_OK = $true

function Write-Pass { param([string]$Label) Write-Output "PASS: $Label"; $script:PASS++ }
function Write-Fail { param([string]$Label) Write-Output "FAIL: $Label"; $script:FAIL++ }
function Begin-Scenario { $script:SCENARIO_OK = $true }
function Report-Scenario { param([string]$Label) if ($script:SCENARIO_OK) { Write-Pass $Label } else { Write-Fail $Label } }
function Assert-Scenario {
    param([bool]$Condition, [string]$Description)
    if (-not $Condition) { Write-Output "  - $Description"; $script:SCENARIO_OK = $false }
}
function Assert-Status { param([int]$Actual, [int]$Expected) Assert-Scenario ($Actual -eq $Expected) "expected exit $Expected, got $Actual" }

# The timestamp column is the only part of the transcript the renderer
# reconstructs rather than copies, so it is the only part excluded here.
function Get-StrippedContent {
    param([string]$Path)
    $lines = [IO.File]::ReadAllLines($Path)
    $out = foreach ($line in $lines) {
        if ($line -match '^- .[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+[+-][0-9]{2}:[0-9]{2}. ') {
            '- ' + $line.Substring($Matches[0].Length)
        } else {
            $line
        }
    }
    return ($out -join "`n")
}

# Read a preamble field back out of a committed transcript so a re-render is
# invoked with exactly the arguments the original capture used.
function Get-Field {
    param([string]$Path, [string]$Label)
    $prefix = '- ' + $Label + ': ' + [char]0x60
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line.StartsWith($prefix)) {
            $rest = $line.Substring($prefix.Length)
            $end = $rest.IndexOf([char]0x60)
            if ($end -ge 0) { return $rest.Substring(0, $end) }
        }
    }
    return ''
}

function Get-InvocationField {
    param([string]$Path)
    $tick = [char]0x60
    $prefix = '- Model: ' + $tick
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line.StartsWith($prefix)) {
            $rest = $line.Substring($prefix.Length)
            $first = $rest.IndexOf($tick)
            if ($first -lt 0) { continue }
            $rest = $rest.Substring($first + 1)
            $second = $rest.IndexOf($tick)
            if ($second -lt 0) { continue }
            $rest = $rest.Substring($second + 1)
            $third = $rest.IndexOf($tick)
            if ($third -lt 0) { continue }
            return $rest.Substring(0, $third)
        }
    }
    return ''
}

function Invoke-Render {
    param([string]$Probe, [string]$Out, [string]$Log, [string]$Renderer)
    $bundle = Join-Path $bundles $Probe
    $transcript = Join-Path $bundle 'transcript.md'
    $arguments = @(
        (Join-Path $bundle 'session.jsonl'), $Out, $Log,
        '--probe', $Probe,
        '--prompt', (Get-Field $transcript 'Prompt submitted'),
        '--model', (Get-Field $transcript 'Model'),
        '--invocation', (Get-InvocationField $transcript)
    )
    if ($Renderer -eq 'ps1') {
        & pwsh -NoProfile -File $rendererPs1 @arguments 2>&1 | Out-Null
    } else {
        & bash $rendererSh @arguments 2>&1 | Out-Null
    }
    return $LASTEXITCODE
}

Write-Output '== Renderer module and forwarders =='
Begin-Scenario
Assert-Scenario (Test-Path -LiteralPath $module -PathType Leaf) 'missing module: scripts/render-capture-transcript.mjs'
Assert-Scenario (Test-Path -LiteralPath $rendererSh -PathType Leaf) 'missing forwarder: scripts/render-capture-transcript.sh'
Assert-Scenario (Test-Path -LiteralPath $rendererPs1 -PathType Leaf) 'missing forwarder: scripts/render-capture-transcript.ps1'
Report-Scenario 'renderer module and both forwarders exist'

Write-Output '== Argument validation =='
Begin-Scenario
& bash $rendererSh 2>&1 | Out-Null
Assert-Status $LASTEXITCODE 2
& bash $rendererSh (Join-Path $tmp 'nonexistent.jsonl') (Join-Path $tmp 't.md') (Join-Path $tmp 'w.log') --probe p --prompt x --model m 2>&1 | Out-Null
Assert-Status $LASTEXITCODE 2
& bash $rendererSh (Join-Path $bundles 'halt-callout/session.jsonl') (Join-Path $tmp 't.md') (Join-Path $tmp 'w.log') --probe p --prompt x --model m --bogus y 2>&1 | Out-Null
Assert-Status $LASTEXITCODE 2
Report-Scenario 'argument validation rejects bad invocations with exit 2'

Write-Output '== Round-trip against the committed bundles =='
foreach ($probe in $probes) {
    $bundle = Join-Path $bundles $probe
    Begin-Scenario
    $session = Join-Path $bundle 'session.jsonl'
    $transcript = Join-Path $bundle 'transcript.md'
    if (-not (Test-Path -LiteralPath $session) -or -not (Test-Path -LiteralPath $transcript)) {
        Assert-Scenario $false "bundle is missing session.jsonl or transcript.md: $probe"
        Report-Scenario "round-trip $probe"
        continue
    }

    $out = Join-Path $tmp "$probe.md"
    $log = Join-Path $tmp "$probe.log"
    Assert-Status (Invoke-Render $probe $out $log 'sh') 0

    $rendered = Get-StrippedContent $out
    $committed = Get-StrippedContent $transcript
    Assert-Scenario ($rendered -eq $committed) "transcript content differs from the committed transcript for $probe"

    $renderedLog = ([IO.File]::ReadAllText($log)).Replace("`r", '')
    $committedLog = ([IO.File]::ReadAllText((Join-Path $bundle 'observed-writes.log'))).Replace("`r", '')
    Assert-Scenario ($renderedLog -eq $committedLog) "observed-writes.log differs from the committed log for $probe"

    Report-Scenario "round-trip $probe"
}

Write-Output '== Twin parity =='
Begin-Scenario
$bundle = Join-Path $bundles 'halt-callout'
$transcript = Join-Path $bundle 'transcript.md'
$session = Join-Path $bundle 'session.jsonl'
$prompt = Get-Field $transcript 'Prompt submitted'
$model = Get-Field $transcript 'Model'
$invocation = Get-InvocationField $transcript
$shOut = Join-Path $tmp 'twin-sh.md'
$shLog = Join-Path $tmp 'twin-sh.log'
$psOut = Join-Path $tmp 'twin-ps.md'
$psLog = Join-Path $tmp 'twin-ps.log'
& bash $rendererSh $session $shOut $shLog --probe halt-callout --prompt $prompt --model $model --invocation $invocation 2>&1 | Out-Null
Assert-Status $LASTEXITCODE 0
& pwsh -NoProfile -File $rendererPs1 $session $psOut $psLog --probe halt-callout --prompt $prompt --model $model --invocation $invocation 2>&1 | Out-Null
Assert-Status $LASTEXITCODE 0
Assert-Scenario (([IO.File]::ReadAllText($shOut)) -eq ([IO.File]::ReadAllText($psOut))) 'Bash and PowerShell transcripts differ'
Assert-Scenario (([IO.File]::ReadAllText($shLog)) -eq ([IO.File]::ReadAllText($psLog))) 'Bash and PowerShell write logs differ'
Report-Scenario 'Bash and PowerShell forwarders produce identical output'

Write-Output '== Re-rendered bundle still scores the same =='
Begin-Scenario
$scorerTxt = Join-Path $bundle 'scorer.txt'
if ((Test-Path -LiteralPath $scorerTxt) -and (Test-Path -LiteralPath $scorer)) {
    $work = Join-Path $tmp 'score'
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $provenance = Join-Path $bundle 'provenance.json'
    if (Test-Path -LiteralPath $provenance) { Copy-Item -LiteralPath $provenance -Destination $work -Force }
    Assert-Status (Invoke-Render 'halt-callout' (Join-Path $work 'transcript.md') (Join-Path $work 'observed-writes.log') 'sh') 0
    $renderedVerdict = @(& bash $scorer --score halt-callout (Join-Path $work 'transcript.md') 2>&1 | Where-Object { $_ -match '^halt-callout\|' })[0]
    $committedVerdict = @([IO.File]::ReadAllLines($scorerTxt) | Where-Object { $_ -match '^halt-callout\|' })[0]
    Assert-Scenario ($null -ne $renderedVerdict) 'scorer produced no verdict line for the re-rendered bundle'
    Assert-Scenario ($renderedVerdict -eq $committedVerdict) "verdict differs: rendered '$renderedVerdict' vs committed '$committedVerdict'"
} else {
    Assert-Scenario $false 'missing scorer.txt or scripts/run-behavioral-eval.sh'
}
Report-Scenario 're-rendered halt-callout bundle scores the committed verdict'

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Output ''
if ($script:FAIL -eq 0) {
    Write-Output "RENDER_CAPTURE_TRANSCRIPT_TESTS|PASS|$($script:PASS) passed"
    exit 0
}
Write-Output "RENDER_CAPTURE_TRANSCRIPT_TESTS|FAIL|$($script:PASS) passed, $($script:FAIL) failed"
exit 1
