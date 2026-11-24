# Regression harness for the live-capture harness (PowerShell).
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-capture-host-session-tests.ps1
#
# scripts/capture-host-session.mjs is the harness promised by
# docs/internal/host-conformance/antigravity-capture-plan.md section 3.1: it
# seeds a fixture, stages and installs the kit with --host=gemini, applies the
# bwrap isolation, drives agy over --input-format stream-json, and preserves the
# raw NDJSON stream. Three properties matter and are asserted here:
#
#   1. Plan resolution. --print-plan must resolve the scenario's prompt, profile,
#      fixture and bundle without touching the filesystem or invoking a model.
#      This is the only part of the harness that runs in CI, which has neither
#      agy nor bwrap, so it is also the part that catches a scenario/fixture
#      mismatch before a maintainer spends a model turn on it.
#   2. Grading material stays out of the fixture. The staged kit must omit the
#      scenario rubric, the scorer, this evaluation record, the published
#      bundles and the task records, while keeping the discovery route
#      (protocols/context-economy.md, protocols/setup.md, docs/WORKFLOW-MAP.md,
#      workflows/route.md) intact. A regression here silently invalidates every
#      capture, because the model under test could read its own rubric.
#   3. The isolation canary can fail. A canary that reports zero paths because
#      it cannot see the fixture is worse than no canary: it manufactures a
#      false pass. The committed canary.txt must therefore carry a control arm
#      that found copies, a sweep arm that found none, and a direct-read arm
#      that was blocked.
#
# The live capture itself is NOT run here: it spends a model turn and needs agy
# plus bwrap. That case is skipped, not failed, when either is absent.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd('\', '/')
$harnessSh = Join-Path $repoRoot 'scripts/capture-host-session.sh'
$harnessPs1 = Join-Path $repoRoot 'scripts/capture-host-session.ps1'
$module = Join-Path $repoRoot 'scripts/capture-host-session.mjs'
$scorer = Join-Path $repoRoot 'scripts/run-behavioral-eval.sh'
$scenDir = Join-Path $repoRoot 'scripts/tests/eval-scenarios'
$bundles = Join-Path $repoRoot 'docs/internal/host-conformance/antigravity'
$scenarios = @(
    'ce-sufficiency-balanced', 'ce-sufficiency-lite',
    'ce-escalation-balanced', 'ce-escalation-lite',
    'ce-antistarvation-balanced', 'ce-antistarvation-lite'
)

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('pk-capture-host-' + [guid]::NewGuid().ToString('N'))
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

# Read one CAPTURE_PLAN field back out of the plan line.
function Get-PlanField {
    param([string]$Path, [string]$Key)
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if (-not $line.StartsWith('CAPTURE_PLAN|')) { continue }
        foreach ($part in $line.Split('|')) {
            $eq = $part.IndexOf('=')
            if ($eq -gt 0 -and $part.Substring(0, $eq) -eq $Key) {
                return $part.Substring($eq + 1)
            }
        }
    }
    return ''
}

# The plan echoes a native path, so its separator is the host's: a Windows plan
# carries backslashes and a Linux plan carries slashes. Compare on one form
# rather than asserting a separator the harness never promised to emit.
function ConvertTo-PlanPath {
    param([string]$Field)
    return ($Field -replace '\\', '/')
}

# Read the ## Prompt body out of a scenario file: the harness must take the
# prompt from the scenario, not duplicate it, or the two can drift apart.
function Get-ScenarioPrompt {
    param([string]$Path)
    $inSection = $false
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -eq '## Prompt') { $inSection = $true; continue }
        if ($line.StartsWith('## ')) { $inSection = $false; continue }
        if ($inSection) {
            $trimmed = $line.Trim()
            if ($trimmed.Length -gt 0) { return $trimmed }
        }
    }
    return ''
}

function Invoke-Plan {
    param([string]$Scenario, [string]$Bundle, [string]$Out, [string]$Forwarder)
    if ($Forwarder -eq 'ps1') {
        & pwsh -NoProfile -File $harnessPs1 $Scenario $Bundle --print-plan 2>&1 | Out-File -FilePath $Out -Encoding utf8
    } else {
        & bash $harnessSh $Scenario $Bundle --print-plan 2>&1 | Out-File -FilePath $Out -Encoding utf8
    }
    return $LASTEXITCODE
}

