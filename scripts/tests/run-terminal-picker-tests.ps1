$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "../terminal-picker.ps1")

function Clear-PkPickerScreen { }
$script:PkTestKeys = [System.Collections.Generic.Queue[string]]::new()
function Read-PkPickerKey { return $script:PkTestKeys.Dequeue() }

$script:PkTestKeys.Enqueue("DownArrow")
$script:PkTestKeys.Enqueue("Enter")
$single = Invoke-PkSinglePicker -Title "Profile" -Items @("Balanced", "Lite") -DefaultIndex 0
if ($single -ne 1) { throw "Single picker did not select the arrow-highlighted item." }

$script:PkTestKeys.Enqueue("Spacebar")
$script:PkTestKeys.Enqueue("DownArrow")
$script:PkTestKeys.Enqueue("Spacebar")
$script:PkTestKeys.Enqueue("Enter")
$multi = Invoke-PkMultiPicker -Title "Hosts" -Ids @("claude", "cursor") -Labels @("Claude Code", "Cursor") -Defaults "claude"
if ($multi -ne "cursor") { throw "Multi picker did not preserve checkbox toggles: '$multi'." }

$script:PkTestKeys.Enqueue("Q")
$cancel = Invoke-PkSinglePicker -Title "Profile" -Items @("Balanced", "Lite") -DefaultIndex 0
if ($cancel -ne -1) { throw "Single picker did not report cancellation." }

Write-Host "Terminal picker behavior passed (single select, multi-select, cancel)."
