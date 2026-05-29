# npm Mirror Switcher for Windows
# Run this script to switch npm registry to domestic mirrors

<#
   功能：切换 npm 镜像源，提供国内常用的几个镜像选项，方便在中国大陆使用 npm 安装包时加速下载。 
#>

# ---------- 设置中文显示 ----------
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Check if npm is available
function Test-NpmInstalled {
    try {
        $npmVersion = & npm -v 2>$null
        if ($npmVersion) {
            Write-Host "[OK] npm found (version: $npmVersion)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] npm is not installed or not in PATH" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to run npm command" -ForegroundColor Red
        return $false
    }
}

# Show current registry
function Show-CurrentRegistry {
    try {
        $current = & npm config get registry
        Write-Host "Current npm registry: " -NoNewline
        Write-Host "$current" -ForegroundColor Cyan
        return $current
    } catch {
        Write-Host "[ERROR] Unable to get current registry" -ForegroundColor Red
        return $null
    }
}

# Set npm registry
function Set-NpmRegistry {
    param([string]$RegistryName, [string]$RegistryUrl)
    
    try {
        & npm config set registry $RegistryUrl
        Write-Host "[OK] Switched to $RegistryName" -ForegroundColor Green
        
        # Verify
        $newRegistry = & npm config get registry
        if ($newRegistry -eq $RegistryUrl) {
            Write-Host "[OK] Verification passed: $newRegistry" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] Verification failed. Expected: $RegistryUrl, Got: $newRegistry" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to set registry: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Show menu
function Show-Menu {
    Clear-Host
    Write-Host "======================================" -ForegroundColor Blue
    Write-Host "     npm Registry Switcher" -ForegroundColor Blue
    Write-Host "======================================" -ForegroundColor Blue
    Write-Host ""
    
    Show-CurrentRegistry
    Write-Host ""
    
    Write-Host "Available mirrors:" -ForegroundColor Yellow
    Write-Host " 1) npm Official (Global)" -ForegroundColor Green
    Write-Host "    https://registry.npmjs.org/"
    Write-Host ""
    Write-Host " 2) Taobao (China, fast - Recommended)" -ForegroundColor Green
    Write-Host "    https://registry.npmmirror.com/"
    Write-Host ""
    Write-Host " 3) Huawei Cloud" -ForegroundColor Green
    Write-Host "    https://mirrors.huaweicloud.com/repository/npm/"
    Write-Host ""
    Write-Host " 4) Tencent Cloud" -ForegroundColor Green
    Write-Host "    https://mirrors.cloud.tencent.com/npm/"
    Write-Host ""
    Write-Host " 5) USTC (University of Science and Technology of China)" -ForegroundColor Green
    Write-Host "    https://npmreg.proxy.ustclug.org/"
    Write-Host ""
    Write-Host " 6) Custom URL" -ForegroundColor Green
    Write-Host ""
    Write-Host " 0) Exit without changes" -ForegroundColor Red
    Write-Host ""
}

# Main function
function Main {
    # Check npm
    if (-not (Test-NpmInstalled)) {
        Write-Host "Please install Node.js/npm first from https://nodejs.org/" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select mirror [0-6]"
        
        switch ($choice) {
            "1" {
                $url = "https://registry.npmjs.org/"
                $name = "npm Official"
                Set-NpmRegistry -RegistryName $name -RegistryUrl $url
                break
            }
            "2" {
                $url = "https://registry.npmmirror.com/"
                $name = "Taobao Mirror"
                Set-NpmRegistry -RegistryName $name -RegistryUrl $url
                break
            }
            "3" {
                $url = "https://mirrors.huaweicloud.com/repository/npm/"
                $name = "Huawei Cloud Mirror"
                Set-NpmRegistry -RegistryName $name -RegistryUrl $url
                break
            }
            "4" {
                $url = "https://mirrors.cloud.tencent.com/npm/"
                $name = "Tencent Cloud Mirror"
                Set-NpmRegistry -RegistryName $name -RegistryUrl $url
                break
            }
            "5" {
                $url = "https://npmreg.proxy.ustclug.org/"
                $name = "USTC Mirror"
                Set-NpmRegistry -RegistryName $name -RegistryUrl $url
                break
            }
            "6" {
                $customUrl = Read-Host "Enter custom registry URL (e.g., https://your-registry.com/)"
                if ($customUrl) {
                    Set-NpmRegistry -RegistryName "Custom" -RegistryUrl $customUrl
                } else {
                    Write-Host "[WARN] No URL provided, skipping..." -ForegroundColor Yellow
                }
                break
            }
            "0" {
                Write-Host "Exiting. No changes made." -ForegroundColor Yellow
                exit 0
            }
            default {
                Write-Host "[ERROR] Invalid choice, please select 0-6" -ForegroundColor Red
                Start-Sleep -Seconds 1
                continue
            }
        }
        
        Write-Host ""
        $again = Read-Host "Switch to another mirror? (y/N)"
        if ($again -ne 'y' -and $again -ne 'Y') {
            Write-Host "Current registry:" -ForegroundColor Cyan
            & npm config get registry
            Write-Host "Exiting. Goodbye!" -ForegroundColor Green
            break
        }
    }
}

# Run
Main