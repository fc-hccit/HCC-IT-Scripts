Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '800,70'
$Form.text                       = "Add Staff Member "
$Form.TopMost                    = $false
$Form.StartPosition              = 'CenterScreen'

$Form1                           = New-Object system.Windows.Forms.Form
$Form1.ClientSize                = '278,367'
$Form1.text                      = "Select Email Groups"
$Form1.TopMost                   = $false
$Form1.StartPosition             = 'CenterScreen'

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Create Account"
$Button1.width                   = 110
$Button1.height                  = 50
$Button1.location                = New-Object System.Drawing.Point(680,15)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Enabled                 = $false
$Button1.DialogResult            = [System.Windows.Forms.DialogResult]::OK

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.DropDownStyle         = 'DropDownList'
$ComboBox1.width                 = 120
$ComboBox1.height                = 20
@('Teaching','Non Teaching','TRT','Temporary','OSHC','Wellbeing') | ForEach-Object {[void] $ComboBox1.Items.Add($_)}
$ComboBox1.location              = New-Object System.Drawing.Point(10,30)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({
    if ($TextBox1.Text -and $ComboBox1.SelectedIndex -ne -1) {
        $Button1.Enabled = $true
    }
})

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.DropDownStyle         = 'DropDownList'
$ComboBox2.width                 = 120
$ComboBox2.height                = 20
@('Full Time Staff','Part Time Staff','Casual Staff') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}
$ComboBox2.location              = New-Object System.Drawing.Point(140,30)
$ComboBox2.Font                  = 'Microsoft Sans Serif,10'
$ComboBox2.add_SelectedIndexChanged({
    if ($TextBox1.Text -and $ComboBox1.SelectedIndex -ne -1 -and $ComboBox2.SelectedIndex -ne -1) {
        $Button1.Enabled = $true
    }
})


$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Staff Type"
$Label1.AutoSize                 = $true
$Label1.location                 = New-Object System.Drawing.Point(10,10)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "Employee Type"
$Label3.AutoSize                 = $true
$Label3.location                 = New-Object System.Drawing.Point(140,9)
$Label3.Font                     = 'Microsoft Sans Serif,10'

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 220
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(270,30)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'
$TextBox1.Add_TextChanged({
    if ($TextBox1.Text -and $ComboBox1.SelectedIndex -ne -1 -and $ComboBox2.SelectedIndex -ne -1) {
        $Button1.Enabled = $true
    }
})

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Full Name"
$Label2.AutoSize                 = $true
$Label2.location                 = New-Object System.Drawing.Point(270,10)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "Create Email"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 150
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(500,10)
$CheckBox1.Font                  = 'Microsoft Sans Serif,10'
$CheckBox1.Add_CheckStateChanged({$Button4.Enabled = $CheckBox1.Checked})

$Button4                         = New-Object system.Windows.Forms.Button
$Button4.text                    = "Select Groups"
$Button4.width                   = 150
$Button4.height                  = 25
$Button4.location                = New-Object System.Drawing.Point(500,30)
$Button4.Font                    = 'Microsoft Sans Serif,10'
$Button4.Enabled                 = $false
$Button4.Add_Click({[void]$Form1.ShowDialog()})


$ListBox1                        = New-Object system.Windows.Forms.ListBox
$ListBox1.text                   = "listBox"
$ListBox1.width                  = 258
$ListBox1.height                 = 313

$getrand = Get-Random -Minimum 10000 -Maximum 90000

$Gpwd = "hope1234"

