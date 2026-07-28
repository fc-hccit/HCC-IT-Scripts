$computername = $env:computername
$username = $env:username
$usernameupper = (Get-Culture).textinfo.totitlecase($username.tolower())
$firstname,$lastname = $usernameupper.Split(".")
$name = "$firstname $lastname"
$Domain = "hopecc.sa.edu.au"
$Emailsender = "alerts"
$Emailsendername = "Battery Alert"
$Emailrecipient = "devicealerts"
$Emailrecipientname = "Device Alerts"
$charging = (Get-CimInstance -ClassName batterystatus -Namespace root/WMI).PowerOnline
$Percentage = (Get-Wmiobject -Class Win32_Battery -Namespace root\CIMV2).EstimatedChargeRemaining
$Date = Get-Date
$Day = (get-date).DayOfWeek
$Time = Get-Date -format "hh:mm tt" 
$logpath = "\\hopecc.sa.edu.au\Source\Files\Battery"
$Log = "\\hopecc.sa.edu.au\Source\Files\Battery\$username.log"
$ILog =  "\\hopecc.sa.edu.au\Source\Files\Battery\Infringements\$username.log"

if ($username -eq "la") {Write-Host "Local Admin is logged in"}

if ($username -eq "ts") {Write-Host "Test Student is logged in"}

if ($username -eq "tst") {Write-Host "Test Staff is logged in"}

if ((Test-Path $logpath) -eq $false) {Write-Host "No network connection available"}

elseif ((Test-Path $log) -eq $false) {Write-Output  "$Date $computername Battery $Percentage% Charging Status: $charging" | Out-File -Append $Log}

elseif ((Get-Item $log).CreationTime.AddMonths(3) -lt $Date) {

    Remove-Item $log

    Write-Output  "$Date $computername Battery $Percentage% Charging Status: $charging" | Out-File -Append $Log

}

elseif ((Get-Item $log).LastWriteTime.AddHours(9) -lt $Date) {

    Write-Output  "$Date $computername Battery $Percentage% Charging Status: $charging" | Out-File -Append $Log

        if($Percentage -lt 80) {

            Write-Output  "On $Day at $Time, $username first logged into $computername with the battery level at $Percentage%" | Out-File -Append $ILog

            Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$name <$username.student@$Domain>" -Subject "It looks like you didn't fully charge your battery last night!" -Body "Hi $firstname, `n`nWe noticed you just logged in and your laptop's battery level was $percentage%`n`nYou must remember to fully charge your laptop every night so it's ready for the next day.`n`nYou will receive a consequence if you keep forgetting to charge your laptop." -SmtpServer "aspmx.l.google.com"

}
}

else {Write-Output  "$Date $computername Battery $Percentage% Charging Status: $charging" | Out-File -Append $Log}