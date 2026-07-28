$devices = @{
    'Junior Building Ricoh C6000' = '192.168.0.218'
    'Library Ricoh' = '192.168.0.220'
    'Middle School Downstairs Corridor' = '192.168.0.216'
    'Primary Prep Area' = '192.168.0.222'
    'Senior Hub Ricoh' = '192.168.0.221'
    'Upstairs Science Corridor' = '192.168.0.223'
    'Junior Building Downstairs' = '192.168.0.224'
}

$SNMP = New-Object -ComObject olePrn.OleSNMP
$alertSoundPath = 'C:\sounds\toneralert.wav'
$wshell = New-Object -ComObject Wscript.Shell
$soundPlayer = New-Object System.Media.SoundPlayer -ArgumentList $alertSoundPath

$previousTonerState = @{}
$previousDeviceState = @{} 

while ($true) {

$currentTime = Get-Date
$startTime = Get-Date -Hour 8 -Minute 0 -Second 0
$endTime = Get-Date -Hour 16 -Minute 30 -Second 0

if ($currentTime -ge $startTime -and $currentTime -le $endTime) {

     foreach ($deviceName in $devices.Keys) {
        $ipAddress = $devices[$deviceName]
        $SNMP.Open($ipAddress, 'public', 2, 1000)

        $blackTonerOID = '.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.1'
        $cyanTonerOID = '.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.2'
        $magentaTonerOID = '.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.3'
        $yellowTonerOID = '.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.4'

        if (!(Test-Connection -ComputerName $ipAddress -Count 1 -Quiet)) {
        
        if($previousDeviceState[$deviceName] -notlike "Offline"){$response = $wshell.Popup("$deviceName is offline", 5, "Device Offline", 48+4096)}
        
        if($response -eq 1) {$previousDeviceState[$deviceName] = "Offline"}

        }

        else{

            $previousDeviceState[$deviceName] = "Online"

            $blackTonerValue = $SNMP.Get($blackTonerOID)
            $cyanTonerValue = $SNMP.Get($cyanTonerOID)
            $magentaTonerValue = $SNMP.Get($magentaTonerOID)
            $yellowTonerValue = $SNMP.Get($yellowTonerOID)
       

        if ($blackTonerValue -eq 0) {
            if ($previousTonerState[$deviceName] -ne 0) {
                $soundPlayer.Play()
                $response = $wshell.Popup("Printer: $deviceName`nToner: Black", 5, "Toner Empty", 48+4096)
                if($response -eq 1){$previousTonerState[$deviceName] = $blackTonerValue}
            }
        }
        if ($cyanTonerValue -eq 0) {
            if ($previousTonerState[$deviceName] -ne 0) {
                $soundPlayer.Play()
                $response = $wshell.Popup("Printer: $deviceName`nToner: Cyan", 5, "Toner Empty", 48+4096)
                if($response -eq 1){$previousTonerState[$deviceName] = $cyanTonerValue}
            }
        }
        if ($magentaTonerValue -eq 0) {
            if ($previousTonerState[$deviceName] -ne 0) {
                $soundPlayer.Play()
                $response = $wshell.Popup("Printer: $deviceName`nToner: Magenta", 5, "Toner Empty", 48+4096)
                if($response -eq 1){$previousTonerState[$deviceName] = $magentaTonerValue}
            }
        }
        if ($yellowTonerValue -eq 0) {
            if ($previousTonerState[$deviceName] -ne 0) {
                $soundPlayer.Play()
                $response = $wshell.Popup("Printer: $deviceName`nToner: Yellow", 5, "Toner Empty", 48+4096)
                if($response -eq 1){$previousTonerState[$deviceName] = $yellowTonerValue}
            }
        }
        

}}
    
    Write-Host "Checking Toner Status..."
    
    Start-Sleep -Seconds 5
}
else {Write-Host "Outside of the specified time range." ; Start-Sleep -Seconds 300}
} 






   
