#Copy / Paste 

Function BagLabel {

$firstname,$lastname = $ComboBox1.text.Split(".")

Set-Clipboard -Value "$firstname $lastname"

start "C:\Users\luke.trollope\Desktop\Scripts\Student Laptop Bag Label.docx"

}

Function LaptopLabel {

$firstname,$lastname = $ComboBox1.text.Split(".")

Set-Clipboard -Value "$firstname $lastname"

start D:\PTLITE10.EXE

}

#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '300,50'
$Form.text                       = "Print Laptop Label"
$Form.TopMost                    = $True
$Form.Icon                       = [system.drawing.icon]::ExtractAssociatedIcon("Print Laptop Label.exe")
$Form.StartPosition              = "CenterScreen"

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.width                   = 60
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(162,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({LaptopLabel})
$Button1.Enabled                 = $false
$Button1.text                    = "Laptop"

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.width                   = 60
$Button2.height                  = 30
$Button2.location                = New-Object System.Drawing.Point(225,11)
$Button2.Font                    = 'Microsoft Sans Serif,10'
$Button2.Add_Click({BagLabel})
$Button2.Enabled                 = $false
$Button2.text                    = "Bag"

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
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true ; $Button2.Enabled = $true}})

$Form.controls.AddRange(@($Button1,$ComboBox1,$Button2))

#Write your logic code here

[void]$Form.ShowDialog()

