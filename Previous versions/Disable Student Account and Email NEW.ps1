Function DisableUser { 

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox1.SelectedItem

    Disable-ADAccount -Identity $user -verbose
    gam update user "$user.student@hopecc.sa.edu.au" suspended on

$popup.Popup("$user has been successfully Disabled",0,"Success",48+0)
} 

Function EnableUser { 

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox1.SelectedItem

    Enable-ADAccount -Identity $user -verbose
    gam update user "$user.student@hopecc.sa.edu.au" suspended off

$popup.Popup("$user has been successfully enabled",0,"Success",48+0)
} 


#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '415,50'
$Form.text                       = "Disable or Enable Users Account and Email"
$Form.TopMost                    = $false

$Button1                         = New-Object system.Windows.Forms.Button

$Button1.width                   = 120
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(284,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({if($ComboBox2.SelectedItem -eq "Disable"){DisableUser} ; if($ComboBox2.SelectedItem -eq "Enable"){EnableUser}})
$Button1.Enabled                 = $true

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
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox2.SelectedIndex -ne "-1") {$Button1.Enabled = $true ; $Button1.text = $ComboBox2.SelectedItem}})

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Action"
$ComboBox2.width                 = 100
$ComboBox2.height                = 20
@('Disable','Enable') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}
$ComboBox2.location              = New-Object System.Drawing.Point(158,14)
$ComboBox2.Font                  = 'Microsoft Sans Serif,10'
$ComboBox2.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true ; $Button1.text = $ComboBox2.SelectedItem }})

$Form.controls.AddRange(@($Button1,$ComboBox1,$ComboBox2))

#Write your logic code here

[void]$Form.ShowDialog()


