Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Add Student to AD"
$form.Size = New-Object System.Drawing.Size(400, 250)
$form.StartPosition = "CenterScreen"

# Year Level Dropdown
$yearLabel = New-Object System.Windows.Forms.Label
$yearLabel.Text = "Year Level:"
$yearLabel.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($yearLabel)

$yearDropdown = New-Object System.Windows.Forms.ComboBox
$yearDropdown.Location = New-Object System.Drawing.Point(100, 18)
$yearDropdown.Size = New-Object System.Drawing.Size(250, 20)
$yearDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$yearDropdown.Items.AddRange((0..12 | ForEach-Object { "$_" }))
$form.Controls.Add($yearDropdown)

# Full Name Field
$nameLabel = New-Object System.Windows.Forms.Label
$nameLabel.Text = "Full Name:"
$nameLabel.Location = New-Object System.Drawing.Point(10, 50)
$form.Controls.Add($nameLabel)

$nameBox = New-Object System.Windows.Forms.TextBox
$nameBox.Location = New-Object System.Drawing.Point(100, 48)
$nameBox.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($nameBox)

# Submit Button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Add to AD"
$submitButton.Location = New-Object System.Drawing.Point(100, 80)
$submitButton.Add_Click({
    $fullName = $nameBox.Text
    $yearLevel = $yearDropdown.SelectedItem
    
    if (-not $fullName -or -not $yearLevel) {
        [System.Windows.Forms.MessageBox]::Show("Please fill in all fields.", "Error", "OK", "Error")
        return
    }
    
    # Generate username (firstname.lastname format)
    $names = $fullName -split " "
    $username = "$($names[0]).$($names[-1])" -replace "[^a-zA-Z0-9]", ""
    $username = $username.ToLower()
    
    # Generate email and employee ID
    $email = "$username@student.hopecc.sa.edu.au"
    $employeeID = "HCC$((Get-Random -Minimum 100000 -Maximum 999999))"
    
    # Generate password
    $simplepass = Invoke-RestMethod -Uri https://www.dinopass.com/password/simple
    
    # Determine OU based on year level
    if ($yearLevel -ge 10) {
        $OU = "OU=Year $yearLevel,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
    } elseif ($yearLevel -ge 6) {
        $OU = "OU=Year $yearLevel,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
    } elseif ($yearLevel -ge 3) {
        $OU = "OU=Year $yearLevel,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
    } else {
        $OU = "OU=Year $yearLevel,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
    }
    
    try {
        New-ADUser -Name $fullName -GivenName $names[0] -Surname $names[-1] -SamAccountName $username -UserPrincipalName "$email" -Path $OU -AccountPassword (ConvertTo-SecureString -AsPlainText $simplepass -Force) -Enabled $true -Description "2025 Year $yearLevel" -Department "Year $yearLevel" -Company "Hope Christian College" -EmployeeID $employeeID
        
        Set-ADUser -Identity $username -Replace @{employeeType="Student"}
        Set-ADUser -Identity $username -Replace @{Comment="##Current Main"}
        
        # Add user to groups
        Add-ADGroupMember -Identity "Students" -Members $username
        Add-ADGroupMember -Identity "Year $yearLevel Students" -Members $username
        
        [System.Windows.Forms.MessageBox]::Show("User $username added successfully!", "Success", "OK", "Information")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error adding user to AD: $_", "Error", "OK", "Error")
    }
})
$form.Controls.Add($submitButton)

# Show Form
$form.ShowDialog()
