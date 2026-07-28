Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define the base directories to search
$baseDirectories = @('C:\', "${env:ProgramFiles}\", "${env:ProgramFiles(x86)}\")

# Variable to store the path to openssl.exe
$opensslExePath = $null

# Iterate through each base directory
foreach ($baseDir in $baseDirectories) {
    # Search for openssl.exe in the bin directory
   $opensslExePath = Get-ChildItem -Path (Join-Path $baseDir 'openssl*\bin\openssl.exe') -File -ErrorAction SilentlyContinue

    # If openssl.exe is found, break the loop
    if ($opensslExePath) {
        break
    }
       
}


# Function to locate OpenSSL
function Locate-OpenSSL {
    param (
        [string]$opensslExePath
    )

    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = 'OpenSSL Executable (*.exe)|*.exe'
    $fileDialog.FileName = 'openssl.exe'
    $result = $fileDialog.ShowDialog()

    if ($result -eq 'OK') {
        $global:opensslExePath = $fileDialog.FileName
        [System.Windows.Forms.MessageBox]::Show("OpenSSL located at: $global:opensslExePath", 'OpenSSL Located', 'OK', 'Information')
    }
}

function Show-InputDialog {
    param(
        [string]$title,
        [string]$prompt
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(300, 150)
    $form.StartPosition = "CenterScreen"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $prompt
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(280, 20)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.PasswordChar = "*"
    $textbox.Location = New-Object System.Drawing.Point(10, 50)
    $textbox.Size = New-Object System.Drawing.Size(280, 20)

    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Text = "OK"
    $buttonOK.Location = New-Object System.Drawing.Point(100, 90)
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $buttonOK.Add_Click({ $form.Close() })

    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCancel.Text = "Cancel"
    $buttonCancel.Location = New-Object System.Drawing.Point(190, 90)
    $buttonCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $buttonCancel.Add_Click({ $form.Close() })

    $form.AcceptButton = $buttonOK
    $form.CancelButton = $buttonCancel

    $form.Controls.Add($label)
    $form.Controls.Add($textbox)
    $form.Controls.Add($buttonOK)
    $form.Controls.Add($buttonCancel)

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textbox.Text
    }

    return $null
}

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Certificate Converter"
$form.Width = 500
$form.Height = 300

# Create labels
$labelCert = New-Object System.Windows.Forms.Label
$labelCert.Text = "Select Certificate File (.cer/.crt):"
$labelCert.Location = New-Object System.Drawing.Point(10, 10)
$labelCert.AutoSize = $true

$labelPrivateKey = New-Object System.Windows.Forms.Label
$labelPrivateKey.Text = "Select Private Key File:"
$labelPrivateKey.Location = New-Object System.Drawing.Point(10, 50)
$labelPrivateKey.AutoSize = $true

$labelOutput = New-Object System.Windows.Forms.Label
$labelOutput.Text = "Output File Path:"
$labelOutput.Location = New-Object System.Drawing.Point(10, 90)
$labelOutput.AutoSize = $true

$labelFormat = New-Object System.Windows.Forms.Label
$labelFormat.Text = "Output Format:"
$labelFormat.Location = New-Object System.Drawing.Point(10, 130)
$labelFormat.AutoSize = $true

# Create textboxes
$textboxCert = New-Object System.Windows.Forms.TextBox
$textboxCert.Location = New-Object System.Drawing.Point(10, 30)
$textboxCert.Width = 250

$textboxPrivateKey = New-Object System.Windows.Forms.TextBox
$textboxPrivateKey.Location = New-Object System.Drawing.Point(10, 70)
$textboxPrivateKey.Width = 250

$textboxOutput = New-Object System.Windows.Forms.TextBox
$textboxOutput.Location = New-Object System.Drawing.Point(10, 110)
$textboxOutput.Width = 250

# Create ComboBox for certificate format selection
$comboBoxFormat = New-Object System.Windows.Forms.ComboBox
$comboBoxFormat.Location = New-Object System.Drawing.Point(10, 150)
$comboBoxFormat.Width = 250
$comboBoxFormat.Items.AddRange(@("PEM", "PKCS#12"))
$comboBoxFormat.SelectedIndex = 0
$comboBoxFormat.Add_SelectedIndexChanged({
    $ext = if ($comboBoxFormat.SelectedItem -eq "PEM") { ".pem" } else { ".p12" }
    $textboxOutput.Text = Join-Path (Get-Item $textboxCert.Text).DirectoryName ((Get-Item $textboxCert.Text).BaseName + $ext)
})

# Create buttons
$buttonBrowseCert = New-Object System.Windows.Forms.Button
$buttonBrowseCert.Text = "Browse"
$buttonBrowseCert.Location = New-Object System.Drawing.Point(265, 30)
$buttonBrowseCert.Add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = 'Certificate Files (*.cer;*.crt)|*.cer;*.crt|All Files (*.*)|*.*'
    $result = $fileDialog.ShowDialog()
    if ($result -eq 'OK') {
        $textboxCert.Text = $fileDialog.FileName
        $ext = if ($comboBoxFormat.SelectedItem -eq "PEM") { ".pem" } else { ".p12" }
        $textboxOutput.Text = Join-Path (Get-Item $fileDialog.FileName).DirectoryName ((Get-Item $fileDialog.FileName).BaseName + $ext)

        # Autofill private key path if found in the certificate directory
        $privateKeyPath = Join-Path (Get-Item $fileDialog.FileName).DirectoryName 'private.key'
        if (Test-Path $privateKeyPath) {
            $textboxPrivateKey.Text = $privateKeyPath
        }
    }
})

