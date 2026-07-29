@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

>nul 2>&1 fltmc || (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs" 
    exit /b
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
