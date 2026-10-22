<#
.SYNOPSIS
    E2E profile matrix tests for init.ps1 (issue #143, PowerShell parity for run-profile-matrix.sh).
.DESCRIPTION
    Covers the 3-profile flag matrix, the --turbo/--experimental guard, non-interactive
    fallback via PROMPTKIT_NO_INTERACTIVE, and lite -> balanced upgrade idempotency.
    All invocations run with redirected stdin (the CI contract); the real-TTY picker
    skip is a manual check (PTY simulation is out of scope per #144/#143).
.NOTES
    Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-profile-matrix.ps1
#>

[CmdletBinding()]
param ()

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Init = Join-Path $RepoRoot "init.ps1"
$TestRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pk-matrix-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null

$script:Pass = 0
$script:Fail = 0

function Ok([string]$name)   { Write-Host "  PASS: $name" -ForegroundColor Green; $script:Pass++ }
function NotOk([string]$name){ Write-Host "  FAIL: $name" -ForegroundColor Red;   $script:Fail++ }

function ProfileOf([string]$dir) {
    $file = Join-Path $dir "PROMPTKIT.md"
    if (-not (Test-Path $file)) { return "" }
    $line = (Get-Content $file | Where-Object { $_ -match '^profile:' } | Select-Object -Last 1)
    if ($line) { return ($line -split '\s+' | Select-Object -Last 1) }
    return ""
}

function Normalize-EngineStamp([string]$text) {
    # The engine stamp is resolved from git, so it differs per machine and per commit. It is
    # canonicalized on BOTH sides, which keeps the comparison independent of the installer's
    # git state. That is safe only because test 10 separately asserts the installed block
    # contains no leftover $ENGINE_VERSION/$ENGINE_SHA tokens.
    # A MatchEvaluator is used rather than -replace because the replacement text contains a
    # literal '$', which -replace would read as a substitution reference.
    return [regex]::Replace(
        $text,
        '(?m)^Engine: .* \(.*\) — stamped at install time',
        { param($match) 'Engine: $ENGINE_VERSION ($ENGINE_SHA) — stamped at install time' })
}

function Normalize-Template([string]$text) {
    # $KIT_DIR_REL is normalized on the TEMPLATE SIDE ONLY, and that asymmetry is deliberate.
    # Applying it to both sides would rewrite a literal $KIT_DIR_REL in the installed block into
    # .promptkit and make a broken substitution compare clean — masking the exact defect the
    # comparison exists to catch. Nothing else in the suite asserts $KIT_DIR_REL does not leak,
    # so test 14 pins that rejection directly.
    $text = $text.Replace('$KIT_DIR_REL', '.promptkit')
    return (Normalize-EngineStamp $text)
}

function ManagedBlockMatchesTemplate([string]$target, [string]$template) {
    $hostText = (Get-Content $target -Raw) -replace "`r`n", "`n"
    $templateText = (Get-Content $template -Raw) -replace "`r`n", "`n"
    return (Normalize-EngineStamp $hostText).Contains((Normalize-Template $templateText))
}

function NewDir([string]$name) {
    $d = Join-Path $TestRoot $name
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    return $d
}

Write-Host "`n🧪 init.ps1 Profile Matrix Tests (non-interactive contract)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. No flag: defaults to balanced.
$d = NewDir "t1"
& pwsh -NoProfile -File $Init $d 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0 -and (ProfileOf $d) -eq "balanced") { Ok "no flag defaults to balanced (exit 0)" }
else { NotOk "no flag should default balanced (rc=$LASTEXITCODE, profile=$(ProfileOf $d))" }

# 2. --lite: profile lite + Lite directive injected.
$d = NewDir "t2"
& pwsh -NoProfile -File $Init --lite $d 2>&1 | Out-Null
$agents = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
if ((ProfileOf $d) -eq "lite" -and $agents -match "PromptKit OS Lite" -and (ManagedBlockMatchesTemplate (Join-Path $d "AGENTS.md") (Join-Path $RepoRoot "templates/agent-directive-lite-template.md"))) { Ok "--lite sets profile lite and renders the selected directive template" }
else { NotOk "--lite install (profile=$(ProfileOf $d))" }

# 3. --balanced: profile balanced + full directive header.
$d = NewDir "t3"
& pwsh -NoProfile -File $Init --balanced $d 2>&1 | Out-Null
$agents = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
if ((ProfileOf $d) -eq "balanced" -and $agents -match "(?m)^## PromptKit OS: Engineering Operating System$" -and (ManagedBlockMatchesTemplate (Join-Path $d "AGENTS.md") (Join-Path $RepoRoot "templates/agent-directive-template.md"))) { Ok "--balanced sets profile balanced and renders the selected directive template" }
else { NotOk "--balanced install (profile=$(ProfileOf $d))" }

# 4. --turbo without --experimental: must fail with guard message.
$d = NewDir "t4"
$out = & pwsh -NoProfile -File $Init --turbo $d 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -and $out -match "requires --experimental") { Ok "--turbo alone is rejected with --experimental guard" }
else { NotOk "--turbo alone should exit non-zero with guard (rc=$LASTEXITCODE)" }

