param(
    [string]$LogPath = "$HOME\workspace\Cleanup.txt",
    [string]$TemporaryDir = "$HOME\workspace\temporary",
    [string]$PrefetchDir = "$env:SystemRoot\Prefetch",
    [string]$WindowsUpdateDir = "$env:SystemRoot\SoftwareDistribution\Download"
)

function Clear-TemporaryFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        $files = Get-ChildItem -Path $Path -Recurse | Remove-Item -Recurse -ErrorAction SilentlyContinue -Force
        return $true
    } catch {
        return $false
    }
}

function Clear-PrefetchFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        $files = Get-ChildItem -Path $Path -Recurse | Remove-Item -Recurse -ErrorAction SilentlyContinue -Force
        return $true
    } catch {
        return $false
    }
}

function Clear-WindowsUpdateFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        $files = Get-ChildItem -Path $Path -Recurse | Remove-Item -Recurse -ErrorAction SilentlyContinue -Force
        return $true
    } catch {
        return $false
    }
}

function Clear-RecycleBinFiles {
    try {
        Clear-RecycleBin -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Generate-Report {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath,
        [Parameter(Mandatory=$true)]
        [boolean]$IsTemporaryFilesCleared,
        [Parameter(Mandatory=$true)]
        [boolean]$IsPrefetchFilesCleared,
        [Parameter(Mandatory=$true)]
        [boolean]$IsWindowsUpdateFilesCleared,
        [Parameter(Mandatory=$true)]
        [boolean]$IsRecycleBinFilesCleared
    )

    $logDir = Split-Path -Path $LogPath -Parent

    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Remove-Item -Path $LogPath -Confirm:$false -ErrorAction SilentlyContinue

    $logContent = @()
    $logContent += "*************************"
    $logContent += "Security Cleanup Tool"
    $logContent += "*************************"
    if ($IsTemporaryFilesCleared) {
        $logContent += "Directory: Temporary - Status: Cleared"
    }

    if ($IsPrefetchFilesCleared) {
        $logContent += "Directory: Prefetch - Status: Cleared"
    }

    if ($IsWindowsUpdateFilesCleared) {
        $logContent += "Directory: Windows Update - Status: Cleared"
    }

    if ($IsRecycleBinFilesCleared) {
        $logContent += "Directory: Recycle Bin - Status: Cleared"
    }

    $logContent | Out-File -FilePath $LogPath -Force
}

$IsTemporaryFilesCleared = Clear-TemporaryFiles -Path $TemporaryDir
$IsPrefetchFilesCleared = Clear-PrefetchFiles -Path $PrefetchDir
$IsWindowsUpdateFilesCleared = Clear-WindowsUpdateFiles -Path $WindowsUpdateDir
$IsRecycleBinFilesCleared = Clear-RecycleBinFiles

Generate-Report -LogPath $LogPath -IsTemporaryFilesCleared $IsTemporaryFilesCleared -IsPrefetchFilesCleared $IsPrefetchFilesCleared `
-IsWindowsUpdateFilesCleared $IsWindowsUpdateFilesCleared -IsRecycleBinFilesCleared $IsRecycleBinFilesCleared
