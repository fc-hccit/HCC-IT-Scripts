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
$script:RecentlyDisabledUsers = @()
$script:AuditRecords = New-Object System.Collections.Generic.List[object]
$script:IsBusy = $false

$script:SearchBases = @{
    Students = 'OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au'
    Staff    = 'OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au'
}
$script:SelectedAudience = 'Students'
$RecentlyDisabledDays = 30

function Get-SelectedSearchBase {
    return $script:SearchBases[$script:SelectedAudience]
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logBox.AppendText("[$timestamp] [$Level] $Message" + [Environment]::NewLine)
    $logBox.ScrollToEnd()
}

function Get-ADCredentials {
    if ($null -eq $script:ADCred) {
        if (Test-Path -LiteralPath $CredentialPath) {
            try {
                $script:ADCred = Import-Clixml -LiteralPath $CredentialPath
            }
            catch {
                $script:ADCred = $null
            }
        }

        if (-not $script:ADCred) {
            $script:ADCred = Get-Credential -Message 'Enter AD credentials (HOPECC\username)'
            if (-not $script:ADCred) {
                throw 'Active Directory credentials were not provided.'
            }

            $credentialFolder = Split-Path -Parent $CredentialPath
            if (-not (Test-Path -LiteralPath $credentialFolder)) {
                New-Item -ItemType Directory -Path $credentialFolder -Force | Out-Null
            }

            $script:ADCred | Export-Clixml -LiteralPath $CredentialPath
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
        Domain     = $domain.DNSRoot
    }
}

function Set-BusyState {
    param([bool]$Busy)

    $script:IsBusy = $Busy
    $btnStudents.IsEnabled = -not $Busy
    $btnStaff.IsEnabled = -not $Busy
    $btnLoadUsers.IsEnabled = -not $Busy
    $btnCheckAd.IsEnabled = -not $Busy
    $btnDisable.IsEnabled = -not $Busy
    $btnEnable.IsEnabled = (-not $Busy) -and ($lstRecentlyDisabled.SelectedItems.Count -gt 0)
    $btnExport.IsEnabled = (-not $Busy) -and ($script:AuditRecords.Count -gt 0)
    $prgBusy.Visibility = if ($Busy) { 'Visible' } else { 'Collapsed' }
    $prgBusy.IsIndeterminate = $Busy
}

function Import-AdUsers {
    Set-BusyState -Busy $true
    try {
        $null = Initialize-ADConnection
        $searchBase = Get-SelectedSearchBase
        $all = [System.Collections.Generic.List[string]]::new()
        $segment = Get-ADUser -Filter 'Enabled -eq $true' -SearchBase $searchBase `
            -Server $ADServer -Credential $script:ADCred -ErrorAction Stop |
            Select-Object -ExpandProperty SamAccountName
        foreach ($sam in $segment) {
            $all.Add($sam)
        }
        Write-Log "Loaded enabled users from $script:SelectedAudience directory ($searchBase)" 'INFO'

        $script:Users = @($all | Sort-Object -Unique)
        $lstUsers.ItemsSource = $script:Users
        $lblUserCount.Text = "Enabled users: $($script:Users.Count)"
        Write-Log "User load complete. Found $($script:Users.Count) unique enabled accounts." 'SUCCESS'

        $cutoff = (Get-Date).AddDays(-$RecentlyDisabledDays)
        $disabledUsers = @(Get-ADUser -Filter 'Enabled -eq $false' -SearchBase $searchBase `
                -Server $ADServer -Credential $script:ADCred -Properties Enabled, whenChanged `
                -ErrorAction Stop |
            Where-Object { $_.whenChanged -ge $cutoff } |
            Sort-Object whenChanged -Descending)
        $script:RecentlyDisabledUsers = @(
            foreach ($user in $disabledUsers) {
                [PSCustomObject]@{
                    SamAccountName = $user.SamAccountName
                    DisplayText    = '{0} ({1}) - changed {2:yyyy-MM-dd HH:mm}' -f
                        $user.Name, $user.SamAccountName, $user.whenChanged
                }
            }
        )
        $lstRecentlyDisabled.ItemsSource = $script:RecentlyDisabledUsers
        $lblRecentlyDisabledCount.Text = "Changed in last $RecentlyDisabledDays days: $($script:RecentlyDisabledUsers.Count)"
        Write-Log "Loaded $($script:RecentlyDisabledUsers.Count) disabled $($script:SelectedAudience.ToLowerInvariant()) account(s) changed since $($cutoff.ToString('yyyy-MM-dd'))." 'INFO'
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

function Set-AccountAudience {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Students', 'Staff')]
        [string]$Audience
    )

    if ($script:SelectedAudience -eq $Audience) {
        return
    }

    $script:SelectedAudience = $Audience
    $txtSearchBase.Text = Get-SelectedSearchBase
    $btnStudents.Background = if ($Audience -eq 'Students') {
        [System.Windows.Media.Brushes]::SteelBlue
    } else {
        [System.Windows.Media.Brushes]::LightGray
    }
    $btnStudents.Foreground = if ($Audience -eq 'Students') {
        [System.Windows.Media.Brushes]::White
    } else {
        [System.Windows.Media.Brushes]::Black
    }
    $btnStaff.Background = if ($Audience -eq 'Staff') {
        [System.Windows.Media.Brushes]::SteelBlue
    } else {
        [System.Windows.Media.Brushes]::LightGray
    }
    $btnStaff.Foreground = if ($Audience -eq 'Staff') {
        [System.Windows.Media.Brushes]::White
    } else {
        [System.Windows.Media.Brushes]::Black
    }

    $script:Users = @()
    $script:RecentlyDisabledUsers = @()
    $lstUsers.ItemsSource = $script:Users
    $lstRecentlyDisabled.ItemsSource = $script:RecentlyDisabledUsers
    $lblUserCount.Text = 'Enabled users: 0'
    $lblRecentlyDisabledCount.Text = "Changed in last $RecentlyDisabledDays days: 0"
    Write-Log "Switched directory to $Audience." 'INFO'
    Import-AdUsers
}

function Update-UserFilter {
    $filter = $txtUserFilter.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($filter)) {
        $lstUsers.ItemsSource = $script:Users
        return
    }

    $lstUsers.ItemsSource = @($script:Users | Where-Object { $_ -like "*$filter*" })
}

function ConvertTo-LdapFilterValue {
    param([Parameter(Mandatory = $true)][string]$Value)

    return $Value.Replace('\', '\5c').
        Replace('*', '\2a').
        Replace('(', '\28').
        Replace(')', '\29').
        Replace([string][char]0, '\00')
}

function Get-InputIdentities {
    $identities = [System.Collections.Generic.List[string]]::new()
    foreach ($selected in $lstUsers.SelectedItems) {
        $identities.Add([string]$selected)
    }

    foreach ($line in ($txtIdentities.Text -split '[,\r\n;]+')) {
        $identity = $line.Trim()
        if (-not [string]::IsNullOrWhiteSpace($identity)) {
            $identities.Add($identity)
        }
    }

    return @($identities | Sort-Object -Unique)
}

function Add-AuditRecord {
    param(
        [Parameter(Mandatory = $true)][string]$Identity,
        [string]$SamAccountName,
        [string]$DisplayName,
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][string]$Details
    )

    $script:AuditRecords.Add([PSCustomObject]@{
        Timestamp       = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        InputIdentity   = $Identity
        SamAccountName  = $SamAccountName
        DisplayName     = $DisplayName
        Status          = $Status
        Details         = $Details
        Operator        = $env:USERNAME
        Computer        = $env:COMPUTERNAME
    })
    $btnExport.IsEnabled = $true
}

function Invoke-AccountDisable {
    $identities = @(Get-InputIdentities)
    if ($identities.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            'Select one or more users, or enter sAMAccountName/userPrincipalName values.',
            'No Users Specified',
            'OK',
            'Warning'
        ) | Out-Null
        return
    }

    $preview = ($identities | Select-Object -First 10) -join "`n"
    if ($identities.Count -gt 10) {
        $preview += "`n...and $($identities.Count - 10) more"
    }
    $confirm = [System.Windows.MessageBox]::Show(
        "Disable $($identities.Count) Active Directory account(s)?`n`n$preview`n`nThis does not disable email or move accounts between OUs.",
        'Confirm Account Disable',
        'YesNo',
        'Warning'
    )
    if ($confirm -ne 'Yes') {
        Write-Log 'Account disable operation cancelled.' 'INFO'
        return
    }

    Set-BusyState -Busy $true
    $disabledCount = 0
    $alreadyDisabledCount = 0
    $failedCount = 0
    try {
        $null = Initialize-ADConnection

        foreach ($identity in $identities) {
            try {
                $escapedIdentity = ConvertTo-LdapFilterValue -Value $identity
                $matches = @(Get-ADUser -LDAPFilter "(|(sAMAccountName=$escapedIdentity)(userPrincipalName=$escapedIdentity))" `
                        -SearchBase (Get-SelectedSearchBase) -Server $ADServer `
                        -Credential $script:ADCred -Properties Enabled `
                        -ErrorAction Stop)

                if ($matches.Count -eq 0) {
                    throw "No AD user matched '$identity'."
                }
                if ($matches.Count -gt 1) {
                    throw "More than one AD user matched '$identity'; no account was changed."
                }

                $user = $matches[0]
                if (-not $user.Enabled) {
                    $alreadyDisabledCount++
                    Add-AuditRecord -Identity $identity -SamAccountName $user.SamAccountName `
                        -DisplayName $user.Name -Status 'AlreadyDisabled' `
                        -Details 'Account was already disabled.'
                    Write-Log "Account $($user.SamAccountName) is already disabled." 'INFO'
                    continue
                }

                Disable-ADAccount -Identity $user.DistinguishedName -Server $ADServer `
                    -Credential $script:ADCred -Confirm:$false -ErrorAction Stop
                $disabledCount++
                Add-AuditRecord -Identity $identity -SamAccountName $user.SamAccountName `
                    -DisplayName $user.Name -Status 'Disabled' -Details 'Account disabled.'
                Write-Log "Disabled account $($user.SamAccountName)." 'SUCCESS'
            }
            catch {
                $failedCount++
                $details = $_.Exception.Message
                Add-AuditRecord -Identity $identity -Status 'Failed' -Details $details
                Write-Log "Could not disable '$identity': $details" 'ERROR'
            }
        }
    }
    catch {
        Write-Log "Active Directory connection failed: $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show(
            "Could not connect to Active Directory.`n$($_.Exception.Message)",
            'Active Directory Error',
            'OK',
            'Error'
        ) | Out-Null
        return
    }
    finally {
        Set-BusyState -Busy $false
    }

    $summary = "Processed $($identities.Count) account(s): $disabledCount disabled, $alreadyDisabledCount already disabled, $failedCount failed."
    Write-Log $summary $(if ($failedCount -gt 0) { 'WARN' } else { 'SUCCESS' })
    [System.Windows.MessageBox]::Show(
        $summary,
        'Disable Results',
        'OK',
        $(if ($failedCount -gt 0) { 'Warning' } else { 'Information' })
    ) | Out-Null
}

function Invoke-AccountEnable {
    $selectedUsers = @($lstRecentlyDisabled.SelectedItems)
    if ($selectedUsers.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "Select one or more recently changed disabled $($script:SelectedAudience.ToLowerInvariant()) accounts first.",
            'No Users Selected',
            'OK',
            'Warning'
        ) | Out-Null
        return
    }

    $identities = @($selectedUsers | ForEach-Object { $_.SamAccountName })
    $preview = ($identities | Select-Object -First 10) -join "`n"
    if ($identities.Count -gt 10) {
        $preview += "`n...and $($identities.Count - 10) more"
    }
    $confirm = [System.Windows.MessageBox]::Show(
        "Re-enable $($identities.Count) Active Directory $($script:SelectedAudience.ToLowerInvariant()) account(s)?`n`n$preview",
        'Confirm Account Re-enable',
        'YesNo',
        'Warning'
    )
    if ($confirm -ne 'Yes') {
        Write-Log 'Account re-enable operation cancelled.' 'INFO'
        return
    }

    Set-BusyState -Busy $true
    $enabledCount = 0
    $failedCount = 0
    try {
        $null = Initialize-ADConnection
        $cutoff = (Get-Date).AddDays(-$RecentlyDisabledDays)

        foreach ($identity in $identities) {
            try {
                $escapedIdentity = ConvertTo-LdapFilterValue -Value $identity
                $matches = @(Get-ADUser -LDAPFilter "(sAMAccountName=$escapedIdentity)" `
                        -SearchBase (Get-SelectedSearchBase) -Server $ADServer `
                        -Credential $script:ADCred -Properties Enabled, whenChanged `
                        -ErrorAction Stop)

                if ($matches.Count -ne 1) {
                    throw "$($script:SelectedAudience) account '$identity' was not found in the selected directory."
                }

                $user = $matches[0]
                if ($user.Enabled) {
                    throw "Account '$identity' is already enabled."
                }
                if ($user.whenChanged -lt $cutoff) {
                    throw "Account '$identity' is no longer within the $RecentlyDisabledDays-day changed window."
                }

                Enable-ADAccount -Identity $user.DistinguishedName -Server $ADServer `
                    -Credential $script:ADCred -Confirm:$false -ErrorAction Stop
                $enabledCount++
                Add-AuditRecord -Identity $identity -SamAccountName $user.SamAccountName `
                    -DisplayName $user.Name -Status 'Re-enabled' -Details 'Account enabled.'
                Write-Log "Re-enabled account $($user.SamAccountName)." 'SUCCESS'
            }
            catch {
                $failedCount++
                $details = $_.Exception.Message
                Add-AuditRecord -Identity $identity -Status 'EnableFailed' -Details $details
                Write-Log "Could not re-enable '$identity': $details" 'ERROR'
            }
        }
    }
    catch {
        Write-Log "Active Directory connection failed: $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show(
            "Could not connect to Active Directory.`n$($_.Exception.Message)",
            'Active Directory Error',
            'OK',
            'Error'
        ) | Out-Null
        return
    }
    finally {
        Set-BusyState -Busy $false
    }

    $summary = "Processed $($identities.Count) account(s): $enabledCount re-enabled, $failedCount failed."
    Write-Log $summary $(if ($failedCount -gt 0) { 'WARN' } else { 'SUCCESS' })
    [System.Windows.MessageBox]::Show(
        $summary,
        'Re-enable Results',
        'OK',
        $(if ($failedCount -gt 0) { 'Warning' } else { 'Information' })
    ) | Out-Null
    Import-AdUsers
}

function Test-AdReadiness {
    Set-BusyState -Busy $true
    try {
        $adSession = Initialize-ADConnection
        Write-Log "AD ready. Domain: $($adSession.Domain)" 'SUCCESS'
        [System.Windows.MessageBox]::Show(
            "Connected to AD domain: $($adSession.Domain)",
            'AD Connection',
            'OK',
            'Information'
        ) | Out-Null
    }
    catch {
        Write-Log "AD readiness check failed: $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show(
            "AD check failed.`n$($_.Exception.Message)",
            'AD Connection',
            'OK',
            'Error'
        ) | Out-Null
    }
    finally {
        Set-BusyState -Busy $false
    }
}

function Export-Audit {
    if ($script:AuditRecords.Count -eq 0) {
        [System.Windows.MessageBox]::Show('No records to export yet.', 'Export', 'OK', 'Information') | Out-Null
        return
    }

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = 'CSV Files (*.csv)|*.csv'
    $dialog.Title = 'Export Account Disable Audit'
    $dialog.FileName = "AccountDisableAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $script:AuditRecords | Export-Csv -LiteralPath $dialog.FileName -NoTypeInformation -Encoding UTF8
            Write-Log "Audit exported to $($dialog.FileName)" 'SUCCESS'
            [System.Windows.MessageBox]::Show('Export complete.', 'Export', 'OK', 'Information') | Out-Null
        }
        catch {
            Write-Log "Export failed: $($_.Exception.Message)" 'ERROR'
            [System.Windows.MessageBox]::Show(
                "Export failed.`n$($_.Exception.Message)",
                'Export Error',
                'OK',
                'Error'
            ) | Out-Null
        }
    }
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AD Account Disabler"
        Width="900"
        Height="760"
        MinWidth="780"
        MinHeight="660"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        Background="#FFF8FAFC">
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="3*"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#FF1F2937" CornerRadius="10" Padding="12" Margin="0,0,0,10">
            <DockPanel>
                <StackPanel DockPanel.Dock="Left">
                    <TextBlock Text="Active Directory Account Disabler" FontSize="20" FontWeight="SemiBold" Foreground="White"/>
                    <TextBlock Text="Disable selected or entered AD accounts with confirmation and audit logging" Foreground="#FFD1D5DB" Margin="0,4,0,0"/>
                </StackPanel>
                <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center" Margin="12,0,0,0">
                    <Button x:Name="btnStudents" Content="Students" Width="88" Height="32"
                            Background="#FF4682B4" Foreground="White" FontWeight="SemiBold"
                            ToolTip="Manage student accounts"/>
                    <Button x:Name="btnStaff" Content="Staff" Width="72" Height="32" Margin="8,0,0,0"
                            Background="#FFD3D3D3" Foreground="Black" FontWeight="SemiBold"
                            ToolTip="Manage staff accounts"/>
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
                </Grid.ColumnDefinitions>
                <TextBox x:Name="txtSearchBase" Grid.Column="0" Height="30"
                         Text="OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
                         IsReadOnly="True"
                         ToolTip="User lookup is restricted to this OU."/>
                <Button x:Name="btnLoadUsers" Grid.Column="1" Content="Load Users" Height="30" Width="110" Margin="10,0,0,0"/>
                <Button x:Name="btnCheckAd" Grid.Column="2" Content="Check AD" Height="30" Width="90" Margin="10,0,0,0"/>
            </Grid>
        </GroupBox>

        <Grid Grid.Row="2" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <GroupBox Grid.Column="0" Header="Select users from Active Directory">
                <DockPanel Margin="10">
                    <TextBlock x:Name="lblUserCount" DockPanel.Dock="Bottom" Margin="0,8,0,0" Foreground="#FF6B7280" Text="Enabled users: 0"/>
                    <StackPanel DockPanel.Dock="Top" Margin="0,0,0,8">
                        <TextBox x:Name="txtUserFilter" Height="28" ToolTip="Filter users by sAMAccountName"/>
                    </StackPanel>
                    <ListBox x:Name="lstUsers" SelectionMode="Extended"/>
                </DockPanel>
            </GroupBox>

            <GroupBox Grid.Column="1" Header="Or enter users">
                <DockPanel Margin="10">
                    <TextBlock DockPanel.Dock="Top" Margin="0,0,0,8" TextWrapping="Wrap" Foreground="#FF4B5563"
                               Text="Enter one sAMAccountName or userPrincipalName per line. Commas and semicolons are also accepted."/>
                    <TextBox x:Name="txtIdentities" AcceptsReturn="True" TextWrapping="NoWrap"
                             VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                             FontFamily="Consolas" ToolTip="Example: jsmith or jsmith@hopecc.sa.edu.au"/>
                </DockPanel>
            </GroupBox>

            <GroupBox Grid.Column="2" Header="Recently disabled accounts">
                <DockPanel Margin="10">
                    <TextBlock DockPanel.Dock="Top" Margin="0,0,0,8" TextWrapping="Wrap" Foreground="#FF4B5563"
                               Text="Disabled accounts in the selected directory whose whenChanged value is within the last 30 days. This can include other account changes, not only disabling."/>
                    <TextBlock x:Name="lblRecentlyDisabledCount" DockPanel.Dock="Bottom" Margin="0,8,0,0"
                               Foreground="#FF6B7280" Text="Changed in last 30 days: 0"/>
                    <ListBox x:Name="lstRecentlyDisabled" SelectionMode="Extended" DisplayMemberPath="DisplayText"/>
                </DockPanel>
            </GroupBox>
        </Grid>

        <GroupBox Grid.Row="3" Header="Actions and Activity">
            <Grid Margin="10">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
                    <Button x:Name="btnDisable" Content="Disable Account(s)" Width="160" Height="34"
                            Background="#FFB91C1C" Foreground="White" FontWeight="SemiBold"/>
                    <Button x:Name="btnEnable" Content="Re-enable Selected" Width="150" Height="34" Margin="10,0,0,0"
                            Background="#FF15803D" Foreground="White" FontWeight="SemiBold"/>
                    <Button x:Name="btnExport" Content="Export Audit CSV" Width="130" Height="34" Margin="10,0,0,0"/>
                </StackPanel>
                <TextBox x:Name="logBox" Grid.Row="1" IsReadOnly="True" VerticalScrollBarVisibility="Auto"
                         HorizontalScrollBarVisibility="Auto" FontFamily="Consolas" TextWrapping="Wrap"/>
            </Grid>
        </GroupBox>

        <TextBlock Grid.Row="4" Margin="4" Foreground="#FF6B7280"
                   Text="This tool disables Active Directory accounts only. It does not suspend email or move accounts to another OU."/>
    </Grid>
</Window>
"@

[xml]$xamlXml = $xaml
$reader = New-Object System.Xml.XmlNodeReader $xamlXml
$window = [Windows.Markup.XamlReader]::Load($reader)

$txtSearchBase = $window.FindName('txtSearchBase')
$btnStudents = $window.FindName('btnStudents')
$btnStaff = $window.FindName('btnStaff')
$btnLoadUsers = $window.FindName('btnLoadUsers')
$btnCheckAd = $window.FindName('btnCheckAd')
$lblUserCount = $window.FindName('lblUserCount')
$txtUserFilter = $window.FindName('txtUserFilter')
$lstUsers = $window.FindName('lstUsers')
$txtIdentities = $window.FindName('txtIdentities')
$lstRecentlyDisabled = $window.FindName('lstRecentlyDisabled')
$lblRecentlyDisabledCount = $window.FindName('lblRecentlyDisabledCount')
$btnDisable = $window.FindName('btnDisable')
$btnEnable = $window.FindName('btnEnable')
$btnExport = $window.FindName('btnExport')
$logBox = $window.FindName('logBox')
$prgBusy = $window.FindName('prgBusy')

$txtSearchBase.Text = Get-SelectedSearchBase
$btnExport.IsEnabled = $false
$btnStudents.Add_Click({ Set-AccountAudience -Audience 'Students' })
$btnStaff.Add_Click({ Set-AccountAudience -Audience 'Staff' })
$btnLoadUsers.Add_Click({ Import-AdUsers })
$btnCheckAd.Add_Click({ Test-AdReadiness })
$txtUserFilter.Add_TextChanged({ Update-UserFilter })
$btnDisable.Add_Click({ Invoke-AccountDisable })
$lstRecentlyDisabled.Add_SelectionChanged({
    $btnEnable.IsEnabled = (-not $script:IsBusy) -and ($lstRecentlyDisabled.SelectedItems.Count -gt 0)
})
$btnEnable.Add_Click({ Invoke-AccountEnable })
$btnExport.Add_Click({ Export-Audit })

$window.Add_ContentRendered({
    Write-Log 'Application started.' 'INFO'
    Write-Log 'Loading enabled users automatically...' 'INFO'
    Import-AdUsers
})

$null = $window.ShowDialog()
