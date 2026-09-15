# Import required libraries for GUI
[System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsBase') | Out-Null
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

function New-OutputFolderForInstaller {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseFolder,

        [Parameter(Mandatory = $true)]
        [string]$InstallerPath
    )

    $appName = [System.IO.Path]::GetFileNameWithoutExtension($InstallerPath)
    $outputFolder = Join-Path -Path $BaseFolder -ChildPath "$appName-wintune"

    if (-not (Test-Path -Path $outputFolder)) {
        $null = New-Item -ItemType Directory -Path $outputFolder -Force
    }

    return $outputFolder
}

function New-TempSourceFolderFromFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath
    )

    $tempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'IntuneWinAppUtil-Staging'
    if (-not (Test-Path -Path $tempRoot)) {
        $null = New-Item -ItemType Directory -Path $tempRoot -Force
    }

    $stagingFolder = Join-Path -Path $tempRoot -ChildPath ([Guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $stagingFolder -Force

    $copiedFilePath = Copy-Item -Path $InstallerPath -Destination $stagingFolder -Force -PassThru

    return @{
        SourceFolder = $stagingFolder
        SourceFile = $copiedFilePath.FullName
    }
}

$script:selectedOutputFolder = $null
$script:selectedSetupFolder = $null
$script:selectedInstallerPath = $null

$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Intune WinApp Deployment - Content Prep Tool"
    Width="620"
    Height="660"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    Background="#f4f7fb">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2563eb"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="14,10,14,10"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="border" Background="{TemplateBinding Background}" CornerRadius="10" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="#d1d5db"/>
                                <Setter Property="Foreground" Value="#9ca3af"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#ffffff"/>
            <Setter Property="BorderBrush" Value="#dfe7f3"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8,10,8"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#ffffff"/>
            <Setter Property="BorderBrush" Value="#dfe7f3"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8,10,8"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#1f2937"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Padding="14" Margin="0,0,0,10" Background="#ffffff" BorderBrush="#dfe7f3" BorderThickness="1" CornerRadius="14">
            <TextBlock Name="StatusLabel" Text="Select a setup folder or installer file:" FontSize="14" FontWeight="SemiBold" Foreground="#1f2937" TextWrapping="Wrap"/>
        </Border>

        <Grid Grid.Row="1" Margin="0,0,0,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox Name="SetupFolderText" Grid.Column="0" Height="36" IsReadOnly="True" VerticalContentAlignment="Center"/>
            <Button Name="BrowseButton" Grid.Column="1" Width="120" Height="36" Margin="12,0,0,0" Content="Browse"/>
        </Grid>

        <TextBlock Grid.Row="2" Margin="0,6,0,4" Text="Select installer/script file:" FontWeight="SemiBold"/>
        <ComboBox Name="InstallerComboBox" Grid.Row="3" Height="36" Margin="0,0,0,10" IsEnabled="False"/>

        <TextBlock Grid.Row="4" Margin="0,6,0,4" Text="Output folder:" FontWeight="SemiBold"/>
        <TextBox Name="OutputFolderText" Grid.Row="5" Height="36" Margin="0,0,0,10" IsReadOnly="True" VerticalContentAlignment="Center"/>

        <Border Grid.Row="6" Margin="0,0,0,10" Background="#ffffff" BorderBrush="#dfe7f3" BorderThickness="1" CornerRadius="12">
            <TextBox Name="LogText" Background="Transparent" BorderThickness="0" Padding="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" AcceptsReturn="True"/>
        </Border>

        <ProgressBar Name="LoadingBar" Grid.Row="7" Height="16" Margin="0,0,0,8" IsIndeterminate="True" Visibility="Collapsed" Foreground="#2563eb"/>
        <Button Name="GenerateButton" Grid.Row="8" Height="42" Content="Generate .intunewin File" Margin="0,0,0,0"/>
        <Button Name="OpenFolderButton" Grid.Row="9" Height="42" Content="Open Output Folder" Margin="0,8,0,0" IsEnabled="False"/>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$statusLabel = $window.FindName('StatusLabel')
$setupFolderText = $window.FindName('SetupFolderText')
$browseButton = $window.FindName('BrowseButton')
$installerComboBox = $window.FindName('InstallerComboBox')
$outputFolderText = $window.FindName('OutputFolderText')
$logText = $window.FindName('LogText')
$loadingBar = $window.FindName('LoadingBar')
$generateButton = $window.FindName('GenerateButton')
$openFolderButton = $window.FindName('OpenFolderButton')
$script:activeJob = $null

$jobPollTimer = New-Object System.Windows.Threading.DispatcherTimer
$jobPollTimer.Interval = [TimeSpan]::FromMilliseconds(250)
$jobPollTimer.Add_Tick({
    if ($null -eq $script:activeJob) { return }

    $jobState = $script:activeJob.State
    if ($jobState -eq 'Completed' -or $jobState -eq 'Failed' -or $jobState -eq 'Stopped') {
        $result = $null
        try {
            $result = Receive-Job -Job $script:activeJob -Keep
        } catch {
            $result = [pscustomobject]@{ Success = $false; Message = "Generation failed: $($_.Exception.Message)" }
        }

        $script:activeJob = $null
        $jobPollTimer.Stop()
        $loadingBar.Visibility = [System.Windows.Visibility]::Collapsed
        $generateButton.IsEnabled = $true

        if ($result -and $result.Success) {
            & $appendLog 'Generation completed successfully.'
            $statusLabel.Text = $result.Message
            $openFolderButton.IsEnabled = $true
        } else {
            $message = if ($result -and $result.Message) { $result.Message } else { 'Generation failed.' }
            if ($result -and $result.LogOutput) {
                & $appendLog '--- IntuneWinAppUtil output ---'
                foreach ($line in ($result.LogOutput -split "`r?`n")) {
                    if ($line) {
                        & $appendLog $line
                    }
                }
            }
            & $appendLog $message
            $statusLabel.Text = $message
            $openFolderButton.IsEnabled = $false
        }
    }
})

$appendLog = {
    param([string]$Message)

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $logText.Text += "[$timestamp] $Message`r`n"
    $logText.ScrollToEnd()
}

$browseButton.Add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = 'Installer files (*.exe;*.msi;*.bat;*.cmd;*.ps1)|*.exe;*.msi;*.bat;*.cmd;*.ps1'
    $fileDialog.Title = 'Select an installer file or press Cancel to choose a folder'

    $selectedPath = $null
    if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = $fileDialog.FileName
        if (Test-Path -Path $selectedPath) {
            $stagingData = New-TempSourceFolderFromFile -InstallerPath $selectedPath
            $script:selectedSetupFolder = $stagingData.SourceFolder
            $script:selectedOutputFolder = New-OutputFolderForInstaller -BaseFolder ([System.IO.Path]::GetDirectoryName($selectedPath)) -InstallerPath $selectedPath
            $setupFolderText.Text = $stagingData.SourceFolder
            $script:selectedInstallerPath = $stagingData.SourceFile
            $installerComboBox.IsEnabled = $false
            $installerComboBox.Items.Clear()
            $installerComboBox.SelectedIndex = -1
            $outputFolderText.Text = $script:selectedOutputFolder
            $statusLabel.Text = 'Single installer file detected and staged in a temporary folder.'
            return
        }
    }

    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = 'Choose the application setup folder.'

    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedFolder = $folderDialog.SelectedPath
        $script:selectedSetupFolder = $selectedFolder
        $script:selectedOutputFolder = $selectedFolder
        $setupFolderText.Text = $selectedFolder
        $outputFolderText.Text = $selectedFolder
        $installerComboBox.IsEnabled = $true
        $installerComboBox.Items.Clear()

        $statusLabel.Text = 'Searching for installer files...'
        $setupFiles = Get-SetupFiles -FolderPath $selectedFolder

        if ($setupFiles -and $setupFiles.Count -gt 0) {
            foreach ($setupFile in $setupFiles) {
                $null = $installerComboBox.Items.Add($setupFile.FullName)
            }

            $installerComboBox.SelectedIndex = 0
            $script:selectedInstallerPath = $setupFiles[0].FullName
            $script:selectedOutputFolder = New-OutputFolderForInstaller -BaseFolder $selectedFolder -InstallerPath $setupFiles[0].FullName
            $outputFolderText.Text = $script:selectedOutputFolder
            $statusLabel.Text = 'Folder selected. Choose an installer file from the dropdown.'
        } else {
            $script:selectedInstallerPath = $null
            $script:selectedOutputFolder = $null
            $installerComboBox.IsEnabled = $false
            $installerComboBox.Text = ''
            $statusLabel.Text = 'No .exe or .msi file was found in the selected folder.'
        }
    }
})

