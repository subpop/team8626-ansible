# FRC Team 8626 - Software Installation Script
# Run this script as Administrator on each Windows 11 laptop
# PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1
#
# This script is idempotent - safe to run multiple times
#
# Individual tools can also be installed standalone:
#   .\modules\Install-WPILib.ps1
#   .\modules\Install-REVClient.ps1
#   etc.

#Requires -RunAsAdministrator

param(
    [string]$Year,
    [switch]$SkipChocolatey,
    [switch]$SkipChrome,
    [switch]$SkipNITools,
    [switch]$SkipREVClient,
    [switch]$SkipPhoenix,
    [switch]$SkipWPILib,
    [switch]$SkipPathPlanner,
    [switch]$SkipRpiImager,
    [switch]$SkipBookmarks,
    [switch]$SkipWallpaper,
    [switch]$OnlyChocolatey,
    [switch]$OnlyChrome,
    [switch]$OnlyNITools,
    [switch]$OnlyREVClient,
    [switch]$OnlyPhoenix,
    [switch]$OnlyWPILib,
    [switch]$OnlyPathPlanner,
    [switch]$OnlyRpiImager,
    [switch]$OnlyBookmarks,
    [switch]$OnlyWallpaper,
    [switch]$CleanupInstallers = $true
)

# ============================================================================
# Import Modules
# ============================================================================

$modulePath = Join-Path $PSScriptRoot "modules"

# Import shared configuration and helpers
. "$modulePath\FRCConfig.ps1"
. "$modulePath\FRCHelpers.ps1"

# Import installer modules (functions only, no auto-execution)
. "$modulePath\Install-Chocolatey.ps1"
. "$modulePath\Install-Chrome.ps1"
. "$modulePath\Install-NITools.ps1"
. "$modulePath\Install-REVClient.ps1"
. "$modulePath\Install-Phoenix.ps1"
. "$modulePath\Install-WPILib.ps1"
. "$modulePath\Install-PathPlanner.ps1"
. "$modulePath\Install-RpiImager.ps1"
. "$modulePath\Install-Bookmarks.ps1"
. "$modulePath\Install-Wallpaper.ps1"

# ============================================================================
# Year Configuration
# ============================================================================

# If no year specified, use default from config
if (-not $Year) {
    $Year = $FRCConfig.Year
    Write-Host "Using default year: $Year" -ForegroundColor Cyan
} else {
    # Validate year is supported
    $yearConfig = Get-FRCYearConfig -Year $Year
    if ($yearConfig) {
        # Update FRCConfig with selected year
        $FRCConfig.Year = $Year
        $FRCConfig.NIToolsUrl = $yearConfig.NIToolsUrl
        $FRCConfig.REVClientUrl = $yearConfig.REVClientUrl
        Write-Host "Installing FRC tools for year: $Year" -ForegroundColor Cyan
    }
}

# ============================================================================
# Windows Configuration
# ============================================================================

