# FRC Team 8626 - Desktop Wallpaper Installer
# Sets team desktop wallpaper for all users
#
# Standalone usage: .\Install-Wallpaper.ps1
# Module usage: . .\Install-Wallpaper.ps1; Set-DesktopWallpaper

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

function Set-DesktopWallpaper {
    param([string]$Step = "1/1")
    
    Write-Step $Step "Setting desktop wallpaper..."

    # Create directory for wallpaper if it doesn't exist
    $wallpaperDir = Split-Path $FRCConfig.WallpaperPath -Parent
    if (-not (Test-Path $wallpaperDir)) {
        New-Item -ItemType Directory -Path $wallpaperDir -Force | Out-Null
    }

    # Download wallpaper if not already present
    if (-not (Test-Path $FRCConfig.WallpaperPath)) {
        Write-Info "Downloading team wallpaper..."
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $FRCConfig.WallpaperUrl -OutFile $FRCConfig.WallpaperPath -UseBasicParsing
            $ProgressPreference = 'Continue'
            Write-Success "Wallpaper downloaded"
        } catch {
            Write-Warning "Failed to download wallpaper: $_"
            return
        }
    } else {
        Write-Info "Wallpaper already exists"
    }

    # Set wallpaper for all users via registry (Default User profile)
    try {
        # Set wallpaper style (2 = Stretch, 10 = Fill, 6 = Fit, 0 = Center, 22 = Span)
        $wallpaperStyle = "10"  # Fill
        $tileWallpaper = "0"

        # Update Default User profile (affects new users)
        $defaultUserNtUser = "C:\Users\Default\NTUSER.DAT"
        if (Test-Path $defaultUserNtUser) {
            reg load "HKU\DefaultUser" $defaultUserNtUser 2>$null
            reg add "HKU\DefaultUser\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d $FRCConfig.WallpaperPath /f 2>$null
            reg add "HKU\DefaultUser\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d $wallpaperStyle /f 2>$null
            reg add "HKU\DefaultUser\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d $tileWallpaper /f 2>$null
            reg unload "HKU\DefaultUser" 2>$null
        }

        # Update all existing user profiles
        $userProfiles = Get-ChildItem "C:\Users" -Directory | Where-Object {
            $_.Name -notin @("Public", "Default", "Default User", "All Users") -and
            -not $_.Name.StartsWith(".")
        }

        foreach ($userProfile in $userProfiles) {
            $ntUserPath = Join-Path $userProfile.FullName "NTUSER.DAT"
            if (Test-Path $ntUserPath) {
                $sid = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
                    Where-Object { $_.ProfileImagePath -eq $userProfile.FullName }).PSChildName

                if ($sid) {
                    # Check if profile is loaded (user logged in)
                    if (Test-Path "Registry::HKU\$sid") {
                        Set-ItemProperty -Path "Registry::HKU\$sid\Control Panel\Desktop" -Name "Wallpaper" -Value $FRCConfig.WallpaperPath -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path "Registry::HKU\$sid\Control Panel\Desktop" -Name "WallpaperStyle" -Value $wallpaperStyle -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path "Registry::HKU\$sid\Control Panel\Desktop" -Name "TileWallpaper" -Value $tileWallpaper -ErrorAction SilentlyContinue
                    } else {
                        # Load the user's hive and update
                        reg load "HKU\TempUser" $ntUserPath 2>$null
                        reg add "HKU\TempUser\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d $FRCConfig.WallpaperPath /f 2>$null
                        reg add "HKU\TempUser\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d $wallpaperStyle /f 2>$null
                        reg add "HKU\TempUser\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d $tileWallpaper /f 2>$null
                        reg unload "HKU\TempUser" 2>$null
                    }
                }
            }
        }

        # Update current user's wallpaper immediately using SystemParametersInfo
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@ -ErrorAction SilentlyContinue

        # SPI_SETDESKWALLPAPER = 0x0014, SPIF_UPDATEINIFILE = 0x01, SPIF_SENDCHANGE = 0x02
        [Wallpaper]::SystemParametersInfo(0x0014, 0, $FRCConfig.WallpaperPath, 0x03) | Out-Null

        Write-Success "Desktop wallpaper set for all users"
    } catch {
        Write-Warning "Failed to set wallpaper: $_"
    }
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - Desktop Wallpaper Installer"
    
    Set-DesktopWallpaper -Step "1/1"
    
    Write-Banner "Installation Complete!"
    Write-Host "Applied:" -ForegroundColor White
    Write-Host "  - Team desktop wallpaper for all users" -ForegroundColor Green
}

