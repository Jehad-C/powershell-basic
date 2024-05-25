# Set source and destination directory
param(
    [string]$SrcDirectory="$HOME\workspace\source",
    [string]$DstDirectory="$HOME\workspace\destination"
)

New-Item -Path $SrcDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $DstDirectory -ItemType Directory -Force | Out-Null

# Get all files in the source directory
$files = Get-ChildItem -Path $SrcDirectory -Recurse | Where-Object { $_.FullName -notlike "$DstDirectory*" }

# Organize files to the destination directory
foreach ($file in $files) {
    if ($file.PSIsContainer) {
        continue
    }

    $extension = $file.Extension.TrimStart('.')
    $dstSubDirectory = Join-Path -Path $DstDirectory -ChildPath $extension

    New-Item -Path $dstSubDirectory -ItemType Directory -Force | Out-Null

    $dstPath = Join-Path -Path $dstSubDirectory -ChildPath $file.Name

    Copy-Item -Path $file.FullName -Destination $dstPath -Force
}
