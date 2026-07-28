$tempDir = "C:\Temp"
If (-NOT (Test-Path $tempDir)) {
    New-Item $tempDir -ItemType Directory -Force
}

Start-Transcript -Path "$tempDir\device_rename.txt" -Verbose

$namePrefix = "HCC-STA-"
$serialNumber = Get-WmiObject win32_bios | Select-Object -ExpandProperty "Serialnumber"
$currentName = (Get-CimInstance -ClassName Win32_ComputerSystem).Name
Try {
    If ($serialNumber.Length -le 7) {
        $newName = ($namePrefix) + ($serialNumber)
        If ($currentName -ne $newName) { Rename-Computer -NewName $newName }
    } else {
        $newName = ($namePrefix) + ($serialNumber.SubString($serialNumber.Length - 7, 7))
        If ($currentName -ne $newName) { Rename-Computer -NewName $newName }
    }
} Catch {
    Write-Output $_
}

#Grab the action script
Invoke-WebRequest -Uri "https://ccmschools.blob.core.windows.net/ccmpublicfiles/CCMCO/Restart-ComputerPostESP.ps1" -OutFile "$tempDir\Restart-ComputerPostESP.ps1"

#Grab the ScheduledTask XML
Invoke-WebRequest -Uri "https://ccmschools.blob.core.windows.net/ccmpublicfiles/CCMCO/Post-ESP-Reboot.xml" -OutFile "$env:TEMP\Post-ESP-Reboot.xml"

Register-ScheduledTask -xml (Get-Content -Path "$env:TEMP\Post-ESP-Reboot.xml" | Out-String) -TaskName "Post-ESP-Reboot" -Force