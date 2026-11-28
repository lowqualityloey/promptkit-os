# Regression harness for the capture-transcript renderer (PowerShell).
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-render-capture-transcript-tests.ps1
#
# The renderer is the only mechanical path from a raw agy stream-json event
# stream to the transcript format the behavioral scorer reads. Two properties
# matter and both are asserted here against the six committed Antigravity
# bundles rather than against synthetic input:
#
#   1. Round-trip fidelity. Re-rendering a bundle's own session.jsonl reproduces
#      that bundle's committed transcript. The timestamp column is excluded from
#      the comparison on purpose: agy reports no per-event clock, so the renderer
#      reconstructs the timeline from a recorded anchor plus the cumulative step
#      durations, and float accumulation can move a reconstructed millisecond.
#      Everything the scorer grades - assistant text, tool verbs, targets and
#      statuses - must match byte-for-byte.
#
#      A separate case re-renders every bundle with the timelineStart recorded in
#      its own provenance.json and requires the timestamps to match exactly, with
#      no stripping. That is the regression the old mtime anchor could not have:
#      git does not preserve mtime, so a committed bundle re-rendered on another
#      machine shifted every timestamp while the stripped comparison still passed.
#
#      The write log is checked structurally rather than against a committed copy:
#      observed-writes.log is gitignored (*.log), so it exists only on the machine
#      that ran the capture. The harness therefore requires one log line per tool
#      entry in the transcript, and compares byte-for-byte only when the capture's
#      own log happens to be present.
#   2. Twin parity. The Bash and PowerShell forwarders invoke the same module, so
#      their output must be identical. This is asserted directly rather than
#      assumed from the shared implementation.
#
# A third case re-scores a re-rendered bundle and compares the verdict with the
# committed transcript scored under the current scenario. The reference is the
# committed transcript, not the bundle's scorer.txt: that line records the kit
# version named in provenance.json, and a deliberate scenario revision (the
# v2.7.0 callout contract) must not read as renderer drift. Identical bytes must
# still score identically under one rubric.

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
# Bundles captured with a recorded timeline anchor. Their provenance.json carries
# timelineStart, so a re-render must reproduce the committed timestamps exactly -
# no timestamp stripping.
$anchoredProbes = $probes + @('ce-sufficiency-balanced', 'ce-sufficiency-lite', 'ce-escalation-balanced', 'ce-escalation-lite', 'ce-antistarvation-balanced', 'ce-antistarvation-lite')

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

# Read the recorded timeline anchor back out of a bundle's provenance.json. The
# assertion is that the bundle is self-describing: a reader holding only the
# committed files can reproduce the transcript byte for byte.
function Get-TimelineAnchor {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    $text = [IO.File]::ReadAllText($Path)
    $match = [regex]::Match($text, '"timelineStart"\s*:\s*"([^"]+)"')
    if ($match.Success) { return $match.Groups[1].Value }
    return ''
}

# The UTC offset the transcript's timestamp column is rendered in. It is a
# property of the bundle, not of the machine doing the rendering: a renderer that
# reads the host zone produces '+13:00' on the capture host and '+00:00' on a UTC
# CI runner, so the committed transcript can never be reproduced off the machine
# that wrote it.
function Get-TimelineOffset {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    $text = [IO.File]::ReadAllText($Path)
    $match = [regex]::Match($text, '"timelineOffset"\s*:\s*"([^"]+)"')
    if ($match.Success) { return $match.Groups[1].Value }
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

    # The write log is derived from the transcript, so it must agree with it: one
    # 'tool <verb> <target> (<status>)' line per tool entry. This is asserted
    # unconditionally because observed-writes.log is gitignored (*.log) and so
    # never exists in a CI checkout.
    $toolEntries = @(Select-String -LiteralPath $transcript -Pattern '^- .*\*\*tool\*\*$' -AllMatches).Count
    $logLines = @(Select-String -LiteralPath $log -Pattern '^tool ' -AllMatches).Count
    Assert-Scenario ($toolEntries -eq $logLines) "write log has $logLines lines but the transcript has $toolEntries tool entries"

    # Where the capture's own log is present (a developer machine, not CI), the
    # rendered log must reproduce it byte-for-byte.
    $recordedLog = Join-Path $bundle 'observed-writes.log'
    if (Test-Path -LiteralPath $recordedLog -PathType Leaf) {
        $renderedLog = ([IO.File]::ReadAllText($log)).Replace("`r", '')
        $committedLog = ([IO.File]::ReadAllText($recordedLog)).Replace("`r", '')
        Assert-Scenario ($renderedLog -eq $committedLog) "observed-writes.log differs from the recorded log for $probe"
    }

    Report-Scenario "round-trip $probe"
}


