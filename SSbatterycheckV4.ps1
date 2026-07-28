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

#Get First Login Precentage After 9:00am from Battery Report Log

Function Generate-batteryreport{
# Define the Battery report path

$batteryreport = "C:\Users\Public\Documents\battery-report.html"

# Generate the Battery report

start-process "C:\Windows\System32\powercfg.exe" -ArgumentList "/batteryreport /output $batteryreport" -WindowStyle Hidden

start-sleep 5

if (!(Test-Path $batteryreport)){write-host "No report file generated"} 

else {
# Read the content of the HTML file
$htmlContent = Get-Content -Path $batteryreport -Raw

# Define the start and end markers
$startMarker1 = "Power states over the last 3 days"
$endMarker1 = "Battery drains over the last 3 days"

# Extract content between the markers
$startIndex = $htmlContent.IndexOf($startMarker1)
$endIndex = $htmlContent.IndexOf($endMarker1)

if ($startIndex -ne -1 -and $endIndex -ne -1 -and $startIndex -lt $endIndex) {
    $extractedContent = $htmlContent.Substring($startIndex + $startMarker1.Length, $endIndex - ($startIndex + $startMarker1.Length))
    
    # Remove HTML tags using a simple regex
    $cleanedContent = $extractedContent -replace '<[^>]+>', ''

    # Filter and format content
    $filteredContentArray = $cleanedContent -split "`r`n" | ForEach-Object {
        $_.Trim() # Trim leading and trailing whitespace
    } | Where-Object {
        $_ -notmatch "mWh" -and
        $_ -notmatch "Report generated" -and
        $_ -notmatch "Battery" -and
        $_ -notmatch "Active" -and
        $_ -notmatch "suspended" -and
        $_ -notmatch "Connected standby" -and
        $_ -notmatch "START TIME" -and
        $_ -notmatch "STATE" -and
        $_ -notmatch "AC" -and
        $_ -notmatch "SOURCE" -and
        $_ -notmatch "CAPACITY REMAINING"
    } | Where-Object { $_ -ne "" }  # Remove blank lines

    # Initialize an array to store processed items
    $processedArray = @()

    # Process each line
    foreach ($line in $filteredContentArray) {
        # Remove all spaces from each item
        $line = $line -replace '\s+', '' # Replace all whitespace characters

        # Check for merged date and time
        if ($line -match '^(\d{4}-\d{2}-\d{2})(\d{2}:\d{2}:\d{2})$') {
            # Extract date and time
            $date = $matches[1]
            $time = $matches[2]

            # Add date and time as separate items to the processed array
            $processedArray += $date
            $processedArray += $time
        } elseif ($line -match '^\d{2}:\d{2}:\d{2}$') {
            # Add time entries as separate items
            $processedArray += $line
        } elseif ($line -match '^\d+%$') {
            # Add percentage entries as separate items
            $processedArray += $line
        }
    }

  
}}

# Define a function to check if a time is after 9 AM
function Is-AfterNineAM {
    param (
        [string]$time
    )
    return [datetime]::ParseExact($time, "HH:mm:ss", $null).TimeOfDay -gt [timespan]::Parse("08:59:59")
}

# Define the date to search for
$searchDate = (Get-Date).ToString("yyyy-MM-dd")

# Initialize variables
$reportDate = $null
$reportTime = $null
$global:reportPercentage = $null
$found = $false

for ($i = 0; $i -lt $processedArray.Count -and -not $found; $i++) {
    if ($processedArray[$i] -match '^\d{4}-\d{2}-\d{2}$') {
        # Date entry
        $reportDate = $processedArray[$i]
        $reportTime = $null # Reset time when a new date is encountered
    } elseif ($processedArray[$i] -match '^\d{2}:\d{2}:\d{2}$') {
        # Time entry
        if ($reportDate -eq $searchDate -and (Is-AfterNineAM -time $processedArray[$i])) {
            $reportTime = $processedArray[$i]
        }
    } elseif ($processedArray[$i] -match '^\d+%$') {
        # Percentage entry
        if ($reportDate -eq $searchDate -and $reportTime) {
            # Output the first found result
            Write-Output "Date: $reportDate"
            Write-Output "Time: $reportTime"
            $reportTime = [datetime]::ParseExact($reportTime, 'HH:mm:ss', $null).ToString('hh:mm tt')
            $reportPercentage = "$($processedArray[$i])"
            Write-Output "percentage: $reportPercentage"
            $found = $true 
            Remove-Item $batteryreport
        }
    }
}

if (-not $found) {
    Write-Output "No matching data found for date $searchDate."
    Remove-Item $batteryreport
}

if ($found) {$global:found = $true; $global:reportDate = $reportDate ; $global:reportTime = $reportTime; $global:reportPercentage= $reportPercentage}

}


# Function to check who’s logged on
Function CheckLogon {
    Write-HostLog "Checking current user: $Username"
    if ($Username -eq "la" -or $Username -eq "msts" -or $Username -eq "ssts" -or $Username -eq "tst") {
        Write-HostLog "$Username is logged in. Script will exit."
        return
    } else {
        Write-HostLog "User $Username is not a test user, Continuing script."
    }
}

