param(
    [string]$LogPath="$HOME/workspace/SystemHealth.txt"
)

function Get-CPUUsage {
    $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time'
    return [Math]::Round($cpuUsage.CounterSamples[0].CookedValue ,2)
}

function Get-MemoryUsage {
    $memoryUsage = Get-Counter '\Memory\% Committed Bytes in Use'
    return [Math]::Round($memoryUsage.CounterSamples[0].CookedValue ,2)
}

function Get-DiskHealth {
    $disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
    $disksHealth = @()
    foreach ($disk in $disks) {
        $freeSpace = [Math]::Round($disk.FreeSpace / 1GB, 2)
        $totalSpace = [Math]::Round($disk.Size / 1GB, 2)
        $usedSpace = $totalSpace - $freeSpace
        $freeSpacePercentage = [Math]::Round(($freeSpace / $totalSpace) * 100, 2)
        $diskInformation = [PSCustomObject]@{
            Name = $disk.DeviceID
            FreeSpaceGB = $freeSpace
            UsedSpaceGB = $usedSpace
            TotalSpaceGB = $totalSpace
            FreeSpacePercentage = $freeSpacePercentage
        }

        $disksHealth += $diskInformation
    }

    return $disksHealth
}

function Get-NetworkPerformance {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $networkPerformance = @()
    foreach ($adapter in $adapters) {
        $netStatistics = Get-NetAdapterStatistics -Name $adapter.Name
        $networkInformation = [PSCustomObject]@{
            Name = $adapter.Name
            BytesSent = [Math]::Round($netStatistics.SentBytes / 1MB, 2)
            BytesReceived = [Math]::Round($netStatistics.ReceivedBytes / 1MB, 2)
        }

        $networkPerformance += $networkInformation
    }

    return $networkPerformance
}

function Generate-Report {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath,
        [Parameter(Mandatory=$true)]
        [string]$CPUUsage,
        [Parameter(Mandatory=$true)]
        [string]$MemoryUsage,
        [Parameter(Mandatory=$true)]
        [Array]$DisksHealth,
        [Parameter(Mandatory=$true)]
        [Array]$NetworksPerformance
    )

    $logDir = Split-Path -Path $LogPath -Parent

    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Remove-Item -Path $LogPath -Confirm:$false -ErrorAction SilentlyContinue

    $logContent = @()
    $logContent += "********************"
    $logContent += "System Health Report"
    $logContent += "********************"
    $logContent += "CPU Usage: $CPUUsage %"
    $logContent += "Memory Usage: $MemoryUsage %"
    $logContent += ""
    $logContent += "--------------------"
    $logContent += "Disk Health"
    $logContent += "--------------------"
    foreach ($disk in $DisksHealth) {
        $logContent += "Disk: $($disk.Name) - Free Space: $($disk.FreeSpaceGB) ($($disk.FreeSpacePercentage)%) - Used Space: $($disk.UsedSpaceGB) - Total Space: $($disk.TotalSpaceGB)"
    }

    $logContent += ""
    $logContent += "--------------------"
    $logContent += "Network Performance"
    $logContent += "--------------------"
    foreach ($network in $NetworksPerformance) {
        $logContent += "Adapter: $($network.Name) - Bytes Sent: $($network.BytesSent) - Bytes Received: $($network.BytesReceived)"
    }

    $logContent | Out-File -FilePath $LogPath -Force
}

$cpuUsage = Get-CPUUsage
$memoryUsage = Get-MemoryUsage
$disksHealth = Get-DiskHealth
$networkPerformance = Get-NetworkPerformance

Write-Host "$($disksHealth[0].Name)"
Generate-Report -LogPath $LogPath -CPUUsage $cpuUsage -MemoryUsage $memoryUsage -DisksHealth $disksHealth -NetworksPerformance $networkPerformance
