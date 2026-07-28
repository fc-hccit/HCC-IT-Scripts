# Get the current date in the format "dd-MM-yyyy"
$currentDate = Get-Date -Format "dd-MM-yyyy"

# Disabled User Accounts Location

$targetOU = "OU=Disabled User Accounts,DC=hopecc,DC=sa,DC=edu,DC=au"

# Define the folder path where the text files containing the offboarding dates are stored
$folderPath = "C:\Offboarding"

# Get all the text files in the folder that match today's date
$textFiles = Get-ChildItem $folderPath -Filter "*_$currentDate.txt"

if ($textFiles.Count -eq 0) {
    Write-Host "No text files found in '$folderPath' with today's date."
}
else {
    # Loop through each text file
    foreach ($textFile in $textFiles) {
        # Extract the user account from the text file name
        $user = $textFile.Name -replace "_$currentDate.txt$"

        # Disable the user account in Active Directory
        Disable-ADAccount -Identity $user
        Move-ADObject -Identity $user -TargetPath $targetOU
        gam user "$user@hopecc.sa.edu.au" delete groups
        gam update user "$user@hopecc.sa.edu.au" suspended on
        
     }
}
