#requires -Version 5.1
#requires -Modules ActiveDirectory

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$ADServer = 'HCC-DC01.hopecc.sa.edu.au'
$CredentialPath = Join-Path $env:LOCALAPPDATA 'StudentProvisioning\ADCred.xml'
$script:ADCred = $null

$script:Users = @()
$script:LastGeneratedPassword = ''
$script:CsvBuffer = New-Object System.Collections.Generic.List[object]
$script:ApiLastMode = 'simple'
$script:IsBusy = $false
$script:ClipboardTimer = $null

$defaultSearchBases = @(
    'OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au',
    'OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au'
)

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    $logBox.AppendText($line + [Environment]::NewLine)
    $logBox.ScrollToEnd()
}

function Get-ADCredentials {
    if ($null -eq $script:ADCred) {
        if (Test-Path $CredentialPath) {
            try {
                $script:ADCred = Import-Clixml $CredentialPath
            }
            catch {
                $script:ADCred = $null
            }
        }

        if (-not $script:ADCred) {
            $script:ADCred = Get-Credential -Message 'Enter AD credentials (HOPECC\username)'

            $CredentialFolder = Split-Path $CredentialPath
            if (-not (Test-Path $CredentialFolder)) {
                New-Item -ItemType Directory -Path $CredentialFolder -Force | Out-Null
            }

            $script:ADCred | Export-Clixml $CredentialPath
        }
    }

    return $script:ADCred
}

function Initialize-ADConnection {
    Import-Module ActiveDirectory -ErrorAction Stop
    $credential = Get-ADCredentials
    $domain = Get-ADDomain -Server $ADServer -Credential $credential -ErrorAction Stop

    return [PSCustomObject]@{
        Credential = $credential
        Domain = $domain.DNSRoot
    }
}

function Set-BusyState {
    param([bool]$Busy)

    $script:IsBusy = $Busy
    $btnLoadUsers.IsEnabled = -not $Busy
    $btnGenerate.IsEnabled = -not $Busy
    $btnApply.IsEnabled = -not $Busy
    $btnExport.IsEnabled = (-not $Busy) -and ($script:CsvBuffer.Count -gt 0)
    $btnCopy.IsEnabled = (-not $Busy) -and (-not [string]::IsNullOrWhiteSpace($txtGeneratedPassword.Text))
    $prgBusy.Visibility = if ($Busy) { 'Visible' } else { 'Collapsed' }
    $prgBusy.IsIndeterminate = $Busy
}

function Test-DinoPasswordPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CandidateText
    )

    # DinoPass usually returns child-friendly strings; enforce baseline policy guard before AD reset.
    if ($CandidateText.Length -lt 8) { return $false }
    if ($CandidateText -notmatch '[A-Za-z]') { return $false }
    if ($CandidateText -notmatch '[0-9]') { return $false }
    return $true
}

function New-FallbackPassword {
    param([int]$Length = 12)

    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@$%*?'
    $result = -join (1..$Length | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] })

    if ($result -notmatch '[A-Z]') { $result = 'A' + $result.Substring(1) }
    if ($result -notmatch '[a-z]') { $result = 'a' + $result.Substring(1) }
    if ($result -notmatch '[0-9]') { $result = '7' + $result.Substring(1) }

    return $result
}

function Get-DinoPassword {
    param(
        [ValidateSet('simple', 'strong')]
        [string]$Mode = 'simple'
    )

    $url = "https://www.dinopass.com/password/$Mode"

    try {
        $value = (Invoke-RestMethod -Uri $url -TimeoutSec 10).ToString().Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw 'DinoPass returned empty text.'
        }

        if (-not (Test-DinoPasswordPolicy -CandidateText $value)) {
            throw 'DinoPass password did not meet baseline policy checks.'
        }

        $script:ApiLastMode = $Mode
        return $value
    }
    catch {
        Write-Log "DinoPass unavailable or password rejected ($($_.Exception.Message)). Using local fallback generator." 'WARN'
        return (New-FallbackPassword)
    }
}

