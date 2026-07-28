While ($True){
$Old = Read-Host -Prompt 'Enter Name of Computer to be Renamed'
$test = Test-Connection -ComputerName $Old -count 2 -quiet
if ($test -eq $true) { Write-Host 'Computer is Online' -ForegroundColor Green
$New = Read-Host -Prompt 'Input New Computer name'
$Credentials = Get-Credential hopecc\dcadmin
Rename-Computer -ComputerName $Old -NewName $New -DomainCredential $Credentials -Force -PassThru
Write-Warning "Set Computer to Restart in 30 min?" -WarningAction Inquire 
cmd.exe /c shutdown /m \\$Old /r /f /c “The computer will restart, please save all work.” /t 1900
Start-Sleep -s 3
}
else { Write-Host 'Computer is Offline' -ForegroundColor Red
Start-Sleep -s 3
}
}