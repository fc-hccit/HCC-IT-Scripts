#Get name of the student and device and include in email
$unkey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
$LastLoggedOnUser = (Get-ItemProperty -Path $unkey -Name LastLoggedOnUser).LastLoggedOnUser
$usernamesplit = $LastLoggedOnUser.split("\") 
$username = $usernamesplit[1]
$devicename = $env:ComputerName
$installpath = 'C:\Program Files (x86)\Acer\Acer Classroom Manager\client32.exe'
$fileVersion = (Get-Item $installpath).VersionInfo.FileVersion
$fileVersion


#See if the program is installed

if (Test-Path -Path $installpath){

#Wait 60 Seconds

Start-Sleep -Seconds 60


#See if process is running

if (!(Get-Process client32 -ErrorAction SilentlyContinue)){


 Send-MailMessage -From "ACM Alert <alerts@hopecc.sa.edu.au>" -To "itstaff@hopecc.sa.edu.au" -Subject "ACM service $fileVersion is installed but not running on $username's $devicename" -SmtpServer "aspmx.l.google.com" -ErrorAction SilentlyContinue}

  }

 
else {

#If the last two commands are false, email IT to install software

Send-MailMessage -From "ACM Alert <alerts@hopecc.sa.edu.au>" -To "itstaff@hopecc.sa.edu.au" -Subject "$username $devicename does not have ACM installed" -SmtpServer "aspmx.l.google.com"

}