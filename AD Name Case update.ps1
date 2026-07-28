
# Set the target OU
$ouPath = "OU=Year 0,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"

# Get all users in the specified OU
$users = Get-ADUser -Filter * -SearchBase $ouPath

# Iterate through each user and update the case of the first letter of the first and last name, display name, and user logon name
foreach ($user in $users) {
    # Get the current first and last name
    $firstName = $user.GivenName
    $lastName = $user.Surname

    # Update the case of the first letter
    $newFirstName = $firstName.Substring(0,1).ToUpper() + $firstName.Substring(1).ToLower()
    $newLastName = $lastName.Substring(0,1).ToUpper() + $lastName.Substring(1).ToLower()

    # Update the display name
    $newDisplayName = "$newFirstName $newLastName"

    # Update the User Logon Name
    $newSamAccountName = $newFirstName.Substring(0,1).ToLower() + $newLastName.ToLower()

    # Set the updated names for the user
    Set-ADUser -Identity $user.SamAccountName -GivenName $newFirstName -Surname $newLastName -DisplayName $newDisplayName -SamAccountName $newSamAccountName

    # Display the updated names
    Write-Host "Updated names for $($user.SamAccountName): $newFirstName $newLastName (Display Name: $newDisplayName, User Logon Name: $newSamAccountName)"
}
