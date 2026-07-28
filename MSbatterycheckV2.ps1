# Script Variables
$ComputerName = $env:COMPUTERNAME
$Username = $env:USERNAME
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
$Time24 = Get-Date -Format "HH:mm"
$Time = Get-Date -Format "hh:mm tt"
$LogPath = "\\hopecc.sa.edu.au\Source\Files\Battery"
$LocalTempLog = "C:\Users\Public\Documents\#"
$Log = "\\hopecc.sa.edu.au\Source\Files\Battery\Middle School\$Username.log"
$ILog = "\\hopecc.sa.edu.au\Source\Files\Battery\Middle School\Infringements\$Username.log"

# Function to append updates from offline log file to network log file
Function AppendOfflineUpdatesToNetworkLog {

    if (Test-Path $LocalTempLog) {
        $NetworkLogLastWriteTime = (Get-Item $Log).LastWriteTime
        $CurrentTime = Get-Date
        Write-Host {"LocalLogExists"}

        if ($NetworkLogLastWriteTime -lt $CurrentTime.AddHours(-9)) {
            $OfflineLogContent = Get-Content $LocalTempLog -Force
            $FirstLine = $OfflineLogContent | Select-Object -First 1
            Write-Host {"File is $([math]::Round((New-TimeSpan -Start (Get-Item $log).LastWriteTime -End (Get-Date)).TotalHours)) hours old."}
            # Extract time and percentage from the first line
            $LogPercentage = ($FirstLine -split ' ')[4].Trim('%')
            $LogTime = ($FirstLine -split ' ')[1]
            $LogTime2d = [datetime]::ParseExact($LogTime, "HH:mm:ss" ,$null)
            $Logtime24 = $LogTime2d.tostring("HH:mm tt")
            # Check if conditions are met
            if ($LogPercentage -lt 80) {
            Write-Host {"Log percentage less than 80"}
            $FirstLine | Out-File -Append $Log
            Write-Output "On $Day at $LogTime24, $Username first logged into $ComputerName with the battery level at $LogPercentage%" | Out-File -Append $ILog
                
            } 
            else {

            Write-Host {"Log% not less than 80"}
                $OfflineLogContent | Out-File -Append $Log
            }
        }

        Else{"File is $([math]::Round((New-TimeSpan -Start (Get-Item $log).LastWriteTime -End (Get-Date)).TotalHours)) hours old.";$OfflineLogContent | Out-File -Append $Log;WritetoLog}

        Remove-Item $LocalTempLog -Force
       
    }
}

Function CheckLogon {
if ($Username -eq "la" -or $Username -eq "msts" -or $Username -eq "ssts" -or $Username -eq "tst") {
Write-Host "$Username is logged in. Script will exit."
return
}
}

Function MessageStudent {Send-MailMessage -From "$EmailSenderName <$EmailSender@$Domain>" -To "$Name <$Username.student@$Domain>" -Subject "It looks like you didn't fully charge your battery last night!" -Body "Hi $FirstName, `n`nWe noticed you just logged in and your laptop's battery level was $Percentage%`n`nYou must remember to fully charge your laptop every night so it's ready for the next day.`n`nYou will receive a consequence if you keep forgetting to charge your laptop." -SmtpServer "aspmx.l.google.com"}

Function WritetoLog {Write-Output "$Date $ComputerName Battery $Percentage% Charging Status: $Charging" | Out-File -Append $Log}

Function WritetoiLog {Write-Output "On $Day at $Time, $Username first logged into $ComputerName with the battery level at $Percentage%" | Out-File -Append $ILog}

Function WritetoTempLog {Write-Output "$Date $ComputerName Battery $Percentage% Charging Status: $charging $connected" | Out-File -Append $LocalTempLog -Force}

Function LowBatteryHealth {
if ($BatteryHealthPercent -lt 60) {
    Send-MailMessage -From "$EmailSenderName <$EmailSender@$Domain>" -To "$Name <$EmailRecipient@$Domain>" -Subject "$ComputerName used by $Name has a battery health of $BatteryHealthPercent%" -Body "Hi IT, `n`n$ComputerName used by $Name has a battery health of $BatteryHealthPercent% `n`nPlease book the battery in for replacement" -SmtpServer "aspmx.l.google.com"
}}

Function ConnectToNetwork {netsh wlan connect name="Hope-Student-WiFi"}


# Check who's logged on

CheckLogon

Write-Host {"Passed Login Check"}

# Delete Old Temp Logs

if(Test-Path $LocalTempLog){

if((Get-Item $LocalTempLog -Force).LastWriteTime.AddHours(12) -lt $Date) {

 Write-Host "Local file gt 12 hrs old.. Deleting";Remove-Item $LocalTempLog -force}
}

# Check if the day is not Saturday or Sunday and the time is between 9 am and 3 pm

if ($day -ne "Saturday" -and $day -ne "Sunday" -and $Time24 -ge "09:00" -and $Time24 -le "15:30") {
   
    # Execute your script or commands here
    Write-Host "It's a weekday between 9 am and 3 pm."

Write-Host {"Time date Check passed"}
#Check Network Connectivity and try to connect
if ((Test-Path $logpath) -eq $false) {Write-Host {"network Check"}; ConnectToNetwork ; Start-Sleep 30 }
#If no Network Connectivity write to Temp Log
if ((Test-Path $logpath) -eq $false) {Write-Host {" WritetoTempLog"}; WritetoTempLog }



if ((Test-Path $logpath) -and ((Test-Path $LocalTempLog) -eq $false)) {

#check Battery Health
LowBatteryHealth
 
if ((Get-Item $Log).LastWriteTime.AddHours(9) -lt $Date -and ($Percentage -lt 80)) {writetolog;writetoilog;MessageStudent}
else {writetolog}
}

if ((Test-Path $logpath) -and (Test-Path $LocalTempLog)){AppendOfflineUpdatesToNetworkLog}
}

else {
    Write-Host "It's not a weekday between 9 am and 3 pm."
}

if(Test-Path $LocalTempLog){Set-ItemProperty -Path $LocalTempLog -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -force}