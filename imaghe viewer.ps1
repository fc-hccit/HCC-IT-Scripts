# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Image Viewer"
$form.Width = 800
$form.Height = 600
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Create a PictureBox to display images
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
$form.Controls.Add($pictureBox)

# Create a Button to close the form
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
$closeButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($closeButton)

# Specify the directory containing the images
$imageDirectory = "C:\Users\ITMGR-ND\Desktop\"

# Output the directory being checked
Write-Host "Checking directory: $imageDirectory"

# Get all image files in the directory
$imageFiles = Get-ChildItem -Path $imageDirectory -File | Where-Object { $_.Extension -match "\.jpg|\.jpeg|\.png" } | Sort-Object Name

if ($imageFiles.Count -eq 0) {
    Write-Host "No image files found in the directory."
} else {
    Write-Host "Found image files:"
    $imageFiles | ForEach-Object { Write-Host $_.FullName }

    # Show the form
    $form.Show()

    # Loop through the images and display them
    $currentFileIndex = 0
    while ($form.Visible -and $currentFileIndex -lt $imageFiles.Count) {
        $imageFile = $imageFiles[$currentFileIndex]

        # Check if the file still exists
        if (Test-Path $imageFile.FullName) {
            try {
                $imageStream = [System.IO.File]::OpenRead($imageFile.FullName)
                $image = [System.Drawing.Image]::FromStream($imageStream)
                $imageStream.Close()

                $pictureBox.Image = $image
                $form.Refresh()

                # Move to the next file
                $currentFileIndex = ($currentFileIndex + 1) % $imageFiles.Count

                # Pause for 2 seconds before displaying the next image
                Start-Sleep -Seconds 2
            } catch {
                Write-Host "Error loading image: $($_.Exception.Message)"
            }
        } else {
            Write-Host "Image file not found: $($imageFile.FullName)"
        }
    }
}

# Keep the form open and handle closing
$form.Add_Shown({$form.Activate()})
[System.Windows.Forms.Application]::Run($form)
