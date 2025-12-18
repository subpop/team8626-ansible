# FRC Team 8626 - Windows Laptop Management

Ansible playbook for managing a "fleet" of Windows 11 laptops with FIRST Robotics Competition (FRC) software.

## Software Installed

| Software | Description | Installation Method |
|----------|-------------|---------------------|
| Google Chrome | Web browser | Chocolatey |
| NI FRC Game Tools | Driver Station, roboRIO imaging | Direct download |
| REV Hardware Client | Configure REV Robotics hardware | Chocolatey |
| Phoenix Tuner X | Configure CTRE motor controllers | Direct download |
| WPILib VS Code | FRC development environment | Direct download |
| PathPlanner | Autonomous path planning | Chocolatey |

## Prerequisites

### Control Node (Your Mac/Linux machine)

1. **Install Ansible**:
   ```bash
   # macOS
   brew install ansible
   
   # Ubuntu/Debian
   sudo apt update && sudo apt install ansible
   
   # pip (any platform)
   pip install ansible
   ```

2. **Install required Python packages**:
   ```bash
   pip install pywinrm
   ```

3. **Install Ansible collections**:
   ```bash
   ansible-galaxy collection install ansible.windows
   ansible-galaxy collection install chocolatey.chocolatey
   ansible-galaxy collection install community.windows
   ```

### Windows Laptops

Each Windows 11 laptop needs WinRM enabled for Ansible connectivity.

1. **Copy the setup script** to each laptop (via USB, network share, etc.)

2. **Run as Administrator** on each laptop:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File setup_winrm.ps1
   ```

3. **Note the IP address** of each laptop for inventory configuration

## Configuration

### 1. Update Inventory

Edit `inventory/hosts.yml` with your laptop IPs:

```yaml
all:
  children:
    windows:
      hosts:
        frc-laptop-01:
          ansible_host: 192.168.1.101  # Your actual IP
        frc-laptop-02:
          ansible_host: 192.168.1.102
        # ... etc
```

### 2. Configure Credentials (Using Ansible Vault)

Your Windows admin credentials should be stored securely using Ansible Vault encryption.

#### Step 1: Running Playbooks with Vault

```bash
# Option A: Prompt for vault password each time
ansible-playbook site.yml --ask-vault-pass

# Option B: Use a password file (more convenient, but secure the file!)
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
ansible-playbook site.yml --vault-password-file .vault_pass
```

#### Vault Management Commands

```bash
# Edit your encrypted vault file
ansible-vault edit group_vars/windows/vault.yml

# View contents without editing
ansible-vault view group_vars/windows/vault.yml

# Change the vault password
ansible-vault rekey group_vars/windows/vault.yml

# Encrypt an existing plaintext file
ansible-vault encrypt somefile.yml

# Decrypt (removes encryption - use carefully!)
ansible-vault decrypt somefile.yml
```

#### Sharing with Team Members

1. Share the vault password securely (in person, password manager, etc.)
2. Never commit `.vault_pass` or plaintext passwords to git
3. The encrypted `vault.yml` is safe to commit

## Usage

### Run Full Playbook

```bash
# Configure all laptops with all software (with vault password prompt)
ansible-playbook site.yml --ask-vault-pass

# Or if using a vault password file
ansible-playbook site.yml --vault-password-file .vault_pass
```

### Run Specific Roles

```bash
# Install only Chrome
ansible-playbook site.yml --tags chrome --ask-vault-pass

# Install only FRC core tools (NI + WPILib)
ansible-playbook site.yml --tags frc_core --ask-vault-pass

# Install only hardware tools (REV + CTRE)
ansible-playbook site.yml --tags hardware --ask-vault-pass
```

### Target Specific Laptops

```bash
# Run on single laptop
ansible-playbook site.yml --limit frc-laptop-01 --ask-vault-pass

# Run on multiple specific laptops
ansible-playbook site.yml --limit "frc-laptop-01,frc-laptop-03" --ask-vault-pass
```

### Test Connectivity

```bash
# Ping all Windows hosts
ansible windows -m win_ping --ask-vault-pass

# Get Windows facts
ansible windows -m setup --ask-vault-pass
```

## Available Tags

| Tag | Description |
|-----|-------------|
| `common` | Chocolatey and base configuration |
| `chrome` / `browsers` | Google Chrome |
| `ni_tools` / `ni` | NI FRC Game Tools |
| `rev_client` / `rev` | REV Hardware Client |
| `ctre_phoenix` / `ctre` / `phoenix` | Phoenix Tuner X |
| `wpilib` | WPILib VS Code |
| `pathplanner` / `autonomous` | PathPlanner |
| `frc_core` | NI Tools + WPILib |
| `hardware` | REV + CTRE tools |

## Directory Structure

```
team8626-ansible/
├── ansible.cfg              # Ansible configuration
├── site.yml                 # Main playbook
├── .vault_pass              # Vault password file (git-ignored, optional)
├── inventory/
│   └── hosts.yml            # Laptop inventory
├── group_vars/
│   ├── windows.yml          # Windows connection settings
│   └── vault.yml            # Encrypted secrets (create with ansible-vault)
├── roles/
│   ├── common/              # Chocolatey + base config
│   ├── chrome/              # Google Chrome
│   ├── ni_tools/            # NI FRC Game Tools
│   ├── rev_client/          # REV Hardware Client
│   ├── ctre_phoenix/        # Phoenix Tuner X
│   ├── wpilib/              # WPILib VS Code
│   └── pathplanner/         # PathPlanner
└── scripts/
    └── setup_winrm.ps1      # WinRM bootstrap script
```

## Customization

### Changing Software Versions

Each role has a `defaults/main.yml` file with configurable variables:

```yaml
# roles/wpilib/defaults/main.yml
wpilib_version: latest    # or "2025.1.1"
wpilib_year: "2025"

# roles/ni_tools/defaults/main.yml  
ni_tools_download_url: "https://..."  # Update for each season
```

### Adding New Software

1. Create a new role directory: `roles/new_software/`
2. Add `tasks/main.yml` and `defaults/main.yml`
3. Include the role in `site.yml`

## Troubleshooting

### Connection Issues

```bash
# Test WinRM connectivity
ansible windows -m win_ping -vvv

# Check if WinRM is running on Windows
winrm enumerate winrm/config/Listener
```

### Common Errors

**"Connection refused"**: WinRM not enabled. Run `setup_winrm.ps1` on the target.

**"Certificate validation failed"**: Already handled by `ansible_winrm_server_cert_validation: ignore`

**"Access denied"**: Check credentials in `group_vars/windows/vault.yml` (use `ansible-vault edit group_vars/vault.yml`)

### Long-Running Installs

NI Game Tools and WPILib are large installers. If timeouts occur:

```yaml
# Increase in group_vars/windows.yml
ansible_winrm_operation_timeout_sec: 300
ansible_winrm_read_timeout_sec: 360
```

## Updating for New FRC Season

1. Update `roles/ni_tools/defaults/main.yml` with new NI download URL
2. Update `roles/wpilib/defaults/main.yml` with new year
3. Re-run playbook: `ansible-playbook site.yml --tags frc_core --ask-vault-pass`

## License

MIT License - Feel free to use and modify for your FRC team!

## Support

For FRC-specific questions:
- [WPILib Documentation](https://docs.wpilib.org/)
- [FIRST Robotics](https://www.firstinspires.org/robotics/frc)
- [Chief Delphi Forums](https://www.chiefdelphi.com/)

