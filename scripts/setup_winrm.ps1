# WinRM Setup Script for Ansible
# Run this script as Administrator on each Windows 11 laptop
# PowerShell -ExecutionPolicy Bypass -File setup_winrm.ps1

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FRC Team 8626 - WinRM Setup Script   " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Enable local Administrator account for Ansible
Write-Host "[1/8] Enabling local Administrator account..." -ForegroundColor Yellow
$adminAccount = Get-LocalUser -Name "Administrator"
if (-not $adminAccount.Enabled) {
    Enable-LocalUser -Name "Administrator"
    Write-Host "  Administrator account enabled" -ForegroundColor Green
} else {
    Write-Host "  Administrator account already enabled" -ForegroundColor Green
}

# Prompt for Administrator password
Write-Host ""
Write-Host "  Set password for the local Administrator account:" -ForegroundColor Cyan
$adminPassword = Read-Host -AsSecureString "  Enter new password"
$adminPasswordConfirm = Read-Host -AsSecureString "  Confirm password"

# Convert to plain text for comparison
$bstr1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
$bstr2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPasswordConfirm)
$plain1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr1)
$plain2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr2)

if ($plain1 -ne $plain2) {
    Write-Host "  ERROR: Passwords do not match. Exiting." -ForegroundColor Red
    exit 1
}

Set-LocalUser -Name "Administrator" -Password $adminPassword
Write-Host "  Administrator password set" -ForegroundColor Green

# Clean up
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
$plain1 = $null
$plain2 = $null

# Enable WinRM service
Write-Host "[2/8] Enabling WinRM service..." -ForegroundColor Yellow
Set-Service -Name WinRM -StartupType Automatic
Start-Service WinRM

# Configure WinRM
Write-Host "[3/8] Configuring WinRM settings..." -ForegroundColor Yellow
winrm quickconfig -quiet

# Set WinRM to allow unencrypted traffic (for NTLM over HTTPS)
Write-Host "[4/8] Setting WinRM authentication options..." -ForegroundColor Yellow
winrm set winrm/config/service '@{AllowUnencrypted="false"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Negotiate="true"}'

# Create self-signed certificate for HTTPS
Write-Host "[5/8] Creating self-signed certificate for HTTPS..." -ForegroundColor Yellow
$hostname = $env:COMPUTERNAME
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=$hostname" -and $_.NotAfter -gt (Get-Date) }

if (-not $cert) {
    $cert = New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(5)
    Write-Host "  Created new certificate with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
} else {
    Write-Host "  Using existing certificate with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
}

# Remove existing HTTPS listener if present
Write-Host "[6/8] Configuring HTTPS listener..." -ForegroundColor Yellow
$httpsListener = Get-ChildItem WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTPS" }
if ($httpsListener) {
    Remove-Item -Path "WSMan:\localhost\Listener\$($httpsListener.Name)" -Recurse -Force
    Write-Host "  Removed existing HTTPS listener" -ForegroundColor Gray
}

# Create new HTTPS listener
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $cert.Thumbprint -Force | Out-Null
Write-Host "  Created HTTPS listener on port 5986" -ForegroundColor Green

# Configure firewall rules
Write-Host "[7/8] Configuring firewall rules..." -ForegroundColor Yellow

# Remove old rules if they exist
$existingRule = Get-NetFirewallRule -Name "WinRM-HTTPS-In" -ErrorAction SilentlyContinue
if ($existingRule) {
    Remove-NetFirewallRule -Name "WinRM-HTTPS-In"
}

# Create new firewall rule for WinRM HTTPS
New-NetFirewallRule -Name "WinRM-HTTPS-In" `
    -DisplayName "WinRM HTTPS Inbound" `
    -Description "Allow WinRM HTTPS traffic for Ansible management" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5986 `
    -Action Allow `
    -Profile Domain,Private,Public | Out-Null
Write-Host "  Firewall rule created for port 5986" -ForegroundColor Green

# Set execution policy for future PowerShell scripts
Write-Host "[8/8] Setting PowerShell execution policy..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Scope LocalMachine

# Verify configuration
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification                         " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "WinRM Service Status:" -ForegroundColor Yellow
Get-Service WinRM | Format-Table -AutoSize

Write-Host "WinRM Listeners:" -ForegroundColor Yellow
winrm enumerate winrm/config/Listener

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Setup Complete!                      " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "This machine is now ready for Ansible management." -ForegroundColor White
Write-Host "Hostname: $hostname" -ForegroundColor White
Write-Host "WinRM HTTPS Port: 5986" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update inventory/hosts.yml with this machine's IP address" -ForegroundColor White
Write-Host "2. Update group_vars/windows.yml with admin credentials" -ForegroundColor White
Write-Host "3. Test connection: ansible windows -m win_ping" -ForegroundColor White
Write-Host ""

