<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Untitled
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '400,400'
$Form.text                       = "PCSchool Update"
$Form.TopMost                    = $true
$Form.StartPosition              = "CenterScreen"
$Form.SizeGripStyle              = "Hide"
$Icon                            = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$Form.Icon                       = $Icon

function update {

begin {
$Wait = 1
While ($wait -lt 5){
$outputBox.text = "Checking Update Files. Please wait"
Start-Sleep -Milliseconds 500
$outputBox.text = "Checking Update Files. Please wait."
Start-Sleep -Milliseconds 500
$outputBox.text = "Checking Update Files. Please wait.."
Start-Sleep -Milliseconds 500
$outputBox.text = "Checking Update Files. Please wait..."
$wait++
}
$outputBox.text = "Checking Update Files. Please wait...`n"
Start-Sleep -Milliseconds 500
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

$outputBox.AppendText("Finished!")
$InstVer.ForeColor    = "#7ed321"
$CurrentVerion        = (Get-ChildItem "$localpath\Version.pcs").LastWriteTime.Date.ToShortDateString()
$InstVer.text         = "Installed Version:$CurrentVerion"
$UpdateButton.text    = "DONE"
}

}

#Get Paths

if(Test-Path "C:\PCSLaunch\Programs") {$localpath = "C:\PCSLaunch\Programs"} 
elseif (Test-Path "C:\PCSLaunch\Programs") {$localpath = "C:\PCSLaunch\PCSchool\Programs"}
else {Write-Error "PCSchool is not installed on this computer"}

$updatepath = "$(Get-Location)"

#Get Versions
if(test-path "$localpath\Version.pcs"){
if(Get-ChildItem "$localpath\Version.pcs"){$CurrentVerion = (Get-ChildItem "$localpath\Version.pcs").LastWriteTime.Date.ToShortDateString()}}

else{Write-Error "Can't Check Local Version.pcs"}

if(test-path "$localpath\Version.pcs"){
if(Get-ChildItem "$updatepath\Version.pcs"){$LatestVersion = (Get-ChildItem "$updatepath\Version.pcs").LastWriteTime.ToShortDateString()}}

else{Write-Error "Can't Read Updated Version.pcs"}


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
$UpdateButton.text               = "UPDATE"
$UpdateButton.width              = 113
$UpdateButton.height             = 41
$UpdateButton.location           = New-Object System.Drawing.Point(130,351)
$UpdateButton.Font               = 'Microsoft Sans Serif,10,style=Bold'
#$UpdateButton.Enabled            = if($CurrentVerion -lt $LatestVersion) {$true} Else {$false}
$UpdateButton.Add_Click({ if ($UpdateButton.Text -eq "UPDATE") {update} Else {$Form.Close()}}) 

$InstVer                         = New-Object system.Windows.Forms.Label
$InstVer.text                    = "Installed Version:$CurrentVerion"
$InstVer.AutoSize                = $true
$InstVer.width                   = 28
$InstVer.height                  = 10
$InstVer.location                = New-Object System.Drawing.Point(18,12)
$InstVer.Font                    = 'Microsoft Sans Serif,10,style=Bold'
$InstVer.ForeColor               = if($CurrentVerion -lt $LatestVersion) {"#d0021b"} Else {"#7ed321"}

$LatestVer                       = New-Object system.Windows.Forms.Label
$LatestVer.text                  = "Latest Version:$LatestVersion"
$LatestVer.AutoSize              = $true
$LatestVer.width                 = 25
$LatestVer.height                = 10
$LatestVer.location              = New-Object System.Drawing.Point(210,12)
$LatestVer.Font                  = 'Microsoft Sans Serif,10,style=Bold'
$LatestVer.ForeColor             = "#7ed321"

$Form.controls.AddRange(@($ProgressBar,$OutputBox,$UpdateButton,$InstVer,$LatestVer))

#Write your logic code here

#Show Form

[void]$Form.ShowDialog()