

PS C:\Users\dcadmin.HOPECC> $connector = (get-adsyncconnector | where-object { $_.Name -like "*AAD*"}).Name
PS C:\Users\dcadmin.HOPECC> $connector
ccmschools.onmicrosoft.com - AAD
PS C:\Users\dcadmin.HOPECC> Set-ADSyncAADPasswordResetConfiguration -Connector $Connector -enable:$false
Password Reset Configuration for AAD connector "ccmschools.onmicrosoft.com - AAD" updated.
PS C:\Users\dcadmin.HOPECC> Set-ADSyncAADPasswordResetConfiguration -Connector $Connector -enable:$true
Password Reset Configuration for AAD connector "ccmschools.onmicrosoft.com - AAD" updated.
PS C:\Users\dcadmin.HOPECC>

