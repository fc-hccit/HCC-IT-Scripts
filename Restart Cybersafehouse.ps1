if(Get-Service CyberSafehouse -ErrorAction SilentlyContinue){

Restart-Service -Name CyberSafehouse -Force -verbose | Out-File C:\Windows\hccache\RestartCyberSafehouse.log

Get-Date -Format "dd-MM-yyyy hh.mm" | Out-File C:\Windows\hccache\RestartCyberSafehouse.log -Append
}