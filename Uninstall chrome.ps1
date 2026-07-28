# Get all Chrome-related services
$chromeServices = Get-Service | Where-Object { $_.DisplayName -like "*Chrome*" -or $_.ServiceName -like "*Chrome*" }

# Stop each Chrome service silently
foreach ($service in $chromeServices) {
    Stop-Service -InputObject $service -Force
    Write-Host "Stopped service: $($service.DisplayName)"
}

Write-Host "All Chrome services have been stopped."



# Define the path to the Chrome installer
$chromeInstallerPath = "C:\Program Files*\Google\Chrome\Application\*\Installer\setup.exe"

# Check if Chrome is installed
if (Test-Path $chromeInstallerPath) {
    # Uninstall Chrome using the specified command
    Start-Process -FilePath $chromeInstallerPath -ArgumentList "-uninstall", "-multi-install", "-chrome", "-system-level" -Wait
    Write-Host "Google Chrome has been uninstalled."
} else {
    Write-Host "Google Chrome is not installed on this system."
}

# Define the path to the Chrome user data folder
$chromeUserDataPath = "C:\Users\*\AppData\Local\Google\Chrome"

# Delete the Chrome user data folder for all users
Get-ChildItem -Path $chromeUserDataPath -Recurse | ForEach-Object {
    Remove-Item $_.FullName -Force -Recurse
}

Write-Host "Chrome user data folders have been deleted for all users."