function Set-WindowsConfiguration {
    Write-Banner "Configuring Windows Settings"

    # Windows Defender exclusions for FRC tools
    Write-Info "Adding Windows Defender exclusions for FRC tools..."
    $exclusionPaths = @(
        "C:\Users\Public\wpilib",
        "C:\Program Files\National Instruments",
        "C:\Program Files (x86)\CTRE"
    )

    foreach ($path in $exclusionPaths) {
        $existing = (Get-MpPreference).ExclusionPath
        if ($existing -notcontains $path) {
            Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
            Write-Success "Added Defender exclusion: $path"
        } else {
            Write-Info "Exclusion already exists: $path"
        }
    }

    # Enable Developer Mode
    Write-Info "Enabling Developer Mode..."
    $devModePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    $currentValue = Get-ItemProperty -Path $devModePath -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue
    if ($currentValue.AllowDevelopmentWithoutDevLicense -ne 1) {
        Set-ItemProperty -Path $devModePath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord
        Write-Success "Developer Mode enabled"
    } else {
        Write-Info "Developer Mode already enabled"
    }

    # Disable Lenovo Vantage startup (machine-wide)
    Write-Info "Disabling Lenovo Vantage startup..."
    $lenovoDisabled = $false

    # Check HKLM Run keys for Lenovo Vantage entries
    $runKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    foreach ($runKey in $runKeys) {
        if (Test-Path $runKey) {
            $properties = Get-ItemProperty -Path $runKey -ErrorAction SilentlyContinue
            $properties.PSObject.Properties | Where-Object { $_.Name -like "*Lenovo*Vantage*" -or $_.Name -like "*VantageService*" } | ForEach-Object {
                Remove-ItemProperty -Path $runKey -Name $_.Name -ErrorAction SilentlyContinue
                Write-Success "Removed startup entry: $($_.Name)"
                $lenovoDisabled = $true
            }
        }
    }

    # Disable Lenovo Vantage scheduled tasks
    $lenovoTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { 
        $_.TaskName -like "*Lenovo*" -and ($_.TaskName -like "*Vantage*" -or $_.TaskName -like "*ImController*")
    }
    foreach ($task in $lenovoTasks) {
        if ($task.State -ne "Disabled") {
            Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue | Out-Null
            Write-Success "Disabled scheduled task: $($task.TaskName)"
            $lenovoDisabled = $true
        }
    }

    # Disable Lenovo Vantage via StartupApproved registry (affects Task Manager startup list)
    $startupApprovedPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    if (Test-Path $startupApprovedPath) {
        $properties = Get-ItemProperty -Path $startupApprovedPath -ErrorAction SilentlyContinue
        $properties.PSObject.Properties | Where-Object { $_.Name -like "*Lenovo*" -or $_.Name -like "*Vantage*" } | ForEach-Object {
            # Set disabled flag (first byte = 03 means disabled)
            $disabledValue = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
            Set-ItemProperty -Path $startupApprovedPath -Name $_.Name -Value $disabledValue -Type Binary -ErrorAction SilentlyContinue
            Write-Success "Disabled in StartupApproved: $($_.Name)"
            $lenovoDisabled = $true
        }
    }

    if (-not $lenovoDisabled) {
        Write-Info "No Lenovo Vantage startup entries found"
    }

    # Disable search highlights (keeps search bar visible)
    Write-Info "Disabling search highlights..."
    $searchSettingsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings"
    if (-not (Test-Path $searchSettingsPath)) {
        New-Item -Path $searchSettingsPath -Force | Out-Null
    }
    $currentValue = Get-ItemProperty -Path $searchSettingsPath -Name "IsDynamicSearchBoxEnabled" -ErrorAction SilentlyContinue
    if ($currentValue.IsDynamicSearchBoxEnabled -ne 0) {
        Set-ItemProperty -Path $searchSettingsPath -Name "IsDynamicSearchBoxEnabled" -Value 0 -Type DWord
        Write-Success "Search highlights disabled"
    } else {
        Write-Info "Search highlights already disabled"
    }

    # Set desktop wallpaper
    if (-not $SkipWallpaper) {
        Set-DesktopWallpaper -Step "Config"
    }
}

# ============================================================================
# Main Execution
# ============================================================================

Write-Banner "FRC Team 8626 - Software Installer"

Write-Host "This script will install the following FRC software:" -ForegroundColor White
Write-Host "  - Chocolatey package manager" -ForegroundColor White
Write-Host "  - Git and 7zip" -ForegroundColor White
Write-Host "  - Google Chrome" -ForegroundColor White
Write-Host "  - NI FRC Game Tools" -ForegroundColor White
Write-Host "  - REV Hardware Client" -ForegroundColor White
Write-Host "  - Phoenix Tuner X" -ForegroundColor White
Write-Host "  - WPILib VS Code" -ForegroundColor White
Write-Host "  - PathPlanner" -ForegroundColor White
Write-Host "  - Raspberry Pi Imager" -ForegroundColor White
Write-Host "  - Browser Bookmarks (Chrome & Edge)" -ForegroundColor White
Write-Host "  - Edge Start Page (search bar only)" -ForegroundColor White
Write-Host "  - Team Desktop Wallpaper" -ForegroundColor White
Write-Host ""

# Ensure temp directory exists
Ensure-TempDirectory

