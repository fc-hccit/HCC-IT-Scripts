# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a new Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Image Viewer"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Create a TextBox for inputting the remote computer name
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(600, 20)
$textBox.Location = New-Object System.Drawing.Point(10, 10)
$textBox.Text = "remotecomputer"
$form.Controls.Add($textBox)

# Create a Button to connect and start image updates
$button = New-Object System.Windows.Forms.Button
$button.Text = "Connect"
$button.Size = New-Object System.Drawing.Size(75, 23)
$button.Location = New-Object System.Drawing.Point(620, 10)
$form.Controls.Add($button)

# Create a PictureBox to display the image
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
$pictureBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$form.Controls.Add($pictureBox)

# Function to update the PictureBox with the latest image
function Update-Image {
    $computerName = $textBox.Text
    $imagePath = "‪C:\Users\Public\RSSC\sstmp"

    if (Test-Path $imagePath) {
        $pictureBox.Image = [System.Drawing.Image]::FromFile($imagePath)
        return $true # Image updated successfully
    } else {
        return $false # Image file not found
    }
}

# Function to handle button click event
$button.Add_Click({
    # Disable the button to prevent multiple starts
    $button.Enabled = $false
    
    # Continuous loop to check for image updates
    while ($form.Visible) {
        if (-not (Update-Image)) {
            [System.Windows.Forms.MessageBox]::Show("Image path not found: \\$($textBox.Text)\c$\Temp\RSSC\screenshot.jpg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            break # Exit the loop if the image is not found
        }
        Start-Sleep -Seconds 1 # Adjust the interval as needed
    }
    
    # Re-enable the button when the loop stops
    $button.Enabled = $true
})

# Show the form
$form.Show()

# Run the form application
[System.Windows.Forms.Application]::Run($form)
