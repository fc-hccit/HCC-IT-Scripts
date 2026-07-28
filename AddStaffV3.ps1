Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Main Form
$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '650,120'
$Form.text = "Add Staff Member"
$Form.StartPosition = 'CenterScreen'

# Email Groups Selection Form
$Form1 = New-Object system.Windows.Forms.Form
$Form1.ClientSize = '278,367'
$Form1.text = "Select Email Groups"
$Form1.StartPosition = 'CenterScreen'

# Full Name Label & TextBox
$Label1 = New-Object system.Windows.Forms.Label
$Label1.text = "Full Name"
$Label1.AutoSize = $true
$Label1.location = New-Object System.Drawing.Point(10,10)
$Label1.Font = 'Microsoft Sans Serif,10'
$Form.Controls.Add($Label1)

$TextBox1 = New-Object system.Windows.Forms.TextBox
$TextBox1.width = 200
$TextBox1.height = 20
$TextBox1.location = New-Object System.Drawing.Point(10,30)
$TextBox1.Font = 'Microsoft Sans Serif,10'
$Form.Controls.Add($TextBox1)

# Staff Type Dropdown
$Label2 = New-Object system.Windows.Forms.Label
$Label2.text = "Staff Type"
$Label2.AutoSize = $true
$Label2.location = New-Object System.Drawing.Point(230,10)
$Label2.Font = 'Microsoft Sans Serif,10'
$Form.Controls.Add($Label2)

$ComboBox1 = New-Object system.Windows.Forms.ComboBox
$ComboBox1.DropDownStyle = 'DropDownList'
$ComboBox1.width = 150
$ComboBox1.height = 20
$ComboBox1.Items.Add("Teaching") | Out-Null
$ComboBox1.Items.Add("Non Teaching") | Out-Null
$ComboBox1.Items.Add("TRT") | Out-Null
$ComboBox1.Items.Add("Temporary") | Out-Null
$ComboBox1.Items.Add("OSHC") | Out-Null
$ComboBox1.Items.Add("Wellbeing") | Out-Null
$ComboBox1.location = New-Object System.Drawing.Point(230,30)
$ComboBox1.Font = 'Microsoft Sans Serif,10'
$Form.Controls.Add($ComboBox1)

# Employee Type Dropdown
$Label3 = New-Object system.Windows.Forms.Label
$Label3.text = "Employee Type"
$Label3.AutoSize = $true
$Label3.location = New-Object System.Drawing.Point(400,10)
$Label3.Font = 'Microsoft Sans Serif,10'
$Form.Controls.Add($Label3)

$ComboBox2 = New-Object system.Windows.Forms.ComboBox
$ComboBox2.DropDownStyle = 'DropDownList'
$ComboBox2.width = 150
$ComboBox2.height = 20
$ComboBox2.Items.Add("FullTime Staff") | Out-Null
$ComboBox2.Items.Add("PartTime Staff") | Out-Null
$ComboBox2.Items.Add("TRT Staff") | Out-Null
$ComboBox2.location = New-Object System.Drawing.Point(400,30)
$ComboBox2.Font = 'Microsoft Sans Serif,10'
$Form.Controls.Add($ComboBox2)

# Create Email Checkbox
$CheckBox1 = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text = "Create Email"
$CheckBox1.AutoSize = $true
$CheckBox1.location = New-Object System.Drawing.Point(10,60)
$CheckBox1.Font = 'Microsoft Sans Serif,10'
$CheckBox1.Add_CheckStateChanged({$Button4.Enabled = $CheckBox1.Checked})
$Form.Controls.Add($CheckBox1)

# Select Groups Button
$Button4 = New-Object system.Windows.Forms.Button
$Button4.text = "Select Groups"
$Button4.width = 150
$Button4.height = 25
$Button4.location = New-Object System.Drawing.Point(120,60)
$Button4.Font = 'Microsoft Sans Serif,10'
$Button4.Enabled = $false
$Button4.Add_Click({[void]$Form1.ShowDialog()})
$Form.Controls.Add($Button4)

# Create Account Button
$Button1 = New-Object system.Windows.Forms.Button
$Button1.text = "Create Account"
$Button1.width = 150
$Button1.height = 40
$Button1.location = New-Object System.Drawing.Point(400,60)
$Button1.Font = 'Microsoft Sans Serif,10'
$Button1.Enabled = $false
$Button1.Add_Click({
    if (-not $TextBox1.Text -or $ComboBox1.SelectedIndex -eq -1 -or $ComboBox2.SelectedIndex -eq -1) {
        [System.Windows.Forms.MessageBox]::Show("Please fill all fields!", "Error", "OK", "Error")
        return
    }
    $Form.DialogResult = [System.Windows.Forms.DialogResult]::OK
})
$Form.Controls.Add($Button1)

# Email Groups List Box (Form1)
$ListBox1 = New-Object system.Windows.Forms.ListBox
$ListBox1.width = 258
$ListBox1.height = 313
$ListBox1.location = New-Object System.Drawing.Point(10,10)
$ListBox1.SelectionMode = 'MultiExtended'

$emailGroups = @(
    "adminstaff@hopecc.sa.edu.au", "staff@hopecc.sa.edu.au", "assistantstoheads@hopecc.sa.edu.au",
    "itstaff@hopecc.sa.edu.au", "teachingleadershipstaff@hopecc.sa.edu.au", "wildhiveteam@hopecc.sa.edu.au"
)
$emailGroups | ForEach-Object {[void] $ListBox1.Items.Add($_)}
$Form1.Controls.Add($ListBox1)

# Email Groups Selection Button
$Button3 = New-Object system.Windows.Forms.Button
$Button3.text = "Select"
$Button3.width = 60
$Button3.height = 30
$Button3.location = New-Object System.Drawing.Point(100,329)
$Button3.Font = 'Microsoft Sans Serif,10'
$Button3.Add_Click({[void]$Form1.Close()})
$Form1.Controls.Add($Button3)

# Show Form and Process Data
$result = $Form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $FullName = $TextBox1.Text.Trim()
    $StaffType = $ComboBox1.Text.Trim()
    $EmployeeType = $ComboBox2.Text.Trim()
    $emailGroupsSelected = $ListBox1.SelectedItems

    $names = $FullName -split ' '
    $Firstname = $names[0]
    $Lastname = $names[1]
    $SamAccountName = "$Firstname.$Lastname"
    $UserPrincipalName = "$SamAccountName@hopecc.sa.edu.au"

    New-ADUser -Name "$FullName" -UserPrincipalName $UserPrincipalName -SamAccountName $SamAccountName `
        -GivenName $Firstname -DisplayName "$FullName" -SurName $Lastname -Description "$EmployeeType - $StaffType" `
        -Department "Staff" -Path "OU=$StaffType,OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au" `
        -AccountPassword (ConvertTo-SecureString "hope1234" -AsPlainText -Force) -Enabled $True -ChangePasswordAtLogon $True -PassThru

    Add-ADGroupMember -Identity "$StaffType Staff" -Members $SamAccountName
    Add-ADGroupMember -Identity "gpStaff" -Members $SamAccountName

    if ($CheckBox1.Checked) {
        $Gpwd = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 10 | ForEach-Object {[char]$_})
        gam create user $UserPrincipalName firstname "$Firstname" lastname "$Lastname" password $Gpwd changepassword "off" org "Staff/$StaffType"
        $emailGroupsSelected | ForEach-Object { gam update group "$_" add "member" user $UserPrincipalName }
    }
}
