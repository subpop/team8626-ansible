# FRC Team 8626 - Shared Configuration
# This file contains all configuration settings used by installer modules
#
# Usage: . $PSScriptRoot\FRCConfig.ps1

# Prevent multiple loading
if ($script:FRCConfigLoaded) { return }
$script:FRCConfigLoaded = $true

# ============================================================================
# Year-Specific Configuration Database
# ============================================================================

# Define supported years and their tool versions/URLs
$script:FRCYearConfigs = @{
    "2026" = @{
        NIToolsUrl = "https://download.ni.com/support/nipkg/products/ni-f/ni-frc-2026-game-tools/26.0/online/ni-frc-2026-game-tools_26.0_online.exe"
        REVClientUrl = "https://rhc2.revrobotics.com/download/rev-hardware-client.exe"
        REVClientVersion = "2"
        REVInstallPath = "C:\Program Files\REV Robotics\REV Hardware Client 2"
        WPILibFallbackVersion = "2026.1.1"
        NIToolsVersion = "26.0"
    }
    "2025" = @{
        NIToolsUrl = "https://download.ni.com/support/nipkg/products/ni-f/ni-frc-2025-game-tools/25.0/online/ni-frc-2025-game-tools_25.0_online.exe"
        REVClientUrl = "https://github.com/REVrobotics/REV-Software-Binaries/releases/download/rhc-1.7.5/REV-Hardware-Client-Setup-1.7.5-offline-FRC-2025-03-18.exe"
        REVClientVersion = "1"
        REVInstallPath = "C:\Program Files\REV Robotics\REV Hardware Client"
        WPILibFallbackVersion = "2025.3.2"
        NIToolsVersion = "25.0"
    }
}

# Default year (used when no -Year parameter is specified)
$script:DefaultYear = "2026"

# ============================================================================
# Configuration
# ============================================================================

$script:FRCConfig = @{
    # Temp directory for downloads
    TempPath = "C:\Temp\FRC_Downloads"

    # Current FRC Season Year (default)
    Year = $script:DefaultYear

    # Year configuration lookup
    YearConfigs = $script:FRCYearConfigs

    # NI FRC Game Tools (defaults to current year)
    # Update URL each season from: https://www.ni.com/en/support/downloads/drivers/download.frc-game-tools.html
    NIToolsUrl = $script:FRCYearConfigs[$script:DefaultYear].NIToolsUrl

    # WPILib (uses GitHub API for latest)
    WPILibInstallPath = "C:\Users\Public\wpilib"

    # Phoenix Tuner X
    PhoenixInstallPath = "C:\Program Files (x86)\CTRE\Phoenix Tuner X"

    # REV Hardware Client (defaults to current year)
    # Update URL from: https://github.com/REVrobotics/REV-Software-Binaries/releases
    REVClientUrl = $script:FRCYearConfigs[$script:DefaultYear].REVClientUrl
    REVInstallPath = "C:\Program Files\REV Robotics\REV Hardware Client"

    # PathPlanner
    PathPlannerInstallPath = "C:\Program Files\PathPlanner"

    # Raspberry Pi Imager
    RpiImagerInstallPath = "C:\Program Files\Raspberry Pi Imager"

    # Common packages to install via Chocolatey
    CommonPackages = @("git", "7zip")

    # Desktop Wallpaper
    # Update this URL if the repo or branch changes
    WallpaperUrl = "https://raw.githubusercontent.com/subpop/team8626-ansible/main/Cyber%2BSailors_Desktop.png"
    WallpaperPath = "C:\Windows\Web\Wallpaper\FRC\Cyber+Sailors_Desktop.png"

    # FRC Resource Bookmarks for Chrome and Edge
    FRCBookmarks = @(
        @{ Name = "WPILib Documentation"; Url = "https://docs.wpilib.org" }
        @{ Name = "W3Schools"; Url = "https://www.w3schools.com" }
        @{ Name = "REV Robotics Docs"; Url = "https://docs.revrobotics.com" }
        @{ Name = "CTRE Phoenix Docs"; Url = "https://v6.docs.ctr-electronics.com" }
        @{ Name = "PathPlanner Docs"; Url = "https://pathplanner.dev/home.html" }
        @{ Name = "Chief Delphi"; Url = "https://www.chiefdelphi.com" }
        @{ Name = "The Blue Alliance"; Url = "https://www.thebluealliance.com" }
        @{ Name = "FRC Q&A"; Url = "https://frc-qa.firstinspires.org" }
        @{ Name = "PhotonVision Docs"; Url = "https://docs.photonvision.org" }
    )
}

# ============================================================================
# Helper Function to Get Year-Specific Configuration
# ============================================================================

function Get-FRCYearConfig {
    <#
    .SYNOPSIS
    Retrieves configuration for a specific FRC year

    .PARAMETER Year
    The FRC year (e.g., "2026", "2025")

    .OUTPUTS
    Hashtable containing year-specific configuration (URLs, versions, etc.)
    #>
    param([string]$Year)

    if (-not $script:FRCYearConfigs.ContainsKey($Year)) {
        Write-Warning "Year $Year is not configured. Supported years: $($script:FRCYearConfigs.Keys -join ', ')"
        Write-Warning "Using default year: $script:DefaultYear"
        $Year = $script:DefaultYear
    }

    return $script:FRCYearConfigs[$Year]
}

# Export for use in other scripts
$global:FRCConfig = $script:FRCConfig
$global:Get-FRCYearConfig = ${function:Get-FRCYearConfig}

