
###############################
#
# HCC Loan Laptop Script
#
# Created by Nathan Dawson
#
# Date 26/06/2019
#
# Version 2.0
#
#
################################

# Variables
$popup = New-Object -ComObject Wscript.Shell
$username = $env:username
$path = "\\hopecc.sa.edu.au\Source\Files\Loan"
$date = (Get-Date)

# Check Local Admin

if ($username -eq "la") {Write-Host "Local Admin is logged in"}

# Check log on hours

elseif ((Get-Date).DayOfWeek -eq "Saturday") {
Write-Host "Login not allowed on Saturday" 
$noauth = Start-Job -ScriptBlock {   
$popup = New-Object -ComObject wscript.shell
$popup.popup("Weekend use is not allowed on a loan device!,`nShutting Down!",0,"Oops!",16+0)}
$noauth
Start-Sleep 10
Stop-Computer -Force }
elseif ((Get-Date).DayOfWeek -eq "Sunday") {Write-Host "Login not allowed on Sunday" 
$noauth = Start-Job -ScriptBlock {   
$popup = New-Object -ComObject wscript.shell
$popup.popup("Weekend use is not allowed on a loan device!,`nShutting Down!",0,"Oops!",16+0)}
$noauth
Start-Sleep 10
Stop-Computer -Force }
elseif ((Get-Date).Hour -lt 8) {Write-Host "Login not allowed before 8am" 
$noauth = Start-Job -ScriptBlock {   
$popup = New-Object -ComObject wscript.shell
$popup.popup("Login not allowed before 8am on a loan device!,`nShutting Down!",0,"Oops!",16+0)}
$noauth
Start-Sleep 10
Stop-Computer -Force }
elseif ((Get-Date).Hour -gt 17) {Write-Host "Login not allowed after 5pm"
$noauth = Start-Job -ScriptBlock {   
$popup = New-Object -ComObject wscript.shell
$popup.popup("Login not allowed after 5pm on a loan device!,`nShutting Down!",0,"Oops!",16+0)}
$noauth
Start-Sleep 10
Stop-Computer -Force }

else {
 
# Check Path Accesible   

if (!(Test-Path -Path $path)) {
    
netsh wlan connect name="Hope-Student-WiFi"

start-sleep 5

if (Test-Path -Path $path) {Write-Host "Network Available"}
    


else { #ScriptBlock

$noauth = Start-Job -ScriptBlock {   
$popup = New-Object -ComObject wscript.shell
$popup.popup("This loan device may only be used at Hope Christian College!,`nShutting Down!",0,"Oops!",16+0)}
      
Write-Host "Network not available!" 

$noauth

Start-Sleep 10

Stop-Computer -Force }

}


else {Write-Host "Network Available"}
}



