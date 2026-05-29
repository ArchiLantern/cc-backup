<#
.SYNOPSIS
    一键配置 Claude Code：禁用自动升级、禁用遥测、回退到稳定版本 2.1.153
.DESCRIPTION
    1. 修改 ~/.claude/settings.json 禁用自动更新
    2. 设置系统环境变量（用户级）禁用遥测和非必要流量
    3. 卸载当前 Claude Code 并安装 2.1.153 版本
    4. 输出 VS Code 插件处理建议
.NOTES
    需要以管理员身份运行 PowerShell
#>

# ---------- 设置中文显示 ----------
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 要求管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员身份运行此脚本！" -ForegroundColor Red
    Write-Host "右键 PowerShell -> 以管理员身份运行" -ForegroundColor Yellow
    exit 1
}

# ---------- 步骤 1：配置 settings.json ----------
Write-Host "`n[1/4] 正在配置 .claude/settings.json 禁用自动升级..." -ForegroundColor Cyan

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$settingsPath = Join-Path $claudeDir "settings.json"

# 创建目录（如果不存在）
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

# 读取现有配置（如果存在）
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = @{}
}

# 添加/更新禁用自动升级的字段
$updateFields = @{
    autoUpdates = $false
    DISABLE_UPDATES = "1"
    DISABLE_AUTOUPDATER = "1"
    disableAutoUpdater = $true
}

foreach ($key in $updateFields.Keys) {
    $settings.$key = $updateFields[$key]
}

# 写回文件
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "✓ settings.json 已更新: $settingsPath" -ForegroundColor Green

# ---------- 步骤 2：设置环境变量（永久） ----------
Write-Host "`n[2/4] 正在设置系统环境变量（用户级）..." -ForegroundColor Cyan

$envVars = @{
    "DISABLE_TELEMETRY" = "1"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" = "1"
    "DISABLE_ERROR_REPORTING" = "1"
}

foreach ($var in $envVars.Keys) {
    [Environment]::SetEnvironmentVariable($var, $envVars[$var], "User")
    # 同时更新当前进程的环境变量，以便后续命令（如 npm）可能用到
    [Environment]::SetEnvironmentVariable($var, $envVars[$var], "Process")
    Write-Host "✓ 已设置 $var = $($envVars[$var])" -ForegroundColor Green
}


# ---------- 步骤 3：检查并安装指定版本的 Claude Code ----------
Write-Host "`n[3/4] 正在检查 Claude Code 版本 ..." -ForegroundColor Cyan

# 检查 npm 是否可用
$npmPath = (Get-Command npm -ErrorAction SilentlyContinue).Source
if (-not $npmPath) {
    Write-Host "错误：未找到 npm 命令，请确保 Node.js 已安装并添加到 PATH。" -ForegroundColor Red
    exit 1
}
Write-Host "使用 npm 路径: $npmPath"

# 获取当前全局安装的 claude 版本
$currentVersion = $null
try {
    $versionOutput = claude --version 2>&1
    if ($LASTEXITCODE -eq 0 -and $versionOutput) {
        # 版本输出通常是 "2.1.153" 这样的格式
        $currentVersion = $versionOutput.Trim()
        Write-Host "当前已安装版本: $currentVersion" -ForegroundColor Cyan
    }
} catch {
    Write-Host "未检测到已安装的 Claude Code 或版本获取失败。" -ForegroundColor Yellow
}

$targetVersion = "2.1.153 (Claude Code)"

if ($currentVersion -eq $targetVersion) {
    Write-Host "✓ 当前版本已是 $targetVersion，无需重新安装。" -ForegroundColor Green
} else {
    Write-Host "当前版本 ($currentVersion) 与目标版本 ($targetVersion) 不一致，开始重新安装..." -ForegroundColor Yellow

    # 卸载当前版本
    Write-Host "正在卸载 @anthropic-ai/claude-code ..."
    npm uninstall -g @anthropic-ai/claude-code
    if ($LASTEXITCODE -ne 0) {
        Write-Host "警告：卸载时出现非零退出码，继续尝试安装..." -ForegroundColor Yellow
    }

    # 安装指定版本
    Write-Host "正在安装 @anthropic-ai/claude-code@$targetVersion ..."
    npm install -g "@anthropic-ai/claude-code@$targetVersion"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Claude Code $targetVersion 安装成功！" -ForegroundColor Green
        # 再次验证版本
        $newVersion = claude --version 2>$null
        if ($newVersion) {
            Write-Host "当前版本: $newVersion" -ForegroundColor Cyan
        }
    } else {
        Write-Host "安装失败，请检查网络或 npm 源配置。" -ForegroundColor Red
        exit 1
    }
}


# ---------- 步骤 4：VS Code 插件提示 ----------
Write-Host "`n[4/4] VS Code 插件处理建议" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Yellow
Write-Host "1. 打开 VS Code"
Write-Host "2. 按 Ctrl+Shift+X 打开扩展面板"
Write-Host "3. 搜索 'Claude Code'"
Write-Host "4. 点击扩展右侧的齿轮图标 → '禁用'"
Write-Host "5. （可选）若要降级到 2.1.153："
Write-Host "   - 点击齿轮 → '安装另一版本...'"
Write-Host "   - 选择 2.1.153（如未列出，需手动下载 .vsix）"
Write-Host "   或直接卸载该插件，继续使用 CLI 版本。"
Write-Host "--------------------------------------------------" -ForegroundColor Yellow

Write-Host "`n所有配置已完成！请重启 PowerShell 和 VS Code 使环境变量生效。" -ForegroundColor Green