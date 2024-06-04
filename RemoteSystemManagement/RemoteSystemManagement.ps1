param(
    [ValidateSet("ExecuteCommand", "GetSystemInfo", "DeployUpdates", "DeployFiles")]
    [Parameter(Mandatory=$true)]
    [string]$Action,
    [string]$Username,
    [string]$IPAddress,
    [string]$PrivateKeyPath = "$HOME\workspace\PrivateKey.pem",
    [string]$Command = "pwd",
    [string]$LocalDirectory = "$HOME\workspace\deploy",
    [string]$RemoteDirectory = "/home/ubuntu"
)

function Invoke-RemoteCommand {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [Parameter(Mandatory=$true)]
        [string]$IPAddress,
        [Parameter(Mandatory=$true)]
        [string]$PrivateKeyPath,
        [Parameter(Mandatory=$true)]
        [string]$Command
    )

    $computerName = "$Username`@$IPAddress"
    $sshCommand = "ssh -i `"$PrivateKeyPath`" $computerName $Command"

    try {
        Invoke-Expression $sshCommand
    } catch {
        Write-Host "Failed to execute command"
    }
}

function Get-RemoteSystemInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [Parameter(Mandatory=$true)]
        [string]$IPAddress,
        [Parameter(Mandatory=$true)]
        [string]$PrivateKeyPath
    )

    $computerName = "$Username`@$IPAddress"
    $commands = @(
        "uname -a",
        "lsb_release -a",
        "df -h",
        "free -m",
        "uptime",
        "cat /proc/cpuinfo",
        "cat /proc/meminfo"
    )

    try {
        foreach ($command in $commands) {
            $sshCommand = "ssh -i `"$PrivateKeyPath`" $computerName $Command"
            Invoke-Expression $sshCommand
        }
    } catch {
        Write-Host "Failed to execute command"
    }
}

function Deploy-SystemUpdates {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [Parameter(Mandatory=$true)]
        [string]$IPAddress,
        [Parameter(Mandatory=$true)]
        [string]$PrivateKeyPath
    )

    $computerName = "$Username`@$IPAddress"
    $commands = @(
        "sudo apt-get update -y",
        "sudo apt-get upgrade -y",
        "sudo apt-get dist-upgrade -y",
        "sudo apt-get autoremove -y"
    )

    try {
        foreach ($command in $commands) {
            $sshCommand = "ssh -i `"$PrivateKeyPath`" $computerName $Command"
            Invoke-Expression $sshCommand
            Write-Host "Successfully deployed system updates"
        }
    } catch {
        Write-Host "Failed to execute command"
    }
}

function Deploy-Files {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [Parameter(Mandatory=$true)]
        [string]$IPAddress,
        [Parameter(Mandatory=$true)]
        [string]$PrivateKeyPath,
        [Parameter(Mandatory=$true)]
        [string]$LocalDirectory,
        [Parameter(Mandatory=$true)]
        [string]$RemoteDirectory
    )

    $computerName = "$Username`@$IPAddress"
    try {
        $scpCommand = "scp -i `"$PrivateKeyPath`" -r `"$LocalDirectory`" $computerName`:`"$RemoteDirectory`""
        Invoke-Expression $scpCommand
        Write-Host "Successfully deployed files"
    } catch {
        Write-Host "Failed to execute command"
    }  
}

switch ($Action) {
    "ExecuteCommand" { Invoke-RemoteCommand -Username $Username -IPAddress $IPAddress -PrivateKeyPath $PrivateKeyPath -Command $Command }
    "GetSystemInfo" { Get-RemoteSystemInfo -Username $Username -IPAddress $IPAddress -PrivateKeyPath $PrivateKeyPath }
    "DeployUpdates" { Deploy-SystemUpdates -Username $Username -IPAddress $IPAddress -PrivateKeyPath $PrivateKeyPath }
    "DeployFiles" {
        Deploy-Files -Username $Username -IPAddress $IPAddress -PrivateKeyPath $PrivateKeyPath -LocalDirectory $LocalDirectory `
        -RemoteDirectory $RemoteDirectory
    }
}
