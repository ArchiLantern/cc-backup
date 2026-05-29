# Claude Code 旧版安装 & 隐私保护工具箱

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> 一套 PowerShell 脚本，帮你解决 Claude Code 新版不兼容第三方 API 的问题，并提供隐私保护方案。

## 🎯 项目背景

近期 Claude Code 更新后，Claude Code 官方 CLI 悄悄推送了新版本（如 v2.1.154+），改变了消息体结构，导致接入 DeepSeek、MiniMax 等第三方模型的用户收到 `API Error: 400 unknown variant system` 错误[reference:0]。同时，VS Code 中的 Claude Code 插件也会自动升级到不兼容的版本，导致同样的错误[reference:1]。

除此之外，Claude Code 内置的遥测系统会收集用户数据，关闭遥测后虽然能保护隐私，但会带来 Prompt Cache TTL 从 1 小时降至 5 分钟的性能惩罚[reference:2]，且 `Attribution Header` 等身份信息仍会随 API 请求发送[reference:3][reference:4]。

本仓库提供了一系列自动化脚本，帮你：

- **一键回退**：将 Claude Code CLI 回退至兼容第三方 API 的 `v2.1.153`，并可选择锁定版本，防止自动更新[reference:5]。
- **禁用遥测**：通过环境变量禁用 Claude Code 的遥测数据上报，保护你的使用习惯等元数据隐私。
- **修复乱码**：提供脚本，批量为 `.bat`、`.cmd`、`.ps1` 等文件添加 UTF-8 with BOM 编码，从根源上解决 Windows 控制台中文乱码问题。

## 🚀 快速开始

### 脚本一：`Setup-ClaudeCode.ps1`
**功能**：一键完成 CLI 版本锁定与遥测禁用。它会自动检查当前版本，如果不是 `2.1.153`，则执行降级；同时它会自动修改 `~/.claude/settings.json` 来禁用自动更新，并设置环境变量以关闭遥测。

**使用方法**：
1.  **用管理员身份运行脚本**
    由于脚本会修改系统环境变量，因此需要右键点击 `Setup-Old-CC-by-admin.bat`，选择"以管理员身份运行"。

2.  **脚本会自动完成以下操作**
    - 修改 `~/.claude/settings.json` 锁定 CLI 版本，防止自动升级[reference:6]。
    - 设置系统环境变量，禁用遥测。
    - 检查当前版本，如果不是 `2.1.153`，则自动执行 `npm uninstall` 与 `npm install` 完成降级。

3.  **手动处理 VSCode 插件**
    CLI 降级完成后，如果你在使用 VSCode 插件，还需要**手动处理**：在 VSCode 扩展面板中找到 `Claude Code` 插件，点击齿轮图标选择"安装另一版本..."，并选择 `2.1.153`。若列表中未显示，则需先卸载，再手动下载 `.vsix` 文件进行安装[reference:7]。

### 脚本二：`Convert-ToUTF8BOM.ps1`
**功能**：批量为 `.bat`、`.cmd`、`.ps1` 等脚本文件添加 UTF-8 with BOM 编码，从根源上解决 Windows 控制台的中文乱码问题。

**注意⚠️**：该脚本会 遍历当前目录及所有子目录下的 `.bat`、`.cmd` 和 `.ps1` 文件，并为不包含 BOM 的文件添加 UTF-8 with BOM 编码。请确保在运行前备份重要文件，以防止意外修改。

**使用方法**：
1.  将 `Convert-ToUTF8BOM.ps1` 放在你的脚本目录中。
2.  右键点击该文件，选择"使用 PowerShell 运行"。
3.  脚本会自动处理当前目录及所有子目录下的 `.bat`、`.cmd` 和 `.ps1` 文件，并跳过已包含 BOM 的文件。


## 🔧 配置文件详解

### `settings.json`
CLI 配置文件位于 `~/.claude/settings.json`（Windows 下为 `C:\Users\你的用户名\.claude\settings.json`）。脚本会自动在其中添加以下配置，以禁用自动更新：
```json
{
  "autoUpdates": false,
  "DISABLE_UPDATES": "1",
  "DISABLE_AUTOUPDATER": "1",
  "disableAutoUpdater": true
}
```

### 环境变量
脚本会自动设置以下用户级环境变量：
```powershell
DISABLE_TELEMETRY = "1"
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
DISABLE_ERROR_REPORTING = "1"
```
设置后，Claude Code 将不再向 Datadog、BigQuery 等通道上报数据。

## ⚠️ 注意事项

- **关闭遥测存在性能代价**：Anthropic 官方将 1 小时 Prompt Cache 视为实验性功能，关闭遥测会导致 Prompt Cache TTL 从 1 小时降至默认的 5 分钟，这意味着长对话场景下的 Token 消耗和延迟可能会显著增加。
- **身份信息无法彻底关闭**：`DISABLE_TELEMETRY=1` 只能关闭 Datadog 和 BigQuery 通道。API 请求自身携带的 `Attribution Header`（含设备指纹）和 `Attestation`（原生客户端认证）仍然会发送。
- **VS Code 插件需手动降级**：CLI 降级后，VSCode 插件通常仍为最新版。为解决插件报错问题，须在插件设置中额外手动安装 `2.1.153` 版本。
- **管理员权限**：设置系统环境变量和修改 `settings.json` 均需要管理员权限。  

--- 
Auto-Gen-By: DeepSeek-v4-flash

