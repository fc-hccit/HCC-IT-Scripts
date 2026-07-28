Add-Type -AssemblyName System.Windows.Forms

# Function to display URL input dialog
function Show-UrlInputDialog {
    $inputForm = New-Object System.Windows.Forms.Form
    $inputForm.Text = "Add URL"
    $inputForm.Size = New-Object System.Drawing.Size(300, 300)

    $urlTextBox = New-Object System.Windows.Forms.TextBox
    $urlTextBox.Multiline = $true
    $urlTextBox.ScrollBars = "Vertical"
    $urlTextBox.Location = New-Object System.Drawing.Point(10, 10)
    $urlTextBox.Width = 260
    $urlTextBox.Height = 180

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(100, 200)
    $okButton.Add_Click({
        $inputForm.Close()
    })

    $inputForm.Controls.Add($urlTextBox)
    $inputForm.Controls.Add($okButton)

    $result = $inputForm.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $urlTextBox.Text
    }

    return $null
}


# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create a label for student names
$studentLabel = New-Object System.Windows.Forms.Label
$studentLabel.Text = "Student:"
$studentLabel.Location = New-Object System.Drawing.Point(30, 30)

# Create a dropdown list for student names
$studentDropdown = New-Object System.Windows.Forms.ComboBox
$studentDropdown.Location = New-Object System.Drawing.Point(150, 30)
$studentDropdown.Width = 200
$studentDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

# Add student names to the dropdown list
$studentDropdown.Items.AddRange(@("Student A", "Student B", "Student C"))

# Create a label for teacher names
$teacherLabel = New-Object System.Windows.Forms.Label
$teacherLabel.Text = "Teacher:"
$teacherLabel.Location = New-Object System.Drawing.Point(30, 70)

# Create a dropdown list for teacher names
$teacherDropdown = New-Object System.Windows.Forms.ComboBox
$teacherDropdown.Location = New-Object System.Drawing.Point(150, 70)
$teacherDropdown.Width = 200
$teacherDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

# Add teacher names to the dropdown list
$teacherDropdown.Items.AddRange(@("Teacher X", "Teacher Y", "Teacher Z"))

# Create a label for the website field
$websiteLabel = New-Object System.Windows.Forms.Label
$websiteLabel.Text = "Website:"
$websiteLabel.Location = New-Object System.Drawing.Point(30, 110)

# Create a text field for entering a website
$websiteField = New-Object System.Windows.Forms.TextBox
$websiteField.Location = New-Object System.Drawing.Point(150, 110)
$websiteField.Width = 200

# Create a button to add URLs to the blocked URLs list
$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = "Add URL"
$addButton.Location = New-Object System.Drawing.Point(180, 200)
$addButton.Add_Click({
    $url = Show-UrlInputDialog
    if (![string]::IsNullOrEmpty($url)) {
        # Add the URL to the blocked URLs list
        $blockedUrlsList.Items.Add($url)
        Write-Host "Added URL to the blocked URLs list: $url"

        # Append the URL to the BlockedURLs.txt file
        Add-Content -Path $blockedUrlsPath -Value $url
    }
})
$addButton.Width = 90

# Create a button for the weekly report
$reportButton = New-Object System.Windows.Forms.Button
$reportButton.Text = "Weekly Report"
$reportButton.Location = New-Object System.Drawing.Point(30, 200)
$reportButton.Add_Click({
    # Generate the weekly report or perform desired action
    Write-Host "Generating weekly report..."
})
$reportButton.Width = 130

# Create a submit button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Submit"
$submitButton.Location = New-Object System.Drawing.Point (150, 150)
$submitButton.Add_Click({
    # Perform the submit action or perform desired action
    $selectedStudent = $studentDropdown.SelectedItem
    $selectedTeacher = $teacherDropdown.SelectedItem
    $selectedWebsite = $websiteField.Text

     # Perform desired action with selected student, teacher, and website
    Write-Host "Selected Student: $selectedStudent"
    Write-Host "Selected Teacher: $selectedTeacher"
    Write-Host "Selected Website: $selectedWebsite"

    
    # Output field data to a text file
    
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $output = @"
    Date and Time: $currentDateTime
    Selected Student: $selectedStudent
    Selected Teacher: $selectedTeacher
    Selected Website: $selectedWebsite
"@

    $outputPath = "C:\Blacklip\Output.txt"  # Specify the desired output file path

    try {
        $output | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        Write-Host "Field data saved to $outputPath"
    } catch {
        Write-Host "Error occurred while saving field data to file: $($_.Exception.Message)"
    }


    # Send an email to the selected teacher
    $subject = "$selectedStudent has been blacklisted"
    $body = @"
Dear $selectedTeacher,

$selectedStudent has been blacklisted for visiting $selectedWebsite

The IT Department has verified this report.

As per the Middle School Student Device Policy, please issue a focus room for this student.

Thank you.

Sincerely,


"@

Send-MailMessage -From "IT Support <itsupport@hopecc.sa.edu.au>" -To "$selectedTeacher@hopecc.sa.edu.au" -Subject $subject -Body $body -SmtpServer "aspmx.l.google.com"

})
$submitButton.Width = 90

# Add the controls to the form
$form.Controls.Add($studentLabel)
$form.Controls.Add($studentDropdown)
$form.Controls.Add($teacherLabel)
$form.Controls.Add($teacherDropdown)
$form.Controls.Add($websiteLabel)
$form.Controls.Add($websiteField)
$form.Controls.Add($blockedUrlsLabel)
$form.Controls.Add($blockedUrlsField)
$form.Controls.Add($addButton)
$form.Controls.Add($reportButton)
$form.Controls.Add($submitButton)
$form.Controls.Add($blockedUrlsList)

# Show the form
$form.ShowDialog()