function Get-SelectedUserSam {
    if ($lstUsers.SelectedItem -is [string]) {
        return [string]$lstUsers.SelectedItem
    }

    return ''
}

function Start-ClipboardExpiryTimer {
    if ($script:ClipboardTimer) {
        $script:ClipboardTimer.Stop()
    }

    $script:ClipboardTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:ClipboardTimer.Interval = [TimeSpan]::FromSeconds(45)
    $script:ClipboardTimer.Add_Tick({
        try {
            [System.Windows.Forms.Clipboard]::Clear()
            Write-Log 'Clipboard cleared after 45 seconds for safety.' 'INFO'
        }
        catch {
            Write-Log "Clipboard clear failed: $($_.Exception.Message)" 'WARN'
        }
        finally {
            $script:ClipboardTimer.Stop()
        }
    })
    $script:ClipboardTimer.Start()
}

function Import-AdUsers {
    Set-BusyState -Busy $true
    try {
        $adSession = Initialize-ADConnection
        $searchBaseRaw = $txtSearchBase.Text.Trim()
        $searchBases = @()

        if ([string]::IsNullOrWhiteSpace($searchBaseRaw)) {
            $searchBases = $defaultSearchBases
        }
        else {
            $searchBases = $searchBaseRaw -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }

        $all = @()
        foreach ($base in $searchBases) {
            try {
                $segment = Get-ADUser -Filter 'Enabled -eq $true' -SearchBase $base -Server $ADServer -Credential $script:ADCred -Properties SamAccountName |
                    Select-Object -ExpandProperty SamAccountName
                $all += $segment
                Write-Log "Loaded users from $base" 'INFO'
            }
            catch {
                Write-Log "Could not query $base : $($_.Exception.Message)" 'WARN'
            }
        }

        $script:Users = $all | Sort-Object -Unique
        $lstUsers.ItemsSource = $script:Users
        $lblUserCount.Content = "Users: $($script:Users.Count)"
        Write-Log "User load complete. Found $($script:Users.Count) unique enabled accounts." 'SUCCESS'
    }
    catch {
        Write-Log "Failed to load AD users: $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show(
            "Failed to load users from AD.`n$($_.Exception.Message)",
            'Load Users Error',
            'OK',
            'Error'
        ) | Out-Null
    }
    finally {
        Set-BusyState -Busy $false
    }
}

function Update-UserFilter {
    $filter = $txtUserFilter.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($filter)) {
        $lstUsers.ItemsSource = $script:Users
        return
    }

    $filtered = $script:Users | Where-Object { $_ -like "*$filter*" }
    $lstUsers.ItemsSource = $filtered
}

