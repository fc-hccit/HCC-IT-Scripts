Import-Module ActiveDirectory

# Load the System.Windows.Forms assembly
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.Text = "Add Device to User"
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Create a label for the device dropdown
$deviceLabel = New-Object System.Windows.Forms.Label
$deviceLabel.Location = New-Object System.Drawing.Point(20, 20)
$deviceLabel.Size = New-Object System.Drawing.Size(80, 20)
$deviceLabel.Text = "Device:"
$form.Controls.Add($deviceLabel)

# Create a dropdown for the devices
$deviceDropdown = New-Object System.Windows.Forms.ComboBox
$deviceDropdown.Location = New-Object System.Drawing.Point(100, 20)
$deviceDropdown.Size = New-Object System.Drawing.Size(200, 20)

# Get the devices from the Devices OU and sort them alphabetically
$devices = Get-ADComputer -SearchBase "OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au" | Select-Object -ExpandProperty Name | Sort-Object
$deviceDropdown.Items.AddRange($devices)
$form.Controls.Add($deviceDropdown)

# Create a label for the user dropdown
$userLabel = New-Object System.Windows.Forms.Label
$userLabel.Location = New-Object System.Drawing.Point(20, 60)
$userLabel.Size = New-Object System.Drawing.Size(80, 20)
$userLabel.Text = "User:"
$form.Controls.Add($userLabel)

# Create a dropdown for the users
$userDropdown = New-Object System.Windows.Forms.ComboBox
$userDropdown.Location = New-Object System.Drawing.Point(100, 60)
$userDropdown.Size = New-Object System.Drawing.Size(200, 20)

# Get the users from the Students OU and sort them alphabetically
$users = Get-ADUser -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" | Select-Object -ExpandProperty Name | Sort-Object
$userDropdown.Items.AddRange($users)
$form.Controls.Add($userDropdown)

# Create a submit button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Location = New-Object System.Drawing.Point(150, 100)
$submitButton.Size = New-Object System.Drawing.Size(100, 30)
$submitButton.Text = "Submit"
$submitButton.Add_Click({
    # Get the selected device and user
    $selecteddevice = $deviceDropdown.SelectedItem
$selectedUser = $userDropdown.SelectedItem

# Check if both device and user have been selected
if ($selectedDevice -eq $null -or $selectedUser -eq $null) {
    [System.Windows.Forms.MessageBox]::Show("Please select both a device and a user.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
} else {
    # Get the device and user objects
    $deviceObject = Get-ADComputer -Filter "Name -eq '$selectedDevice'"
    $userObject = Get-ADUser -Filter "Name -eq '$selectedUser'"

    # Add the device to the user's "memberOf" attribute
    $userObject.memberOf += $deviceObject.DistinguishedName
    Set-ADUser -Instance $userObject

    [System.Windows.Forms.MessageBox]::Show("Device added to user successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}
})
$form.Controls.Add($submitButton)

Show the form
$form.ShowDialog()