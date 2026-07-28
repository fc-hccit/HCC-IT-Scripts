Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "User Offboarding Form"
$form.Size = New-Object System.Drawing.Size(400, 200)

# Create a label for user selection
$labelUser = New-Object System.Windows.Forms.Label
$labelUser.Text = "Select a user account:"
$labelUser.Location = New-Object System.Drawing.Point(20, 20)
$labelUser.AutoSize = $true

# Create a drop-down list for user selection
$comboBoxUser = New-Object System.Windows.Forms.ComboBox
$comboBoxUser.Location = New-Object System.Drawing.Point(200, 20)
$comboBoxUser.Width = 150
$comboBoxUser.Sorted = $true

# Get the list of user accounts from Active Directory
$userAccounts = Get-ADUser -Filter * -SearchBase "OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au"
# Populate the user accounts in the drop-down list
foreach ($userAccount in $userAccounts) {
    $comboBoxUser.Items.Add($userAccount.SamAccountName)
}

# Create a label for offboarding date
$labelDate = New-Object System.Windows.Forms.Label
$labelDate.Text = "Select offboarding date:"
$labelDate.Location = New-Object System.Drawing.Point(20, 60)
$labelDate.AutoSize = $true

# Create a date picker for offboarding date
$datePicker = New-Object System.Windows.Forms.DateTimePicker
$datePicker.Location = New-Object System.Drawing.Point(200, 60)
$datePicker.Width = 150
$datePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
$datePicker.CustomFormat = "dd-MM-yyyy"

# Create a button for submitting the form
$buttonSubmit = New-Object System.Windows.Forms.Button
$buttonSubmit.Text = "Submit"
$buttonSubmit.Location = New-Object System.Drawing.Point(150, 120)
$buttonSubmit.Width = 100

# Add event handler for button click event
$buttonSubmit.Add_Click({
    $userSelection = $comboBoxUser.SelectedItem
    $offboardingDate = $datePicker.Value.ToString("dd-MM-yyyy")

    # Define the folder path where the text files containing the offboarding dates will be stored
    $folderPath = "C:\Offboarding"

    # Construct the filename for the text file based on the selected user account and offboarding date
    $filename = "$($userSelection)_$($offboardingDate).txt"

    # Construct the full file path by combining the folder path and filename
    $filePath = Join-Path $folderPath $filename

    # Create the text file with the selected user and offboarding date
    Set-Content -Path $filePath -Value "User: $userSelection`r`nOffboarding Date: $offboardingDate"

    [System.Windows.Forms.MessageBox]::Show("Text file '$filename' has been created in the folder '$folderPath'.", "Success")
})

# Add controls to the form
$form.Controls.Add($labelUser)
$form.Controls.Add($comboBoxUser)
$form.Controls.Add($labelDate)
$form.Controls.Add($datePicker)
$form.Controls.Add($buttonSubmit)

# Show the form
$form.ShowDialog() | Out-Null

# Dispose the form
$form.Dispose()
