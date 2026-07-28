function delete-profile {

$regpath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\"
$Username = $ComboBox1.SelectedItem
$UserAccountPath = "C:\\Users\\$Username"
$WMIQuery = "SELECT * FROM Win32_UserProfile WHERE localpath = '$UserAccountPath'"
$UserProfile = Get-WmiObject -Query $WMIQuery 
$SID = $UserProfile.SID 

if ($sid -eq $null){Write-Host "User Don't Exist in Registry"}

else {
if(test-path $regpath$SID){
Remove-Item -Path "$regpath$SID" -Force -Verbose -Recurse
Write-Host "Deleted Profile from Registry"}

if(Test-Path "$regpath$SID.bak"){Remove-Item -Path "$regpath$SID.bak" -Force -Verbose -Recurse
Write-Host "Deleted Backup Profile from Registry"}

if(Test-Path "$UserAccountPath"){
takeown /f "C:\\Users\\$Username" /r /d y
Remove-Item -Path $UserAccountPath -Force -Verbose -Recurse
Write-Host "Deleted Profile from Users Folder"}

if(Test-Path "$UserAccountPath.HOPECC"){
takeown /f "C:\\Users\\$Username.HOPECC" /r /d y
Remove-Item -Path "$UserAccountPath.HOPECC" -Force -Verbose -Recurse
Write-Host "Deleted Profile from Users Folder"}

}

}


#Get Students

$WMIQuery = "SELECT * FROM Win32_UserProfile WHERE localpath LIKE '%Users%'"

$UserProfile = Get-WmiObject -Query $WMIQuery

$paths = $UserProfile.LocalPath


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(300,150)
$Form.text                       = "Remove Profile"
$Form.TopMost                    = $true
$Form.StartPosition              = 'CenterScreen'

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Select Profile"
ForEach($path in $paths) {$combobox1.Items.Add(($path -split '\\')[-1])}
$ComboBox1.width                 = 250
$ComboBox1.height                = 80
$ComboBox1.location              = New-Object System.Drawing.Point(20,20)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Delete"
$Button1.width                   = 90
$Button1.height                  = 50
$Button1.location                = New-Object System.Drawing.Point(100,80)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button1.Add_Click({delete-profile})

$Form.controls.AddRange(@($ComboBox1,$Button1))


[void]$Form.ShowDialog()



