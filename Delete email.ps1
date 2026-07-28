Function Delete-Email{

$searchstring = $TextBox1.text

$identity = $ComboBox1.SelectedItem

$identifier = $ComboBox3.SelectedItem

$max = $ComboBox2.SelectedItem

if ($identity -like "All Users") {$users = "all users"}

if ($identity -like "Staff") {$users = "group staff@hopecc.sa.edu.au"}

if ($identity -like "Students") {$users = "group students@hopecc.sa.edu.au"}

if ($identifier -like "Message ID") {$query = "rfc822msgid:$searchstring"}

if ($identifier -like "Subject")    {$query = "`'subject:`"$searchstring`"`'"}

if ($CheckBox1.Checked) {$confirm = "doit"}
else {$confirm = ""}

cmd /c "gam $users delete messages query $query MaxtoDelete $max $confirm"

 }


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(800,50)
$Form.text                       = "Form"
$Form.TopMost                    = $false

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Users"
$ComboBox1.width                 = 100
$ComboBox1.height                = 20
$ComboBox1.location              = New-Object System.Drawing.Point(11,15)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
@('All Users','Staff','Students') | ForEach-Object {[void] $ComboBox1.Items.Add($_)}

$ComboBox3                       = New-Object system.Windows.Forms.ComboBox
$ComboBox3.text                  = "Identifier"
$ComboBox3.width                 = 100
$ComboBox3.height                = 20
$ComboBox3.location              = New-Object System.Drawing.Point(120,15)
$ComboBox3.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
@('Message ID','Subject') | ForEach-Object {[void] $ComboBox3.Items.Add($_)}

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 296
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(230,15)
$TextBox1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "Confirm"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 75
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(655,18)
$CheckBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Checkbox1.Add_Click({if ($CheckBox1.Checked) {$Button1.text = "Execute"} else {$Button1.text = "Test"}})


$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Test"
$Button1.width                   = 65
$Button1.height                  = 25
$Button1.location                = New-Object System.Drawing.Point(730,15)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button1.Add_Click({Delete-Email})

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Max to Delete"
$ComboBox2.width                 = 110
$ComboBox2.height                = 20
$ComboBox2.location              = New-Object System.Drawing.Point(535,15)
$ComboBox2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
@('1','2','3','4','5','6','7','8','9','10') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}


$Form.controls.AddRange(@($ComboBox1,$TextBox1,$CheckBox1,$Button1,$ComboBox2,$ComboBox3))




#Write your logic code here

[void]$Form.ShowDialog()