Write-Output '== Harness module and forwarders =='
Begin-Scenario
Assert-Scenario (Test-Path -LiteralPath $module -PathType Leaf) 'missing module: scripts/capture-host-session.mjs'
Assert-Scenario (Test-Path -LiteralPath $harnessSh -PathType Leaf) 'missing forwarder: scripts/capture-host-session.sh'
Assert-Scenario (Test-Path -LiteralPath $harnessPs1 -PathType Leaf) 'missing forwarder: scripts/capture-host-session.ps1'
Report-Scenario 'harness module and both forwarders exist'

Write-Output '== Argument validation =='
Begin-Scenario
$out = (& bash $harnessSh 2>&1 | Out-String); $status = $LASTEXITCODE
Assert-Status $status 2
Assert-Scenario ($out.Contains('Usage:')) 'no-argument output did not print usage'
$out = (& bash $harnessSh 'ce-sufficiency-balanced' 2>&1 | Out-String); $status = $LASTEXITCODE
Assert-Status $status 2
Assert-Scenario ($out.Contains('Usage:')) 'one-positional output did not print usage'
$out = (& bash $harnessSh 'ce-sufficiency-balanced' (Join-Path $tmp 'b') '--bogus' 'y' 2>&1 | Out-String); $status = $LASTEXITCODE
Assert-Status $status 2
Assert-Scenario ($out.Contains('unknown argument')) 'unknown-flag output did not name the problem'
$out = (& bash $harnessSh 'no-such-scenario' (Join-Path $tmp 'b') '--print-plan' 2>&1 | Out-String); $status = $LASTEXITCODE
Assert-Status $status 2
Assert-Scenario ($out.Contains('no such scenario')) 'missing-scenario output did not name the problem'
Report-Scenario 'argument validation rejects bad invocations with exit 2'

Write-Output '== Plan resolution for every ce-* scenario =='
foreach ($scenario in $scenarios) {
    Begin-Scenario
    $scenarioFile = Join-Path $scenDir ($scenario + '.md')
    if (-not (Test-Path -LiteralPath $scenarioFile -PathType Leaf)) {
        Assert-Scenario $false "missing scenario file: scripts/tests/eval-scenarios/$scenario.md"
        Report-Scenario "plan $scenario"
        continue
    }
    $plan = Join-Path $tmp ($scenario + '.plan')
    $bundle = Join-Path $tmp ($scenario + '-bundle')
    $status = Invoke-Plan -Scenario $scenario -Bundle $bundle -Out $plan -Forwarder 'sh'
    Assert-Status $status 0

    # The profile comes from the scenario's own ## Directive body, and the
    # scenario name must agree with it: a mismatch means the file and its name
    # disagree and the capture would install the wrong directive.
    $expectedProfile = $scenario.Substring($scenario.LastIndexOf('-') + 1)
    Assert-Scenario ((Get-PlanField $plan 'profile') -eq $expectedProfile) "profile resolved to '$(Get-PlanField $plan 'profile')', expected '$expectedProfile'"

    # The fixture is shared by the Balanced and Lite cells of a probe, so it is
    # named without the profile suffix.
    $expectedFixture = $scenario.Substring(0, $scenario.Length - $expectedProfile.Length - 1)
    $fixtureField = ConvertTo-PlanPath (Get-PlanField $plan 'fixture')
    Assert-Scenario ($fixtureField.EndsWith('/' + $expectedFixture)) "fixture resolved to '$fixtureField', expected .../$expectedFixture"

    # The probe label is the full scenario name: it is the cell identity that
    # reaches the transcript, the README and state-check.json.
    Assert-Scenario ((Get-PlanField $plan 'probe') -eq $scenario) "probe resolved to '$(Get-PlanField $plan 'probe')', expected '$scenario'"

    # The prompt must come from the scenario file, not be duplicated in the
    # harness: a drift between the two would capture the wrong task.
    $scenarioPrompt = Get-ScenarioPrompt $scenarioFile
    $planPrompt = ''
    foreach ($line in [IO.File]::ReadAllLines($plan)) {
        if ($line.StartsWith('CAPTURE_PROMPT|')) { $planPrompt = $line.Substring('CAPTURE_PROMPT|'.Length); break }
    }
    Assert-Scenario ($scenarioPrompt.Length -gt 0 -and $planPrompt -eq $scenarioPrompt) "prompt resolved to '$planPrompt', expected '$scenarioPrompt'"

    # --print-plan must not touch the filesystem: the bundle directory is a
    # destination, not a side effect.
    Assert-Scenario (-not (Test-Path -LiteralPath $bundle)) '--print-plan created the bundle directory'
    Report-Scenario "plan $scenario"
}

