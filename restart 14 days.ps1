#Last Restart

$Lastrestart = (get-date) - (gcim Win32_OperatingSystem).LastBootUpTime | select days

$days = $Lastrestart -replace "\D" , ""  

#Popup

$popup = New-Object -ComObject Wscript.Shell

if([int]$days -ge 14) {

if($result  = $popup.Popup(" Your Laptop has not been restarted for $days days!`n`n Your device may be running slower than usual.`n`n Would you like to restart your computer now?",30,"  Your laptop needs to be restarted",48+4) -eq 6) {

if($restart = $popup.Popup("Have you saved all open files or documents?",0,"Please save any open files or documents!",32+4) -eq 6) {cmd.exe /c shutdown /r}

else {cmd.exe /c shutdown /r /t 300 /c "Your Laptop will restart in 5 minutes, Please save any open files or documents!"}}

else {cmd.exe /c shutdown /r /t 300 /c "Your Laptop will restart in 5 minutes, Please save any open files or documents!"}

}

