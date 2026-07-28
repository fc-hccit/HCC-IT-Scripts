Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Get all Microsoft Store apps installed on the current user's account
$apps = Get-AppxPackage -AllUsers

# Create a form object
$form = New-Object System.Windows.Forms.Form
$form.Text = "Uninstall Microsoft Store Apps"
$form.Width = 1000  # Double the width
$form.Height = 1000  # Double the height

# Create a list box to display the apps
$listBox = New-Object System.Windows.Forms.CheckedListBox
$listBox.Location = New-Object System.Drawing.Point(10, 10)
$listBox.Size = New-Object System.Drawing.Size(980, 800)  # Double the size

# Add the apps to the list box
foreach ($app in $apps) {
    $listBox.Items.Add($app.Name) | Out-Null
}

# Create a button to initiate the uninstall process
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10, 860)  # Update the position
$button.Size = New-Object System.Drawing.Size(75, 23)
$button.Text = "Uninstall"
$button.Add_Click({
    foreach ($item in $listBox.CheckedItems) {
        $app = $apps | Where-Object {$_.Name -eq $item}
        if ($app) {
            Write-Host "Uninstalling $($app.Name)..."
            Remove-AppxPackage $app.PackageFullName
        }
    }
    $form.Close()
})

# Add the controls to the form
$form.Controls.Add($listBox)
$form.Controls.Add($button)

# Show the form
$form.ShowDialog() | Out-Null
