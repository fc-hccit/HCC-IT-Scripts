$Log = "\\hopecc.sa.edu.au\source\Files\ACM log\ACM check.log"
$computers = (Get-ADComputer -Filter {Enabled -eq $TRUE} -SearchBase "OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au").Name

ForEach($computer in $computers) {

if(test-path "\\$computer\c$"){ 
Invoke-Command -Computer $computer {

$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"

$key = Get-Item -Path $Path
$llou = $key.GetValue('LastLoggedOnUser')

$acm = 'HKLM:\SOFTWARE\Policies\NetSupport\Client\Standard'
$string = (Get-ItemProperty -Path $acm -Name RoomSpec).RoomSpec

Write-Output $computer $llou $string | Out-File -Append $Log

}
}
Else{Write-Output "$computer offline!" | Out-File -Append $Log}
}
