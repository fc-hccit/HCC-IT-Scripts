Add-Type -AssemblyName System.Windows.Forms

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Vacation Responder"
$form.Size = New-Object System.Drawing.Size(400, 360)
$form.StartPosition = "CenterScreen"

# Create labels
$labelName = New-Object System.Windows.Forms.Label
$labelName.Text = "Username:"
$labelName.Location = New-Object System.Drawing.Point(10, 20)
$labelName.Size = New-Object System.Drawing.Size(80, 20)
$form.Controls.Add($labelName)

$labelSubject = New-Object System.Windows.Forms.Label
$labelSubject.Text = "Subject:"
$labelSubject.Location = New-Object System.Drawing.Point(10, 60)
$labelSubject.Size = New-Object System.Drawing.Size(80, 20)
$form.Controls.Add($labelSubject)

$labelText = New-Object System.Windows.Forms.Label
$labelText.Text = "Text:"
$labelText.Location = New-Object System.Drawing.Point(10, 100)
$labelText.Size = New-Object System.Drawing.Size(80, 20)
$form.Controls.Add($labelText)

# Create textboxes
$textboxName = New-Object System.Windows.Forms.TextBox
$textboxName.Location = New-Object System.Drawing.Point(100, 20)
$textboxName.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($textboxName)

$textboxSubject = New-Object System.Windows.Forms.TextBox
$textboxSubject.Location = New-Object System.Drawing.Point(100, 60)
$textboxSubject.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($textboxSubject)

$textboxText = New-Object System.Windows.Forms.TextBox
$textboxText.Multiline = $true
$textboxText.ScrollBars = "Vertical"
$textboxText.Location = New-Object System.Drawing.Point(100, 100)
$textboxText.Size = New-Object System.Drawing.Size(250, 120)
$form.Controls.Add($textboxText)

# Create checkbox
$checkboxRemove = New-Object System.Windows.Forms.CheckBox
$checkboxRemove.Text = "Remove Responder"
$checkboxRemove.Location = New-Object System.Drawing.Point(100, 240)
$checkboxRemove.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($checkboxRemove)

# Create button
$buttonSubmit = New-Object System.Windows.Forms.Button
$buttonSubmit.Text = "Submit"
$buttonSubmit.Location = New-Object System.Drawing.Point(150, 280)
$buttonSubmit.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($buttonSubmit)

# Display form
$result = $form.ShowDialog()

# Retrieve input values
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $Name = $textboxName.Text
    $subject = $textboxSubject.Text
    $text = $textboxText.Text
    $remove = $checkboxRemove.Checked

    # Output the values of the variables
    Write-Host "Username: $Name"
    Write-Host "Subject: $subject"
    Write-Host "Text: $text"
    Write-Host "Remove: $remove"
}

if($remove){gam user $Name vacation off}

else {gam user $Name vacation on subject "$subject" message "$text"}


$form.Dispose()