Write-Output '== Newer stream formats =='
# The renderer understands three host event shapes. agy is covered by the round-trip
# cases above; the other two are pinned against committed golden transcripts rendered
# from a real, sanitized stream.
$fx = Join-Path $repoRoot 'scripts/tests/fixtures/render-capture-transcript'
$fxPrompt = 'Read a.txt, then create c.txt containing the word gamma, then run the shell command ls -1, then say DONE.'

# Compare content, not bytes. The renderer always writes LF, while a Windows
# checkout materialises the committed golden as CRLF, so a raw byte comparison
# passes on the machine that captured it and fails on every Windows runner - the
# same defect class the renderer's own canonical hashing was fixed for. Line
# endings are normalised before comparing; everything else must match exactly.
function Test-FileEquals {
    param([string]$Left, [string]$Right)
    if (-not (Test-Path -LiteralPath $Left -PathType Leaf)) { return $false }
    if (-not (Test-Path -LiteralPath $Right -PathType Leaf)) { return $false }
    $a = [IO.File]::ReadAllText($Left) -replace "`r`n", "`n"
    $b = [IO.File]::ReadAllText($Right) -replace "`r`n", "`n"
    return ($a -ceq $b)
}

# opencode carries a per-event clock, so its golden is compared with no timestamp
# stripping: the times are observed in the stream, not derived from an anchor.
Begin-Scenario
$ocFixture = Join-Path $fx 'opencode/session.jsonl'
$ocGolden = Join-Path $fx 'opencode/transcript.md'
$ocGoldenLog = Join-Path $fx 'opencode/expected-writes.txt'
$ocMd = Join-Path $tmp 'oc.md'
$ocLog = Join-Path $tmp 'oc.log'
Assert-Scenario (Test-Path -LiteralPath $ocFixture -PathType Leaf) 'missing fixture: scripts/tests/fixtures/render-capture-transcript/opencode/session.jsonl'
& bash $rendererSh $ocFixture $ocMd $ocLog --probe halt-callout --prompt $fxPrompt --model 'opencode/deepseek-v4.1-flash-free' --host 'OpenCode' --stream-format opencode --start '2026-11-25T00:00:00+09:00' --offset '+09:00' 2>&1 | Out-Null
Assert-Status $LASTEXITCODE 0
Assert-Scenario (Test-FileEquals $ocMd $ocGolden) 'opencode transcript differs from its golden'
Assert-Scenario (Test-FileEquals $ocLog $ocGoldenLog) 'opencode write log differs from its golden'
Report-Scenario 'opencode stream renders to its golden transcript'

# commandcode carries neither a per-event clock nor per-step durations, so its
# timeline is anchored on --start and the sequence, not the timing, is the record.
Begin-Scenario
$ccFixture = Join-Path $fx 'commandcode/session.jsonl'
$ccGolden = Join-Path $fx 'commandcode/transcript.md'
$ccGoldenLog = Join-Path $fx 'commandcode/expected-writes.txt'
$ccMd = Join-Path $tmp 'cc.md'
$ccLog = Join-Path $tmp 'cc.log'
Assert-Scenario (Test-Path -LiteralPath $ccFixture -PathType Leaf) 'missing fixture: scripts/tests/fixtures/render-capture-transcript/commandcode/session.jsonl'
& bash $rendererSh $ccFixture $ccMd $ccLog --probe halt-callout --prompt $fxPrompt --model 'deepseek/deepseek-v4.1-flash' --host 'Command Code' --stream-format commandcode --start '2026-11-25T00:00:00+09:00' --offset '+09:00' 2>&1 | Out-Null
Assert-Status $LASTEXITCODE 0
Assert-Scenario (Test-FileEquals $ccMd $ccGolden) 'commandcode transcript differs from its golden'
Assert-Scenario (Test-FileEquals $ccLog $ccGoldenLog) 'commandcode write log differs from its golden'
Report-Scenario 'commandcode stream renders to its golden transcript'