$emailAddresses = @(
    "adminstaff@hopecc.sa.edu.au",
    "staff@hopecc.sa.edu.au",
    "assistantstoheads@hopecc.sa.edu.au",
    "avtechsupport@hopecc.sa.edu.au",
    "blessingbuddies@hopecc.sa.edu.au",
    "busdrivingstaff@hopecc.sa.edu.au",
    "canteenstaff@hopecc.sa.edu.au",
    "chapel@hopecc.sa.edu.au",
    "christianencouragment@hopecc.sa.edu.au",
    "classroom_teachers@hopecc.sa.edu.au",
    "community.fund@hopecc.sa.edu.au",
    "departmentassistants@hopecc.sa.edu.au",
    "financestaff@hopecc.sa.edu.au",
    "heads_coordinators_lal@hopecc.sa.edu.au",
    "humanresourcesstaff@hopecc.sa.edu.au",
    "itstaff@hopecc.sa.edu.au",
    "juniorprimaryteachingstaff@hopecc.sa.edu.au",
    "leadershipstaff@hopecc.sa.edu.au",
    "learningsupportstaff@hopecc.sa.edu.au",
    "librarystaff@hopecc.sa.edu.au",
    "maintenancestaff@hopecc.sa.edu.au",
    "middleschoolteachingstaff@hopecc.sa.edu.au",
    "musicstaff@hopecc.sa.edu.au",
    "nonteachingleadershipstaff@hopecc.sa.edu.au",
    "nonteachingstaff@hopecc.sa.edu.au",
    "oshcstaff@hopecc.sa.edu.au",
    "primarylearningsupportstaff@hopecc.sa.edu.au",
    "primaryteachingstaff@hopecc.sa.edu.au",
    "secondarylearningsupportstaff@hopecc.sa.edu.au",
    "seniorschoolteachingstaff@hopecc.sa.edu.au",
    "teachingleadershipstaff@hopecc.sa.edu.au",
    "teachingstaff@hopecc.sa.edu.au",
    "timetablingstaff@hopecc.sa.edu.au",
    "trtstaff@hopecc.sa.edu.au",
    "wellbeingteam@hopecc.sa.edu.au",
    "wildhiveteam@hopecc.sa.edu.au"
)
$emailAddresses | ForEach-Object {[void] $ListBox1.Items.Add($_)}
$ListBox1.location               = New-Object System.Drawing.Point(10,10)
$ListBox1.SelectionMode          = 'MultiExtended'

$Button3                         = New-Object system.Windows.Forms.Button
$Button3.text                    = "Select"
$Button3.width                   = 60
$Button3.height                  = 30
$Button3.location                = New-Object System.Drawing.Point(100,329)
$Button3.Font                    = 'Microsoft Sans Serif,10'
$Button3.Add_Click({[void]$Form1.Close()})
 
$Form.controls.AddRange(@($Button1,$Button4,$ComboBox1,$Label1,$TextBox1,$Label2,$Label3,$ComboBox2,$CheckBox1))
$Form1.controls.AddRange(@($ListBox1,$Button3))

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $FullName = $TextBox1.Text.Trim()
    $emailgroups = $ListBox1.SelectedItems
    $StaffType = $ComboBox1.Text.Trim()
    $EmployeeType = $ComboBox2.Text.Trim()

    $names = $FullName -split ' '
    $Firstname = $names[0]
    $Lastname = $names[1]

    New-ADUser -Name "$FullName" -UserPrincipalName "$Firstname.$Lastname@hopecc.sa.edu.au" -SamAccountName "$Firstname.$Lastname" -GivenName $Firstname -DisplayName "$FullName" -SurName "$Lastname" -Description "$StaffType Staff" -EmailAddress "$Firstname.$Lastname@hopecc.sa.edu.au" -Company "Hope Christian College" -employeeID "HCC$getrand" -Department "Staff" -Office "$StaffType" -HomeDrive "H:" -HomeDirectory "\\hopecc.sa.edu.au\staff\StaffHome\$Firstname.$Lastname" -Path "OU=$StaffType,OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "hope1234" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $False -PassThru
    Add-ADGroupMember -Identity "$StaffType Staff" -Members "$Firstname.$Lastname" -PassThru 
    Add-ADGroupMember -Identity "gpStaff" -Members "$Firstname.$Lastname" -PassThru
    Set-ADUser -Identity "$Firstname.$Lastname" -Replace @{Comment="##Current Main"}
    Set-ADUser -Identity "$Firstname.$Lastname" -Replace @{employeeType=$EmployeeType}

    if ($CheckBox1.Checked) {
        gam create user "$Firstname.$Lastname@hopecc.sa.edu.au" firstname "$Firstname" lastname "$Lastname" password $Gpwd changepassword "off" org "Staff/$StaffType Staff" organization department "Staff" primary
        $emailgroups | Foreach-object { gam update group "$_" add "member" user "$Firstname.$Lastname@hopecc.sa.edu.au" }
    }
}
