param(
    [string]$Username,
    [string]$Password,
    [string]$KeyPairPath = "$HOME\workspace\secret\KeyPair.pem",
    [string]$Command = "pwd",
    [string]$SourceDirectory = "$HOME\workspace\source",
    [string]$DestinationDirectory = "$HOME\workspace\destination",
    [string]$RemoteDirectory = "/home/ubuntu/test",
    [string]$LogPath = "$HOME\workspace\logs\SyncFiles.log",
    [switch]$IsRemote
)

New-Item -Path $SrcDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $DstDirectory -ItemType Directory -Force | Out-Null

function Sync-LocalToLocal {
    param(
    [string]$SourceDirectory,
    [string]$DestinationDirectory,
    [string]$LogPath
    )

    $options = @("/MIR", "/R:3", "/W:5", "/NP", "/LOG+:$LogPath", "/XD", ".git")
    $robocopyCommand = "robocopy $SourceDirectory $DestinationDirectory $options"
    try {
        Invoke-Expression $robocopyCommand
        Write-Host "Successfully synced the files"
    } catch {
        Write-Host "Failed to sync the files"
    }
}

function Sync-LocalToRemote {
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

if ($IsRemote) {
    Sync-LocalToRemote
} else {
    Sync-LocalToLocal -SourceDirectory $SourceDirectory -DestinationDirectory $DestinationDirectory -LogPath $LogPath
}
