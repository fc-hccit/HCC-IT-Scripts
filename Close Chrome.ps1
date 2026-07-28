
while ($true){

Start-Sleep 1800

$a = new-object -comobject wscript.shell
$b = $a.popup("Your session is about to time out. Do you wish to continue?",30,"Session Expiring in 30 Seconds",0+4096)
$b
if ($b -eq -1){

stop-Process -name chrome

}
}