@echo off
set /p COMPUTERNAME= Enter the name of computer you would like to access: 
echo netsh advfirewall firewall set service remoteadmin enable
c:\engineer\psexec \\%COMPUTERNAME% cmd

pause