function Invoke-PasswordReset {
    $sam = Get-SelectedUserSam
    if ([string]::IsNullOrWhiteSpace($sam)) {
        [System.Windows.MessageBox]::Show('Select a user first.', 'No User Selected', 'OK', 'Warning') | Out-Null
        return
    }

    $newPassword = $txtGeneratedPassword.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($newPassword)) {
        [System.Windows.MessageBox]::Show('Generate or type a password first.', 'No Password', 'OK', 'Warning') | Out-Null
        return
    }

    if (-not (Test-DinoPasswordPolicy -CandidateText $newPassword)) {
        [System.Windows.MessageBox]::Show('Password does not meet baseline policy checks (8+ chars, letters and numbers).', 'Policy Check', 'OK', 'Warning') | Out-Null
        return
    }

    $confirm = [System.Windows.MessageBox]::Show(
        "Reset password for user '$sam'?",
        'Confirm Password Reset',
        'YesNo',
        'Question'
    )

    if ($confirm -ne 'Yes') {
        Write-Log "Password reset cancelled for $sam" 'INFO'
        return
    }

    Set-BusyState -Busy $true
    try {
        $secure = ConvertTo-SecureString -AsPlainText $newPassword -Force
        Get-ADUser -Identity $sam -Server $ADServer -Credential $script:ADCred -ErrorAction Stop | Out-Null
        Set-ADAccountPassword -Identity $sam -Reset -NewPassword $secure -Server $ADServer -Credential $script:ADCred -ErrorAction Stop

        if ($chkUnlock.IsChecked) {
            Unlock-ADAccount -Identity $sam -Server $ADServer -Credential $script:ADCred -ErrorAction Stop
        }

        Set-ADUser -Identity $sam -ChangePasswordAtLogon ([bool]$chkChangeAtLogon.IsChecked) -Server $ADServer -Credential $script:ADCred -ErrorAction Stop

        if ($chkNeverExpires.IsChecked) {
            Set-ADUser -Identity $sam -PasswordNeverExpires $true -Server $ADServer -Credential $script:ADCred -ErrorAction Stop
        }

        $item = [PSCustomObject]@{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Username = $sam
            Password = $newPassword
            Source = if ($newPassword -eq $script:LastGeneratedPassword) { "DinoPass/$($script:ApiLastMode)" } else { 'Manual' }
            ChangeAtLogon = [bool]$chkChangeAtLogon.IsChecked
            UnlockTried = [bool]$chkUnlock.IsChecked
            NeverExpires = [bool]$chkNeverExpires.IsChecked
            Operator = $env:USERNAME
            Computer = $env:COMPUTERNAME
        }

        $script:CsvBuffer.Add($item)
        $btnExport.IsEnabled = $script:CsvBuffer.Count -gt 0

        Write-Log "Password updated successfully for $sam" 'SUCCESS'
        [System.Windows.MessageBox]::Show("Password updated for $sam", 'Success', 'OK', 'Information') | Out-Null
    }
    catch {
        Write-Log "Password reset failed for $sam : $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show(
            "Password reset failed for $sam.`n$($_.Exception.Message)",
            'Reset Error',
            'OK',
            'Error'
        ) | Out-Null
    }
    finally {
        Set-BusyState -Busy $false
    }
}

