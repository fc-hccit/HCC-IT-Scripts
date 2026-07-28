$i = 1

Function load {

$Label1.text = "Infecting your computer with a virus..."

while ($i -ne 15){ 

$ProgressBar1.Value = ($i)

Start-Sleep -Milliseconds 300

$i++

}

$Label1.text = "Deleting all your files..."

while ($i -ne 55){ 

$ProgressBar1.Value = ($i)

Start-Sleep -Milliseconds 20

$i++

}

$Label1.text = "Uninstalling Windows..."

while ($i -ne 80){ 

$ProgressBar1.Value = ($i)

Start-Sleep -Milliseconds 200

$i++

} 

$ProgressBar1.Value = 100

$Label1.text = "Done!"

}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(400,108)
$Form.text                       = "Virus"
$Form.TopMost                    = $false

$ProgressBar1                    = New-Object system.Windows.Forms.ProgressBar
$ProgressBar1.width              = 367
$ProgressBar1.height             = 17
$ProgressBar1.location           = New-Object System.Drawing.Point(22,46)

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Press the button!"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(22,20)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Press"
$Button1.width                   = 60
$Button1.height                  = 19
$Button1.location                = New-Object System.Drawing.Point(167,75)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button1.Add_Click({load})

$Form.controls.AddRange(@($ProgressBar1,$Label1,$Button1))

#Write your logic code here

[void]$Form.ShowDialog()

