$devices = @{
    'Junior Building Ricoh C6000' = '192.168.0.218'
    'Library Ricoh' = '192.168.0.220'
    'Middle School Downstairs Corridor' = '192.168.0.216'
    'Primary Prep Area' = '192.168.0.222'
    'Senior Hub Ricoh' = '192.168.0.221'
    'Upstairs Science Corridor' = '192.168.0.217'
}

$SNMP = New-Object -ComObject olePrn.OleSNMP
$alertSoundPath = 'C:\sounds\toneralert.wav'
$wshell = New-Object -ComObject Wscript.Shell
$soundPlayer = New-Object System.Media.SoundPlayer -ArgumentList $alertSoundPath

while ($true) {
    foreach ($deviceName in $devices.Keys) {
        $ipAddress = $devices[$deviceName]
        $SNMP.Open($ipAddress, 'public', 2, 1000)

        $blackTonerOID = '.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.1'
        $cyanTonerOID = '.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.2'
        $magentaTonerOID = '.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.3'
        $yellowTonerOID = '.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.4'

        $blackTonerValue = $SNMP.Get($blackTonerOID)
        $cyanTonerValue = $SNMP.Get($cyanTonerOID)
        $magentaTonerValue = $SNMP.Get($magentaTonerOID)
        $yellowTonerValue = $SNMP.Get($yellowTonerOID)

        if ($blackTonerValue -eq 0) {
            $soundPlayer.Play()
            $wshell.Popup("Printer: $deviceName`nToner: Black",0,"Toner Empty",48+4096)
        }

        if ($cyanTonerValue -eq 0) {
            $soundPlayer.Play()
            $wshell.Popup("Printer: $deviceName`nToner: Cyan",0,"Toner Empty",48+4096)
        }

        if ($magentaTonerValue -eq 0) {
            $soundPlayer.Play()
            $wshell.Popup("Printer: $deviceName`nToner: Magenta",0,"Toner Empty",48+4096)
        }

        if ($yellowTonerValue -eq 0) {
            $soundPlayer.Play()
            $wshell.Popup("Printer: $deviceName`nToner: Yellow",0,"Toner Empty",48+4096)
        }
    }

    Start-Sleep -Seconds 180
}
