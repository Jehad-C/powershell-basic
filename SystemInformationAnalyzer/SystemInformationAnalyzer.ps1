param(
    [string]$LogPath = "$HOME\workspace\logs\SystemInformation.log" # Default log path
)

# Function to retrieve system information
function Get-SystemInformation {
    try {
        $properties = @(
            'CsName',                # Computer name
            'WindowsVersion',        # Windows version
            'WindowsBuildLabEx',     # Detailed Windows build info
            'CsManufacturer',        # Computer manufacturer
            'CsModel',               # Computer model
            'CsProcessors',          # Processor information
            'CsTotalPhysicalMemory', # Total physical memory
            'BiosVersion',           # BIOS version
            'BiosReleaseDate'        # BIOS release date
        )

        # Retrieve computer information
        $computerInfo = Get-ComputerInfo -Property $properties
        return $computerInfo
    } catch {
        Write-Host 'Failed to retrieved system information'
        return $null
    }
}

# Function to generate a log file with system information
function Generate-Log {
    param(
        [PSCustomObject]$SystemInformation, # System information object
        [string]$LogPath                    # Path to save the log file
    )

    $logDirectory = Split-Path -Path $LogPath -Parent

    # Ensure log directory exists, Remove existing log file if it exists
    New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    if (Test-Path -Path $LogPath) {
        Remove-Item -Path $LogPath -Confirm:$false
    }

    $physicalMemory = "$([Math]::Round($SystemInformation.CsTotalPhysicalMemory / 1GB, 2)) GB" # Convert to GB

    # Prepare log content
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
        # Write log content to file
        $logContent | Out-File -FilePath $LogPath
        Write-Host 'Successfully logged system information'
    } catch {
        # Handle potential errors during system information retrieval 
        Write-Host 'Failed to logged system information'
    }
}

# Main script execution
# Retrieve system information and generate log file if successful
$systemInformation = Get-SystemInformation
if ($systemInformation) {
    Generate-Log -SystemInformation $systemInformation -LogPath $LogPath
}
