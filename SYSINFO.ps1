Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "System Information"
$form.Size = New-Object System.Drawing.Size(500, 300)

# Create labels to display information
$computerNameLabel = New-Object System.Windows.Forms.Label
$computerNameLabel.Location = New-Object System.Drawing.Point(10, 10)
$computerNameLabel.Size = New-Object System.Drawing.Size(200, 20)
$computerNameLabel.Text = "Computer Name:"
$form.Controls.Add($computerNameLabel)

$adGroupsLabel = New-Object System.Windows.Forms.Label
$adGroupsLabel.Location = New-Object System.Drawing.Point(10, 40)
$adGroupsLabel.Size = New-Object System.Drawing.Size(200, 20)
$adGroupsLabel.Text = "AD Groups:"
$form.Controls.Add($adGroupsLabel)

$deviceOULabel = New-Object System.Windows.Forms.Label
$deviceOULabel.Location = New-Object System.Drawing.Point(10, 70)
$deviceOULabel.Size = New-Object System.Drawing.Size(200, 20)
$deviceOULabel.Text = "Device OU:"
$form.Controls.Add($deviceOULabel)

$serialNumberLabel = New-Object System.Windows.Forms.Label
$serialNumberLabel.Location = New-Object System.Drawing.Point(10, 100)
$serialNumberLabel.Size = New-Object System.Drawing.Size(200, 20)
$serialNumberLabel.Text = "Serial Number:"
$form.Controls.Add($serialNumberLabel)

$freeSpaceLabel = New-Object System.Windows.Forms.Label
$freeSpaceLabel.Location = New-Object System.Drawing.Point(10, 130)
$freeSpaceLabel.Size = New-Object System.Drawing.Size(200, 20)
$freeSpaceLabel.Text = "Free Space (C:):"
$form.Controls.Add($freeSpaceLabel)

# Get the information to display
$computerName = $env:COMPUTERNAME
$adGroups = (Get-ADPrincipalGroupMembership -Identity $env:USERNAME).Name -join ", "
$deviceOU = (Get-ADComputer $env:COMPUTERNAME).DistinguishedName
$serialNumber = (Get-CimInstance -ClassName Win32_Bios).SerialNumber
$freeSpace = "{0:N2} GB" -f ((Get-PSDrive -Name C).FreeSpace / 1GB)

# Set the label values
$computerNameLabel.Text += " $computerName"
$adGroupsLabel.Text += " $adGroups"
$deviceOULabel.Text += " $deviceOU"
$serialNumberLabel.Text += " $serialNumber"
$freeSpaceLabel.Text += " $freeSpace"

# Show the form
$form.ShowDialog() | Out-Null
