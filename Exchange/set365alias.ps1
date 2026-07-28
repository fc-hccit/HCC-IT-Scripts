 Connect-ExchangeOnline -UserPrincipalName "nathan.dawson@hopecc.sa.edu.au" 
 
 Set-UnifiedGroup –Identity "HCC.PE@ccmschools.onmicrosoft.com" –EmailAddresses @{Add="pestaff@hopecc.sa.edu.au"}