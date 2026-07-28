#See if process is running

Get-Process client32.exe

#See if the program is installed

Test-Path -Path 'C:\Program Files (x86)\Acer\Acer Classroom Manager\client32.exe'

#If the last two commands are false, email IT to install software

Send-MailMessage -From "ACM Alert <alerts@hopecc.sa.edu.au>" -To "$itstaff@hopecc.sa.edu.au" -Subject "$username $devicename does not have ACM installed" -Body "Hi IT, `n`n$username Does not have ACM installed. Please call them to the IT Office to have it installed" -SmtpServer "aspmx.l.google.com"

#If the program is installed but not running

Start-Process -Path 'C:\Program Files (x86)\Acer\Acer Classroom Manager\client32.exe'

#What group is the device in? Check registry, then include group in email

$key = 'HKLM:\SOFTWARE\Policies\NetSupport\Client\Standard'
$string = (Get-ItemProperty -Path $key -Name RoomSpec).RoomSpec

#Get name of the student and device and include in email

$env:UserName
$env:ComputerName