$buttonBrowsePrivateKey = New-Object System.Windows.Forms.Button
$buttonBrowsePrivateKey.Text = "Browse"
$buttonBrowsePrivateKey.Location = New-Object System.Drawing.Point(265, 70)
$buttonBrowsePrivateKey.Add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = 'Private Key Files (*.key)|*.key|All Files (*.*)|*.*'
    $result = $fileDialog.ShowDialog()
    if ($result -eq 'OK') {
        $textboxPrivateKey.Text = $fileDialog.FileName
    }
})

$buttonLocateOpenSSL = New-Object System.Windows.Forms.Button
$buttonLocateOpenSSL.Text = "Locate OpenSSL"
$buttonLocateOpenSSL.Location = New-Object System.Drawing.Point(340, 30)
$buttonLocateOpenSSL.Width = 120
$buttonLocateOpenSSL.Add_Click({Locate-OpenSSL})

$buttonConvert = New-Object System.Windows.Forms.Button
$buttonConvert.Text = "Convert"
$buttonConvert.Location = New-Object System.Drawing.Point(265, 190)
$buttonConvert.Add_Click({
    $certPath = $textboxCert.Text
    $outputPath = $textboxOutput.Text
    $outputFormat = $comboBoxFormat.SelectedItem.ToString()
    $privateKeyPath = $textboxPrivateKey.Text

    if (-not (Test-Path $certPath)) {
        [System.Windows.Forms.MessageBox]::Show('Invalid certificate file path.', 'Error', 'OK', 'Error')
        return
    }

    if ($outputFormat -eq "PKCS#12" -and -not (Test-Path $privateKeyPath)) {
        [System.Windows.Forms.MessageBox]::Show('Invalid private key file path.', 'Error', 'OK', 'Error')
        return
    }

    if (-not (Test-Path (Split-Path $outputPath))) {
        [System.Windows.Forms.MessageBox]::Show('Invalid output file path.', 'Error', 'OK', 'Error')
        return
    }

   if ($opensslExePath -eq $null) {[System.Windows.Forms.MessageBox]::Show('OpenSSL not found. Please use the "Locate OpenSSL" button to find the OpenSSL executable.', 'Error', 'OK', 'Error')
   return
    }

   elseif (-not (Test-Path $opensslExePath)) {
       
       [System.Windows.Forms.MessageBox]::Show('OpenSSL not found. Please use the "Locate OpenSSL" button to find the OpenSSL executable.', 'Error', 'OK', 'Error')
        return
    }

    # Run OpenSSL command to convert the certificate based on the selected format
    try {
        switch ($outputFormat) {
            "PEM" {
                if ($privateKeyPath) {
                    
                    $command = "& '$opensslExePath' rsa -in ""$privateKeyPath"" -outform PEM -out ""$outputPath"""
                    Invoke-Expression $command

                    # Append the certificate to the PEM file
                    Add-Content -Path $outputPath -Value "`n"
                    Add-Content -Path $outputPath -Value (Get-Content -Path $certPath)
                } else {
                    [System.Windows.Forms.MessageBox]::Show('Private key file path is required for PEM format.', 'Error', 'OK', 'Error')
                    return
                }
            }
            "PKCS#12" {
                if ($privateKeyPath) {
                    $password = Show-InputDialog -title "Enter Password" -prompt "Enter password for PKCS#12 file"
                    if (-not $password) {
                        return
                    }

                    # Create a PKCS#12 file with the entered password
                    $command = "& '$opensslExePath' pkcs12 -export -in ""$certPath"" -inkey ""$privateKeyPath"" -out ""$outputPath"" -passout pass:$password"
                    Invoke-Expression $command
                } else {
                    [System.Windows.Forms.MessageBox]::Show('Private key file path is required for PKCS#12 format.', 'Error', 'OK', 'Error')
                    return
                }
            }
            default {
                [System.Windows.Forms.MessageBox]::Show('Invalid output format selected.', 'Error', 'OK', 'Error')
                return
            }
        }

        [System.Windows.Forms.MessageBox]::Show('Certificate conversion completed.', 'Success', 'OK', 'Information')
    } catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", 'Error', 'OK', 'Error')
    }
})


# Add controls to the form
$form.Controls.Add($labelCert)
$form.Controls.Add($textboxCert)
$form.Controls.Add($buttonBrowseCert)
$form.Controls.Add($buttonLocateOpenSSL)

$form.Controls.Add($labelPrivateKey)
$form.Controls.Add($textboxPrivateKey)
$form.Controls.Add($buttonBrowsePrivateKey)

$form.Controls.Add($labelOutput)
$form.Controls.Add($textboxOutput)
$form.Controls.Add($labelFormat)
$form.Controls.Add($comboBoxFormat)
$form.Controls.Add($buttonConvert)

# Show the form
$null = $form.ShowDialog()
