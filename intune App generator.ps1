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

function Get-SetupFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    $candidateFiles = Get-ChildItem -Path $FolderPath -File -Recurse -Include '*.exe', '*.msi' |
        Sort-Object -Property FullName

    return $candidateFiles
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
$form.Size = New-Object System.Drawing.Size(620, 660)
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
        $setupFileComboBox.Items.Clear()
        $outputFolderTextBox.Clear()
        $progressBar.Style = 'Continuous'
        $progressBar.Value = 10

        $statusLabel.Text = 'Searching for installer files...'
        $setupFiles = Get-SetupFiles -FolderPath $selectedFolder

        if ($setupFiles -and $setupFiles.Count -gt 0) {
            foreach ($setupFile in $setupFiles) {
                $null = $setupFileComboBox.Items.Add($setupFile.FullName)
            }

            $setupFileComboBox.SelectedIndex = 0
            $progressBar.Value = 40
            $statusLabel.Text = 'Installer list loaded. Select a file from the dropdown.'
        } else {
            $setupFileComboBox.Text = ''
            $progressBar.Value = 0
            $statusLabel.Text = 'No .exe or .msi file was found in the selected folder.'
        }
    }
})
$form.Controls.Add($browseSetupFolderButton)

# Label for setup file dropdown
$setupFileLabel = New-Object System.Windows.Forms.Label
$setupFileLabel.Text = 'Select installer/script file:'
$setupFileLabel.Location = New-Object System.Drawing.Point(20, 82)
$setupFileLabel.Size = New-Object System.Drawing.Size(560, 18)
$setupFileLabel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$form.Controls.Add($setupFileLabel)

# Dropdown to show all available setup files
$setupFileComboBox = New-Object System.Windows.Forms.ComboBox
$setupFileComboBox.Location = New-Object System.Drawing.Point(20, 100)
$setupFileComboBox.Size = New-Object System.Drawing.Size(560, 30)
$setupFileComboBox.DropDownStyle = 'DropDownList'
$setupFileComboBox.Add_SelectedIndexChanged({
    if ($setupFileComboBox.SelectedItem -and $setupFolderTextBox.Text) {
        $selectedSetupFilePath = [string]$setupFileComboBox.SelectedItem
        $selectedSetupFileName = [System.IO.Path]::GetFileName($selectedSetupFilePath)
        $outputFolder = Get-OutputFolder -SetupFolder $setupFolderTextBox.Text -SetupFile $selectedSetupFileName
        $outputFolderTextBox.Text = $outputFolder
        $progressBar.Style = 'Continuous'
        $progressBar.Value = 55
    }
})
$form.Controls.Add($setupFileComboBox)

# TextBox to show the selected output folder
$outputFolderTextBox = New-Object System.Windows.Forms.TextBox
$outputFolderTextBox.Location = New-Object System.Drawing.Point(20, 150)
$outputFolderTextBox.Size = New-Object System.Drawing.Size(560, 30)
$outputFolderTextBox.ReadOnly = $true
$form.Controls.Add($outputFolderTextBox)

# Progress bar for workflow state
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 185)
$progressBar.Size = New-Object System.Drawing.Size(560, 10)
$progressBar.Style = 'Continuous'
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$form.Controls.Add($progressBar)

# CheckBox for Quiet Mode
$quietModeCheckBox = New-Object System.Windows.Forms.CheckBox
$quietModeCheckBox.Text = 'Quiet Mode'
$quietModeCheckBox.Location = New-Object System.Drawing.Point(20, 205)
$quietModeCheckBox.Size = New-Object System.Drawing.Size(150, 25)
$form.Controls.Add($quietModeCheckBox)

# Label for execution log
$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = 'Execution log:'
$logLabel.Location = New-Object System.Drawing.Point(20, 330)
$logLabel.Size = New-Object System.Drawing.Size(560, 20)
$logLabel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$form.Controls.Add($logLabel)

# TextBox to display execution details and errors
$logTextBox = New-Object System.Windows.Forms.TextBox
$logTextBox.Location = New-Object System.Drawing.Point(20, 350)
$logTextBox.Size = New-Object System.Drawing.Size(560, 240)
$logTextBox.Multiline = $true
$logTextBox.ScrollBars = 'Vertical'
$logTextBox.ReadOnly = $true
$logTextBox.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($logTextBox)

$appendLog = {
    param(
        [string]$Message
    )

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $logTextBox.AppendText("[$timestamp] $Message`r`n")
    $logTextBox.SelectionStart = $logTextBox.TextLength
    $logTextBox.ScrollToCaret()
}

