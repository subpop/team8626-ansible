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

    # Determine install path based on year config
    $revInstallPath = if ($yearConfig.REVInstallPath) {
        $yearConfig.REVInstallPath
    } else {
        $FRCConfig.REVInstallPath  # Fallback to default
    }

    # Determine version for messaging
    $revVersion = if ($yearConfig.REVClientVersion) {
        $yearConfig.REVClientVersion
    } else {
        "1"  # Default to RHC1
    }

    Write-Step $Step "Installing REV Hardware Client $revVersion (for $Year season)..."

    # Check if already installed - use year-specific path
    $revExe = Join-Path $revInstallPath "REV Hardware Client.exe"
    if (Test-Path $revExe) {
        Write-Success "REV Hardware Client $revVersion is already installed"
        New-DesktopShortcut -TargetPath $revExe -ShortcutName "REV Hardware Client $revVersion" -Description "REV Robotics Hardware Client $revVersion"
        return
    }

    # Ensure temp directory exists
    Ensure-TempDirectory

    # Use year-specific filename to avoid conflicts when downloading different versions
    $installerFileName = "REV-Hardware-Client-Setup-v$revVersion.exe"
    $installerPath = Join-Path $FRCConfig.TempPath $installerFileName

    # Download installer if not present
    if (-not (Test-Path $installerPath)) {
        Write-Info "Downloading REV Hardware Client $revVersion..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $FRCConfig.REVClientUrl -OutFile $installerPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Success "Download complete"
    } else {
        Write-Info "Using cached installer"
    }

    # Run installer
    Write-Info "Installing REV Hardware Client $revVersion..."
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -NoNewWindow
    Write-Success "REV Hardware Client $revVersion installed"

    # Create desktop shortcut with version in name
    New-DesktopShortcut -TargetPath $revExe -ShortcutName "REV Hardware Client $revVersion" -Description "REV Robotics Hardware Client $revVersion"

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

    $yearConfig = Get-FRCYearConfig -Year $installYear
    $revVersion = if ($yearConfig.REVClientVersion) { $yearConfig.REVClientVersion } else { "1" }

    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - REV Hardware Client $revVersion (FRC $installYear)" -ForegroundColor Green
    Write-Host "  - Desktop shortcut created" -ForegroundColor Green
}

