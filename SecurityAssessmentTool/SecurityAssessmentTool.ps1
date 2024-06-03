param(
    [string]$LogPath="$HOME/workspace/SecurityAssessment.txt"
)

function Check-OpenPorts {
	$openPorts = Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" } | Select-Object LocalAddress, LocalPort
    return $openPorts
}

function Check-ExpiredPasswords {
    $users = Get-LocalUser
    $expiredPasswords = @()
    foreach ($user in $users) {
        if ($user.PasswordExpires -eq $false) {
            $expiredPasswords += $user.Name
        }
    }

    return $expiredPasswords
}

function Check-OutdatedSoftware {
    $registryUninstallPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $outdatedSoftwares = @()
    $softwares = Get-ItemProperty -Path $registryUninstallPath |
    Select-Object DisplayName, DisplayVersion, InstallDate, Publisher

    foreach ($software in $softwares) {
        if ($software.DisplayName) {
            $installedDate = $software.InstallDate
            if ($installedDate) {
                $installedDate = [DateTime]::ParseExact($installedDate, "yyyyMMdd", $null)
                $threshold = (Get-Date).AddMonths(-6)
                if ($installedDate -le $threshold) {
                    $outdatedSoftwares += [PSCustomObject]@{
                        Name = $software.DisplayName
                        Version = $software.DisplayVersion
                        InstallDate = $software.InstallDate
                    }                
                }
            } else {
                $outdatedSoftwares += [PSCustomObject]@{
                    Name = $software.DisplayName
                    Version = $software.DisplayVersion
                    InstallDate = $software.InstallDate
                }
            }
        }
    }
    
    return $outdatedSoftwares
}

function Generate-Report {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath,
        [Array]$Connections,
        [Array]$ExpiredPasswords,
        [Array]$OutdatedSoftwares
    )

    $logDir = Split-Path -Path $LogPath -Parent

    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Remove-Item -Path $LogPath -Confirm:$false -ErrorAction SilentlyContinue

    $logContent = @()
    $logContent += "********************"
    $logContent += "Security Assessment"
    $logContent += "********************"
    if ($Connections) {
        $logContent += "--------------------"
        $logContent += "Open Ports"
        $logContent += "--------------------"
        $logContent += $Connections | Format-Table -AutoSize
        $logContent += ""
    }

    if ($ExpiredPasswords) {
        $logContent += "--------------------"
        $logContent += "Expired Passwords"
        $logContent += "--------------------"
        $logContent += $ExpiredPasswords | Format-Table -AutoSize
        $logContent += ""
    }

    if ($OutdatedSoftwares) {
        $logContent += "--------------------"
        $logContent += "Outdated Softwares"
        $logContent += "--------------------"
        $logContent += $OutdatedSoftwares | Format-Table -AutoSize
        $logContent += ""
    }

    $logContent | Out-File -FilePath $LogPath -Force
}


$connections = Check-OpenPorts
$expiredPasswords = Check-ExpiredPasswords
$outdatedSoftwares = Check-OutdatedSoftware

Generate-Report -LogPath $LogPath -Connections $connections -ExpiredPasswords $expiredPasswords -OutdatedSoftwares $outdatedSoftwares
