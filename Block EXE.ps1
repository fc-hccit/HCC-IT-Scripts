#Get Computers

$computers = (Get-ADComputer -Filter {Enabled -eq $TRUE} -SearchBase "OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '415,50'
$Form.text                       = "Block Executable"
$Form.TopMost                    = $false

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Block"
$Button1.width                   = 120
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(284,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({AddDevice})
$Button1.Enabled                 = $false

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Computer Name"
$ComboBox1.width                 = 130
$ComboBox1.height                = 30
ForEach($user in $users) {$combobox1.Items.Add($User)}
$combobox1.sorted                = $true
$combobox1.AutoCompleteMode      = 'Suggest'
$combobox1.AutoCompleteSource    = 'ListItems'
$ComboBox1.location              = New-Object System.Drawing.Point(14,14)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox2.SelectedIndex -ne "-1") {$Button1.Enabled = $true}})

$ComboBox2                       = New-Object system.Windows.Forms.TextBox
$ComboBox2.width                 = 100
$ComboBox2.height                = 20
$ComboBox2.location              = New-Object System.Drawing.Point(158,14)
$ComboBox2.Font                  = 'Microsoft Sans Serif,10'
$ComboBox2.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true}})

$Form.controls.AddRange(@($Button1,$ComboBox1,$ComboBox2))

#Write your logic code here

[void]$Form.ShowDialog()

Enter-PSSession 
