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
    NIToolsUrl = "https://download.ni.com/support/nipkg/products/ni-f/ni-frc-2025-game-tools/25.0/offline/ni-frc-2025-game-tools_25.0.0_offline.iso"
    
    # WPILib (uses GitHub API for latest)
    WPILibInstallPath = "C:\Users\Public\wpilib"
    
    # Phoenix Tuner X
    PhoenixInstallPath = "C:\Program Files (x86)\CTRE\Phoenix Tuner X"
    
    # REV Hardware Client
    REVInstallPath = "C:\Program Files\REV Robotics\REV Hardware Client"
    
    # PathPlanner
    PathPlannerInstallPath = "C:\Program Files\PathPlanner"
    
    # Common packages to install via Chocolatey
    CommonPackages = @("git", "7zip")
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
    Write-Step "1/8" "Installing Chocolatey package manager..."
    
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
    Write-Step "2/8" "Installing common utilities (Git, 7zip)..."
    
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
    Write-Step "3/8" "Installing Google Chrome..."
    
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
    Write-Step "4/8" "Installing NI FRC Game Tools..."
    
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
    
    $isoPath = Join-Path $Config.TempPath "ni-frc-game-tools.iso"
    
    # Download ISO if not present
    if (-not (Test-Path $isoPath)) {
        Write-Info "Downloading NI FRC Game Tools (~2GB, this may take a while)..."
        $ProgressPreference = 'SilentlyContinue'  # Speed up download
        Invoke-WebRequest -Uri $Config.NIToolsUrl -OutFile $isoPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Success "Download complete"
    } else {
        Write-Info "Using cached ISO file"
    }
    
    # Mount ISO
    Write-Info "Mounting ISO..."
    $mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    
    # Find and run installer
    Write-Info "Installing NI FRC Game Tools (this takes 15-30 minutes)..."
    $installer = Get-ChildItem -Path "${driveLetter}:\" -Filter "*.exe" -Recurse | Select-Object -First 1
    if ($installer) {
        Start-Process -FilePath $installer.FullName -ArgumentList "/q /AcceptLicenses yes /r:n" -Wait -NoNewWindow
        Write-Success "NI FRC Game Tools installed"
    } else {
        Write-Warning "Installer not found in ISO"
    }
    
    # Unmount ISO
    Write-Info "Unmounting ISO..."
    Dismount-DiskImage -ImagePath $isoPath | Out-Null
    
    # Cleanup
    if ($CleanupInstallers) {
        Remove-Item $isoPath -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned up installer files"
    }
}

function Install-REVClient {
    Write-Step "5/8" "Installing REV Hardware Client..."
    
    $installed = choco list --local-only rev-hardware-client 2>$null | Select-String "^rev-hardware-client\s"
    if ($installed) {
        Write-Success "REV Hardware Client is already installed"
    } else {
        Write-Info "Installing REV Hardware Client via Chocolatey..."
        choco install rev-hardware-client -y | Out-Null
        Write-Success "REV Hardware Client installed"
    }
    
    # Create desktop shortcut
    $revExe = Join-Path $Config.REVInstallPath "REV Hardware Client.exe"
    New-DesktopShortcut -TargetPath $revExe -ShortcutName "REV Hardware Client" -Description "REV Robotics Hardware Client"
}

function Install-PhoenixTunerX {
    Write-Step "6/8" "Installing Phoenix Tuner X..."
    
    $phoenixExe = Join-Path $Config.PhoenixInstallPath "Phoenix Tuner.exe"
    if (Test-Path $phoenixExe) {
        Write-Success "Phoenix Tuner X is already installed"
        New-DesktopShortcut -TargetPath $phoenixExe -ShortcutName "Phoenix Tuner X" -Description "CTRE Phoenix Tuner X"
        return
    }
    
    # Ensure temp directory exists
    if (-not (Test-Path $Config.TempPath)) {
        New-Item -ItemType Directory -Path $Config.TempPath -Force | Out-Null
    }
    
    # Get latest release from GitHub
    Write-Info "Fetching latest Phoenix Tuner X release..."
    $release = Get-GitHubLatestRelease -Repo "CrossTheRoadElec/Phoenix-Releases"
    
    if ($release) {
        $asset = $release.assets | Where-Object { $_.name -match "Phoenix.*Tuner.*\.exe$" } | Select-Object -First 1
        if ($asset) {
            $downloadUrl = $asset.browser_download_url
        } else {
            $downloadUrl = "https://github.com/CrossTheRoadElec/Phoenix-Releases/releases/latest/download/Phoenix-Tuner-X-Windows.exe"
        }
    } else {
        $downloadUrl = "https://github.com/CrossTheRoadElec/Phoenix-Releases/releases/latest/download/Phoenix-Tuner-X-Windows.exe"
    }
    
    $installerPath = Join-Path $Config.TempPath "PhoenixTunerX_Setup.exe"
    
    # Download installer
    Write-Info "Downloading Phoenix Tuner X..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    # Install silently
    Write-Info "Installing Phoenix Tuner X..."
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -NoNewWindow
    Write-Success "Phoenix Tuner X installed"
    
    # Create desktop shortcut
    New-DesktopShortcut -TargetPath $phoenixExe -ShortcutName "Phoenix Tuner X" -Description "CTRE Phoenix Tuner X"
    
    # Cleanup
    if ($CleanupInstallers) {
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    }
}

function Install-WPILib {
    Write-Step "7/8" "Installing WPILib..."
    
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
    
    # Get latest release from GitHub
    Write-Info "Fetching latest WPILib release..."
    $release = Get-GitHubLatestRelease -Repo "wpilibsuite/allwpilib"
    
    if ($release) {
        $version = $release.tag_name -replace '^v', ''
    } else {
        Write-Warning "Could not fetch latest version, using default"
        $version = "2025.1.1"
    }
    
    $isoUrl = "https://github.com/wpilibsuite/allwpilib/releases/download/v$version/WPILib_Windows-$version.iso"
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
    Write-Step "8/8" "Installing PathPlanner..."
    
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
Write-Host ""

# Ensure temp directory exists
if (-not (Test-Path $Config.TempPath)) {
    New-Item -ItemType Directory -Path $Config.TempPath -Force | Out-Null
}

# Run installations
if (-not $SkipChocolatey) { Install-Chocolatey }
if (-not $SkipChocolatey) { Install-CommonPackages }
if (-not $SkipChrome) { Install-Chrome }
if (-not $SkipNITools) { Install-NIGameTools }
if (-not $SkipREVClient) { Install-REVClient }
if (-not $SkipPhoenix) { Install-PhoenixTunerX }
if (-not $SkipWPILib) { Install-WPILib }
if (-not $SkipPathPlanner) { Install-PathPlanner }

# Configure Windows settings
Set-WindowsConfiguration

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
Write-Host ""
Write-Host "Desktop shortcuts have been created." -ForegroundColor White

if ($rebootRequired) {
    Write-Host ""
    Write-Host "*** REBOOT REQUIRED ***" -ForegroundColor Red
    Write-Host "Please restart this computer to complete the installation." -ForegroundColor Yellow
}

Write-Host ""