Write-Output '== Twin parity =='
Begin-Scenario
# Both forwarders are given the same bundle path: the plan echoes it, so a
# difference in the path would mask a real difference in the plan.
$twinBundle = Join-Path $tmp 'twin-bundle'
$shPlan = Join-Path $tmp 'twin-sh.txt'
$psPlan = Join-Path $tmp 'twin-ps.txt'
$status = Invoke-Plan -Scenario 'ce-escalation-balanced' -Bundle $twinBundle -Out $shPlan -Forwarder 'sh'
Assert-Status $status 0
$status = Invoke-Plan -Scenario 'ce-escalation-balanced' -Bundle $twinBundle -Out $psPlan -Forwarder 'ps1'
Assert-Status $status 0
$shText = ([IO.File]::ReadAllText($shPlan)) -replace "`r`n", "`n"
$psText = ([IO.File]::ReadAllText($psPlan)) -replace "`r`n", "`n"
Assert-Scenario ($shText -eq $psText) 'Bash and PowerShell plans differ'
# The plan echoes a native path, so only the Windows job ever sees a backslash
# fixture. Pin the normalization here, where it runs on every host: this is the
# assertion that fails if the comparison regresses to a '/'-anchored suffix test
# on the raw field, which is the defect that shipped a red Windows job.
Assert-Scenario ((ConvertTo-PlanPath 'C:\repo\scripts\tests\fixtures\ce-capture\ce-sufficiency').EndsWith('/ce-sufficiency')) 'plan path normalization rejects a backslash path'
Report-Scenario 'Bash and PowerShell forwarders produce identical plans'

Write-Output '== Committed bundles keep grading material out of the fixture =='
foreach ($scenario in $scenarios) {
    $bundle = Join-Path $bundles $scenario
    Begin-Scenario
    $exclusions = Join-Path $bundle 'kit-exclusions.txt'
    if (-not (Test-Path -LiteralPath $exclusions -PathType Leaf)) {
        Assert-Scenario $false "bundle has no kit-exclusions.txt: $scenario"
        Report-Scenario "exclusions $scenario"
        continue
    }
    $lines = [IO.File]::ReadAllLines($exclusions)
    # Every exclusion must be recorded as absent. A 'LEAK' line means the model
    # under test could have read its own rubric, which invalidates the capture.
    Assert-Scenario (-not ($lines | Where-Object { $_ -match '^LEAK ' })) 'kit-exclusions.txt records a leak'
    foreach ($rel in @('scripts/tests/eval-scenarios', 'scripts/run-behavioral-eval.sh', 'docs/BEHAVIORAL-EVAL.md', 'docs/internal/host-conformance', 'docs/tasks')) {
        $pattern = '^absent  ' + [regex]::Escape($rel) + '( |$)'
        Assert-Scenario ([bool]($lines | Where-Object { $_ -match $pattern })) "kit-exclusions.txt does not record $rel as absent"
    }
    # The discovery route must survive the pruning, or the capture measures nothing.
    foreach ($rel in @('protocols/context-economy.md', 'protocols/setup.md', 'docs/WORKFLOW-MAP.md', 'workflows/route.md')) {
        $pattern = '^present  ' + [regex]::Escape($rel) + '( |$)'
        Assert-Scenario ([bool]($lines | Where-Object { $_ -match $pattern })) "kit-exclusions.txt does not record $rel as present"
    }
    Report-Scenario "exclusions $scenario"
}

Write-Output '== Committed canaries can fail =='
foreach ($scenario in $scenarios) {
    $bundle = Join-Path $bundles $scenario
    Begin-Scenario
    $canary = Join-Path $bundle 'canary.txt'
    if (-not (Test-Path -LiteralPath $canary -PathType Leaf)) {
        Assert-Scenario $false "bundle has no canary.txt: $scenario"
        Report-Scenario "canary $scenario"
        continue
    }
    $line = ([IO.File]::ReadAllLines($canary) | Where-Object { $_ -match '^CANARY\|' } | Select-Object -First 1)
    Assert-Scenario ([bool]$line) 'canary.txt has no CANARY| verdict line'
    Assert-Scenario ($line -like 'CANARY|PASS*') "canary did not pass: $line"
    # The control arm is what makes the canary meaningful: if it found nothing,
    # the isolated arm's empty result proves nothing at all.
    $unisolated = 0; $isolated = 0
    if ($line -match '\|unisolated=([0-9]+)') { $unisolated = [int]$Matches[1] }
    if ($line -match '\|isolated=([0-9]+)') { $isolated = [int]$Matches[1] }
    Assert-Scenario ($unisolated -gt 0) "control arm found no copy, so the canary proves nothing: $line"
    Assert-Scenario ($isolated -eq 0) "isolated arm still found copies: $line"
    # The direct-read arm is the one that catches a blind sweep: a bounded find
    # can miss a readable file, but cat either opens it or it does not.
    Assert-Scenario ($line.Contains('direct-read=blocked')) "direct-read arm did not report a blocked read: $line"
    Report-Scenario "canary $scenario"
}

