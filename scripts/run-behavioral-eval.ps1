# PromptKit OS Behavioral Evaluation Harness (PowerShell)
#
# Scores model transcripts against scenario rubrics in two independent layers:
#
#   * PRESENTATION (field 3, RESULT) — the transcript's observable output
#     properties: a Level was declared, code was withheld, a halt used the
#     mandated callout. All presentation checks must hold; prose equality is
#     never asserted.
#   * BEHAVIOR (field 5, behavioral=) — properties of the capture bundle that
#     holds the transcript: an artifact exists, a prohibited write never
#     happened, recovery reads happened in the mandated order, a recorded field
#     holds a real value instead of a placeholder. Keywords cannot satisfy
#     these; only recorded evidence can, so prose that merely *mentions* halting
#     or checkpointing never earns behavioral credit.
#
# This is the PowerShell twin of scripts/run-behavioral-eval.sh. The Bash twin is
# the reference implementation and this file is a faithful port of it: same check
# types, same three-state evidence verdict, same result lines, same exit codes.
# CONTRIBUTING.md requires both halves to ship together, so any behavior change
# belongs in both files.
#
# Honesty contract: sampled compliance for named models at a named commit,
# not a guarantee. See docs/BEHAVIORAL-EVAL.md.
#
# Run from repository root:
#   pwsh -NoProfile -File .\scripts\run-behavioral-eval.ps1 -SelfTest
#       Offline CI mode. Scores the PASS/FAIL fixtures embedded in every
#       scenario file through the same check engine as live scoring.
#       PASS fixtures must satisfy all checks; FAIL fixtures must violate
#       at least one. No network, no API keys. Exit 0 on success.
#   pwsh -NoProfile -File .\scripts\run-behavioral-eval.ps1 -Score <scenario> -Transcript <file>
#       Live mode. Scores one transcript (produced by any model under any
#       directive variant) and prints the scored line plus failure detail.
#       The evidence bundle is the transcript's parent directory; there is no
#       flag for it, matching the bundle layout
#       scripts/check-milestone-halt-evidence.ps1 already invokes this harness
#       with.
#
# Output: machine-parseable lines.
#   SCENARIO|MODE|RESULT|EVIDENCE|provenance=STATE
#       The scenario declares no evidence checks: RESULT is the presentation
#       verdict.
#   SCENARIO|MODE|RESULT|EVIDENCE|behavioral=VERDICT|provenance=STATE
#       The scenario declares at least one evidence check: a behavioral verdict,
#       graded from bundle evidence alone. VERDICT is PASS, PARTIAL, UNTESTED, or
#       FAIL. UNTESTED means the evidence needed to judge was absent — an invalid
#       observation, never a pass.
# Fields 1-4 keep their exact meaning for every scenario, so callers that
# anchor on SCENARIO|live|PARTIAL| stay correct.
#
# MODE is a scoring mode, not an origin. A hand-written transcript scores in `live`
# mode too, so provenance is reported as its own trailing field and is always
# present: `provenance=verified` when the bundle carries all ten provenance keys
# with real values plus a recorded write log (Test-ProvenanceVerified), and
# `provenance=unverified` otherwise. It never moves RESULT and never moves an exit
# code — a synthetic fixture is labelled, not scored differently.

param(
    [switch]$SelfTest,
    [string]$Score = "",
    [string]$Transcript = ""
)

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
$ScenDir = Join-Path $RepoRoot "scripts/tests/eval-scenarios"

$script:PassCount = 0
$script:FailCount = 0
$script:EvidenceDetail = ""

# The six evidence check types, mirroring run-behavioral-eval.sh eval_checks.
# They decide the behavioral verdict and never move RESULT; the four remaining
# types are the presentation checks counted in checks=M/N.
$script:EvidenceTypes = @(
    'evidence-present', 'evidence-absent', 'prohibited-action',
    'evidence-order', 'repo-unwritten', 'record-field'
)

