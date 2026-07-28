#---------------------------------------------------------------------
#
# Script to Re-join student to Hope-Student-WiFi if SSID is available
#
# Created by Nathan Dawson
#
#---------------------------------------------------------------------

#Variable List

$StudentWiFi = '*Hope-Student-WiFi*'
$off = '*The wireless local area network interface is powered down*'
$unkey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
$LastLoggedOnUser = (Get-ItemProperty -Path $unkey -Name LastLoggedOnUser).LastLoggedOnUser
$usernamesplit = $LastLoggedOnUser.split("\") 
$username = $usernamesplit[1]
$devicename = $env:ComputerName

#Start Script

# Turn Off Metered Connections

# Define the old and new values
$oldValue = [byte[]] (0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00)
$newValue = [byte[]] (0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x00)

# Get all network interfaces
$interfacesPath = "HKLM:\SOFTWARE\Microsoft\WlanSvc\Interfaces"
$interfaces = Get-ChildItem -Path $interfacesPath

foreach ($interface in $interfaces) {
    # Get all profiles for the current interface
    $profilesPath = "$interfacesPath\$($interface.PSChildName)\Profiles"
    $profiles = Get-ChildItem -Path $profilesPath
    
    foreach ($profile in $profiles) {
        $metaDataPath = "$profilesPath\$($profile.PSChildName)\MetaData"
        
        # Get the current value of "User Cost"
        $currentValue = Get-ItemProperty -Path $metaDataPath -Name "User Cost" -ErrorAction SilentlyContinue
        
        if ($currentValue."User Cost" -eq $oldValue) {
            # Update the value to the new one
            Set-ItemProperty -Path $metaDataPath -Name "User Cost" -Value $newValue
            Write-Host "Updated 'User Cost' for $metaDataPath"
	        Send-MailMessage -From "ACM Alert <alerts@hopecc.sa.edu.au>" -To "itstaff@hopecc.sa.edu.au" -Subject "Metered Connection Has been Disabled on $username's $devicename" -SmtpServer "aspmx.l.google.com" -ErrorAction SilentlyContinue}	
        }
    }

while($true)

{

Write-Host "Checking if wireless is switched on"

$Network = netsh wlan show network mode=ssid

if ($Network -like $off) 

{

Write-Host "Terminating Applications"

Stop-Process -Name chrome -Force
Stop-Process -Name MicrosoftEdge -Force
Stop-Process -Name iexplore -force
Stop-Process -Name Video.UI -force
Stop-Process -Name wmplayer -force
Stop-Process -Name vlc -force
Stop-Process -Name Microsoft.Photos -force

Start-Sleep -Seconds 5

}

else

{

Write-Host "Checking Available SSID's for Student WiFi"

$Network = netsh wlan show network mode=ssid

if ($Network -like $StudentWiFi) 

{

Write-Output 'Student WiFi Available'

$SSID = netsh wlan show interfaces | select-string SSID

if ($SSID -like $StudentWiFi) 

{

Write-Output 'Already Connected To Student WiFi'

}

else 

{

netsh wlan connect name="Hope-Student-WiFi"

}

Start-Sleep -Seconds 30

}

else

{
 
Write-Output 'Student WiFi is not accessible'

Start-Sleep -Seconds 30

}

}

}