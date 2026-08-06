Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Import-Module ActiveDirectory -ErrorAction Stop

# ========================
# AD Connection / Credential Handling
# ========================

$ADServer = 'HCC-DC01.hopecc.sa.edu.au'
$CredentialPath = "$env:LOCALAPPDATA\StaffProvisioning\ADCred.xml"

if (Test-Path $CredentialPath) {
    $ADCred = Import-Clixml $CredentialPath
}
else {
    $ADCred = Get-Credential -Message 'Enter AD credentials (HOPECC\username)'

    $CredentialFolder = Split-Path $CredentialPath -Parent
    New-Item -ItemType Directory -Path $CredentialFolder -Force | Out-Null
    $ADCred | Export-Clixml $CredentialPath
}

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Add Staff Member"
    Width="920"
    Height="380"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    Background="#f8fafc">
    <Window.Resources>
        <Style TargetType="TextBox">
            <Setter Property="Height" Value="42" />
            <Setter Property="Padding" Value="10,8" />
            <Setter Property="FontSize" Value="14" />
            <Setter Property="BorderBrush" Value="#cbd5e1" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Height" Value="42" />
            <Setter Property="FontSize" Value="14" />
            <Setter Property="Padding" Value="10,8" />
        </Style>
        <Style TargetType="Button">
            <Setter Property="Height" Value="46" />
            <Setter Property="FontSize" Value="15" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="Background" Value="#2563eb" />
            <Setter Property="BorderBrush" Value="#2563eb" />
            <Setter Property="Padding" Value="16,8" />
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,16">
            <TextBlock Text="Add Staff Member" FontSize="28" FontWeight="Bold" Foreground="#0f172a" />
            <TextBlock Text="Create a new staff account with the required organisational details." FontSize="13" Foreground="#64748b" Margin="0,4,0,0" />
        </StackPanel>

        <Border Grid.Row="1" Background="White" CornerRadius="16" Padding="24" BorderBrush="#e2e8f0" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="1.2*" />
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Grid.Column="0" Margin="0,0,12,16">
                    <TextBlock Text="Staff Type" FontWeight="SemiBold" Foreground="#334155" Margin="0,0,0,6" />
                    <ComboBox Name="StaffTypeCombo" />
                </StackPanel>

                <StackPanel Grid.Row="0" Grid.Column="1" Margin="12,0,12,16">
                    <TextBlock Text="Employee Type" FontWeight="SemiBold" Foreground="#334155" Margin="0,0,0,6" />
                    <ComboBox Name="EmployeeTypeCombo" />
                </StackPanel>

                <StackPanel Grid.Row="0" Grid.Column="2" Margin="12,0,0,16">
                    <TextBlock Text="Full Name" FontWeight="SemiBold" Foreground="#334155" Margin="0,0,0,6" />
                    <TextBox Name="FullNameBox" />
                </StackPanel>

                <Border Grid.Row="1" Grid.ColumnSpan="3" Background="#f8fafc" BorderBrush="#e2e8f0" BorderThickness="1" CornerRadius="12" Padding="16" Margin="0,8,0,0">
                    <StackPanel>
                        <TextBlock Text="Username Preview" FontWeight="SemiBold" Foreground="#475569" Margin="0,0,0,8" />
                        <TextBlock Name="PreviewLabel" Text="" FontSize="18" FontWeight="Bold" Foreground="#0f172a" />
                        <TextBlock Name="StatusLabel" Text="Enter a full name to generate the username." FontSize="13" Foreground="#64748b" Margin="0,8,0,0" />
                    </StackPanel>
                </Border>
            </Grid>
        </Border>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
            <Button Name="CreateButton" Content="Create Account" Width="180" IsEnabled="False" />
        </StackPanel>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [System.Windows.Markup.XamlReader]::Load($reader)

$StaffTypeCombo = $Window.FindName('StaffTypeCombo')
$EmployeeTypeCombo = $Window.FindName('EmployeeTypeCombo')
$FullNameBox = $Window.FindName('FullNameBox')
$PreviewLabel = $Window.FindName('PreviewLabel')
$StatusLabel = $Window.FindName('StatusLabel')
$CreateButton = $Window.FindName('CreateButton')

@('Teaching','Non Teaching','TRT','Temporary','OSHC','Wellbeing','Pre Service') | ForEach-Object {
    [void]$StaffTypeCombo.Items.Add($_)
}

@('Full Time Staff','Part Time Staff','Casual Staff') | ForEach-Object {
    [void]$EmployeeTypeCombo.Items.Add($_)
}

function Update-FormState {
    $nameText = $FullNameBox.Text.Trim()
    $PreviewLabel.Text = ''
    $StatusLabel.Text = 'Enter a full name to generate the username.'
    $StatusLabel.Foreground = [System.Windows.Media.Brushes]::DimGray
    $CreateButton.IsEnabled = $false

    if ([string]::IsNullOrWhiteSpace($nameText)) {
        return
    }

    $names = $nameText -split '\s+'
    if ($names.Count -lt 2) {
        $PreviewLabel.Text = 'Enter first and last name'
        $PreviewLabel.Foreground = [System.Windows.Media.Brushes]::DarkOrange
        $StatusLabel.Text = 'Please provide both a first and last name.'
        $StatusLabel.Foreground = [System.Windows.Media.Brushes]::DarkOrange
        return
    }

    $firstName = $names[0]
    $lastName = $names[$names.Length - 1]
    $username = ($firstName + '.' + $lastName).ToLower()

    $PreviewLabel.Text = "$username@hopecc.sa.edu.au"
    $PreviewLabel.Foreground = [System.Windows.Media.Brushes]::MidnightBlue

    if (Get-ADUser -Filter "SamAccountName -eq '$username'" -Server $ADServer -Credential $ADCred -ErrorAction SilentlyContinue) {
        $StatusLabel.Text = 'That username already exists.'
        $StatusLabel.Foreground = [System.Windows.Media.Brushes]::IndianRed
        return
    }

    if ($StaffTypeCombo.SelectedItem -and $EmployeeTypeCombo.SelectedItem) {
        $CreateButton.IsEnabled = $true
        $StatusLabel.Text = 'Ready to create the account.'
        $StatusLabel.Foreground = [System.Windows.Media.Brushes]::ForestGreen
    }
    else {
        $StatusLabel.Text = 'Choose a staff type and employee type.'
        $StatusLabel.Foreground = [System.Windows.Media.Brushes]::DimGray
    }
}