# The provenance record a genuine capture must carry, mirroring the required key
# list at scripts/check-milestone-halt-evidence.sh:19.
$script:ProvenanceKeys = @(
    'captureDate', 'promptkitCommit', 'profile', 'seedCommit', 'resetCommands',
    'openCodeVersion', 'omoVersion', 'agentModel', 'observationStart', 'observationEnd'
)

function Get-Section {
    param([string]$File, [string]$Heading)
    $out = @()
    $capture = $false
    foreach ($l in Get-Content -LiteralPath $File) {
        if ($l -ceq "## $Heading") { $capture = $true; continue }
        if ($l.StartsWith("## ", [StringComparison]::Ordinal)) { $capture = $false; continue }
        if ($capture) { $out += $l }
    }
    return $out
}

function Split-OnDelimiters {
    # Mirrors `IFS=<delims> read -ra`: split on any delimiter, keep interior
    # empty fields (so "a||b" yields three), and drop the single trailing empty
    # field bash drops.
    param([string]$Text, [string]$DelimiterClass)
    $fields = [regex]::Split($Text, $DelimiterClass)
    if ($fields.Count -gt 1 -and $fields[$fields.Count - 1] -eq '') {
        $fields = $fields[0..($fields.Count - 2)]
    }
    return $fields
}

function Test-PatternIn {
    # Test-PatternIn <lines> <pattern> : the PowerShell twin of `grep -Eq
    # <pattern> <file>`. Matching is per line, which is exactly how grep reads a
    # file, so ^ and $ anchor at line boundaries here and in Bash — joining the
    # lines and matching once would diverge on every ^-anchored scenario check.
    # $null when the pattern is not a valid .NET regex, so an unjudgeable check
    # degrades the same way a failing grep does.
    param([string[]]$Lines, [string]$Pattern)
    $rx = $null
    try { $rx = [regex]::new($Pattern) } catch { return $false }
    foreach ($l in $Lines) { if ($rx.IsMatch($l)) { return $true } }
    return $false
}

function Find-FirstPatternLine {
    # 1-based line number of the first line matching the pattern, or 0 when the
    # pattern never matches — the PowerShell twin of
    # `grep -nE -- <pattern> <log> | head -n 1 | cut -d: -f1`.
    param([string[]]$Lines, [string]$Pattern)
    $rx = $null
    try { $rx = [regex]::new($Pattern) } catch { return 0 }
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($rx.IsMatch($Lines[$i])) { return $i + 1 }
    }
    return 0
}

function Test-SizedFile {
    # A regular file with at least one byte, i.e. bash's `[ -f ] && [ -s ]`.
    # PathType Leaf is load-bearing: plain `[ -s ]` is also true for a directory.
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    return (Get-Item -LiteralPath $Path).Length -gt 0
}

function Test-RecordedActivity {
    # True when the file holds at least one byte that is not ASCII whitespace or NUL.
    # Read as bytes, not text: Get-Content -Raw strips a UTF-8 BOM and returns $null for
    # a BOM-only file, and a text regex would classify control characters by .NET's
    # Unicode-aware \s, so the same bundle graded differently from the Bash twin. The
    # byte set is spelled out to match the twin's `tr -d ' \t\n\r\f\v\000'` exactly.
    # Read through the provider rather than [System.IO.File]::ReadAllBytes: the bundle
    # path comes from Resolve-Path and so carries a `FileSystem::` qualifier, which the
    # .NET API resolves against the process directory and turns into an invalid path.
    # Note this is a blank-file guard, not an activity guard: it cannot tell a recorded
    # tool call from a fabricated byte.
    param([string]$Path)
    try { $bytes = Get-Content -LiteralPath $Path -AsByteStream -Raw } catch { return $false }
    if ($null -eq $bytes) { return $false }
    foreach ($b in $bytes) {
        if (@(0, 9, 10, 11, 12, 13, 32) -notcontains [int]$b) { return $true }
    }
    return $false
}

