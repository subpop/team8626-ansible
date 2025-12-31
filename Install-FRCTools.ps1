# FRC Team 8626 - Software Installation Script
# Run this script as Administrator on each Windows 11 laptop
# PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1
#
# This script is idempotent - safe to run multiple times

#Requires -RunAsAdministrator

param(
    [switch]$SkipChocolatey,
    [switch]$SkipChrome,
    [switch]$SkipNITools,
    [switch]$SkipREVClient,
    [switch]$SkipPhoenix,
    [switch]$SkipWPILib,
    [switch]$SkipPathPlanner,
    [switch]$SkipBookmarks,
    [switch]$SkipWallpaper,
    [switch]$OnlyChocolatey,
    [switch]$OnlyChrome,
    [switch]$OnlyNITools,
    [switch]$OnlyREVClient,
    [switch]$OnlyPhoenix,
    [switch]$OnlyWPILib,
    [switch]$OnlyPathPlanner,
    [switch]$OnlyBookmarks,
    [switch]$OnlyWallpaper,
    [switch]$CleanupInstallers = $true
)

# ============================================================================
# Configuration
# ============================================================================

$Config = @{
    # Temp directory for downloads
    TempPath = "C:\Temp\FRC_Downloads"

    # FRC Season Year
    Year = "2025"

    # NI FRC Game Tools
    # Update URL each season from: https://www.ni.com/en/support/downloads/drivers/download.frc-game-tools.html
    NIToolsUrl = "https://download.ni.com/support/nipkg/products/ni-f/ni-frc-2025-game-tools/25.0/online/ni-frc-2025-game-tools_25.0_online.exe"

    # WPILib (uses GitHub API for latest)
    WPILibInstallPath = "C:\Users\Public\wpilib"

    # Phoenix Tuner X
    PhoenixInstallPath = "C:\Program Files (x86)\CTRE\Phoenix Tuner X"

    # REV Hardware Client
    # Update URL from: https://github.com/REVrobotics/REV-Software-Binaries/releases
    REVClientUrl = "https://github.com/REVrobotics/REV-Software-Binaries/releases/download/rhc-1.7.5/REV-Hardware-Client-Setup-1.7.5-offline-FRC-2025-03-18.exe"
    REVInstallPath = "C:\Program Files\REV Robotics\REV Hardware Client"

    # PathPlanner
    PathPlannerInstallPath = "C:\Program Files\PathPlanner"

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
# Helper Functions
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

# ============================================================================
# Installation Functions
# ============================================================================

function Install-Chocolatey {
    Write-Step "1/9" "Installing Chocolatey package manager..."

    if (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
        Write-Success "Chocolatey is already installed"
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        return
    }

    Write-Info "Downloading and installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    # Enable global confirmation
    choco feature enable -n=allowGlobalConfirmation | Out-Null

    Write-Success "Chocolatey installed successfully"
}

function Install-CommonPackages {
    Write-Step "2/9" "Installing common utilities (Git, 7zip)..."

    foreach ($package in $Config.CommonPackages) {
        $installed = choco list --local-only $package 2>$null | Select-String "^$package\s"
        if ($installed) {
            Write-Success "$package is already installed"
        } else {
            Write-Info "Installing $package..."
            choco install $package -y | Out-Null
            Write-Success "$package installed"
        }
    }
}

function Install-Chrome {
    Write-Step "3/9" "Installing Google Chrome..."

    $installed = choco list --local-only googlechrome 2>$null | Select-String "^googlechrome\s"
    if ($installed) {
        Write-Success "Google Chrome is already installed"
        return
    }

    Write-Info "Installing Google Chrome via Chocolatey..."
    choco install googlechrome -y | Out-Null
    Write-Success "Google Chrome installed"
}

function Install-NIGameTools {
    Write-Step "4/9" "Installing NI FRC Game Tools..."

    # Check if already installed via registry
    $niInstalled = Get-ItemProperty "HKLM:\SOFTWARE\National Instruments\Common\Installer" -ErrorAction SilentlyContinue
    if ($niInstalled) {
        Write-Success "NI FRC Game Tools is already installed"
        return
    }

    # Ensure temp directory exists
    if (-not (Test-Path $Config.TempPath)) {
        New-Item -ItemType Directory -Path $Config.TempPath -Force | Out-Null
    }

    $installerPath = Join-Path $Config.TempPath "ni-frc-game-tools_online.exe"

    # Download online installer if not present
    if (-not (Test-Path $installerPath)) {
        Write-Info "Downloading NI FRC Game Tools online installer..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Config.NIToolsUrl -OutFile $installerPath -UseBasicParsing
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
    if ($CleanupInstallers) {
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned up installer files"
    }
}

function Install-REVClient {
    Write-Step "5/9" "Installing REV Hardware Client..."

    # Check if already installed
    $revExe = Join-Path $Config.REVInstallPath "REV Hardware Client.exe"
    if (Test-Path $revExe) {
        Write-Success "REV Hardware Client is already installed"
        New-DesktopShortcut -TargetPath $revExe -ShortcutName "REV Hardware Client" -Description "REV Robotics Hardware Client"
        return
    }

    # Ensure temp directory exists
    if (-not (Test-Path $Config.TempPath)) {
        New-Item -ItemType Directory -Path $Config.TempPath -Force | Out-Null
    }

    $installerPath = Join-Path $Config.TempPath "REV-Hardware-Client-Setup.exe"

    # Download installer if not present
    if (-not (Test-Path $installerPath)) {
        Write-Info "Downloading REV Hardware Client..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Config.REVClientUrl -OutFile $installerPath -UseBasicParsing
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
    if ($CleanupInstallers) {
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned up installer files"
    }
}

function Install-PhoenixTunerX {
    Write-Step "6/9" "Installing Phoenix Tuner X..."

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

function Install-WPILib {
    Write-Step "7/9" "Installing WPILib..."

    $wpilibPath = Join-Path $Config.WPILibInstallPath $Config.Year
    if (Test-Path $wpilibPath) {
        Write-Success "WPILib $($Config.Year) is already installed"
        $vscodeExe = Join-Path $wpilibPath "vscode\Code.exe"
        New-DesktopShortcut -TargetPath $vscodeExe -ShortcutName "WPILib VS Code $($Config.Year)" -Description "WPILib VS Code $($Config.Year) - FRC Development Environment"
        return
    }

    # Ensure temp directory exists
    if (-not (Test-Path $Config.TempPath)) {
        New-Item -ItemType Directory -Path $Config.TempPath -Force | Out-Null
    }

    # Get latest release version from GitHub
    Write-Info "Fetching latest WPILib release..."
    $release = Get-GitHubLatestRelease -Repo "wpilibsuite/allwpilib"

    if ($release) {
        $version = $release.tag_name -replace '^v', ''
    } else {
        Write-Warning "Could not fetch latest version, using default"
        $version = "2025.3.2"
    }

    # Download from WPILib packages server (not GitHub releases)
    $isoUrl = "https://packages.wpilib.workers.dev/installer/v$version/Win64/WPILib_Windows-$version.iso"
    $isoPath = Join-Path $Config.TempPath "WPILib_Windows.iso"

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
    Write-Info "Installing WPILib (this takes 10-20 minutes)..."
    $installerPath = "${driveLetter}:\WPILibInstaller.exe"
    Start-Process -FilePath $installerPath -ArgumentList "--mode unattended --installAllUsers true" -Wait -NoNewWindow
    Write-Success "WPILib installed"

    # Unmount ISO
    Write-Info "Unmounting ISO..."
    Dismount-DiskImage -ImagePath $isoPath | Out-Null

    # Create desktop shortcut
    $vscodeExe = Join-Path $wpilibPath "vscode\Code.exe"
    New-DesktopShortcut -TargetPath $vscodeExe -ShortcutName "WPILib VS Code $($Config.Year)" -Description "WPILib VS Code $($Config.Year) - FRC Development Environment"

    # Cleanup
    if ($CleanupInstallers) {
        Remove-Item $isoPath -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned up installer files"
    }
}

function Install-PathPlanner {
    Write-Step "8/9" "Installing PathPlanner..."

    $installed = choco list --local-only pathplanner 2>$null | Select-String "^pathplanner\s"
    if ($installed) {
        Write-Success "PathPlanner is already installed"
    } else {
        Write-Info "Installing PathPlanner via Chocolatey..."
        choco install pathplanner -y | Out-Null
        Write-Success "PathPlanner installed"
    }

    # Create desktop shortcut
    $pathplannerExe = Join-Path $Config.PathPlannerInstallPath "PathPlanner.exe"
    New-DesktopShortcut -TargetPath $pathplannerExe -ShortcutName "PathPlanner" -Description "FRC PathPlanner - Autonomous Path Planning"
}

function Install-BrowserBookmarks {
    Write-Step "9/9" "Installing FRC browser bookmarks..."

    # Browser configurations (Chromium-based browsers share the same bookmark format)
    $browsers = @(
        @{ Name = "Chrome"; ProfilePath = "Google\Chrome\User Data" }
        @{ Name = "Edge"; ProfilePath = "Microsoft\Edge\User Data" }
    )

    # Get all user profile directories
    $userProfiles = Get-ChildItem "C:\Users" -Directory | Where-Object {
        $_.Name -notin @("Public", "Default", "Default User", "All Users") -and
        -not $_.Name.StartsWith(".")
    }

    $bookmarksAdded = $false

    foreach ($userProfile in $userProfiles) {
        foreach ($browser in $browsers) {
            $browserDataPath = Join-Path $userProfile.FullName "AppData\Local\$($browser.ProfilePath)"
            $bookmarkFile = Join-Path $browserDataPath "Default\Bookmarks"
            $bookmarkDir = Split-Path $bookmarkFile -Parent

            # Skip if browser profile doesn't exist (browser never launched)
            if (-not (Test-Path $bookmarkDir)) {
                continue
            }

            try {
                # Check if bookmark file is locked (browser is running)
                $fileStream = $null
                if (Test-Path $bookmarkFile) {
                    try {
                        $fileStream = [System.IO.File]::Open($bookmarkFile, 'Open', 'ReadWrite', 'None')
                        $fileStream.Close()
                    } catch {
                        Write-Info "Skipping $($browser.Name) for $($userProfile.Name) - browser may be running"
                        continue
                    }
                }

                # Load existing bookmarks or create new structure
                if (Test-Path $bookmarkFile) {
                    $bookmarkData = Get-Content $bookmarkFile -Raw | ConvertFrom-Json
                } else {
                    # Create new bookmark structure
                    $bookmarkData = [PSCustomObject]@{
                        checksum = ""
                        roots = [PSCustomObject]@{
                            bookmark_bar = [PSCustomObject]@{
                                children = @()
                                date_added = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)
                                date_last_used = "0"
                                date_modified = "0"
                                guid = [guid]::NewGuid().ToString()
                                id = "1"
                                name = "Bookmarks bar"
                                type = "folder"
                            }
                            other = [PSCustomObject]@{
                                children = @()
                                date_added = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)
                                date_last_used = "0"
                                date_modified = "0"
                                guid = [guid]::NewGuid().ToString()
                                id = "2"
                                name = "Other bookmarks"
                                type = "folder"
                            }
                            synced = [PSCustomObject]@{
                                children = @()
                                date_added = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)
                                date_last_used = "0"
                                date_modified = "0"
                                guid = [guid]::NewGuid().ToString()
                                id = "3"
                                name = "Mobile bookmarks"
                                type = "folder"
                            }
                        }
                        version = 1
                    }
                }

                # Check if FRC Resources folder already exists
                $bookmarkBar = $bookmarkData.roots.bookmark_bar
                $frcFolder = $bookmarkBar.children | Where-Object { $_.name -eq "FRC Resources" -and $_.type -eq "folder" }

                if ($frcFolder) {
                    Write-Info "$($browser.Name) bookmarks already configured for $($userProfile.Name)"
                    continue
                }

                # Get the next available ID
                $maxId = 3
                function Get-MaxId($node) {
                    if ($node.id) {
                        $id = [int]$node.id
                        if ($id -gt $script:maxId) { $script:maxId = $id }
                    }
                    if ($node.children) {
                        foreach ($child in $node.children) {
                            Get-MaxId $child
                        }
                    }
                }
                Get-MaxId $bookmarkData.roots.bookmark_bar
                Get-MaxId $bookmarkData.roots.other
                if ($bookmarkData.roots.synced) { Get-MaxId $bookmarkData.roots.synced }

                $nextId = $maxId + 1
                $timestamp = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)

                # Create FRC Resources folder with bookmarks
                $frcBookmarkChildren = @()
                foreach ($bookmark in $Config.FRCBookmarks) {
                    $nextId++
                    $frcBookmarkChildren += [PSCustomObject]@{
                        date_added = $timestamp
                        date_last_used = "0"
                        guid = [guid]::NewGuid().ToString()
                        id = [string]$nextId
                        name = $bookmark.Name
                        type = "url"
                        url = $bookmark.Url
                    }
                }

                $nextId++
                $frcResourcesFolder = [PSCustomObject]@{
                    children = $frcBookmarkChildren
                    date_added = $timestamp
                    date_last_used = "0"
                    date_modified = $timestamp
                    guid = [guid]::NewGuid().ToString()
                    id = [string]$nextId
                    name = "FRC Resources"
                    type = "folder"
                }

                # Add FRC Resources folder to bookmark bar
                $bookmarkBar.children = @($frcResourcesFolder) + @($bookmarkBar.children)

                # Update date_modified on bookmark bar
                $bookmarkBar.date_modified = $timestamp

                # Save bookmarks
                $bookmarkJson = $bookmarkData | ConvertTo-Json -Depth 20
                Set-Content -Path $bookmarkFile -Value $bookmarkJson -Encoding UTF8

                Write-Success "Added FRC bookmarks to $($browser.Name) for $($userProfile.Name)"
                $bookmarksAdded = $true

            } catch {
                Write-Info "Could not update $($browser.Name) bookmarks for $($userProfile.Name): $_"
            }
        }
    }

    if (-not $bookmarksAdded) {
        Write-Info "No browser profiles found or all already configured"
    }
}

