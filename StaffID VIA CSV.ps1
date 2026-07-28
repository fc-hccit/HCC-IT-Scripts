Add-Type -AssemblyName System.Windows.Forms

# Create and configure the OpenFileDialog
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Title = "Select a CSV File"
$fileDialog.Filter = "CSV Files (*.csv)|*.csv"
$fileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $csvPath = $fileDialog.FileName
    Write-Host "Selected file: $csvPath"

    # Path to the error log file
    $errorLogPath = "C:\Users\dcadmin\Desktop\ErrorLog.txt"

    # Ensure the error log file is empty before starting
    Clear-Content -Path $errorLogPath -ErrorAction SilentlyContinue

    # Import the CSV file
    $users = Import-Csv -Path $csvPath

    # Loop through each user in the CSV
    foreach ($user in $users) {
        try {
            # Construct the filter to find the user in AD
            $filter = "(&(givenName=$($user.FirstName))(sn=$($user.Surname)))"

            # Search for the user in AD
            $adUser = Get-ADUser -LDAPFilter $filter -Properties employeeID

            if ($adUser) {
                # Append HCC prefix to the EmployeeID
                $newEmployeeID = "HCC$($user.EmployeeID)"

                # Update the employeeID field
                Set-ADUser -Identity $adUser.DistinguishedName -EmployeeID $newEmployeeID
                Write-Host "Updated EmployeeID for $($user.FirstName) $($user.Surname) to $newEmployeeID"
            } else {
                # Log warning if user not found
                $warning = "User $($user.FirstName) $($user.Surname) not found in Active Directory."
                Write-Warning $warning
                $warning | Out-File -Append -FilePath $errorLogPath
            }
        } catch {
            # Log any unexpected errors
            $errorMessage = "Error updating EmployeeID for $($user.FirstName) $($user.Surname): $($_.Exception.Message)"
            Write-Error $errorMessage
            $errorMessage | Out-File -Append -FilePath $errorLogPath
        }
    }
} else {
    Write-Host "File selection canceled. Exiting script."
}
