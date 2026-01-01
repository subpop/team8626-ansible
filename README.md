# FRC Team 8626 - Windows Laptop Setup

PowerShell scripts for setting up Windows 11 laptops with FIRST Robotics Competition (FRC) software.

## Software Installed

| Software | Description | Installation Method |
|----------|-------------|---------------------|
| Chocolatey | Package manager for Windows | Direct download |
| Git | Version control | Chocolatey |
| 7zip | File archiver | Chocolatey |
| Google Chrome | Web browser | Chocolatey |
| NI FRC Game Tools | Driver Station, roboRIO imaging | Online installer |
| REV Hardware Client | Configure REV Robotics hardware | GitHub release |
| Phoenix Tuner X | Configure CTRE motor controllers | GitHub release |
| WPILib VS Code | FRC development environment | GitHub release |
| PathPlanner | Autonomous path planning | Chocolatey |
| Browser Bookmarks | FRC resources for Chrome & Edge | Script |
| Team Wallpaper | Desktop wallpaper | Script |

## Quick Start

### Install FRC Software

1. Download the entire repository (or clone it) to the Windows laptop
2. Right-click `Install-FRCTools.ps1` and select **Run with PowerShell** as Administrator, or:

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
| Browser Bookmarks | < 1 minute |
| Team Wallpaper | < 1 minute |
| **Total** | **35-65 minutes** |

## Project Structure

```
team8626-ansible/
├── Install-FRCTools.ps1          # Main installer (orchestrates everything)
├── modules/
│   ├── FRCConfig.ps1             # Shared configuration (versions, URLs)
│   ├── FRCHelpers.ps1            # Shared helper functions
│   ├── Install-Bookmarks.ps1     # Browser bookmarks installer
│   ├── Install-Chocolatey.ps1    # Chocolatey + common packages
│   ├── Install-Chrome.ps1        # Google Chrome
│   ├── Install-NITools.ps1       # NI FRC Game Tools
│   ├── Install-PathPlanner.ps1   # PathPlanner
│   ├── Install-Phoenix.ps1       # Phoenix Tuner X
│   ├── Install-REVClient.ps1     # REV Hardware Client
│   ├── Install-Wallpaper.ps1     # Desktop wallpaper
│   └── Install-WPILib.ps1        # WPILib VS Code
└── Cyber+Sailors_Desktop.png     # Team wallpaper image
```

## Usage

### Full Installation (Default)

```powershell
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1
```

### Skip Specific Components

```powershell
# Skip NI Game Tools (useful if already installed)
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1 -SkipNITools

# Skip multiple components
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1 -SkipChrome -SkipPathPlanner -SkipWallpaper
```

**Available Skip Flags:**
- `-SkipChocolatey` - Skip Chocolatey and common packages
- `-SkipChrome` - Skip Google Chrome
- `-SkipNITools` - Skip NI FRC Game Tools
- `-SkipREVClient` - Skip REV Hardware Client
- `-SkipPhoenix` - Skip Phoenix Tuner X
- `-SkipWPILib` - Skip WPILib
- `-SkipPathPlanner` - Skip PathPlanner
- `-SkipBookmarks` - Skip browser bookmarks
- `-SkipWallpaper` - Skip team wallpaper

### Install Only Specific Components

Use "Only" flags to run just one installer:

```powershell
# Install only WPILib
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1 -OnlyWPILib

# Install only bookmarks and wallpaper
PowerShell -ExecutionPolicy Bypass -File Install-FRCTools.ps1 -OnlyBookmarks -OnlyWallpaper
```

**Available Only Flags:**
- `-OnlyChocolatey` - Install only Chocolatey and common packages
- `-OnlyChrome` - Install only Google Chrome
- `-OnlyNITools` - Install only NI FRC Game Tools
- `-OnlyREVClient` - Install only REV Hardware Client
- `-OnlyPhoenix` - Install only Phoenix Tuner X
- `-OnlyWPILib` - Install only WPILib
- `-OnlyPathPlanner` - Install only PathPlanner
- `-OnlyBookmarks` - Install only browser bookmarks
- `-OnlyWallpaper` - Install only team wallpaper

### Standalone Module Usage

Each module can also be run independently:

```powershell
# Run a single installer module directly
.\modules\Install-WPILib.ps1
.\modules\Install-REVClient.ps1
.\modules\Install-Bookmarks.ps1
```

## What Gets Installed

### Desktop Shortcuts

After installation, the following shortcuts appear on the Public Desktop:
- WPILib VS Code 2025
- REV Hardware Client
- Phoenix Tuner X
- PathPlanner

### Browser Bookmarks

FRC resource bookmarks are added to both Chrome and Edge:
- WPILib Documentation
- REV Robotics Docs
- CTRE Phoenix Docs
- PathPlanner Docs
- Chief Delphi
- The Blue Alliance
- FRC Q&A
- PhotonVision Docs
- W3Schools

### Windows Configuration

The script also:
- Adds Windows Defender exclusions for FRC tool directories
- Enables Developer Mode (helpful for FRC development)
- Sets team desktop wallpaper

## Updating for New FRC Season

Edit `modules/FRCConfig.ps1` to update versions and URLs:

```powershell
$script:FRCConfig = @{
    # FRC Season Year
    Year = "2025"
    
    # NI FRC Game Tools - UPDATE THIS URL EACH SEASON
    # Get from: https://www.ni.com/en/support/downloads/drivers/download.frc-game-tools.html
    NIToolsUrl = "https://download.ni.com/..."
    
    # REV Hardware Client - UPDATE FROM GitHub releases
    REVClientUrl = "https://github.com/REVrobotics/..."
    
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

The NI download may timeout on slow connections. If it fails:
1. Download manually from [NI's website](https://www.ni.com/en/support/downloads/drivers/download.frc-game-tools.html)
2. Run the installer manually
3. Re-run the script with `-SkipNITools`

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
