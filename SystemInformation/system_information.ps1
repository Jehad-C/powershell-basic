# Set workspace directory
$WORKSPACE = "$HOME\workspace"

if (!(Test-Path -Path $WORKSPACE)) {
    New-Item -Path $HOME -ItemType Directory -Name workspace | Out-Null
}

Set-Location $WORKSPACE

try {
    # Get system information
    $computerInfo = Get-ComputerInfo -Property `
        CsName, `
        WindowsVersion, `
        WindowsBuildLabEx, `
        CsManufacturer, `
        CsModel, `
        CsProcessors, `
        CsTotalPhysicalMemory, `
        BiosVersion, `
        BiosReleaseDate

    $physicalMemory = "$([Math]::Round($computerInfo.CsTotalPhysicalMemory / 1GB, 2)) GB"

    $systemInfo = @"
Computer Name: $($computerInfo.CsName)
OS Version: $($computerInfo.WindowsVersion)
OS Build: $($computerInfo.WindowsBuildLabEx)
Manufacturer: $($computerInfo.CsManufacturer)
Model: $($computerInfo.CsModel)
Processor: $($computerInfo.CsProcessors)
Total Physical Memory: $physicalMemory
Bios Version: $($computerInfo.BiosVersion)
Bios Release Date: $($computerInfo.BiosReleaseDate)
"@

    $filePath = Join-Path -Path $WORKSPACE -ChildPath 'system_info.txt'

    # Write system information to text file
    $systemInfo | Out-File -FilePath $filePath

    Write-Output "System information saved to: $filePath"
} catch {
    Write-Output "Failed to retrieve system information. Details: $_"
}
