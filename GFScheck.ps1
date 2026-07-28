$wshell = New-Object -ComObject Wscript.Shell
$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6BBAE539-2232-434A-A4E5-9A33560C6283}'
$string = (Get-ItemProperty -Path $key -Name InstallLocation).InstallLocation

    Start-Sleep -Seconds 30

While ($Null -eq (get-process "GoogleDriveFS" -ea SilentlyContinue)){
        
      $null = $wshell.Popup("  Your Google Drive isn't running!`n`n  Let's start it now.",10,"Oops!",48+4096)

      #Start GFS
      .$string
        
      Start-Sleep -Seconds 60
}

while (!(Test-Path -Path "G:\My Drive")) {
       
    $null = $wshell.Popup("  Please sign in to your Google Drive",10,"Oops!",48+4096)
    
    #Kill GFS 
    Stop-Process -Name "GoogleDriveFS" -Force
    #Start GFS
    .$string
    #pause
    Start-Sleep -Seconds 120
        
    }    