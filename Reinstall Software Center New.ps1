Function Connect {
 
$CompName = $TextBox1.Text

    if (Test-Connection $CompName -Count 1) {

        $Label2.Text = "Online"
        $Label2.ForeColor = "#7ed321"
        
        }
    
   
    else {$Label2.Text = "Offline" ; $Label2.ForeColor = "#d0021b"}} 
    
Function Reinstall {


$CompName   = $TextBox1.Text
$CCMSETUP   = "\\$CompName\c$\Windows\ccmsetup"
$CCM        = "\\$CompName\c$\Windows\ccm"
$CCMTEMP    = "\\$CompName\c$\Windows\ccmtemp"
$CCMCACHE   = "\\$CompName\c$\Windows\ccmcache"
$CCMLOG     = "\\$CompName\c$\Windows\ccmsetup\Logs\ccmsetup.log"
$WINDOWS    = "\\$CompName\c$\Windows\"

if (test-path $CCMLOG) {Remove-Item $CCMLOG}

New-Item $CCMLOG -force

start $cmtrace $CCMLOG

start $WINDOWS

start-sleep 2 

cmd.exe /c C:\Engineer\PsExec.exe \\$CompName c:\windows\ccmsetup\ccmsetup.exe /uninstall

if (test-path $CCMSETUP ){Remove-Item -Path $CCMSETUP -Recurse -Force -Verbose}
if (test-path $CCM){Remove-Item -Path $CCM -Recurse -Force -Verbose}
if (test-path $CCMTEMP ){Remove-Item -Path $CCMTEMP -Recurse -Force -Verbose}
if (test-path $CCMCACHE){Remove-Item -Path $CCMCACHE -Recurse -Force -Verbose}

Write-Host "Finished"

$CompName = $TextBox1.Text
$CCMLOG     = "\\$CompName\c$\Windows\ccmsetup\Logs\ccmsetup.log"

Import-Module "\\hcc-sccm\SMS_HCC\AdminConsole\bin\ConfigurationManager\ConfigurationManager.psd1"

cd hcc:

Install-CMClient -DeviceName $CompName -IncludeDomainController $False -AlwaysInstallClient $true -ForceReinstall $True -SiteCode "HCC"

cd c:
 
}       

Write-Host "Getting Computers"

$computers = (Get-ADComputer -Filter {Enabled -eq $TRUE} -SearchBase "OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au").Name


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '150,180'
$Form.text                       = "Form"
$Form.TopMost                    = $false


$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Device Name"
$ComboBox1.width                  = 130
$ComboBox1.height                 = 20
ForEach($computer in $computers) {$combobox1.Items.Add($computer)}
$combobox1.sorted                = $true
$combobox1.AutoCompleteMode      = 'Suggest'
$combobox1.AutoCompleteSource    = 'ListItems'
$ComboBox1.location               = New-Object System.Drawing.Point(10,20)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Reinstall"
$Button1.width                   = 101
$Button1.height                  = 55
$Button1.location                = New-Object System.Drawing.Point(22,100)
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

$Form.controls.AddRange(@($ComboBox1,$Label2,$Button1,$Button2))

$cmtrace = "C:\Program Files (x86)\ConfigMgr 2012 Toolkit R2\ClientTools\CMTrace.exe"

#Write your logic code here

[void]$Form.ShowDialog()