Write-Output '== Committed bundles record a reproducible timeline =='
foreach ($scenario in $scenarios) {
    $bundle = Join-Path $bundles $scenario
    Begin-Scenario
    $provenance = Join-Path $bundle 'provenance.json'
    $transcript = Join-Path $bundle 'transcript.md'
    if (-not (Test-Path -LiteralPath $provenance -PathType Leaf) -or -not (Test-Path -LiteralPath $transcript -PathType Leaf)) {
        Assert-Scenario $false "bundle is missing provenance.json or transcript.md: $scenario"
        Report-Scenario "timeline $scenario"
        continue
    }
    # The renderer reconstructs the timeline from a recorded anchor rather than
    # from the stream file's mtime, because git does not preserve mtime and a
    # committed bundle re-rendered elsewhere would shift every timestamp. The
    # anchor must therefore be in the bundle, and it must be the instant the
    # harness observed before spawning agy - not an approximation derived from
    # the reported duration, which drifts by the harness's own overhead.
    $provText = [IO.File]::ReadAllText($provenance)
    $anchor = ''; $observed = ''; $windowEnd = ''
    $m = [regex]::Match($provText, '"timelineStart"\s*:\s*"([^"]+)"'); if ($m.Success) { $anchor = $m.Groups[1].Value }
    $m = [regex]::Match($provText, '"observationStart"\s*:\s*"([^"]+)"'); if ($m.Success) { $observed = $m.Groups[1].Value }
    $m = [regex]::Match($provText, '"observationEnd"\s*:\s*"([^"]+)"'); if ($m.Success) { $windowEnd = $m.Groups[1].Value }
    Assert-Scenario (-not [string]::IsNullOrEmpty($anchor)) "provenance.json records no timelineStart: $scenario"
    if (-not [string]::IsNullOrEmpty($anchor) -and -not [string]::IsNullOrEmpty($observed)) {
        $anchorEpoch = [DateTimeOffset]::Parse($anchor).ToUnixTimeSeconds()
        $observedEpoch = [DateTimeOffset]::Parse($observed).ToUnixTimeSeconds()
        Assert-Scenario ($anchorEpoch -eq $observedEpoch) "timelineStart ($anchor) is not the observed capture start ($observed): $scenario"
    }
    # Every rendered entry must land inside the window the same bundle records.
    # A timeline that contradicts its own provenance is not evidence.
    $lines = [IO.File]::ReadAllLines($transcript)
    $stamps = @()
    foreach ($line in $lines) {
        $tm = [regex]::Match($line, '^- .([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+[+-][0-9]{2}:[0-9]{2}). ')
        if ($tm.Success) { $stamps += $tm.Groups[1].Value }
    }
    if ($stamps.Count -gt 0 -and -not [string]::IsNullOrEmpty($observed) -and -not [string]::IsNullOrEmpty($windowEnd)) {
        $firstEpoch = [DateTimeOffset]::Parse($stamps[0]).ToUnixTimeSeconds()
        $lastEpoch = [DateTimeOffset]::Parse($stamps[$stamps.Count - 1]).ToUnixTimeSeconds()
        $startEpoch = [DateTimeOffset]::Parse($observed).ToUnixTimeSeconds()
        $endEpoch = [DateTimeOffset]::Parse($windowEnd).ToUnixTimeSeconds()
        Assert-Scenario ($firstEpoch -ge $startEpoch -and $lastEpoch -le $endEpoch) "transcript timeline ($($stamps[0]) .. $($stamps[$stamps.Count - 1])) falls outside the recorded window ($observed .. $windowEnd): $scenario"
    }
    Report-Scenario "timeline $scenario"
}

