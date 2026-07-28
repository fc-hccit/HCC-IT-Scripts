Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '650,107'
$Form.text                       = "Add Staff Member "
$Form.TopMost                    = $false
$Form.StartPosition              = 'CenterScreen'
$Form.AcceptButton = $Button1

$Form1                           = New-Object system.Windows.Forms.Form
$Form1.ClientSize                = '278,367'
$Form1.text                      = "Select Email Groups"
$Form1.TopMost                   = $false
$Form1.StartPosition             = 'CenterScreen'
$Form1.AcceptButton              = $Button3

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Create Account"
$Button1.width                   = 110
$Button1.height                  = 35
$Button1.location                = New-Object System.Drawing.Point(522,62)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Enabled                 = $false
$Button1.DialogResult = [System.Windows.Forms.DialogResult]::OK

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.DropDownStyle         = 'DropDownList'
$ComboBox1.width                 = 160
$ComboBox1.height                = 20
@('Teaching','Non Teaching','TRT','Temporary') | ForEach-Object {[void] $ComboBox1.Items.Add($_)}
$ComboBox1.location              = New-Object System.Drawing.Point(20,25)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({ if($TextBox1.Text -and $TextBox2.Text) {$Button1.Enabled = $true}})

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Staff Type"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(62,8)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 140
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(201,24)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'
$TextBox1.Add_TextChanged({ if($TextBox2.Text -and $ComboBox1 -ne "-1") {$Button1.Enabled = $true}})

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $false
$TextBox2.width                  = 140
$TextBox2.height                 = 20
$TextBox2.location               = New-Object System.Drawing.Point(358,24)
$TextBox2.Font                   = 'Microsoft Sans Serif,10'
$TextBox2.Add_TextChanged({ if($TextBox1.Text -and $ComboBox1 -ne "-1") {$Button1.Enabled = $true}})

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "First Name"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(232,8)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "Last Name"
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(395,8)
$Label3.Font                     = 'Microsoft Sans Serif,10'

$TextBox3                        = New-Object system.Windows.Forms.TextBox
$TextBox3.multiline              = $false
$TextBox3.width                  = 100
$TextBox3.height                 = 20
$TextBox3.location               = New-Object System.Drawing.Point(20,75)
$TextBox3.Font                   = 'Microsoft Sans Serif,10'
$TextBox3.TextAlign              = '2'

$Label4                          = New-Object system.Windows.Forms.Label
$Label4.text                     = "Key Tag ID"
$Label4.AutoSize                 = $true
$Label4.width                    = 25
$Label4.height                   = 10
$Label4.location                 = New-Object System.Drawing.Point(38,57)
$Label4.Font                     = 'Microsoft Sans Serif,10'

$TextBox4                        = New-Object system.Windows.Forms.TextBox
$TextBox4.multiline              = $false
$TextBox4.width                  = 120
$TextBox4.height                 = 20
$TextBox4.location               = New-Object System.Drawing.Point(134,75)
$TextBox4.Font                   = 'Microsoft Sans Serif,10'
$TextBox4.TextAlign              = '2'

$Label5                          = New-Object system.Windows.Forms.Label
$Label5.text                     = "Passtab ID"
$Label5.AutoSize                 = $true
$Label5.width                    = 25
$Label5.height                   = 10
$Label5.location                 = New-Object System.Drawing.Point(170,57)
$Label5.Font                     = 'Microsoft Sans Serif,10'

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "Convert"
$Button2.width                   = 66
$Button2.height                  = 23
$Button2.location                = New-Object System.Drawing.Point(263,75)
$Button2.Font                    = 'Microsoft Sans Serif,10'
$button2.Add_Click({
$keytaghex                       = $TextBox3.Text
$keytagrevhex                    = ([regex]::Matches("$keytaghex",'..','RightToLeft') | ForEach {$_.value}) -join ''
$keytagdec                       = [Convert]::ToInt64($keytagrevhex,16)
$TextBox4.Text                   = "$keytagdec"})

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "Create Email"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 110
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(525,12)
$CheckBox1.Font                  = 'Microsoft Sans Serif,10'
$CheckBox1.Add_CheckStateChanged({$Button4.Enabled = $checkbox1.Checked})

$CheckBox2                       = New-Object system.Windows.Forms.CheckBox
$CheckBox2.text                  = "Assign Key Tag"
$CheckBox2.AutoSize              = $false
$CheckBox2.width                 = 130
$CheckBox2.height                = 20
$CheckBox2.location              = New-Object System.Drawing.Point(525,38)
$CheckBox2.Font                  = 'Microsoft Sans Serif,10'

$Button4                       = New-Object system.Windows.Forms.Button
$Button4.text                  = "Select Groups"
$Button4.width                 = 124
$Button4.height                = 25
$Button4.location              = New-Object System.Drawing.Point(367,73)
$Button4.Font                  = 'Microsoft Sans Serif,10'
$Button4.Enabled               = $false
$Button4.Add_Click({[void]$Form1.ShowDialog()})

