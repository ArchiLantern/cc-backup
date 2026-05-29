# Claude Code Windows 工具箱

专为 Windows 用户打造的 [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) 安装、降级与配置工具箱。解决在中国大陆 Windows 环境下使用 Claude Code 时可能遇到的各种痛点：

- Node.js 版本检测与自动安装/升级
- 一键安装/降级 Claude Code CLI 并锁定版本（防止静默更新）
- 自动禁用遥测与不必要的网络请求
- 切换国内 npm 镜像源加速下载
- 配置 DeepSeek V4 作为后端模型，绕过区域限制
- 修复 PowerShell/CMD 中文乱码问题
- 附带 VS Code 插件离线安装包（v2.1.153）

---

## 目录

- [Claude Code Windows 工具箱](#claude-code-windows-工具箱)
  - [目录](#目录)
  - [项目结构](#项目结构)
  - [快速使用](#快速使用)
    - [场景一：全新安装 Claude Code](#场景一全新安装-claude-code)
    - [场景二：降级与锁定版本](#场景二降级与锁定版本)
    - [场景三：单独安装/升级 Node.js](#场景三单独安装升级-nodejs)
    - [场景四：切换 npm 镜像源](#场景四切换-npm-镜像源)
    - [场景五：批量修复中文乱码](#场景五批量修复中文乱码)
  - [各脚本详解](#各脚本详解)
    - [`setup-old-cc/` — 降级与锁版本](#setup-old-cc--降级与锁版本)
    - [`cc-quick-install-scripts/cc-auto-install/` — 一键安装Claude Code（API配置DeepSeek）](#cc-quick-install-scriptscc-auto-install--一键安装claude-codeapi配置deepseek)
    - [工具脚本](#工具脚本)
  - [配置文件说明](#配置文件说明)
    - [`~/.claude/settings.json`](#claudesettingsjson)
    - [系统环境变量（用户级）](#系统环境变量用户级)
  - [注意事项](#注意事项)

---

## 项目结构

```
cc-backup/
│
├── setup-old-cc/                              # 旧版降级 & 锁版本工具
│   ├── Setup-Old-CC-by-Admin.bat             # ★ 入口：右键管理员运行
│   ├── Setup-Old-ClaudeCode.ps1              # 核心脚本
│   ├── anthropic.claude-code-2.1.153
│   │       └── -win32-x64.vsix               # VS Code 插件离线安装包
│   └── 告小白：要快，就右键管理员运行.bat文件！！！.txt
│
├── cc-quick-install-scripts/
│   └── cc-auto-install/                       # 全新安装套件
│       ├── cc-install-by-Admin.bat           # ★ 入口：右键管理员运行
│       ├── cc-install.ps1                   # 一键安装 CC + 配置 DeepSeek
│       ├── node-install-by-Admin.bat        # ★ 入口：右键管理员运行
│       ├── node-install.ps1                 # Node.js 安装/升级
│       ├── npm-mirror-switcher-by-Admin.bat # ★ 入口：右键管理员运行
│       ├── npm-mirror-switcher.ps1          # npm 镜像源切换
│       ├── 告小白：要快，就右键管理员运行.bat文件！！！.txt
│       └── 踩坑历史（部分）/                 # 开发过程中的参考记录
│           ├── Convert-ToUTF8BOM.ps1        # UTF-8 BOM 编码修复
│           └── ...其他调试脚本
│
└── README.md
```

---

## 快速使用

> ⚠️ **注意**：以 `.ps1` 结尾的 PowerShell 脚本不支持直接右键管理员运行，请始终通过同目录下的 `.bat` 文件启动。`.bat` 文件支持 **右键 → 以管理员身份运行**。

---

### 场景一：全新安装 Claude Code

如果你是**第一次安装 Claude Code**，或想**快速重装并配置好 DeepSeek 后端**：

1. 进入 `cc-quick-install-scripts/cc-auto-install/`
2. 右键 `cc-install-by-Admin.bat` → **以管理员身份运行**
3. 脚本自动完成以下 6 步：
   - 检测 Node.js 版本（需 v18+，不满足则提示）
   - 全局安装 `@anthropic-ai/claude-code` 及必要依赖
   - 将 Claude Code 添加到系统 PATH
   - 配置 `~/.claude/settings.json` 禁用自动更新
   - 设置用户级环境变量禁用遥测
   - 配置 DeepSeek V4 作为后端模型：设置 `ANTHROPIC_BASE_URL`、`ANTHROPIC_MODEL`
   - 提示输入 DeepSeek API Key 并保存
   - 绕过 Claude Code 区域限制

---

### 场景二：降级与锁定版本

如果**已安装新版 Claude Code**（v2.1.154+），由于消息体结构变化导致接入第三方 API（如 DeepSeek、MiniMax）时报 `API Error: 400 unknown variant system` 错误，需要**回退到 v2.1.153** 并锁定版本防止再次升级：

1. 进入 `setup-old-cc/`
2. 右键 `Setup-Old-CC-by-Admin.bat` → **以管理员身份运行**
3. 脚本自动完成：
   - 修改 `~/.claude/settings.json` 禁用自动更新
   - 设置用户级环境变量禁用遥测
   - 卸载当前 Claude Code，安装 `@anthropic-ai/claude-code@2.1.153`
   - 提示 VS Code 插件降级步骤

> **VS Code 插件手动处理**：如果使用 VS Code 插件，CLI 降级后插件仍为最新版，需额外手动降级。打开 VS Code → 扩展面板 → 找到 Claude Code → 齿轮图标 → "安装另一版本..." → 选择 `2.1.153`。若列表中未显示，可卸载后使用附带的 `.vsix` 文件手动安装。

---

### 场景三：单独安装/升级 Node.js

Node.js 版本低于 v18，或想通过 NVM 管理多版本：

1. 进入 `cc-quick-install-scripts/cc-auto-install/`
2. 右键 `node-install-by-Admin.bat` → **以管理员身份运行**
3. 脚本自动检测当前 Node.js 版本：
   - 满足要求（v18+）→ 可选择是否重新安装
   - 过低或未安装 → 弹出菜单选择 v18 LTS 或 v22 LTS
4. 优先使用 **NVM for Windows** 安装，失败则自动回退到 **MSI 安装**
5. 安装完成后自动切换为国内 npm 镜像源（淘宝镜像）

---

### 场景四：切换 npm 镜像源

`npm install` 速度慢或超时：

1. 进入 `cc-quick-install-scripts/cc-auto-install/`
2. 右键 `npm-mirror-switcher-by-Admin.bat` → **以管理员身份运行**
3. 从菜单中选择一个镜像源：

| 选项 | 镜像源 | 说明 |
|------|--------|------|
| 1 | npm Official（`registry.npmjs.org`） | 官方源 |
| 2 | 淘宝（`registry.npmmirror.com`） | 国内推荐 |
| 3 | 华为云 | 国内备用 |
| 4 | 腾讯云 | 国内备用 |
| 5 | 中科大 USTC | 教育网友好 |
| 6 | 自定义 URL | 手动输入 |

---

### 场景五：批量修复中文乱码

`.bat` / `.cmd` / `.ps1` 脚本在 CMD 或 PowerShell 中显示中文乱码时：

1. 找到 `踩坑历史（部分）/Convert-ToUTF8BOM.ps1`
2. 右键 → **使用 PowerShell 运行**
3. 脚本自动遍历当前目录及所有子目录，为不包含 BOM 的 `.bat`、`.cmd`、`.ps1` 文件添加 **UTF-8 with BOM** 编码

---

## 各脚本详解

### `setup-old-cc/` — 降级与锁版本

| 文件 | 说明 |
|------|------|
| `Setup-Old-CC-by-Admin.bat` | 入口文件，右键管理员运行，自动调用同目录下的 PowerShell 脚本 |
| `Setup-Old-ClaudeCode.ps1` | 核心脚本：检查当前版本 → 配置 settings.json 禁用更新 → 设置遥测禁用环境变量 → 降级到 v2.1.153 → 输出 VS Code 插件处理建议 |
| `anthropic.claude-code-2.1.153-win32-x64.vsix` | VS Code 插件离线安装包，v2.1.153 版本（Windows x64），供无法在线降级的用户使用 |

### `cc-quick-install-scripts/cc-auto-install/` — 一键安装Claude Code（API配置DeepSeek）

| 文件 | 说明 |
|------|------|
| `cc-install-by-Admin.bat` | Claude Code 一键安装入口 |
| `cc-install.ps1` | 6 步完成：检测 Node → 安装 CC → 配置 PATH → 配置 settings.json → 设置环境变量 → 配置 DeepSeek 后端并绕过区域限制 |
| `node-install-by-Admin.bat` | Node.js 安装入口 |
| `node-install.ps1` | 检测 Node 版本，通过 NVM 或 MSI 安装 v18/v22，安装后自动切换国内镜像 |
| `npm-mirror-switcher-by-Admin.bat` | npm 镜像切换入口 |
| `npm-mirror-switcher.ps1` | 交互式切换 npm registry 到 6 种可选镜像源，支持自定义源 |

### 工具脚本

| 文件 | 说明 |
|------|------|
| `踩坑历史（部分）/Convert-ToUTF8BOM.ps1` | 批量为脚本文件添加 UTF-8 with BOM 编码，解决 Windows 中文乱码 |

---

## 配置文件说明

### `~/.claude/settings.json`

Claude Code CLI 的配置文件（Windows 路径：`C:\Users\<用户名>\.claude\settings.json`）。脚本会在其中写入以下字段：

```json
{
  "autoUpdates": false,
  "DISABLE_UPDATES": "1",
  "DISABLE_AUTOUPDATER": "1",
  "disableAutoUpdater": true
}
```

### 系统环境变量（用户级）

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `DISABLE_TELEMETRY` | `1` | 禁用遥测上报（关闭 Datadog、BigQuery 等通道） |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `1` | 禁用非必要网络流量 |
| `DISABLE_ERROR_REPORTING` | `1` | 禁用错误报告 |

以下由 `cc-install.ps1` 额外设置，用于配置 DeepSeek 后端：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` | DeepSeek API 端点 |
| `ANTHROPIC_MODEL` | `deepseek-v4-flash` | 默认使用的模型 |
| `ANTHROPIC_AUTH_TOKEN` | `sk-xxxxxx` | DeepSeek API Key（安装时交互输入） |

---

## 注意事项

- **管理员权限**：所有涉及修改系统环境变量、PATH 或 `settings.json` 的操作均需管理员权限。请始终通过右键 `.bat` 文件 → **以管理员身份运行** 来执行。

- **关闭遥测存在性能代价**：Anthropic 官方将 1 小时 Prompt Cache 视为实验性功能，关闭遥测会导致 Prompt Cache TTL 从 1 小时降至默认的 5 分钟，长对话场景下的 Token 消耗和延迟可能会显著增加。

- **身份信息无法彻底关闭**：`DISABLE_TELEMETRY=1` 只能关闭 Datadog 和 BigQuery 通道。API 请求自身携带的 `Attribution Header`（含设备指纹）和 `Attestation`（原生客户端认证）仍然会发送。

- **VS Code 插件需手动降级**：CLI 降级后，VS Code 插件通常仍为最新版，如遇插件报错需在插件设置中手动安装 `2.1.153` 版本。本工具箱附带了 `.vsix` 离线安装包。

- **重启终端**：修改环境变量后，需重启 PowerShell / CMD / VS Code 才能生效。

- **npm 镜像同步延迟**：国内镜像源与官方源存在数分钟到数小时的同步延迟，如遇包版本找不到，可切回官方源重试。