# 5. --turbo --experimental: profile turbo accepted.
$d = NewDir "t5"
& pwsh -NoProfile -File $Init --turbo --experimental $d 2>&1 | Out-Null
if ((ProfileOf $d) -eq "turbo") { Ok "--turbo --experimental sets profile turbo" }
else { NotOk "--turbo --experimental install (profile=$(ProfileOf $d))" }

# 6. PROMPTKIT_NO_INTERACTIVE=1: accepted, no picker text, defaults balanced.
$d = NewDir "t6"
$env:PROMPTKIT_NO_INTERACTIVE = "1"
$out = & pwsh -NoProfile -File $Init $d 2>&1 | Out-String
Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
if ($LASTEXITCODE -eq 0 -and $out -notmatch "Profile Selection" -and (ProfileOf $d) -eq "balanced") { Ok "PROMPTKIT_NO_INTERACTIVE=1 yields non-interactive default" }
else { NotOk "env-var escape test (rc=$LASTEXITCODE, profile=$(ProfileOf $d))" }

# 7. Upgrade path lite -> balanced re-run: profile flips, single directive block.
$d = NewDir "t7"
& pwsh -NoProfile -File $Init --lite $d 2>&1 | Out-Null
& pwsh -NoProfile -File $Init --balanced $d 2>&1 | Out-Null
$agentsRaw = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
$profileDoc = (Get-Content (Join-Path $d "PROMPTKIT.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
$markerCount = ([regex]::Matches($agentsRaw, "(?m)^<!-- PROMPTKIT_START -->$")).Count
if ((ProfileOf $d) -eq "balanced" -and $markerCount -eq 1 -and $agentsRaw -match "(?m)^## PromptKit OS: Engineering Operating System$" -and $profileDoc -match "(?m)^- \*\*Profile\*\*: balanced$") { Ok "lite -> balanced upgrade is idempotent (profile + Section 0 body flip, one directive block)" }
else { NotOk "upgrade re-run (profile=$(ProfileOf $d), markers=$markerCount)" }

# 8. Aider parity: existing CONVENTIONS.md receives an idempotent directive block.
$d = NewDir "t8"
Set-Content -Path (Join-Path $d "CONVENTIONS.md") -Value "# My aider notes" -NoNewline
& pwsh -NoProfile -File $Init --balanced $d 2>&1 | Out-Null
$c = (Get-Content (Join-Path $d "CONVENTIONS.md") -Raw) -replace "\r\n", "`n"
$cm = ([regex]::Matches($c, "(?m)^<!-- PROMPTKIT_START -->$")).Count
if ($cm -eq 1 -and $c -match "(?m)^# My aider notes$") { Ok "existing CONVENTIONS.md injected idempotently with user content preserved" }
else { NotOk "CONVENTIONS.md injection (markers=$cm)" }

$d = NewDir "t9-agents-only"
$env:PROMPTKIT_NO_PREFLIGHT = "1"
& pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
$initialExitCode = $LASTEXITCODE
if ($initialExitCode -eq 0) {
    $out = & pwsh -NoProfile -File $Init $d 2>&1 | Out-String
    $rerunExitCode = $LASTEXITCODE
    $hostFiles = @("CLAUDE.md", ".opencode/rules.md", ".cursorrules", "GEMINI.md", ".windsurfrules", ".github/copilot-instructions.md", ".clinerules", ".traerules", "CONVENTIONS.md")
    $unexpectedHostFiles = @($hostFiles | Where-Object { Test-Path (Join-Path $d $_) })
    if ($rerunExitCode -eq 0 -and $out -match "Keeping installed hosts: agents" -and (Test-Path (Join-Path $d "AGENTS.md")) -and $unexpectedHostFiles.Count -eq 0) {
        Ok "AGENTS.md-only install preserves universal hosts on rerun"
    } else { NotOk "AGENTS.md-only rerun did not preserve universal host choice (rc=$rerunExitCode)" }
} else { NotOk "AGENTS.md-only initial install (rc=$initialExitCode)" }
Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue

# 10. Engine identity stamp: init.ps1 substitutes $ENGINE_VERSION / $ENGINE_SHA, so
# the literal tokens must not survive into the rendered directive. The sha must be a
# real short hash (or the no-git `unknown` fallback) rather than arbitrary text, since
# the stamp exists to make engine drift detectable.
$d = NewDir "t10-engine-stamp"
& pwsh -NoProfile -File $Init --balanced $d 2>&1 | Out-Null
$stampAgents = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "`r`n", "`n"
if ($stampAgents -match "(?m)^Engine: [^\$]+ \((unknown|[0-9a-f]{7,})\) — stamped at install time" -and $stampAgents -notmatch '\$ENGINE_VERSION|\$ENGINE_SHA') {
    Ok "engine identity stamp is substituted into the rendered directive"
} else {
    NotOk "engine identity stamp unresolved (tokens leaked or stamp line missing)"
}

# 11. Adversarial git tag: a legal ref name may contain .NET replacement metacharacters
# ('$' introduces a substitution reference, '&' is the whole match). The install must still
# succeed with the hostile version degraded rather than substituted into the directive.
# NOTE: the Windows filesystem cannot create a ref containing '|', so the payload here is the
# '$'/'&' class only; the POSIX harness additionally covers the sed delimiter.
$fixtureKit = Join-Path $TestRoot "t11-kit"
New-Item -ItemType Directory -Force -Path (Join-Path $fixtureKit "scripts") | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot "templates") -Destination $fixtureKit -Recurse -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot "scripts\terminal-picker.ps1") -Destination (Join-Path $fixtureKit "scripts") -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath (Join-Path $RepoRoot "init.ps1") -Destination $fixtureKit -Force
    # The install-door assert (#549) needs its checker in the kit; this synthetic partial
    # kit ships it and opts out, since its subject is adversarial-tag stamp robustness.
    Copy-Item -LiteralPath (Join-Path $RepoRoot "scripts\check-setup-assert.ps1") -Destination (Join-Path $fixtureKit "scripts") -Force
    & git -C $fixtureKit init -q 2>&1 | Out-Null
