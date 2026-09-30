[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$ExitCode,

    [Parameter(ValueFromPipeline = $true)]
    [string[]]$InputObject,

    [Parameter(Mandatory = $false)]
    [string]$InputPath
)

begin {
    $rawLines = [System.Collections.Generic.List[string]]::new()
}

process {
    if ($null -ne $InputObject) {
        foreach ($item in $InputObject) {
            if ($null -ne $item) {
                $lines = "$item".Split(@("`r`n", "`n", "`r"), [System.StringSplitOptions]::None)
                foreach ($l in $lines) {
                    $rawLines.Add($l)
                }
            }
        }
    }
}

end {
    if ($InputPath -and (Test-Path $InputPath)) {
        $fileLines = [System.IO.File]::ReadAllLines($InputPath)
        foreach ($fl in $fileLines) {
            $rawLines.Add($fl)
        }
    }

    if ($rawLines.Count -eq 0 -and $null -ne $input) {
        foreach ($item in $input) {
            if ($null -ne $item) {
                $lines = "$item".Split(@("`r`n", "`n", "`r"), [System.StringSplitOptions]::None)
                foreach ($l in $lines) {
                    $rawLines.Add($l)
                }
            }
        }
    }

    if ($rawLines.Count -eq 0) {
        try {
            while (($line = [System.Console]::ReadLine()) -ne $null) {
                $rawLines.Add($line)
            }
        } catch {}
    }

    $hasNonEmpty = $false
    foreach ($l in $rawLines) {
        if (-not [string]::IsNullOrWhiteSpace($l)) {
            $hasNonEmpty = $true
            break
        }
    }

    if (-not $hasNonEmpty) {
        Write-Error "Contract violation: Validator output was completely empty."
        exit 1
    }

    if ($ExitCode -ne 0 -and $ExitCode -ne 1) {
        Write-Error "Release record validation crashed with exit code $ExitCode."
        exit $ExitCode
    }

    $summaryCount = 0
    $summaryType = $null
    $summaryErrors = 0
    $summaryRecords = 0
    $diagnosticCount = 0
    $nonGrandfathered = [System.Collections.Generic.List[string]]::new()
    $invalidLines = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $rawLines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            $invalidLines.Add("<empty line>")
            continue
        }

        if ($line -match '^VALID\|RECORDS=(\d+)\|ROOT=(.*)$') {
            $summaryCount++
            $summaryType = 'VALID'
            $summaryRecords = [int]$Matches[1]
            continue
        }

        if ($line -match '^FAILED\|ERRORS=(\d+)\|RECORDS=(\d+)$') {
            $summaryCount++
            $summaryType = 'FAILED'
            $summaryErrors = [int]$Matches[1]
            $summaryRecords = [int]$Matches[2]
            continue
        }

        if ($line -match '^([A-Z_]+)\|([^|]+)\|([^|]+)\|([^|]+)\|(.+)$') {
            $category = $Matches[1]
            $evalId = $Matches[2]
            $recPath = $Matches[3]
            $msg = $Matches[4]
            $remedy = $Matches[5]

            $diagnosticCount++
            $normPath = $recPath.Replace('\', '/')
            if ($normPath -notmatch '^(\./)?docs/releases/2026-09-08-v1\.0\.0-[^/]+\.md$') {
                $nonGrandfathered.Add($line)
            }
            continue
        }

        $invalidLines.Add($line)
    }

    if ($invalidLines.Count -gt 0) {
        $badLines = $invalidLines -join "`n  "
        Write-Error "Contract violation: Found unrecognized or unstructured line(s):`n  $badLines"
        exit 1
    }

    if ($summaryCount -ne 1) {
        Write-Error "Contract violation: Expected exactly 1 summary line, found $summaryCount."
        exit 1
    }

    if ($ExitCode -eq 0) {
        if ($summaryType -ne 'VALID') {
            Write-Error "Contract violation: Process exited 0 but summary was $summaryType."
            exit 1
        }
        if ($diagnosticCount -ne 0) {
            Write-Error "Contract violation: Process exited 0 with $diagnosticCount diagnostic(s)."
            exit 1
        }
        Write-Host "All release records passed validation (clean valid)."
        exit 0
    } elseif ($ExitCode -eq 1) {
        if ($summaryType -ne 'FAILED') {
            Write-Error "Contract violation: Process exited 1 but summary was $summaryType."
            exit 1
        }
        if ($diagnosticCount -eq 0) {
            Write-Error "Contract violation: Process exited 1 with FAILED summary but 0 diagnostics."
            exit 1
        }
        if ($diagnosticCount -ne $summaryErrors) {
            Write-Error "Contract violation: FAILED summary reported $summaryErrors error(s), but parsed $diagnosticCount diagnostic(s)."
            exit 1
        }
        if ($nonGrandfathered.Count -gt 0) {
            $errs = $nonGrandfathered -join "`n  "
            Write-Error "Release record validation errors found in non-grandfathered records:`n  $errs"
            exit 1
        }
        $global:LASTEXITCODE = 0
        Write-Host "All non-grandfathered release records passed validation (all diagnostics grandfathered)."
        exit 0
    }
}
