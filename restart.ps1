$Old = Read-Host -Prompt 'Input Old Computer Name'
$Credentials = Get-Credential hopecc\dcadmin
Restart-Computer -ComputerName $Old -Credential $Credentials -Force -Confirm:$false
Restart-Computer -ComputerName $Old -Credential $Credentials -Force -Confirm:$false
Restart-Computer -ComputerName $Old -Credential $Credentials -Force -Confirm:$false
Restart-Computer -ComputerName $Old -Credential $Credentials -Force -Confirm:$false
Restart-Computer -ComputerName $Old -Credential $Credentials -Force -Confirm:$false



