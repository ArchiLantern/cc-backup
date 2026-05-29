<#
.SYNOPSIS
    Claude Code One-Click Installation and Configuration Script
.DESCRIPTION
    Automatically completes Node.js version detection, Claude Code installation, environment variable configuration, and region restriction bypass
.NOTES
    Administrator privileges required for certain steps
#>

# ---------- 设置中文显示 ----------
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    Claude Code Installation Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Check Administrator Privileges
# ============================================
Write-Host "Checking administrator privileges..." -ForegroundColor Yellow

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "ERROR: Administrator privileges required to modify system PATH" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as administrator'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Administrator privileges confirmed." -ForegroundColor Green
Write-Host ""

# ============================================
# Step 1: Check Node.js Version
# ============================================
Write-Host "[1/6] Checking Node.js environment..." -ForegroundColor Yellow

try {
    $nodeVersion = & node -v 2>&1
    if (-not $nodeVersion -or $nodeVersion -match "not recognized") {
        throw "Node not found"
    }
    $nodeVersion = $nodeVersion.ToString().Trim()
}
catch {
    Write-Host "ERROR: Node.js not detected. Please install Node.js v18 or higher." -ForegroundColor Red
    Write-Host "Download: https://nodejs.org/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

try {
    $nodeMajorVersion = [int]($nodeVersion -replace 'v', '' -split '\.')[0]
    if ($nodeMajorVersion -lt 18) {
        Write-Host "ERROR: Current Node.js version is $nodeVersion, v18 or higher required" -ForegroundColor Red
        Write-Host "Please upgrade Node.js: https://nodejs.org/" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}
catch {
    Write-Host "Warning: Unable to parse Node.js version: $nodeVersion" -ForegroundColor Yellow
    Write-Host "Assuming version meets requirements, continuing..." -ForegroundColor Cyan
    $nodeMajorVersion = 18
}

Write-Host "Node.js version detected: $nodeVersion" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 2: Install Claude Code
# ============================================
Write-Host "[2/6] Installing Claude Code..." -ForegroundColor Yellow

$claudeInstalled = $null
try {
    $claudeInstalled = Get-Command claude -ErrorAction SilentlyContinue
}
catch {
    # Continue with installation
}

if ($claudeInstalled) {
    # Write-Host "Claude Code already detected, updating..." -ForegroundColor Cyan
    # $installResult = npm install -g @anthropic-ai/claude-code@latest 2>&1
    Write-Host "Claude Code already detected, skipping installation." -ForegroundColor Cyan
}
else {
    Write-Host "Installing Claude Code @2.1.153 (this may take a few minutes)..." -ForegroundColor Cyan
    $installResult = npm install -g @anthropic-ai/claude-code@2.1.153 2>&1
}

if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-Host "ERROR: Claude Code installation failed. Please check network connection and try again." -ForegroundColor Red
    Write-Host "Error details: $installResult" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Claude Code installed successfully." -ForegroundColor Green
Write-Host ""

# ============================================
# Step 3: Add Claude Code to System PATH
# ============================================
Write-Host "[3/6] Configuring system PATH environment variable..." -ForegroundColor Yellow

try {
    $npmPrefix = npm prefix -g 2>&1
    $npmPrefix = $npmPrefix.ToString().Trim()
    $npmBinPath = Join-Path $npmPrefix "node_modules\.bin"
    
    if (-not (Test-Path $npmBinPath)) {
        throw "Path not found"
    }
}
catch {
    Write-Host "Warning: npm global bin directory not found at: $npmBinPath" -ForegroundColor Yellow
    Write-Host "Trying alternative paths..." -ForegroundColor Yellow
    
    $possiblePaths = @(
        "$env:AppData\npm\node_modules\.bin",
        "$env:ProgramFiles\nodejs\node_modules\.bin",
        "$env:USERPROFILE\AppData\Roaming\npm\node_modules\.bin"
    )
    
    $npmBinPath = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $npmBinPath = $path
            break
        }
    }
    
    if (-not $npmBinPath) {
        Write-Host "ERROR: Unable to auto-detect Claude Code installation path" -ForegroundColor Red
        Write-Host "Please manually add the following path to your system PATH:" -ForegroundColor Yellow
        Write-Host "$npmPrefix\node_modules\.bin" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Press any key to continue (you can add it manually later)..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

if ($npmBinPath -and (Test-Path $npmBinPath)) {
    Write-Host "Claude Code path detected: $npmBinPath" -ForegroundColor Cyan
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $pathToAdd = $npmBinPath
        
        if ($currentPath -split ';' -contains $pathToAdd) {
            Write-Host "Claude Code path already exists in system PATH." -ForegroundColor Green
        }
        else {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pathToAdd", "Machine")
            Write-Host "Claude Code added to system PATH." -ForegroundColor Green
            Write-Host "Note: You need to restart your terminal for changes to take effect." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Warning: Unable to modify system PATH: $_" -ForegroundColor Yellow
        Write-Host "Please manually add the following path to your system PATH:" -ForegroundColor Cyan
        Write-Host $npmBinPath -ForegroundColor Gray
    }
}

Write-Host ""

# =============================================
# 补充设置：禁用自动升级、设置环境变量等
# =============================================

# ---------- 补充步骤 1：配置 settings.json ----------
Write-Host "`n[1/2]补充设置：正在配置 .claude/settings.json 禁用自动升级..." -ForegroundColor Cyan

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$settingsPath = Join-Path $claudeDir "settings.json"

# 创建目录（如果不存在）
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

# 读取现有配置（如果存在）
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
}
else {
    $settings = @{}
}

# 添加/更新禁用自动升级的字段
$updateFields = @{
    autoUpdates         = $false
    DISABLE_UPDATES     = "1"
    DISABLE_AUTOUPDATER = "1"
    disableAutoUpdater  = $true
}

foreach ($key in $updateFields.Keys) {
    $settings.$key = $updateFields[$key]
}

# 写回文件
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "✓ settings.json 已更新: $settingsPath" -ForegroundColor Green

# ---------- 补充步骤 2：设置环境变量以禁止绝大多数遥测数据（永久） ----------
Write-Host "`n[2/2]补充设置：正在设置用户级系统环境变量以禁止绝大多数遥测数据..." -ForegroundColor Cyan

$envVars = @{
    "DISABLE_TELEMETRY"                        = "1"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" = "1"
    "DISABLE_ERROR_REPORTING"                  = "1"
}

foreach ($var in $envVars.Keys) {
    [Environment]::SetEnvironmentVariable($var, $envVars[$var], "User")
    # 同时更新当前进程的环境变量，以便后续命令（如 npm）可能用到
    [Environment]::SetEnvironmentVariable($var, $envVars[$var], "Process")
    Write-Host "✓ 已设置 $var = $($envVars[$var])" -ForegroundColor Green
}



# ============================================
# Step 4: Bypass Region Restriction (Solution C)
# ============================================
Write-Host "[4/6] Configuring Claude Code to bypass region restrictions..." -ForegroundColor Yellow

$claudeConfigPath = Join-Path $env:USERPROFILE ".claude.json"

if (-not (Test-Path $claudeConfigPath)) {
    $initialConfig = @{
        hasCompletedOnboarding = $true
        apiKey                 = $null
    } | ConvertTo-Json
    Set-Content -Path $claudeConfigPath -Value $initialConfig -Encoding UTF8
    Write-Host "Claude Code configuration file created." -ForegroundColor Green
}
else {
    try {
        $configContent = Get-Content $claudeConfigPath -Raw -Encoding UTF8
        $config = $configContent | ConvertFrom-Json
        
        if ($config -is [PSCustomObject]) {
            $config | Add-Member -NotePropertyName "hasCompletedOnboarding" -NotePropertyValue $true -Force
            $config | ConvertTo-Json | Set-Content $claudeConfigPath -Encoding UTF8
            Write-Host "Claude Code configuration updated, region restrictions bypassed." -ForegroundColor Green
        }
        else {
            throw "Invalid config format"
        }
    }
    catch {
        Write-Host "Warning: Configuration file format issue, rebuilding..." -ForegroundColor Yellow
        $config = @{
            hasCompletedOnboarding = $true
        } | ConvertTo-Json
        Set-Content -Path $claudeConfigPath -Value $config -Encoding UTF8
        Write-Host "Configuration file rebuilt successfully." -ForegroundColor Green
    }
}

Write-Host ""

# ============================================
# Step 5: Configure LLM Environment Variables (DeepSeek)
# ============================================
Write-Host "[5/6] Configuring DeepSeek V4 environment variables..." -ForegroundColor Yellow

try {
    [Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "https://api.deepseek.com/anthropic", "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", "deepseek-v4-flash", "User")
    Write-Host "ANTHROPIC_BASE_URL and ANTHROPIC_MODEL have been set." -ForegroundColor Green
}
catch {
    Write-Host "Warning: Unable to set environment variables: $_" -ForegroundColor Yellow
    Write-Host "Please manually set the following user environment variables:" -ForegroundColor Cyan
    Write-Host "  ANTHROPIC_BASE_URL = https://api.deepseek.com/anthropic" -ForegroundColor Gray
    Write-Host "  ANTHROPIC_MODEL = deepseek-v4-flash" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Please prepare your DeepSeek API Key" -ForegroundColor Cyan
Write-Host "   Get it from: https://platform.deepseek.com/api_keys" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$apiKey = Read-Host "Enter your DeepSeek API Key (format: sk-xxxxxx)"

if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "ERROR: API Key cannot be empty" -ForegroundColor Red
    Write-Host "You can manually set the environment variable ANTHROPIC_AUTH_TOKEN later." -ForegroundColor Yellow
}
elseif ($apiKey -notmatch '^sk-') {
    Write-Host "Warning: API Key format may be incorrect. DeepSeek API Keys typically start with 'sk-'" -ForegroundColor Yellow
    $confirm = Read-Host "Continue anyway? (y/n)"
    if ($confirm -ne 'y') {
        Write-Host "Please re-run the script or configure manually." -ForegroundColor Yellow
        $apiKey = $null
    }
}

if ($apiKey) {
    try {
        [Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $apiKey, "User")
        Write-Host "DeepSeek API Key saved to user environment variables." -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Unable to save API Key: $_" -ForegroundColor Yellow
        Write-Host "Please manually set the user environment variable: ANTHROPIC_AUTH_TOKEN" -ForegroundColor Cyan
    }
}

Write-Host ""

# ============================================
# Step 6: Complete Configuration
# ============================================
Write-Host "[6/6] Configuration complete!" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "    Claude Code Installation Successful!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "  - Node.js v$nodeMajorVersion detected"
Write-Host "  - Claude Code installed"
Write-Host "  - System PATH configured"
Write-Host "  - Region restrictions bypassed"
Write-Host "  - DeepSeek V4 Flash configured" -ForegroundColor Green
if ($apiKey) {
    Write-Host "  - DeepSeek API Key saved" -ForegroundColor Green
}
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Close this PowerShell window" -ForegroundColor Yellow
Write-Host "  2. Open a NEW PowerShell window (as a regular user)" -ForegroundColor Yellow
Write-Host "  3. Navigate to your project directory, for example:" -ForegroundColor Yellow
Write-Host "     cd D:\your-project" -ForegroundColor Gray
Write-Host "  4. Start Claude Code:" -ForegroundColor Yellow
Write-Host "     claude" -ForegroundColor White
Write-Host ""

Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  - claude           - Start Claude Code" -ForegroundColor Gray
Write-Host "  - claude --help    - View help" -ForegroundColor Gray
Write-Host "  - claude --version - View version" -ForegroundColor Gray
Write-Host ""

Write-Host "Important Notes:" -ForegroundColor Yellow
Write-Host "  - If 'claude' command is not found, restart your terminal for PATH changes to take effect" -ForegroundColor Gray
Write-Host "  - To change API Key, edit the ANTHROPIC_AUTH_TOKEN user environment variable" -ForegroundColor Gray
Write-Host "  - To switch models, modify the ANTHROPIC_MODEL environment variable" -ForegroundColor Gray
Write-Host "    Examples: deepseek-v4-flash / deepseek-v4-pro" -ForegroundColor Gray
Write-Host ""

Write-Host "Thank you! Happy coding! " -ForegroundColor Magenta
Write-Host ""

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")