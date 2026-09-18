[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$requiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Groups',
    'Microsoft.Graph.Users'
)
$graphModuleVersion = [version]'2.35.1'
foreach ($module in $requiredModules) {
    $availableModule = Get-Module -ListAvailable -Name $module | Where-Object Version -eq $graphModuleVersion
    if (-not $availableModule) {
        throw "The PowerShell module '$module' version $graphModuleVersion is required. Install it with: Install-Module $module -RequiredVersion $graphModuleVersion -Scope CurrentUser"
    }
    Import-Module $module -RequiredVersion $graphModuleVersion -ErrorAction Stop
}

$scopes = @('DeviceManagementManagedDevices.Read.All', 'User.Read.All')
$defaultMailDomain = 'ccmschools.onmicrosoft.com'
$priorityUserDomain = 'hopecc.sa.edu.au'

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Microsoft 365 Group Creator" Height="850" Width="1040"
        MinHeight="700" MinWidth="850" WindowStartupLocation="CenterScreen"
        Background="#F5F7FA" FontFamily="Segoe UI">
    <Window.Resources>
        <SolidColorBrush x:Key="Ink" Color="#17212B" />
        <SolidColorBrush x:Key="Muted" Color="#61707D" />
        <SolidColorBrush x:Key="Line" Color="#DCE3E8" />
        <SolidColorBrush x:Key="Teal" Color="#007F86" />
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="{StaticResource Ink}" />
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="10,7" />
            <Setter Property="Margin" Value="0,4,0,12" />
            <Setter Property="BorderBrush" Value="{StaticResource Line}" />
            <Setter Property="BorderThickness" Value="1" />
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Padding" Value="8,6" />
            <Setter Property="Margin" Value="0,4,0,12" />
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="0,5,0,5" />
        </Style>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="14,8" />
            <Setter Property="Margin" Value="4" />
            <Setter Property="Cursor" Value="Hand" />
        </Style>
    </Window.Resources>
    <Grid Margin="28">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,18">
            <TextBlock Text="Microsoft 365 Group Creator" FontSize="27" FontWeight="SemiBold" />
            <TextBlock Text="Create a ready-to-use group for your team" Foreground="{StaticResource Muted}" FontSize="14" Margin="0,4,0,0" />
        </StackPanel>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <Border Background="White" BorderBrush="{StaticResource Line}" BorderThickness="1" Padding="20" Margin="0,0,0,14">
                    <StackPanel>
                        <TextBlock Text="GROUP DETAILS" FontSize="12" FontWeight="Bold" Foreground="{StaticResource Teal}" />
                        <TextBlock Text="Group name *" FontWeight="SemiBold" Margin="0,16,0,0" />
                        <TextBox Name="GroupName" Text="HCC " />
                        <TextBlock Text="Description" FontWeight="SemiBold" />
                        <TextBox Name="Description" Height="65" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" />
                        <TextBlock Text="Email address *" FontWeight="SemiBold" />
                        <TextBox Name="EmailAddress" />
                        <TextBlock Text="Format: hcc.groupname@ccmschools.onmicrosoft.com. Spaces are removed automatically." Foreground="{StaticResource Muted}" FontSize="12" Margin="0,-8,0,10" />
                        <CheckBox Name="AddHopeCcAlias" Content="Add a HopeCC secondary email address" ToolTip="Uses Exchange Online to add the address to the new Microsoft 365 Group." IsChecked="False" Margin="0,5,0,5" />
                        <TextBox Name="HopeCcAlias" Text="pestaff@hopecc.sa.edu.au" IsEnabled="False" />
                        <TextBlock Text="Privacy" FontWeight="SemiBold" />
                        <ComboBox Name="Privacy"><ComboBoxItem Content="Private" IsSelected="True" /><ComboBoxItem Content="Public" /></ComboBox>
                    </StackPanel>
                </Border>
                <Grid Margin="0,0,0,14">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                    <Border Grid.Column="0" Background="White" BorderBrush="{StaticResource Line}" BorderThickness="1" Padding="20" Margin="0,0,7,0">
                        <StackPanel>
                            <TextBlock Text="OWNERS" FontSize="12" FontWeight="Bold" Foreground="{StaticResource Teal}" />
                            <TextBlock Text="At least one owner is required." Foreground="{StaticResource Muted}" FontSize="12" Margin="0,4,0,10" />
                            <Grid Margin="0,0,0,8">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>
                                <TextBox Name="OwnerSearch" Grid.Column="0" Margin="0,0,6,0" />
                                <Button Name="OwnerSearchButton" Grid.Column="1" Content="Search" Margin="0" />
                            </Grid>
                            <ListBox Name="OwnerResults" Height="105" DisplayMemberPath="Display" />
                            <TextBlock Text="Selected owners" FontWeight="SemiBold" Margin="0,12,0,4" />
                            <ListBox Name="SelectedOwners" Height="75" DisplayMemberPath="Display" />
                        </StackPanel>
                    </Border>
                    <Border Grid.Column="1" Background="White" BorderBrush="{StaticResource Line}" BorderThickness="1" Padding="20" Margin="7,0,0,0">
                        <StackPanel>
                            <TextBlock Text="MEMBERS" FontSize="12" FontWeight="Bold" Foreground="{StaticResource Teal}" />
                            <TextBlock Text="Optional. Search and select one or more members." Foreground="{StaticResource Muted}" FontSize="12" Margin="0,4,0,10" />
                            <Grid Margin="0,0,0,8">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>
                                <TextBox Name="MemberSearch" Grid.Column="0" Margin="0,0,6,0" />
                                <Button Name="MemberSearchButton" Grid.Column="1" Content="Search" Margin="0" />
                            </Grid>
                            <ListBox Name="MemberResults" Height="105" DisplayMemberPath="Display" />
                            <TextBlock Text="Selected members" FontWeight="SemiBold" Margin="0,12,0,4" />
                            <ListBox Name="SelectedMembers" Height="75" DisplayMemberPath="Display" />
                        </StackPanel>
                    </Border>
                </Grid>
                <Border Background="White" BorderBrush="{StaticResource Line}" BorderThickness="1" Padding="20" Margin="0,0,0,14">
                    <StackPanel>
                        <TextBlock Text="EMAIL &amp; SUBSCRIPTION" FontSize="12" FontWeight="Bold" Foreground="{StaticResource Teal}" />
                        <CheckBox Name="AutoSubscribe" Content="Send group conversations and events to members' inboxes" ToolTip="New members receive group email notifications in their inbox." IsChecked="True" Margin="0,15,0,5" />
                        <TextBlock Text="New members receive group email notifications in their inbox." Foreground="{StaticResource Muted}" FontSize="12" Margin="24,0,0,8" />
                        <CheckBox Name="ExternalSenders" Content="Allow external senders" ToolTip="People outside your organization can send messages to the group." IsChecked="False" />
                        <TextBlock Text="People outside your organization can send messages to the group." Foreground="{StaticResource Muted}" FontSize="12" Margin="24,0,0,8" />
                        <TextBlock Text="External members are controlled by tenant and Exchange policies and are not exposed here because Microsoft Graph does not provide a supported group update property for this setting." Foreground="{StaticResource Muted}" FontSize="12" TextWrapping="Wrap" Margin="24,0,0,0" />
                    </StackPanel>
                </Border>
                <Border Name="SummaryPanel" Background="#E9F4F3" Padding="18" Visibility="Collapsed" Margin="0,0,0,14">
                    <StackPanel>
                        <TextBlock Text="CONFIRMATION" FontSize="12" FontWeight="Bold" Foreground="{StaticResource Teal}" />
                        <TextBlock Name="SummaryText" TextWrapping="Wrap" Margin="0,8,0,0" />
                    </StackPanel>
                </Border>
                <Border Name="ProgressPanel" Background="White" BorderBrush="{StaticResource Line}" BorderThickness="1" Padding="20" Visibility="Collapsed" Margin="0,0,0,14">
                    <StackPanel>
                        <TextBlock Name="ProgressTitle" Text="Creating group..." FontSize="17" FontWeight="SemiBold" />
                        <TextBlock Name="ProgressText" TextWrapping="Wrap" Margin="0,12,0,0" />
                    </StackPanel>
                </Border>
                <TextBlock Name="StatusText" Foreground="#B42318" TextWrapping="Wrap" Margin="0,0,0,8" />
            </StackPanel>
        </ScrollViewer>
        <DockPanel Grid.Row="2" LastChildFill="False" Margin="0,14,0,0">
            <TextBlock Name="SignedInText" Text="Not connected" Foreground="{StaticResource Muted}" VerticalAlignment="Center" DockPanel.Dock="Left" />
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
                <Button Name="ConnectButton" Content="Connect to Microsoft Graph" />
                <Button Name="CreateButton" Content="Create Microsoft 365 Group" Background="{StaticResource Teal}" Foreground="White" IsEnabled="False" />
            </StackPanel>
        </DockPanel>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$names = @('GroupName','Description','EmailAddress','Privacy','OwnerSearch','OwnerSearchButton','OwnerResults','SelectedOwners','MemberSearch','MemberSearchButton','MemberResults','SelectedMembers','AutoSubscribe','ExternalSenders','AddHopeCcAlias','HopeCcAlias','SummaryPanel','SummaryText','ProgressPanel','ProgressTitle','ProgressText','StatusText','SignedInText','ConnectButton','CreateButton')
