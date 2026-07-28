Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Installed Programs"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"

# Create listbox to display installed programs
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,10)
$listBox.Size = New-Object System.Drawing.Size(560,300)
$listBox.Anchor = "Top, Left, Right, Bottom"
$form.Controls.Add($listBox)

# Create button to show uninstall commands
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(200,320)
$button.Size = New-Object System.Drawing.Size(200,30)
$button.Text = "Show Uninstall Commands"
$button.Anchor = "Bottom"
$button.Add_Click({
    $selectedItem = $listBox.SelectedItem
    if ($selectedItem -ne $null) {
        $uninstallCommand = Get-UninstallCommand -DisplayName $selectedItem
        if ($uninstallCommand -ne $null) {
            $uninstallCommand | Set-Clipboard
            [System.Windows.Forms.MessageBox]::Show("Uninstall command copied to clipboard: `n$uninstallCommand", "Uninstall Command for $selectedItem", "OK", "Information")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Uninstall command not found for $selectedItem", "Error", "OK", "Error")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a program from the list", "Error", "OK", "Error")
    }
})
$form.Controls.Add($button)

# Function to get uninstall command for a program
function Get-UninstallCommand {
    param (
        [string]$DisplayName
    )
    $uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach ($key in $uninstallKey) {
        if (Test-Path $key) {
            $programs = Get-ChildItem $key | Get-ItemProperty
            foreach ($program in $programs) {
                if ($program.DisplayName -eq $DisplayName) {
                    return $program.UninstallString
                }
            }
        }
    }
    return $null
}

# Function to get list of installed programs
function Get-InstalledPrograms {
    $programs = @()
    $uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach ($key in $uninstallKey) {
        if (Test-Path $key) {
            $programs += Get-ChildItem $key | Get-ItemProperty | Where-Object { $_.DisplayName -and $_.DisplayName -notlike "*(KB*" }
        }
    }
    $programs | Select-Object -ExpandProperty DisplayName | Sort-Object
}

# Populate listbox with installed programs
$listBox.Items.AddRange((Get-InstalledPrograms))

# Show the form
$form.ShowDialog() | Out-Null
