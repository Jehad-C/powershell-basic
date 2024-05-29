param(
    [string]$SoftwareName="Google Chrome",
    [string]$LatestVersionUrl="https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Windows",
    [string]$LatestVersionResponseKey="version",
    [string]$LatestVersionDownloadUrl="https://dl.google.com/chrome/install/latest/chrome_installer.exe",
    [string]$InstallationPath="$HOME/workspace/chrome_installer.exe"
)

function Get-CurrentVersion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SoftwareName
    )

    $registryUninstallPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
    $currentVersion = $null

    $keys = Get-ChildItem -Path $registryUninstallPath
    foreach ($key in $keys) {
        $properties = Get-ItemProperty -Path $key.PSPath | Select-Object DisplayName, DisplayVersion
        if ($properties.DisplayName -eq $SoftwareName) {
            $currentVersion = $properties.DisplayVersion
        }
    }

    Write-Host "Software: $SoftwareName - Current Version: $currentVersion"

    return $currentVersion
}

function Get-LatestVersion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SoftwareName,
        [Parameter(Mandatory=$true)]
        [string]$LatestVersionUrl,
        [Parameter(Mandatory=$true)]
        [string]$LatestVersionResponseKey
    )

    $response = Invoke-RestMethod -Uri $LatestVersionUrl
    $latestVersion = $response[0].$LatestVersionResponseKey
    Write-Host "Software: $SoftwareName - Latest Version: $latestVersion"

    return "$latestVersion"
}

function Install-Updates {
    param(
        [string]$LatestVersionDownloadUrl,
        [string]$InstallationPath
    )

    Invoke-WebRequest -Uri $LatestVersionDownloadUrl -OutFile $InstallationPath
    Start-Process -FilePath $InstallationPath -ArgumentList "/install" -Wait
    Remove-Item $InstallationPath

    Write-Host "Google Chrome is updated to the latest version"
}

$currentVersion = Get-CurrentVersion -SoftwareName $SoftwareName
$latestVersion = Get-LatestVersion -SoftwareName $SoftwareName -LatestVersionUrl $LatestVersionUrl `
-LatestVersionResponseKey $LatestVersionResponseKey

if ($currentVersion) {
    if ($currentVersion -ne $LatestVersionUrl) {
        $confirmUpdate = Read-Host "Do you want to install updates for Google Chrome? (Y/N)"
        if ($confirmUpdate -eq "Y" -or $confirmUpdate -eq "y") {
            Install-Updates -LatestVersionDownloadUrl $LatestVersionDownloadUrl -InstallationPath $InstallationPath
        } else {
            Write-Host "Google Chrome update is cancelled"
        }
    } else {
        Write-Host "Google Chrome is up to date"
    }
} else {
    Write-Host "Google Chrome is not installed"
}
