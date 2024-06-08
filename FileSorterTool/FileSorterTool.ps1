param(
    [string]$SourceDirectory = "$HOME\workspace\source",          # Default source directory
    [string]$DestinationDirectory = "$HOME\workspace\destination" # Default destination directory
)

# Function to retrieve files from the source directory
function Get-Files {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceDirectory,      # Source directory

        [Parameter(Mandatory=$true)]
        [string]$DestinationDirectory  # Destination directory
    )

    # Ensure the source directory exists
    New-Item -Path $SourceDirectory -ItemType Directory -Force | Out-Null

    try {
        # Retrieve files, excluding the destination directory
        $files = Get-ChildItem -Path $SourceDirectory -Recurse | Where-Object { $_.FullName -notlike "$DestinationDirectory" }
        return $files
    } catch {
        # Handle potential errors during file retrieval
        Write-Host "Failed to retrieve files"
        return $null
    }
}

# Function to organize files from the source directory to the destination directory
function Organize-Files {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Files,                # Array of files to organize

        [Parameter(Mandatory=$true)]
        [string]$SourceDirectory,     # Source directory

        [Parameter(Mandatory=$true)]
        [string]$DestinationDirectory # Destination directory
    )

    # Ensure the destination directory exists
    New-Item -Path $DestinationDirectory -ItemType Directory -Force | Out-Null

    try {
        foreach ($file in $Files) {
            # Skip folders
            if ($file.PSIsContainer) {
                continue
            }

            $relativePath = $file.FullName.Substring($SourceDirectory.Length).TrimStart('\')
            $extension = $file.Extension.TrimStart('.')
            $destinationSubDirectory = Join-Path -Path $DestinationDirectory -ChildPath $extension
            $destinationPath = Join-Path -Path $destinationSubDirectory -ChildPath $relativePath

            # Ensure the destination subdirectory exists
            New-Item -Path $destinationSubDirectory -ItemType Directory -Force | Out-Null


            # Copy the file
            Copy-Item -Path $file.FullName -Destination $destinationPath -Force
        }

        Write-Host "Successfully organized files"
    } catch {
        # Handle potential errors during file copying
        Write-Host "Failed to organize files"
    }
}

# Main script execution
# Retrieve files from the source directory and organize them if successful
$files = Get-Files -SourceDirectory $SourceDirectory -DestinationDirectory $DestinationDirectory
if ($files) {
    Organize-Files -Files $files -SourceDirectory $SourceDirectory -DestinationDirectory $DestinationDirectory
}
