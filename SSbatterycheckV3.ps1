

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
$LogFile = "C:\Users\Public\Documents\batterylog.log"
$Log = "\\hopecc.sa.edu.au\Source\Files\Battery\Senior School\$Username.log"
$ILog = "\\hopecc.sa.edu.au\Source\Files\Battery\Senior School\Infringements\$Username.log"

# Function to log and append content
Function Log-Output {
    param (
        [string]$Message
    )
    $Message | Out-File -Append -FilePath $LogFile
}

# Redirect Write-Host to Log-Output for debugging
Function Write-HostLog {
    param (
        [string]$Message
    )
    Log-Output $Message
    Write-Host $Message
}

#Write new Line to Local Log

Write-HostLog "******************************************************"
Write-HostLog "`n"
Write-HostLog "******************************************************"

# Function to append updates from offline log file to network log file
Function AppendOfflineUpdatesToNetworkLog {
    Write-HostLog "Checking if local temp log exists..."
    if (Test-Path $LocalTempLog) {
        $NetworkLogLastWriteTime = (Get-Item $Log).LastWriteTime
        $CurrentTime = Get-Date
        Write-HostLog "Local temp log exists. Network log last written at: $NetworkLogLastWriteTime"

        if ($NetworkLogLastWriteTime -lt $CurrentTime.AddHours(-9)) {
            Write-HostLog "Network log is older than 9 hours. Preparing to append offline updates."
            $OfflineLogContent = Get-Content $LocalTempLog -Force
            $FirstLine = $OfflineLogContent | Select-Object -First 1
            Write-HostLog "First line of local temp log: $FirstLine"
            
            $LogPercentage = ($FirstLine -split ' ')[4].Trim('%')
            $LogTime = ($FirstLine -split ' ')[1]
            $LogTime2d = [datetime]::ParseExact($LogTime, "HH:mm:ss", $null)
            $Logtime24 = $LogTime2d.tostring("HH:mm tt")
            
            Write-HostLog "Log percentage: $LogPercentage%, Log time: $Logtime24"

            if ($LogPercentage -lt 80) {
                Write-HostLog "Log percentage is less than 80%. Appending to logs."
                $FirstLine | Out-File -Append $Log
                Write-Output "On $Day at $Logtime24, $Username first logged into $ComputerName with the battery level at $LogPercentage%" | Out-File -Append $ILog
            } else {
                Write-HostLog "Log percentage is not less than 80%. Appending full log."
                $OfflineLogContent | Out-File -Append $Log
            }
        } else {
            Write-HostLog "Network log is not older than 9 hours. Appending offline content."
            $OfflineLogContent | Out-File -Append $Log
        }

        Write-HostLog "Removing local temp log."
        Remove-Item $LocalTempLog -Force
    } else {
        Write-HostLog "No local temp log found."
    }
}

# Function to check who’s logged on
Function CheckLogon {
    Write-HostLog "Checking current user: $Username"
    if ($Username -eq "la" -or $Username -eq "msts" -or $Username -eq "ssts" -or $Username -eq "tst" -or $ComputerName -like "HCCLOAN*") {
        Write-HostLog "$Username is logged in. Script will exit."
        return
    } else {
        Write-HostLog "User $Username is not a test user, Continuing script."
    }
}

# Function to send message to the student
Function MessageStudent {
    Write-HostLog "Sending low battery email to student $Username."
    Send-MailMessage -From "$EmailSenderName <$EmailSender@$Domain>" -To "$Name <$Username.student@$Domain>" -Subject "It looks like you didn't fully charge your battery last night!" -Body "Hi $FirstName, `n`nWe noticed you just logged in and your laptop's battery level was $Percentage%`n`nYou must remember to fully charge your laptop every night so it's ready for the next day.`n`nYou will receive a consequence if you keep forgetting to charge your laptop." -SmtpServer "aspmx.l.google.com"
}

# Function to write to the main log
Function WritetoLog {
    Write-HostLog "Writing battery status to log. Battery Percentage: $Percentage%, Charging: $Charging."
    Write-Output "$Date $ComputerName Battery $Percentage% Charging Status: $Charging" | Out-File -Append $Log
}

