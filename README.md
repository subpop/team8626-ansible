# FRC Team 8626 - Windows Laptop Setup

PowerShell scripts for setting up Windows 11 laptops with FIRST Robotics Competition (FRC) software.

## Software Installed

| Software | Description | Installation Method |
|----------|-------------|---------------------|
| Chocolatey | Package manager for Windows | Direct download |
| Git | Version control | Chocolatey |
| 7zip | File archiver | Chocolatey |
| Google Chrome | Web browser | Chocolatey |
| NI FRC Game Tools | Driver Station, roboRIO imaging | ISO download |
| REV Hardware Client | Configure REV Robotics hardware | Chocolatey |
| Phoenix Tuner X | Configure CTRE motor controllers | GitHub release |
| WPILib VS Code | FRC development environment | ISO download |
| PathPlanner | Autonomous path planning | Chocolatey |

## Quick Start

### Install FRC Software

1. Download `Install-FRCTools.ps1` to the Windows laptop
2. Right-click and select **Run with PowerShell** as Administrator, or:

```powershell
# Open PowerShell as Administrator and run:
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1
```

The script is **idempotent** - safe to run multiple times. It will skip already-installed software.

### Installation Time

| Component | Approximate Time |
|-----------|------------------|
| Chocolatey + common packages | 2-5 minutes |
| Google Chrome | 1-2 minutes |
| NI FRC Game Tools | 15-30 minutes |
| REV Hardware Client | 2-3 minutes |
| Phoenix Tuner X | 2-3 minutes |
| WPILib | 10-20 minutes |
| PathPlanner | 1-2 minutes |
| **Total** | **35-65 minutes** |

## Scripts

### Install-FRCTools.ps1

Main installation script that sets up all FRC software.

```powershell
# Full installation (recommended)
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1

# Skip specific components
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1 -SkipNITools
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1 -SkipChrome -SkipPathPlanner
```

**Available Skip Flags:**
- `-SkipChocolatey` - Skip Chocolatey and common packages
- `-SkipChrome` - Skip Google Chrome
- `-SkipNITools` - Skip NI FRC Game Tools
- `-SkipREVClient` - Skip REV Hardware Client
- `-SkipPhoenix` - Skip Phoenix Tuner X
- `-SkipWPILib` - Skip WPILib
- `-SkipPathPlanner` - Skip PathPlanner

### Undo-WinRMSetup.ps1

If you previously used the Ansible-based setup (which required WinRM remote management), this script reverts those security changes.

```powershell
PowerShell -ExecutionPolicy Bypass -File Undo-WinRMSetup.ps1
```

**This script:**
- Removes Windows Defender exclusions for temp directories
- Disables the local Administrator account
- Stops and disables WinRM service
- Removes the WinRM HTTPS listener (port 5986)
- Removes the self-signed certificate
- Removes the firewall rule for WinRM
- Resets LocalAccountTokenFilterPolicy

## What Gets Installed

### Desktop Shortcuts

After installation, the following shortcuts appear on the Public Desktop:
- WPILib VS Code 2025
- REV Hardware Client
- Phoenix Tuner X
- PathPlanner

### Windows Configuration

The script also:
- Adds Windows Defender exclusions for FRC tool directories
- Enables Developer Mode (helpful for FRC development)

## Updating for New FRC Season

Edit the configuration section at the top of `Install-FRCTools.ps1`:

```powershell
$Config = @{
    # FRC Season Year
    Year = "2025"
    
    # NI FRC Game Tools - UPDATE THIS URL EACH SEASON
    # Get from: https://www.ni.com/en/support/downloads/drivers/download.frc-game-tools.html
    NIToolsUrl = "https://download.ni.com/support/nipkg/products/ni-f/ni-frc-2025-game-tools/25.0/offline/ni-frc-2025-game-tools_25.0.0_offline.iso"
    
    # ... other settings
}
```

Then re-run the script on each laptop.

## Troubleshooting

### Script Won't Run

```powershell
# If you get an execution policy error, run:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### NI Game Tools Download Fails

The NI download is ~2GB and may timeout on slow connections. If it fails:
1. Download the ISO manually from [NI's website](https://www.ni.com/en/support/downloads/drivers/download.frc-game-tools.html)
2. Place it at `C:\Temp\FRC_Downloads\ni-frc-game-tools.iso`
3. Re-run the script

### WPILib Download Fails

Similar to NI tools, you can manually download:
1. Get the ISO from [WPILib GitHub Releases](https://github.com/wpilibsuite/allwpilib/releases)
2. Place it at `C:\Temp\FRC_Downloads\WPILib_Windows.iso`
3. Re-run the script

### Reboot Required

Some components (especially NI Game Tools) may require a reboot. The script will notify you if a reboot is pending.

## License

MIT License - Feel free to use and modify for your FRC team!

## Support

For FRC-specific questions:
- [WPILib Documentation](https://docs.wpilib.org/)
- [FIRST Robotics](https://www.firstinspires.org/robotics/frc)
- [Chief Delphi Forums](https://www.chiefdelphi.com/)
