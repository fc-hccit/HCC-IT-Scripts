@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

:MENU
cls
echo USB Script Launcher
echo ==================
echo 1. Run a .ps1 file from this USB folder
echo 2. Exit
set /p CHOICE=Choose an option: 

if /I "%CHOICE%"=="1" (
    echo.
    echo Available PowerShell scripts in this folder:
    set "COUNT=0"
    for %%F in ("%SCRIPT_DIR%*.ps1") do (
        set /a COUNT+=1
        echo !COUNT!. %%~nxF
    )
    if !COUNT! EQU 0 (
        echo No PowerShell scripts found.
        pause
        goto MENU
    )
    echo.
    set /p TARGET=Enter the number for the script to run: 
    if not defined TARGET (
        echo No selection entered.
        pause
        goto MENU
    )
    set "SELECTED="
    set "INDEX=0"
    for %%F in ("%SCRIPT_DIR%*.ps1") do (
        set /a INDEX+=1
        if !INDEX! EQU !TARGET! set "SELECTED=%%~fF"
    )
    if not defined SELECTED (
        echo Invalid selection.
        pause
        goto MENU
    )
    powershell -ExecutionPolicy Bypass -File "!SELECTED!"
    goto END
)

if /I "%CHOICE%"=="2" (
    goto END
)

echo Invalid choice.
pause
goto MENU

:END
endlocal
