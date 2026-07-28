<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Untitled
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '400,400'
$Form.text                       = "Sibelius Sounds Installer"
$Form.TopMost                    = $true
$Form.StartPosition              = "CenterScreen"
$Form.SizeGripStyle              = "Hide"
$Icon                            = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$Form.Icon                       = $Icon

function update {

begin {

$outputBox.text = "Calculating Sound Files. Please wait.."

}

process {

#count the source files

$Files = Get-ChildItem $updatepath -recurse

$Filecount = $Files.Count 

if (Test-Path $updatepath) {

$outputBox.Focus()

foreach($file in $Files) {

$ErrorActionPreference = "silentlycontinue"

Copy-Item -Path $file.FullName -Destination "$localpath" -Force

#calculate percentage

$i++

[int]$pct = ($i/$Filecount)*100

#update the progress bar

$progressbar.Value = ($pct)

$outputBox.AppendText($file.FullName + "`r`n")

Start-Sleep -Milliseconds 200

[void] [System.Windows.Forms.Application]::DoEvents()

}

}

end {$progressbar.Value = 100}

}

}

#Get Paths

$updatepath = "\\hopecc.sa.edu.au\Source\SCCM\Applications\SibeliusSounds"

$localpath = "C:\Program Files (x86)\Avid\Sibelius Sounds\Sibelius 7 Sounds"

#Form

$ProgressBar                     = New-Object system.Windows.Forms.ProgressBar
$ProgressBar.width               = 360
$ProgressBar.height              = 30
$ProgressBar.location            = New-Object System.Drawing.Point(19,313)

$OutputBox                       = New-Object system.Windows.Forms.TextBox
$OutputBox.multiline             = $true
$OutputBox.width                 = 360
$OutputBox.height                = 270
$OutputBox.location              = New-Object System.Drawing.Point(19,29)
$OutputBox.Font                  = 'Microsoft Sans Serif,8'
$outputBox.ScrollBars            = "Both"

$UpdateButton                    = New-Object system.Windows.Forms.Button
$UpdateButton.text               = "Install"
$UpdateButton.width              = 113
$UpdateButton.height             = 41
$UpdateButton.location           = New-Object System.Drawing.Point(130,351)
$UpdateButton.Font               = 'Microsoft Sans Serif,10,style=Bold'
$UpdateButton.Enabled            = {$true}
$UpdateButton.Add_Click({ if ($UpdateButton.Text -eq "Install") {update} Else {$Form.Close()}}) 

$Form.controls.AddRange(@($ProgressBar,$OutputBox,$UpdateButton,$InstVer,$LatestVer))

#Write your logic code here

#Show Form

[void]$Form.ShowDialog()