Write-Output '== Committed bundles still score their recorded verdict =='
foreach ($scenario in $scenarios) {
    $bundle = Join-Path $bundles $scenario
    Begin-Scenario
    $scorerTxt = Join-Path $bundle 'scorer.txt'
    $transcript = Join-Path $bundle 'transcript.md'
    if (-not (Test-Path -LiteralPath $scorerTxt -PathType Leaf) -or -not (Test-Path -LiteralPath $transcript -PathType Leaf)) {
        Assert-Scenario $false "bundle is missing scorer.txt or transcript.md: $scenario"
        Report-Scenario "score $scenario"
        continue
    }
    $rendered = (& bash $scorer '--score' $scenario $transcript 2>&1 | Where-Object { $_ -match ('^' + [regex]::Escape($scenario) + '\|') } | Select-Object -First 1)
    $committed = ([IO.File]::ReadAllLines($scorerTxt) | Where-Object { $_ -match ('^' + [regex]::Escape($scenario) + '\|') } | Select-Object -First 1)
    Assert-Scenario ([bool]$rendered) "scorer produced no verdict line for $scenario"
    Assert-Scenario ($rendered -eq $committed) "verdict differs: rendered '$rendered' vs committed '$committed'"
    Report-Scenario "score $scenario"
}

Write-Output '== Fresh clone: every bundle write log is tracked and a stub is rejected =='
# The defect this case exists for: the repository root ignores *.log, and a
# negation only takes effect in a .gitignore at or below the ignored path. The
# bundles had no .gitignore of their own, so every observed-writes.log was
# silently untracked - the bundle's primary evidence never reached a clone, and
# a fresh checkout graded each bundle from whatever else it happened to carry.
# A working tree cannot show this: the file is right there on disk. Only a
# clone can, which is why the case clones.
#
# The second half is the same defect one layer down. A comment-only stub is a
# note that the log does not apply, not a log, and a scorer that accepts one
# searches it, finds no prohibited action, and reports compliance. Both halves
# are asserted here because either one alone still publishes a bundle that
# cannot be re-graded.
Begin-Scenario
$clone = Join-Path $tmp 'fresh-clone'
& git clone --quiet --no-hardlinks --shared $repoRoot $clone 2>&1 | Out-Null
$cloneStatus = $LASTEXITCODE
if ($cloneStatus -ne 0) {
    Assert-Scenario $false "git clone failed with exit $cloneStatus"
    Report-Scenario 'fresh clone reproduces every bundle write log'
} else {
    # The clone starts from HEAD, and the fix is uncommitted by instruction, so
    # the bundle files are copied in from the working tree before the assertion.
    # That is not a shortcut around the check: what is under test is whether git
    # will TRACK the log given the .gitignore that sits beside it, and the copy
    # only puts the two files where git can answer that. A clone of HEAD alone
    # would test the defect instead of the fix.
    foreach ($scenario in $scenarios) {
        $bundle = Join-Path $bundles $scenario
        $dest = Join-Path $clone ('docs/internal/host-conformance/antigravity/' + $scenario)
        $log = Join-Path $bundle 'observed-writes.log'
        $ignore = Join-Path $bundle '.gitignore'
        # The log must exist in the working tree at all: a bundle with no write
        # log cannot substantiate anything, and the tracked check below would
        # otherwise pass vacuously on a missing file.
        Assert-Scenario ((Test-Path -LiteralPath $log -PathType Leaf) -and ((Get-Item -LiteralPath $log).Length -gt 0)) "bundle has no non-empty observed-writes.log: $scenario"
        Assert-Scenario (Test-Path -LiteralPath $ignore -PathType Leaf) "bundle has no .gitignore, so its write log cannot be un-ignored: $scenario"
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        if (Test-Path -LiteralPath $ignore -PathType Leaf) { Copy-Item -LiteralPath $ignore -Destination (Join-Path $dest '.gitignore') -Force }
        if (Test-Path -LiteralPath $log -PathType Leaf) { Copy-Item -LiteralPath $log -Destination (Join-Path $dest 'observed-writes.log') -Force }
        $rel = 'docs/internal/host-conformance/antigravity/' + $scenario + '/observed-writes.log'
        # git check-ignore exits 0 when the path IS ignored and 1 when it is not.
        # Asserting the exit status rather than the output is deliberate: with -v
        # git prints the matching negation line and still exits 0, so an output
        # match would read a negation as an ignore.
        & git -C $clone check-ignore -q -- $rel 2>&1 | Out-Null
        Assert-Scenario ($LASTEXITCODE -eq 1) "observed-writes.log is still ignored in a fresh clone: $scenario"
        # Ignored is not the same as tracked, and staging is the operation that
        # separates them: git refuses an ignored path outright. This is the check
        # that would have caught the defect, because the old tree staged every
        # bundle file except the log and nothing said so.
        & git -C $clone add -- $rel 2>&1 | Out-Null
        Assert-Scenario ($LASTEXITCODE -eq 0) "git add refused the write log in a fresh clone: $scenario"
        & git -C $clone ls-files --error-unmatch -- $rel 2>&1 | Out-Null
        Assert-Scenario ($LASTEXITCODE -eq 0) "observed-writes.log is not tracked in a fresh clone: $scenario"
    }
    Report-Scenario 'fresh clone reproduces every bundle write log'
}

