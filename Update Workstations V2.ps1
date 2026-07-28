$NewWorkstation = "AVZ4860-MUS01","AVZ4860-MUS02","AVZ4860-MUS03","AVZ4860-MUS04","AVZ4860-MUS05","AVZ4860-MUS06","AVZ4860-MUS07","AVZ4860-MUS08","AVZ4860-MUS09","AVZ4860-MUS10","AVZ4860-MUS11","AVZ4860-MUS12","AVZ4860-MUS13","AVZ4860-MUS14","AVZ4860-MUS15"

$users = Get-ADUser -SearchBase "OU=Year 12,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -filter *

ForEach ($user in $users) {    
    $LogonWorkstations = Get-ADUser -Identity $user -Properties LogonWorkstations | select -ExpandProperty LogonWorkstations #get current computernames that user can access

    if ($LogonWorkstations) {
        $existingWorkstations = $LogonWorkstations -split ',' | Where-Object {$_ -notlike "HCCLOAN*" -and $_ -notlike "ACERL4620*" -and $_ -notlike "HCC-D*"} | ForEach-Object { $_.Trim() } | Select-Object -Unique
        $NewLogonWorkstations = $existingWorkstations + ($NewWorkstation | Where-Object { $existingWorkstations -notcontains $_ }) #add new workstations that are not already in the list
        Set-ADUser -Identity $User -LogonWorkstations ($NewLogonWorkstations -join ',') -verbose #set the new list of workstations
    }
    else { 
        Set-ADUser -Identity $User -LogonWorkstations $NewWorkstation -verbose #only add new workstations
    }
}
