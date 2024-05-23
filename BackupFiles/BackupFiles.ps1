# Set source and destination directory
param(
    [string]$SrcDirectory="$HOME\workspace\source",
    [string]$BKDirectory="$HOME\workspace\bk"
)

New-Item -Path $SrcDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $BKDirectory -ItemType Directory -Force | Out-Null

# Get all files in the source directory
$files = Get-ChildItem -Path $SrcDirectory -Recurse | Where-Object { $_.FullName -notlike "$BKDirectory*" }

# Backup files to the backup directory
$allUpToDate = $true
foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($SrcDirectory.Length).TrimStart('\')
    $dstPath = Join-Path -Path $BKDirectory -ChildPath $relativePath
    $dstDir = Split-Path -Path $dstPath -Parent

    New-Item -Path $dstDir -ItemType Directory -Force | Out-Null

    # Check if the file exists and is updated in the backup directory
    if (-not (Test-Path -Path $dstPath) -or $file.LastWriteTime -gt (Get-Item -Path $dstPath).LastWriteTime) {
        $allUpToDate = $false
        Copy-Item -Path $file.FullName -Destination $dstPath -Force
        Write-Output "Successfully backed up $file to $dstDir"
    }
}

if ($allUpToDate -eq $true) {
    Write-Output "All files are up to date"
}
