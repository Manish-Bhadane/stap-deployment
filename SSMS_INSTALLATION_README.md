# MS SQL Server Management Studio (SSMS) - Dynamic Ansible Installation

This Ansible playbook provides a fully automated, dynamic installation of Microsoft SQL Server Management Studio (SSMS) on Windows Server with MSSQL Database.

## 📋 Features

- **Dynamic Input**: Prompts for all required information at runtime
- **No Inventory File Required**: Dynamically adds target host
- **SQL Server Connectivity Test**: Validates database connection
- **Automatic Download**: Downloads latest SSMS installer
- **Silent Installation**: Unattended installation with logging
- **Post-Installation Verification**: Confirms successful installation
- **Desktop Shortcuts**: Creates shortcuts for easy access
- **Configuration Backup**: Saves connection details for reference

## 🔧 Prerequisites

### On Control Machine (Where Ansible Runs)

1. **Ansible Installation**
   ```bash
   # For Ubuntu/Debian
   sudo apt update
   sudo apt install ansible -y
   
   # For RHEL/CentOS
   sudo yum install ansible -y
   
   # For macOS
   brew install ansible
   ```

2. **Python WinRM Library**
   ```bash
   pip install pywinrm
   # or
   pip3 install pywinrm
   ```

3. **Verify Installation**
   ```bash
   ansible --version
   python -c "import winrm; print('WinRM module installed')"
   ```

### On Target Windows Server

1. **Enable WinRM** (Run in PowerShell as Administrator)
   ```powershell
   # Enable WinRM
   Enable-PSRemoting -Force
   
   # Configure WinRM for HTTP
   winrm quickconfig -q
   
   # Set WinRM service to automatic
   Set-Service WinRM -StartupType Automatic
   
   # Allow unencrypted traffic (for testing only)
   Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
   
   # Configure authentication
   Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
   
   # Configure firewall
   New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
   
   # Test WinRM
   Test-WSMan
   ```

2. **SQL Server Requirements**
   - SQL Server must be installed and running
   - SQL Server Authentication must be enabled
   - Valid SQL Server login credentials (sa or custom user)

3. **Network Requirements**
   - Port 5985 (WinRM HTTP) must be accessible
   - Internet connectivity for downloading SSMS installer
   - Sufficient disk space (minimum 2 GB free)

## 🚀 Usage

### Basic Usage

1. **Navigate to the playbook directory**
   ```bash
   cd /path/to/playbook
   ```

2. **Run the playbook**
   ```bash
   ansible-playbook install_ssms_dynamic.yml
   ```

3. **Provide the requested information when prompted:**
   - Windows Server IP address or hostname
   - Windows Administrator username (default: Administrator)
   - Windows Administrator password
   - SQL Server Database username (default: sa)
   - SQL Server Database password
   - SSMS version (default: 20.2 - latest)
   - SSMS download URL (default: latest from Microsoft)
   - Restart after installation (yes/no)

### Example Session

```bash
$ ansible-playbook install_ssms_dynamic.yml

Enter the Windows Server IP address or hostname: 192.168.1.100
Enter Windows Administrator username [Administrator]: Administrator
Enter Windows Administrator password: 
Enter SQL Server Database username (sa or custom) [sa]: sa
Enter SQL Server Database password: 
Enter SSMS version to install (press Enter for latest) [20.2]: 
Enter SSMS download URL (press Enter for latest) [https://aka.ms/ssmsfullsetup]: 
Restart server after installation? (yes/no) [no]: no

PLAY [Gather Dynamic Input for SSMS Installation] ****************************
...
```

## 📊 What the Playbook Does

### Phase 1: Input Collection
- Prompts for all required credentials and configuration
- Dynamically adds target host to inventory
- Displays configuration summary

### Phase 2: Pre-Installation Checks
- Tests WinRM connectivity
- Checks if SSMS is already installed
- Verifies SQL Server service status
- Tests SQL Server database connectivity
- Creates temporary directory

### Phase 3: Installation
- Downloads SSMS installer from Microsoft
- Verifies download integrity
- Performs silent installation (15-30 minutes)
- Monitors installation progress
- Checks installation logs for errors

### Phase 4: Post-Installation
- Verifies successful installation
- Creates desktop and Start Menu shortcuts
- Saves SQL Server connection configuration
- Cleans up installer file
- Optionally restarts the server

### Phase 5: Verification
- Confirms SSMS executable exists
- Displays installation summary
- Provides connection details

## 📁 Output Files

After successful installation, the following files are created on the target server:

1. **Installation Log**
   - Location: `C:\Temp\SSMS_Install_Log.txt`
   - Contains detailed installation progress and any errors

2. **SQL Connection Configuration**
   - Location: `C:\Temp\sql_connection_config.txt`
   - Contains SQL Server connection details and SSMS information

3. **Desktop Shortcut**
   - Location: `C:\Users\Public\Desktop\SQL Server Management Studio.lnk`
   - Quick access to SSMS

