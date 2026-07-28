$User = Read-Host -Prompt 'Input the user name'
$regpath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\"
$UserAccountPath = "C:\\Users\\$User"
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

if(Test-Path ){
takeown /f $UserAccountPath /r /d y
Remove-Item -Path $UserAccountPath -Force -Verbose -Recurse
Write-Host "Deleted Profile from Users Folder"}

if(Test-Path "$UserAccountPath.HOPECC"){
takeown /f "$UserAccountPath.HOPECC" /r /d y
Remove-Item -Path "$UserAccountPath.HOPECC" -Force -Verbose -Recurse
Write-Host "Deleted Profile from Users Folder"}
}