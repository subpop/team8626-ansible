# FRC Team 8626 - Raspberry Pi Imager Installer
# Installs Raspberry Pi Imager via Chocolatey
#
# Standalone usage: .\Install-RpiImager.ps1
# Module usage: . .\Install-RpiImager.ps1; Install-RpiImager

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

function Install-RpiImager {
    param([string]$Step = "1/1")
    
    Write-Step $Step "Installing Raspberry Pi Imager..."

    $installed = choco list rpi-imager 2>$null | Select-String "^rpi-imager\s"
    if ($installed) {
        Write-Success "Raspberry Pi Imager is already installed"
    } else {
        Write-Info "Installing Raspberry Pi Imager via Chocolatey..."
        choco install rpi-imager -y | Out-Null
        Write-Success "Raspberry Pi Imager installed"
    }

    # Create desktop shortcut
    $rpiImagerExe = Join-Path $FRCConfig.RpiImagerInstallPath "rpi-imager.exe"
    New-DesktopShortcut -TargetPath $rpiImagerExe -ShortcutName "Raspberry Pi Imager" -Description "Raspberry Pi Imager - Create SD Card Images"
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - Raspberry Pi Imager Installer"
    
    # Ensure Chocolatey is installed first
    Install-Chocolatey -Step "1/2"
    Install-RpiImager -Step "2/2"
    
    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - Raspberry Pi Imager" -ForegroundColor Green
    Write-Host "  - Desktop shortcut created" -ForegroundColor Green
}

