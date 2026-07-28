Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Form Setup
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Print Driver Installer'
$form.Size = New-Object System.Drawing.Size(300, 300)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true  # Keep the form on top

# OK Button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75, 210)
$OKButton.Size = New-Object System.Drawing.Size(75, 23)
$OKButton.Text = 'OK'
$OKButton.Enabled = $False
$form.Controls.Add($OKButton)

# Cancel Button
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150, 210)
$CancelButton.Size = New-Object System.Drawing.Size(75, 23)
$CancelButton.Text = 'Cancel'
$form.Controls.Add($CancelButton)

# Label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(280, 20)
$label.Text = 'Please select your printer model:'
$form.Controls.Add($label)

# ListBox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 40)
$listBox.Size = New-Object System.Drawing.Size(260, 150)
$form.Controls.Add($listBox)

# Path to Printer Drivers
$driverPath = "\\hopecc.sa.edu.au\source\SCCM\Applications\Printer Drivers\"

# Populate ListBox with Folder Names
$printerFolders = Get-ChildItem -Path $driverPath -Directory
$printerFolders | ForEach-Object {
    $listBox.Items.Add($_.Name)
}

# Show the OK Button when an item is selected
$listBox.add_SelectedIndexChanged({ $OKButton.Enabled = $true })

# Handle OK Button Click
$OKButton.Add_Click({
    $selectedPrinter = $listBox.SelectedItem.ToString()
    $driverExecutable = Join-Path -Path $driverPath -ChildPath $selectedPrinter
    $dpinstPath = Join-Path -Path $driverExecutable -ChildPath "dpinstx64.exe"

    # Error Handling: Check if dpinstx64.exe exists
    if (-Not (Test-Path -Path $dpinstPath)) {
        [System.Windows.Forms.MessageBox]::Show($form, "The installer file `dpinstx64.exe` could not be found in the directory: $driverExecutable", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Execute the driver installer directly
    try {
        Start-Process -FilePath $dpinstPath -NoNewWindow -Wait
        # Show Success Message
        [System.Windows.Forms.MessageBox]::Show($form, "Printer has been installed successfully!", "Done", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show($form, "An error occurred while installing the printer driver: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Show the form
$form.ShowDialog() | Out-Null
