# FRC Team 8626 - Chocolatey Package Manager Installer
# Installs Chocolatey and common packages (Git, 7zip)
#
# Standalone usage: .\Install-Chocolatey.ps1
# Module usage: . .\Install-Chocolatey.ps1; Install-Chocolatey

#Requires -RunAsAdministrator

param(
    [switch]$Standalone
)

# Import shared modules
$modulePath = $PSScriptRoot
. "$modulePath\FRCConfig.ps1"
. "$modulePath\FRCHelpers.ps1"

# ============================================================================
# Installation Functions
# ============================================================================

function Install-Chocolatey {
    param([string]$Step = "1/2")
    
    Write-Step $Step "Installing Chocolatey package manager..."

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
    param([string]$Step = "2/2")
    
    Write-Step $Step "Installing common utilities (Git, 7zip)..."

    foreach ($package in $FRCConfig.CommonPackages) {
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

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - Chocolatey Installer"
    
    Install-Chocolatey -Step "1/2"
    Install-CommonPackages -Step "2/2"
    
    Write-Banner "Installation Complete!"
    Write-Host "Installed:" -ForegroundColor White
    Write-Host "  - Chocolatey package manager" -ForegroundColor Green
    Write-Host "  - Git" -ForegroundColor Green
    Write-Host "  - 7zip" -ForegroundColor Green
}

