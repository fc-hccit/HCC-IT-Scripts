
#Script Variables
$ComputerName = $env:COMPUTERNAME
$Username = $env:USERNAME
#$UsernameUpper = (Get-Culture).TextInfo.ToTitleCase($Username.ToLower())
$FirstName,$LastName = $Username.Split(".")
$Name = "$FirstName $LastName"
$Domain = "hopecc.sa.edu.au"
$EmailSender = "alerts"
$EmailSenderName = "Battery Alert"
$EmailRecipient = "devicealerts"
$EmailRecipientName = "Device Alerts"
$Charging = (Get-CimInstance -ClassName batterystatus -Namespace root/WMI).PowerOnline
$Percentage = (Get-WmiObject -Class Win32_Battery -Namespace root/CIMV2).EstimatedChargeRemaining
$Wmi = Get-WmiObject -Class "BatteryStaticData" -Namespace "root\wmi"
$BatteryDesignCapacity = $Wmi.DesignedCapacity / 1000
$Wmi = Get-WmiObject -Class "BatteryFullChargedCapacity" -Namespace "root\wmi"
$BatteryFullChargeCapacity = $Wmi.FullChargedCapacity / 1000
$BatteryHealthPercent = [math]::Round(($BatteryFullChargeCapacity / $BatteryDesignCapacity) * 100)
$Date = Get-Date
$Day = (Get-Date).DayOfWeek
$Time = Get-Date -Format "hh:mm tt"
$LogPath = "\\hopecc.sa.edu.au\Source\Files\Battery"
$LocalTempLog = "C:\Users\Public\Documents\$username.log"
$Log = "\\hopecc.sa.edu.au\Source\Files\Battery\Middle School\$Username.log"
$ILog = "\\hopecc.sa.edu.au\Source\Files\Battery\Middle School\Infringements\$Username.log"

# Check for specific user logins
if ($Username -eq "la") { Write-Host "Local Admin is logged in" ; return }
if ($Username -eq "msts") { Write-Host "Test Student is logged in" ; return }
if ($Username -eq "ssts") { Write-Host "Test Student is logged in" ; return }
if ($Username -eq "tst") { Write-Host "Test Staff is logged in" ; return }

# Send email alert for low battery health
if ($BatteryHealthPercent -lt 60) {
    Send-MailMessage -From "$EmailSenderName <$EmailSender@$Domain>" -To "$Name <$EmailRecipient@$Domain>" -Subject "$ComputerName used by $Name has a battery health of $BatteryHealthPercent%" -Body "Hi IT, `n`n$ComputerName used by $Name has a battery health of $BatteryHealthPercent% `n`nPlease book the battery in for replacement" -SmtpServer "aspmx.l.google.com"
}

# Check for network connectivity
if ((Test-Path $logpath) -eq $false) {

    $WiFiProfile = Get-NetConnectionProfile

    if ($WiFiProfile -ne $null) {
        if ($WiFiProfile.Connected -eq $true) {$connected = "Connected to WiFi network: $($WiFiProfile.Name)"}
        else {$connected = "Not connected to WiFi network: $($WiFiProfile.Name)"}
        }
    else {$connected = "WiFi network profile not found."}


    if (Test-Path $LocalTempLog -and (Get-Item $LocalTempLog -ErrorAction Ignore).CreationTime.AddDays(14) -lt $Date) {
    
    Remove-Item $LocalTempLog

    Write-Output  "$Date $computername Battery $Percentage% Charging Status: $charging $connected" | Out-File -Append $LocalTempLog 
    }
    
    else{  Write-Output  "$Date $computername Battery $Percentage% Charging Status: $charging $connected" | Out-File -Append $LocalTempLog 
    
    }  
    }

# Check last write time and append battery status to log
if (Test-Path $Log){

if ((Get-Item $Log).LastWriteTime.AddHours(9) -lt $Date ) {
    Write-Output "$Date $ComputerName Battery $Percentage% Charging Status: $Charging" | Out-File -Append $Log

    # Check battery percentage and send email alert
    if ($Percentage -lt 80) {
        Write-Output "On $Day at $Time, $Username first logged into $ComputerName with the battery level at $Percentage%" | Out-File -Append $ILog
        Send-MailMessage -From "$EmailSenderName <$EmailSender@$Domain>" -To "$Name <$Username.student@$Domain>" -Subject "It looks like you didn't fully charge your battery last night!" -Body "Hi $FirstName, `n`nWe noticed you just logged in and your laptop's battery level was $Percentage%`n`nYou must remember to fully charge your laptop every night so it's ready for the next day.`n`nYou will receive a consequence if you keep forgetting to charge your laptop." -SmtpServer "aspmx.l.google.com"
    }
}
}

# Append battery status to log
else {
    Write-Output "$Date $ComputerName Battery $Percentage% Charging Status: $Charging" | Out-File -Append $Log
}
