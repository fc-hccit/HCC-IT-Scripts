Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '236,110'
$Form.text                       = "Key Tag"
$Form.BackColor                  = "#4a90e2"
$Form.TopMost                    = $false
$Form.StartPosition              = 'CenterScreen'

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $false
$TextBox2.width                  = 198
$TextBox2.height                 = 20
$TextBox2.location               = New-Object System.Drawing.Point(17,28)
$TextBox2.Font                   = 'Microsoft Sans Serif,10'
$TextBox2.TextAlign              = '2'
$TextBox2.Add_TextChanged({if($TextBox2.Text.Length -gt 1){
$keytaghex                       = $TextBox2.Text
$keytagrevhex                    = ([regex]::Matches("$keytaghex",'..','RightToLeft') | ForEach {$_.value}) -join ''
$keytagdec                       = [Convert]::ToInt64($keytagrevhex,16)
$TextBox1.Text                   = "$keytagdec"}})

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 198
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(17,72)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'
$TextBox1.TextAlign              = '2'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Papercut ID"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(75,9)
$Label1.Font                     = 'Microsoft Sans Serif,10,style=Bold'
$Label1.ForeColor                = "#ffffff"

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Passtab ID"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(75,53)
$Label2.Font                     = 'Microsoft Sans Serif,10,style=Bold'
$Label2.ForeColor                = "#ffffff"

$Form.controls.AddRange(@($TextBox2,$TextBox1,$Button1,$Label1,$Label2))




#Write your logic code here

[void]$Form.ShowDialog()