# Detect if any "Only" flag is set
$onlyMode = $OnlyChocolatey -or $OnlyChrome -or $OnlyNITools -or $OnlyREVClient -or $OnlyPhoenix -or $OnlyWPILib -or $OnlyPathPlanner -or $OnlyRpiImager -or $OnlyBookmarks -or $OnlyWallpaper

# Run installations
if ($onlyMode) {
    # Only mode - run only the specified installation(s)
    if ($OnlyChocolatey) {
        Install-Chocolatey -Step "1/2"
        Install-CommonPackages -Step "2/2"
    }
    if ($OnlyChrome) { Install-Chrome -Step "1/1" }
    if ($OnlyNITools) { Install-NIGameTools -Step "1/1" -Cleanup $CleanupInstallers -Year $Year }
    if ($OnlyREVClient) { Install-REVClient -Step "1/1" -Cleanup $CleanupInstallers -Year $Year }
    if ($OnlyPhoenix) { Install-PhoenixTunerX -Step "1/1" }
    if ($OnlyWPILib) { Install-WPILib -Step "1/1" -Cleanup $CleanupInstallers -Year $Year }
    if ($OnlyPathPlanner) { Install-PathPlanner -Step "1/1" }
    if ($OnlyRpiImager) { Install-RpiImager -Step "1/1" }
    if ($OnlyBookmarks) { 
        Install-BrowserBookmarks -Step "1/2"
        Set-EdgeStartPage -Step "2/2"
    }
    if ($OnlyWallpaper) { Set-DesktopWallpaper -Step "1/1" }
} else {
    # Normal mode - run all installations except skipped ones
    if (-not $SkipChocolatey) { Install-Chocolatey -Step "1/11" }
    if (-not $SkipChocolatey) { Install-CommonPackages -Step "2/11" }
    if (-not $SkipChrome) { Install-Chrome -Step "3/11" }
    if (-not $SkipNITools) { Install-NIGameTools -Step "4/11" -Cleanup $CleanupInstallers -Year $Year }
    if (-not $SkipREVClient) { Install-REVClient -Step "5/11" -Cleanup $CleanupInstallers -Year $Year }
    if (-not $SkipPhoenix) { Install-PhoenixTunerX -Step "6/11" }
    if (-not $SkipWPILib) { Install-WPILib -Step "7/11" -Cleanup $CleanupInstallers -Year $Year }
    if (-not $SkipPathPlanner) { Install-PathPlanner -Step "8/11" }
    if (-not $SkipRpiImager) { Install-RpiImager -Step "9/11" }
    if (-not $SkipBookmarks) { 
        Install-BrowserBookmarks -Step "10/11"
        Set-EdgeStartPage -Step "11/11"
    }

    # Configure Windows settings
    Set-WindowsConfiguration
}

# Check if reboot is required
$rebootRequired = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) -ne $null

Write-Banner "Installation Complete!"

Write-Host "Installed FRC $Year software:" -ForegroundColor White
Write-Host "  - Google Chrome" -ForegroundColor Green
Write-Host "  - NI FRC Game Tools $Year" -ForegroundColor Green
Write-Host "  - REV Hardware Client (FRC $Year)" -ForegroundColor Green
Write-Host "  - Phoenix Tuner X" -ForegroundColor Green
Write-Host "  - WPILib VS Code $Year" -ForegroundColor Green
Write-Host "  - PathPlanner" -ForegroundColor Green
Write-Host "  - Raspberry Pi Imager" -ForegroundColor Green
Write-Host "  - FRC Browser Bookmarks" -ForegroundColor Green
Write-Host "  - Team Desktop Wallpaper" -ForegroundColor Green
Write-Host ""
Write-Host "Desktop shortcuts have been created." -ForegroundColor White
Write-Host "FRC Resources bookmarks added to Chrome and Edge." -ForegroundColor White
Write-Host "Edge start page configured (search bar only)." -ForegroundColor White
Write-Host "Team wallpaper has been applied to all user profiles." -ForegroundColor White

if ($rebootRequired) {
    Write-Host ""
    Write-Host "*** REBOOT REQUIRED ***" -ForegroundColor Red
    Write-Host "Please restart this computer to complete the installation." -ForegroundColor Yellow
}

Write-Host ""
