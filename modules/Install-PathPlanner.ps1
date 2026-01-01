# FRC Team 8626 - PathPlanner Installer
# Installs PathPlanner via Chocolatey
#
# Standalone usage: .\Install-PathPlanner.ps1
# Module usage: . .\Install-PathPlanner.ps1; Install-PathPlanner

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

function Install-PathPlanner {
    param([string]$Step = "1/1")
    
    Write-Step $Step "Installing PathPlanner..."

    $installed = choco list --local-only pathplanner 2>$null | Select-String "^pathplanner\s"
    if ($installed) {
        Write-Success "PathPlanner is already installed"
    } else {
        Write-Info "Installing PathPlanner via Chocolatey..."
        choco install pathplanner -y | Out-Null
        Write-Success "PathPlanner installed"
    }

    # Create desktop shortcut
    $pathplannerExe = Join-Path $FRCConfig.PathPlannerInstallPath "PathPlanner.exe"
    New-DesktopShortcut -TargetPath $pathplannerExe -ShortcutName "PathPlanner" -Description "FRC PathPlanner - Autonomous Path Planning"
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - PathPlanner Installer"
    
    # Ensure Chocolatey is installed first
    Install-Chocolatey -Step "1/2"
    Install-PathPlanner -Step "2/2"
    
    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - PathPlanner" -ForegroundColor Green
    Write-Host "  - Desktop shortcut created" -ForegroundColor Green
}

