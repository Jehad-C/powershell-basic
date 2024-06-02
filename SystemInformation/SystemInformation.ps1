param(
    [string]$LogPath = "$HOME\workspace\logs\SystemInformation.log"
)

function Get-SystemInformation {
    try {
        $properties = @(
            'CsName',
            'WindowsVersion',
            'WindowsBuildLabEx',
            'CsManufacturer',
            'CsModel',
            'CsProcessors',
            'CsTotalPhysicalMemory',
            'BiosVersion',
            'BiosReleaseDate'
        )

        $computerInfo = Get-ComputerInfo -Property $properties
        return $computerInfo
    } catch {
        Write-Host 'Failed to retrieved system information'
        return $null
    }
}

function Generate-Log {
    param(
        [PSCustomObject]$SystemInformation,
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
    $logContent += "System Information"
    $logContent += "********************"
    $logContent += "`n--- Computer Information ---"
    $logContent += "Computer Name: $($SystemInformation.CsName)"
    $logContent += "Manufacturer: $($SystemInformation.CsManufacturer)"
    $logContent += "Model: $($SystemInformation.CsModel)"
    $logContent += "Processor: $($SystemInformation.CsProcessors)"
    $logContent += "Total Physical Memory: $physicalMemory"
    $logContent += "`n--- Operating System Information ---"
    $logContent += "OS Version: $($SystemInformation.WindowsVersion)"
    $logContent += "OS Build: $($SystemInformation.WindowsBuildLabEx)"
    $logContent += "`n--- Bios Information ---"
    $logContent += "Bios Version: $($SystemInformation.BiosVersion)"
    $logContent += "Bios Release Date: $($SystemInformation.BiosReleaseDate)"

    try {
        $logContent | Out-File -FilePath $LogPath
        Write-Host 'Successfully logged system information'
    } catch {
        Write-Host 'Failed to logged system information'
    }
}

$systemInformation = Get-SystemInformation
if ($systemInformation) {
    Generate-Log -SystemInformation $systemInformation -LogPath $LogPath
}
