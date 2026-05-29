@echo off
echo Current directory: %cd%
echo Batch file directory: %~dp0
echo.

cd /d "%~dp0"
echo Switched to: %cd%
echo.

@REM 1. the zh_Encoding Bug
if not exist "node-install-zh_Encoding_Bug.ps1" (
    echo ERROR: node-install-zh_Encoding_Bug.ps1 not found!
    pause
    exit /b 1
)

powershell -File "node-install-zh_Encoding_Bug.ps1" -NoProfile -ExecutionPolicy Bypass
echo Exit code: %errorlevel%
echo ==================================== 
echo. 

@REM 2. the Write-Output Bug
if not exist "check-currentNode-test.ps1" (
    echo ERROR: check-currentNode-test.ps1 not found!
    pause
    exit /b 1
)

powershell -File "check-currentNode-test.ps1" -NoProfile -ExecutionPolicy Bypass
echo Exit code: %errorlevel%
echo ==================================== 
echo. 

@REM 3. the Next Bug is coming, maybe...
if not exist "node-install_0.ps1" (
    echo ERROR: node-install_0.ps1 not found!
    pause
    exit /b 1
)

powershell -File "node-install_0.ps1" -NoProfile -ExecutionPolicy Bypass
echo Exit code: %errorlevel%
echo ==================================== 
echo. 

pause