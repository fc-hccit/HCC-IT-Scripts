$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6BBAE539-2232-434A-A4E5-9A33560C6283}'
$string = (Get-ItemProperty -Path $key -Name UninstallString).UninstallString
.$string /uninstall