$installerComboBox.Add_SelectionChanged({
    if ($installerComboBox.SelectedItem -and $setupFolderText.Text) {
        $selectedSetupFilePath = [string]$installerComboBox.SelectedItem
        $script:selectedInstallerPath = $selectedSetupFilePath
        $script:selectedSetupFolder = [System.IO.Path]::GetDirectoryName($selectedSetupFilePath)
        $script:selectedOutputFolder = New-OutputFolderForInstaller -BaseFolder ([System.IO.Path]::GetDirectoryName($selectedSetupFilePath)) -InstallerPath $selectedSetupFilePath
        $outputFolderText.Text = $script:selectedOutputFolder
    }
})

$generateButton.Add_Click({
    $setupFile = if ($installerComboBox.SelectedItem) { [string]$installerComboBox.SelectedItem } elseif ($script:selectedInstallerPath) { [string]$script:selectedInstallerPath } else { '' }
    $setupFolder = if ($script:selectedSetupFolder) { $script:selectedSetupFolder } else { $setupFolderText.Text }
    $outputFolder = if ($script:selectedOutputFolder) { $script:selectedOutputFolder } else { $outputFolderText.Text }
    $logText.Text = ''

    if (-not $setupFile -or -not $setupFolder -or -not $outputFolder) {
        & $appendLog 'Validation failed: setup file, setup folder, or output folder is missing.'
        $statusLabel.Text = 'Please browse for a setup folder first.'
        return
    }

    if (-not (Test-Path -Path $setupFolder)) {
        & $appendLog "Validation failed: setup folder not found - $setupFolder"
        $statusLabel.Text = 'The selected setup folder could not be found.'
        return
    }

    if (-not (Test-Path -Path $setupFile)) {
        & $appendLog "Validation failed: setup file not found - $setupFile"
        $statusLabel.Text = 'The selected installer file could not be found.'
        return
    }

    if (-not (Test-Path -Path $intuneWinAppUtilPath)) {
        & $appendLog "Validation failed: IntuneWinAppUtil.exe not found - $intuneWinAppUtilPath"
        $statusLabel.Text = 'IntuneWinAppUtil.exe was not found next to the script.'
        return
    }

    $arguments = @('-c', $setupFolder, '-s', $setupFile, '-o', $outputFolder)
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
    $generateButton.IsEnabled = $false
    $openFolderButton.IsEnabled = $false
    $loadingBar.Visibility = [System.Windows.Visibility]::Visible

    $script:activeJob = Start-Job -ScriptBlock {
        param($exePath, $jobArgs, $jobOutputFolder)

        $combinedLogPath = Join-Path -Path $env:TEMP -ChildPath ("intunewin_output_{0}.log" -f ([Guid]::NewGuid().ToString('N')))
        $result = [ordered]@{
            Success = $false
            Message = ''
            LogOutput = ''
            OutputFolder = $jobOutputFolder
        }

        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $exePath
            $psi.WorkingDirectory = Split-Path -Parent $exePath
            $psi.Arguments = ($jobArgs | ForEach-Object {
                if ($_ -match '\s') {
                    '"{0}"' -f ($_ -replace '"', '\\"')
                } else {
                    $_
                }
            }) -join ' '
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($psi)
            $outputLines = New-Object System.Collections.Generic.List[string]

            while (-not $proc.HasExited) {
                $line = $proc.StandardOutput.ReadLine()
                if ($null -ne $line -and $line.Trim().Length -gt 0) {
                    $outputLines.Add($line.TrimEnd())
                }

                $errLine = $proc.StandardError.ReadLine()
                if ($null -ne $errLine -and $errLine.Trim().Length -gt 0) {
                    $outputLines.Add($errLine.TrimEnd())
                }
            }

            while (-not $proc.StandardOutput.EndOfStream) {
                $line = $proc.StandardOutput.ReadLine()
                if ($null -ne $line -and $line.Trim().Length -gt 0) {
                    $outputLines.Add($line.TrimEnd())
                }
            }

            while (-not $proc.StandardError.EndOfStream) {
                $line = $proc.StandardError.ReadLine()
                if ($null -ne $line -and $line.Trim().Length -gt 0) {
                    $outputLines.Add($line.TrimEnd())
                }
            }

            $result.LogOutput = ($outputLines -join "`r`n")
            if ($proc.ExitCode -ne 0) {
                throw "IntuneWinAppUtil exited with code $($proc.ExitCode)."
            }

            $generatedIntuneWin = Get-ChildItem -Path $jobOutputFolder -Filter '*.intunewin' -File -ErrorAction SilentlyContinue |
                Sort-Object -Property LastWriteTime -Descending |
                Select-Object -First 1

            $toolReportedSuccess = ($result.LogOutput -match 'generated successfully|Done!!!')
            if ($generatedIntuneWin -or $toolReportedSuccess) {
                $result.Success = $true
                $result.Message = "Successfully generated the .intunewin file in '$jobOutputFolder'."
            } else {
                throw 'IntuneWinAppUtil completed but did not report success.'
            }
        } catch {
            $result.Message = "Generation failed: $($_.Exception.Message)"
        } finally {
            if ($result.LogOutput) {
                $result.LogOutput | Out-File -FilePath $combinedLogPath -Encoding UTF8 -Force
            }
        }

        return $result
    } -ArgumentList $intuneWinAppUtilPath, $arguments, $outputFolder

    $jobPollTimer.Start()
})

$openFolderButton.Add_Click({
    if ($script:selectedOutputFolder -and (Test-Path -Path $script:selectedOutputFolder)) {
        Invoke-Item -Path $script:selectedOutputFolder
    }
})

$window.ShowDialog() | Out-Null