function Get-EvidenceWriteLog {
    # The bundle's recorded tool-activity write log, or empty when the bundle
    # records none. Both tests are load-bearing and each looks removable:
    # a directory of that name and an unreadable file both record no
    # tool activity, and an empty or blank one records none either.
    param([string]$Bundle)
    foreach ($name in @('observed-writes.log', 'observed-m2-writes.txt')) {
        $candidate = Join-Path $Bundle $name
        if ((Test-SizedFile $candidate) -and (Test-RecordedActivity $candidate)) { return $candidate }
    }
    return ""
}

function Get-EvidenceRecord {
    # The canonical Task/Checkpoint Record inside the bundle. Without an
    # explicit path, state-check.json may name it via recordPath or taskRecord;
    # the default is docs/STATE.md. Resolved against the bundle's repository
    # clone first, then the bundle root, then the bare filename, and finally the
    # recorded end-of-capture copy of the default. Empty when the bundle holds no
    # record at all.
    param([string]$Bundle, [string]$Path)
    if ($Path -eq "") {
        $sc = Join-Path $Bundle 'state-check.json'
        if (Test-Path -LiteralPath $sc -PathType Leaf) {
            foreach ($l in Get-Content -LiteralPath $sc) {
                $m = [regex]::Match($l, '.*"(?:recordPath|taskRecord)"[ \t\r\v\f]*:[ \t\r\v\f]*"([^"]*)".*')
                if ($m.Success) { $Path = $m.Groups[1].Value; break }
            }
        }
        if ($Path -eq "") { $Path = 'docs/STATE.md' }
    }
    if ($Path.StartsWith('./', [StringComparison]::Ordinal)) { $Path = $Path.Substring(2) }
    $leaf = $Path.Substring($Path.LastIndexOf('/') + 1)
    foreach ($candidate in @("$Bundle/repository/$Path", "$Bundle/$Path", "$Bundle/$leaf")) {
        if (Test-SizedFile $candidate) { return $candidate }
    }
    if ($Path -ceq 'docs/STATE.md') {
        $end = Join-Path $Bundle 'state-at-end.md'
        if (Test-SizedFile $end) { return $end }
    }
    return ""
}

function Get-EvidenceFieldValue {
    # Value of the canonical record field, mirroring validate-execution-control.sh
    # field_value — the needle is anchored at column 1, so indented lines and
    # Markdown table rows never match; only the first match counts; a fully
    # backtick-wrapped value loses its outer backticks.
    param([string]$Record, [string]$Label)
    $needle = "- **${Label}**:"
    $space = '[ \t\n\r\v\f]'
    foreach ($l in Get-Content -LiteralPath $Record) {
        $l = $l -replace "`r$", ''
        if (-not $l.StartsWith($needle, [StringComparison]::Ordinal)) { continue }
        $value = $l.Substring($needle.Length)
        $value = $value -replace "^$space+", ''
        $value = $value -replace "$space+$", ''
        if ($value.Length -ge 2 -and $value.StartsWith('`') -and $value.EndsWith('`')) {
            $value = $value.Substring(1, $value.Length - 2)
            $value = $value -replace "^$space+", ''
            $value = $value -replace "$space+$", ''
        }
        return $value
    }
    return ""
}

function Test-EvidenceIsPlaceholder {
    # Mirrors validate-execution-control.sh is_placeholder.
    param([string]$Value)
    $v = $Value.Trim([char[]]" `t`n`r`f`v")
    if ($v -eq '') { return $true }
    switch -CaseSensitive ($v) {
        'N/A' { return $true }
        'n/a' { return $true }
        'None' { return $true }
        'none' { return $true }
        'Not applicable' { return $true }
        'not applicable' { return $true }
        '[N/A]' { return $true }
        '[None]' { return $true }
        '[Pending]' { return $true }
        'Pending' { return $true }
    }
    if ($v.Length -ge 2 -and $v.StartsWith('[') -and $v.EndsWith(']')) { return $true }
    return $false
}

