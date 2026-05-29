# Color functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args  # !!!Never Use This F*!
        # !!! Use Write-Host to send directly to console, not to output stream !!!
        # Write-Host $args -ForegroundColor $ForegroundColor
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Check current Node.js version
function Check-CurrentNode {
    try {
        # $nodeVersion = & node -v 2>$null
        # Remove error redirection to see actual errors
        $nodeVersion = & node -v 2>&1
        Write-ColorOutput Yellow "Current Node.js version: $nodeVersion"
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

# Main function
function Main {
    Write-ColorOutput Blue "Node.js Environment Check and Installation Script"
    Write-ColorOutput Blue "=================================================="
    
    # if (-not (Test-Administrator)) {
    if ($false) {
        Write-ColorOutput Yellow "NOTE: Running without administrator privileges"
        Write-ColorOutput Yellow "NVM installation may not work properly"
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            exit 1
        }
    }
    
    $versionOk = Check-CurrentNode
    
    Write-ColorOutput Red "check result ??: $versionOk"
    if ($versionOk) {
        Write-ColorOutput Green "Current version meets requirements"
        $reinstall = Read-Host "Reinstall with different version? (y/N)"
        if ($reinstall -ne 'y' -and $reinstall -ne 'Y') {
            exit 0
        }
    }
    
    Read-Host "`nPress Enter to exit"
}

# Run main function
Main
# Check-CurrentNode