$StaffTypeCombo.Add_SelectionChanged({
    if ($StaffTypeCombo.Text -eq 'TRT' -or $StaffTypeCombo.Text -eq 'Pre Service') {
        $EmployeeTypeCombo.SelectedItem = 'Casual Staff'
        $EmployeeTypeCombo.IsEnabled = $false
    }
    else {
        $EmployeeTypeCombo.IsEnabled = $true
    }

    Update-FormState
})

$EmployeeTypeCombo.Add_SelectionChanged({ Update-FormState })
$FullNameBox.Add_TextChanged({ Update-FormState })

$CreateButton.Add_Click({
    $FullName = $FullNameBox.Text.Trim()
    $StaffType = $StaffTypeCombo.Text
    $EmployeeType = $EmployeeTypeCombo.Text

    $names = $FullName -split '\s+'
    if ($names.Count -lt 2) {
        [System.Windows.MessageBox]::Show('Please enter a first and last name.', 'Error', 'OK', 'Error')
        return
    }

    $firstName = $names[0]
    $lastName = $names[$names.Length - 1]
    $Username = ($firstName + '.' + $lastName).ToLower()

    do {
        $rand = Get-Random -Minimum 10000 -Maximum 90000
        $employeeID = "HCC$rand"
    } until (-not (Get-ADUser -Filter "employeeID -eq '$employeeID'" -Server $ADServer -Credential $ADCred -ErrorAction SilentlyContinue))

    $baseOU = 'OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au'
    $ouExists = Get-ADOrganizationalUnit -Filter "Name -eq '$StaffType'" -SearchBase $baseOU -Server $ADServer -Credential $ADCred -ErrorAction SilentlyContinue
    if (-not $ouExists) {
        [System.Windows.MessageBox]::Show("OU '$StaffType' not found under Staff. Aborting.", 'Error')
        return
    }

    $staffGroup = "$StaffType Staff"
    $staffGroupExists = Get-ADGroup -Filter "Name -eq '$staffGroup'" -Server $ADServer -Credential $ADCred -ErrorAction SilentlyContinue
    if (-not $staffGroupExists) {
        [System.Windows.MessageBox]::Show("Group '$staffGroup' not found. Aborting.", 'Error')
        return
    }

    $gpStaffExists = Get-ADGroup -Filter "Name -eq 'gpStaff'" -Server $ADServer -Credential $ADCred -ErrorAction SilentlyContinue
    $plainPassword = -join ((33..126) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
    $securePass = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    try {
        New-ADUser `
            -Name $FullName `
            -UserPrincipalName "$Username@hopecc.sa.edu.au" `
            -SamAccountName $Username `
            -GivenName $firstName `
            -Surname $lastName `
            -DisplayName $FullName `
            -Description "$StaffType Staff" `
            -EmailAddress "$Username@hopecc.sa.edu.au" `
            -Company 'Hope Christian College' `
            -employeeID $employeeID `
            -Department 'Staff' `
            -Office $StaffType `
            -Path "OU=$StaffType,OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au" `
            -AccountPassword $securePass `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -Server $ADServer `
            -Credential $ADCred

        Add-ADGroupMember $staffGroup $Username -Server $ADServer -Credential $ADCred
        if ($gpStaffExists) { Add-ADGroupMember 'gpStaff' $Username -Server $ADServer -Credential $ADCred }

        if ($StaffType -eq 'TRT') {
            Set-ADUser $Username -Replace @{ Comment = '##Casual Teacher' } -Server $ADServer -Credential $ADCred
        }
        elseif ($StaffType -eq 'Pre Service') {
            Set-ADUser $Username -Replace @{ Comment = '##Pre Service Teachers' } -Server $ADServer -Credential $ADCred
        }
        elseif ($StaffType -eq 'Temporary') {
            Set-ADUser $Username -Replace @{ Comment = '##Casual Other' } -Server $ADServer -Credential $ADCred
        }
        else {
            Set-ADUser $Username -Replace @{ Comment = '##Current Main' } -Server $ADServer -Credential $ADCred
        }

        Set-ADUser $Username -Replace @{ employeeType = $EmployeeType } -Server $ADServer -Credential $ADCred

        try { Set-Clipboard $plainPassword -ErrorAction SilentlyContinue } catch {}
        [System.Windows.MessageBox]::Show('Account created successfully. Temporary password copied to clipboard.', 'Complete')
        $Window.Close()
    }
    catch {
        [System.Windows.MessageBox]::Show("Error creating account: $($_.Exception.Message)", 'Error')
    }
})

Update-FormState
[void]$Window.ShowDialog()