# A format the renderer does not know must fail loudly rather than fall back to
# rendering the stream as if it were agy.
Begin-Scenario
$badOut = (& bash $rendererSh $ocFixture (Join-Path $tmp 'bad.md') (Join-Path $tmp 'bad.log') --probe p --prompt x --model m --stream-format nope 2>&1 | Out-String)
Assert-Status $LASTEXITCODE 2
Assert-Scenario ($badOut -match 'not one of') 'unknown-format output did not name the problem'
Report-Scenario 'an unknown --stream-format is rejected'

# Each format records time differently and the transcript must say which it is.
Begin-Scenario
$agyNote = Get-Content -Raw -LiteralPath (Join-Path $bundles 'halt-callout/transcript.md')
Assert-Scenario ($agyNote -match 'reconstruction of the run') 'the agy bundle does not carry the reconstructed-clock note'
Assert-Scenario ((Get-Content -Raw -LiteralPath $ocGolden) -match 'Timestamps are observed') 'the opencode golden does not carry the observed-clock note'
Assert-Scenario ((Get-Content -Raw -LiteralPath $ccGolden) -match 'neither a per-event clock') 'the commandcode golden does not carry the anchored-only note'
Report-Scenario 'each format states which kind of clock it has'

# A tool name the verb map does not know renders verbatim, which the scorer reads as
# neither an inspection nor a write: the safe direction, but a silent gap unless it
# is named on stderr where a capture operator will see it.
Begin-Scenario
$unknown = Join-Path $tmp 'unknown.jsonl'
$unknownLine = '{"type":"tool_use","timestamp":0,"sessionID":"s","part":{"tool":"mystery_tool","state":{"status":"completed","input":{"path":"x"}}}}'
[IO.File]::WriteAllText($unknown, $unknownLine + "`n")
$uMd = Join-Path $tmp 'u.md'
$uLog = Join-Path $tmp 'u.log'
$uOut = (& bash $rendererSh $unknown $uMd $uLog --probe p --prompt x --model m --stream-format opencode 2>&1 | Out-String)
Assert-Status $LASTEXITCODE 0
Assert-Scenario ($uOut -match 'unmapped tool name') 'an unmapped tool name was not reported on stderr'
Assert-Scenario ((Get-Content -Raw -LiteralPath $uMd) -match 'mystery_tool x \(completed\)') 'an unmapped tool was not rendered verbatim'
Report-Scenario 'an unmapped tool name is rendered verbatim and reported'
Write-Output '== Anchored bundles reproduce their timestamps exactly =='
foreach ($probe in $anchoredProbes) {
    $bundle = Join-Path $bundles $probe
    Begin-Scenario
    $transcript = Join-Path $bundle 'transcript.md'
    $provenance = Join-Path $bundle 'provenance.json'
    if (-not (Test-Path -LiteralPath $transcript) -or -not (Test-Path -LiteralPath $provenance)) {
        Assert-Scenario $false "bundle is missing transcript.md or provenance.json: $probe"
        Report-Scenario "anchored round-trip $probe"
        continue
    }

    # The ce-* bundles render from the derived relative stream; the six earlier
    # bundles predate that derivation and render from the raw stream.
    $relative = Join-Path $bundle 'session.relative.jsonl'
    if (Test-Path -LiteralPath $relative) { $streamName = 'session.relative.jsonl' } else { $streamName = 'session.jsonl' }

    $anchor = Get-TimelineAnchor $provenance
    if ([string]::IsNullOrEmpty($anchor)) {
        Assert-Scenario $false "provenance.json records no timelineStart: $probe"
        Report-Scenario "anchored round-trip $probe"
        continue
    }

    # The rendering offset is a property of the bundle, not of this machine. A
    # bundle that does not record one cannot be reproduced off the host that
    # captured it, which is exactly the defect this case exists to catch.
    $offset = Get-TimelineOffset $provenance
    if ([string]::IsNullOrEmpty($offset)) {
        Assert-Scenario $false "provenance.json records no timelineOffset: $probe"
        Report-Scenario "anchored round-trip $probe"
        continue
    }

    $out = Join-Path $tmp "$probe-anchored.md"
    $log = Join-Path $tmp "$probe-anchored.log"
    $arguments = @(
        (Join-Path $bundle $streamName), $out, $log,
        '--probe', $probe,
        '--prompt', (Get-Field $transcript 'Prompt submitted'),
        '--model', (Get-Field $transcript 'Model'),
        '--invocation', (Get-InvocationField $transcript),
        '--stream', $streamName,
        '--start', $anchor,
        '--offset', $offset
    )
    & bash $rendererSh @arguments 2>&1 | Out-Null
    Assert-Status $LASTEXITCODE 0

    # No timestamp stripping here: the whole point is that the timestamps match.
    $rendered = ([IO.File]::ReadAllText($out)).Replace("`r", '')
    $committed = ([IO.File]::ReadAllText($transcript)).Replace("`r", '')
    Assert-Scenario ($rendered -eq $committed) "re-render with the recorded anchor differs from the committed transcript for $probe"
    Report-Scenario "anchored round-trip $probe"
}

