Function Computer { 

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox3.SelectedItem

   $NewPassword = Read-Host "Enter new password" -AsSecureString

   Set-ADAccountPassword -Identity $User -NewPassword $NewPassword -Reset
    
   Set-ADUser -Identity $User -ChangePasswordAtLogon $false

$notification.ShowBalloonTip(5000, "Success", "Password has been changed successfully!", [System.Windows.Forms.ToolTipIcon]::Info)
} 

Function Email { 

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox3.SelectedItem

    gam update user "$user.student@hopecc.sa.edu.au" password "hope1234" changepassword "off"

$notification.ShowBalloonTip(5000, "Success", "Password has been changed successfully!", [System.Windows.Forms.ToolTipIcon]::Info)
} 

Function Both { 

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox3.SelectedItem

$NewPassword = Read-Host "Enter new password" -AsSecureString

Set-ADAccountPassword -Identity $User -NewPassword $NewPassword -Reset


    Set-ADUser -Identity $User -ChangePasswordAtLogon $false
    
    gam update user "$user.student@hopecc.sa.edu.au" password $NewPassword changepassword "off"

$notification.ShowBalloonTip(5000, "Success", "Password has been changed successfully!", [System.Windows.Forms.ToolTipIcon]::Info)
} 

#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '415,50'
$Form.text                       = "Reset student computer and email password"
$Form.TopMost                    = $true
$Form.StartPosition              = "CenterScreen"
$Form.Icon                       = [system.drawing.icon]::ExtractAssociatedIcon("Reset student computer and email password.exe")

$notification = New-Object System.Windows.Forms.NotifyIcon
$notification.Icon = [System.Drawing.SystemIcons]::Information
$notification.Visible = $true

$Button4                         = New-Object system.Windows.Forms.Button
$Button4.text                    = "Reset Password"
$Button4.width                   = 120
$Button4.height                  = 30
$Button4.location                = New-Object System.Drawing.Point(284,11)
$Button4.Font                    = 'Microsoft Sans Serif,10'
$Button4.Add_Click({if($ComboBox4.SelectedItem -eq "Computer"){Computer} ; if($ComboBox4.SelectedItem -eq "Email"){Email} ; if($ComboBox4.SelectedItem -eq "Both"){Both}})
$Button4.Enabled                 = $false

$ComboBox3                       = New-Object system.Windows.Forms.ComboBox
$ComboBox3.text                  = "Student Name"
$ComboBox3.width                 = 130
$ComboBox3.height                = 30
ForEach($user in $users) {$ComboBox3.Items.Add($User)}
$ComboBox3.sorted                = $true
$ComboBox3.AutoCompleteMode      = 'Suggest'
$ComboBox3.AutoCompleteSource    = 'ListItems'
$ComboBox3.location              = New-Object System.Drawing.Point(14,14)
$ComboBox3.Font                  = 'Microsoft Sans Serif,10'
$ComboBox3.add_SelectedIndexChanged({ if($ComboBox4.SelectedIndex -ne "-1") {$Button4.Enabled = $true}})

$ComboBox4                       = New-Object system.Windows.Forms.ComboBox
$ComboBox4.text                  = "Select Account"
$ComboBox4.width                 = 120
$ComboBox4.height                = 20
@('Computer','Email','Both') | ForEach-Object {[void] $ComboBox4.Items.Add($_)}
$ComboBox4.location              = New-Object System.Drawing.Point(154,14)
$ComboBox4.Font                  = 'Microsoft Sans Serif,10'
$ComboBox4.add_SelectedIndexChanged({ if($ComboBox3.SelectedIndex -ne "-1") {$Button4.Enabled = $true}})

$Form.controls.AddRange(@($Button4,$ComboBox3,$ComboBox4))


#Write your logic code here

[void]$Form.ShowDialog()


