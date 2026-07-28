$deviceName = "PT-P700"

# Function to check if the device is connected
function IsDeviceConnected {
    $devices = Get-WmiObject Win32_PnPEntity | Where-Object {$_.Name -eq $deviceName}
    return $devices.Count -gt 0
}

# Loop until the device is connected
while (-not (IsDeviceConnected)) {
    # Wait for 5 seconds before checking again
    write-host "device not connected"
    Start-Sleep -Seconds 5
}

# Function to get the drive letter of the connected device
function GetDeviceDriveLetter {
    $drive = Get-WmiObject Win32_Volume | Where-Object {$_.Label -eq $deviceName} | Select-Object -First 1 -ExpandProperty DriveLetter
    return $drive
}

$driveLetter = GetDeviceDriveLetter


# Execute your desired action here
Start-Process -FilePath "$driveLetter\PTLITE10.EXE"