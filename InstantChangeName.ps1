While ($True){
$Old = Read-Host -Prompt 'Enter Name of Computer to be Renamed'
$test = Test-Connection -ComputerName $Old -count 1 -quiet
if ($test -eq $true) { Write-Host 'Computer is Online' -ForegroundColor Green
$New = Read-Host -Prompt 'Input New Computer name'
$Credentials = Get-Credential hopecc\dcadmin
Rename-Computer -ComputerName $Old -NewName $New -DomainCredential $Credentials -Force -PassThru -Restart
Start-Sleep -s 3
}
else { Write-Host 'Computer is Offline' -ForegroundColor Red
Start-Sleep -s 3
}
}