function Set-DesktopWallpaper {
    Write-Info "Setting desktop wallpaper..."

    # Create directory for wallpaper if it doesn't exist
    $wallpaperDir = Split-Path $Config.WallpaperPath -Parent
    if (-not (Test-Path $wallpaperDir)) {
        New-Item -ItemType Directory -Path $wallpaperDir -Force | Out-Null
    }

    # Download wallpaper if not already present
    if (-not (Test-Path $Config.WallpaperPath)) {
        Write-Info "Downloading team wallpaper..."
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $Config.WallpaperUrl -OutFile $Config.WallpaperPath -UseBasicParsing
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
            reg add "HKU\DefaultUser\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d $Config.WallpaperPath /f 2>$null
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
                        Set-ItemProperty -Path "Registry::HKU\$sid\Control Panel\Desktop" -Name "Wallpaper" -Value $Config.WallpaperPath -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path "Registry::HKU\$sid\Control Panel\Desktop" -Name "WallpaperStyle" -Value $wallpaperStyle -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path "Registry::HKU\$sid\Control Panel\Desktop" -Name "TileWallpaper" -Value $tileWallpaper -ErrorAction SilentlyContinue
                    } else {
                        # Load the user's hive and update
                        reg load "HKU\TempUser" $ntUserPath 2>$null
                        reg add "HKU\TempUser\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d $Config.WallpaperPath /f 2>$null
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
        [Wallpaper]::SystemParametersInfo(0x0014, 0, $Config.WallpaperPath, 0x03) | Out-Null

        Write-Success "Desktop wallpaper set for all users"
    } catch {
        Write-Warning "Failed to set wallpaper: $_"
    }
}

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

    # Set desktop wallpaper
    if (-not $SkipWallpaper) {
        Set-DesktopWallpaper
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
Write-Host "  - Browser Bookmarks (Chrome & Edge)" -ForegroundColor White
Write-Host "  - Team Desktop Wallpaper" -ForegroundColor White
Write-Host ""

# Ensure temp directory exists
if (-not (Test-Path $Config.TempPath)) {
    New-Item -ItemType Directory -Path $Config.TempPath -Force | Out-Null
}

# Detect if any "Only" flag is set
$onlyMode = $OnlyChocolatey -or $OnlyChrome -or $OnlyNITools -or $OnlyREVClient -or $OnlyPhoenix -or $OnlyWPILib -or $OnlyPathPlanner -or $OnlyBookmarks -or $OnlyWallpaper

# Run installations
if ($onlyMode) {
    # Only mode - run only the specified installation(s)
    if ($OnlyChocolatey) {
        Install-Chocolatey
        Install-CommonPackages
    }
    if ($OnlyChrome) { Install-Chrome }
    if ($OnlyNITools) { Install-NIGameTools }
    if ($OnlyREVClient) { Install-REVClient }
    if ($OnlyPhoenix) { Install-PhoenixTunerX }
    if ($OnlyWPILib) { Install-WPILib }
    if ($OnlyPathPlanner) { Install-PathPlanner }
    if ($OnlyBookmarks) { Install-BrowserBookmarks }
    if ($OnlyWallpaper) { Set-DesktopWallpaper }
} else {
    # Normal mode - run all installations except skipped ones
    if (-not $SkipChocolatey) { Install-Chocolatey }
    if (-not $SkipChocolatey) { Install-CommonPackages }
    if (-not $SkipChrome) { Install-Chrome }
    if (-not $SkipNITools) { Install-NIGameTools }
    if (-not $SkipREVClient) { Install-REVClient }
    if (-not $SkipPhoenix) { Install-PhoenixTunerX }
    if (-not $SkipWPILib) { Install-WPILib }
    if (-not $SkipPathPlanner) { Install-PathPlanner }
    if (-not $SkipBookmarks) { Install-BrowserBookmarks }

    # Configure Windows settings
    Set-WindowsConfiguration
}

# Check if reboot is required
$rebootRequired = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) -ne $null

Write-Banner "Installation Complete!"

Write-Host "Installed software:" -ForegroundColor White
Write-Host "  - Google Chrome" -ForegroundColor Green
Write-Host "  - NI FRC Game Tools" -ForegroundColor Green
Write-Host "  - REV Hardware Client" -ForegroundColor Green
Write-Host "  - Phoenix Tuner X" -ForegroundColor Green
Write-Host "  - WPILib VS Code" -ForegroundColor Green
Write-Host "  - PathPlanner" -ForegroundColor Green
Write-Host "  - FRC Browser Bookmarks" -ForegroundColor Green
Write-Host "  - Team Desktop Wallpaper" -ForegroundColor Green
Write-Host ""
Write-Host "Desktop shortcuts have been created." -ForegroundColor White
Write-Host "FRC Resources bookmarks added to Chrome and Edge." -ForegroundColor White
Write-Host "Team wallpaper has been applied to all user profiles." -ForegroundColor White

if ($rebootRequired) {
    Write-Host ""
    Write-Host "*** REBOOT REQUIRED ***" -ForegroundColor Red
    Write-Host "Please restart this computer to complete the installation." -ForegroundColor Yellow
}

Write-Host ""
