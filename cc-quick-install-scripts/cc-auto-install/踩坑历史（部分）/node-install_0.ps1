# Node.js Automatic Installation Script for Windows 10
# Run as Administrator for best experience

# Color functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        # Write-Output $args  # !!!Never Use This F*!
        # !!! Use Write-Host to send directly to console, not to output stream !!!
        Write-Host $args 
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Check administrator privileges
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check current Node.js version
function Check-CurrentNode {
    try {
        # $nodeVersion = & node -v 2>$null
        # Remove error redirection to see actual errors
        $nodeVersion = & node -v 2>&1
        # Write-ColorOutput Yellow "Current Node.js version: $nodeVersion"
        if ($nodeVersion) {
            $version = $nodeVersion.TrimStart('v')
            Write-ColorOutput Yellow "Current Node.js version: $nodeVersion"
            $majorVersion = [int]($version -split '\.')[0]
            if ($majorVersion -ge 18) {
                Write-ColorOutput Green "[OK] Current version meets requirement (v18+ required)"
                return $true
            } else {
                Write-ColorOutput Red "[ERROR] Current version is too low, v18 or higher required"
                return $false
            }
        } else {
            Write-ColorOutput Yellow "Node.js not detected"
            return $false
        }
    } catch {
        Write-ColorOutput Yellow "Node.js not detected"
        return $false
    }
}

