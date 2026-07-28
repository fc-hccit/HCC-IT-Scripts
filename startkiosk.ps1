Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoRestartShell -Value 0 -ErrorAction SilentlyContinue
Stop-Process -ProcessName explorer -Force
$ProcessActive = Get-Process checkin -ErrorAction SilentlyContinue
while($true){
$ProcessActive = Get-Process checkin -ErrorAction SilentlyContinue
start-sleep 5
if($ProcessActive -eq $null){."c:\kiosk\checkin.exe";start-sleep 5}}