function Test-EvidencePathWritten {
    # True when the log records a write at or under the prefix. The log captures
    # writes observed in tool activity, so a match is a boundary violation even
    # when the repository is clean again because the write was reverted. The
    # Bash twin replaces each of ( ) , ; [ with a space and word-splits; ] is
    # deliberately not a separator, matching its `${line//[(),;[]/ }`.
    param([string]$Log, [string]$Prefix)
    $prefix = $Prefix
    if ($prefix.StartsWith('./', [StringComparison]::Ordinal)) { $prefix = $prefix.Substring(2) }
    if ($prefix.EndsWith('/')) { $prefix = $prefix.Substring(0, $prefix.Length - 1) }
    if ($prefix -eq '') { return $false }
    foreach ($line in Get-Content -LiteralPath $Log) {
        foreach ($token in Split-OnDelimiters ($line -replace '[(),;\[]', ' ') '[ \t\n]+') {
            if ($token -eq '') { continue }
            $t = $token
            if ($t.StartsWith('./', [StringComparison]::Ordinal)) { $t = $t.Substring(2) }
            if ($t.EndsWith('/')) { $t = $t.Substring(0, $t.Length - 1) }
            if ($t -ceq $prefix) { return $true }
            if ($t.StartsWith("$prefix/", [StringComparison]::Ordinal)) { return $true }
        }
    }
    return $false
}

function Get-ProvenanceJsonValue {
    # The value of a JSON string key, or "" when the key is absent or its value is
    # not a string literal — a non-string (null, true, a nested object) is as absent
    # as a missing key. A textual scan, not ConvertFrom-Json: the Bash twin cannot
    # parse JSON natively and both shells have to reach the identical verdict from
    # the identical file, which they can only do with the same text rules. Tolerates
    # either quote spacing and CRLF endings; the first line carrying the key wins.
    param([string]$Path, [string]$Key)
    $needle = '"' + $Key + '"'
    $rx = [regex]::new('^[ \t]*:[ \t]*"')
    foreach ($l in Get-Content -LiteralPath $Path) {
        $l = $l -replace "`r$", ''
        $at = $l.IndexOf($needle, [StringComparison]::Ordinal)
        if ($at -lt 0) { continue }
        $rest = $l.Substring($at + $needle.Length)
        if (-not $rx.IsMatch($rest)) { continue }
        $rest = $rx.Replace($rest, '')
        $end = $rest.IndexOf('"', [StringComparison]::Ordinal)
        if ($end -lt 0) { continue }
        return $rest.Substring(0, $end)
    }
    return ""
}

function Test-ProvenanceVerified {
    # True when the bundle substantiates a genuine capture. `live` in field 2 names
    # the scoring MODE (-Score, not -SelfTest), never the origin of the transcript,
    # so provenance is derived here instead of asserted: all ten provenance keys
    # must hold real, non-placeholder string values — the set
    # scripts/check-milestone-halt-evidence.sh:19 requires — AND a recorded write
    # log must accompany the transcript. The write log is required because a capture
    # with no tool activity cannot substantiate a halt or checkpoint claim, however
    # complete its metadata is.
    param([string]$Bundle)
    if ((Get-EvidenceWriteLog $Bundle) -eq '') { return $false }
    $prov = Join-Path $Bundle 'provenance.json'
    if (-not (Test-SizedFile $prov)) { return $false }
    foreach ($key in $script:ProvenanceKeys) {
        if (Test-EvidenceIsPlaceholder (Get-ProvenanceJsonValue $prov $key)) { return $false }
    }
    return $true
}

