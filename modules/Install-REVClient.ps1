# FRC Team 8626 - REV Hardware Client Installer
# Installs REV Robotics Hardware Client
#
# Standalone usage: .\Install-REVClient.ps1 [-CleanupInstallers]
# Module usage: . .\Install-REVClient.ps1; Install-REVClient

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

function Install-REVClient {
    param(
        [string]$Step = "1/1",
        [bool]$Cleanup = $true,
        [string]$Year = $null
    )

    # Resolve year (use parameter, fall back to config)
    if (-not $Year) {
        $Year = $FRCConfig.Year
    }

    # Get year-specific configuration
    $yearConfig = Get-FRCYearConfig -Year $Year

    Write-Step $Step "Installing REV Hardware Client (for $Year season)..."

    # Check if already installed
    $revExe = Join-Path $FRCConfig.REVInstallPath "REV Hardware Client.exe"
    if (Test-Path $revExe) {
        Write-Success "REV Hardware Client is already installed"
        New-DesktopShortcut -TargetPath $revExe -ShortcutName "REV Hardware Client" -Description "REV Robotics Hardware Client"
        return
    }

    # Ensure temp directory exists
    Ensure-TempDirectory

    $installerPath = Join-Path $FRCConfig.TempPath "REV-Hardware-Client-Setup.exe"

    # Download installer if not present
    if (-not (Test-Path $installerPath)) {
        Write-Info "Downloading REV Hardware Client..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $FRCConfig.REVClientUrl -OutFile $installerPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Success "Download complete"
    } else {
        Write-Info "Using cached installer"
    }

    # Run installer
    Write-Info "Installing REV Hardware Client..."
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -NoNewWindow
    Write-Success "REV Hardware Client installed"

    # Create desktop shortcut
    New-DesktopShortcut -TargetPath $revExe -ShortcutName "REV Hardware Client" -Description "REV Robotics Hardware Client"

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
    Write-Banner "FRC Team 8626 - REV Hardware Client Installer"

    $installYear = if ($Year) { $Year } else { $FRCConfig.Year }
    Install-REVClient -Step "1/1" -Cleanup $CleanupInstallers -Year $installYear

    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - REV Hardware Client (FRC $installYear)" -ForegroundColor Green
    Write-Host "  - Desktop shortcut created" -ForegroundColor Green
}