$controls = @{}
foreach ($name in $names) { $controls[$name] = $window.FindName($name) }

$selectedOwners = [System.Collections.ArrayList]::new()
$selectedMembers = [System.Collections.ArrayList]::new()
$script:connected = $false
$script:updatingAlias = $false
$script:updatingGroupName = $false

function Set-Status {
    param([string]$Message, [bool]$IsError = $true)
    $controls.StatusText.Text = $Message
    $controls.StatusText.Foreground = if ($IsError) { [Windows.Media.Brushes]::Firebrick } else { [Windows.Media.Brushes]::DarkGreen }
}

function Set-AliasFromName {
    $groupNameForEmail = $controls.GroupName.Text -replace '^hcc[\s._-]*', ''
    $alias = 'hcc.' + ($groupNameForEmail.ToLowerInvariant() -replace '[^a-z0-9._-]', '')
    if ($alias.Length -gt 64) { $alias = $alias.Substring(0, 64).TrimEnd('._-') }
    if (-not $controls.EmailAddress.Tag) {
        $script:updatingAlias = $true
        $controls.EmailAddress.Text = "$alias@$defaultMailDomain"
        $script:updatingAlias = $false
    }
}

function Ensure-HccGroupName {
    if ($script:updatingGroupName -or [string]::IsNullOrWhiteSpace($controls.GroupName.Text)) { return }
    if ($controls.GroupName.Text -notmatch '^HCC(?:\s|$)') {
        $script:updatingGroupName = $true
        $controls.GroupName.Text = "HCC $($controls.GroupName.Text.Trim())"
        $controls.GroupName.CaretIndex = $controls.GroupName.Text.Length
        $script:updatingGroupName = $false
    }
}

