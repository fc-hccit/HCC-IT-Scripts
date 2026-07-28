# Import Active Directory module
Import-Module ActiveDirectory

# Set the OU to search
$OU = "OU=Year 2,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"

# Get all users from the OU
$Users = Get-ADUser -Filter * -SearchBase $OU -Properties SamAccountName

# Initialize an array to store the results
$Results = @()

# Loop through each user
foreach ($User in $Users) {
    # Fetch a random password from dinopass
    try {
        $Password = (Invoke-RestMethod -Uri "https://www.dinopass.com/password/simple").Trim()
    } catch {
        Write-Host "Failed to get a password for $($User.SamAccountName). Skipping..."
        continue
    }

    # Set the new password
    try {
        Set-ADAccountPassword -Identity $User.SamAccountName -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
        Set-ADUser -Identity $User.SamAccountName -PasswordNeverExpires $true

        # Store the result
        $Results += [PSCustomObject]@{
            Username = $User.SamAccountName
            Password = $Password
        }

        Write-Host "Password changed for $($User.SamAccountName)"
    } catch {
        Write-Host "Failed to reset password for $($User.SamAccountName): $_"
    }
}

# Export to CSV
$Results | Export-Csv -Path 'C:\Users\ladmin\Desktop\Year2_UserPasswords.csv' -NoTypeInformation
Write-Host "Password reset process completed. Results saved to ‪C:\Users\ladmin\Desktop\Year2_UserPasswords.csv"
