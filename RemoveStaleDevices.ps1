 
$1year = (Get-Date).AddDays(-365) # The 365 is the number of days from today since the last logon. 
$1y1m = (Get-Date).AddDays(-395) 
 
# Disable computer objects and move to disabled OU (Older than 1 year): 
Get-ADComputer {OperatingSystem -notLike '*SERVER*' } -Property Name,lastLogonDate -Filter lastLogonDate -lt $1year -SearchBase "OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au" | Set-ADComputer -Enabled $false -WhatIf
Get-ADComputer -Property Name,Enabled -Filter {Enabled -eq $False} | Move-ADObject -TargetPath "OU=Stale Devices,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au" -WhatIf
pause