function Get-UserDisplay {
    param($User)
    [pscustomobject]@{ Id = $User.Id; Display = "$($User.DisplayName) <$($User.UserPrincipalName)>" }
}

function Search-Users {
    param([string]$Query, $ResultsControl)
    if (-not $script:connected) { Set-Status 'Connect to Microsoft Graph before searching for users.'; return }
    if ([string]::IsNullOrWhiteSpace($Query)) { Set-Status 'Enter a name or email address to search.'; return }
    try {
        $safeQuery = $Query.Replace("'", "''")
        $users = Get-MgUser -Filter "startsWith(displayName,'$safeQuery') or startsWith(userPrincipalName,'$safeQuery')" -ConsistencyLevel eventual -CountVariable ignored -Top 25 -Property Id,DisplayName,UserPrincipalName
        $users = $users | Sort-Object @{ Expression = { if ($_.UserPrincipalName -like "*@${priorityUserDomain}") { 0 } else { 1 } } }, DisplayName
        $ResultsControl.Items.Clear()
        foreach ($user in $users) { [void]$ResultsControl.Items.Add((Get-UserDisplay $user)) }
        Set-Status "$($ResultsControl.Items.Count) user(s) found." $false
    } catch { Set-Status "User search failed: $($_.Exception.Message)" }
}

function Add-SelectedUser {
    param($ResultControl, $SelectedControl, [System.Collections.ArrayList]$Collection)
    $user = $ResultControl.SelectedItem
    if ($null -eq $user) { return }
    if (-not ($Collection | Where-Object Id -eq $user.Id)) {
        [void]$Collection.Add($user)
        $SelectedControl.Items.Add($user) | Out-Null
    }
}

$controls.GroupName.Add_TextChanged({ Ensure-HccGroupName; Set-AliasFromName })
$controls.EmailAddress.Add_TextChanged({ if (-not $script:updatingAlias) { $controls.EmailAddress.Tag = $true } })
$controls.AddHopeCcAlias.Add_Checked({ $controls.HopeCcAlias.IsEnabled = $true })
$controls.AddHopeCcAlias.Add_Unchecked({ $controls.HopeCcAlias.IsEnabled = $false })
$controls.OwnerSearchButton.Add_Click({ Search-Users $controls.OwnerSearch.Text $controls.OwnerResults })
$controls.MemberSearchButton.Add_Click({ Search-Users $controls.MemberSearch.Text $controls.MemberResults })
$controls.OwnerSearch.Add_KeyDown({ if ($_.Key -eq 'Return') { Search-Users $controls.OwnerSearch.Text $controls.OwnerResults } })
$controls.MemberSearch.Add_KeyDown({ if ($_.Key -eq 'Return') { Search-Users $controls.MemberSearch.Text $controls.MemberResults } })
$controls.OwnerResults.Add_MouseDoubleClick({ Add-SelectedUser $controls.OwnerResults $controls.SelectedOwners $selectedOwners })
$controls.MemberResults.Add_MouseDoubleClick({ Add-SelectedUser $controls.MemberResults $controls.SelectedMembers $selectedMembers })
$controls.ConnectButton.Add_Click({
    try {
        Connect-MgGraph -Scopes $scopes -ContextScope Process -NoWelcome | Out-Null
        $context = Get-MgContext
        $script:connected = $true
        $controls.SignedInText.Text = "Connected: $($context.Account)"
        $controls.ConnectButton.IsEnabled = $false
        $controls.CreateButton.IsEnabled = $true
        Set-Status 'Connected to Microsoft Graph.' $false
    } catch { Set-Status "Connection failed: $($_.Exception.Message)" }
})

