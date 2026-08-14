@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

if /I "%~1"=="--elevated" goto MENU

for /f "delims=" %%I in ('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); [int]$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" 2^>nul') do set "IS_ADMIN=%%I"
for /f "delims=" %%S in ('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$sn = (Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SerialNumber); if ([string]::IsNullOrWhiteSpace($sn)) { $sn = 'Unknown' }; $sn" 2^>nul') do set "SERIAL=%%S"

if /I not "%IS_ADMIN%"=="1" (
    if defined SERIAL (
        echo Requesting administrator privileges for serial: %SERIAL%...
    ) else (
        echo Requesting administrator privileges...
    )
    powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated' -Wait" 
    exit /b %ERRORLEVEL%
)

:MENU
cls
echo USB Script Launcher
echo ==================
echo Available PowerShell scripts in this folder:
echo.
set "COUNT=0"
for %%F in ("%SCRIPT_DIR%*.ps1") do (
    set /a COUNT+=1
    echo !COUNT!. %%~nxF
)
if !COUNT! EQU 0 (
    echo No PowerShell scripts found.
    echo.
echo Press any key to exit...
    pause >nul
    goto END
)
echo.
echo Press the number for the script you want to run.
echo.
choice /C 1234567890 /N /M "Selection: " >nul
set "TARGET=%ERRORLEVEL%"
if not defined TARGET (
    goto END
)
set "SELECTED="
set "INDEX=0"
for %%F in ("%SCRIPT_DIR%*.ps1") do (
    set /a INDEX+=1
    if !INDEX! EQU !TARGET! set "SELECTED=%%~fF"
)
if not defined SELECTED (
    echo Invalid selection.
    echo.
echo Press any key to exit...
    pause >nul
    goto END
)
powershell -ExecutionPolicy Bypass -File "!SELECTED!"

:END
endlocal
