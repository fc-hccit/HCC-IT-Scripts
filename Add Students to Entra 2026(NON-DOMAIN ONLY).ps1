Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module ActiveDirectory -ErrorAction Stop

# ========================
# AD Connection
# ========================

$ADServer = "HCC-DC01.hopecc.sa.edu.au"
$CredentialPath = "$env:LOCALAPPDATA\StudentProvisioning\ADCred.xml"

if (Test-Path $CredentialPath) {
    $ADCred = Import-Clixml $CredentialPath
}
else {
    $ADCred = Get-Credential -Message "Enter AD credentials (HOPECC\username)"

    $CredentialFolder = Split-Path $CredentialPath

    New-Item -ItemType Directory -Path $CredentialFolder -Force | Out-Null

    $ADCred | Export-Clixml $CredentialPath
}



# ========================
# Paths
# ========================
$CsvPath = "C:\Users\Public\Documents\students.csv"
$ErrorLogPath = "C:\Users\Public\Documents\students_error_log.txt"

# Recreate CSV with headers to prevent -Append errors
$CsvHeaders = [PSCustomObject]@{
    FullName  = ''
    Username  = ''
    Email     = ''
    Password  = ''
    YearLevel = ''
}
$CsvHeaders | Export-Csv $CsvPath -NoTypeInformation

# Clear previous error log
"" | Out-File $ErrorLogPath

# ========================
# Helper: Get OU by Year
# ========================
function Get-StudentOU {
    param([int]$Year)
    if ($Year -ge 10) { "OU=Year $Year,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" }
    elseif ($Year -ge 7) { "OU=Year $Year,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" }
    elseif ($Year -ge 3) { "OU=Year $Year,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" }
    else { "OU=Year $Year,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" }
}

