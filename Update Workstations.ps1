$NewWorkstation = "AVZ4860-MUS01,AVZ4860-MUS02,AVZ4860-MUS03,AVZ4860-MUS04,AVZ4860-MUS05,AVZ4860-MUS06,AVZ4860-MUS07,AVZ4860-MUS08,AVZ4860-MUS09,AVZ4860-MUS10,AVZ4860-MUS11,AVZ4860-MUS12,AVZ4860-MUS13,AVZ4860-MUS14,AVZ4860-MUS15"
 
$users = Get-ADUser -SearchBase "OU=Year 10,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -filter *
 
ForEach($user in $users)    {    

$LogonWorkstations = Get-AdUser -Identity $user -Properties LogonWorkstations | select -ExpandProperty LogonWorkstations #get current computernames that user can access

if ($LogonWorkstations) {
    Set-ADUser -Identity $User -LogonWorkstations "$LogonWorkstations,$NewWorkstation" -verbose #add new workstation to existing entries
}
else { 
    Set-ADUser -Identity $User -LogonWorkstations $NewWorkstation -verbose #only add new workstation
}
}  