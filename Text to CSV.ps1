Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Email Address Extractor"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Create the label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(380, 20)
$label.Text = "Enter the path to the text file:"
$form.Controls.Add($label)

# Create the text box
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 40)
$textBox.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($textBox)

# Create the browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(320, 40)
$browseButton.Size = New-Object System.Drawing.Size(70, 20)
$browseButton.Text = "Browse..."
$browseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select the text file"
    $openFileDialog.Filter = "Text Files (*.txt)|*.txt"
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $textBox.Text = $openFileDialog.FileName
    }
})
$form.Controls.Add($browseButton)

# Create the extract button
$extractButton = New-Object System.Windows.Forms.Button
$extractButton.Location = New-Object System.Drawing.Point(10, 80)
$extractButton.Size = New-Object System.Drawing.Size(380, 30)
$extractButton.Text = "Extract First Name and Last Name"
$extractButton.Add_Click({
    $inputFile = $textBox.Text
    $outputFile = [System.IO.Path]::ChangeExtension($inputFile, ".csv")

    # Read the text file and extract email addresses
    $content = Get-Content $inputFile
    $matches = foreach ($line in $content) {
        $regex = [regex]::Match($line, "\b(\w+)\.(\w+)\.student@hopecc\.sa\.edu\.au\b")
        if ($regex.Success) {
            $firstName = $regex.Groups[1].Value
            $lastName = $regex.Groups[2].Value
            $firstName = (Get-Culture).TextInfo.ToTitleCase($firstName)
            $lastName = (Get-Culture).TextInfo.ToTitleCase($lastName)
            [PSCustomObject]@{
                FirstName = $firstName
                LastName = $lastName
            }
        }
    }

    if ($matches) {
        # Output the first name and last name to a CSV file
        $matches | Export-Csv -Path $outputFile -NoTypeInformation

        [System.Windows.Forms.MessageBox]::Show("First names and last names extracted and saved to $outputFile", "Extraction Complete")
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("No email addresses matching the required format found in the text file.", "Extraction Failed")
    }
})
$form.Controls.Add($extractButton)

# Show the form
$form.ShowDialog() | Out-Null