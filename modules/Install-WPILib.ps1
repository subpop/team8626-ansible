# FRC Team 8626 - WPILib Installer
# Installs WPILib VS Code and FRC Development Tools
#
# Standalone usage: .\Install-WPILib.ps1 [-CleanupInstallers]
# Module usage: . .\Install-WPILib.ps1; Install-WPILib

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

function Install-WPILib {
    param(
        [string]$Step = "1/1",
        [bool]$Cleanup = $true,
        [string]$Year = $null
    )

    Write-Step $Step "Installing WPILib..."

    # Resolve year (use parameter, fall back to config)
    if (-not $Year) {
        $Year = $FRCConfig.Year
    }

    # Get year-specific configuration
    $yearConfig = Get-FRCYearConfig -Year $Year

    $wpilibPath = Join-Path $FRCConfig.WPILibInstallPath $Year
    if (Test-Path $wpilibPath) {
        Write-Success "WPILib $Year is already installed"
        $vscodeExe = Join-Path $wpilibPath "vscode\Code.exe"
        New-DesktopShortcut -TargetPath $vscodeExe -ShortcutName "WPILib VS Code $Year" -Description "WPILib VS Code $Year - FRC Development Environment"
        return
    }

    # Ensure temp directory exists
    Ensure-TempDirectory

    # Get latest release version from GitHub
    Write-Info "Fetching latest WPILib release..."
    $release = Get-GitHubLatestRelease -Repo "wpilibsuite/allwpilib"

    if ($release) {
        $version = $release.tag_name -replace '^v', ''
    } else {
        Write-Warning "Could not fetch latest version, using fallback"
        $version = $yearConfig.WPILibFallbackVersion
    }

    # Download from WPILib packages server (not GitHub releases)
    $isoUrl = "https://packages.wpilib.workers.dev/installer/v$version/Win64/WPILib_Windows-$version.iso"
    $isoPath = Join-Path $FRCConfig.TempPath "WPILib_Windows.iso"

    # Download ISO if not present
    if (-not (Test-Path $isoPath)) {
        Write-Info "Downloading WPILib $version (this may take a while)..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $isoUrl -OutFile $isoPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Success "Download complete"
    } else {
        Write-Info "Using cached ISO file"
    }

    # Mount ISO
    Write-Info "Mounting ISO..."
    $mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter

    # Run installer
    Write-Info "Installing WPILib..."
    $installerPath = "${driveLetter}:\WPILibInstaller.exe"
    Start-Process -FilePath $installerPath -Wait -NoNewWindow
    Write-Success "WPILib installed"

    # Unmount ISO
    Write-Info "Unmounting ISO..."
    Dismount-DiskImage -ImagePath $isoPath | Out-Null

    # Create desktop shortcut
    $vscodeExe = Join-Path $wpilibPath "vscode\Code.exe"
    New-DesktopShortcut -TargetPath $vscodeExe -ShortcutName "WPILib VS Code $Year" -Description "WPILib VS Code $Year - FRC Development Environment"

    # Cleanup
    if ($Cleanup) {
        Remove-Item $isoPath -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned up installer files"
    }
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - WPILib Installer"

    $installYear = if ($Year) { $Year } else { $FRCConfig.Year }
    Install-WPILib -Step "1/1" -Cleanup $CleanupInstallers -Year $installYear

    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - WPILib VS Code $installYear" -ForegroundColor Green
    Write-Host "  - Desktop shortcut created" -ForegroundColor Green
}

