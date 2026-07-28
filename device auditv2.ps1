# Specify the OUs
$middleSchoolOU = "OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
$seniorSchoolOU = "OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
$devicesOU = "OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"

# Specify the excluded workstations
$excludedWorkstations = @("*hcc-dc0*", "*acerl4620*", "*AVZ4860-MUS*", "*HP430*")

# Specify the output CSV file path
$outputCsvPath = "C:\Users\dcadmin\Desktop\UserDetails.csv"

# Initialize an array to store results
$results = @()

# Function to check if a device is in the excluded list
function IsExcludedDevice($deviceName) {
    return $excludedWorkstations | Where-Object { $deviceName -like $_ }
}

# Function to get non-excluded logon workstations
function GetNonExcludedLogonWorkstations($logonWorkstations) {
    return $logonWorkstations -split ',' | Where-Object { -not (IsExcludedDevice $_.Trim()) } | ForEach-Object { $_.Trim() }
}

# Function to get the OU of a device from a list of workstations
function GetDeviceOU($deviceList) {
    $ouList = @()

    foreach ($deviceName in $deviceList) {
        $trimmedDeviceName = $deviceName.Trim()

        # Check if the trimmed device name is not null or empty
        if (-not [string]::IsNullOrEmpty($trimmedDeviceName)) {
            $device = Get-ADComputer $trimmedDeviceName -ErrorAction Ignore 
            if ($device) {
                $ouList += $device.DistinguishedName
            } else {
                $ouList += "Device not found"
            }
        }
    }

    if ($ouList -eq "") {
        return "No Workstations Available"
    }

    return $ouList -join ','
}

# Process users in Middle School OU
$middleSchoolUsers = Get-ADUser -Filter * -SearchBase $middleSchoolOU -Properties Name, DistinguishedName, LogonWorkstations 

foreach ($user in $middleSchoolUsers) {
    $logonWorkstations = GetNonExcludedLogonWorkstations $user.LogonWorkstations
    $deviceOU = GetDeviceOU $logonWorkstations

    $results += [PSCustomObject]@{
        Name = $user.Name
        OU = $user.DistinguishedName
        LogonWorkstation = $logonWorkstations -join ','
        DeviceOU = $deviceOU
    }
}

# Process users in Senior School OU
$seniorSchoolUsers = Get-ADUser -Filter * -SearchBase $seniorSchoolOU -Properties Name, DistinguishedName, LogonWorkstations 

foreach ($user in $seniorSchoolUsers) {
    $logonWorkstations = GetNonExcludedLogonWorkstations $user.LogonWorkstations
    $deviceOU = GetDeviceOU $logonWorkstations

    $results += [PSCustomObject]@{
        Name = $user.Name
        OU = $user.DistinguishedName
        LogonWorkstation = $logonWorkstations -join ','
        DeviceOU = $deviceOU
    }
}

# Export results to CSV
$results | Export-Csv -Path $outputCsvPath -NoTypeInformation

Write-Host "Script execution completed. Results exported to: $outputCsvPath"
