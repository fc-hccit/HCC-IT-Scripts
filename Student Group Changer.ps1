Function UserChanges { 


$username = $ComboBox1.SelectedItem.ToString()
$Yearlevel = $ComboBox3.SelectedItem.ToString()
$userGroups = Get-ADPrincipalGroupMembership $username
$useremail = "$username.student@hopecc.sa.edu.au"


if($Yearlevel -like "Year 5"){$groups = "gpOUStudentsPrimary","gpOUStudentsYr5","Year 5 Students"; $section = "Primary School"; $GOU = "Middle School Students (Restricted Mail)/Year 5 Students"}
if($Yearlevel -like "Year 6"){$groups = "gpOUStudentsMiddle","gpOUStudentsYr6","Year 6 Students"; $section = "Middle School"; $GOU = "Middle School Students (Restricted Mail)/Year 6 Students"}
if($Yearlevel -like "Year 7"){$groups = "gpOUStudentsMiddle","gpOUStudentsYr7","Year 7 Students"; $section = "Middle School"; $GOU = "Middle School Students (Restricted Mail)/Year 7 Students"}
if($Yearlevel -like "Year 8"){$groups = "gpOUStudentsMiddle","gpOUStudentsYr8","Year 8 Students"; $section = "Middle School"; $GOU = "Middle School Students (Restricted Mail)/Year 8 Students"}
if($Yearlevel -like "Year 9"){$groups = "gpOUStudentsMiddle","gpOUStudentsYr9","Year 9 Students"; $section = "Middle School"; $GOU = "Middle School Students (Restricted Mail)/Year 9 Students"}
if($Yearlevel -like "Year 10"){$groups = "gpOUStudentsSenior","gpOUStudentsYr10","Year 10 Students"; $section = "Senior School"; $GOU = "Senior School Students/Year 10 Students"}
if($Yearlevel -like "Year 11"){$groups = "gpOUStudentsSenior","gpOUStudentsYr11","Year 11 Students"; $section = "Senior School"; $GOU = "Senior School Students/Year 11 Students"}
if($Yearlevel -like "Year 12"){$groups = "gpOUStudentsSenior","gpOUStudentsYr12","Year 12 Students"; $section = "Senior School"; $GOU = "Senior School Students/Year 12 Students"}

# Remove user from all groups
foreach ($group in $userGroups) {
    if ($group.Name -ne "Domain Users") {
        Remove-ADPrincipalGroupMembership $username -MemberOf $group -Confirm:$false -verbose
    }
}

gam user $useremail delete groups


# Add user to specified groups
foreach ($group in $groups) {
    Add-ADGroupMember $group -Members $username -verbose
}

$GGroup = "$Yearlevel Students"

gam update group $GGroup.Replace(" ","") add member $useremail

# Move user to specified OU
Get-ADUser $username | Move-ADObject -TargetPath "OU=$Yearlevel,OU=$section,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -Verbose

gam update user $useremail org $GOU organization department "$yearlevel" primary

$notification.ShowBalloonTip(5000, "Success", "$username's groups have been changed successfully!", [System.Windows.Forms.ToolTipIcon]::Info)

} 

$notification = New-Object System.Windows.Forms.NotifyIcon
$notification.Icon = [System.Drawing.SystemIcons]::Information
$notification.Visible = $true

#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '290,50'
$Form.text                       = "Student Laptop Deployment Tool"
$Form.TopMost                    = $false

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Go"
$Button1.width                   = 40
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(240,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({UserChanges})
$Button1.Enabled                 = $false

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Student Name"
$ComboBox1.width                 = 130
$ComboBox1.height                = 30
ForEach($user in $users) {$combobox1.Items.Add($User)}
$combobox1.sorted                = $true
$combobox1.AutoCompleteMode      = 'Suggest'
$combobox1.AutoCompleteSource    = 'ListItems'
$ComboBox1.location              = New-Object System.Drawing.Point(14,14)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox3.SelectedIndex -ne "-1") {$Button1.Enabled = $true}})


$ComboBox3                       = New-Object system.Windows.Forms.ComboBox
$ComboBox3.text                  = "Year"
$ComboBox3.width                 = 70
$ComboBox3.height                = 50
@('Year 5','Year 6','Year 7','Year 8','Year 9','Year 10','Year 11','Year 12') | ForEach-Object {[void] $ComboBox3.Items.Add($_)}
$ComboBox3.AutoCompleteMode      = 'Suggest'
$ComboBox3.AutoCompleteSource    = 'ListItems'
$ComboBox3.location              = New-Object System.Drawing.Point(150,14)
$ComboBox3.Font                  = 'Microsoft Sans Serif,10'
$ComboBox3.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true}})


$Form.controls.AddRange(@($Button1,$ComboBox1,$ComboBox3))

#Write your logic code here

[void]$Form.ShowDialog()