# Load necessary assemblies for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define the form
$form = New-Object Windows.Forms.Form
$form.Text = "USB Drive Formatter"
$form.Size = New-Object Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Define the label
$label = New-Object Windows.Forms.Label
$label.Text = "Select a USB drive:"
$label.AutoSize = $true
$label.Location = New-Object Drawing.Point(10, 20)

# Define the combo box for drive selection
$driveComboBox = New-Object Windows.Forms.ComboBox
$driveComboBox.Location = New-Object Drawing.Point(10, 40)
$driveComboBox.Width = 200

# Populate combo box with available drives and their descriptions
Function Refresh-DriveComboBox {
    $driveComboBox.Items.Clear()
    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' }
    foreach ($drive in $drives) {
        $driveLetter = $drive.DriveLetter
        $driveName = "$driveLetter - $($drive.DriveType)- $($drive.FileSystemType)"
        $driveComboBox.Items.Add($driveName)
    }
}

Refresh-DriveComboBox

# Define the format button
$formatButton = New-Object Windows.Forms.Button
$formatButton.Text = "Format"
$formatButton.Location = New-Object Drawing.Point(10, 80)
$formatButton.Add_Click({
    # Check if a drive is selected
    if (-not $driveComboBox.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Please select a drive before formatting.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Get the selected drive letter
    $selectedDriveLetter = ($driveComboBox.SelectedItem -split ' ')[0]

    # Confirmation dialog
    $confirmation = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to format the selected drive? This will erase all data on the drive.", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

    if ($confirmation -eq 'No') {
        return
    }

    try {
        # Get the corresponding partition for the selected drive letter
        $partition = Get-Partition -DriveLetter $selectedDriveLetter

        if (-not $partition) {
            # No partition found, create a new one
            $disk = Get-Disk | Where-Object { $_.Size -gt 0 }

            if (-not $disk) {
                [System.Windows.Forms.MessageBox]::Show("No available disk for creating a new partition.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }

            # Clear the entire disk
            Clear-Disk -Number $disk.Number -RemoveData -Confirm:$false -RemoveOEM

            # Create a new partition with the maximum available size
            $newPartition = New-Partition -DiskNumber $disk.Number -AssignDriveLetter -UseMaximumSize

            # Format the new partition
            $formattedPartition = Format-Volume -Partition $newPartition -FileSystem FAT32 -Force

            [System.Windows.Forms.MessageBox]::Show("New partition created and formatted successfully.", "Format Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            # Get the disk number associated with the selected drive letter
            $disk = Get-Disk -Number $partition.DiskNumber

            # Clear the entire disk
            Clear-Disk -Number $disk.Number -RemoveData -Confirm:$false -RemoveOEM

            # Create a new partition with the maximum available size
            $newPartition = New-Partition -DiskNumber $disk.Number -AssignDriveLetter -UseMaximumSize

            # Format the new partition
            Format-Volume -Partition $newPartition -FileSystem FAT32 -Force

            [System.Windows.Forms.MessageBox]::Show("Format completed successfully.", "Format Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }

    # Refresh the drive combo box after formatting
    Refresh-DriveComboBox
})

# Define the refresh button
$refreshButton = New-Object Windows.Forms.Button
$refreshButton.Text = "Refresh Drives"
$refreshButton.Location = New-Object Drawing.Point(10, 120)
$refreshButton.Add_Click({
    # Refresh the drive combo box
    Refresh-DriveComboBox
})

# Add controls to the form
$form.Controls.Add($label)
$form.Controls.Add($driveComboBox)
$form.Controls.Add($formatButton)
$form.Controls.Add($refreshButton)

# Show the form
$form.ShowDialog()