function Invoke-EvidenceCheck {
    # Runs one evidence check and returns 0 when the evidence holds, 1 when the
    # evidence needed to judge is absent (UNTESTED), 2 when the evidence shows a
    # violation. Its detail line, when there is one, lands in
    # $script:EvidenceDetail — a side channel so the integer return value stays
    # unambiguous, exactly as the Bash twin relies on $?.
    param([string]$Type, [string]$Pattern, [string]$Bundle)
    $script:EvidenceDetail = ""
    $log = Get-EvidenceWriteLog $Bundle
    switch ($Type) {
        'evidence-present' {
            if (Test-SizedFile (Join-Path $Bundle $Pattern)) { return 0 }
            $script:EvidenceDetail = "    ✗ evidence-present '$Pattern' missing or empty in bundle"; return 1
        }
        'evidence-absent' {
            if (-not (Test-SizedFile (Join-Path $Bundle $Pattern))) { return 0 }
            $script:EvidenceDetail = "    ✗ evidence-absent '$Pattern' present in bundle"; return 2
        }
'prohibited-action' {
              if ($log -eq '') {
                  $script:EvidenceDetail = "    ✗ prohibited-action '$Pattern' unjudgeable (bundle records no readable write log with recorded activity)"; return 1
              }
              # An unreadable log must not read as "no prohibited write found": with
              # $ErrorActionPreference Continue, Get-Content yields $null on failure
              # and Test-PatternIn then iterates nothing and reports no match.
              try { $lines = Get-Content -LiteralPath $log -ErrorAction Stop }
              catch {
                  $script:EvidenceDetail = "    ✗ prohibited-action '$Pattern' unjudgeable ($(Split-Path -Leaf $log) unreadable)"; return 1
              }
              if (Test-PatternIn $lines $Pattern) {
                  $script:EvidenceDetail = "    ✗ prohibited action '$Pattern' observed in $(Split-Path -Leaf $log)"; return 2
              }
              return 0
          }
        'evidence-order' {
            # Ordered steps, space- or pipe-separated. Proves the mandated read
            # order (task record, then checkpoint, then STATE/workflow/root
            # directives) rather than asserting it with keywords.
            $steps = Split-OnDelimiters ($Pattern.Trim([char[]]" `t")) '[ \t|]'
            if ($log -eq '' -or $steps.Count -lt 2) {
                $script:EvidenceDetail = "    ✗ evidence-order '$Pattern' unjudgeable (needs >=2 ordered paths and a recorded write log)"; return 1
            }
            $lines = Get-Content -LiteralPath $log
            $prev = 0
            foreach ($step in $steps) {
                $at = Find-FirstPatternLine $lines $step
                if ($at -eq 0) {
                    $script:EvidenceDetail = "    ✗ evidence-order step '$step' never observed in $(Split-Path -Leaf $log)"; return 1
                }
                if ($at -le $prev) {
                    if ($at -eq $prev) {
                        $script:EvidenceDetail = "    ✗ evidence-order steps '$step' and its predecessor are not separable in $(Split-Path -Leaf $log) (both at line $at)"; return 1
                    }
                    $script:EvidenceDetail = "    ✗ evidence-order step '$step' at line $at came after its predecessor at line $prev"; return 2
                }
                $prev = $at
            }
            return 0
        }
        'repo-unwritten' {
            if ($log -eq '') {
                $script:EvidenceDetail = "    ✗ repo-unwritten '$Pattern' unjudgeable (bundle records no write log)"; return 1
            }
            if (Test-EvidencePathWritten $log $Pattern) {
                $script:EvidenceDetail = "    ✗ repo-unwritten '$Pattern' written in tool activity, even if later reverted"; return 2
            }
            return 0
        }
        'record-field' {
            # "<record-path>|<Label>" names the record explicitly; a bare
            # "<Label>" resolves it through the bundle ladder.
            $target = ""
            $label = $Pattern
            $bar = $Pattern.IndexOf('|')
            if ($bar -ge 0) { $target = $Pattern.Substring(0, $bar); $label = $Pattern.Substring($bar + 1) }
            $record = Get-EvidenceRecord $Bundle $target
            if ($record -eq '') {
                $script:EvidenceDetail = "    ✗ record-field '$label' unjudgeable (bundle holds no canonical record)"; return 1
            }
            $value = Get-EvidenceFieldValue $record $label
            if ($value -eq '') {
                $script:EvidenceDetail = "    ✗ record-field '$label' absent from $(Split-Path -Leaf $record)"; return 2
            }
            if (Test-EvidenceIsPlaceholder $value) {
                $script:EvidenceDetail = "    ✗ record-field '$label' is a placeholder in $(Split-Path -Leaf $record)"; return 2
            }
            return 0
        }
    }
    return 0
}

