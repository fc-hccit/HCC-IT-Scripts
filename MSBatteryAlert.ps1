
$Domain = "hopecc.sa.edu.au"
$Emailsender = "msbatteryalerts"
$Emailsendername = "Battery Alert"
$Emailrecipient = "devicealerts"
$Emailrecipientname = "Device Alerts"
$Date = Get-Date
$Day = (get-date).DayOfWeek
$Time = Get-Date -format "hh:mm tt" 
$logdir = "\\hopecc.sa.edu.au\Source\Files\Battery\Middle School\Infringements"
$Infringments = Get-ChildItem $logdir -recurse



if ((Test-Path $logdir) -eq $false) {Write-Host "No network connection available"}

else {
    
    foreach ($Infringment in $Infringments) {

    $logfile = "$logdir\$Infringment"

    $username = $infringment.BaseName

    $Firstname,$Lastname = $username.split(".")

    $ILogContent = Get-Content -path "$logfile"

    $ILogContentDisplay = (Get-Content -path "$logfile") -join "`n"

    $InfringmentCount = $ILogContent.Count
     
    if ($InfringmentCount -gt 2) {

        Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "$Firstname $Lastname has not been fully charging His/Her laptop every night" -Body "Hi, `n`nJust letting you know that $Firstname did not fully charge His/Her laptop on the following days last week:`n`n$ILogContentDisplay`n`nCould you please discuss with them why this isn't happening and encourage them to do so.`n`nRegards," -SmtpServer "aspmx.l.google.com"
    
        Remove-Item $logfile
        
        }
     
    else {Remove-Item $logfile}
  
  }
  }