$Label6                          = New-Object system.Windows.Forms.Label
$Label6.text                     = "Email Group"
$Label6.AutoSize                 = $true
$Label6.width                    = 25
$Label6.height                   = 10
$Label6.location                 = New-Object System.Drawing.Point(390,57)
$Label6.Font                     = 'Microsoft Sans Serif,10'

$ListBox1                        = New-Object system.Windows.Forms.ListBox
$ListBox1.text                   = "listBox"
$ListBox1.width                  = 258
$ListBox1.height                 = 313
@('adminstaff@hopecc.sa.edu.au','blessingbuddies@hopecc.sa.edu.au','busdrivers@hopecc.sa.edu.au','canteenstaff@hopecc.sa.edu.au','chaplaincy@hopecc.sa.edu.au','femalestaff@hopecc.sa.edu.au','financestaff@hopecc.sa.edu.au','greenkeepingstaff@hopecc.sa.edu.au','itstaff@hopecc.sa.edu.au','jpteachingstaff@hopecc.sa.edu.au','leadership@hopecc.sa.edu.au','learningsupport@hopecc.sa.edu.au','librarystaff@hopecc.sa.edu.au','malestaff@hopecc.sa.edu.au','msteachingstaff@hopecc.sa.edu.au','nonteachingstaff@hopecc.sa.edu.au','oshcstaff@hopecc.sa.edu.au','primaryteachingstaff@hopecc.sa.edu.au','ssteachingstaff@hopecc.sa.edu.au','teachingstaff@hopecc.sa.edu.au','trtstaff@hopecc.sa.edu.au') | ForEach-Object {[void] $ListBox1.Items.Add($_)}
$ListBox1.location               = New-Object System.Drawing.Point(10,10)
$ListBox1.SelectionMode          = 'MultiExtended'

$Button3                         = New-Object system.Windows.Forms.Button
$Button3.text                    = "Select"
$Button3.width                   = 60
$Button3.height                  = 30
$Button3.location                = New-Object System.Drawing.Point(100,329)
$Button3.Font
$Button3.Add_Click({[void]$Form1.Close()})
 
$Form.controls.AddRange(@($Button1,$Button4,$ComboBox1,$Label1,$TextBox1,$TextBox2,$Label2,$Label3,$TextBox3,$Label4,$TextBox4,$Label5,$Button2,$CheckBox1,$CheckBox2,$ComboBox2,$Label6))
$Form1.controls.AddRange(@($ListBox1,$Button3))

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK){

$firstname = $TextBox1.Text.Trim() 
$Lastname = $TextBox2.Text.Trim()
$emailgroups = $ListBox1.SelectedItems
$StaffType = $ComboBox1.Text.Trim()


New-ADUser -Name "$Firstname $Lastname"  -UserPrincipalName "$Firstname.$Lastname@hopecc.sa.edu.au" -SamAccountName "$Firstname.$Lastname" -GivenName $Firstname -DisplayName "$Firstname $Lastname" -SurName "$Lastname" -Description "$StaffType Staff" -EmailAddress "$Firstname.$Lastname@hopecc.sa.edu.au" -Department "Staff" -Office "$StaffType" -HomeDrive "H:" -HomeDirectory "\\hopecc.sa.edu.au\staff\StaffHome\$Firstname.$Lastname" -Path "OU=$StaffType,OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "hope1234" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
Add-ADGroupMember -Identity "$StaffType Staff" -Members "$Firstname.$Lastname" -PassThru 
Add-ADGroupMember -Identity "gpStaff" -Members "$Firstname.$Lastname" -PassThru

if($CheckBox1.Checked){gam create user "$Firstname.$Lastname@hopecc.sa.edu.au" firstname "$Firstname" lastname "$Lastname" password "hope1234" changepassword "on" org "Staff/$StaffType Staff" organization department "Staff" primary
$emailgroups | Foreach-object {gam update group "$_" add "member" user "$Firstname.$Lastname@hopecc.sa.edu.au"} 
}

if($stafftype -eq "TRT"){Send-MailMessage -From 'New Staff <alerts@hopecc.sa.edu.au>' -To 'Matthew Morton <matthew.morton@hopecc.sa.edu.au>' -Subject "Computer and email account has been set up for $Firstname $Lastname" -Body "Hi Matt, `n`nI've just created a computer and email account for $Firstname $Lastname.`n`nKind Regards,`nIT Department" -SmtpServer 'aspmx.l.google.com' 
}

else{Send-MailMessage -From 'New Staff <alerts@hopecc.sa.edu.au>' -To 'IT Assistant <itstaff@hopecc.sa.edu.au>' -Subject "Please prepare a laptop for $Firstname $Lastname" -Body "Hi, `n`nI've just created a computer and email account for $Firstname $Lastname.`n`nPlease prepare a laptop for them to use." -SmtpServer 'aspmx.l.google.com' 
}

}