function Test-Checks {
    # Test-Checks <transcript-file> <checks-text>
    # The four presentation check types decide RESULT by the all-must-hold rule.
    # The six evidence check types read the capture bundle and decide the
    # behavioral verdict reported beside RESULT; they never move RESULT.
    # Returns the side channel the Bash harness reads off stdout —
    # OK|TOTAL|BEHAVIORAL|EVIDENCE_SEEN|DETAIL_LINES — as an object, and
    # $true only when every presentation check holds.
    param([string]$TranscriptPath, [string[]]$CheckLines)
    $lines = @(Get-Content -LiteralPath $TranscriptPath)
    $first = if ($lines.Count -gt 0) { $lines[0] } else { "" }
    $bundle = Split-Path -Parent (Resolve-Path -LiteralPath $TranscriptPath)
    $ok = 0
    $total = 0
    $evViolation = 0
    $evUntested = 0
    $evSeen = 0
    $details = @()
    foreach ($line in $CheckLines) {
        if ($line.StartsWith('- ', [StringComparison]::Ordinal)) { $line = $line.Substring(2) }
        if ($line -eq '') { continue }
        $sep = $line.IndexOf(': ')
        $type = if ($sep -ge 0) { $line.Substring(0, $sep) } else { $line }
        $pat = if ($sep -ge 0) { $line.Substring($sep + 2) } else { $line }
        if ($script:EvidenceTypes -contains $type) {
            $evSeen = 1
            $status = Invoke-EvidenceCheck $type $pat $bundle
            if ($status -eq 1) { $evUntested++ }
            elseif ($status -ge 2) { $evViolation++ }
            if ($script:EvidenceDetail -ne '') { $details += $script:EvidenceDetail }
            continue
        }
        $total++
        switch ($type) {
            'first-line-matches' {
                if (Test-PatternIn @($first) $pat) { $ok++ }
                else { $details += "    ✗ first-line-matches '$pat' (got: $first)" } }
            'contains' {
                if (Test-PatternIn $lines $pat) { $ok++ }
                else { $details += "    ✗ missing '$pat'" } }
            'not-contains' {
                if (Test-PatternIn $lines $pat) { $details += "    ✗ forbidden '$pat' present" }
                else { $ok++ } }
            'contains-any' {
                $hit = $false
                foreach ($alt in Split-OnDelimiters $pat '\|') {
                    if (Test-PatternIn $lines $alt) { $hit = $true; break }
                }
                if ($hit) { $ok++ }
                else { $details += "    ✗ none of '$pat' present" } }
            default { $details += "    ✗ unknown check type '$type'" }
        }
    }
    $verdict = '-'
    if ($evSeen -eq 1) {
        # A prohibited action or any observed violation outranks everything;
        # absent evidence is an invalid observation, never a pass; only then does
        # the presentation verdict leak into the behavioral one.
        if ($evViolation -gt 0) { $verdict = 'FAIL' }
        elseif ($evUntested -gt 0) { $verdict = 'UNTESTED' }
        elseif ($ok -ne $total) { $verdict = 'PARTIAL' }
        else { $verdict = 'PASS' }
    }
    return [pscustomobject]@{
        Passed       = ($ok -eq $total -and $total -gt 0)
        Met          = $ok
        Total        = $total
        Behavioral   = $verdict
        EvidenceSeen = $evSeen
        Details      = $details
    }
}

