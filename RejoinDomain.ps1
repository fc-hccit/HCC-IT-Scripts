$Computer = Read-Host -Prompt 'Input Computer Name'
Test-Connection -Computername $Computer
$Credentials = Get-Credential $Computer\la
Remove-Computer -ComputerName $Computer -Credential $Credentials -passthru -verbose
pause