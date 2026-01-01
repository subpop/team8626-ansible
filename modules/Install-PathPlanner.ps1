# FRC Team 8626 - PathPlanner Installer
# Installs PathPlanner via winget (Microsoft Store)
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

# ============================================================================
# Installation Function
# ============================================================================

function Install-PathPlanner {
    param([string]$Step = "1/1")
    
    Write-Step $Step "Installing PathPlanner..."

    # Check if winget is available
    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetPath) {
        Write-Warning "winget is not available. Please ensure App Installer is installed from the Microsoft Store."
        return
    }

    # Check if PathPlanner is already installed
    $installed = winget list --id 9NQBKB5DW909 --accept-source-agreements 2>$null | Select-String "9NQBKB5DW909"
    if ($installed) {
        Write-Success "PathPlanner is already installed"
    } else {
        Write-Info "Installing PathPlanner via winget (Microsoft Store)..."
        winget install --id 9NQBKB5DW909 --source msstore --accept-source-agreements --accept-package-agreements --silent | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "PathPlanner installed"
        } else {
            Write-Warning "PathPlanner installation may have failed. Please check manually."
        }
    }

    # Note: Microsoft Store apps create Start Menu shortcuts automatically
    # Desktop shortcut can be created manually by the user from the Start Menu
    Write-Info "PathPlanner is available from the Start Menu"
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - PathPlanner Installer"
    
    Install-PathPlanner -Step "1/1"
    
    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - PathPlanner (Microsoft Store)" -ForegroundColor Green
    Write-Host "  - Available from Start Menu" -ForegroundColor Green
}