# Button to generate .intunewin file
$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Text = 'Generate .intunewin File'
$generateButton.Location = New-Object System.Drawing.Point(20, 240)
$generateButton.Size = New-Object System.Drawing.Size(560, 35)
$generateButton.Add_Click({
    $setupFile = if ($setupFileComboBox.SelectedItem) { [string]$setupFileComboBox.SelectedItem } else { '' }
    $setupFolder = $setupFolderTextBox.Text
    $outputFolder = $outputFolderTextBox.Text
    $quietMode = $quietModeCheckBox.Checked
    $logTextBox.Clear()
    $progressBar.Style = 'Continuous'
    $progressBar.Value = 60

    if (-not $setupFile -or -not $setupFolder -or -not $outputFolder) {
        & $appendLog 'Validation failed: setup file, setup folder, or output folder is missing.'
        $progressBar.Value = 0
        $statusLabel.Text = 'Please browse for a setup folder first.'
        return
    }

    if (-not (Test-Path -Path $setupFolder)) {
        & $appendLog "Validation failed: setup folder not found - $setupFolder"
        $progressBar.Value = 0
        $statusLabel.Text = 'The selected setup folder could not be found.'
        return
    }

    if (-not (Test-Path -Path $setupFile)) {
        & $appendLog "Validation failed: setup file not found - $setupFile"
        $progressBar.Value = 0
        $statusLabel.Text = 'The selected installer file could not be found.'
        return
    }

    if (-not (Test-Path -Path $intuneWinAppUtilPath)) {
        & $appendLog "Validation failed: IntuneWinAppUtil.exe not found - $intuneWinAppUtilPath"
        $progressBar.Value = 0
        $statusLabel.Text = 'IntuneWinAppUtil.exe was not found next to the script.'
        return
    }

    $arguments = @('-c', $setupFolder, '-s', $setupFile, '-o', $outputFolder)
    if ($quietMode) {
        $arguments += '-q'
    }

    $quotedArguments = $arguments | ForEach-Object {
        if ($_ -match '\s') {
            '"{0}"' -f ($_ -replace '"', '\\"')
        } else {
            $_
        }
    }

    & $appendLog "Running: $intuneWinAppUtilPath $($quotedArguments -join ' ')"
    & $appendLog "Setup folder: $setupFolder"
    & $appendLog "Setup file: $setupFile"
    & $appendLog "Output folder: $outputFolder"

    $statusLabel.Text = 'Generating .intunewin file...'
    $progressBar.Style = 'Marquee'
    $generateButton.Enabled = $false
    $exitButton.Enabled = $false

    $stdoutLogPath = Join-Path -Path $env:TEMP -ChildPath ("intunewin_stdout_{0}.log" -f ([Guid]::NewGuid().ToString('N')))
    $stderrLogPath = Join-Path -Path $env:TEMP -ChildPath ("intunewin_stderr_{0}.log" -f ([Guid]::NewGuid().ToString('N')))
    $maxRuntimeMs = 1800000

    try {
        $process = Start-Process -FilePath $intuneWinAppUtilPath -ArgumentList $arguments -PassThru -NoNewWindow -RedirectStandardOutput $stdoutLogPath -RedirectStandardError $stderrLogPath

        $elapsedMs = 0
        while (-not $process.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 250
            $elapsedMs += 250

            if ($elapsedMs % 5000 -eq 0) {
                & $appendLog ("Still running... {0} seconds elapsed." -f [int]($elapsedMs / 1000))
            }

            if ($elapsedMs -ge $maxRuntimeMs) {
                try {
                    $process.Kill()
                } catch {
                }
                throw 'Generation timed out after 30 minutes. Check the execution log for last known progress.'
            }
        }

        $process.WaitForExit()

        if (Test-Path -Path $stdoutLogPath) {
            $stdoutContent = [string](Get-Content -Path $stdoutLogPath -Raw -ErrorAction SilentlyContinue)
            if (-not [string]::IsNullOrWhiteSpace($stdoutContent)) {
                & $appendLog '--- IntuneWinAppUtil output ---'
                foreach ($line in ($stdoutContent -split "`r?`n")) {
                    if ($line) {
                        & $appendLog $line
                    }
                }
            }
        }

        if (Test-Path -Path $stderrLogPath) {
            $stderrContent = [string](Get-Content -Path $stderrLogPath -Raw -ErrorAction SilentlyContinue)
            if (-not [string]::IsNullOrWhiteSpace($stderrContent)) {
                & $appendLog '--- IntuneWinAppUtil errors ---'
                foreach ($line in ($stderrContent -split "`r?`n")) {
                    if ($line) {
                        & $appendLog $line
                    }
                }
            }
        }

        if ($process.ExitCode -ne 0) {
            throw "IntuneWinAppUtil exited with code $($process.ExitCode)."
        }

        & $appendLog 'Generation completed successfully.'
        $progressBar.Style = 'Continuous'
        $progressBar.Value = 100
        $statusLabel.Text = "Successfully generated the .intunewin file in '$outputFolder'."
    } catch {
        & $appendLog "Generation failed: $($_.Exception.Message)"
        $progressBar.Style = 'Continuous'
        $progressBar.Value = 0
        $statusLabel.Text = "Error generating .intunewin file: $($_.Exception.Message)"
    } finally {
        if (Test-Path -Path $stdoutLogPath) {
            Remove-Item -Path $stdoutLogPath -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -Path $stderrLogPath) {
            Remove-Item -Path $stderrLogPath -Force -ErrorAction SilentlyContinue
        }

        $generateButton.Enabled = $true
        $exitButton.Enabled = $true
    }
})
$form.Controls.Add($generateButton)

# Button to exit
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = 'Exit'
$exitButton.Location = New-Object System.Drawing.Point(20, 285)
$exitButton.Size = New-Object System.Drawing.Size(560, 35)
$exitButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($exitButton)

# Show the form
$form.ShowDialog()