# The stub half. A bundle whose only write log is a comment must not grade as if
# it had recorded activity: the scorer has to report the evidence as absent
# rather than search a note and find no violation in it.
Begin-Scenario
$stub = Join-Path $tmp 'stub-bundle'
Copy-Item -LiteralPath (Join-Path $bundles 'ce-antistarvation-balanced') -Destination $stub -Recurse -Force
$stubNote = "# Not applicable - this probe records no M2 writes." + [Environment]::NewLine
[IO.File]::WriteAllText((Join-Path $stub 'observed-writes.log'), $stubNote)
[IO.File]::WriteAllText((Join-Path $stub 'observed-m2-writes.txt'), $stubNote)
$stubLine = (& bash $scorer '--score' 'ce-antistarvation-balanced' (Join-Path $stub 'transcript.md') 2>&1 | Where-Object { $_ -match '^ce-antistarvation-balanced\|' } | Select-Object -First 1)
Assert-Scenario ([bool]$stubLine) 'scorer produced no verdict line for the stub bundle'
# behavioral=UNTESTED is the assertion, not merely "not PASS": the scorer must
# say the evidence is absent. A comment-only log that graded PARTIAL would mean
# the stub was searched and its emptiness read as compliance.
Assert-Scenario ($stubLine -like '*behavioral=UNTESTED*') "a comment-only write log was not rejected as absent evidence: $stubLine"
Assert-Scenario ($stubLine -like '*provenance=unverified*') "a comment-only write log still verified provenance: $stubLine"
# The control: the same bundle with its real log must still grade as recorded,
# or the case would pass by rejecting every bundle rather than the stub.
$realLine = (& bash $scorer '--score' 'ce-antistarvation-balanced' (Join-Path $bundles 'ce-antistarvation-balanced/transcript.md') 2>&1 | Where-Object { $_ -match '^ce-antistarvation-balanced\|' } | Select-Object -First 1)
Assert-Scenario ($realLine -like '*behavioral=PASS*') "the real bundle no longer grades as recorded: $realLine"
Report-Scenario 'a comment-only write log is rejected as absent evidence'

Write-Output '== Live capture (skipped without agy and bwrap) =='
$agy = Get-Command agy -ErrorAction SilentlyContinue
$bwrap = Get-Command bwrap -ErrorAction SilentlyContinue
if ($agy -and $bwrap) {
    Begin-Scenario
    # A live capture spends a model turn, so it is not run here. What is asserted
    # is that the harness reaches the point of invoking the model: the plan
    # resolves and both binaries are found.
    $plan = Join-Path $tmp 'live.plan'
    $status = Invoke-Plan -Scenario 'ce-sufficiency-balanced' -Bundle (Join-Path $tmp 'live-bundle') -Out $plan -Forwarder 'sh'
    Assert-Status $status 0
    $agyLine = ([IO.File]::ReadAllLines($plan) | Where-Object { $_ -match '^CAPTURE_AGY\|' } | Select-Object -First 1)
    $bwrapLine = ([IO.File]::ReadAllLines($plan) | Where-Object { $_ -match '^CAPTURE_BWRAP\|' } | Select-Object -First 1)
    Assert-Scenario ($agyLine -notlike '*|(not found)') 'harness did not resolve agy'
    Assert-Scenario ($bwrapLine -notlike '*|(not found)') 'harness did not resolve bwrap'
    Report-Scenario 'harness resolves agy and bwrap for a live capture'
} else {
    Write-Output 'SKIP: live capture prerequisites (agy and/or bwrap not available)'
}

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Output ''
if ($script:FAIL -eq 0) {
    Write-Output ("CAPTURE_HOST_SESSION_TESTS|PASS|{0} passed" -f $script:PASS)
    exit 0
}
Write-Output ("CAPTURE_HOST_SESSION_TESTS|FAIL|{0} passed, {1} failed" -f $script:PASS, $script:FAIL)
exit 1
