@echo off
setlocal
REM Windows Batch Wrapper for Argo CD Root Application
REM Runs the PowerShell script with ExecutionPolicy Bypass for full UTF-8 and color support

where powershell.exe >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell not found. Please verify your Windows environment.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-root-app-windows.ps1" %*
set "EXIT_CODE=%errorlevel%"

endlocal & exit /b %EXIT_CODE%