function Test-AdReadiness {
    Set-BusyState -Busy $true
    try {
        $adSession = Initialize-ADConnection
        Write-Log "AD ready. Domain: $($adSession.Domain)" 'SUCCESS'
        [System.Windows.MessageBox]::Show("Connected to AD domain: $($adSession.Domain)", 'AD Connection', 'OK', 'Information') | Out-Null
    }
    catch {
        Write-Log "AD readiness check failed: $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show("AD check failed.`n$($_.Exception.Message)", 'AD Connection', 'OK', 'Error') | Out-Null
    }
    finally {
        Set-BusyState -Busy $false
    }
}

function Export-Audit {
    if ($script:CsvBuffer.Count -eq 0) {
        [System.Windows.MessageBox]::Show('No records to export yet.', 'Export', 'OK', 'Information') | Out-Null
        return
    }

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = 'CSV Files (*.csv)|*.csv'
    $dialog.Title = 'Export Password Reset Audit'
    $dialog.FileName = "PasswordResetAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $script:CsvBuffer | Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8
            Write-Log "Audit exported to $($dialog.FileName)" 'SUCCESS'
            [System.Windows.MessageBox]::Show('Export complete.', 'Export', 'OK', 'Information') | Out-Null
        }
        catch {
            Write-Log "Export failed: $($_.Exception.Message)" 'ERROR'
            [System.Windows.MessageBox]::Show("Export failed.`n$($_.Exception.Message)", 'Export Error', 'OK', 'Error') | Out-Null
        }
    }
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AD Password Updater (DinoPass)"
        Width="980"
        Height="820"
        MinWidth="920"
        MinHeight="760"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        Background="#FFF8FAFC">
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#FF1F2937" CornerRadius="10" Padding="12" Margin="0,0,0,10">
            <DockPanel>
                <StackPanel DockPanel.Dock="Left">
                    <TextBlock Text="Active Directory Password Updater" FontSize="20" FontWeight="SemiBold" Foreground="White"/>
                    <TextBlock Text="WPF GUI with DinoPass generator, AD safety checks, and audit export" Foreground="#FFD1D5DB" Margin="0,4,0,0"/>
                </StackPanel>
                <ProgressBar x:Name="prgBusy" Width="160" Height="18" Visibility="Collapsed" VerticalAlignment="Center" HorizontalAlignment="Right"/>
            </DockPanel>
        </Border>

        <GroupBox Grid.Row="1" Header="Directory Query" Margin="0,0,0,10">
            <Grid Margin="10">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox x:Name="txtSearchBase" Grid.Column="0" Height="30"
                         Text="OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au;OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au"
                         ToolTip="Use one or more SearchBase values separated by semicolon (;)."/>
                <Button x:Name="btnLoadUsers" Grid.Column="1" Content="Load Users" Height="30" Width="110" Margin="10,0,0,0"/>
                <Button x:Name="btnCheckAd" Grid.Column="2" Content="Check AD" Height="30" Width="90" Margin="10,0,0,0"/>
                <Label x:Name="lblUserCount" Grid.Column="3" Content="Users: 0" VerticalAlignment="Center" Margin="10,0,0,0"/>
            </Grid>
        </GroupBox>

        <Grid Grid.Row="2" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="2*"/>
                <ColumnDefinition Width="3*"/>
            </Grid.ColumnDefinitions>

            <GroupBox Grid.Column="0" Header="User Selection" Margin="0,0,10,0">
                <DockPanel Margin="10">
                    <TextBox x:Name="txtUserFilter" Height="28" DockPanel.Dock="Top" Margin="0,0,0,8" ToolTip="Filter usernames"/>
                    <ListBox x:Name="lstUsers"
                             ScrollViewer.VerticalScrollBarVisibility="Auto"
                             ScrollViewer.HorizontalScrollBarVisibility="Auto"
                             ScrollViewer.CanContentScroll="True"/>
                </DockPanel>
            </GroupBox>

            <GroupBox Grid.Column="1" Header="Password Actions">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <TextBlock Grid.Row="0" Text="Selected User" FontWeight="SemiBold"/>
                    <TextBlock x:Name="txtSelectedUser" Grid.Row="1" Margin="0,4,0,10" Text="(none)" Foreground="#FF374151" FontSize="15"/>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,10">
                        <Button x:Name="btnGenerate" Content="Generate DinoPass" Width="160" Height="32"/>
                        <ComboBox x:Name="cmbMode" Width="120" Height="32" Margin="8,0,0,0" SelectedIndex="0">
                            <ComboBoxItem Content="simple"/>
                            <ComboBoxItem Content="strong"/>
                        </ComboBox>
                        <Button x:Name="btnCopy" Content="Copy" Width="80" Height="32" Margin="8,0,0,0"/>
                    </StackPanel>

                    <TextBox x:Name="txtGeneratedPassword" Grid.Row="3" Height="34" FontSize="16" FontFamily="Consolas"/>

                    <CheckBox x:Name="chkChangeAtLogon" Grid.Row="4" Margin="0,10,0,0" IsChecked="False" Content="Require change at next logon"/>
                    <CheckBox x:Name="chkUnlock" Grid.Row="5" Margin="0,4,0,0" IsChecked="True" Content="Unlock account after reset"/>
                    <CheckBox x:Name="chkNeverExpires" Grid.Row="5" Margin="260,4,0,0" IsChecked="True" Content="Set password never expires"/>
                    <StackPanel Grid.Row="6" Orientation="Horizontal" VerticalAlignment="Top" Margin="0,12,0,0">
                        <Button x:Name="btnApply" Content="Apply Password Reset" Width="170" Height="34" Background="#FF2563EB" Foreground="White" FontWeight="SemiBold"/>
                        <Button x:Name="btnExport" Content="Export Audit CSV" Width="130" Height="34" Margin="10,0,0,0"/>
                    </StackPanel>
                </Grid>
            </GroupBox>
        </Grid>

        <GroupBox Grid.Row="3" Header="Activity Log">
            <TextBox x:Name="logBox" Margin="10" IsReadOnly="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" FontFamily="Consolas" TextWrapping="Wrap"/>
        </GroupBox>

        <TextBlock Grid.Row="4" Margin="4" Foreground="#FF6B7280"
                   Text="Tip: Keep this tool limited to authorized admin workflows. Exports include plaintext passwords for operational handover."/>
    </Grid>