$controls.CreateButton.Add_Click({
    $name = $controls.GroupName.Text.Trim()
    $emailAddress = $controls.EmailAddress.Text.Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($name)) { Set-Status 'Group name is required.'; return }
    if ([string]::IsNullOrWhiteSpace($emailAddress) -or $emailAddress -notmatch "^hcc\.[a-z0-9][a-z0-9._-]{0,59}@$([regex]::Escape($defaultMailDomain))$") { Set-Status "Enter an email address in the format hcc.groupname@$defaultMailDomain without spaces."; return }
    if ($selectedOwners.Count -eq 0) { Set-Status 'Select at least one owner.'; return }
    $hopeCcAlias = $controls.HopeCcAlias.Text.Trim().ToLowerInvariant()
    if ($controls.AddHopeCcAlias.IsChecked -and $hopeCcAlias -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') { Set-Status 'Enter a valid HopeCC email address.'; return }
    $alias = $emailAddress.Substring(0, $emailAddress.IndexOf('@'))
    $privacy = $controls.Privacy.SelectedItem.Content
    $controls.SummaryText.Text = "Name: $name`nEmail address: $emailAddress`nPrivacy: $privacy`nOwners: $($selectedOwners.Count) | Members: $($selectedMembers.Count)"
    $controls.SummaryPanel.Visibility = 'Visible'
    $answer = [System.Windows.MessageBox]::Show($controls.SummaryText.Text + "`n`nCreate this Microsoft 365 Group?", 'Confirm group creation', 'YesNo', 'Question')
    if ($answer -ne 'Yes') { return }
    $controls.CreateButton.IsEnabled = $false
    $controls.ProgressPanel.Visibility = 'Visible'
    $controls.ProgressText.Text = 'Creating group...'
    $controls.StatusText.Text = ''
    try {
        $bindOwners = @($selectedOwners | ForEach-Object { "https://graph.microsoft.com/v1.0/users/$($_.Id)" })
        $bindMembers = @($selectedMembers | ForEach-Object { "https://graph.microsoft.com/v1.0/users/$($_.Id)" })
        $body = @{
            displayName = $name
            description = $controls.Description.Text.Trim()
            groupTypes = @('Unified')
            mailEnabled = $true
            mailNickname = $alias
            securityEnabled = $false
            visibility = $privacy
            'owners@odata.bind' = $bindOwners
        }
        if ($bindMembers.Count -gt 0) { $body['members@odata.bind'] = $bindMembers }
        $group = New-MgGroup -BodyParameter $body
        $controls.ProgressText.Text += "`n✓ Group created"
        $patch = @{}
        if ($controls.AutoSubscribe.IsChecked) { $patch.autoSubscribeNewMembers = $true }
        if ($controls.ExternalSenders.IsChecked) { $patch.allowExternalSenders = $true }
        if ($patch.Count -gt 0) {
            Update-MgGroup -GroupId $group.Id -BodyParameter $patch
        }
        $controls.ProgressText.Text += "`n✓ Owners added"
        $controls.ProgressText.Text += "`n✓ Members added"
        $controls.ProgressText.Text += "`n✓ Email settings configured"
            if ($controls.AddHopeCcAlias.IsChecked) {
                Import-Module ExchangeOnlineManagement -ErrorAction Stop
                Connect-ExchangeOnline -ShowBanner:$false
                Set-UnifiedGroup -Identity $emailAddress -EmailAddresses @{ Add = $hopeCcAlias }
                $controls.ProgressText.Text += "`n✓ HopeCC alias added"
            }
        $controls.ProgressText.Text += "`n✓ Services provisioned"
        $controls.ProgressTitle.Text = 'Group created successfully'
        $mail = if ($group.Mail) { $group.Mail } else { $emailAddress }
        $controls.ProgressText.Text += "`n`n$name`n$mail"
        $controls.ProgressTitle.Foreground = [Windows.Media.Brushes]::DarkGreen
    } catch {
        $controls.ProgressTitle.Text = 'Creation could not be completed'
        Set-Status "Graph request failed: $($_.Exception.Message)"
        $controls.CreateButton.IsEnabled = $true
    }
})

$window.Add_ContentRendered({
    $controls.ConnectButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
})

[void]$window.ShowDialog()
