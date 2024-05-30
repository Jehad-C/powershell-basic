param(
    [string]$LogPath="$HOME/workspace/Log.txt",
    [string]$ReportPath="$HOME/workspace/LogReport.txt"
)

function Parse-LogFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    $logContent = @()
    $logs = Get-Content -Path $LogPath
    $pattern = "^\[(?<Timestamp>[^\]]+)\] \[(?<Level>[^\]]+)\] \[(?<Source>[^\]]+)\] (?<Message>.+)$"
    foreach ($log in $logs) {
        if ($log -match $pattern) {
            $logInformation = [PSCustomObject]@{
                Timestamp = $Matches.Timestamp
                Level = $Matches.Level
                Source = $Matches.Source
                Message = $Matches.Message
            }

            $logContent += $logInformation
        }
    }

    return $logContent
}

function Generate-Report {
    param(
        [Parameter(Mandatory=$true)]
        [Array]$LogContent,
        [Parameter(Mandatory=$true)]
        [string]$ReportPath
    )

    $reportDir = Split-Path -Path $ReportPath -Parent

    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    Remove-Item -Path $ReportPath -Confirm:$false -ErrorAction SilentlyContinue

    $logCount = 0
    $infoCount = 0
    $warningCount = 0
    $errorCount = 0
    $criticalCount = 0

    if (-not $LogContent.IsEmpty) {
        $logCount = $LogContent.Count
    }

    $infos = $LogContent | Where-Object { $_.Level -eq "INFO" }
    if ($infos) {
        if ($infos.Count) {
            $infoCount = $infos.Count
        } else {
            $infoCount = 1
        }
    } else {
        $infoCount = 0
    }

    $warnings = $LogContent | Where-Object { $_.Level -eq "WARNING" }
    if ($warnings) {
        if ($warnings.Count) {
            $warningCount = $warnings.Count
        } else {
            $warningCount = 1
        }
    } else {
        $warningCount = 0
    }

    $errors = $LogContent | Where-Object { $_.Level -eq "ERROR" }
    if ($errors) {
        if ($errors.Count) {
            $errorCount = $errors.Count
        } else {
            $errorCount = 1
        }
    } else {
        $errorCount = 0
    }

    $criticals = $LogContent | Where-Object { $_.Level -eq "CRITICAL" }
    if ($criticals) {
        if ($criticals.Count) {
            $criticalCount = $criticals.Count
        } else {
            $criticalCount = 1
        }
    } else {
        $criticalCount = 0
    }

    $reportContent = @()
    $reportContent += "********************"
    $reportContent += "Log Analysis Report"
    $reportContent += "********************"
    $reportContent += "Total Log Entries: $logCount"
    $reportContent += "Info Entries: $infoCount"
    $reportContent += "Warning Entries: $warningCount"
    $reportContent += "Error Entries: $errorCount"
    $reportContent += "Critical Entries: $criticalCount"
    $reportContent += ""
    $reportContent += "--------------------"
    $reportContent += "Recent Errors:"
    $reportContent += "--------------------"
    $reportContent += $errors | Select-Object -First 5 | Format-Table -AutoSize | Out-String

    $reportContent | Out-File -FilePath $ReportPath -Force

    Write-Host "Successfully generated report"
}

$logContent = Parse-LogFile -LogPath $LogPath
if (-not $LogContent) {
    $logContent = New-Object PSObject
    $logContent | Add-Member -MemberType NoteProperty -Name IsEmpty -Value $true
}

Generate-Report -LogContent $logContent -ReportPath $ReportPath
