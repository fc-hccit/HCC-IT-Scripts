# Prompt the user to save files
[System.Windows.Forms.MessageBox]::Show("Please save any open files before clicking OK. This script will log you off if gpupdate takes longer than 2 minutes.", "Save Reminder", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

# Function to check Wi-Fi connection to "Hope-Student-Wifi"
function CheckWifiConnection {
    $SSID = netsh wlan show interfaces | Select-String -Pattern "SSID" | Select-Object -First 1
    if ($SSID -match "Hope-Student-WiFi") {
        return $true
    } else {
        return $false
    }
}

$wifiConnected = CheckWifiConnection

while (-not $wifiConnected) {
    $result = [System.Windows.Forms.MessageBox]::Show("You are not connected to the 'Hope-Student-WiFi' network. Please connect to 'Hope-Student-WiFi' and click Retry to continue or Cancel to exit.", "Wi-Fi Connection Error", [System.Windows.Forms.MessageBoxButtons]::RetryCancel, [System.Windows.Forms.MessageBoxIcon]::Error)

    if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
        exit
    }

    $wifiConnected = CheckWifiConnection
}


# Create a GUI window
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = "Updating Computer Policy"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Add a label to the GUI
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(380,20)
$label.Text = "Running gpupdate, please wait..."
$form.Controls.Add($label)

# Add a progress bar to the GUI
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10,50)
$progressBar.Size = New-Object System.Drawing.Size(380,20)
$progressBar.Style = "Continuous"
$progressBar.Maximum = 120 # 2 minutes in seconds
$form.Controls.Add($progressBar)

# Show the form
$form.Show() | Out-Null

# Start the gpupdate process asynchronously
$gpupdateProcess = Start-Process -FilePath "gpupdate" -ArgumentList "/force" -PassThru -WindowStyle Hidden

# Start the progress bar
for ($i = 0; $i -le 120; $i++) {
    $progressBar.Value = $i
    $percentage = [math]::Round(($i / 120) * 100)
    $label.Text = "Running gpupdate, please wait... $percentage%"
    Start-Sleep -Milliseconds 1000 # Sleep for 1 second
    
    # Check if gpupdate process has exited
    if ($gpupdateProcess.HasExited) {
        [System.Windows.Forms.MessageBox]::Show("Update completed successfully" , "Completed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        break
    }
}

# Close the form after gpupdate completes
$form.Close()

# If gpupdate process is still running after 2 minutes, restart the computer
if (-not $gpupdateProcess.HasExited) {
    Restart-Computer -Force -whatif
}