4. **Start Menu Shortcut**
   - Location: `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\`

## 🔍 Troubleshooting

### WinRM Connection Issues

**Problem**: Cannot connect to Windows server

**Solutions**:
```powershell
# On Windows Server, verify WinRM is running
Get-Service WinRM

# Check WinRM configuration
winrm get winrm/config

# Test from control machine
ansible all -i "192.168.1.100," -m win_ping -e "ansible_user=Administrator ansible_password=YourPassword ansible_connection=winrm ansible_winrm_server_cert_validation=ignore"
```

### SQL Server Connection Issues

**Problem**: Cannot connect to SQL Server

**Solutions**:
```powershell
# Verify SQL Server is running
Get-Service MSSQLSERVER

# Enable SQL Server Authentication
# Open SQL Server Configuration Manager
# SQL Server Services -> SQL Server -> Properties -> Security
# Set "Server authentication" to "SQL Server and Windows Authentication mode"

# Restart SQL Server
Restart-Service MSSQLSERVER
```

### Installation Fails

**Problem**: SSMS installation fails

**Solutions**:
1. Check installation log: `C:\Temp\SSMS_Install_Log.txt`
2. Verify sufficient disk space (minimum 2 GB)
3. Ensure no other installations are running
4. Try manual installation to identify issues
5. Check Windows Event Viewer for errors

### Download Issues

**Problem**: Cannot download SSMS installer

**Solutions**:
1. Verify internet connectivity on target server
2. Check firewall rules
3. Try alternative download URL
4. Manually download and place in `C:\Temp\SSMS-Setup-ENU.exe`

## 🔐 Security Considerations

### Production Environments

For production use, implement these security measures:

1. **Use HTTPS for WinRM**
   ```powershell
   # Configure HTTPS listener
   New-SelfSignedCertificate -DnsName "server.domain.com" -CertStoreLocation Cert:\LocalMachine\My
   
   # Enable HTTPS
   winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="server.domain.com";CertificateThumbprint="THUMBPRINT"}
   
   # Update firewall
   New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
   ```

2. **Use Ansible Vault for Passwords**
   ```bash
   # Create encrypted variables file
   ansible-vault create secrets.yml
   
   # Add to playbook
   ansible-playbook install_ssms_dynamic.yml --ask-vault-pass
   ```

3. **Disable Basic Authentication** (after testing)
   ```powershell
   Set-Item WSMan:\localhost\Service\Auth\Basic -Value $false
   ```

4. **Use Domain Accounts** instead of local Administrator

## 📝 Advanced Configuration

### Custom SSMS Version

To install a specific SSMS version:

1. Find the version download URL from [Microsoft Docs](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)
2. When prompted, enter the specific URL

### Offline Installation

For servers without internet access:

1. Download SSMS installer manually
2. Copy to target server: `C:\Temp\SSMS-Setup-ENU.exe`
3. Modify playbook to skip download task

### Multiple Servers

To install on multiple servers, create a loop:

```yaml
- name: Install on multiple servers
  include_tasks: install_ssms_dynamic.yml
  loop:
    - { host: "192.168.1.100", user: "admin1", pass: "pass1" }
    - { host: "192.168.1.101", user: "admin2", pass: "pass2" }
```

## 🎯 Post-Installation Steps

### Launch SSMS

1. **From Desktop**: Double-click "SQL Server Management Studio" shortcut
2. **From Start Menu**: Search for "SQL Server Management Studio"
3. **From Command Line**: 
   ```cmd
   "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20.2\Common7\IDE\Ssms.exe"
   ```

### Connect to SQL Server

1. Open SSMS
2. In "Connect to Server" dialog:
   - **Server name**: `localhost` or server IP
   - **Authentication**: SQL Server Authentication
   - **Login**: Enter SQL username (e.g., sa)
   - **Password**: Enter SQL password
3. Click "Connect"

## 📚 Additional Resources

- [SSMS Documentation](https://learn.microsoft.com/en-us/sql/ssms/)
- [Ansible Windows Modules](https://docs.ansible.com/ansible/latest/collections/ansible/windows/)
- [WinRM Setup Guide](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html)
- [SQL Server Authentication](https://learn.microsoft.com/en-us/sql/relational-databases/security/choose-an-authentication-mode)

## 🐛 Known Issues

1. **Long Installation Time**: SSMS installation can take 15-30 minutes depending on server performance
2. **Restart Required**: Some installations may require a restart even if not specified
3. **Antivirus Interference**: Antivirus software may slow down or block installation

## 📞 Support

For issues or questions:
1. Check the installation log: `C:\Temp\SSMS_Install_Log.txt`
2. Review Windows Event Viewer
3. Verify all prerequisites are met
4. Test manual installation to isolate Ansible-specific issues

## 📄 License

This playbook is provided as-is for educational and production use.

## 🔄 Version History

- **v1.0** (2024): Initial release with dynamic input support
- Supports SSMS 18.x, 19.x, and 20.x
- Compatible with Windows Server 2016, 2019, 2022

---

**Note**: Always test in a non-production environment first!