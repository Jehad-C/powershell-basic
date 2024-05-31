param(
    [ValidateSet("Start", "Stop", "Restart", "Monitor")]
    [Parameter(Mandatory=$true)]
    [string]$Action,
    [Parameter(Mandatory=$true)]
    [string[]]$ServiceNames,
    [string]$LogPath="$HOME/workspace/ServiceLog.txt"
)

function Start-Services {
    param(
        [string[]]$ServiceNames
    )

    foreach ($serviceName in $ServiceNames) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $service) {
            Write-Host "Service: $serviceName is not found"
        }

        Start-Service -Name $serviceName

        Write-Host "Service: $serviceName started successfully"
    }
}

function Stop-Services {
    param(
        [string[]]$ServiceNames
    )

    foreach ($serviceName in $ServiceNames) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $service) {
            Write-Host "Service: $serviceName is not found"
        }

        Stop-Service -Name $serviceName

        Write-Host "Service: $serviceName stopped successfully"
    }
}

function Restart-Services {
    param(
        [string[]]$ServiceNames
    )

    foreach ($serviceName in $ServiceNames) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $service) {
            Write-Host "Service: $serviceName is not found"
        }

        Restart-Service -Name $serviceName

        Write-Host "Service: $serviceName restarted successfully"
    }
}

function Monitor-Services {
    param(
        [string[]]$ServiceNames,
        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    $logDir = Split-Path -Path $LogPath -Parent

    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Remove-Item -Path $LogPath -Confirm:$false -ErrorAction SilentlyContinue

    $logContent = @()
    foreach ($serviceName in $ServiceNames) {
        $service = Get-Service -Name $serviceName
        if (-not $service) {
            $logContent += "Service: $ServiceName - Status: `"N/A`""
        } elseif ($service.Status -eq "Running") {
            $logContent += "Service: $ServiceName - Status: `"Running`""
        } else {
            Start-Service -Name $ServiceName
            $logContent += "Service: $ServiceName - Status: `"Restarted`""
        }
    }

    $logContent | Out-File -FilePath $LogPath -Append

    Write-Host "Successfully logged service information"
}

switch ($Action) {
    "Start" { Start-Services -ServiceNames $ServiceNames }
    "Stop" { Stop-Services -ServiceNames $ServiceNames }
    "Restart" { Restart-Services -ServiceNames $ServiceNames }
    "Monitor" { Monitor-Services -ServiceNames $ServiceNames -LogPath $LogPath }
}
