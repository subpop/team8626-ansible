# FRC Team 8626 - NI FRC Game Tools Installer
# Installs National Instruments FRC Game Tools
#
# Standalone usage: .\Install-NITools.ps1 [-CleanupInstallers]
# Module usage: . .\Install-NITools.ps1; Install-NIGameTools

#Requires -RunAsAdministrator

param(
    [switch]$CleanupInstallers = $true,
    [switch]$Standalone,
    [string]$Year
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
        [bool]$Cleanup = $true,
        [string]$Year = $null
    )

    Write-Step $Step "Installing NI FRC Game Tools..."

    # Resolve year (use parameter, fall back to config)
    if (-not $Year) {
        $Year = $FRCConfig.Year
    }

    # Get year-specific configuration
    $yearConfig = Get-FRCYearConfig -Year $Year

    # Check for existing installation
    $nipmRegPath = "HKLM:\SOFTWARE\National Instruments\NI Package Manager"
    $nipmReg = Get-ItemProperty $nipmRegPath -ErrorAction SilentlyContinue
    $nipkgExe = $null
    $installedYear = $null

    if ($nipmReg -and $nipmReg.Path) {
        $nipkgExe = Join-Path $nipmReg.Path "nipkg.exe"
        if (Test-Path $nipkgExe) {
            Write-Info "Detecting installed NI FRC Game Tools version..."
            $installedPackages = & $nipkgExe list 2>$null | Where-Object { $_ -match "ni-frc-.*-game-tools" }

            if ($installedPackages -match "ni-frc-(\d{4})-game-tools") {
                $installedYear = $Matches[1]
                Write-Info "Found NI FRC Game Tools $installedYear"
            }
        }
    }

    # If we found an installed version, check for conflicts
    if ($installedYear) {
        if ($installedYear -ne $Year) {
            Write-Warning "================================================"
            Write-Warning "NI FRC Game Tools YEAR CONFLICT DETECTED"
            Write-Warning "================================================"
            Write-Warning "Currently installed: $installedYear"
            Write-Warning "Requested installation: $Year"
            Write-Warning ""
            Write-Warning "NI FRC Game Tools only supports ONE year at a time."
            Write-Warning "Installing $Year will REPLACE the existing $installedYear installation."
            Write-Warning ""

            $response = Read-Host "Continue with replacement? (yes/no)"
            if ($response -ne "yes" -and $response -ne "y") {
                Write-Warning "Installation cancelled by user"
                return
            }
            Write-Info "Proceeding with installation of $Year NI Tools..."
        } else {
            Write-Success "NI FRC Game Tools $Year is already installed"
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
    Write-Info "Installing NI FRC Game Tools $Year (this takes 15-30 minutes, requires internet)..."
    Start-Process -FilePath $installerPath -ArgumentList "--prevent-reboot" -Wait -NoNewWindow
    Write-Success "NI FRC Game Tools $Year installed"

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

    $installYear = if ($Year) { $Year } else { $FRCConfig.Year }
    Install-NIGameTools -Step "1/1" -Cleanup $CleanupInstallers -Year $installYear

    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - NI FRC Game Tools $installYear" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: A reboot may be required." -ForegroundColor Yellow
}