# ========================
# Helper: Create or Update Student
# ========================
function New-OrUpdateStudent {
    param(
        [string]$FirstName,
        [string]$LastName,
        [int]$YearLevel
    )

    $FullName = "$FirstName $LastName"
    $BaseUser = "$FirstName.$LastName"
    $Username = $BaseUser.Substring(0, [Math]::Min(20, $BaseUser.Length))
    $Email = "$Username@student.hopecc.sa.edu.au"
    $OU = Get-StudentOU -Year $YearLevel

    Update-Status "Step 1: Looking up AD account for $Username"
    $existing = Get-ADUser `
    -Filter "SamAccountName -eq '$Username'" `
    -Server $ADServer `
    -Credential $ADCred `
    -Properties DistinguishedName, Enabled, UserAccountControl, GivenName, Surname, DisplayName, Department, Description, UserPrincipalName, EmployeeID, EmployeeType, pwdLastSet

    try {
        if ($null -ne $existing) {
            Update-Status "Step 2: Account exists in AD: $Username"

            # UPDATE existing
            $Password = "<unchanged>"
            $PasswordResetRequired = $false

            $ExistingEnabled = $false
            if ($existing.Enabled -is [bool]) {
                $ExistingEnabled = [bool]$existing.Enabled
            }
            elseif ($existing.Enabled -is [string]) {
                $ExistingEnabled = [bool]::Parse($existing.Enabled.Trim())
            }
            elseif ($null -ne $existing.Enabled) {
                $ExistingEnabled = [bool]([int]$existing.Enabled)
            }

            Update-Status "Step 3: Enabled state for $Username = $ExistingEnabled"

            if (-not $ExistingEnabled) {
                Update-Status "Step 4: Account is disabled, calling Enable-ADAccount for $Username"
            Enable-ADAccount `
                -Identity $Username `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop
                Update-Status "Step 4 complete: Enable-ADAccount finished for $Username"
            }
            else {
                Update-Status "Step 4: Account is already enabled; skipping Enable-ADAccount for $Username"
            }

            $RequiredUserPrincipalName = "$Username@student.hopecc.sa.edu.au"
            if ($existing.GivenName -ne $FirstName -or
                $existing.Surname -ne $LastName -or
                $existing.DisplayName -ne $FullName -or
                $existing.Department -ne "Year $YearLevel" -or
                $existing.Description -ne "2026 Year $YearLevel" -or
                $existing.UserPrincipalName -ne $RequiredUserPrincipalName) {

                Update-Status "Step 5: Updating AD attributes for $Username"
               Set-ADUser $existing `
                -GivenName $FirstName `
                -Surname $LastName `
                -DisplayName $FullName `
                -Department "Year $YearLevel" `
                -Description "2026 Year $YearLevel" `
                -UserPrincipalName $RequiredUserPrincipalName `
                -EmailAddress $RequiredUserPrincipalName `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop
                Update-Status "Step 5 complete: AD attributes updated for $Username"
            }

            if ($existing.DistinguishedName -notlike "*$OU*") {
                Update-Status "Step 6: Moving account to OU: $OU"
            Move-ADObject `
            $existing.DistinguishedName `
            -TargetPath $OU `
            -Server $ADServer `
            -Credential $ADCred `
            -ErrorAction Stop
                Update-Status "Step 6 complete: Account moved to OU for $Username"
            }
            else {
                Update-Status "Step 6: Account is already in the correct OU for $Username"
            }

            if ($existing.employeeType -ne "Student" -or [string]::IsNullOrWhiteSpace($existing.employeeID)) {
                $EmployeeID = "HCC$((Get-Random -Minimum 100000 -Maximum 999999))"
                Update-Status "Step 7: Setting employeeType and employeeID for $Username"
                Set-ADUser $Username `
                -Replace @{employeeType = "Student"; employeeID = $EmployeeID} `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop
                Update-Status "Step 7 complete: employeeType and employeeID set for $Username"
            }
            else {
                Update-Status "Step 7: employeeType and employeeID already present for $Username"
            }

            if (-not $existing.pwdLastSet -or $existing.pwdLastSet -eq 0) {
                $PasswordResetRequired = $true
                Update-Status "Step 8: Password reset required for $Username"
                $Password = -join ((65..90)+(97..122)+(48..57) | Get-Random -Count 12 | ForEach-Object {[char]$_})
               Set-ADAccountPassword `
                    -Identity $Username `
                    -NewPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
                    -Reset `
                    -Server $ADServer `
                    -Credential $ADCred `
                    -ErrorAction Stop

                Set-ADUser $Username `
                    -ChangePasswordAtLogon $true `
                    -Server $ADServer `
                    -Credential $ADCred `
                    -ErrorAction Stop
                Update-Status "Step 8 complete: Password reset and change-at-logon set for $Username"
            }
            else {
                Update-Status "Step 8: Password already set; no reset needed for $Username"
            }

            Update-Status "Step 9: Adding $Username to Students group"
            Add-ADGroupMember `
                "Students" `
                $Username `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop
            Update-Status "Step 10: Adding $Username to Year $YearLevel Students group"
            Add-ADGroupMember `
                "Year $YearLevel Students" `
                $Username `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop

            $Result = "Updated"
        }
        else {
            Update-Status "Step 2: Account does not exist in AD by SamAccountName: $Username"

          $NameCollision = Get-ADObject `
            -Filter "(objectClass -eq 'user') -and ((name -eq '$FullName') -or (cn -eq '$FullName'))" `
            -SearchBase $OU `
            -Server $ADServer `
            -Credential $ADCred `
            -ErrorAction SilentlyContinue
            if ($NameCollision) {
                Update-Status "Step 2a: AD name collision detected for $FullName in $OU"
                throw "AD object name already in use for $FullName in $OU"
            }
            else {
                Update-Status "Step 2a: No AD name collision detected for $FullName in $OU"
            }

            # CREATE new
            Update-Status "Step 3: Creating new AD account: $Username"
            $Password = -join ((65..90)+(97..122)+(48..57) | Get-Random -Count 12 | ForEach-Object {[char]$_})
            $EmployeeID = "HCC$((Get-Random -Minimum 100000 -Maximum 999999))"

            Update-Status "Step 4: Running New-ADUser for: $Username"
            New-ADUser `
                -Name $FullName `
                -GivenName $FirstName `
                -Surname $LastName `
                -SamAccountName $Username `
                -UserPrincipalName $Email `
                -DisplayName $FullName `
                -Path $OU `
                -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
                -Enabled $true `
                -Department "Year $YearLevel" `
                -Description "2026 Year $YearLevel" `
                -Company "Hope Christian College" `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop
            Update-Status "Step 4 complete: New-ADUser finished for $Username"
            Update-Status "Step 5: Setting employee attributes for new account: $Username"

            Set-ADUser $Username `
                -Replace @{employeeType="Student"; employeeID=$EmployeeID} `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop

            Update-Status "Step 6: Adding $Username to Students group"

            Add-ADGroupMember `
                "Students" `
                $Username `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop

            Update-Status "Step 7: Adding $Username to Year $YearLevel Students group"

            Add-ADGroupMember `
                "Year $YearLevel Students" `
                $Username `
                -Server $ADServer `
                -Credential $ADCred `
                -ErrorAction Stop

            $Result = "Created"
        }

        # Export to CSV
        [PSCustomObject]@{
            FullName  = $FullName
            Username  = $Username
            Email     = $Email
            Password  = $Password
            YearLevel = $YearLevel
        } | Export-Csv $CsvPath -Append -NoTypeInformation

        return [pscustomobject]@{
            Result    = $Result
            FullName  = $FullName
            Username  = $Username
            Email     = $Email
            Password  = $Password
            YearLevel = $YearLevel
        }
    }
    catch {
        $Reason = $_.Exception.Message
        if (-not $Reason) { $Reason = $_ | Out-String }
        "$FullName : $Reason" | Out-File $ErrorLogPath -Append
        throw
    }
}

# ========================
# WPF UI SETUP
# ========================
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml

$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                Title="Student Account Provisioning" Height="620" Width="780" WindowStartupLocation="CenterScreen">
    <Grid Background="#F6F8FA" Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Vertical" Grid.Row="0" Margin="6">
            <TextBlock Text="Student Account Provisioning" FontSize="18" FontWeight="Bold" Foreground="#222"/>
            <TextBlock Text="Manual or CSV-based Active Directory creation" FontSize="12" Foreground="#555"/>
        </StackPanel>

        <Border Grid.Row="1" Background="White" CornerRadius="6" Padding="10" Margin="0,10,0,10">
            <StackPanel Orientation="Vertical">
                <TextBlock Text="Manual Entries" FontWeight="SemiBold" Margin="0,0,0,6"/>

                <StackPanel Orientation="Vertical" Margin="0,2,0,0">
                    <StackPanel Orientation="Horizontal" Margin="0,4,0,4">
                        <TextBlock Text="Year" Width="50" VerticalAlignment="Center"/>
                        <ComboBox Name="Year0" Width="80" Margin="0,0,8,0"/>
                        <TextBlock Text="Name" Width="50" Margin="12,0,0,0" VerticalAlignment="Center"/>
                        <TextBox Name="Name0" Width="520" />
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,4,0,4">
                        <TextBlock Text="Year" Width="50" VerticalAlignment="Center"/>
                        <ComboBox Name="Year1" Width="80" Margin="0,0,8,0"/>
                        <TextBlock Text="Name" Width="50" Margin="12,0,0,0" VerticalAlignment="Center"/>
                        <TextBox Name="Name1" Width="520" />
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,4,0,4">
                        <TextBlock Text="Year" Width="50" VerticalAlignment="Center"/>
                        <ComboBox Name="Year2" Width="80" Margin="0,0,8,0"/>
                        <TextBlock Text="Name" Width="50" Margin="12,0,0,0" VerticalAlignment="Center"/>
                        <TextBox Name="Name2" Width="520" />
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,4,0,4">
                        <TextBlock Text="Year" Width="50" VerticalAlignment="Center"/>
                        <ComboBox Name="Year3" Width="80" Margin="0,0,8,0"/>
                        <TextBlock Text="Name" Width="50" Margin="12,0,0,0" VerticalAlignment="Center"/>
                        <TextBox Name="Name3" Width="520" />
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,4,0,4">
                        <TextBlock Text="Year" Width="50" VerticalAlignment="Center"/>
                        <ComboBox Name="Year4" Width="80" Margin="0,0,8,0"/>
                        <TextBlock Text="Name" Width="50" Margin="12,0,0,0" VerticalAlignment="Center"/>
                        <TextBox Name="Name4" Width="520" />
                    </StackPanel>
                </StackPanel>
            </StackPanel>
        </Border>

        <Grid Grid.Row="2" Margin="0,0,0,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal" Grid.Column="1" HorizontalAlignment="Right" VerticalAlignment="Center">
                <Button Name="CreateButton" Content="Create / Update Students" Width="160" Margin="6" />
                <Button Name="CsvButton" Content="Import CSV" Width="100" Margin="6" />
                <Button Name="CopyButton" Content="Copy All Details" Width="130" Margin="6" />
                <Button Name="OpenCsvButton" Content="Open CSV" Width="90" Margin="6" />
            </StackPanel>
        </Grid>

        <Border Grid.Row="3" Background="White" CornerRadius="6" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="*" />
                </Grid.RowDefinitions>
                <TextBlock Text="Result Log" FontWeight="SemiBold" Margin="0,0,0,6"/>
                <TextBox Name="StatusText" Grid.Row="1" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" IsReadOnly="True" Margin="0" />
            </Grid>
        </Border>

        <StackPanel Orientation="Vertical" Grid.Row="4" Margin="0,8,0,0" HorizontalAlignment="Stretch">
            <ProgressBar Name="ProgressBar" Height="18" Width="730" Minimum="0" Maximum="100" Margin="6" />
        </StackPanel>
    </Grid>
</Window>
"@

$xml = [xml]$Xaml
$reader = (New-Object System.Xml.XmlNodeReader $xml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Helper to find named controls
function FindCtrl([string]$name) { $Window.FindName($name) }

# Populate year comboboxes
for ($i=0; $i -lt 5; $i++) {
        $cb = FindCtrl("Year$i")
        $cb.Items.Add('-')
        0..12 | ForEach-Object { [void]$cb.Items.Add($_) }
        $cb.SelectedIndex = 0

        $nameBox = FindCtrl("Name$i")
        $nameBox.IsEnabled = $false
        $nameBox.Background = [System.Windows.Media.Brushes]::LightGray

        $cb.Add_SelectionChanged({
                param($sender, $e)
                $rowIndex = $sender.Name.Replace('Year', '')
                $nameBox = FindCtrl("Name$rowIndex")
                $selectedYear = $sender.SelectedItem
                $isValidYear = ($selectedYear -is [int]) -and ($selectedYear -ge 0) -and ($selectedYear -le 12)
                $nameBox.IsEnabled = $isValidYear
                $nameBox.Background = if ($isValidYear) { [System.Windows.Media.Brushes]::White } else { [System.Windows.Media.Brushes]::LightGray }
        })
}

$ProgressBar = FindCtrl('ProgressBar')
$StatusText = FindCtrl('StatusText')

# Create/Open/Import buttons
$CreateButton = FindCtrl('CreateButton')
$CsvButton = FindCtrl('CsvButton')
$CopyButton = FindCtrl('CopyButton')
$OpenCsvButton = FindCtrl('OpenCsvButton')
$LastProcessedAccount = $null
$StatusLog = New-Object System.Collections.Generic.List[string]

function Clear-StatusLog {
        $StatusLog.Clear()
        $Window.Dispatcher.Invoke([Action]{
                $StatusText.Text = ''
                $ProgressBar.Value = 0
        })
}

function Update-Status([string]$text, [int]$progress = $null) {
        $displayText = $text
        if ($displayText -like 'Step *' -and $displayText -notlike 'Failed*') {
                $displayText = "$displayText ✓"
        }

        $Window.Dispatcher.Invoke([Action]{
                if ($progress -ne $null) { $ProgressBar.Value = $progress }
                $StatusLog.Add($displayText)
                $StatusText.Text = ($StatusLog -join [Environment]::NewLine)
                $StatusText.CaretIndex = $StatusText.Text.Length
                $StatusText.ScrollToEnd()
                $StatusText.UpdateLayout()
        })
}

$CreateButton.Add_Click({
        Clear-StatusLog
        Update-Status "Ready"
        $entries = @()
        for ($i=0; $i -lt 5; $i++) {
                $name = (FindCtrl("Name$i")).Text
                $year = (FindCtrl("Year$i")).SelectedItem
                if ($name -and $year -ne $null -and $year -is [int] -and $year -ge 0 -and $year -le 12) {
                        $entries += [pscustomobject]@{Name=$name; Year=$year}
                }
        }

        if (-not $entries) { Update-Status "No valid entries"; return }

        $total = $entries.Count; $i = 0; $created=0; $updated=0; $failed=0
        foreach ($e in $entries) {
                $i++
                Update-Status "Processing $($e.Name)..." ([int](($i/$total)*100))
                try {
                        $Parts = $e.Name -split '\s+'
                        $Result = New-OrUpdateStudent -FirstName $Parts[0] -LastName ($Parts[1..($Parts.Count-1)] -join ' ') -YearLevel ([int]$e.Year)
                        $LastProcessedAccount = $Result
                        if ($Result.Result -eq 'Created') { $created++ } else { $updated++ }
                }
                catch {
                        $failed++
                        $Reason = $_.Exception.Message
                        if (-not $Reason) { $Reason = $_ | Out-String }
                        Update-Status "Failed for $($e.Name): $Reason"
                }
        }

        if ($failed -gt 0) {
                Update-Status "⚠️ Done: $created created, $updated updated, $failed failed`nSee $ErrorLogPath for details." 100
                $Window.Dispatcher.Invoke([Action] {
                        [System.Windows.MessageBox]::Show("Processing complete. $created created, $updated updated, $failed failed.`nSee $ErrorLogPath for details.", 'Summary')
                })
        }
        else {
                Update-Status "✅ Done: $created created, $updated updated, $failed failed" 100
                $Window.Dispatcher.Invoke([Action] {
                        [System.Windows.MessageBox]::Show("Processing complete. $created created, $updated updated, $failed failed.", 'Summary')
                })
        }
})