</Window>
"@

[xml]$xamlXml = $xaml
$reader = New-Object System.Xml.XmlNodeReader $xamlXml
$window = [Windows.Markup.XamlReader]::Load($reader)

$txtSearchBase = $window.FindName('txtSearchBase')
$btnLoadUsers = $window.FindName('btnLoadUsers')
$btnCheckAd = $window.FindName('btnCheckAd')
$lblUserCount = $window.FindName('lblUserCount')
$txtUserFilter = $window.FindName('txtUserFilter')
$lstUsers = $window.FindName('lstUsers')
$txtSelectedUser = $window.FindName('txtSelectedUser')
$btnGenerate = $window.FindName('btnGenerate')
$cmbMode = $window.FindName('cmbMode')
$btnCopy = $window.FindName('btnCopy')
$txtGeneratedPassword = $window.FindName('txtGeneratedPassword')
$chkChangeAtLogon = $window.FindName('chkChangeAtLogon')
$chkUnlock = $window.FindName('chkUnlock')
$chkNeverExpires = $window.FindName('chkNeverExpires')
$btnApply = $window.FindName('btnApply')
$btnExport = $window.FindName('btnExport')
$logBox = $window.FindName('logBox')
$prgBusy = $window.FindName('prgBusy')

$btnExport.IsEnabled = $false
$btnCopy.IsEnabled = $false

$btnLoadUsers.Add_Click({ Import-AdUsers })
$btnCheckAd.Add_Click({ Test-AdReadiness })
$txtUserFilter.Add_TextChanged({ Update-UserFilter })

$lstUsers.Add_SelectionChanged({
    $user = Get-SelectedUserSam
    $txtSelectedUser.Text = if ($user) { $user } else { '(none)' }
})

$btnGenerate.Add_Click({
    Set-BusyState -Busy $true
    try {
        $mode = (($cmbMode.SelectedItem).Content).ToString().Trim().ToLowerInvariant()
        $script:LastGeneratedPassword = Get-DinoPassword -Mode $mode
        $txtGeneratedPassword.Text = $script:LastGeneratedPassword
        $btnCopy.IsEnabled = $true
        Write-Log "Generated password using mode '$mode'." 'SUCCESS'
    }
    finally {
        Set-BusyState -Busy $false
    }
})

$btnCopy.Add_Click({
    if (-not [string]::IsNullOrWhiteSpace($txtGeneratedPassword.Text)) {
        [System.Windows.Forms.Clipboard]::SetText($txtGeneratedPassword.Text)
        Start-ClipboardExpiryTimer
        Write-Log 'Generated password copied to clipboard.' 'INFO'
    }
})

$btnApply.Add_Click({ Invoke-PasswordReset })
$btnExport.Add_Click({ Export-Audit })

$window.Add_ContentRendered({
    Write-Log 'Application started.' 'INFO'
    Write-Log 'Loading users automatically...' 'INFO'
    Import-AdUsers
    Write-Log 'Clipboard auto-clear is set to 45 seconds after copy.' 'INFO'
})

$window.Add_Closing({
    try {
        if ($script:ClipboardTimer) {
            $script:ClipboardTimer.Stop()
        }
        [System.Windows.Forms.Clipboard]::Clear()
    }
    catch {
        # Ignore clipboard cleanup exceptions during close.
    }
})

$null = $window.ShowDialog()
