﻿param(
    [string]$SourceDirectory = "$HOME\workspace\source", # Default source directory
    [string]$BackupDirectory = "$HOME\workspace\backup"  # Default backup directory
)

# Function to retrieve files from the source directory
function Get-Files {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceDirectory, # Source directory

        [Parameter(Mandatory=$true)]
        [string]$BackupDirectory  # Backup directory
    )

    # Ensure source directory exists
    New-Item -Path $SourceDirectory -ItemType Directory -Force | Out-Null

    try {
        # Retrieve files excluding the backup directory
        $files = Get-ChildItem -Path $SourceDirectory -Recurse | Where-Object { $_.FullName -notlike "$BackupDirectory" }
        return $files
    } catch {
        # Handle potential errors during files retrieval
        Write-Host "Failed to retrieve files"
        return $null
    }
}

# Function to backup files
function Process-BackupFiles {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Files,            # Array of files to backup

        [Parameter(Mandatory=$true)]
        [string]$SourceDirectory, # Source directory

        [Parameter(Mandatory=$true)]
        [string]$BackupDirectory  # Backup directory
    )

    # Ensure backup directory exists
    New-Item -Path $BackupDirectory -ItemType Directory -Force | Out-Null

    $modified = $false
    foreach ($file in $Files) {
        $relativePath = $file.FullName.Substring($SourceDirectory.Length).TrimStart('\')
        $destinationPath = Join-Path -Path $BackupDirectory -ChildPath $relativePath
        $destinationDirectory = Split-Path -Path $destinationPath -Parent

        # Ensure destination directory exists
        New-Item -Path $destinationDirectory -ItemType Directory -Force | Out-Null

        # Check if files are modified
        if (-not (Test-Path -Path $DestinationPath) -or $File.LastWriteTime -gt (Get-Item -Path $DestinationPath).LastWriteTime) {
            $modified = $true

            try {
                # Backup file
                Copy-Item -Path $file.FullName -Destination $destinationPath -Force
                Write-Output "Successfully backed up file"
            } catch {
                # Handle potential errors during file backup 
                Write-Output "Failed to backup file"
            }
        }
    }

    if ($modified -eq $false) {
        Write-Output "All files are up to date"
    }
}

# Main script execution
# Retrieve files from the source directory and backup if successful
$files = Get-Files -SourceDirectory $SourceDirectory -BackupDirectory $BackupDirectory
if ($files) {
    Process-BackupFiles -Files $files -SourceDirectory $SourceDirectory -BackupDirectory $BackupDirectory
}
