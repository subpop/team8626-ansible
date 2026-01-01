# FRC Team 8626 - Phoenix Tuner X Installer
# Installs CTRE Phoenix Tuner X from Microsoft Store
#
# Standalone usage: .\Install-Phoenix.ps1
# Module usage: . .\Install-Phoenix.ps1; Install-PhoenixTunerX

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

function Install-PhoenixTunerX {
    param([string]$Step = "1/1")
    
    Write-Step $Step "Installing Phoenix Tuner X..."

    # Check if winget is available
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Warning "winget is not available. Please install Phoenix Tuner X manually from the Microsoft Store:"
        Write-Warning "https://apps.microsoft.com/detail/9nvv4pwdw27z"
        return
    }

    # Check if already installed via winget
    $installed = winget list --id 9NVVV4PWDW27Z --source msstore 2>$null
    if ($LASTEXITCODE -eq 0 -and $installed -match "Phoenix") {
        Write-Success "Phoenix Tuner X is already installed"
        return
    }

    # Install from Microsoft Store via winget
    # https://apps.microsoft.com/detail/9nvv4pwdw27z
    Write-Info "Installing Phoenix Tuner X from Microsoft Store..."

    # Install using winget from Microsoft Store
    $result = winget install --id 9NVVV4PWDW27Z --source msstore --accept-package-agreements --accept-source-agreements --silent

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Phoenix Tuner X installed from Microsoft Store"
    } elseif ($LASTEXITCODE -eq -1978335189) {
        # Already installed
        Write-Success "Phoenix Tuner X is already installed"
    } else {
        Write-Warning "Phoenix Tuner X installation may have failed (exit code: $LASTEXITCODE)"
        Write-Warning "You can install manually from: https://apps.microsoft.com/detail/9nvv4pwdw27z"
    }
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - Phoenix Tuner X Installer"
    
    Install-PhoenixTunerX -Step "1/1"
    
    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - Phoenix Tuner X" -ForegroundColor Green
}

