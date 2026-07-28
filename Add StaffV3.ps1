Add-Type -AssemblyName System.Windows.Forms
Import-Module ActiveDirectory
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '900,160'
$Form.Text = "Add Staff Member"
$Form.StartPosition = 'CenterScreen'

$Font = 'Microsoft Sans Serif,12'

$Button1 = New-Object system.Windows.Forms.Button
$Button1.Text = "Create Account"
$Button1.Width = 180
$Button1.Height = 60
$Button1.Location = New-Object System.Drawing.Point(700,70)
$Button1.Enabled = $false
$Button1.Font = $Font
$Button1.DialogResult = [System.Windows.Forms.DialogResult]::OK

$ComboBox1 = New-Object system.Windows.Forms.ComboBox
$ComboBox1.DropDownStyle = 'DropDownList'
$ComboBox1.Width = 180
$ComboBox1.Font = $Font
$ComboBox1.Location = New-Object System.Drawing.Point(20,60)

@('Teaching','Non Teaching','TRT','Temporary','OSHC','Wellbeing','Pre Service') | ForEach-Object {
    [void]$ComboBox1.Items.Add($_)
}

$ComboBox2 = New-Object system.Windows.Forms.ComboBox
$ComboBox2.DropDownStyle = 'DropDownList'
$ComboBox2.Width = 200
$ComboBox2.Font = $Font
$ComboBox2.Location = New-Object System.Drawing.Point(220,60)

@('Full Time Staff','Part Time Staff','Casual Staff') | ForEach-Object {
    [void]$ComboBox2.Items.Add($_)
}

$TextBox1 = New-Object system.Windows.Forms.TextBox
$TextBox1.Width = 260
$TextBox1.Font = $Font
$TextBox1.Location = New-Object System.Drawing.Point(440,60)

$UsernamePreview = New-Object system.Windows.Forms.Label
$UsernamePreview.AutoSize = $true
$UsernamePreview.Font = $Font
$UsernamePreview.Location = New-Object System.Drawing.Point(440,110)

$Label1 = New-Object system.Windows.Forms.Label
$Label1.Text = "Staff Type"
$Label1.AutoSize = $true
$Label1.Font = $Font
$Label1.Location = New-Object System.Drawing.Point(20,25)

$Label2 = New-Object system.Windows.Forms.Label
$Label2.Text = "Employee Type"
$Label2.AutoSize = $true
$Label2.Font = $Font
$Label2.Location = New-Object System.Drawing.Point(220,25)

$Label3 = New-Object system.Windows.Forms.Label
$Label3.Text = "Full Name"
$Label3.AutoSize = $true
$Label3.Font = $Font
$Label3.Location = New-Object System.Drawing.Point(440,25)

function Test-FormComplete {
    $nameText = $TextBox1.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($nameText)) {
        $UsernamePreview.Text = ""
        $Button1.Enabled = $false
        return
    }

    $names = $nameText -split '\s+'

    if ($names.Count -lt 2) {
        $UsernamePreview.Text = "Enter first and last name"
        $UsernamePreview.ForeColor = 'DarkOrange'
        $Button1.Enabled = $false
        return
    }

    $Firstname = $names[0]
    $Lastname = $names[$names.Length - 1]

    $Username = ($Firstname + "." + $Lastname).ToLower()

    $UsernamePreview.Text = "$Username@hopecc.sa.edu.au"

    if (Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction SilentlyContinue) {
        $UsernamePreview.ForeColor = "Red"
        $Button1.Enabled = $false
    }
    else {
        $UsernamePreview.ForeColor = "Green"
        if ($ComboBox1.SelectedIndex -ne -1 -and $ComboBox2.SelectedIndex -ne -1) {
            $Button1.Enabled = $true
        }
    }
}

$ComboBox1.Add_SelectedIndexChanged({
    if ($ComboBox1.Text -eq "TRT" -or $ComboBox1.Text -eq "Pre Service") {
        $ComboBox2.SelectedItem = "Casual Staff"
        $ComboBox2.Enabled = $false
    }
    else {
        $ComboBox2.Enabled = $true
    }

    Test-FormComplete
})

$ComboBox2.Add_SelectedIndexChanged({Test-FormComplete})
$TextBox1.Add_TextChanged({Test-FormComplete})

$Form.Controls.AddRange(@(
$Button1,
$ComboBox1,
$ComboBox2,
$TextBox1,
$Label1,
$Label2,
$Label3,
$UsernamePreview
))

$result = $Form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {

    $FullName = $TextBox1.Text.Trim()
    $StaffType = $ComboBox1.Text
    $EmployeeType = $ComboBox2.Text

    $names = $FullName -split '\s+'
    if ($names.Count -lt 2) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a first and last name","Error","OK",'Error')
        return
    }

    $Firstname = $names[0]
    $Lastname = $names[$names.Length - 1]

    $Username = ($Firstname + "." + $Lastname).ToLower()

    do {
        $rand = Get-Random -Minimum 10000 -Maximum 90000
        $employeeID = "HCC$rand"
    } until (-not (Get-ADUser -Filter "employeeID -eq '$employeeID'" -ErrorAction SilentlyContinue))

    $baseOU = "OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au"
    $ouExists = Get-ADOrganizationalUnit -Filter "Name -eq '$StaffType'" -SearchBase $baseOU -ErrorAction SilentlyContinue
    if (-not $ouExists) {
        [System.Windows.Forms.MessageBox]::Show("OU '$StaffType' not found under Staff. Aborting.","Error")
        return
    }

    $staffGroup = "$StaffType Staff"
    $staffGroupExists = Get-ADGroup -Filter "Name -eq '$staffGroup'" -ErrorAction SilentlyContinue
    if (-not $staffGroupExists) {
        [System.Windows.Forms.MessageBox]::Show("Group '$staffGroup' not found. Aborting.","Error")
        return
    }

    $gpStaffExists = Get-ADGroup -Filter "Name -eq 'gpStaff'" -ErrorAction SilentlyContinue

    $plainPassword = -join ((33..126) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    $securePass = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    try {
        New-ADUser `
            -Name $FullName `
            -UserPrincipalName "$Username@hopecc.sa.edu.au" `
            -SamAccountName $Username `
            -GivenName $Firstname `
            -Surname $Lastname `
            -DisplayName $FullName `
            -Description "$StaffType Staff" `
            -EmailAddress "$Username@hopecc.sa.edu.au" `
            -Company "Hope Christian College" `
            -employeeID $employeeID `
            -Department "Staff" `
            -Office $StaffType `
            -Path "OU=$StaffType,OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au" `
            -AccountPassword $securePass `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Add-ADGroupMember $staffGroup $Username
        if ($gpStaffExists) { Add-ADGroupMember "gpStaff" $Username }

        if ($StaffType -eq "TRT") {
            Set-ADUser $Username -Replace @{Comment="##Casual Teacher"}
        }
        elseif ($StaffType -eq "Pre Service") {
            Set-ADUser $Username -Replace @{Comment="##Pre Service Teachers"}
        }
        elseif ($StaffType -eq "Temporary") {
            Set-ADUser $Username -Replace @{Comment="##Casual Other"}
        }
        else {
            Set-ADUser $Username -Replace @{Comment="##Current Main"}
        }

        Set-ADUser $Username -Replace @{employeeType=$EmployeeType}

        try { Set-Clipboard $plainPassword -ErrorAction SilentlyContinue } catch {}

        [System.Windows.Forms.MessageBox]::Show("Account created successfully. Temporary password copied to clipboard.","Complete")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error creating account: $($_.Exception.Message)","Error")
    }

}