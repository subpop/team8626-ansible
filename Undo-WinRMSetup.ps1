# FRC Team 8626 - Undo WinRM Setup Script
# Run this script as Administrator to revert security changes made by setup_winrm.ps1
# PowerShell -ExecutionPolicy Bypass -File Undo-WinRMSetup.ps1
#
# This script restores security settings that were weakened for Ansible remote management

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FRC Team 8626 - Undo WinRM Setup     " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will revert security changes made for Ansible remote management." -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# Step 1: Remove Windows Defender Exclusions
# ============================================================================
Write-Host "[1/7] Removing Windows Defender exclusions..." -ForegroundColor Yellow

$exclusionPaths = @(
    "C:\Users\Administrator\AppData\Local\Temp",
    "C:\Windows\Temp"
)

foreach ($path in $exclusionPaths) {
    $existing = (Get-MpPreference).ExclusionPath
    if ($existing -contains $path) {
        Remove-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
        Write-Host "  Removed exclusion: $path" -ForegroundColor Green
    } else {
        Write-Host "  Exclusion not found: $path" -ForegroundColor Gray
    }
}

# Remove PowerShell process exclusion
$existingProcesses = (Get-MpPreference).ExclusionProcess
if ($existingProcesses -contains "powershell.exe") {
    Remove-MpPreference -ExclusionProcess "powershell.exe" -ErrorAction SilentlyContinue
    Write-Host "  Removed process exclusion: powershell.exe" -ForegroundColor Green
} else {
    Write-Host "  Process exclusion not found: powershell.exe" -ForegroundColor Gray
}

# ============================================================================
# Step 2: Disable Local Administrator Account
# ============================================================================
Write-Host "[2/7] Disabling local Administrator account..." -ForegroundColor Yellow

$adminAccount = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
if ($adminAccount) {
    if ($adminAccount.Enabled) {
        Disable-LocalUser -Name "Administrator"
        Write-Host "  Administrator account disabled" -ForegroundColor Green
        Write-Host "  NOTE: The password remains set. Clear it manually if needed." -ForegroundColor Cyan
    } else {
        Write-Host "  Administrator account already disabled" -ForegroundColor Gray
    }
} else {
    Write-Host "  Administrator account not found" -ForegroundColor Gray
}

# ============================================================================
# Step 3: Remove WinRM HTTPS Listener
# ============================================================================
Write-Host "[3/7] Removing WinRM HTTPS listener..." -ForegroundColor Yellow

$httpsListener = Get-ChildItem WSMan:\localhost\Listener -ErrorAction SilentlyContinue | Where-Object { $_.Keys -contains "Transport=HTTPS" }
if ($httpsListener) {
    Remove-Item -Path "WSMan:\localhost\Listener\$($httpsListener.Name)" -Recurse -Force
    Write-Host "  Removed HTTPS listener on port 5986" -ForegroundColor Green
} else {
    Write-Host "  No HTTPS listener found" -ForegroundColor Gray
}

# ============================================================================
# Step 4: Remove Self-Signed Certificate
# ============================================================================
Write-Host "[4/7] Removing self-signed WinRM certificate..." -ForegroundColor Yellow

$hostname = $env:COMPUTERNAME
$certs = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=$hostname" }

if ($certs) {
    foreach ($cert in $certs) {
        Remove-Item -Path "Cert:\LocalMachine\My\$($cert.Thumbprint)" -Force
        Write-Host "  Removed certificate: $($cert.Thumbprint)" -ForegroundColor Green
    }
} else {
    Write-Host "  No WinRM certificates found for $hostname" -ForegroundColor Gray
}

# ============================================================================
# Step 5: Remove Firewall Rule
# ============================================================================
Write-Host "[5/7] Removing WinRM firewall rule..." -ForegroundColor Yellow

$firewallRule = Get-NetFirewallRule -Name "WinRM-HTTPS-In" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Remove-NetFirewallRule -Name "WinRM-HTTPS-In"
    Write-Host "  Removed firewall rule: WinRM-HTTPS-In (port 5986)" -ForegroundColor Green
} else {
    Write-Host "  Firewall rule not found" -ForegroundColor Gray
}

# ============================================================================
# Step 6: Reset LocalAccountTokenFilterPolicy
# ============================================================================
Write-Host "[6/7] Resetting LocalAccountTokenFilterPolicy..." -ForegroundColor Yellow

$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$currentValue = Get-ItemProperty -Path $regPath -Name "LocalAccountTokenFilterPolicy" -ErrorAction SilentlyContinue

if ($currentValue.LocalAccountTokenFilterPolicy -eq 1) {
    Set-ItemProperty -Path $regPath -Name "LocalAccountTokenFilterPolicy" -Value 0 -Type DWord
    Write-Host "  LocalAccountTokenFilterPolicy reset to 0 (secure default)" -ForegroundColor Green
} else {
    Write-Host "  LocalAccountTokenFilterPolicy already at secure default" -ForegroundColor Gray
}

# ============================================================================
# Step 7: Stop and Disable WinRM Service
# ============================================================================
Write-Host "[7/7] Stopping and disabling WinRM service..." -ForegroundColor Yellow

$winrmService = Get-Service -Name WinRM -ErrorAction SilentlyContinue
if ($winrmService) {
    if ($winrmService.Status -eq "Running") {
        Stop-Service -Name WinRM -Force
        Write-Host "  WinRM service stopped" -ForegroundColor Green
    }
    
    if ($winrmService.StartType -ne "Disabled") {
        Set-Service -Name WinRM -StartupType Disabled
        Write-Host "  WinRM service startup disabled" -ForegroundColor Green
    } else {
        Write-Host "  WinRM service already disabled" -ForegroundColor Gray
    }
} else {
    Write-Host "  WinRM service not found" -ForegroundColor Gray
}

# ============================================================================
# Summary
# ============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Security Restoration Complete!       " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The following security changes have been reverted:" -ForegroundColor White
Write-Host "  - Windows Defender exclusions removed" -ForegroundColor White
Write-Host "  - Local Administrator account disabled" -ForegroundColor White
Write-Host "  - WinRM HTTPS listener removed" -ForegroundColor White
Write-Host "  - Self-signed certificate removed" -ForegroundColor White
Write-Host "  - Firewall rule for port 5986 removed" -ForegroundColor White
Write-Host "  - LocalAccountTokenFilterPolicy reset" -ForegroundColor White
Write-Host "  - WinRM service stopped and disabled" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: PowerShell execution policy remains at 'RemoteSigned' as this is" -ForegroundColor Cyan
Write-Host "      a safe default that allows running local scripts." -ForegroundColor Cyan
Write-Host ""
Write-Host "This machine is no longer configured for remote management." -ForegroundColor Yellow
Write-Host ""