# Install Node.js via MSI
function Install-NodeJS {
    param([string]$Version, [string]$MajorVersion)
    
    $nodeVersion = $Version
    $installerName = "node-v${nodeVersion}-x64.msi"
    
    if ($MajorVersion -eq "18") {
        $downloadUrl = "https://nodejs.org/dist/v${nodeVersion}/$installerName"
    } else {
        $downloadUrl = "https://nodejs.org/dist/v${nodeVersion}/$installerName"
    }
    
    $tempDir = "$env:TEMP\nodejs_install"
    $installerPath = "$tempDir\$installerName"
    
    if (!(Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    Write-ColorOutput Yellow "Downloading Node.js v${nodeVersion}..."
    Write-ColorOutput Yellow "Download URL: $downloadUrl"
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $installerPath)
        Write-ColorOutput Green "[OK] Download completed"
        
        Write-ColorOutput Yellow "Installing Node.js (this may take a few minutes)..."
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-ColorOutput Green "[OK] Node.js installed successfully"
            Refresh-EnvironmentVariables
            return $true
        } else {
            Write-ColorOutput Red "[ERROR] Installation failed, exit code: $($process.ExitCode)"
            return $false
        }
    } catch {
        Write-ColorOutput Red "Download or installation failed: $($_.Exception.Message)"
        return $false
    } finally {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Install using NVM for Windows
function Install-WithNVM {
    param([string]$Version)
    
    Write-ColorOutput Yellow "Checking NVM for Windows..."
    
    $nvmInstalled = Get-Command nvm -ErrorAction SilentlyContinue
    
    if (-not $nvmInstalled) {
        $nvmInstallerUrl = "https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe"
        $tempDir = "$env:TEMP\nvm_install"
        $installerPath = "$tempDir\nvm-setup.exe"
        
        if (!(Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        try {
            Write-ColorOutput Yellow "Downloading NVM for Windows..."
            Write-ColorOutput Yellow "Downloading from Github: $nvmInstallerUrl"
            Write-ColorOutput Yellow "....."
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($nvmInstallerUrl, $installerPath)
            
            Write-ColorOutput Yellow "Installing NVM..."
            Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
            
            Refresh-EnvironmentVariables
            
            Write-ColorOutput Green "[OK] NVM installed successfully"
        } catch {
            Write-ColorOutput Red "NVM installation failed: $($_.Exception.Message)"
            return $false
        } finally {
            if (Test-Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        Write-ColorOutput Green "[OK] NVM already installed"
    }
    
    Write-ColorOutput Yellow "Installing Node.js v${Version} via NVM..."
    
    try {
        & nvm install $Version
        Start-Sleep -Seconds 2
        
        & nvm use $Version
        
        & nvm alias default $Version
        
        Write-ColorOutput Green "[OK] Node.js v${Version} installed successfully"
        return $true
    } catch {
        Write-ColorOutput Red "NVM installation failed: $($_.Exception.Message)"
        return $false
    }
}

# Refresh environment variables
function Refresh-EnvironmentVariables {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Verify installation
function Verify-Installation {
    Start-Sleep -Seconds 2
    Write-ColorOutput Blue "`nVerifying installation..."
    
    try {
        $nodeVersion = & node -v 2>$null
        $npmVersion = & npm -v 2>$null
        
        if ($nodeVersion) {
            Write-ColorOutput Green "[OK] Node.js version: $nodeVersion"
            Write-ColorOutput Green "[OK] npm version: $npmVersion"
            
            $version = $nodeVersion.TrimStart('v')
            $majorVersion = [int]($version -split '\.')[0]
            if ($majorVersion -ge 18) {
                Write-ColorOutput Green "[OK] Version requirement satisfied!"
                return $true
            } else {
                Write-ColorOutput Red "[ERROR] Version still too low"
                return $false
            }
        } else {
            Write-ColorOutput Red "[ERROR] Node.js not properly installed"
            return $false
        }
    } catch {
        Write-ColorOutput Red "[ERROR] Verification failed"
        return $false
    }
}

# Show menu
function Show-Menu {
    Clear-Host
    Write-ColorOutput Blue "=================================="
    Write-ColorOutput Blue "   Node.js Version Selection"
    Write-ColorOutput Blue "=================================="
    Write-ColorOutput Green "1) Node.js v18 (LTS)"
    Write-ColorOutput Green "2) Node.js v22 (Recommended)"
    Write-ColorOutput Red "0) Exit"
    Write-ColorOutput Blue "=================================="
}

# Get latest version number
function Get-LatestVersion {
    param([string]$MajorVersion)
    
    if ($MajorVersion -eq "18") {
        return "18.19.0"
    } else {
        return "22.11.0"
    }
}

# Main function
function Main {
    Write-ColorOutput Blue "Node.js Environment Check and Installation Script"
    Write-ColorOutput Blue "=================================================="
    
    if (-not (Test-Administrator)) {
        Write-ColorOutput Yellow "NOTE: Running without administrator privileges"
        Write-ColorOutput Yellow "NVM installation may not work properly"
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            exit 1
        }
    }
    
    $versionOk = Check-CurrentNode
    
    if ($versionOk) {
        Write-ColorOutput Green "Current version meets requirements"
        $reinstall = Read-Host "Reinstall with different version? (y/N)"
        if ($reinstall -ne 'y' -and $reinstall -ne 'Y') {
            exit 0
        }
    }
    
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select version [0-2]"
        
        switch ($choice) {
            "1" { 
                $version = "18"
                $fullVersion = Get-LatestVersion -MajorVersion "18"
                break
            }
            "2" { 
                $version = "22"
                $fullVersion = Get-LatestVersion -MajorVersion "22"
                break
            }
            "0" { 
                Write-ColorOutput Red "Exiting installation"
                exit 0
            }
            default { 
                Write-ColorOutput Red "Invalid choice, please try again"
                continue
            }
        }
        break
    }
    
    Write-Host ""
    Write-ColorOutput Yellow "Select installation method:"
    Write-ColorOutput Green "1) NVM for Windows (Recommended - easy version management)"
    Write-ColorOutput Green "2) Direct MSI installer (IF NVM not well, try this)"
    $method = Read-Host "Select [1-2]"
    
    $success = $false
    if ($method -eq "1") {
        $success = Install-WithNVM -Version $version
    } else {
        $success = Install-NodeJS -Version $fullVersion -MajorVersion $version
    }
    
    if ($success) {
        Refresh-EnvironmentVariables
        
        if (Verify-Installation) {
            Write-Host ""
            Write-ColorOutput Green "=================================="
            Write-ColorOutput Green "Installation completed!"
            Write-ColorOutput Yellow "Please restart your command prompt to apply environment variables"
            Write-ColorOutput Green "=================================="
        }
    } else {
        Write-ColorOutput Yellow ""
        Write-ColorOutput Red "Installation Failed. Please manually download from:  "
        Write-ColorOutput Yellow "---> https://nodejs.org/dist"
    }
    
    Read-Host "`nPress Enter to exit"
}

# Run main function
Main