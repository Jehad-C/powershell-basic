param(
    [string]$LogPath = "$HOME\workspace\logs\SystemHealthInformation.log" # Default log path
)

# Function to retrieve cpu information
function Get-CPUInformation {
    $samples = 12
    $interval = 5
    $duration = $samples * $interval
    $totalCpuUsage = @()
    try {
        # Retrieve average cpu usage
        for ($i = 0; $i -lt $samples; $i++) {
            $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time'
            $totalCpuUsage += [Math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
            Start-Sleep -Seconds $interval
        }

        $averageCpuUsage = [Math]::Round(($totalCpuUsage | Measure-Object -Average).Average, 2)
        Start-Sleep -Seconds $interval

        # Retrieve current cpu usage
        $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time'
        $currentCpuUsagePercentage = [Math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
        $cpuInformation = [PSCustomObject]@{
            CurrentCpuUsagePercentage = "$currentCpuUsagePercentage %"
            AverageCpuUsage = "$averageCpuUsage with $samples samples in $duration seconds"
        }

        return $cpuInformation
    } catch {
        # Handle potential errors during cpu information retrieval
        Write-Host 'Failed to retrieve cpu information'
    }
}

# Function to retrieve memory information
function Get-MemoryInformation {
    try {
        # Retrieve memory information
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $freeMemory = [Math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $totalMemory = [Math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $usedMemory = $totalMemory - $freeMemory
        $memoryCounter = Get-Counter '\Memory\% Committed Bytes in Use'
        $usedMemoryPercentage = [Math]::Round($memoryCounter.CounterSamples[0].CookedValue, 2)
        $memoryInformation = [PSCustomObject]@{
            FreeMemory           = $freeMemory
            UsedMemory           = $usedMemory
            UsedMemoryPercentage = $usedMemoryPercentage
            TotalMemory          = $totalMemory
        }

        return $memoryInformation
    } catch {
        # Handle potential errors during memory information retrieval
        Write-Host 'Failed to retrieve memory information'
        return $null
    }
}

# Function to retrieve disk information
function Get-DiskInformation {
    try {
        # Retrieve disk information
        $drives = Get-PSDrive -PSProvider FileSystem

        $diskInformation = @()
        foreach ($drive in $drives) {
            $freeSpace           = [Math]::Round($drive.Free / 1GB, 2)
            $usedSpace           = [Math]::Round($drive.Used / 1GB, 2)
            $totalSpace          = $drive.Used + $drive.Free
            $freeSpacePercentage = [Math]::Round($drive.Free / $totalSpace, 4) * 100
            $diskInformation += [PSCustomObject]@{
                Drive               = $drive.Name
                FreeSpace           = $freeSpace
                FreeSpacePercentage = $freeSpacePercentage
                UsedSpace           = $usedSpace
                TotalSpace          = $totalSpace
            }
        }

        return $diskInformation
    } catch {
        # Handle potential errors during disk information retrieval
        Write-Host 'Failed to retrieve disk information'
        return $null
    }
}

# Function to retrieve network information
function Get-NetworkInformation {
    try {
        # Retrieve adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        $networkInformation = @()
        foreach ($adapter in $adapters) {
            # Retrieve network information
            $netStatistics = Get-NetAdapterStatistics -Name $adapter.Name
            
            # Perform ping test
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 4 -ErrorAction SilentlyContinue
            $pingAverage = if ($ping) { [Math]::Round(($ping | Measure-Object -Property ResponseTime -Average).Average, 2) } else { 0 }
            $networkInformation += [PSCustomObject]@{
                Name = $adapter.Name
                BytesSent = [Math]::Round($netStatistics.SentBytes / 1MB, 2)
                BytesReceived = [Math]::Round($netStatistics.ReceivedBytes / 1MB, 2)
                UnicastBytesSent = [Math]::Round($netStatistics.SentUnicastBytes / 1MB, 2)
                UnicastBytesReceived = [Math]::Round($netStatistics.ReceivedUnicastBytes / 1MB, 2)
                AveragePing = $pingAverage
            }
        }

        return $networkInformation
    } catch {
        # Handle potential errors during network information retrieval
        Write-Host 'Failed to retrieve network information'
        return $null
    }
}

function Generate-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath,                   # Path to save the log file
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$CpuInformation,    # CPU information object
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$MemoryInformation, # Memory information object
        [Parameter(Mandatory=$true)]
        [array]$DiskInformation,            # Disk information object
        [Parameter(Mandatory=$true)]
        [array]$NetworkInformation          # Network information object
    )

    $logDir = Split-Path -Path $LogPath -Parent

    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Remove-Item -Path $LogPath -Confirm:$false -ErrorAction SilentlyContinue

    $logContent = @()
    $logContent += "*************************"
    $logContent += "System Health Information"
    $logContent += "*************************"
    $logContent += "--------------------"
    $logContent += "CPU"
    $logContent += "--------------------"
    $logContent += "Current CPU Usage: $($CpuInformation.CurrentCpuUsagePercentage)"
    $logContent += "Average CPU Usage: $($CpuInformation.AverageCpuUsage)"
    $logContent += ""
    $logContent += "--------------------"
    $logContent += "Memory"
    $logContent += "--------------------"
    $logContent += "Free Memory: $($MemoryInformation.FreeMemory)"
    $logContent += "Used Memory: $($MemoryInformation.UsedMemory) ($($MemoryInformation.UsedMemoryPercentage)%)"
    $logContent += "Total Memory: $($MemoryInformation.TotalMemory)"
    $logContent += ""
    $logContent += "--------------------"
    $logContent += "Disk"
    $logContent += "--------------------"
    foreach ($disk in $DiskInformation) {
        $logContent += "Disk: $($disk.Drive)"
        $logContent += "Free Space: $($disk.FreeSpace) ($($disk.FreeSpacePercentage)%)"
        $logContent += "Used Space: $($disk.UsedSpace)"
        $logContent += "Total Space: $($disk.TotalSpace)"
        $logContent += ""
    }

    $logContent += "--------------------"
    $logContent += "Network"
    $logContent += "--------------------"
    foreach ($network in $NetworkInformation) {
        $logContent += "Adapter: $($network.Name)"
        $logContent += "Bytes Sent: $($network.BytesSent)"
        $logContent += "Bytes Received: $($network.BytesReceived)"
        $logContent += "Unicast Bytes Sent: $($network.UnicastBytesSent)"
        $logContent += "Unicast Bytes Received: $($network.UnicastBytesReceived)"
        $logContent += "Average Ping: $($network.AveragePing)"
        $logContent += ""
    }

    $logContent | Out-File -FilePath $LogPath -Force
}

$cpuInformation = Get-CPUInformation
$memoryInformation = Get-MemoryInformation
$diskInformation = Get-DiskInformation
$networkInformation = Get-NetworkInformation

# Main script execution
# Retrieve system information and generate log file if successful
if ($cpuInformation -and $memoryInformation -and $diskInformation -and $networkInformation) {
    Generate-Log -LogPath $LogPath -CpuInformation $cpuInformation -MemoryInformation $memoryInformation `
    -DiskInformation $diskInformation -NetworkInformation $networkInformation
}
