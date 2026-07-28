Function AddDevice { 

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox1.SelectedItem
$Device = $ComboBox2.SelectedItem.ToString()
$Yearlevel = $ComboBox3.SelectedItem.ToString()
$CurrentLogonWorkstations = Get-AdUser -Identity $user -Properties LogonWorkstations | select -ExpandProperty LogonWorkstations #get current computernames that user can access

if ($CurrentLogonWorkstations) {
    Set-ADUser -Identity $User -LogonWorkstations "$CurrentLogonWorkstations,$Device" -verbose #add new workstation to existing entries
}
else { 
    Set-ADUser -Identity $User -LogonWorkstations "$Device" -verbose #only add new workstation
}

$y8ou = "OU=Year 8,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"
$y9ou = "OU=Year 9,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"
$y10ou = "OU=Year 10,OU=Senior,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"
$y6ou = "OU=Year 6,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"
$y7ou = "OU=Year 7,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"
$y11ou = "OU=Year 11,OU=Senior,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"
$y12ou = "OU=Year 12,OU=Senior,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"

if($Yearlevel -like "Year 6"){Get-ADComputer $Device | Move-ADObject -TargetPath $y6ou}
if($Yearlevel -like "Year 7"){Get-ADComputer $Device | Move-ADObject -TargetPath $y7ou}
if($Yearlevel -like "Year 8"){Get-ADComputer $Device | Move-ADObject -TargetPath $y8ou}
if($Yearlevel -like "Year 9"){Get-ADComputer $Device | Move-ADObject -TargetPath $y9ou}
if($Yearlevel -like "Year 10"){Get-ADComputer $Device | Move-ADObject -TargetPath $y10ou}
if($Yearlevel -like "Year 11"){Get-ADComputer $Device | Move-ADObject -TargetPath $y11ou}
if($Yearlevel -like "Year 12"){Get-ADComputer $Device | Move-ADObject -TargetPath $y12ou}

$popup.Popup("$Device has been checked out to $user and moved to $yearlevel OU",0,"Success",48+0)

} 


#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName
$computers = (Get-ADComputer -Filter {Enabled -eq $TRUE} -SearchBase "OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au").Name

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '420,50'
$Form.text                       = "Student Laptop Deployment Tool"
$Form.TopMost                    = $false

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Go"
$Button1.width                   = 40
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(370,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({AddDevice})
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
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox2.SelectedIndex -ne "-1") {$Button1.Enabled = $true}})

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Device Name"
$ComboBox2.width                 = 130
$ComboBox2.height                = 50
ForEach($computer in $computers) {$combobox2.Items.Add($computer)}
$combobox2.sorted                = $true
$combobox2.AutoCompleteMode      = 'Suggest'
$combobox2.AutoCompleteSource    = 'ListItems'
$ComboBox2.location              = New-Object System.Drawing.Point(150,14)
$ComboBox2.Font                  = 'Microsoft Sans Serif,10'
$ComboBox2.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true}})

$ComboBox3                       = New-Object system.Windows.Forms.ComboBox
$ComboBox3.text                  = "Year"
$ComboBox3.width                 = 70
$ComboBox3.height                = 50
@('Year 6','Year 7','Year 8','Year 9','Year 10','Year 11','Year 12') | ForEach-Object {[void] $ComboBox3.Items.Add($_)}
$ComboBox3.AutoCompleteMode      = 'Suggest'
$ComboBox3.AutoCompleteSource    = 'ListItems'
$ComboBox3.location              = New-Object System.Drawing.Point(290,14)
$ComboBox3.Font                  = 'Microsoft Sans Serif,10'
$ComboBox3.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true}})


$Form.controls.AddRange(@($Button1,$ComboBox1,$ComboBox2,$ComboBox3))

#Write your logic code here

[void]$Form.ShowDialog()