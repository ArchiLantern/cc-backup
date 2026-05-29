@echo off
echo Current directory: %cd%
echo Batch file directory: %~dp0
echo.

cd /d "%~dp0"
echo Switched to: %cd%
echo.

if not exist "cc-install.ps1" (
    echo ERROR: cc-install.ps1 not found!
    pause
    exit /b 1
)

powershell -File "cc-install.ps1" -NoProfile -ExecutionPolicy Bypass
echo Exit code: %errorlevel%
pause