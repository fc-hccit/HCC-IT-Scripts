@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%UserProfile Deleter WPF.ps1"

:MENU
cls
echo USB Script Launcher
echo ==================
echo 1. Run User Profile Deleter
echo 2. Run a .ps1 file from this USB folder
echo 3. Exit
set /p CHOICE=Choose an option: 

if /I "%CHOICE%"=="1" (
    powershell -ExecutionPolicy Bypass -File "%PS1_FILE%"
    goto END
)

if /I "%CHOICE%"=="2" (
    echo.
    echo Available PowerShell scripts in this folder:
    dir /b "%SCRIPT_DIR%*.ps1" 2>nul
    echo.
    set /p TARGET=Enter the exact filename to run: 
    if not exist "%SCRIPT_DIR%!TARGET!" (
        echo File not found.
        pause
        goto MENU
    )
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%!TARGET!"
    goto END
)

if /I "%CHOICE%"=="3" (
    goto END
)

echo Invalid choice.
pause
goto MENU

:END
endlocal
