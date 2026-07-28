@echo off

REM Run PowerShell script to add VPN connection and route
powershell -ExecutionPolicy Bypass -File "G:\Shared drives\ICT\ICT Scripts\Join VPN\Join VPN New.ps1"

REM Run Command Prompt command to add route
cmd.exe /c netsh interface ipv4 add route 192.168.0.0/22 "Hope Christian College"
