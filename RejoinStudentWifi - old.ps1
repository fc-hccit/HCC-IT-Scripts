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

#Start Script

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