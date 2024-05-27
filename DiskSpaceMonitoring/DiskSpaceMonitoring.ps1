param(
    [string]$LogPath="$HOME\workspace\DiskSpace.txt",
    [string]$Threshold="25"
)

function Check-DiskSpace {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath,
        [Parameter(Mandatory=$true)]
        [string]$Threshold
    )

    $logContent = @()
    $logDir = Split-Path -Path $LogPath -Parent

    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Remove-Item -Path $LogPath -Confirm:$false -ErrorAction SilentlyContinue

    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives) {
        $freeSpace = [Math]::Round($drive.Free / 1GB, 2)
        $usedSpace = [Math]::Round($drive.Used / 1GB, 2)
        $totalSpace = $drive.Used + $drive.Free
        $freeSpacePercentage = [Math]::Round($drive.Free / $totalSpace, 4) * 100
        $status = "OK"
        if ($freeSpacePercentage -lt $Threshold) {
            $status = "NOT OK"
        }

        $diskInformation = [PSCustomObject]@{
            Drive = $drive.Name
            FreeSpace = "$freeSpace ($freeSpacePercentage%)"
            Status = $status
        }

        $logContent += $diskInformation
    }

    $logContent | Format-Table -AutoSize | Out-String | Out-File -FilePath $LogPath -Append
    Write-Output "Successfully logged disk information"
}

Check-DiskSpace -LogPath $LogPath -Threshold $Threshold
