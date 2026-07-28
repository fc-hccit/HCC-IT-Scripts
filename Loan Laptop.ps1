
#Get Users

$users = (Get-ADUser -Filter * -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").Name


#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '415,50'
$Form.text                       = "Loan Laptop Deployment Tool"
$Form.TopMost                    = $false

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Assign "
$Button1.width                   = 120
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(284,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Student Name"
$ComboBox1.width                 = 130
$ComboBox1.height                = 30
$users | ForEach-Object {[void] $ComboBox2.Items.Add($_)}
$ComboBox1.location              = New-Object System.Drawing.Point(14,14)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Loan Laptop "
$ComboBox2.width                 = 100
$ComboBox2.height                = 20
@('HCCLOAN1','HCCLOAN2','HCCLOAN3','HCCLOAN4','HCCLOAN5','HCCLOAN6','HCCLOAN7','HCCLOAN8','HCCLOAN9','HCCLOAN10') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}
$ComboBox2.location              = New-Object System.Drawing.Point(158,14)
$ComboBox2.Font                  = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($Button1,$ComboBox1,$ComboBox2))




#Write your logic code here

[void]$Form.ShowDialog()


