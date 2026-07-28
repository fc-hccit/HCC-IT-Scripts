# Define the path to the desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Get all files on the desktop, except icons
$files = Get-ChildItem -Path $desktopPath -File | Where-Object {$_.Extension -ne ".lnk"}

# Group the files by extension
$filesByExtension = $files | Group-Object -Property Extension

# Create a folder for each extension
$filesByExtension | ForEach-Object {
    $extension = $_.Name
    $extensionFolder = Join-Path -Path $desktopPath -ChildPath $extension.TrimStart('.')
    New-Item -ItemType Directory -Path $extensionFolder -ErrorAction SilentlyContinue
}

# Move each file into the appropriate extension folder
$files | ForEach-Object {
    $extension = $_.Extension.TrimStart('.')
    $extensionFolder = Join-Path -Path $desktopPath -ChildPath $extension
    Move-Item $_.FullName $extensionFolder
}