& git -C $fixtureKit add -A 2>&1 | Out-Null
& git -C $fixtureKit -c user.email=fixture@example.invalid -c user.name=fixture commit -qm fixture 2>&1 | Out-Null
& git -C $fixtureKit tag ("v1.0.0-" + [char]36 + "1-" + [char]38 + "y") 2>&1 | Out-Null
$d = Join-Path $TestRoot "t11-proj"
New-Item -ItemType Directory -Force -Path $d | Out-Null
    $env:PROMPTKIT_NO_PREFLIGHT = "1"
    try {
        & pwsh -NoProfile -File (Join-Path $fixtureKit "init.ps1") --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
        $t11Rc = $LASTEXITCODE
    } finally {
        Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue
    }
$t11Agents = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "`r`n", "`n"
if ($t11Rc -eq 0 -and $t11Agents -match "(?m)^Engine: [A-Za-z0-9._+-]+ \(([0-9a-f]{7,}|unknown)\) — stamped at install time" -and $t11Agents -notmatch '\$ENGINE_VERSION|\$ENGINE_SHA') {
    Ok "adversarial git tag cannot abort or corrupt the install"
} else {
    NotOk "adversarial git tag handling ($((($t11Agents -split "`n") | Where-Object { $_ -match '^Engine: ' }) -join ''))"
}

# 12. docs/STATE.md is mutated in place by the stamp pass, so it must be part of the rollback
# transaction. Sabotage a later scaffold step and assert both files are restored.
$d = NewDir "t12-rollback"
New-Item -ItemType Directory -Force -Path (Join-Path $d "docs") | Out-Null
Set-Content -LiteralPath (Join-Path $d "docs\STATE.md") -Value "- **Engine Version**: vOLD @ deadbee"
Set-Content -LiteralPath (Join-Path $d "PROMPTKIT.md") -Value "profile: lite"
Set-Content -LiteralPath (Join-Path $d ".github") -Value ""
& pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
$rbState = Get-Content (Join-Path $d "docs\STATE.md") -Raw
$rbProfile = Get-Content (Join-Path $d "PROMPTKIT.md") -Raw
if ($rbState -match "vOLD @ deadbee" -and $rbProfile -match "profile: lite") {
    Ok "rollback restores a pre-existing docs/STATE.md after a later failure"
} else {
    NotOk "rollback left docs/STATE.md mutated ($(($rbState -split "`r?`n" | Where-Object { $_ -match 'Engine Version' }) -join ''))"
}

# 13. A STATE.md that predates the engine stamp has no row to replace, so one must be inserted
# without disturbing the surrounding user content.
$d = NewDir "t13-legacy-state"
New-Item -ItemType Directory -Force -Path (Join-Path $d "docs") | Out-Null
$legacyState = "# Project State`n`n## 1. Executive Summary & Current Position`n- **Project Name**: Legacy`n- **Last Updated**: 2026-01-01`n`n---`n`n## 2. Milestone`n"
Set-Content -LiteralPath (Join-Path $d "docs\STATE.md") -Value $legacyState
& pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
$legacyAfter = (Get-Content (Join-Path $d "docs\STATE.md") -Raw) -replace "`r`n", "`n"
if (([regex]::Matches($legacyAfter, "(?m)^- \*\*Engine Version\*\*:")).Count -eq 1 -and $legacyAfter -match "\*\*Project Name\*\*: Legacy" -and $legacyAfter -match "Last Updated\*\*: 2026-01-01" -and $legacyAfter -match "(?m)^## 2\. Milestone$") {
    Ok "legacy STATE.md gains the engine stamp row without losing user content"
} else {
    NotOk "legacy STATE.md stamp insertion (rows=$(([regex]::Matches($legacyAfter, 'Engine Version')).Count))"
}

# 14. Normalization asymmetry guard: $KIT_DIR_REL is substituted on the template side only.
# Normalizing it on the installed side too would rewrite a leaked placeholder into
# .promptkit and make a broken installer compare clean, so this pins that rejection.
$d = NewDir "t14-kit-dir-leak"
Set-Content -LiteralPath (Join-Path $d "AGENTS.md") -Value ((Get-Content (Join-Path $RepoRoot "templates\agent-directive-template.md") -Raw) -replace '\$KIT_DIR_REL', '$KIT_DIR_REL') -NoNewline
if (ManagedBlockMatchesTemplate (Join-Path $d "AGENTS.md") (Join-Path $RepoRoot "templates\agent-directive-template.md")) {
    NotOk "harness accepts a leaked `$KIT_DIR_REL placeholder (normalizer masking regression)"
} else {
    Ok "harness rejects a leaked `$KIT_DIR_REL placeholder"
}

# 15. Courier release version is retained for a tarball install, with no fabricated SHA.
$t15 = NewDir "courier-engine-identity"
$t15Kit = Join-Path $t15 "kit"
$t15Project = Join-Path $t15 "project"
New-Item -ItemType Directory -Path $t15Kit, $t15Project -Force | Out-Null
Get-ChildItem -LiteralPath $RepoRoot -Force | Where-Object { $_.Name -notin @(".git", ".codegraph") } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $t15Kit -Recurse -Force }
$t15Output = & pwsh -NoProfile -File (Join-Path $t15Kit "init.ps1") --balanced --engine-version=v9.8.7 --tracking=local --host=agents $t15Project 2>&1
$t15Agents = Get-Content -Raw (Join-Path $t15Project "AGENTS.md") -ErrorAction SilentlyContinue
$t15State = Get-Content -Raw (Join-Path $t15Project "docs/STATE.md") -ErrorAction SilentlyContinue
if ($LASTEXITCODE -eq 0 -and $t15Agents -match '(?m)^Engine: v9\.8\.7 \(unknown\) — stamped at install time' -and $t15State -match '(?m)^- \*\*Engine Version\*\*: v9\.8\.7 @ unknown$') {
    Ok "courier release version is stamped while SHA remains unknown"
} else {
    NotOk "courier identity stamp (agent=$($t15Agents -split "`r?`n" | Where-Object { $_ -match '^Engine:' }), state=$($t15State -split "`r?`n" | Where-Object { $_ -match 'Engine Version' }))"
}
git -C $t15Kit init -q
git -C $t15Kit add -A
git -C $t15Kit -c user.email=fixture@example.invalid -c user.name=fixture commit -qm "fixture"
git -C $t15Kit tag v1.2.3
$t15GitProject = NewDir "courier-git-identity"
$t15GitOutput = & pwsh -NoProfile -File (Join-Path $t15Kit "init.ps1") --balanced --engine-version=v9.8.7 --tracking=local --host=agents $t15GitProject 2>&1
$t15GitAgents = Get-Content -Raw (Join-Path $t15GitProject "AGENTS.md") -ErrorAction SilentlyContinue
if ($LASTEXITCODE -eq 0 -and $t15GitAgents -match '(?m)^Engine: v1\.2\.3 \([0-9a-f]{7,}\) — stamped at install time') {
    Ok "Git-derived engine identity overrides courier version hint"
} else {
    NotOk "Git identity precedence (agent=$($t15GitAgents -split "`r?`n" | Where-Object { $_ -match '^Engine:' }))"
}

