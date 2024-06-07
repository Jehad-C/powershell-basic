param(
    [int]$FreeSpacePercentageThreshold = "25",                          # Default free space percentage threshold
    [string]$LogPath = "$HOME\workspace\logs\DiskHealthInformation.log" # Default log path
)

# Function to retrieve disk information
function Get-DiskInformation {
    param(
        [Parameter(Mandatory=$true)]
        [int]$FreeSpacePercentageThreshold # Free space percentage threshold
    )

    try {
        # Retrieve disk information
        $drives = Get-PSDrive -PSProvider FileSystem

        $diskInformation = @()
        foreach ($drive in $drives) {
            $freeSpace           = [Math]::Round($drive.Free / 1GB, 2)
            $usedSpace           = [Math]::Round($drive.Used / 1GB, 2)
            $totalSpace          = $drive.Used + $drive.Free
            $freeSpacePercentage = [Math]::Round($drive.Free / $totalSpace, 4) * 100
            $status              = if ($freeSpacePercentage -lt $FreeSpacePercentageThreshold) { "PASSED" } else { "FAILED" }
            $diskInformation += [PSCustomObject]@{
                Drive               = $drive.Name
                FreeSpace           = $freeSpace
                UsedSpace           = $usedSpace
                FreeSpacePercentage = $freeSpacePercentage
                Status              = $status
            }
        }

        return $diskInformation
    } catch {
        # Handle potential errors during disk information retrieval
        Write-Host 'Failed to retrieve disk information'
        return $null
    }
}

# Function to generate a log file with disk information
function Generate-Log {
    param(
        [Parameter(Mandatory=$true)]
        [array]$DiskInformation, # Disk information object

        [Parameter(Mandatory=$true)]
        [string]$LogPath         # Path to save the log file
    )

    $logDirectory = Split-Path -Path $LogPath -Parent

    # Ensure log directory exists, Remove existing log file if it exists
    New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null

    if (Test-Path -Path $LogPath) {
        Remove-Item -Path $LogPath -Confirm:$false
    }

    # Prepare log content
    $logContent = @()
    $logContent += "********************"
    $logContent += "Disk Information"
    $logContent += "********************"
    $logContent += $DiskInformation | Format-Table -AutoSize

    try {
        # Write log content to file
        $logContent | Out-File -FilePath $LogPath
        Write-Host 'Successfully logged disk information'
    } catch {
        # Handle potential errors during disk information logging
        Write-Host 'Failed to log disk information'
    }    
}

# Main script execution
# Retrieve disk information and generate log file if successful
$diskInformation = Get-DiskInformation -FreeSpacePercentageThreshold $FreeSpacePercentageThreshold
if ($diskInformation) {
    Generate-Log -DiskInformation $diskInformation -LogPath $LogPath
}