Write-Output '== Rendering is independent of the host time zone =='
# The anchored case above proves a bundle reproduces on THIS machine. It cannot
# prove the rendering is a property of the bundle rather than of the machine,
# because this machine is the one that captured it. Re-render the same bundle
# under two foreign zones and require the identical bytes: a renderer that reads
# the host zone (getTimezoneOffset/getHours) passes the anchored case locally and
# fails here, which is exactly how the defect reached CI.
Begin-Scenario
$zoneBundle = Join-Path $bundles 'breaker-exhaustion'
$zoneAnchor = Get-TimelineAnchor (Join-Path $zoneBundle 'provenance.json')
$zoneOffset = Get-TimelineOffset (Join-Path $zoneBundle 'provenance.json')
if ([string]::IsNullOrEmpty($zoneAnchor) -or [string]::IsNullOrEmpty($zoneOffset)) {
    Assert-Scenario $false 'breaker-exhaustion records no timelineStart/timelineOffset'
} else {
    $zoneTranscript = Join-Path $zoneBundle 'transcript.md'
    $zonePrompt = Get-Field $zoneTranscript 'Prompt submitted'
    $zoneModel = Get-Field $zoneTranscript 'Model'
    $zoneInvocation = Get-InvocationField $zoneTranscript
    $committedZone = ([IO.File]::ReadAllText($zoneTranscript)).Replace("`r", '')
    foreach ($zone in @('UTC', 'America/New_York', 'Asia/Kolkata')) {
        # The zone name carries a slash, so it cannot be used as a file name.
        $zoneSlug = $zone.Replace('/', '_')
        $zoneOut = Join-Path $tmp "zone-$zoneSlug.md"
        $zoneLog = Join-Path $tmp "zone-$zoneSlug.log"
        $zoneArguments = @(
            (Join-Path $zoneBundle 'session.jsonl'), $zoneOut, $zoneLog,
            '--probe', 'breaker-exhaustion',
            '--prompt', $zonePrompt,
            '--model', $zoneModel,
            '--invocation', $zoneInvocation,
            '--stream', 'session.jsonl',
            '--start', $zoneAnchor,
            '--offset', $zoneOffset
        )
        $previousTz = $env:TZ
        $env:TZ = $zone
        try {
            & bash $rendererSh @zoneArguments 2>&1 | Out-Null
            Assert-Status $LASTEXITCODE 0
        } finally {
            $env:TZ = $previousTz
        }
        if (Test-Path -LiteralPath $zoneOut) {
            $renderedZone = ([IO.File]::ReadAllText($zoneOut)).Replace("`r", '')
            Assert-Scenario ($renderedZone -eq $committedZone) "re-render under TZ=$zone differs from the committed transcript"
        } else {
            Assert-Scenario $false "re-render under TZ=$zone produced no transcript"
        }
    }
}
Report-Scenario 'rendering is independent of the host time zone'

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
    $committedVerdict = @(& bash $scorer --score halt-callout (Join-Path $bundle 'transcript.md') 2>&1 | Where-Object { $_ -match '^halt-callout\|' })[0]
    Assert-Scenario ($null -ne $renderedVerdict) 'scorer produced no verdict line for the re-rendered bundle'
    Assert-Scenario ($null -ne $committedVerdict) 'scorer produced no verdict line for the committed transcript'
    Assert-Scenario ($renderedVerdict -eq $committedVerdict) "verdict differs: rendered '$renderedVerdict' vs committed transcript '$committedVerdict'"
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
