Import-Module ActiveDirectory

# Configuration
$YearLevels = @{
    "Middle School" = 6..9   # Year 6 to 9
    "Senior School" = 10..12  # Year 10 to 12
    "Primary School" = 3..5   # Year 3 to 5
    "Junior School" = 0..2    # Year 0 to 2
}

foreach ($School in $YearLevels.Keys) {
    # Iterate over the years in each school category
    foreach ($Year in $YearLevels[$School]) {
        # Define the OU for the current year based on the school category
        $OU = "OU=Year $Year,OU=$School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
        
        # Define the group name for the current year
        $ADGroupName = "Year $Year Students"
        
        # Retrieve users from the specified OU
        Write-Host "Fetching users from $OU..."
        $UsersInOU = Get-ADUser -Filter * -SearchBase $OU -SearchScope Subtree | Select-Object -ExpandProperty SamAccountName

        if (-not $UsersInOU) {
            Write-Warning "No users found in the specified OU for Year $Year in $School. Skipping."
            continue
        }

        # Retrieve current members of the AD group
        Write-Host "Fetching current members of the AD group '$ADGroupName'..."
        $GroupMembers = Get-ADGroupMember -Identity $ADGroupName -Recursive | Where-Object { $_.objectClass -eq 'user' } | Select-Object -ExpandProperty SamAccountName

        # Determine users to add and remove
        $UsersToAdd = $UsersInOU | Where-Object { $_ -notin $GroupMembers }
        $UsersToRemove = $GroupMembers | Where-Object { $_ -notin $UsersInOU }

        # Add users to the AD group
        if ($UsersToAdd.Count -gt 0) {
            Write-Host "Adding users to the AD group..."
            foreach ($User in $UsersToAdd) {
                try {
                    Add-ADGroupMember -Identity $ADGroupName -Members $User -ErrorAction Stop
                    Write-Host "Added user: $User"
                } catch {
                    Write-Warning "Failed to add user: $User. Error: $_"
                }
            }
        } else {
            Write-Host "No users to add to the AD group for Year $Year in $School."
        }

        # Remove users from the AD group
        if ($UsersToRemove.Count -gt 0) {
            Write-Host "Removing users from the AD group..."
            foreach ($User in $UsersToRemove) {
                try {
                    Remove-ADGroupMember -Identity $ADGroupName -Members $User -Confirm:$false -ErrorAction Stop
                    Write-Host "Removed user: $User"
                } catch {
                    Write-Warning "Failed to remove user: $User. Error: $_"
                }
            }
        } else {
            Write-Host "No users to remove from the AD group for Year $Year in $School."
        }

        Write-Host "Synchronization complete for Year $Year in $School."
    }
}
