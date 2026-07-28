
Function ResetPassword { 

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox1.SelectedItem

    Set-ADAccountPassword -Identity $User -NewPassword (ConvertTo-SecureString -AsPlainText "hope1234" -Force)

$popup.Popup("$user's has been successfully changed",0,"Success",48+0)
} 


#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '300,50'
$Form.text                       = "Reset Student Password"
$Form.TopMost                    = $false

$Button1                         = New-Object system.Windows.Forms.Button

$Button1.width                   = 120
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(162,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({ResetPassword})
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
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true ; $Button1.text = "Reset Password"}})

$Form.controls.AddRange(@($Button1,$ComboBox1))

#Write your logic code here

[void]$Form.ShowDialog()


