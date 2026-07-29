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
    Write-Host "[STATUS] $Message"
}

function Write-LogEntry {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] $Message"
    Add-Content -Path (Join-Path $PSScriptRoot 'userprofile-deleter.log') -Value $logLine
    Write-Host $logLine
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

    if ($selected.Loaded -eq $true) {
        Write-LogEntry "Profile is still loaded/in use; skipping delete for SID=$($selected.SID) User=$($selected.UserName)"
        Update-Status "Skipped '$($selected.UserName)' because it is still loaded/in use."
        [System.Windows.MessageBox]::Show(
            "This profile is currently loaded or in use. Log off the user or restart the device, then try again.",
            "Action blocked",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    try {
        $sid = $selected.SID
        $localPath = $selected.LocalPath
        $profileKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' + $sid

        Write-LogEntry "Starting delete for SID=$sid User=$($selected.UserName) Path=$localPath"
        Update-Status "Deleting '$($selected.UserName)'..."

        if ($deleteFolder -eq $true -and (Test-Path -LiteralPath $localPath)) {
            Write-LogEntry "Removing folder: $localPath"
            Remove-Item -LiteralPath $localPath -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $localPath) {
                Write-LogEntry "Primary removal failed; trying alternate cleanup for hidden/system files"
                $items = @(Get-ChildItem -LiteralPath $localPath -Force -ErrorAction SilentlyContinue)
                foreach ($item in $items) {
                    try {
                        if ($item.PSIsContainer) {
                            Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        }
                        else {
                            Remove-Item -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
                        }
                    }
                    catch {
                        Write-LogEntry "Could not remove item: $($item.FullName)"
                    }
                }

                if (Test-Path -LiteralPath $localPath) {
                    $folderItem = Get-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
                    $folderAttributes = $folderItem.Attributes
                    Write-LogEntry "Folder still exists after alternate cleanup. Attributes=$folderAttributes"
                    $remainingItems = @(Get-ChildItem -LiteralPath $localPath -Force -ErrorAction SilentlyContinue)
                    if ($remainingItems.Count -gt 0) {
                        $remainingNames = ($remainingItems | Select-Object -ExpandProperty FullName) -join '; '
                        Write-LogEntry "Remaining items under folder: $remainingNames"
                    }
                }
                else {
                    Write-LogEntry "Folder removal complete after alternate cleanup. ExistsAfter=False"
                }
            }
            else {
                Write-LogEntry "Folder removal complete. ExistsAfter=False"
            }
        }
        else {
            Write-LogEntry "Folder removal skipped. DeleteFolder=$deleteFolder Exists=$(Test-Path -LiteralPath $localPath)"
        }

        if (Test-Path -LiteralPath $profileKey) {
            Write-LogEntry "Removing registry key: $profileKey"
            Remove-Item -LiteralPath $profileKey -Force -ErrorAction SilentlyContinue
            Write-LogEntry "Registry key removal complete. ExistsAfter=$(Test-Path -LiteralPath $profileKey)"
        }
        else {
            Write-LogEntry "Registry key not found: $profileKey"
        }

        $profilePath = Join-Path $env:SystemDrive 'Users'
        $userFolder = Split-Path $localPath -Leaf
        if ($userFolder -and $userFolder -ne 'Users') {
            $candidateFolder = Join-Path $profilePath $userFolder
            Write-LogEntry "Checking fallback folder: $candidateFolder"
            if (Test-Path -LiteralPath $candidateFolder) {
                Remove-Item -LiteralPath $candidateFolder -Recurse -Force -ErrorAction SilentlyContinue
                Write-LogEntry "Fallback folder removal complete. ExistsAfter=$(Test-Path -LiteralPath $candidateFolder)"
            }
            else {
                Write-LogEntry "Fallback folder not found: $candidateFolder"
            }
        }

        Update-Status "Deleted profile '$($selected.UserName)'."
        Write-LogEntry "Delete completed for SID=$sid"
        Refresh-Profiles
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-LogEntry "Delete failed for SID=${sid}: $errorMessage"
        Update-Status "Delete failed: $errorMessage"
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
