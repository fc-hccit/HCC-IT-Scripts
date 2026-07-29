<#
.SYNOPSIS
    Deletes local user profiles from a WPF GUI.

.DESCRIPTION
    Loads Windows user profiles from Win32_UserProfile and displays them in a WPF list.
    The user can refresh the list, select a profile, and delete it after confirmation.
    A checkbox allows removing the profile folder from disk as well.

.NOTES
    Requires Windows with WPF support.
#>

[CmdletBinding()]
param()

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="User Profile Deleter" Height="480" Width="760" WindowStartupLocation="CenterScreen">
    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Delete local Windows user profiles safely." FontWeight="Bold" Margin="0,0,0,8"/>

        <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,8">
            <TextBox Name="txtSearch" Width="280" Margin="0,0,8,0" />
            <Button Name="btnRefresh" Content="Refresh" Width="90" Margin="0,0,8,0" />
            <Button Name="btnDelete" Content="Delete Selected" Width="120" IsDefault="True" />
        </StackPanel>

        <ListView Name="lvProfiles" Grid.Row="2" Margin="0,0,0,8">
            <ListView.ItemContainerStyle>
                <Style TargetType="ListViewItem">
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding IsCurrentUser}" Value="True">
                            <Setter Property="Foreground" Value="Red" />
                            <Setter Property="FontWeight" Value="Bold" />
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </ListView.ItemContainerStyle>
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="User" DisplayMemberBinding="{Binding UserName}" Width="140" />
                    <GridViewColumn Header="Local Path" DisplayMemberBinding="{Binding LocalPath}" Width="280" />
                    <GridViewColumn Header="Loaded" DisplayMemberBinding="{Binding Loaded}" Width="80" />
                    <GridViewColumn Header="Last Used" DisplayMemberBinding="{Binding LastUseTime}" Width="180" />
                </GridView>
            </ListView.View>
        </ListView>

        <StackPanel Grid.Row="3" Orientation="Horizontal">
            <CheckBox Name="chkDeleteFolder" Content="Remove profile folder from disk" Margin="0,0,12,0" />
            <TextBlock Name="txtStatus" Text="Ready" VerticalAlignment="Center" TextWrapping="Wrap" />
        </StackPanel>
    </Grid>
</Window>
'@

$reader = New-Object System.IO.StringReader($xaml.OuterXml)
$xmlReader = [System.Xml.XmlReader]::Create($reader)
$window = [System.Windows.Markup.XamlReader]::Load($xmlReader)

$btnRefresh = $window.FindName('btnRefresh')
$btnDelete = $window.FindName('btnDelete')
$lvProfiles = $window.FindName('lvProfiles')
$txtSearch = $window.FindName('txtSearch')
$chkDeleteFolder = $window.FindName('chkDeleteFolder')
$txtStatus = $window.FindName('txtStatus')

$allProfiles = @()
$currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$currentUserName = [System.Environment]::UserName

function Update-Status {
    param([string]$Message)
    $txtStatus.Text = $Message
}

function Get-ProfileItems {
    $items = @()

    try {
        $profiles = @(Get-CimInstance -ClassName Win32_UserProfile -ErrorAction Stop | Where-Object {
            $_.LocalPath -and
            $_.SID -and
            $_.LocalPath -notmatch '^C:\\Users\\(Default|Public)$'
        })

        foreach ($profile in $profiles) {
            $localPath = $profile.LocalPath
            $userName = [System.IO.Path]::GetFileName($localPath)
            if ([string]::IsNullOrWhiteSpace($userName)) {
                $userName = $profile.SID
            }

            $items += [pscustomobject]@{
                SID = $profile.SID
                UserName = $userName
                LocalPath = $localPath
                Loaded = $profile.Loaded
                LastUseTime = $profile.LastUseTime
                IsCurrentUser = $profile.SID -eq $currentSid
            }
        }
    }
    catch {
        Update-Status "Unable to read profiles: $($_.Exception.Message)"
    }

    return $items | Sort-Object UserName
}

