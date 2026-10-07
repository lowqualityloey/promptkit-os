<#
.SYNOPSIS
    PromptKit OS 1-Click Setup Script for Windows (PowerShell)
    Supports profiles: --lite, --balanced (default), --turbo --experimental
.DESCRIPTION
    Initializes PromptKit OS in your project:
    - Scaffolds project documentation directories (docs/adrs, docs/specs, docs/rca, docs/spikes, docs/design)
    - Creates PROMPTKIT.md project profile if missing, injects profile: lite|balanced|turbo
    - Injects or updates PromptKit OS directives in AGENTS.md, CLAUDE.md, GEMINI.md, .cursorrules, .cursor/rules/*.mdc, .windsurfrules, .github/copilot-instructions.md, .clinerules, .traerules, .opencode/rules.md, or CONVENTIONS.md (Aider)
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [Alias("ProjectRoot")]
    [string]$TargetDir = "",
    [ValidateSet("lite","balanced","turbo")]
    [string]$Profile = "balanced",
    [switch]$Lite,
    [switch]$Balanced,
    [switch]$Turbo,
    [switch]$Experimental,
    [ValidateSet("local","github","jira","linear")]
    [string]$Tracking = "local",
    [string]$Hosts = "",
    [string]$AddHost = "",
    [switch]$Reconfigure,
    [string[]]$Target = @(),
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Remaining = @()
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "scripts/terminal-picker.ps1")
$UsePicker = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected -and $env:TERM -ne "dumb" -and [string]::IsNullOrEmpty($env:PROMPTKIT_NO_INTERACTIVE)
$ProfileInteractive = $false
$TrackingInteractive = $false
$HostInteractive = $false
$CourierEngineVersion = ""

function Show-SetupBanner {
    if (-not $UsePicker) { return }
    $script:PkPickerBannerPath = Join-Path $PSScriptRoot "templates/terminal-banner.txt"
    $script:PkPickerBannerFull = ([Console]::WindowWidth -ge 120)
    $script:PkPickerBannerActive = $true
}

# Host map + probes (defined up front: param handling below calls Get-HostFile).
function Get-HostFile($Name) {
    switch ($Name) {
        "agents" { return "AGENTS.md" }
        "claude" { return "CLAUDE.md" }
        "opencode" { return ".opencode/rules.md" }
        "cursor" { return ".cursorrules" }
        "gemini" { return "GEMINI.md" }
        "windsurf" { return ".windsurfrules" }
        "copilot" { return ".github/copilot-instructions.md" }
        "cline" { return ".clinerules" }
        "trae" { return ".traerules" }
        "aider" { return "CONVENTIONS.md" }
        default { return "" }
    }
}
$KnownHostsList = @("claude","opencode","cursor","gemini","windsurf","copilot","cline","trae","aider")
$HostPickerLabels = @("Claude Code", "OpenCode", "Cursor", "Gemini CLI", "Windsurf", "GitHub Copilot", "Cline", "Trae", "Aider")

function Stop-PromptKitSetup {
    Write-Host "`nSetup cancelled before any project files were changed."
    exit 130
}

function Select-PromptKitProfile {
    $attempts = 0
    if ($UsePicker) {
        $defaultIndex = switch ($Profile) { "lite" { 1 } "turbo" { 2 } default { 0 } }
        $choice = Invoke-PkSinglePicker -Title "Choose your profile" -Subtitle "Balanced is recommended. Turbo needs a second confirmation." -Items @(
            "Balanced — Recommended default; full workflow set",
            "Lite — Six core workflows for a lighter setup",
            "Turbo — Experimental parallel workflows; higher token cost"
        ) -DefaultIndex $defaultIndex
        if ($choice -lt 0) { Stop-PromptKitSetup }
        switch ($choice) {
            0 { $script:Profile = "balanced" }
            1 { $script:Profile = "lite" }
            2 {
                Write-Host "`nTurbo is experimental and can use up to ~2x measured token cost."
                $confirm = Read-Host "Acknowledge this and enable Turbo? [y/N]"
                if ($confirm -match "^[Yy]$") { $script:Profile = "turbo"; $script:Experimental = $true }
                else { $script:Profile = "balanced" }
            }
        }
    } else {
        while ($true) {
            Write-Host "`n◉ Profile`n  1) Balanced — Recommended default; full workflow set`n  2) Lite — Six core workflows`n  3) Turbo — Experimental; higher token cost"
            $choice = Read-Host "Choose 1-3 (Enter for Balanced, q to cancel)"
            if ($choice -match "^[Qq]$") { Stop-PromptKitSetup }
            switch ($choice) {
                { $_ -eq "" -or $_ -eq "1" } { $script:Profile = "balanced"; break }
                "2" { $script:Profile = "lite"; break }
                "3" {
                    $confirm = Read-Host "Turbo is experimental and costs more. Continue? [y/N]"
                    if ($confirm -match "^[Yy]$") { $script:Profile = "turbo"; $script:Experimental = $true }
                    else { $script:Profile = "balanced" }
                    break
                }
                default {
                    $attempts++
                    Write-Host "Please enter 1, 2, or 3." -ForegroundColor Yellow
                    if ($attempts -ge 3) { Stop-PromptKitSetup }
                    continue
                }
            }
            break
        }
    }
    $script:ProfileSet = $true
    $script:ProfileInteractive = $true
}

function Select-PromptKitTracking {
    $attempts = 0
    if ($UsePicker) {
        $defaultIndex = switch ($Tracking) { "github" { 1 } "jira" { 2 } "linear" { 3 } default { 0 } }
        $choice = Invoke-PkSinglePicker -Title "Choose task tracking" -Subtitle "Local works offline. GitHub can mirror local task records." -Items @(
            "Local Markdown — Recommended; stored in docs/tasks/",
            "GitHub Issues — Requires GitHub setup",
            "Jira — Manual import; no automatic push",
            "Linear — Manual import; no automatic push"
        ) -DefaultIndex $defaultIndex
        if ($choice -lt 0) { Stop-PromptKitSetup }
        switch ($choice) {
            0 { $script:Tracking = "local" }
            1 { $script:Tracking = "github" }
            2 { $script:Tracking = "jira" }
            3 { $script:Tracking = "linear" }
        }
        if ($Tracking -eq "local") {
            $defaults = if ($TrackingProjection -eq "github") { "github" } else { "" }
            $projection = Invoke-PkMultiPicker -Title "Local task projection" -Subtitle "Optional checkbox. Space toggles it; Enter keeps the setting." -Ids @("github") -Labels @("Also project local tasks to GitHub Issues") -Defaults $defaults
            if ($null -eq $projection) { Stop-PromptKitSetup }
            $script:TrackingProjection = $projection
        } else { $script:TrackingProjection = "" }
    } else {
        while ($true) {
            Write-Host "`n▣ Task tracking`n  1) Local Markdown — Recommended; docs/tasks/`n  2) GitHub Issues`n  3) Jira — manual import`n  4) Linear — manual import`n  1,2) Local Markdown + GitHub projection"
            $choice = Read-Host "Choose 1-4 or 1,2 (Enter for Local, q to cancel)"
            if ($choice -match "^[Qq]$") { Stop-PromptKitSetup }
            switch ($choice) {
                { $_ -eq "" -or $_ -eq "1" } { $script:Tracking = "local"; $script:TrackingProjection = ""; break }
                { $_ -eq "1,2" -or $_ -eq "2,1" } { $script:Tracking = "local"; $script:TrackingProjection = "github"; break }
                "2" { $script:Tracking = "github"; $script:TrackingProjection = ""; break }
                "3" { $script:Tracking = "jira"; $script:TrackingProjection = ""; break }
                "4" { $script:Tracking = "linear"; $script:TrackingProjection = ""; break }
                default {
                    $attempts++
                    Write-Host "Please enter one of the listed choices exactly." -ForegroundColor Yellow
                    if ($attempts -ge 3) { Stop-PromptKitSetup }
                    continue
                }
            }
            break
        }
    }
    $script:TrackingSet = $true
    $script:TrackingInteractive = $true
}

function Select-PromptKitHosts {
    $attempts = 0
    if ($UsePicker) {
        if ($HostInteractive) {
            $defaults = if ($Hosts -eq "agents") { "" } else { $Hosts }
        } else {
            $defaults = if ($DetectedHosts.Count -gt 0) { $DetectedHosts -join "," } else { "claude" }
        }
        $picked = Invoke-PkMultiPicker -Title "Choose AI hosts" -Subtitle "Space toggles host-specific files. Select none for universal AGENTS.md only." -Ids $KnownHostsList -Labels $HostPickerLabels -Defaults $defaults
        if ($null -eq $picked) { Stop-PromptKitSetup }
        $script:Hosts = if ([string]::IsNullOrWhiteSpace($picked)) { "agents" } else { $picked }
    } else {
        while ($true) {
            Write-Host "`n◆ AI hosts (comma-separated numbers; 0 = universal AGENTS.md only)"
            for ($i = 0; $i -lt $KnownHostsList.Count; $i++) {
                $marker = if ($DetectedHosts -contains $KnownHostsList[$i]) { " [detected]" } else { "" }
                Write-Host ("  {0}) {1}{2}" -f ($i + 1), $HostPickerLabels[$i], $marker)
            }
            Write-Host "  Enter keeps detected hosts; if none are detected, Claude Code is the default."
            $choice = Read-Host "Choose hosts (q to cancel)"
            if ($choice -match "^[Qq]$") { Stop-PromptKitSetup }
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $script:Hosts = if ($DetectedHosts.Count -gt 0) { $DetectedHosts -join "," } else { "claude" }
                break
            }
            if ($choice -eq "0") { $script:Hosts = "agents"; break }
            $picked = [System.Collections.Generic.List[string]]::new()
            $valid = $true
            foreach ($token in ($choice -split ',')) {
                $number = 0
                if (-not [int]::TryParse($token.Trim(), [ref]$number) -or $number -lt 1 -or $number -gt $KnownHostsList.Count) { $valid = $false; break }
                $id = $KnownHostsList[$number - 1]
                if (-not $picked.Contains($id)) { $picked.Add($id) }
            }
            if ($valid) { $script:Hosts = $picked -join ","; break }
            $attempts++
            Write-Host "Invalid choice. Enter only host numbers from 1 to $($KnownHostsList.Count)." -ForegroundColor Yellow
            if ($attempts -ge 3) { Stop-PromptKitSetup }
        }
    }
    $script:HostSet = $true
    $script:HostInteractive = $true
}

function Review-PromptKitSetup {
    $items = [System.Collections.Generic.List[string]]::new()
    $actions = [System.Collections.Generic.List[string]]::new()
    if ($ProfileInteractive) { $items.Add("Edit profile"); $actions.Add("profile") }
    if ($TrackingInteractive) { $items.Add("Edit task tracking"); $actions.Add("tracking") }
    if ($HostInteractive) { $items.Add("Edit AI hosts"); $actions.Add("hosts") }
    $items.Add("Install with these settings"); $actions.Add("install")
    $items.Add("Cancel setup"); $actions.Add("cancel")
    while ($true) {
        $hostSummary = if ($Hosts -eq "agents") { "Universal AGENTS.md only" } else { $Hosts -replace ',', ' · ' }
        $trackerSummary = if ($TrackingProjection) { "$Tracking + GitHub projection" } else { $Tracking }
        $subtitle = "Profile: $Profile`nTask tracking: $trackerSummary`nAI hosts: $hostSummary`n`nChoose a setting to edit, install, or cancel."
        if ($UsePicker) {
            $choice = Invoke-PkSinglePicker -Title "Review setup" -Subtitle $subtitle -Items $items.ToArray() -DefaultIndex ($items.Count - 2)
            if ($choice -lt 0) { Stop-PromptKitSetup }
            $action = $actions[$choice]
        } else {
            Write-Host "`n◇ Review setup`n  Profile: $Profile`n  Task tracking: $trackerSummary`n  AI hosts: $hostSummary"
            for ($i = 0; $i -lt $items.Count; $i++) { Write-Host ("  {0}) {1}" -f ($i + 1), $items[$i]) }
            $choice = Read-Host "Choose an option, or q to cancel"
            if ($choice -match "^[Qq]$") { Stop-PromptKitSetup }
            $number = 0
            if (-not [int]::TryParse($choice, [ref]$number) -or $number -lt 1 -or $number -gt $items.Count) {
                Write-Host "Please choose one of the listed options." -ForegroundColor Yellow
                continue
            }
            $action = $actions[$number - 1]
        }
        switch ($action) {
            "profile" { $script:ProfileSet = $false; Select-PromptKitProfile }
            "tracking" { $script:TrackingSet = $false; Select-PromptKitTracking }
            "hosts" { $script:HostSet = $false; Select-PromptKitHosts }
            "install" { return }
            "cancel" { Stop-PromptKitSetup }
        }
    }
}

# Canonical path resolution and containment verification (F04 - P2, R3 - P2, R4 - P2)
function Resolve-CanonicalPath {
    param(
        [string]$Path,
        [int]$HopCount = 0
    )
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    if ($HopCount -ge 25) { return [System.IO.Path]::GetFullPath($Path) }

    $p = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetPathRoot($p)
    $remainder = $p.Substring($root.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $parts = $remainder.Split([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    $current = $root
    $i = 0
    while ($i -lt $parts.Length) {
        $part = $parts[$i]
        $i++
        if ([string]::IsNullOrEmpty($part)) { continue }
        $current = [System.IO.Path]::Combine($current, $part)
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if ($null -ne $item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                $target = $null
                if ($item.PSObject.Properties['Target'] -and $item.Target) {
                    $target = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
                } elseif ($item.PSObject.Properties['LinkTarget'] -and $item.LinkTarget) {
                    $target = $item.LinkTarget
                }
                if (-not [string]::IsNullOrEmpty($target)) {
                    if (-not [System.IO.Path]::IsPathRooted($target)) {
                        $parentDir = [System.IO.Path]::GetDirectoryName($item.FullName)
                        $target = [System.IO.Path]::Combine($parentDir, $target)
                    }
                    if ($i -lt $parts.Length) {
                        $remParts = $parts[$i..($parts.Length - 1)]
                        $target = [System.IO.Path]::Combine(@($target) + @($remParts))
                    }
                    return Resolve-CanonicalPath -Path $target -HopCount ($HopCount + 1)
                }
            }
        }
    }
    return [System.IO.Path]::GetFullPath($current)
}

function Test-PathContained {
    param(
        [string]$ProjectRootPath,
        [string]$TargetPath
    )
    $canonicalRoot = Resolve-CanonicalPath $ProjectRootPath
    $canonicalTarget = Resolve-CanonicalPath $TargetPath
    $canonicalRoot = $canonicalRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    } else {
        [System.StringComparison]::Ordinal
    }

    if ($canonicalTarget.Equals($canonicalRoot, $comparison)) {
        return $true
    }
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $prefix = $canonicalRoot + $sep
    if ($canonicalTarget.StartsWith($prefix, $comparison)) {
        return $true
    }
    return $false
}

if ($Help) {
    Write-Host "`nPromptKit OS init.ps1 — 1-Click Setup`n" -ForegroundColor Cyan
    Write-Host "Usage: .\init.ps1 [options] [project-root]`n"
    Write-Host "Options:"
    Write-Host "  --lite              Lite profile: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) <1,500 tok, 80% value"
    Write-Host "  --balanced          Balanced profile: the full workflow set, Level 0-3 adaptive ceremony (default)"
    Write-Host "  --turbo             Turbo profile: Balanced + parallel subagent waves, up to ~2x measured token cost"
    Write-Host "  --experimental      Required for --turbo, acknowledges experimental cost and warnings"
    Write-Host "  --tracking=local|github|jira|linear  Task tracker (default: local; jira/linear = manual import)"
    Write-Host "  --host=a,b,c        AI hosts to configure (comma-separated from: claude,opencode,cursor,gemini,windsurf,copilot,cline,trae,aider)"
    Write-Host "  --add-host=name     Add one host to an existing install (agents = universal AGENTS.md)"
    Write-Host "  --reconfigure       Force interactive host re-selection on existing installations"
    Write-Host "  --target=rel/path   Custom directive file (project-relative, repeatable; e.g. docs/AI.md)"
    Write-Host "  -Help               Show this help`n"
    Write-Host "Interactive (TTY): Arrow keys move, Enter selects, Space toggles checkboxes, q cancels."
    Write-Host "  A final review lets you edit choices before installation. PROMPTKIT_NO_INTERACTIVE=1 skips the wizard.`n"
    Write-Host "Profiles stored in PROMPTKIT.md as 'profile: lite|balanced|turbo'"
    Write-Host "Examples:"
    Write-Host "  .\init.ps1 --lite"
    Write-Host "  .\init.ps1 --balanced C:\path\to\project"
    Write-Host "  .\init.ps1 --turbo --experimental"
    Write-Host "  .\init.ps1 (interactive picker when TTY)`n"
    exit 0
}

# Handle switch aliases (allow --lite style via PS args parsing quirks)
$ProfileSet = $false
$TrackingSet = $false
$HostSet = $false
if ($Hosts -ne "") { $HostSet = $true }
if ($AddHost -ne "") {
    if ((Get-HostFile $AddHost) -eq "") {
        Write-Host "[!] Unknown host: $AddHost" -ForegroundColor Red
        exit 1
    }
    $Hosts = "agents,$AddHost"
    $HostSet = $true
}
$ExtraTargets = @()
if ($Target) {
    foreach ($t in $Target) {
        if (-not [string]::IsNullOrWhiteSpace($t)) {
            $ExtraTargets += $t
        }
    }
}
if ($PSBoundParameters.ContainsKey("Profile")) { $ProfileSet = $true }
if ($PSBoundParameters.ContainsKey("Tracking")) { $TrackingSet = $true }
if ($PSBoundParameters.ContainsKey("Hosts")) { $HostSet = $true }
if ($Lite) { $Profile = "lite"; $ProfileSet = $true }
if ($Balanced) { $Profile = "balanced"; $ProfileSet = $true }
if ($Turbo) { $Profile = "turbo"; $ProfileSet = $true }

# Also check $args for --lite style (when called via pwsh -File with --lite).
# Tokens PowerShell cannot bind (notably --name=value with a double dash) land
# in $Remaining instead of throwing, so merge both sources before parsing.
$AllArgs = @($args) + @($Remaining)
foreach ($a in $AllArgs) {
    switch ($a) {
        "--lite" { $Profile = "lite"; $ProfileSet = $true }
        "--balanced" { $Profile = "balanced"; $ProfileSet = $true }
        "--turbo" { $Profile = "turbo"; $ProfileSet = $true }
        "--experimental" { $Experimental = $true }
        "--tracking=local" { $Tracking = "local"; $TrackingSet = $true }
        "--tracking=github" { $Tracking = "github"; $TrackingSet = $true }
        "--tracking=jira" { $Tracking = "jira"; $TrackingSet = $true }
        "--tracking=linear" { $Tracking = "linear"; $TrackingSet = $true }
        { $_ -like "--engine-version=*" } { $CourierEngineVersion = $_.Substring(17) }
        { $_ -like "--host=*" } { $Hosts = $_.Substring(7); $HostSet = $true }
        { $_ -like "--add-host=*" } {
            $ah = $_.Substring(11)
            if ((Get-HostFile $ah) -eq "" -and $ah -ne "agents") {
                Write-Host "[!] Unknown host: $ah" -ForegroundColor Red
                exit 1
            }
            $Hosts = "agents,$ah"
            $HostSet = $true
        }
        { $_ -like "--target=*" } {
            $tp = $_.Substring(9)
            if ($tp.StartsWith("/") -or $tp -match '\.\.' -or [string]::IsNullOrWhiteSpace($tp)) {
                Write-Host "[!] --target must be a project-relative path without '..': $tp" -ForegroundColor Red
                exit 1
            }
            $ExtraTargets += $tp
        }
        "--reconfigure" { $Reconfigure = $true }
        "--help" { 
            Write-Host "`nPromptKit OS init.ps1 — 1-Click Setup`n" -ForegroundColor Cyan
            Write-Host "Usage: .\init.ps1 [options] [project-root]`n"
            Write-Host 'PROMPTKIT_NO_PREFLIGHT=1 skips advisory local security inspection independently of PROMPTKIT_NO_INTERACTIVE.'
            exit 0
        }
        default {
            if ($a -notlike "--*" -and $TargetDir -eq "") {
                $TargetDir = $a
            }
        }
    }
}

# Keep installed settings on update re-runs (flags always win over installed values)
$TrackingProjection = ""
$probeRoot = if ($TargetDir -ne "") { $TargetDir } elseif ((Split-Path -Leaf (Split-Path -Parent $MyInvocation.MyCommand.Path)) -in @(".promptkit", "promptkit")) { Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".." } else { (Get-Location).Path }
$probeProfile = Join-Path $probeRoot "PROMPTKIT.md"
if (-not $ProfileSet -and (Test-Path $probeProfile)) {
    $ip = Select-String -Path $probeProfile -Pattern '^profile:\s*(\S+)' | Select-Object -Last 1
    if ($null -ne $ip -and $ip.Matches[0].Groups[1].Value -in @('lite', 'balanced')) {
        $Profile = $ip.Matches[0].Groups[1].Value; $ProfileSet = $true
        Write-Host "  Keeping installed profile: $Profile (pass a flag to change)" -ForegroundColor DarkGray
    } elseif ($null -ne $ip -and $ip.Matches[0].Groups[1].Value -eq 'turbo') {
        $Profile = "turbo"; $Experimental = $true; $ProfileSet = $true
        Write-Host "  Keeping installed profile: turbo (previously acknowledged --experimental)" -ForegroundColor DarkGray
    }
}
if (-not $TrackingSet -and (Test-Path $probeProfile)) {
    $it = Select-String -Path $probeProfile -Pattern '^tracking:\s*(\S+)' | Select-Object -Last 1
    if ($null -ne $it -and $it.Matches[0].Groups[1].Value -in @('local', 'github', 'jira', 'linear')) {
        $Tracking = $it.Matches[0].Groups[1].Value; $TrackingSet = $true
        if ($Tracking -eq "local") {
            $ipr = Select-String -Path $probeProfile -Pattern '^projection:\s*(\S+)' | Select-Object -Last 1
            if ($null -ne $ipr -and $ipr.Matches[0].Groups[1].Value -eq 'github') { $TrackingProjection = "github" }
        }
        $projNote = if ($TrackingProjection -ne "") { " + $TrackingProjection projection" } else { "" }
        Write-Host "  Keeping installed tracker: $Tracking$projNote (pass --tracking= to change)" -ForegroundColor DarkGray
    }
}
if (-not $HostSet -and -not $Reconfigure -and (Test-Path $probeProfile)) {
    $installedHosts = @()
    foreach ($h in $KnownHostsList) {
        $hf = Get-HostFile $h
        if ($hf -ne "" -and (Test-Path (Join-Path $probeRoot $hf))) {
            $installedHosts += $h
        } elseif ($h -eq "cline" -and ((Test-Path (Join-Path $probeRoot ".clinerules")) -or (Test-Path (Join-Path $probeRoot ".clinerules/promptkit.md")))) {
            $installedHosts += $h
        } elseif ($h -eq "cursor" -and ((Test-Path (Join-Path $probeRoot ".cursorrules")) -or (Test-Path (Join-Path $probeRoot ".cursor/rules/promptkit.mdc")))) {
            $installedHosts += $h
        }
    }
    if ($installedHosts.Count -eq 0 -and (Test-Path (Join-Path $probeRoot "AGENTS.md"))) {
        $installedHosts += "agents"
    }
    if ($installedHosts.Count -gt 0) {
        $Hosts = ($installedHosts | Select-Object -Unique) -join ','
        $HostSet = $true
        Write-Host "  Keeping installed hosts: $Hosts (pass -Hosts or -Reconfigure to change)" -ForegroundColor DarkGray
    }
}

# Show the banner and collect profile/tracker choices only for an interactive first-time setup.
if ((-not $ProfileSet -and -not $Experimental) -or -not $TrackingSet) { Show-SetupBanner }
if (-not $ProfileSet -and -not $Experimental -and $UsePicker) { Select-PromptKitProfile }
if (-not $TrackingSet -and $UsePicker) { Select-PromptKitTracking }

if ($Profile -eq "turbo" -and -not $Experimental) {
    Write-Host "`n[!] --turbo requires --experimental flag" -ForegroundColor Red
    Write-Host "   Turbo uses parallel subagent waves (up to ~2x measured token cost) and is experimental." -ForegroundColor DarkGray
    Write-Host "   It still requires human approval for Level 3 (releases/tags/deploys)." -ForegroundColor DarkGray
    Write-Host "   Run: .\init.ps1 --turbo --experimental [project-root]`n" -ForegroundColor DarkGray
    exit 1
}

# Determine PromptKit OS directory and Host Project Root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($TargetDir -ne "") {
    $ProjectRoot = Resolve-Path $TargetDir
} elseif ((Split-Path -Leaf $ScriptDir) -in @(".promptkit", "promptkit")) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..")
} else {
    $ProjectRoot = Resolve-Path "."
}

$ProjectRootPath = if ($ProjectRoot.Path) { $ProjectRoot.Path } else { $ProjectRoot.ToString() }

$DocDirs = @(
    "docs/tasks",
    "docs/specs",
    "docs/adrs",
    "docs/tests"
)

$ProjectProfile = Join-Path $ProjectRoot "PROMPTKIT.md"
$TemplateProfile = Join-Path $ScriptDir "templates/project-profile-template.md"
$DesignProfile = Join-Path $ProjectRoot "DESIGN.md"
$DocsDir = Join-Path $ProjectRoot "docs"
$StateTracker = Join-Path $DocsDir "STATE.md"
$TemplateState = Join-Path $ScriptDir "templates/state-tracker-template.md"
$GitHubDir = Join-Path $ProjectRoot ".github"
$PrTemplateTarget = Join-Path $GitHubDir "pull_request_template.md"
$TemplatePr = Join-Path $ScriptDir "templates/pull-request-template.md"
$IssueTemplateDir = Join-Path $GitHubDir "ISSUE_TEMPLATE"
$TaskTemplateTarget = Join-Path $IssueTemplateDir "task.md"
$TemplateTask = Join-Path $ScriptDir "templates/github-issue-template.md"
$EngineDir = Split-Path $ScriptDir -Leaf

# Stamp the installed engine identity (#545). Must never fail the install: unresolved
# values degrade to "unknown", which pk:sync reports as its own state, not an error.
# Never add -abbrev=0 here: it discards commit distance (measured: v1.10.1 vs
# v1.10.1-12-ge78fde0), hiding exactly the drift the stamp exists to expose. -match
# excludes the repo's non-release backup/* tags, which describe would otherwise pick.
$EngineVersion = "unknown"
$EngineSha = "unknown"
try {
    if (Test-Path -LiteralPath (Join-Path $ScriptDir ".git")) {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $describeOutput = git -C $ScriptDir describe --tags --match "v[0-9]*" 2>$null
            $describeExit = $LASTEXITCODE
            $described = $describeOutput | Select-Object -First 1
            if ($describeExit -eq 0 -and -not [string]::IsNullOrWhiteSpace($described)) { $EngineVersion = "$described".Trim() }
            $shaOutput = git -C $ScriptDir rev-parse --short HEAD 2>$null
            $shaExit = $LASTEXITCODE
            $shortSha = $shaOutput | Select-Object -First 1
            if ($shaExit -eq 0 -and -not [string]::IsNullOrWhiteSpace($shortSha)) { $EngineSha = "$shortSha".Trim() }
        }
    } elseif (-not [string]::IsNullOrWhiteSpace($CourierEngineVersion)) {
        $EngineVersion = $CourierEngineVersion
    }
} catch {
    $EngineVersion = "unknown"
    $EngineSha = "unknown"
}

# `git describe` output is influenced by any tag an attacker can push to the kit repo, and
# both values are substituted into the directive below. A legal git ref may contain '$',
# which PowerShell's -replace reads as a substitution reference in the REPLACEMENT text
# ($1, $&, ${name}). Legitimate describe and short-SHA output only ever uses [A-Za-z0-9._+-],
# so anything else is rejected at the source and degrades to "unknown" like any other
# unresolved value: the stamp stays display-only and no tag can rewrite the directive.
if ($EngineVersion -notmatch '^[A-Za-z0-9._+-]+$') { $EngineVersion = "unknown" }
if ($EngineSha -notmatch '^[A-Za-z0-9._+-]+$') { $EngineSha = "unknown" }

# Escape a value for use as .NET replacement text, where '$' introduces a substitution
# reference. Doubling every '$' makes it literal.
function ConvertTo-LiteralReplacement([string]$value) {
    if ($null -eq $value) { return "" }
    return $value -replace '\$', '$$$$'
}

if (Test-Path -LiteralPath $DesignProfile) {
    Write-Host "  [✓] DESIGN.md detected (brand identity & anti-slop rules)" -ForegroundColor DarkGray
}# 2b. Host probing + selection (which AI assistants get directive files)
# Probes are best-effort suggestions only; the TTY menu (or --host=) is authoritative.
# AGENTS.md is always created fresh as the universal fallback standard.
if ($HostSet) {
    foreach ($h in ($Hosts -split ',')) {
        if ((Get-HostFile $h) -eq "") {
            Write-Host "[!] Unknown host: $h (use comma-separated from: $($KnownHostsList -join ','))" -ForegroundColor Red
            exit 1
        }
    }
}
function Test-HostDetected($Name) {
    $hf = Get-HostFile $Name
    if ($hf -ne "" -and (Test-Path (Join-Path $probeRoot $hf))) { return $true }
    if ($Name -eq "cline" -and ((Test-Path (Join-Path $probeRoot ".clinerules")) -or (Test-Path (Join-Path $probeRoot ".clinerules/promptkit.md")))) { return $true }
    if ($Name -eq "cursor" -and ((Test-Path (Join-Path $probeRoot ".cursorrules")) -or (Test-Path (Join-Path $probeRoot ".cursor/rules/promptkit.mdc")))) { return $true }
    switch ($Name) {
        "claude" { return ($null -ne (Get-Command claude -ErrorAction SilentlyContinue)) }
        "opencode" { return ($null -ne (Get-Command opencode -ErrorAction SilentlyContinue)) -or (Test-Path (Join-Path $HOME ".config/opencode")) }
        "cursor" { return ($null -ne (Get-Command cursor -ErrorAction SilentlyContinue)) -or (Test-Path (Join-Path $HOME ".cursor")) }
        "gemini" { return ($null -ne (Get-Command gemini -ErrorAction SilentlyContinue)) }
        "windsurf" { return ($null -ne (Get-Command windsurf -ErrorAction SilentlyContinue)) -or (Test-Path (Join-Path $HOME ".windsurf")) }
        "copilot" { return ($null -ne (Get-Command copilot -ErrorAction SilentlyContinue)) }
        "cline" { return (Test-Path (Join-Path $HOME ".config/cline")) -or (Test-Path (Join-Path $HOME ".cline")) }
        "trae" { return ($null -ne (Get-Command trae -ErrorAction SilentlyContinue)) }
        "aider" { return ($null -ne (Get-Command aider -ErrorAction SilentlyContinue)) }
        default { return $false }
    }
}
$DetectedHosts = @()
if (-not $HostSet) {
    foreach ($h in $KnownHostsList) {
        if (Test-HostDetected $h) { $DetectedHosts += $h }
    }
}
$IsTTY = $UsePicker
if (-not $HostSet -and -not $IsTTY) {
    # Non-interactive: a single unambiguous probe hit wins; zero or many
    # fall back to the deterministic default pair (never guess among several).
    if ($DetectedHosts.Count -eq 1) {
        $Hosts = $DetectedHosts[0]
        $HostSet = $true
    }
}
if (-not $HostSet -and $IsTTY) { Select-PromptKitHosts }
if ($ProfileInteractive -or $TrackingInteractive -or $HostInteractive) { Review-PromptKitSetup }

Write-Host "`n🚀 Initializing PromptKit OS ($Profile profile)..." -ForegroundColor Cyan
Write-Host "   Host Project: $ProjectRoot" -ForegroundColor DarkGray
Write-Host "   Engine Path:  $ScriptDir" -ForegroundColor DarkGray
Write-Host "   Profile:      $Profile" -ForegroundColor DarkGray
Write-Host "   Tracking:     $Tracking" -ForegroundColor DarkGray
if ($Profile -eq "turbo") {
    Write-Host "   ⚠️  Turbo: up to ~2x measured token cost, experimental, parallel waves. Human approval still required for L3." -ForegroundColor Yellow
}
if ($Profile -eq "lite") {
    Write-Host "   ✨ Lite: 6 utility workflows, <1,500 tok, 80% value — perfect for onboarding" -ForegroundColor Green
}
Write-Host ""

if ($env:PROMPTKIT_NO_PREFLIGHT -eq '1') {
    Write-Output 'PREFLIGHT|SKIPPED|USER_OPT_OUT'
} else {
    $savedExitCode = $global:LASTEXITCODE
    try {
        & (Join-Path $ScriptDir 'scripts/check-harness-security.ps1') -Root $ProjectRootPath
        if ($LASTEXITCODE -ne 0) {
            Write-Output 'PREFLIGHT|ADVISORY|Review findings or incomplete checks; installation continues'
        }
    } catch {
        Write-Output 'PREFLIGHT|INCOMPLETE|SCANNER_UNAVAILABLE'
    } finally {
        $global:LASTEXITCODE = $savedExitCode
    }
}


# 3. Detect Agent Files or Default to AGENTS.md
$AgentFileCandidates = @(
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    ".cursorrules",
    ".cursor/rules/promptkit.mdc",
    ".windsurfrules",
    ".github/copilot-instructions.md",
    ".clinerules",
    ".clinerules/promptkit.md",
    ".traerules",
    ".opencode/rules.md",
    "CONVENTIONS.md"   # Aider conventions file
)

function Test-IsManagedDestination {
    param([string]$CandidatePath)
    $canonCand = Resolve-CanonicalPath $CandidatePath
    $managed = @($ProjectProfile, $StateTracker, $PrTemplateTarget, $TaskTemplateTarget)
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    } else {
        [System.StringComparison]::Ordinal
    }
    foreach ($m in $managed) {
        $canonM = Resolve-CanonicalPath $m
        if ($canonCand.Equals($canonM, $comparison)) {
            return $true
        }
    }
    return $false
}

function Add-TargetUnique {
    param([string]$TargetPath)
    $canonWant = Resolve-CanonicalPath $TargetPath
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    } else {
        [System.StringComparison]::Ordinal
    }
    foreach ($existing in $script:TargetsFound) {
        $canonExist = Resolve-CanonicalPath $existing
        if ($canonWant.Equals($canonExist, $comparison)) {
            return $false
        }
    }
    $script:TargetsFound += $TargetPath
    return $true
}

$TargetsFound = @()
foreach ($file in $AgentFileCandidates) {
    $path = Join-Path $ProjectRoot $file
    if (Test-Path -LiteralPath $path) {
        if (Test-Path -LiteralPath $path -PathType Container) {
            if ($file -eq ".clinerules") {
                Add-TargetUnique (Join-Path $path "promptkit.md") | Out-Null
            }
        } else {
            Add-TargetUnique $path | Out-Null
        }
    }
}

# Custom --target paths (F06 - P2, R6 - P2, R7 - P2)
foreach ($xp in $ExtraTargets) {
    $xfull = Join-Path $ProjectRoot $xp
    if (Test-IsManagedDestination $xfull) {
        throw "Error: Custom target cannot be a managed PromptKit OS file: $xp"
    }
    if (Test-Path -LiteralPath $xfull -PathType Container) {
        throw "Error: Target destination cannot be a directory: $xp"
    }
    if (Add-TargetUnique $xfull) {
        Write-Host "  [+] Added custom target: $xp" -ForegroundColor Green
    }
}

function Register-TargetFile($Rel) {
    $want = Join-Path $ProjectRoot $Rel
    if ($Rel -eq ".clinerules") {
        if (Test-Path -LiteralPath $want -PathType Leaf) {
            # Existing file layout
        } elseif (Test-Path -LiteralPath $want -PathType Container) {
            $want = Join-Path $want "promptkit.md"
        } else {
            $want = Join-Path $want "promptkit.md"
        }
    }
    return (Add-TargetUnique $want)
}

$Fresh = ($TargetsFound.Count -eq 0)
if ($HostSet -and $Hosts -ne "") {
    foreach ($h in ($Hosts -split ',')) {
        $rel = Get-HostFile $h.Trim()
        if (Register-TargetFile $rel) {
            Write-Host "  [+] Added host configuration: $rel" -ForegroundColor Green
        }
    }
}
if ($Fresh) {
    Register-TargetFile "AGENTS.md" | Out-Null
    if ($HostSet -and $Hosts -ne "") {
        foreach ($h in ($Hosts -split ',')) {
            $rel = Get-HostFile $h.Trim()
            if ($rel -eq "AGENTS.md") { continue }
            Register-TargetFile $rel | Out-Null
        }
    } else {
        Register-TargetFile "CLAUDE.md" | Out-Null
    }
    $created = @($TargetsFound | ForEach-Object {
        $_.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
    }) -join ' '
    Write-Host "  [+] Created default agent configurations: $created" -ForegroundColor Green
}

# 4. Containment Verification (F04 - P2)
$AllDestinations = @($ProjectProfile, $StateTracker, $PrTemplateTarget, $TaskTemplateTarget) + $TargetsFound
foreach ($dest in $AllDestinations) {
    if (-not (Test-PathContained $ProjectRoot $dest)) {
        $relDest = if ($dest.StartsWith($ProjectRootPath)) {
            $dest.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
        } else {
            $dest -replace "\\", "/"
        }
        [System.Console]::Error.WriteLine("Error: Target destination escapes project root: $relDest")
        throw "Error: Target destination escapes project root: $relDest"
    }
}

# 5. Directive Block (Loaded from Canonical Template based on profile)
$KitDirRel = if ($ScriptDir.StartsWith($ProjectRootPath)) {
    $ScriptDir.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
} else {
    ".promptkit"
}

if ($Profile -eq "lite") {
    $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-lite-template.md"
    if (-not (Test-Path -LiteralPath $TemplateDirective)) {
        Write-Host "Warning: Lite template not found, falling back to full template" -ForegroundColor Yellow
        $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-template.md"
    }
} else {
    $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-template.md"
}

if (Test-Path -LiteralPath $TemplateDirective) {
    $RawTemplate = [System.IO.File]::ReadAllText($TemplateDirective, [System.Text.Encoding]::UTF8)
    $Directive = ($RawTemplate `
        -replace '\$KIT_DIR_REL', (ConvertTo-LiteralReplacement $KitDirRel) `
        -replace '\$ENGINE_VERSION', (ConvertTo-LiteralReplacement $EngineVersion) `
        -replace '\$ENGINE_SHA', (ConvertTo-LiteralReplacement $EngineSha)).TrimEnd("`r", "`n")
} else {
    throw "Error: Canonical directive template not found at $TemplateDirective"
}

# 6. Pre-validation and Transformation Staging (F07 - P2)
$StagedTargetUpdates = [System.Collections.Generic.List[PSObject]]::new()
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($targetPath in $TargetsFound) {
    $relTarget = if ($targetPath.StartsWith($ProjectRootPath)) {
        $targetPath.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
    } else {
        $targetPath -replace "\\", "/"
    }

    if (Test-Path -LiteralPath $targetPath -PathType Container) {
        throw "Error: Target destination cannot be a directory: $relTarget"
    }

    $content = if (Test-Path -LiteralPath $targetPath) {
        [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
    } else {
        ""
    }

    $lines = $content -split "\r?\n"
    $startIndex = -1
    $endIndex = -1
    $startCount = 0
    $endCount = 0

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $trimmed = $lines[$i].Trim()
        if ($trimmed -eq "<!-- PROMPTKIT_START -->") {
            $startCount++
            if ($startIndex -eq -1) { $startIndex = $i }
        }
        if ($trimmed -eq "<!-- PROMPTKIT_END -->") {
            $endCount++
            if ($endIndex -eq -1) { $endIndex = $i }
        }
    }

    if ($startCount -gt 0 -or $endCount -gt 0) {
        if ($startCount -ne 1 -or $endCount -ne 1 -or $startIndex -ge $endIndex) {
            [System.Console]::Error.WriteLine("Error: Cannot safely update ${relTarget}: expected exactly one complete PromptKit directive block with START before END.")
            throw "Error: Cannot safely update ${relTarget}: expected exactly one complete PromptKit directive block with START before END."
        }

        $isCrlf = $content.Contains("`r`n")
        $nl = if ($isCrlf) { "`r`n" } else { "`n" }
        $targetDirective = ($Directive -split "`r?`n") -join $nl

        # Calculate exact character offsets to preserve original bytes outside the managed block
        $currentOffset = 0
        $blockStartChar = -1
        $blockEndChar = -1

        for ($i = 0; $i -lt $lines.Length; $i++) {
            $lineLen = $lines[$i].Length
            if ($i -eq $startIndex) {
                $blockStartChar = $currentOffset
            }
            if ($i -eq $endIndex) {
                $blockEndChar = $currentOffset + $lineLen
                break
            }

            $nextOffset = $currentOffset + $lineLen
            if ($nextOffset -lt $content.Length) {
                if ($content.Substring($nextOffset).StartsWith("`r`n")) {
                    $currentOffset = $nextOffset + 2
                } elseif ($content.Substring($nextOffset).StartsWith("`n")) {
                    $currentOffset = $nextOffset + 1
                } else {
                    $currentOffset = $nextOffset
                }
            } else {
                $currentOffset = $nextOffset
            }
        }

        $before = if ($blockStartChar -gt 0) { $content.Substring(0, $blockStartChar) } else { "" }
        $after = if ($blockEndChar -lt $content.Length) { $content.Substring($blockEndChar) } else { "" }

        $updated = $before + $targetDirective + $after
        $StagedTargetUpdates.Add([PSCustomObject]@{
            TargetPath = $targetPath
            Content    = $updated
            Mode       = "update"
            RelTarget  = $relTarget
        })
    } elseif (Test-Path -LiteralPath $targetPath) {
        $isCrlf = $content.Contains("`r`n")
        $targetDirective = if ($isCrlf) {
            ($Directive -split "`r?`n") -join "`r`n"
        } else {
            ($Directive -split "`r?`n") -join "`n"
        }
        $prefix = ""
        if ($content.Length -gt 0) {
            if ($content.EndsWith("`r`n")) {
                $prefix = "`r`n"
            } elseif ($content.EndsWith("`n")) {
                $prefix = "`n"
            } else {
                $prefix = if ($isCrlf) { "`r`n`r`n" } else { "`n`n" }
            }
        }
        $updated = $content + $prefix + $targetDirective
        $StagedTargetUpdates.Add([PSCustomObject]@{
            TargetPath = $targetPath
            Content    = $updated
            Mode       = "inject"
            RelTarget  = $relTarget
        })
    } else {
        $isCrlf = $Directive.Contains("`r`n")
        $targetNl = if ($isCrlf) { "`r`n" } else { "`n" }
        $targetDirective = ($Directive -split "`r?`n") -join $targetNl
        $StagedTargetUpdates.Add([PSCustomObject]@{
            TargetPath = $targetPath
            Content    = $targetDirective + $targetNl
            Mode       = "create"
            RelTarget  = $relTarget
        })
    }
}

# Pre-calculate PROMPTKIT.md content
function Get-UpdatedProfileContent {
    param(
        [string]$CurrentContent,
        [string]$Profile,
        [string]$Tracking,
        [string]$TrackingProjection,
        [string]$EngineDir
    )
    $text = $CurrentContent
    if ($text -match "(?m)^profile:") {
        $lines = @($text -split "`r?\n" | Where-Object { $_ -notmatch "^profile:" })
        $lines += "profile: $Profile"
        $text = ($lines -join "`n") + "`n"
        if ($text -match "(?m)^- \*\*Profile\*\*:") {
            $text = $text -replace "(?m)^- \*\*Profile\*\*:.*", "- **Profile**: $Profile"
        }
        if ($text -match "(?m)^- \*\*Installed\*\*:") {
            $text = $text -replace "(?m)^- \*\*Installed\*\*:.*", "- **Installed**: $(Get-Date -Format 'yyyy-MM-dd')"
        }
    } else {
        $firstLine = ""
        $rest = ""
        $allLines = $text -split "`r?\n"
        if ($allLines.Length -gt 0) { $firstLine = $allLines[0] }
        if ($allLines.Length -gt 1) { $rest = ($allLines[1..($allLines.Length - 1)] -join "`n") }
        $profileSection = @"

## 0. PromptKit OS Profile
- **Profile**: $Profile
- **Installed**: $(Get-Date -Format "yyyy-MM-dd")
- **Engine**: $EngineDir
- **Upgrade**: Run ``$EngineDir/init.ps1 --balanced`` for the full Balanced profile, or ``--turbo --experimental`` for parallel waves

"@
        $text = "$firstLine`n$profileSection`n$rest`n`n"
        $lines = @($text -split "`r?\n" | Where-Object { $_ -notmatch "^profile:" })
        $lines += "profile: $Profile"
        $text = ($lines -join "`n") + "`n"
    }

    $lines = @($text -split "`r?\n" | Where-Object { $_ -notmatch "^tracking:" })
    $lines += "tracking: $Tracking"
    $text = ($lines -join "`n") + "`n"

    $lines = @($text -split "`r?\n" | Where-Object { $_ -notmatch "^projection:" })
    if (-not [string]::IsNullOrEmpty($TrackingProjection)) {
        $lines += "projection: $TrackingProjection"
    }
    $text = ($lines -join "`n") + "`n"
    return $text
}

# 7. Transactional Commit with Rollback (F07 - P2)
$backupDir = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$createdFiles = New-Object System.Collections.Generic.List[string]
$backedUpFiles = New-Object System.Collections.Generic.List[string]
$backupSources = New-Object System.Collections.Generic.List[string]

$comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
    [System.StringComparison]::OrdinalIgnoreCase
} else {
    [System.StringComparison]::Ordinal
}

try {
    # Snapshot all existing destinations ONCE before ANY disk mutation begins (R5 - P2)
    if (Test-Path -LiteralPath $ProjectProfile) {
        $bkp = Join-Path $backupDir "PROMPTKIT.md"
        Copy-Item -LiteralPath $ProjectProfile -Destination $bkp -Force
        $backedUpFiles.Add($ProjectProfile)
        $backupSources.Add($bkp)
    }

    $bIdx = 0
    foreach ($item in $StagedTargetUpdates) {
        $tPath = $item.TargetPath
        if (Test-Path -LiteralPath $tPath) {
            $canonT = Resolve-CanonicalPath $tPath
            $alreadySnapshotted = $false
            foreach ($existingBkp in $backedUpFiles) {
                $canonExist = Resolve-CanonicalPath $existingBkp
                if ($canonT.Equals($canonExist, $comparison)) {
                    $alreadySnapshotted = $true
                    break
                }
            }
            if (-not $alreadySnapshotted) {
                $bkp = Join-Path $backupDir ("target_" + $bIdx)
                Copy-Item -LiteralPath $tPath -Destination $bkp -Force
                $backedUpFiles.Add($tPath)
                $backupSources.Add($bkp)
            }
        }
        $bIdx++
    }

    # STATE.md is mutated in place rather than staged, so it belongs in the transaction even
    # though it is not a staged target. Without this, a failure after the stamp pass restores
    # PROMPTKIT.md and the host targets but leaves an already-stamped STATE.md behind.
    if (Test-Path -LiteralPath $StateTracker) {
        $stateCanon = Resolve-CanonicalPath $StateTracker
        $alreadySnapshotted = $false
        foreach ($existingBkp in $backedUpFiles) {
            if ($stateCanon.Equals((Resolve-CanonicalPath $existingBkp), $comparison)) {
                $alreadySnapshotted = $true
                break
            }
        }
        if (-not $alreadySnapshotted) {
            $bkp = Join-Path $backupDir "STATE.md"
            Copy-Item -LiteralPath $StateTracker -Destination $bkp -Force
            $backedUpFiles.Add($StateTracker)
            $backupSources.Add($bkp)
        }
    }

    # Ensure doc directories
    foreach ($dir in $DocDirs) {
        $fullPath = Join-Path $ProjectRoot $dir
        if (-not (Test-Path -LiteralPath $fullPath)) {
            [System.IO.Directory]::CreateDirectory($fullPath) | Out-Null
            Write-Host "  [+] Created directory: $dir" -ForegroundColor Green
        }
    }

    # Commit PROMPTKIT.md
    $profileInitialContent = ""
    if (Test-Path -LiteralPath $ProjectProfile) {
        $profileInitialContent = [System.IO.File]::ReadAllText($ProjectProfile, [System.Text.Encoding]::UTF8)
    } elseif (Test-Path -LiteralPath $TemplateProfile) {
        $profileInitialContent = [System.IO.File]::ReadAllText($TemplateProfile, [System.Text.Encoding]::UTF8)
    }
    $stagedProfile = Get-UpdatedProfileContent -CurrentContent $profileInitialContent -Profile $Profile -Tracking $Tracking -TrackingProjection $TrackingProjection -EngineDir $EngineDir

    if (-not (Test-Path -LiteralPath $ProjectProfile)) {
        $createdFiles.Add($ProjectProfile)
    }
    [System.IO.File]::WriteAllText($ProjectProfile, $stagedProfile, $utf8NoBom)
    if ($backedUpFiles.Contains($ProjectProfile)) {
        Write-Host "  [✓] Updated PROMPTKIT.md profile: $Profile" -ForegroundColor Yellow
        Write-Host "  [✓] Updated PROMPTKIT.md tracking: $Tracking" -ForegroundColor Yellow
        if (-not [string]::IsNullOrEmpty($TrackingProjection)) {
            Write-Host "  [✓] Updated PROMPTKIT.md projection: $TrackingProjection" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [+] Created: PROMPTKIT.md (project profile & guardrails)" -ForegroundColor Green
        Write-Host "  [+] Set PROMPTKIT.md profile: $Profile" -ForegroundColor Green
        Write-Host "  [✓] Updated PROMPTKIT.md tracking: $Tracking" -ForegroundColor Yellow
    }

    # Commit scaffolds
    if (-not (Test-Path -LiteralPath $StateTracker) -and (Test-Path -LiteralPath $TemplateState)) {
        $docsParent = Split-Path -Parent $StateTracker
        if (-not (Test-Path -LiteralPath $docsParent)) { [System.IO.Directory]::CreateDirectory($docsParent) | Out-Null }
        Copy-Item -LiteralPath $TemplateState -Destination $StateTracker -Force
        $createdFiles.Add($StateTracker)
        Write-Host "  [+] Created: docs/STATE.md (living project & state tracker)" -ForegroundColor Green
    }
    # STATE.md is copied verbatim, not substituted, so it needs its own stamp pass. A STATE.md
    # that predates this feature has no Engine Version row at all, so insert one after the Last
    # Updated row instead of skipping the file forever; a file carrying neither anchor is left
    # untouched rather than guessed at.
    if (Test-Path -LiteralPath $StateTracker) {
        $stateText = [System.IO.File]::ReadAllText($StateTracker, [System.Text.Encoding]::UTF8)
        $stampRow = "- **Engine Version**: $EngineVersion @ $EngineSha"
        if ($stateText -match "(?m)^- \*\*Engine Version\*\*:") {
            $stateText = $stateText -replace "(?m)^- \*\*Engine Version\*\*:.*", (ConvertTo-LiteralReplacement $stampRow)
            [System.IO.File]::WriteAllText($StateTracker, $stateText, $utf8NoBom)
        } elseif ($stateText -match "(?m)^- \*\*Last Updated\*\*:") {
            $inserted = [System.Text.RegularExpressions.Regex]::Replace(
                $stateText,
                "(?m)^(- \*\*Last Updated\*\*:.*)$",
                { param($m) $m.Groups[1].Value + "`n" + $stampRow },
                1)
            [System.IO.File]::WriteAllText($StateTracker, $inserted, $utf8NoBom)
        }
    }
    if (-not (Test-Path -LiteralPath $PrTemplateTarget) -and (Test-Path -LiteralPath $TemplatePr)) {
        $ghParent = Split-Path -Parent $PrTemplateTarget
        if (-not (Test-Path -LiteralPath $ghParent)) { [System.IO.Directory]::CreateDirectory($ghParent) | Out-Null }
        Copy-Item -LiteralPath $TemplatePr -Destination $PrTemplateTarget -Force
        $createdFiles.Add($PrTemplateTarget)
        Write-Host "  [+] Created: .github/pull_request_template.md (staff-level PR specification)" -ForegroundColor Green
    }
    if (-not (Test-Path -LiteralPath $TaskTemplateTarget) -and (Test-Path -LiteralPath $TemplateTask)) {
        $taskParent = Split-Path -Parent $TaskTemplateTarget
        if (-not (Test-Path -LiteralPath $taskParent)) { [System.IO.Directory]::CreateDirectory($taskParent) | Out-Null }
        Copy-Item -LiteralPath $TemplateTask -Destination $TaskTemplateTarget -Force
        $createdFiles.Add($TaskTemplateTarget)
        Write-Host "  [+] Created: .github/ISSUE_TEMPLATE/task.md (standard task specification)" -ForegroundColor Green
    }

    # Commit targets
    foreach ($item in $StagedTargetUpdates) {
        $tPath = $item.TargetPath
        $pDir = Split-Path -Parent $tPath
        if ($pDir -ne "" -and -not (Test-Path -LiteralPath $pDir)) {
            [System.IO.Directory]::CreateDirectory($pDir) | Out-Null
        }
        if (-not (Test-Path -LiteralPath $tPath)) {
            $createdFiles.Add($tPath)
        }
        [System.IO.File]::WriteAllText($tPath, $item.Content, $utf8NoBom)
        if ($item.Mode -eq "update") {
            Write-Host "  [✓] Updated PromptKit OS directives in: $($item.RelTarget) (profile: $Profile)" -ForegroundColor Yellow
        } else {
            Write-Host "  [+] Injected PromptKit OS directives into: $($item.RelTarget) (profile: $Profile)" -ForegroundColor Green
        }
    }
} catch {
    # Rollback!
    for ($i = $createdFiles.Count - 1; $i -ge 0; $i--) {
        $f = $createdFiles[$i]
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
    }
    for ($i = 0; $i -lt $backedUpFiles.Count; $i++) {
        $dest = $backedUpFiles[$i]
        $bkp = $backupSources[$i]
        if (Test-Path -LiteralPath $bkp) {
            Copy-Item -LiteralPath $bkp -Destination $dest -Force -ErrorAction SilentlyContinue
        }
    }
    throw
} finally {
    if (Test-Path -LiteralPath $backupDir) {
        Remove-Item -LiteralPath $backupDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 8. Install-door structural assert (#549). Must stay after the rollback block
# and before the banner: a non-zero result fails the install without rollback.
$assertRc = 0
try {
    & (Join-Path $ScriptDir 'scripts/check-setup-assert.ps1') -ProjectRoot $ProjectRootPath -KitDir $ScriptDir -KitDirRel $KitDirRel
    $assertRc = $LASTEXITCODE
} catch {
    Write-Output 'ASSERT|unknown|checker|INCOMPLETE'
    exit 2
}
if ($assertRc -eq 1) { exit 1 }
if ($assertRc -ne 0) {
    if ($assertRc -ne 2) { Write-Output 'ASSERT|unknown|checker|INCOMPLETE' }
    exit 2
}

Write-Host "`n✨ PromptKit OS successfully configured for $ProjectRoot! ($Profile profile)" -ForegroundColor Cyan
if ($Profile -eq "lite") {
    Write-Host "   Lite: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) — 80% value, <1,500 tok" -ForegroundColor Green
    Write-Host "   Upgrade anytime: .promptkit/init.ps1 --balanced for the full Balanced profile" -ForegroundColor DarkGray
} elseif ($Profile -eq "balanced") {
    Write-Host "   Balanced: 25 workflows, Level 0-3 adaptive ceremony — full power" -ForegroundColor White
    Write-Host "   For onboarding: .promptkit/init.ps1 --lite for minimal setup" -ForegroundColor DarkGray
} else {
    Write-Host "   Turbo (Experimental): Balanced + parallel waves, up to ~2x measured token cost" -ForegroundColor Yellow
    Write-Host "   Human approval still required for Level 3 (releases/tags/deploys)" -ForegroundColor DarkGray
}
Write-Host "   Start by asking your AI: 'pk:route', 'pk:debug', 'pk:commit', 'pk:checkpoint'`n" -ForegroundColor White
