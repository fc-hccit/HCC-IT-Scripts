Add-Type -AssemblyName System.Windows.Forms

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WIM Driver Injection"
$form.Size = New-Object System.Drawing.Size(500, 500)
$form.StartPosition = "CenterScreen"

# Create WIM file type selection label and dropdown
$wimTypeLabel = New-Object System.Windows.Forms.Label
$wimTypeLabel.Text = "Select WIM File Type:"
$wimTypeLabel.Location = New-Object System.Drawing.Point(10, 20)
$wimTypeLabel.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($wimTypeLabel)

$wimTypeComboBox = New-Object System.Windows.Forms.ComboBox
$wimTypeComboBox.Location = New-Object System.Drawing.Point(10, 45)
$wimTypeComboBox.Size = New-Object System.Drawing.Size(360, 20)
$wimTypeComboBox.Items.AddRange(@("install.wim", "boot.wim"))
$wimTypeComboBox.SelectedIndex = 0
$form.Controls.Add($wimTypeComboBox)

# Create WIM file selection label and button
$wimLabel = New-Object System.Windows.Forms.Label
$wimLabel.Text = "Select WIM File:"
$wimLabel.Location = New-Object System.Drawing.Point(10, 80)
$wimLabel.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($wimLabel)

$wimFileTextBox = New-Object System.Windows.Forms.TextBox
$wimFileTextBox.Location = New-Object System.Drawing.Point(10, 105)
$wimFileTextBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($wimFileTextBox)

$wimButton = New-Object System.Windows.Forms.Button
$wimButton.Text = "Browse"
$wimButton.Location = New-Object System.Drawing.Point(380, 105)
$wimButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "WIM files (*.wim)|*.wim"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $wimFileTextBox.Text = $openFileDialog.FileName

        # Populate index dropdown based on selected WIM file
        $indexComboBox.Items.Clear()
        $wimInfo = dism /Get-WimInfo /WimFile:$wimFileTextBox.Text
        foreach ($line in $wimInfo) {
            if ($line -match "Index : (\d+)") {
                $indexComboBox.Items.Add("Index $($matches[1])")
            }
        }

        if ($indexComboBox.Items.Count -gt 0) {
            $indexComboBox.SelectedIndex = 0
        }
    }
})
$form.Controls.Add($wimButton)

# Create Drivers folder selection label and button
$driverLabel = New-Object System.Windows.Forms.Label
$driverLabel.Text = "Select Drivers Folder:"
$driverLabel.Location = New-Object System.Drawing.Point(10, 140)
$driverLabel.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($driverLabel)

$driverTextBox = New-Object System.Windows.Forms.TextBox
$driverTextBox.Location = New-Object System.Drawing.Point(10, 165)
$driverTextBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($driverTextBox)

$driverButton = New-Object System.Windows.Forms.Button
$driverButton.Text = "Browse"
$driverButton.Location = New-Object System.Drawing.Point(380, 165)
$driverButton.Add_Click({
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $driverTextBox.Text = $folderBrowserDialog.SelectedPath
    }
})
$form.Controls.Add($driverButton)

# Create Index selection label and dropdown
$indexLabel = New-Object System.Windows.Forms.Label
$indexLabel.Text = "Select Image Index:"
$indexLabel.Location = New-Object System.Drawing.Point(10, 200)
$indexLabel.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($indexLabel)

$indexComboBox = New-Object System.Windows.Forms.ComboBox
$indexComboBox.Location = New-Object System.Drawing.Point(10, 225)
$indexComboBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($indexComboBox)

# Create output textbox to show DISM output
$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10, 260)
$outputTextBox.Size = New-Object System.Drawing.Size(460, 150)
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = "Vertical"
$form.Controls.Add($outputTextBox)

# Function to run a DISM command and update output textbox
function Run-DismCommand {
    param (
        [string]$Command
    )

    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $Command" -NoNewWindow -PassThru -RedirectStandardOutput ([System.IO.StreamWriter]::Synchronized((New-Object System.IO.StreamWriter -ArgumentList $outputTextBox)))

    $process.StandardOutput.ReadLine() | ForEach-Object {
        $outputTextBox.AppendText("$_`r`n")
        $outputTextBox.SelectionStart = $outputTextBox.Text.Length
        $outputTextBox.ScrollToCaret()
    }

    $process.WaitForExit()
}

# Create Inject button
$injectButton = New-Object System.Windows.Forms.Button
$injectButton.Text = "Inject Drivers"
$injectButton.Location = New-Object System.Drawing.Point(10, 420)
$injectButton.Size = New-Object System.Drawing.Size(460, 30)
$injectButton.Add_Click({
    $wimFilePath = $wimFileTextBox.Text
    $driverFolderPath = $driverTextBox.Text
    $selectedIndex = $indexComboBox.Text -replace 'Index ', ''

    if (-not (Test-Path $wimFilePath)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid WIM file.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if (-not (Test-Path $driverFolderPath)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid drivers folder.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if (-not $selectedIndex) {
        [System.Windows.Forms.MessageBox]::Show("Please select an image index.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Mount the WIM file
    $mountDir = "$env:TEMP\WIMMount"
    New-Item -ItemType Directory -Path $mountDir -Force | Out-Null
    Run-DismCommand "dism /Mount-Wim /WimFile:$wimFilePath /Index:$selectedIndex /MountDir:$mountDir"

    # Inject drivers
    Run-DismCommand "dism /Image:$mountDir /Add-Driver /Driver:$driverFolderPath /Recurse"

    # Commit changes and unmount
    Run-DismCommand "dism /Unmount-Wim /MountDir:$mountDir /Commit"

    # Cleanup
    Remove-Item -Path $mountDir -Recurse -Force

    [System.Windows.Forms.MessageBox]::Show("Drivers have been successfully injected into the $($wimTypeComboBox.SelectedItem) file.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($injectButton)

# Run the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
