function openchrome {

$url1 = "https://www.hopecc.sa.edu.au/"
$url2 = "https://www.2goschools.com"
$url3 = "https://www.google.com/intl/en-GB/gmail/about/"

[System.Diagnostics.Process]::Start("chrome.exe","--incognito $url1 $url2 $url3")

}

openchrome

while ($true){

Start-Sleep 1800

$a = new-object -comobject wscript.shell
$b = $a.popup("Your session is about to time out. Do you wish to continue?",30,"Session Expiring in 30 Seconds",0+4096)
$b
if ($b -eq -1){

stop-Process -name chrome
openchrome

}
}