# 16. Fresh install with the engine external (#643): the profile must record when the
# profile was written, not an "Installed" date, and the target starts without an engine.
$d = NewDir "t16-profile-written"
if (Test-Path (Join-Path $d ".promptkit")) {
    NotOk "fresh-install target unexpectedly contains an in-repo engine (.promptkit)"
} else {
    $env:PROMPTKIT_NO_PREFLIGHT = "1"
    try {
        & pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
        $t16Rc = $LASTEXITCODE
    } finally {
        Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue
    }
    $t16Doc = [string](Get-Content (Join-Path $d "PROMPTKIT.md") -ErrorAction SilentlyContinue -Raw) -replace "`r`n", "`n"
    $t16Written = ([regex]::Matches($t16Doc, "(?m)^- \*\*Profile written\*\*: \d{4}-\d{2}-\d{2}$")).Count
    $t16Legacy = ([regex]::Matches($t16Doc, "Installed\*{0,2}:[ \t]*\d{4}-\d{2}-\d{2}")).Count
    if ($t16Rc -eq 0 -and $t16Written -eq 1 -and $t16Legacy -eq 0) {
        Ok "fresh install records Profile written and no Installed date"
    } else {
        NotOk "fresh install header (rc=$t16Rc, Profile written=$t16Written, Installed=$t16Legacy, header=$(($t16Doc -split "`n" | Where-Object { $_ -match 'Profile written|Installed' }) -join ' | '))"
    }
}

# 17. Legacy labeled profile on rerun (#643): an existing Installed date line is migrated to
# Profile written, and the profile section survives.
$d = NewDir "t17-profile-migration"
$seed = "profile: balanced`n`n## 0. PromptKit OS Profile`n- **Profile**: balanced`n- **Installed**: 2026-10-21`n- **Engine**: ``external```n"
Set-Content -LiteralPath (Join-Path $d "PROMPTKIT.md") -Value $seed -NoNewline
$env:PROMPTKIT_NO_PREFLIGHT = "1"
try {
    & pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
    $t17Rc = $LASTEXITCODE
} finally {
    Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue
}
$t17Doc = [string](Get-Content (Join-Path $d "PROMPTKIT.md") -ErrorAction SilentlyContinue -Raw) -replace "`r`n", "`n"
$t17Written = ([regex]::Matches($t17Doc, "(?m)^- \*\*Profile written\*\*: \d{4}-\d{2}-\d{2}$")).Count
$t17Legacy = ([regex]::Matches($t17Doc, "Installed\*{0,2}:[ \t]*\d{4}-\d{2}-\d{2}")).Count
if ($t17Rc -eq 0 -and $t17Written -eq 1 -and $t17Legacy -eq 0 -and $t17Doc -match "(?m)^## 0\. PromptKit OS Profile$") {
    Ok "legacy Installed date migrates to Profile written on rerun"
} else {
    NotOk "legacy profile migration (rc=$t17Rc, Profile written=$t17Written, Installed=$t17Legacy, header=$(($t17Doc -split "`n" | Where-Object { $_ -match 'Profile written|Installed' }) -join ' | '))"
}

# 18. Append path (#643): no profile: machine line and a legacy date line; one Profile written
# date is added and the user's overview survives.
$d = NewDir "t18-profile-append"
$seed = "# Project Profile`n`n## 1. Overview`n- **Project Name**: Legacy`n`n## 0. PromptKit OS Profile`n- **Installed**: 2026-10-21`n"
Set-Content -LiteralPath (Join-Path $d "PROMPTKIT.md") -Value $seed -NoNewline
$env:PROMPTKIT_NO_PREFLIGHT = "1"
try {
    & pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
    $t18Rc = $LASTEXITCODE
} finally {
    Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue
}
$t18Doc = [string](Get-Content (Join-Path $d "PROMPTKIT.md") -ErrorAction SilentlyContinue -Raw) -replace "`r`n", "`n"
$t18Written = ([regex]::Matches($t18Doc, "(?m)^- \*\*Profile written\*\*: \d{4}-\d{2}-\d{2}$")).Count
$t18Legacy = ([regex]::Matches($t18Doc, "Installed\*{0,2}:[ \t]*\d{4}-\d{2}-\d{2}")).Count
if ($t18Rc -eq 0 -and $t18Written -eq 1 -and $t18Legacy -eq 0 -and $t18Doc -match "(?m)^## 1\. Overview$" -and $t18Doc -match "(?m)^- \*\*Project Name\*\*: Legacy$") {
    Ok "append path adds one Profile written date without dropping user overview"
} else {
    NotOk "append path header (rc=$t18Rc, Profile written=$t18Written, Installed=$t18Legacy, header=$(($t18Doc -split "`n" | Where-Object { $_ -match 'Profile written|Installed' }) -join ' | '))"
}

# 19. Conflicting date labels (#643): the existing Profile written value wins, every legacy
# Installed line is stripped, and a second rerun keeps the same single resolved value.
$d = NewDir "t19-profile-conflict"
$seed = @(
    'profile: balanced'
    ''
    '## 0. PromptKit OS Profile'
    '- **Profile**: balanced'
    '- **Installed**: 2026-10-21'
    '- **Profile written**: 2026-10-20'
    '- **Engine**: `external`'
    ''
    '## 1. Overview'
    '- **Project Name**: Legacy'
) -join "`n"
Set-Content -LiteralPath (Join-Path $d "PROMPTKIT.md") -Value ($seed + "`n") -NoNewline
$env:PROMPTKIT_NO_PREFLIGHT = "1"
try {
    & pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
    $t19Rc = $LASTEXITCODE
    $t19First = ([string](Get-Content (Join-Path $d "PROMPTKIT.md") -ErrorAction SilentlyContinue -Raw)) -replace "`r`n", "`n"
    & pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
    $t19Rc2 = $LASTEXITCODE
} finally {
    Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue
}
$t19Doc = ([string](Get-Content (Join-Path $d "PROMPTKIT.md") -ErrorAction SilentlyContinue -Raw)) -replace "`r`n", "`n"
$t19FirstWritten = ([regex]::Matches($t19First, "(?m)^- \*\*Profile written\*\*: \d{4}-\d{2}-\d{2}$")).Count
$t19FirstLegacy = ([regex]::Matches($t19First, "Installed\*{0,2}:[ \t]*\d{4}-\d{2}-\d{2}")).Count
$t19FirstValue = if ($t19First -match "(?m)^- \*\*Profile written\*\*: (\d{4}-\d{2}-\d{2})$") { $Matches[1] } else { "" }
$t19Written = ([regex]::Matches($t19Doc, "(?m)^- \*\*Profile written\*\*: \d{4}-\d{2}-\d{2}$")).Count
$t19Legacy = ([regex]::Matches($t19Doc, "Installed\*{0,2}:[ \t]*\d{4}-\d{2}-\d{2}")).Count
$t19Value = if ($t19Doc -match "(?m)^- \*\*Profile written\*\*: (\d{4}-\d{2}-\d{2})$") { $Matches[1] } else { "" }
if ($t19Rc -eq 0 -and $t19Rc2 -eq 0 -and
    $t19FirstWritten -eq 1 -and $t19FirstLegacy -eq 0 -and $t19FirstValue -eq "2026-10-20" -and
    $t19Written -eq 1 -and $t19Legacy -eq 0 -and $t19Value -eq "2026-10-20") {
    Ok "conflicting date labels resolve to one retained Profile written value and rerun keeps it"
} else {
    NotOk "conflicting date labels (rc=$t19Rc/$t19Rc2, run1=$t19FirstWritten/$t19FirstLegacy/$t19FirstValue, run2=$t19Written/$t19Legacy/$t19Value, header=$(($t19Doc -split "`n" | Where-Object { $_ -match 'Profile written|Installed' }) -join ' | '))"
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "Passed: $script:Pass | Failed: $script:Fail"

Remove-Item -Recurse -Force $TestRoot -ErrorAction SilentlyContinue

if ($script:Fail -gt 0) {
    Write-Host "❌ init.ps1 profile matrix FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "✅ init.ps1 profile matrix passed" -ForegroundColor Green
exit 0
