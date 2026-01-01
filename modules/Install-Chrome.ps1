# FRC Team 8626 - Google Chrome Installer
# Installs Google Chrome via Chocolatey
#
# Standalone usage: .\Install-Chrome.ps1
# Module usage: . .\Install-Chrome.ps1; Install-Chrome

#Requires -RunAsAdministrator

param(
    [switch]$Standalone
)

# Import shared modules
$modulePath = $PSScriptRoot
. "$modulePath\FRCConfig.ps1"
. "$modulePath\FRCHelpers.ps1"

# Ensure Chocolatey is available for standalone execution
if ($MyInvocation.InvocationName -notin @(".", "&") -or $Standalone) {
    . "$modulePath\Install-Chocolatey.ps1"
}

# ============================================================================
# Installation Function
# ============================================================================

function Install-Chrome {
    param([string]$Step = "1/1")
    
    Write-Step $Step "Installing Google Chrome..."

    $installed = choco list --local-only googlechrome 2>$null | Select-String "^googlechrome\s"
    if ($installed) {
        Write-Success "Google Chrome is already installed"
        return
    }

    Write-Info "Installing Google Chrome via Chocolatey..."
    choco install googlechrome -y | Out-Null
    Write-Success "Google Chrome installed"
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - Google Chrome Installer"
    
    # Ensure Chocolatey is installed first
    Install-Chocolatey -Step "1/2"
    Install-Chrome -Step "2/2"
    
    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - Google Chrome" -ForegroundColor Green
}

