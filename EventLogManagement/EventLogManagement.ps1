param(
    [ValidateSet("Monitor", "Archive", "Clear")]
    [Parameter(Mandatory=$true)]
    [string]$Action,
    [string]$ID,
    [Parameter(Mandatory=$true)]
    [string]$LogName,
    [string]$ArchiveDirectory = "$HOME\workspace\archive",
    [string]$LogPath = "$HOME\workspace\logs\Events.log"
)

function Monitor-Event {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ID,
        [Parameter(Mandatory=$true)]
        [string]$LogName,
        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    $filters = @{
        ID = $ID
        LogName = $LogName
        StartTime = Get-Date
    }

    do {
        #$key = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
        $events = Get-WinEvent -FilterHashtable $filters -ErrorAction SilentlyContinue
        if ($events) {
            foreach ($event in $events) {
                $filters['StartTime'] = $event.TimeCreated.AddMilliseconds(1)

                $eventInformation = @{
                    ID = $event.Id
                    LogName = $event.LogName
                    Message = $event.Message
                    TimeCreated = $event.TimeCreated
                }

                Generate-Log -EventInformation $eventInformation -LogPath $LogPath
            }

            break
        }
    } until ($key.VirtualKeyCode -eq 13)    
}

function Generate-Log {
    param(
        [PSCustomObject]$EventInformation,
        [string]$LogPath
    )

    $logDir = Split-Path -Path $LogPath -Parent
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    if (Test-Path -Path $LogPath) {
        Remove-Item -Path $LogPath -Confirm:$false
    }

    $physicalMemory = "$([Math]::Round($SystemInformation.CsTotalPhysicalMemory / 1GB, 2)) GB"

    $logContent = @()
    $logContent += "********************"
    $logContent += "Event Information"
    $logContent += "********************"
    $logContent += "ID: $($EventInformation.ID)"
    $logContent += "Name: $($EventInformation.LogName)"
    $logContent += "Date: $($EventInformation.TimeCreated)"
    $logContent += "Message: $($EventInformation.Message)"

    try {
        $logContent | Out-File -FilePath $LogPath
        Write-Host 'Successfully logged event information'
    } catch {
        Write-Host 'Failed to logged event information'
    }
}

function Archive-EventLogs {
    param(
        [string]$LogName,
        [string]$ArchiveDirectory
    )

    New-Item -Path $ArchiveDirectory -ItemType Directory -Force | Out-Null
    $archiveFile = Join-Path -Path $ArchiveDirectory -ChildPath $LogName-$(Get-Date -Format yyyyMMddHHmmss).evtx
    Wevtutil epl $LogName $archiveFile
    Write-Host 'Successfully archived the event logs'
}

function Clear-EventLogs {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogName
    )

    Clear-EventLog -LogName $LogName
    Write-Host 'Successfully cleared the event logs'
}

switch ($Action) {
    'Monitor' { Monitor-Event -ID $ID -LogName $LogName -LogPath $LogPath }
    'Archive' { Archive-EventLogs -LogName $LogName -ArchiveDirectory $ArchiveDirectory }
    'Clear' { Clear-EventLogs -LogName $LogName }
}
