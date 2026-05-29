@echo off
REM 设置控制台代码页为 UTF-8
chcp 65001 >nul

REM 可选：切换当前目录到批处理所在目录
cd /d "%~dp0"

echo 当前目录: %cd%
echo.

if not exist "Setup-Old-ClaudeCode.ps1" (
    echo 错误: 找不到 Setup-Old-ClaudeCode.ps1
    pause
    exit /b 1
)

REM 使用 -NoProfile 避免干扰，但明确指定输入输出编码为 UTF-8
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '.\Setup-Old-ClaudeCode.ps1'"

echo 脚本退出码: %errorlevel%
pause