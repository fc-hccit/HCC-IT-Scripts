@echo off
set /p COMPUTERNAME= Enter the name of computer you would like to access: 
c:\engineer\psexec \\%COMPUTERNAME% C:\PCSLaunch\Programs\Admin.exe -i