$wshell = New-Object -ComObject Wscript.Shell
$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6BBAE539-2232-434A-A4E5-9A33560C6283}'
$string = (Get-ItemProperty -Path $key -Name InstallLocation).InstallLocation

    Start-Sleep -Seconds 30

if ($Null -eq (get-process "GoogleDriveFS" -ea SilentlyContinue)){
        
      $null = $wshell.Popup("  Your Google Drive isn't running!`n`n  Let's start it now.",10,"Oops!",48+4096)

      #Start GFS
      .$string
        
      
}

elseif (!(Test-Path -Path "G:\My Drive")) {
       
    $null = $wshell.Popup("  You are not signed in to your Google Drive",10,"Oops!",48+4096)
    
    #Kill GFS 
    Stop-Process -Name "GoogleDriveFS" -Force
    #Start GFS
    .$string
            
    }    