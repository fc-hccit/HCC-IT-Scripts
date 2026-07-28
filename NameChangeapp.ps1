Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '208,145'
$Form.text                       = "Change Computer Name"
$Form.TopMost                    = $false

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.Multiline              = $false
$TextBox1.Width                  = 167
$TextBox1.Height                 = 20
$TextBox1.Location               = New-Object System.Drawing.Point(19,20)
$TextBox1.Font                   = 'Microsoft Sans Serif,10,style=Bold'

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.Multiline              = $false
$TextBox2.Width                  = 167
$TextBox2.Height                 = 20
$TextBox2.Location               = New-Object System.Drawing.Point(19,63)
$TextBox2.Font                   = 'Microsoft Sans Serif,10,style=Bold'

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.Text                    = "Delay Change"
$Button1.Width                   = 94
$Button1.Height                  = 42
$Button1.Location                = New-Object System.Drawing.Point(105,94)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({ DelayChange })

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.Text                    = "Instant Change"
$Button2.Width                   = 94
$Button2.Height                  = 42
$Button2.Location                = New-Object System.Drawing.Point(7,94)
$Button2.Font                    = 'Microsoft Sans Serif,10'
$Button2.Add_Click({ InstantChange })

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.Text                     = "Current Name"
$Label1.AutoSize                 = $true
$Label1.Width                    = 25
$Label1.Height                   = 10
$Label1.Location                 = New-Object System.Drawing.Point(58,1)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.Text                     = "New Name"
$Label2.AutoSize                 = $true
$Label2.Width                    = 25
$Label2.Height                   = 10
$Label2.Location                 = New-Object System.Drawing.Point(58,46)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$Form.Controls.AddRange(@($TextBox1,$TextBox2,$Button1,$Button2,$Label1,$Label2))

function InstantChange {
    $Old = $TextBox1.Text
    $New = $TextBox2.Text

    if (Test-Connection -ComputerName $Old -Count 1 -Quiet) {
        $TextBox1.ForeColor = [System.Drawing.Color]::FromArgb(126, 211, 33)
        $Credentials = Get-Credential hopecc\dcadmin
        Rename-Computer -ComputerName $Old -NewName $New -DomainCredential $Credentials -Force -PassThru -Restart
    } else {
        $TextBox1.ForeColor = [System.Drawing.Color]::FromArgb(208, 2, 27)
    }
}

function DelayChange {
    $Old = $TextBox1.Text
    $New = $TextBox2.Text

    if (Test-Connection -ComputerName $Old -Count 1 -Quiet) {
        $TextBox1.ForeColor = [System.Drawing.Color]::FromArgb(126, 211, 33)
        $Credentials = Get-Credential hopecc\dcadmin
        Rename-Computer -ComputerName $Old -NewName $New -DomainCredential $Credentials -Force -PassThru
        Write-Warning "Computer will Restart in 30 min?"
        cmd.exe /c shutdown /m \\$Old /r /f /c “The computer will restart, please save all work.” /t 1900
        Start-Sleep -s 3
    } else {
        $TextBox1.ForeColor = [System.Drawing.Color]::FromArgb(208, 2, 27)
    }
}

[void]$Form.ShowDialog()
