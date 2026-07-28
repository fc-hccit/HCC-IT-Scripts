gam print users query "orgUnitPath='/Staff/TRT Staff'" | gam csv - gam update user ~primaryEmail suspended on
Get-ADUser -Filter * -SearchBase "OU=TRT,OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au" | Disable-ADAccount

