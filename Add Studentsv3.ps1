Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Add Students to AD"
$form.Size = New-Object System.Drawing.Size(450, 400)
$form.StartPosition = "CenterScreen"

# Labels
$yearLabel = New-Object System.Windows.Forms.Label
$yearLabel.Text = "Year Level:"
$yearLabel.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($yearLabel)

$nameLabel = New-Object System.Windows.Forms.Label
$nameLabel.Text = "Full Name:"
$nameLabel.Location = New-Object System.Drawing.Point(200, 20)
$form.Controls.Add($nameLabel)

# First student entry (Year Level 1 and Name 1)
$yearDropdown1 = New-Object System.Windows.Forms.ComboBox
$yearDropdown1.Location = New-Object System.Drawing.Point(100, 50)
$yearDropdown1.Size = New-Object System.Drawing.Size(75, 20)
$yearDropdown1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$yearDropdown1.Items.AddRange((0..12 | ForEach-Object { "$_" }))  # Adding year levels 0-12
$form.Controls.Add($yearDropdown1)

$nameBox1 = New-Object System.Windows.Forms.TextBox
$nameBox1.Location = New-Object System.Drawing.Point(200, 50)
$nameBox1.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($nameBox1)

# Second student entry (Year Level 2 and Name 2)
$yearDropdown2 = New-Object System.Windows.Forms.ComboBox
$yearDropdown2.Location = New-Object System.Drawing.Point(100, 90)
$yearDropdown2.Size = New-Object System.Drawing.Size(75, 20)
$yearDropdown2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$yearDropdown2.Items.AddRange((0..12 | ForEach-Object { "$_" }))  # Adding year levels 0-12
$form.Controls.Add($yearDropdown2)

$nameBox2 = New-Object System.Windows.Forms.TextBox
$nameBox2.Location = New-Object System.Drawing.Point(200, 90)
$nameBox2.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($nameBox2)

# Third student entry (Year Level 3 and Name 3)
$yearDropdown3 = New-Object System.Windows.Forms.ComboBox
$yearDropdown3.Location = New-Object System.Drawing.Point(100, 130)
$yearDropdown3.Size = New-Object System.Drawing.Size(75, 20)
$yearDropdown3.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$yearDropdown3.Items.AddRange((0..12 | ForEach-Object { "$_" }))  # Adding year levels 0-12
$form.Controls.Add($yearDropdown3)

$nameBox3 = New-Object System.Windows.Forms.TextBox
$nameBox3.Location = New-Object System.Drawing.Point(200, 130)
$nameBox3.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($nameBox3)

# Fourth student entry (Year Level 4 and Name 4)
$yearDropdown4 = New-Object System.Windows.Forms.ComboBox
$yearDropdown4.Location = New-Object System.Drawing.Point(100, 170)
$yearDropdown4.Size = New-Object System.Drawing.Size(75, 20)
$yearDropdown4.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$yearDropdown4.Items.AddRange((0..12 | ForEach-Object { "$_" }))  # Adding year levels 0-12
$form.Controls.Add($yearDropdown4)

$nameBox4 = New-Object System.Windows.Forms.TextBox
$nameBox4.Location = New-Object System.Drawing.Point(200, 170)
$nameBox4.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($nameBox4)

# Fifth student entry (Year Level 5 and Name 5)
$yearDropdown5 = New-Object System.Windows.Forms.ComboBox
$yearDropdown5.Location = New-Object System.Drawing.Point(100, 210)
$yearDropdown5.Size = New-Object System.Drawing.Size(75, 20)
$yearDropdown5.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$yearDropdown5.Items.AddRange((0..12 | ForEach-Object { "$_" }))  # Adding year levels 0-12
$form.Controls.Add($yearDropdown5)

$nameBox5 = New-Object System.Windows.Forms.TextBox
$nameBox5.Location = New-Object System.Drawing.Point(200, 210)
$nameBox5.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($nameBox5)

# Submit Button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Add to AD"
$submitButton.Location = New-Object System.Drawing.Point(150, 260)  # Coordinates for the button
$submitButton.Add_Click({
    $students = @(
        @{ NameBox = $nameBox1; YearDropdown = $yearDropdown1 },
        @{ NameBox = $nameBox2; YearDropdown = $yearDropdown2 },
        @{ NameBox = $nameBox3; YearDropdown = $yearDropdown3 },
        @{ NameBox = $nameBox4; YearDropdown = $yearDropdown4 },
        @{ NameBox = $nameBox5; YearDropdown = $yearDropdown5 }
    )

    foreach ($student in $students) {
        $fullName = $student.NameBox.Text
        $yearLevel = $student.YearDropdown.SelectedItem

        # Skip if full name or year level is not selected
        if (-not $fullName -or -not $yearLevel) { continue }

        # Split the full name into first and last names
        $names = $fullName -split " "
        $firstName = $names[0]
        $lastName = $names[1]
        
        # Create username as Firstname.Lastname (keeping the dot)
        $username = "$firstName.$lastName"
        $username = $username.Substring(0, [System.Math]::Min($username.Length, 20))  # Truncate to 20 chars
        $email = "$username@student.hopecc.sa.edu.au"
        $employeeID = "HCC$((Get-Random -Minimum 100000 -Maximum 999999))"
        
        # Fetch a simple password from a service
        $simplepass = Invoke-RestMethod -Uri https://www.dinopass.com/password/simple

        # Set the Organizational Unit (OU) based on the year level
        if ($yearLevel -ge 10 -and $yearLevel -le 12) {
            $OU = "OU=Year $yearLevel,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
        } elseif ($yearLevel -ge 6 -and $yearLevel -le 9) {
            $OU = "OU=Year $yearLevel,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
        } elseif ($yearLevel -ge 3 -and $yearLevel -le 5) {
            $OU = "OU=Year $yearLevel,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
        } else {
            $OU = "OU=Year $yearLevel,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
        }

        try {
            # Create AD User
            New-ADUser -Name $fullName -GivenName $firstName -Surname $lastName -SamAccountName $username -DisplayName $fullName -UserPrincipalName "$email" -Path $OU -AccountPassword (ConvertTo-SecureString -AsPlainText $simplepass -Force) -Enabled $true -Description "2026 Year $yearLevel" -Department "Year $yearLevel" -Company "Hope Christian College" -Office "$yearLevel" -Verbose 
            
            # Set additional attributes for the user
            Set-ADUser -Identity $username -Replace @{employeeType="Student"} -Verbose
            Set-ADUser -Identity $username -Replace @{EmployeeID="$employeeID"} -Verbose
            
            # Add to AD groups
            Add-ADGroupMember -Identity "Students" -Members $username -Verbose
            Add-ADGroupMember -Identity "Year $yearLevel Students" -Members $username -Verbose
            
            # Export student details to CSV
            $csvPath = "C:\Users\Public\Documents\students.csv"
            $entry = [PSCustomObject]@{
                FullName = $fullName
                Username = $username
                Email = $email
                Password = $simplepass
                YearLevel = $yearLevel
            }
            $entry | Export-Csv -Path $csvPath -Append -NoTypeInformation


        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
})


            # Open the CSV file after exporting
            Start-Process $csvPath

$form.Controls.Add($submitButton)

# Show the form
$form.ShowDialog()

