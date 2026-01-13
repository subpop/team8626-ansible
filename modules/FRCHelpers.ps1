# FRC Team 8626 - Shared Helper Functions
# This file contains utility functions used by all installer modules
#
# Usage: . $PSScriptRoot\FRCHelpers.ps1

# Prevent multiple loading
if ($script:FRCHelpersLoaded) { return }
$script:FRCHelpersLoaded = $true

# ============================================================================
# Output Helper Functions
# ============================================================================

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host "[$Step] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Gray
}

function Write-Banner {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# Utility Functions
# ============================================================================

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function New-DesktopShortcut {
    param(
        [string]$TargetPath,
        [string]$ShortcutName,
        [string]$Description
    )

    $desktopPath = "C:\Users\Public\Desktop"
    $shortcutPath = Join-Path $desktopPath "$ShortcutName.lnk"

    if (Test-Path $TargetPath) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.Description = $Description
        $shortcut.Save()
        Write-Success "Created desktop shortcut: $ShortcutName"
    } else {
        Write-Info "Target not found, skipping shortcut: $ShortcutName"
    }
}

function Get-GitHubLatestRelease {
    param([string]$Repo)

    $url = "https://api.github.com/repos/$Repo/releases/latest"
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{ "User-Agent" = "PowerShell" }
        return $response
    } catch {
        Write-Warning "Failed to get latest release from GitHub: $_"
        return $null
    }
}

function Ensure-TempDirectory {
    if (-not (Test-Path $FRCConfig.TempPath)) {
        New-Item -ItemType Directory -Path $FRCConfig.TempPath -Force | Out-Null
    }
}

function Test-IsStandaloneExecution {
    # Check if the script is being run directly (not dot-sourced)
    # When dot-sourced, InvocationName is "." or "&"
    $invocationName = $MyInvocation.PSCommandPath
    $scriptName = $MyInvocation.MyCommand.Path

    # Alternative check: if the script has no parent scope with the same functions loaded
    return $MyInvocation.InvocationName -notin @(".", "&")
}

# ============================================================================
# Year Configuration Helper Functions
# ============================================================================

function Get-InstalledNIToolsYear {
    <#
    .SYNOPSIS
    Detects the currently installed NI FRC Game Tools year

    .DESCRIPTION
    Queries the NI Package Manager to determine which year of FRC Game Tools is installed

    .OUTPUTS
    String containing the year (e.g., "2026"), or $null if not installed
    #>

    $nipmRegPath = "HKLM:\SOFTWARE\National Instruments\NI Package Manager"
    $nipmReg = Get-ItemProperty $nipmRegPath -ErrorAction SilentlyContinue

    if ($nipmReg -and $nipmReg.Path) {
        $nipkgExe = Join-Path $nipmReg.Path "nipkg.exe"
        if (Test-Path $nipkgExe) {
            $installedPackages = & $nipkgExe list "ni-frc-*-game-tools" 2>$null
            if ($installedPackages -match "ni-frc-(\d{4})-game-tools") {
                return $Matches[1]
            }
        }
    }

    return $null
}

function Get-InstalledWPILibYears {
    <#
    .SYNOPSIS
    Gets a list of all installed WPILib years

    .DESCRIPTION
    Scans the WPILib installation directory for installed year folders

    .OUTPUTS
    Array of strings containing installed years (e.g., @("2025", "2026"))
    #>

    $wpilibBasePath = "C:\Users\Public\wpilib"
    if (-not (Test-Path $wpilibBasePath)) {
        return @()
    }

    $yearFolders = Get-ChildItem -Path $wpilibBasePath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{4}$' } |
        Select-Object -ExpandProperty Name

    return $yearFolders
}

# Export for use in other scripts
$global:Get-InstalledNIToolsYear = ${function:Get-InstalledNIToolsYear}
$global:Get-InstalledWPILibYears = ${function:Get-InstalledWPILibYears}