$CsvButton.Add_Click({
        Clear-StatusLog
        Update-Status "Select a CSV file to import"
        $dlg = New-Object Microsoft.Win32.OpenFileDialog
        $dlg.Filter = "CSV Files (*.csv)|*.csv"
        $ok = $dlg.ShowDialog()
        if (-not $ok) { return }
        $Rows = Import-Csv $dlg.FileName
        Update-Status "Loaded $($Rows.Count) row(s) from CSV"

        # Header check
        $RequiredHeaders = @('firstname','lastname','year')
        $Missing = $RequiredHeaders | Where-Object { -not ($Rows[0].PSObject.Properties.Name -contains $_) }
        if ($Missing) { [System.Windows.MessageBox]::Show("CSV missing required headers: $($Missing -join ', ')"); return }

        $total = $Rows.Count; $i=0; $created=0; $updated=0; $failed=0
        foreach ($r in $Rows) {
                $i++
                Update-Status "Processing $($r.firstname) $($r.lastname)..." ([int](($i/$total)*100))
                try {
                        $Result = New-OrUpdateStudent -FirstName $r.firstname -LastName $r.lastname -YearLevel ([int]$r.year)
                        $LastProcessedAccount = $Result
                        if ($Result.Result -eq 'Created') { $created++ } else { $updated++ }
                }
                catch {
                        $failed++
                        $Reason = $_.Exception.Message
                        if (-not $Reason) { $Reason = $_ | Out-String }
                        Update-Status "Failed for $($r.firstname) $($r.lastname): $Reason"
                }
        }

        if ($failed -gt 0) {
                Update-Status "⚠️ Done: $created created, $updated updated, $failed failed`nSee $ErrorLogPath for details." 100
                $Window.Dispatcher.Invoke([Action] {
                        [System.Windows.MessageBox]::Show("Processing complete. $created created, $updated updated, $failed failed.`nSee $ErrorLogPath for details.", 'Summary')
                })
        }
        else {
                Update-Status "✅ Done: $created created, $updated updated, $failed failed" 100
                $Window.Dispatcher.Invoke([Action] {
                        [System.Windows.MessageBox]::Show("Processing complete. $created created, $updated updated, $failed failed.", 'Summary')
                })
        }
})

$CopyButton.Add_Click({
        if (-not (Test-Path $CsvPath)) {
                [System.Windows.MessageBox]::Show("No CSV output exists yet at: $CsvPath")
                return
        }

        $Accounts = Import-Csv $CsvPath
        if (-not $Accounts) {
                [System.Windows.MessageBox]::Show('No user details found in the CSV output.')
                return
        }

        $copyText = @()
        foreach ($Account in $Accounts) {
                if (-not $Account.Username -and -not $Account.Email -and -not $Account.Password) { continue }
                $copyText += "Username: $($Account.Username)`r`nEmail: $($Account.Email)`r`nPassword: $($Account.Password)`r`n"
        }

        [System.Windows.Clipboard]::SetText(($copyText -join "`r`n"))
        Update-Status "All user details copied to clipboard"
})

$OpenCsvButton.Add_Click({ if (Test-Path $CsvPath) { Start-Process $CsvPath } else { [System.Windows.MessageBox]::Show("CSV not found: $CsvPath") } })

$Window.Add_Closed({
        $StatusLog.Clear()
        $StatusText.Text = ''
})

[void]$Window.ShowDialog()
