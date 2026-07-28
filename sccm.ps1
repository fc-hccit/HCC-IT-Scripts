<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    test
#>

Function Connect {
 
$CompName   = $TextBox1.Text
$CCMSETUP   = "\\$CompName\c$\Windows\ccmsetup"
$CCM        = "\\$CompName\c$\Windows\ccm"
$CCMTEMP    = "\\$CompName\c$\Windows\ccmtemp"
$CCMCACHE   = "\\$CompName\c$\Windows\ccmcache"
$CCMLOG     = "\\$CompName\c$\Windows\ccmsetup\Logs\ccmsetup.log"
$WINDOWS    = "\\$CompName\c$\Windows\"

    if (Test-Connection $CompName -Count 1) {

        $Label2.Text = "Online"
        $Label2.ForeColor = "#7ed321"
        start $cmtrace $CCMLOG
        }
    
   
    else {$Label2.Text = "Offline" ; $Label2.ForeColor = "#d0021b"}} 
    
Function Uninstall {

$CompName   = $TextBox1.Text
$CCMSETUP   = "\\$CompName\c$\Windows\ccmsetup"
$CCM        = "\\$CompName\c$\Windows\ccm"
$CCMTEMP    = "\\$CompName\c$\Windows\ccmtemp"
$CCMCACHE   = "\\$CompName\c$\Windows\ccmcache"
$CCMLOG     = "\\$CompName\c$\Windows\ccmsetup\Logs\ccmsetup.log"
$WINDOWS    = "\\$CompName\c$\Windows\"



start-sleep 2 

cmd.exe /c C:\Engineer\PsExec.exe \\$CompName c:\windows\ccmsetup\ccmsetup.exe /uninstall

if (test-path $CCMSETUP ){Remove-Item -Path $CCMSETUP -Recurse -Force -Verbose}
if (test-path $CCM){Remove-Item -Path $CCM -Recurse -Force -Verbose}
if (test-path $CCMTEMP ){Remove-Item -Path $CCMTEMP -Recurse -Force -Verbose}
if (test-path $CCMCACHE){Remove-Item -Path $CCMCACHE -Recurse -Force -Verbose}

Write-Host "Finished"
}       

Function Reinstall {

Write-Host "Reinstalling"

$CompName = $TextBox1.Text

Write-Host "Turning off Metered Connection"

cmd.exe /c C:\Engineer\PsExec.exe \\$CompName netsh wlan set profileparameter name="Hope-Student-WiFi" cost=unrestricted


Write-Host "Metered Connection turned off"

Import-Module "\\hcc-sccm\SMS_HCC\AdminConsole\bin\ConfigurationManager\ConfigurationManager.psd1"

cd hcc:

Install-CMClient -DeviceName $CompName -IncludeDomainController $False -AlwaysInstallClient $true -ForceReinstall $True -SiteCode "HCC"

cd c:
 
}       



Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '150,250'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 100
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(23,33)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Computer Name"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(20,16)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Button3                         = New-Object system.Windows.Forms.Button
$Button3.text                    = "Reinstall"
$Button3.width                   = 101
$Button3.height                  = 55
$Button3.location                = New-Object System.Drawing.Point(22,174)
$Button3.Font                    = 'Microsoft Sans Serif,10'
$Button3.Add_Click({Reinstall}) 

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Uninstall"
$Button1.width                   = 101
$Button1.height                  = 55
$Button1.location                = New-Object System.Drawing.Point(22,111)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({Uninstall}) 

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "Connect"
$Button2.width                   = 101
$Button2.height                  = 26
$Button2.location                = New-Object System.Drawing.Point(22,61)
$Button2.Font                    = 'Microsoft Sans Serif,10'
$Button2.Add_Click({Connect}) 

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(55,90)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($OutputBox1,$TextBox1,$Label1,$Label2,$Button3,$Button1,$Button2))


$cmtrace = ".\CMTrace.exe"

#Write your logic code here

[void]$Form.ShowDialog()