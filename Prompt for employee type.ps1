# Define the OU to search
$OU = "OU=Teaching,OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au"

# Function to prompt the user for input
function Prompt-ForEmployeeType {
    param (
        [string]$userName
    )

    Write-Host "User $userName does not have an employeeType entry."
    Write-Host "Please select the type for this user:"
    Write-Host "1. FullTime Staff"
    Write-Host "2. PartTime Staff"
    Write-Host "3. Casual Staff"
    Write-Host "4. No entry"
    
    $selection = Read-Host "Enter your choice (1-4)"

    switch ($selection) {
        1 { return "FullTime Staff" }
        2 { return "PartTime Staff" }
        3 { return "Casual Staff" }
        4 { return $null }
        default {
            Write-Host "Invalid selection. No entry will be made."
            return $null
        }
    }
}

# Retrieve all users from the specified OU
$users = Get-ADUser -Filter * -SearchBase $OU -Properties employeeType

# Loop through each user
foreach ($user in $users) {
    # Check if employeeType is empty or not set
    if (-not $user.employeeType) {
        # Prompt the user for input
        $employeeType = Prompt-ForEmployeeType -userName $user.SamAccountName
        
        if ($employeeType) {
            # Update the employeeType field using the -Replace parameter
            Set-ADUser -Identity $user -Replace @{employeeType = $employeeType}
            Write-Host "Updated $($user.SamAccountName) with EmployeeType $employeeType"
        } else {
            Write-Host "No update made for $($user.SamAccountName)."
        }
    } else {
        Write-Host "$($user.SamAccountName) already has an employeeType entry."
    }
}
