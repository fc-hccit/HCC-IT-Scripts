Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Paste Usernames'
$form.Width = 400
$form.Height = 300

# Create a multiline text box
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Dock = 'Fill'
$textBox.ScrollBars = 'Vertical'
$form.Controls.Add($textBox)

# Create a button to process the content
$button = New-Object System.Windows.Forms.Button
$button.Text = 'Process'
$button.Dock = 'Bottom'
$form.Controls.Add($button)

# Button click event
$button.Add_Click({
    $content = $textBox.Text -split "`r`n" # Split content by new lines
    foreach ($username in $content) {
        $username = $username.Trim() # Trim any extra spaces
        if (-not [string]::IsNullOrWhiteSpace($username)) {
            try {
                Disable-ADAccount -Identity $username -ErrorAction Stop
                write-host = "Disabled account for: $username"
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to disable account for: $username. Error: $_")
            }
        }
    }
})

# Show the form
$form.ShowDialog()
