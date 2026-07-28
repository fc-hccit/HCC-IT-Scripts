# Import the Active Directory module
Import-Module ActiveDirectory

# Path to your CSV file
$csvPath = "c:\users\dcadmin\desktop\job.csv"

# Import the CSV
$users = Import-Csv -Path $csvPath

# Loop through each user
foreach ($user in $users) {
    $fullName = $user.FullName
    $jobTitle = $user.JobTitle

    # Attempt to find user by Full Name
    $adUser = Get-ADUser -Filter * -Properties Title | Where-Object { $_.Name -eq $fullName }


    if ($adUser) {
        try {
            Set-ADUser -Identity $adUser.DistinguishedName -Title $jobTitle 
            Write-Host "Updated $fullName to Job Title '$jobTitle'"
        } catch {
            Write-Warning "Failed to update $fullName : $_"
        }
    } else {
        Write-Warning "User $fullName not found in AD."
    }
}
