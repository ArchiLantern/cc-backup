# Node.js 自动安装脚本 for Windows 10
# 需要以管理员权限运行

# 颜色函数
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检查当前 Node.js 版本
function Check-CurrentNode {
    try {
        $nodeVersion = & node -v 2>$null
        if ($nodeVersion) {
            $version = $nodeVersion.TrimStart('v')
            Write-ColorOutput Yellow "当前 Node.js 版本: $nodeVersion"
            $majorVersion = [int]($version -split '\.')[0]
            if ($majorVersion -ge 18) {
                Write-ColorOutput Green "✓ 当前版本满足要求 (需要 v18+)"
                return $true
            } else {
                Write-ColorOutput Red "✗ 当前版本过低，需要 v18 或更高版本"
                return $false
            }
        } else {
            Write-ColorOutput Yellow "未检测到 Node.js 安装"
            return $false
        }
    } catch {
        Write-ColorOutput Yellow "未检测到 Node.js 安装"
        return $false
    }
}

# 下载并安装 Node.js
function Install-NodeJS {
    param([string]$Version, [string]$MajorVersion)
    
    $nodeVersion = $Version
    $installerName = "node-v${nodeVersion}-x64.msi"
    
    # 根据版本选择下载链接
    if ($MajorVersion -eq "18") {
        $downloadUrl = "https://nodejs.org/dist/v${nodeVersion}/$installerName"
    } else {
        $downloadUrl = "https://nodejs.org/dist/v${nodeVersion}/$installerName"
    }
    
    $tempDir = "$env:TEMP\nodejs_install"
    $installerPath = "$tempDir\$installerName"
    
    # 创建临时目录
    if (!(Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    Write-ColorOutput Yellow "正在下载 Node.js v${nodeVersion}..."
    Write-ColorOutput Yellow "下载地址: $downloadUrl"
    
    try {
        # 下载安装程序
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $installerPath)
        Write-ColorOutput Green "✓ 下载完成"
        
        # 静默安装 MSI
        Write-ColorOutput Yellow "正在安装 Node.js (这可能需要几分钟)..."
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-ColorOutput Green "✓ Node.js 安装成功"
            
            # 刷新环境变量
            Refresh-EnvironmentVariables
            
            return $true
        } else {
            Write-ColorOutput Red "✗ 安装失败，退出代码: $($process.ExitCode)"
            return $false
        }
    } catch {
        Write-ColorOutput Red "下载或安装失败: $($_.Exception.Message)"
        return $false
    } finally {
        # 清理临时文件
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# 使用 NVM for Windows 安装
function Install-WithNVM {
    param([string]$Version)
    
    Write-ColorOutput Yellow "正在安装/更新 NVM for Windows..."
    
    # 检查是否已安装 nvm
    $nvmInstalled = Get-Command nvm -ErrorAction SilentlyContinue
    
    if (-not $nvmInstalled) {
        # 下载 NVM 安装程序
        $nvmInstallerUrl = "https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe"
        $tempDir = "$env:TEMP\nvm_install"
        $installerPath = "$tempDir\nvm-setup.exe"
        
        if (!(Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        try {
            Write-ColorOutput Yellow "正在下载 NVM for Windows..."
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($nvmInstallerUrl, $installerPath)
            
            Write-ColorOutput Yellow "正在安装 NVM..."
            Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
            
            # 刷新环境变量
            Refresh-EnvironmentVariables
            
            Write-ColorOutput Green "✓ NVM 安装完成"
        } catch {
            Write-ColorOutput Red "NVM 安装失败: $($_.Exception.Message)"
            return $false
        } finally {
            if (Test-Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        Write-ColorOutput Green "✓ NVM 已安装"
    }
    
    # 使用 NVM 安装 Node.js
    Write-ColorOutput Yellow "正在使用 NVM 安装 Node.js v${Version}..."
    
    try {
        # 安装指定版本
        & nvm install $Version
        Start-Sleep -Seconds 2
        
        # 使用该版本
        & nvm use $Version
        
        # 设置默认版本
        & nvm alias default $Version
        
        Write-ColorOutput Green "✓ Node.js v${Version} 安装完成"
        return $true
    } catch {
        Write-ColorOutput Red "NVM 安装 Node.js 失败: $($_.Exception.Message)"
        return $false
    }
}

# 刷新环境变量
function Refresh-EnvironmentVariables {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# 验证安装
function Verify-Installation {
    Start-Sleep -Seconds 2
    Write-ColorOutput Blue "`n验证安装结果:"
    
    try {
        $nodeVersion = & node -v 2>$null
        $npmVersion = & npm -v 2>$null
        
        if ($nodeVersion) {
            Write-ColorOutput Green "✓ Node.js 版本: $nodeVersion"
            Write-ColorOutput Green "✓ npm 版本: $npmVersion"
            
            $version = $nodeVersion.TrimStart('v')
            $majorVersion = [int]($version -split '\.')[0]
            if ($majorVersion -ge 18) {
                Write-ColorOutput Green "✓ 版本满足要求！"
                return $true
            } else {
                Write-ColorOutput Red "✗ 版本仍然过低"
                return $false
            }
        } else {
            Write-ColorOutput Red "✗ Node.js 未正确安装"
            return $false
        }
    } catch {
        Write-ColorOutput Red "✗ 验证失败"
        return $false
    }
}

# 主菜单
function Show-Menu {
    Clear-Host
    Write-ColorOutput Blue "=================================="
    Write-ColorOutput Blue "   Node.js 版本安装选择"
    Write-ColorOutput Blue "=================================="
    Write-ColorOutput Green "1) Node.js v18 (LTS - 长期支持版)"
    Write-ColorOutput Green "2) Node.js v22 (推荐 - 最新稳定版)"
    Write-ColorOutput Red "0) 退出"
    Write-ColorOutput Blue "=================================="
}

# 主函数
function Main {
    Write-ColorOutput Blue "Node.js 环境检查和安装脚本"
    Write-ColorOutput Blue "=================================="
    
    # 检查管理员权限
    if (-not (Test-Administrator)) {
        Write-ColorOutput Red "警告: 建议以管理员权限运行此脚本以获得最佳体验"
        Write-ColorOutput Yellow "如果不使用管理员权限，NVM 方式可能无法正常工作"
        Write-Host ""
        $continue = Read-Host "是否继续？(y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            exit 1
        }
    }
    
    # 检查当前版本
    $versionOk = Check-CurrentNode
    
    if ($versionOk) {
        Write-ColorOutput Green "当前版本已满足要求"
        $reinstall = Read-Host "是否仍要重新安装其他版本？(y/N)"
        if ($reinstall -ne 'y' -and $reinstall -ne 'Y') {
            exit 0
        }
    }
    
    # 选择安装版本
    while ($true) {
        Show-Menu
        $choice = Read-Host "请选择要安装的版本 [0-2]"
        
        switch ($choice) {
            "1" { 
                $version = "18"
                $fullVersion = "18.19.0"  # v18 LTS 最新版本
                break
            }
            "2" { 
                $version = "22"
                $fullVersion = "22.11.0"  # v22 最新稳定版
                break
            }
            "0" { 
                Write-ColorOutput Red "退出安装"
                exit 0
            }
            default { 
                Write-ColorOutput Red "无效选择，请重新输入"
                continue
            }
        }
        break
    }
    
    # 选择安装方式
    Write-Host ""
    Write-ColorOutput Yellow "请选择安装方式:"
    Write-ColorOutput Green "1) 使用 NVM for Windows (推荐 - 便于版本管理)"
    Write-ColorOutput Green "2) 直接下载 MSI 安装包"
    $method = Read-Host "请选择 [1-2]"
    
    $success = $false
    if ($method -eq "1") {
        $success = Install-WithNVM -Version $version
    } else {
        $success = Install-NodeJS -Version $fullVersion -MajorVersion $version
    }
    
    if ($success) {
        # 刷新环境变量
        Refresh-EnvironmentVariables
        
        # 验证安装
        if (Verify-Installation) {
            Write-Host ""
            Write-ColorOutput Green "=================================="
            Write-ColorOutput Green "安装完成！"
            Write-ColorOutput Yellow "请重新打开命令行窗口以使环境变量生效"
            Write-ColorOutput Green "=================================="
        }
    } else {
        Write-ColorOutput Red "安装失败，请手动下载安装"
        Write-ColorOutput Yellow "下载地址: https://nodejs.org/"
    }
    
    Read-Host "`n按回车键退出"
}

# 运行主函数
Main