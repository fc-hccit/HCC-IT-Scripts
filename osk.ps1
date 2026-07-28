Start-Process -FilePath C:\Windows\System32\osk.exe
$ProcessActive = Get-Process C:\Windows\System32\osk.exe -ErrorAction SilentlyContinue
while($true){
$ProcessActive = Get-Process C:\Windows\System32\osk.exe -ErrorAction SilentlyContinue
start-sleep 5
if($ProcessActive -eq $null){."C:\Windows\System32\osk.exe";start-sleep 5}}