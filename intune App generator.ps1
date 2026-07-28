# Import required libraries for GUI
Add-Type -AssemblyName 'System.Windows.Forms'
Add-Type -AssemblyName 'System.Drawing'

# Resolve the script directory so IntuneWinAppUtil.exe can be found reliably
$scriptDir = if ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $PSScriptRoot
}

$intuneWinAppUtilPath = Join-Path -Path $scriptDir -ChildPath 'IntuneWinAppUtil.exe'

function Get-SetupFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    $candidateFiles = Get-ChildItem -Path $FolderPath -File -Recurse -Include '*.exe', '*.msi', '*.cmd', '*.bat', '*.ps1' |
        Sort-Object -Property FullName

    return $candidateFiles | Select-Object -First 1
}

function Get-OutputFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SetupFolder,

        [Parameter(Mandatory = $true)]
        [string]$SetupFile
    )

    $parentFolder = [System.IO.Directory]::GetParent($SetupFolder).FullName
    $appName = [System.IO.Path]::GetFileNameWithoutExtension($SetupFile)
    $outputFolder = Join-Path -Path $parentFolder -ChildPath "$appName-wintune"

    if (-not (Test-Path -Path $outputFolder)) {
        $null = New-Item -ItemType Directory -Path $outputFolder -Force
    }

    return $outputFolder
}

# Define the main form (window)
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Intune WinApp Deployment - Content Prep Tool'
$form.Size = New-Object System.Drawing.Size(620, 420)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

# Label for status display
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Select the setup folder:'
$statusLabel.Location = New-Object System.Drawing.Point(20, 20)
$statusLabel.Size = New-Object System.Drawing.Size(560, 20)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$form.Controls.Add($statusLabel)

# TextBox to show the selected setup folder
$setupFolderTextBox = New-Object System.Windows.Forms.TextBox
$setupFolderTextBox.Location = New-Object System.Drawing.Point(20, 50)
$setupFolderTextBox.Size = New-Object System.Drawing.Size(430, 30)
$setupFolderTextBox.ReadOnly = $true
$form.Controls.Add($setupFolderTextBox)

# Button to browse for setup folder
$browseSetupFolderButton = New-Object System.Windows.Forms.Button
$browseSetupFolderButton.Text = 'Browse'
$browseSetupFolderButton.Location = New-Object System.Drawing.Point(460, 50)
$browseSetupFolderButton.Size = New-Object System.Drawing.Size(120, 30)
$browseSetupFolderButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = 'Choose the application setup folder.'

    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedFolder = $folderDialog.SelectedPath
        $setupFolderTextBox.Text = $selectedFolder

        $statusLabel.Text = 'Searching for installer files...'
        $setupFile = Get-SetupFile -FolderPath $selectedFolder

        if ($setupFile) {
            $setupFileTextBox.ReadOnly = $false
            $setupFileTextBox.ForeColor = [System.Drawing.Color]::Black
            $setupFileTextBox.BackColor = [System.Drawing.Color]::White
            $setupFileTextBox.Text = $setupFile.FullName
            $setupFileTextBox.ReadOnly = $true
            $setupFileTextBox.Refresh()

            $outputFolder = Get-OutputFolder -SetupFolder $selectedFolder -SetupFile $setupFile.Name
            $outputFolderTextBox.Text = $outputFolder

            $statusLabel.Text = 'Installer detected. Output folder has been prepared.'
        } else {
            $setupFileTextBox.ReadOnly = $false
            $setupFileTextBox.ForeColor = [System.Drawing.Color]::Red
            $setupFileTextBox.BackColor = [System.Drawing.Color]::FromArgb(255, 245, 245)
            $setupFileTextBox.Text = 'No .exe, .msi, .cmd, .bat, or .ps1 file found in the selected folder.'
            $setupFileTextBox.ReadOnly = $true
            $setupFileTextBox.Refresh()
            $outputFolderTextBox.Clear()
            $statusLabel.Text = 'No supported installer or script file was found in the selected folder.'
        }
    }
})
$form.Controls.Add($browseSetupFolderButton)

# TextBox to show the selected setup file
$setupFileTextBox = New-Object System.Windows.Forms.TextBox
$setupFileTextBox.Location = New-Object System.Drawing.Point(20, 100)
$setupFileTextBox.Size = New-Object System.Drawing.Size(560, 30)
$setupFileTextBox.ReadOnly = $true
$form.Controls.Add($setupFileTextBox)

# TextBox to show the selected output folder
$outputFolderTextBox = New-Object System.Windows.Forms.TextBox
$outputFolderTextBox.Location = New-Object System.Drawing.Point(20, 150)
$outputFolderTextBox.Size = New-Object System.Drawing.Size(560, 30)
$outputFolderTextBox.ReadOnly = $true
$form.Controls.Add($outputFolderTextBox)

# CheckBox for Quiet Mode
$quietModeCheckBox = New-Object System.Windows.Forms.CheckBox
$quietModeCheckBox.Text = 'Quiet Mode'
$quietModeCheckBox.Location = New-Object System.Drawing.Point(20, 200)
$quietModeCheckBox.Size = New-Object System.Drawing.Size(150, 25)
$form.Controls.Add($quietModeCheckBox)

# Button to generate .intunewin file
$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Text = 'Generate .intunewin File'
$generateButton.Location = New-Object System.Drawing.Point(20, 240)
$generateButton.Size = New-Object System.Drawing.Size(560, 35)
$generateButton.Add_Click({
    $setupFile = $setupFileTextBox.Text
    $setupFolder = $setupFolderTextBox.Text
    $outputFolder = $outputFolderTextBox.Text
    $quietMode = $quietModeCheckBox.Checked

    if (-not $setupFile -or -not $setupFolder -or -not $outputFolder) {
        $statusLabel.Text = 'Please browse for a setup folder first.'
        return
    }

    if (-not (Test-Path -Path $setupFolder)) {
        $statusLabel.Text = 'The selected setup folder could not be found.'
        return
    }

    if (-not (Test-Path -Path $setupFile)) {
        $statusLabel.Text = 'The selected installer file could not be found.'
        return
    }

    if (-not (Test-Path -Path $intuneWinAppUtilPath)) {
        $statusLabel.Text = 'IntuneWinAppUtil.exe was not found next to the script.'
        return
    }

    $arguments = @('-c', $setupFolder, '-s', $setupFile, '-o', $outputFolder)
    if ($quietMode) {
        $arguments += '-q'
    }

    $statusLabel.Text = 'Generating .intunewin file...'
    $generateButton.Enabled = $false
    $exitButton.Enabled = $false

    try {
        & $intuneWinAppUtilPath @arguments

        if ($LASTEXITCODE -ne 0) {
            throw "IntuneWinAppUtil exited with code $LASTEXITCODE."
        }

        $statusLabel.Text = "Successfully generated the .intunewin file in '$outputFolder'."
    } catch {
        $statusLabel.Text = "Error generating .intunewin file: $($_.Exception.Message)"
    } finally {
        $generateButton.Enabled = $true
        $exitButton.Enabled = $true
    }
})
$form.Controls.Add($generateButton)

# Button to exit
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = 'Exit'
$exitButton.Location = New-Object System.Drawing.Point(20, 290)
$exitButton.Size = New-Object System.Drawing.Size(560, 35)
$exitButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($exitButton)

# Show the form
$form.ShowDialog()