function Refresh-Profiles {
    $global:allProfiles = @(Get-ProfileItems)
    $searchValue = $txtSearch.Text

    if ([string]::IsNullOrWhiteSpace($searchValue)) {
        $lvProfiles.ItemsSource = $global:allProfiles
    }
    else {
        $searchValue = $searchValue.ToLowerInvariant()
        $filtered = $global:allProfiles | Where-Object {
            $_.UserName.ToLowerInvariant().Contains($searchValue) -or
            $_.LocalPath.ToLowerInvariant().Contains($searchValue) -or
            $_.SID.ToLowerInvariant().Contains($searchValue)
        }
        $lvProfiles.ItemsSource = @($filtered)
    }

    $btnDelete.IsEnabled = $false
    Update-Status "Loaded $($global:allProfiles.Count) profiles."
}

$btnRefresh.Add_Click({
    param($sender, $e)
    Refresh-Profiles
})

$btnDelete.Add_Click({
    param($sender, $e)

    $selected = $lvProfiles.SelectedItem
    if (-not $selected) {
        Update-Status "Select a profile before deleting it."
        return
    }

    if ($selected.SID -eq $currentSid -or $selected.UserName -eq $currentUserName) {
        [System.Windows.MessageBox]::Show(
            "The currently signed-in profile cannot be deleted from this tool.",
            "Action blocked",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    $deleteFolder = $chkDeleteFolder.IsChecked
    $confirm = [System.Windows.MessageBox]::Show(
        "Delete profile '$($selected.UserName)' from '$($selected.LocalPath)'?",
        "Confirm deletion",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )

    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
        return
    }

    try {
        $sid = $selected.SID
        $localPath = $selected.LocalPath
        $profileKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' + $sid

        if ($deleteFolder -eq $true -and (Test-Path -LiteralPath $localPath)) {
            Remove-Item -LiteralPath $localPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path -LiteralPath $profileKey) {
            Remove-Item -LiteralPath $profileKey -Force -ErrorAction SilentlyContinue
        }

        $profilePath = Join-Path $env:SystemDrive 'Users'
        $userFolder = Split-Path $localPath -Leaf
        if ($userFolder -and $userFolder -ne 'Users' -and (Test-Path -LiteralPath (Join-Path $profilePath $userFolder))) {
            Remove-Item -LiteralPath (Join-Path $profilePath $userFolder) -Recurse -Force -ErrorAction SilentlyContinue
        }

        Update-Status "Deleted profile '$($selected.UserName)'."
        Refresh-Profiles
    }
    catch {
        Update-Status "Delete failed: $($_.Exception.Message)"
    }
})

$lvProfiles.Add_SelectionChanged({
    param($sender, $e)
    $selected = $lvProfiles.SelectedItem
    if ($selected -and $selected.IsCurrentUser) {
        $btnDelete.IsEnabled = $false
        Update-Status "The current logged-in profile cannot be deleted."
    }
    else {
        $btnDelete.IsEnabled = $null -ne $selected
    }
})

$txtSearch.Add_TextChanged({
    param($sender, $e)
    $searchValue = $txtSearch.Text

    if ([string]::IsNullOrWhiteSpace($searchValue)) {
        $lvProfiles.ItemsSource = $global:allProfiles
    }
    else {
        $searchValue = $searchValue.ToLowerInvariant()
        $filtered = $global:allProfiles | Where-Object {
            $_.UserName.ToLowerInvariant().Contains($searchValue) -or
            $_.LocalPath.ToLowerInvariant().Contains($searchValue) -or
            $_.SID.ToLowerInvariant().Contains($searchValue)
        }
        $lvProfiles.ItemsSource = @($filtered)
    }
})

$window.Add_Loaded({
    Refresh-Profiles
})

[void]$window.ShowDialog()
