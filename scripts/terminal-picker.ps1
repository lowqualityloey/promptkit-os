function Clear-PkPickerScreen {
    if (-not [Console]::IsOutputRedirected) { [Console]::Clear() }
    if ($script:PkPickerBannerActive) {
        if ($script:PkPickerBannerFull -and (Test-Path -LiteralPath $script:PkPickerBannerPath)) {
            Get-Content -LiteralPath $script:PkPickerBannerPath -Encoding UTF8 | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "◆ PromptKit OS · Project Setup ◆"
        }
        Write-Host ""
    } else {
        Write-Host "◆ PromptKit OS Setup ◆`n"
    }
}

function Read-PkPickerKey {
    return [Console]::ReadKey($true).Key.ToString()
}

function Invoke-PkSinglePicker {
    param(
        [Parameter(Mandatory)][string]$Title,
        [string]$Subtitle = "",
        [Parameter(Mandatory)][string[]]$Items,
        [int]$DefaultIndex = 0
    )
    $index = [Math]::Max(0, [Math]::Min($DefaultIndex, $Items.Count - 1))
    while ($true) {
        Clear-PkPickerScreen
        Write-Host "◈ $Title" -ForegroundColor Cyan
        if ($Subtitle) { Write-Host $Subtitle -ForegroundColor DarkGray }
        Write-Host ""
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $cursor = if ($i -eq $index) { "›" } else { " " }
            $radio = if ($i -eq $index) { "◉" } else { "○" }
            Write-Host " $cursor $radio $($Items[$i])"
        }
        Write-Host "`n↑/↓ Move   Enter Select   q Cancel" -ForegroundColor DarkGray
        $key = Read-PkPickerKey
        switch ($key) {
            'UpArrow' { $index = if ($index -eq 0) { $Items.Count - 1 } else { $index - 1 } }
            'DownArrow' { $index = if ($index -ge $Items.Count - 1) { 0 } else { $index + 1 } }
            'Enter' { $script:PkPickerBannerActive = $false; return $index }
            'Escape' { $script:PkPickerBannerActive = $false; return -1 }
            'Q' { $script:PkPickerBannerActive = $false; return -1 }
        }
    }
}

function Invoke-PkMultiPicker {
    param(
        [Parameter(Mandatory)][string]$Title,
        [string]$Subtitle = "",
        [Parameter(Mandatory)][string[]]$Ids,
        [Parameter(Mandatory)][string[]]$Labels,
        [string]$Defaults = ""
    )
    $selected = [System.Collections.Generic.List[string]]::new()
    foreach ($item in ($Defaults -split ',')) {
        if ($item -and $Ids -contains $item -and -not $selected.Contains($item)) { $selected.Add($item) }
    }
    $index = 0
    while ($true) {
        Clear-PkPickerScreen
        Write-Host "◈ $Title" -ForegroundColor Cyan
        if ($Subtitle) { Write-Host $Subtitle -ForegroundColor DarkGray }
        Write-Host ""
        for ($i = 0; $i -lt $Ids.Count; $i++) {
            $cursor = if ($i -eq $index) { "›" } else { " " }
            $check = if ($selected.Contains($Ids[$i])) { "✓" } else { " " }
            Write-Host " $cursor [$check] $($Labels[$i])"
        }
        Write-Host "`n↑/↓ Move   Space Toggle   Enter Done   q Cancel" -ForegroundColor DarkGray
        $key = Read-PkPickerKey
        switch ($key) {
            'UpArrow' { $index = if ($index -eq 0) { $Ids.Count - 1 } else { $index - 1 } }
            'DownArrow' { $index = if ($index -ge $Ids.Count - 1) { 0 } else { $index + 1 } }
            'Spacebar' {
                $item = $Ids[$index]
                if ($selected.Contains($item)) { $selected.Remove($item) } else { $selected.Add($item) }
            }
            'Enter' { $script:PkPickerBannerActive = $false; return ($selected -join ',') }
            'Escape' { $script:PkPickerBannerActive = $false; return $null }
            'Q' { $script:PkPickerBannerActive = $false; return $null }
        }
    }
}
