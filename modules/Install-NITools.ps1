# FRC Team 8626 - NI FRC Game Tools Installer
# Installs National Instruments FRC Game Tools
#
# Standalone usage: .\Install-NITools.ps1 [-CleanupInstallers]
# Module usage: . .\Install-NITools.ps1; Install-NIGameTools

#Requires -RunAsAdministrator

param(
    [switch]$CleanupInstallers = $true,
    [switch]$Standalone
)

# Import shared modules
$modulePath = $PSScriptRoot
. "$modulePath\FRCConfig.ps1"
. "$modulePath\FRCHelpers.ps1"

# ============================================================================
# Installation Function
# ============================================================================

function Install-NIGameTools {
    param(
        [string]$Step = "1/1",
        [bool]$Cleanup = $true
    )
    
    Write-Step $Step "Installing NI FRC Game Tools..."

    # Check if NI Package Manager is actually installed by verifying executable exists
    $nipmRegPath = "HKLM:\SOFTWARE\National Instruments\NI Package Manager"
    $nipmReg = Get-ItemProperty $nipmRegPath -ErrorAction SilentlyContinue
    if ($nipmReg -and $nipmReg.Path) {
        $nipkgExe = Join-Path $nipmReg.Path "nipkg.exe"
        if (Test-Path $nipkgExe) {
            Write-Success "NI FRC Game Tools is already installed"
            return
        }
    }

    # Ensure temp directory exists
    Ensure-TempDirectory

    $installerPath = Join-Path $FRCConfig.TempPath "ni-frc-game-tools_online.exe"

    # Download online installer if not present
    if (-not (Test-Path $installerPath)) {
        Write-Info "Downloading NI FRC Game Tools online installer..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $FRCConfig.NIToolsUrl -OutFile $installerPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Success "Download complete"
    } else {
        Write-Info "Using cached installer"
    }

    # Run installer
    Write-Info "Installing NI FRC Game Tools (this takes 15-30 minutes, requires internet)..."
    Start-Process -FilePath $installerPath -ArgumentList "--acccept-eulas --passive install ni-frc-2025-game-tools" -Wait -NoNewWindow
    Write-Success "NI FRC Game Tools installed"

    # Cleanup
    if ($Cleanup) {
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned up installer files"
    }
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - NI FRC Game Tools Installer"
    
    Install-NIGameTools -Step "1/1" -Cleanup $CleanupInstallers
    
    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - NI FRC Game Tools" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: A reboot may be required." -ForegroundColor Yellow
}

