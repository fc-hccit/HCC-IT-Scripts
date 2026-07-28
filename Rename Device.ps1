# Remediation Script

# Prefix for the computer name
$namePrefix = "HCC-STA-"

# Get the username of the currently logged-in user
$username = ((Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty "UserName") -split '\\' | Select-Object -Last 1).ToUpper() -replace '[^A-Z0-9]', ''


# Get the current computer name
$currentName = (Get-CimInstance -ClassName Win32_ComputerSystem).Name

# Construct the desired computer name
$newName = "$namePrefix$username"

Try {
    # Rename the computer if the name does not match
    If ($currentName -ne $newName) {
        Rename-Computer -NewName $newName -Force
        Write-Output "Remediation: Computer renamed from '$currentName' to '$newName'."
    } Else {
        Write-Output "Remediation not needed: Computer name is already correct."
    }
} Catch {
    # Output error details if something fails
    Write-Output "Remediation failed: $_"
    Exit 1
}
