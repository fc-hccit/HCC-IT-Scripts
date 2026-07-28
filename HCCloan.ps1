
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
$computername = $env:computername
$path = "\\hopecc.sa.edu.au\Source\Files\Loan"
$date = (Get-Date)

function Create-Loanfile {#Create Loan File

Write-Output "Username: $($username) Date: $($date) Loan Laptop: $($computername) Previously Borrowed Times: $(0)" | Out-File -Append -FilePath‪ $path\$username.txt

$popup.Popup("This is your first laptop loan of the term.`nPlease remember to bring your laptop to school every day!",0,"Reminder",48+0)}

function Update-Loanfile {
# Update user loan file

if (Test-Path -Path $path\$username.txt) {

$username = $env:username
$computername = $env:computername
$loanedtimes = Get-Content -path $path\$username.txt
$loanedtimesnumber = $loanedtimes.Count

# Check Date

if ((Get-Item $path\$username.txt).LastWriteTime.AddHours(9) -lt $date) {

if ( $loanedtimes.Count -ge 3) {
   
#ScriptBlock

$toomany = Start-Job -ScriptBlock {   
$popup = New-Object -ComObject wscript.shell
$popup.popup("You have borrowed the laptop too many times this term!`nYou may only borrow it 3 times per term.`nYour computer will now shutdown!`nPlease return this laptop to the IT office",0,"Oops!",16+0)}
        
Write-Host "Too many times!" 

$toomany

Start-Sleep 10

Stop-Computer }
   
elseif ($loanedtimes.Count -eq 2) {

Write-Output "Username: $($username) Date: $($date) Loan Laptop: $($computername) Previously Borrowed Times: $($loanedtimesnumber)" | Out-File -Append -FilePath‪ $path\$username.txt

$popup.Popup("You have already borrowed the loan laptop $loanedtimesnumber times this term.`nThis is the last time you will be able to borrow it this term.",0,"Reminder",48+0)}

else { 

Write-Output "Username: $($username) Date: $($date) Loan Laptop: $($computername) Previously Borrowed Times: $($loanedtimesnumber)" | Out-File -Append -FilePath‪ $path\$username.txt
$popup.Popup("You have already borrowed the loan laptop $loanedtimesnumber time this term.`nYou may only borrow it 3 times per term.`nPlease remember to bring your laptop to school every day!",0,"Reminder",48+0)}
        
else { Write-Host "Already updated loan file"}}}

else {Create-Loanfile}
}

# Check Local Admin

if ($username -eq "la") {Write-Host "Local Admin is logged in"}

# Check log on hours

elseif ((Get-Date).DayOfWeek -eq "Saturday") {Write-Host "Login not allowed on Saturday" 
Stop-Computer }
elseif ((Get-Date).DayOfWeek -eq "Sunday") {Write-Host "Login not allowed on Sunday" 
Stop-Computer }
elseif ((Get-Date).Hour -lt 8) {Write-Host "Login not allowed before 8am" 
Stop-Computer }
elseif ((Get-Date).Hour -gt 17) {Write-Host "Login not allowed after 5pm"
Stop-Computer }

else {
 
# Check Path Accesible   

if (!(Test-Path -Path $path)) {
    
netsh wlan connect name="Hope-Student-WiFi"

start-sleep 5

if (Test-Path -Path $path) {Update-Loanfile}
    


else { #ScriptBlock

$noauth = Start-Job -ScriptBlock {   
$popup = New-Object -ComObject wscript.shell
$popup.popup("The HCC Network is not available,`nShutting Down!",0,"Oops!",16+0)}
      
Write-Host "Network not available!" 

$noauth

Start-Sleep 10

Stop-Computer -Force }

}


else {Update-Loanfile}
}