function Invoke-SelfTest {
    Write-Output ""
    Write-Output "🧪 Behavioral Eval Offline Self-Test (fixtures through the live scoring path)"
    Write-Output "==========================================================================="
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("behavioral-selftest-" + [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        foreach ($f in Get-ChildItem -Path $ScenDir -Filter "*.md" | Sort-Object Name) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
            $passFix = Join-Path $tmp 'pass.md'
            $failFix = Join-Path $tmp 'fail.md'
            # Written the way the Bash twin's `section "$f" X > "$tmp/pass.md"`
            # redirect writes them: one line per section line, LF separated.
            [System.IO.File]::WriteAllText($passFix, (Get-Section $f.FullName 'Transcript-PASS') -join "`n")
            [System.IO.File]::WriteAllText($failFix, (Get-Section $f.FullName 'Transcript-FAIL') -join "`n")
            $checks = Get-Section $f.FullName 'Checks'
            $pass = Test-Checks $passFix $checks
            if ($pass.Passed) {
                $fail = Test-Checks $failFix $checks
                if ($fail.Passed) {
                    Write-Output "  ❌ FAIL: $name — FAIL fixture unexpectedly satisfies all checks"
                    Write-Output "$name|self-test|FAIL|fail-fixture-satisfies-all-checks"
                    $script:FailCount++
                } else {
                    Write-Output "  ✅ PASS: $name (pass-fixture holds, fail-fixture violates)"
                    Write-Output "$name|self-test|PASS|pass-holds-fail-violates"
                    $script:PassCount++
                }
            } else {
                Write-Output "  ❌ FAIL: $name — PASS fixture violates checks:"
                foreach ($d in $pass.Details) { Write-Output "    $d" }
                Write-Output "$name|self-test|FAIL|pass-fixture-violates-checks"
                $script:FailCount++
            }
        }
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Output "==========================================================================="
    Write-Output "Passed: $($script:PassCount) | Failed: $($script:FailCount)"
    if ($script:FailCount -gt 0) { exit 1 }
}

function Invoke-Score {
    param([string]$Name, [string]$TranscriptPath)
    $f = Join-Path $ScenDir "$Name.md"
    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { Write-Error "Unknown scenario '$Name' (see $ScenDir)"; exit 2 }
    if (-not (Test-Path -LiteralPath $TranscriptPath -PathType Leaf)) { Write-Error "Transcript file '$TranscriptPath' not found"; exit 2 }
    $r = Test-Checks $TranscriptPath (Get-Section $f 'Checks')
    $suffix = if ($r.EvidenceSeen -eq 1) { "|behavioral=$($r.Behavioral)" } else { '' }
    if ($r.Passed) { $result = 'PASS' }
    elseif ($r.Met -gt 0) { $result = 'PARTIAL' }
    else { $result = 'FAIL' }
    $bundleDir = Split-Path -Parent (Resolve-Path -LiteralPath $TranscriptPath)
    $provenance = if (Test-ProvenanceVerified $bundleDir) { 'verified' } else { 'unverified' }
    # Provenance is reported on an axis of its own: it records where the transcript
    # came from, never whether the model behaved, and it moves no exit code.
    Write-Output "$Name|live|$result|checks=$($r.Met)/$($r.Total)$suffix|provenance=$provenance"
    if ((-not $r.Passed) -or ($r.EvidenceSeen -eq 1 -and $r.Behavioral -ne 'PASS')) {
        foreach ($d in $r.Details) { Write-Output $d }
    }
    # Exit 0 only when the presentation verdict passes AND no observed boundary
    # violation was recorded. An observed prohibited action or an inverted
    # recovery-read order is behavioral=FAIL and must be non-zero on its own:
    # scripts/check-milestone-halt-evidence.ps1:87 consumes this exit status as
    # success, so a FAIL that exited 0 would be indistinguishable from a pass.
    # behavioral=UNTESTED never fails here on its own — absent evidence is an
    # invalid observation, not observed misbehavior.
    # `exit 0` rather than falling off the end: that caller reads
    # $LASTEXITCODE, which PowerShell only refreshes when the invoked script
    # exits explicitly. The Bash twin's `$?` is 0 here.
    if ($result -eq 'PASS' -and $r.Behavioral -ne 'FAIL') { exit 0 }
    exit 1
}

if ($SelfTest) { Invoke-SelfTest }
elseif ($Score -ne "") { Invoke-Score $Score $Transcript }
else { Write-Error "Usage: run-behavioral-eval.ps1 -SelfTest | -Score <scenario> -Transcript <file>"; exit 2 }