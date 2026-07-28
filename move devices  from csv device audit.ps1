# Import CSV file
$csvData = Import-Csv -Path "C:\Users\dcadmin\Desktop\UserDetails.csv"

# Iterate through each row in the CSV
foreach ($row in $csvData) {
    $studentOU = $row.OU
    $deviceOU = $row.DeviceOU

    # Skip rows with incomplete identities
    if (-not $studentOU -or -not $deviceOU) {
        Write-Host "Ignoring row with incomplete identity. Student OU: $studentOU, Device OU: $deviceOU"
        continue
    }

    # Skip rows containing 'hccloan' in the student's OU
    if ($deviceOU -like '*hccloan*') {
        Write-Host "Ignoring row with 'hccloan' in student's OU: $studentOU"
        continue
    }

    # Extract Year level from the student's OU
    $yearLevel = ($studentOU -split ',')[1] -replace 'OU=Year ',''

        # Construct the target OU for the device based on the Year level
    if ($yearLevel -ge 6 -and $yearLevel -le 9) {
        $targetOU = "OU=Year $yearLevel,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"
    }
    elseif ($yearLevel -ge 10 -and $yearLevel -le 12) {
        $targetOU = "OU=Year $yearLevel,OU=Senior,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"
    } else {
        Write-Host "Unsupported Year level: $yearLevel"
        continue
    }

    # Move the device to the target OU
    Move-ADObject -Identity "$deviceOU" -TargetPath $targetOU -Verbose
}


