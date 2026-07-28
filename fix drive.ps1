Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "USB Drive Repair"
$form.Size = New-Object System.Drawing.Size(400, 250)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

# Create label for instructions
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(380, 40)
$label.Text = "Please select the USB drive to repair:"
$form.Controls.Add($label)

# Create combo box to display available drives
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10, 70)
$comboBox.Size = New-Object System.Drawing.Size(380, 20)

# Function to refresh the list of drives
function RefreshDrives {
    $comboBox.Items.Clear()
    $drives = Get-PhysicalDisk
    foreach ($drive in $drives) {
        $friendlyName = (Get-PhysicalDisk).friendlyname
        $size = (Get-PhysicalDisk).size
        $driveObject = New-Object PSObject -Property @{
            Name = $drive.Name
            FriendlyName = $friendlyName
            Size = $size
        }
        $comboBox.Items.Add($driveObject) | Out-Null
        $comboBox.DisplayMember = "FriendlyName"
        $comboBox.ValueMember = "Name"
        $comboBox.Items[$comboBox.Items.Count - 1] = $driveObject
    }
}

# Initial drive refresh
RefreshDrives

$form.Controls.Add($comboBox)

# Create repair button
$repairButton = New-Object System.Windows.Forms.Button
$repairButton.Location = New-Object System.Drawing.Point(10, 120)
$repairButton.Size = New-Object System.Drawing.Size(180, 30)
$repairButton.Text = "Repair"
$repairButton.Add_Click({
    $selectedDrive = $comboBox.SelectedItem
    if ($selectedDrive) {

# Repair logic here
try {
    Write-Host "Repairing drive: $($selectedDrive.Name)"

    # Check if the drive is currently mounted
    $isMounted = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $selectedDrive.Name }
    Write-Host "IsMounted: $isMounted"

    if ($isMounted) {
        # Offline the volume before repairing
        $volume = Get-Partition | Where-Object { $_.AccessPaths -contains "$($selectedDrive.Name.TrimEnd(':'))\\" }
        Write-Host "Volume: $volume"
        $offlineResult = $volume | Set-Partition -NoDefaultDriveLetter -NewDriveLetter "$null" -Confirm:$false -ErrorAction Stop
        if (!$offlineResult) {
            Write-Host "Failed to offline the drive. Repair process aborted."
            return
        }
    }

    # Format the drive (replace "NTFS" with the desired file system)
    $partition = Get-Partition | Where-Object { $_.DriveLetter -eq $selectedDrive.Name }
    Write-Host "Partition: $partition"
    if ($partition) {
        $volume = $partition | Get-Volume
        Write-Host "Volume: $volume"
        $volume | Format-Volume -FileSystem NTFS -Confirm:$false -Force
    }

    # Get the disk associated with the selected drive letter using the serial number
    Get-PhysicalDisk 
    $disk = Get-PhysicalDisk | Where-Object { $_.SerialNumber -eq $serialNumber }
    Write-Host "Disk: $disk"

    if ($disk) {
        # Create a new partition table (replace "MBR" with "GPT" if desired)
        $partitionStyle = "MBR"
        $disk | Clear-Disk -RemoveData -Confirm:$false -ErrorAction Stop
        $disk | Initialize-Disk -PartitionStyle $partitionStyle -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -Force

        Write-Host "Drive successfully repaired."
    } else {
        Write-Host "Failed to retrieve disk for the drive."
    }
} catch {
    Write-Host "An error occurred while repairing the drive: $($_.Exception.Message)"
}






    }
})
$form.Controls.Add($repairButton)

# Create refresh button
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(210, 120)
$refreshButton.Size = New-Object System.Drawing.Size(180, 30)
$refreshButton.Text = "Refresh Drives"
$refreshButton.Add_Click({
    RefreshDrives
})
$form.Controls.Add($refreshButton)

# Display the form
$form.ShowDialog()