# Function to write to the infringement log
Function WritetoiLog {
    Write-HostLog "Writing first logon details to infringement log. Username: $Username, Battery: $Percentage%"
    Write-Output "On $Day at $Time, $Username first logged into $ComputerName with the battery level at $Percentage%" | Out-File -Append $ILog
}

# Function to write to the temp log
Function WritetoTempLog {
    Write-HostLog "Writing battery status to temp log (offline)."
    Write-Output "$Date $ComputerName Battery $Percentage% Charging Status: $charging $connected" | Out-File -Append $LocalTempLog -Force
}

# Function to check battery health and notify IT if necessary
Function LowBatteryHealth {
    Write-HostLog "Checking battery health. Current health: $BatteryHealthPercent%"
    if ($BatteryHealthPercent -lt 60) {
        Write-HostLog "Battery health is below 60%. Sending email to IT."
        Send-MailMessage -From "$EmailSenderName <$EmailSender@$Domain>" -To "$EmailRecipient@$Domain" -Subject "$ComputerName used by $Name has a battery health of $BatteryHealthPercent%" -Body "Hi IT, `n`n$ComputerName used by $Name has a battery health of $BatteryHealthPercent% `n`nPlease book the battery in for replacement" -SmtpServer "aspmx.l.google.com"
    } else {
        Write-HostLog "Battery health is above 60%. No email sent."
    }
}

# Function to connect to the network
Function ConnectToNetwork {
    Write-HostLog "Attempting to connect to Hope-Student-WiFi."
    netsh wlan connect name="Hope-Student-WiFi"
    Start-Sleep 30
}

# Check who's logged on
CheckLogon

# Delete old temp logs
if (Test-Path $LocalTempLog) {
    if ((Get-Item $LocalTempLog -Force).LastWriteTime.AddHours(12) -lt $Date) {
        Write-HostLog "Local temp log is older than 12 hours. Deleting."
        Remove-Item $LocalTempLog -Force
    } else {
        Write-HostLog "Local temp log is not older than 12 hours."
    }
} else {
    Write-HostLog "No local temp log found."
}

# Check if the day is a weekday and the time is between 9 am and 3:30 pm
if ($day -ne "Saturday" -and $day -ne "Sunday" -and $Time24 -ge "09:00" -and $Time24 -le "15:30") {
    Write-HostLog "It's $Time24 on $day."
    Write-HostLog "It's a weekday between 9 am and 3:30 pm so the script may continue"

    # Check network connectivity
    if ((Test-Path $logpath) -eq $false) {
        Write-HostLog "Network not accessible. Attempting to connect."
        ConnectToNetwork
    }

    # If still offline, write to temp log
    if ((Test-Path $logpath) -eq $false) {
        Write-HostLog "Still offline. Writing to temp log."
        WritetoTempLog
    }

    # If online and no temp log, write directly to log
    if ((Test-Path $logpath) -and ((Test-Path $LocalTempLog) -eq $false)) {
        Write-HostLog "Network is accessible. Checking battery health."
        LowBatteryHealth

        if ((Get-Item $Log).LastWriteTime.AddHours(9) -lt $Date -and ($Percentage -lt 80)) {
            Write-HostLog "Battery level is $Percentage% which is less than the required 80%. Writing to logs and notifying student."
            WritetoLog
            WritetoiLog
            MessageStudent
        } 
        elseif ((Get-Item $Log).LastWriteTime.AddHours(9) -lt $Date -and ($Percentage -ge 80)) {
            Write-HostLog "Battery level is $Percentage% which is at least the required 80%. Only writing to log."
            WritetoLog 
        }
        
        else {
            Write-HostLog "Battery level is $Percentage% and log file has been written to today. Only writing to log."
            WritetoLog
        }
    }

    # If online and temp log exists, append offline updates
    if ((Test-Path $logpath) -and (Test-Path $LocalTempLog)) {
        Write-HostLog "Temp log found. Appending offline updates to network log."
        AppendOfflineUpdatesToNetworkLog
    }
} else {
    Write-HostLog "It's $Time24 on $day."
    Write-HostLog "It's not a weekday between 9 am and 3:30 pm. Script will exit."
}

# Hide local temp log if it exists
if (Test-Path $LocalTempLog) {
    Write-HostLog "Hiding local temp log."
    Set-ItemProperty -Path $LocalTempLog -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -Force} 