# Function to send message to the student
Function MessageStudent79-50 {
    Write-HostLog "Sending slightly low battery email to student $Username."
    Send-MailMessage -From "$EmailSenderName <$EmailSender@$Domain>" -To "$Name <$Username.student@$Domain>" -Subject "$Firstname, $global:reportPercentage`? Your Laptop’s Feeling Half Awake!" -Body "Hey $FirstName, `n`nYour laptop just logged in, and it's at $global:reportPercentage. It's kinda like showing up to school in your PJs - functional, but not quite ready for the day!`n`nDon't forget to plug it in every night! We need your tech to be fully charged, just like you after a good night's sleep (or at least a solid breakfast)!`n`nIf you keep forgetting to charge it, you'll be spending some quality time with us at lunchtime. Trust me, it's not the kind of hangout you want to be at!`n`nSave your battery - and your lunch break!" -SmtpServer "aspmx.l.google.com"
}

Function MessageStudent49-1 {
    Write-HostLog "Sending very low battery email to student $Username."
    Send-MailMessage -From "$EmailSenderName <$EmailSender@$Domain>" -To "$Name <$Username.student@$Domain>" -Subject "$Firstname, Your Laptop's Running on Empty! ($Global:reportPercentage`? Really?!)" -Body "Hey $FirstName, `n`nYour laptop just rolled into school running on $global:reportPercentage... It's basically one click away from a nap.`n`nDon't forget to plug it in every night! We need your tech to be fully charged, just like you after a good night's sleep (or at least a solid breakfast)!`n`nIf you keep forgetting to charge it, you'll be spending some quality time with us at lunchtime. Trust me, it's not the kind of hangout you want to be at!`n`nSave your battery - and your lunch!" -SmtpServer "aspmx.l.google.com"
}

# Function to write to the main log
Function WritetoLog {
    Write-HostLog "Writing battery status to log. Battery Percentage: $Percentage%, Charging: $Charging."
    Write-Output "$Date $ComputerName Battery $Percentage% Charging Status: $Charging" | Out-File -Append $Log
}

# Function to write to the infringement log
Function WritetoiLog {

    Write-HostLog "Writing first logon details to infringement log. Username: $Username, Battery: $global:reportPercentage"
    Write-Output "On $Day at $global:reportTime, $Username first logged into $ComputerName with the battery level at $global:reportPercentage" | Out-File -Append $ILog
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

# Check if the day is a weekday and the time is between 9 am and 3:30 pm
if ($day -ne "Saturday" -and $day -ne "Sunday" -and $Time24 -ge "09:00" -and $Time24 -le "15:30") {
    Write-HostLog "It's $Time24 on $day."
    Write-HostLog "It's a weekday between 9 am and 3:30 pm so the script may continue"

    # Check network connectivity
    if ((Test-Path $logpath) -eq $false) {
        Write-HostLog "Network not accessible. Attempting to connect."
        ConnectToNetwork
    }

    
    # If online  write directly to log
    if (Test-Path $logpath){
        Write-HostLog "Network is accessible. Checking battery health."
        LowBatteryHealth
        Write-HostLog "Generating and Analysing Battery Report."
        
      if((Get-Item $Log).LastWriteTime.AddHours(9) -lt $Date) {Generate-batteryreport}
      else { "Log file has been written to today so Battery Report not needed."}
      
      if($global:found -eq $True){ Write-HostLog "Report Details Found" 

           if((Get-Item $Log).LastWriteTime.AddHours(9) -lt $Date -and ($global:reportPercentage -lt 49)) {
            Write-HostLog "According to Battery Report Battery level was $global:reportPercentage at $global:reportTime which is less than the required 80%. Writing to logs and notifying student."
            WritetoLog
            WritetoiLog
            MessageStudent49-1
        } 
           elseif((Get-Item $Log).LastWriteTime.AddHours(9) -lt $Date -and ($global:reportPercentage -lt 80)) {
            Write-HostLog "According to Battery Report Battery level was $global:reportPercentage at $global:reportTime which is less than the required 80%. Writing to logs and notifying student."
            WritetoLog
            WritetoiLog
            MessageStudent79-50
        } 
        
           elseif((Get-Item $Log).LastWriteTime.AddHours(9) -lt $Date -and ($global:reportPercentage -gt 80)) {
            Write-HostLog "Battery level is $global:reportPercentage which is at least the required 80%. Only writing to log."
            WritetoLog 
        }

            else{
             Write-HostLog "Battery level is $Percent% and log file has been written to today. Only writing to log."
             WritetoLog
        }
        }
        
      else {
            Write-HostLog "Report Details not Found."
            }
    }
} 

else {
    Write-HostLog "It's $Time24 on $day."
    Write-HostLog "It's not a weekday between 9 am and 3:30 pm. Script will exit."
}
 
