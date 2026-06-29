# SSMS Installation via AWX - Complete Setup Guide

## 📋 Current AWX Configuration

✅ **Project Created**: STAP Deployment  
✅ **Git Repository**: https://github.com/Manish-Bhadane/stap-deployment.git  
✅ **Branch**: main  
✅ **Playbook Directory**: _9__stap_deployment  
✅ **Last Sync**: Successful (865775d)  

---

## 🚀 Quick Setup Steps

### Step 1: Push SSMS Files to Your Git Repository

```bash
# Navigate to your local repository
cd /path/to/stap-deployment

# Copy the SSMS files (if not already there)
# - windows_server_winrm_setup.ps1
# - install_ssms_dynamic.yml
# - SSMS_INSTALLATION_README.md

# Add and commit
git add windows_server_winrm_setup.ps1
git add install_ssms_dynamic.yml
git add SSMS_INSTALLATION_README.md
git commit -m "Add SSMS installation automation for Windows Server"
git push origin main
```

### Step 2: Sync AWX Project

1. **Login to AWX**: https://9.46.241.103
2. **Navigate to**: Projects → STAP Deployment
3. **Click**: Sync button (circular arrow icon)
4. **Wait**: For sync to complete (Status: Successful)
5. **Verify**: Check that new playbooks appear in the project

---

## 📊 Step 3: Create Inventory for Windows Servers

### Option A: Create New Inventory

1. **Navigate to**: Resources → Inventories
2. **Click**: Add → Add inventory
3. **Fill in**:
   ```
   Name: Windows SQL Servers
   Description: Windows Servers for SSMS installation
   Organization: Default
   ```
4. **Click**: Save

### Option B: Use Existing Inventory

If you already have an inventory, skip to adding hosts.

---

## 🖥️ Step 4: Add Windows Server Hosts

### Add Your Windows Server

1. **Click on**: Your inventory (e.g., "Windows SQL Servers")
2. **Navigate to**: Hosts tab
3. **Click**: Add (+)
4. **Fill in**:
   ```
   Name: windows-sql-server-01
   Description: Production SQL Server
   ```
5. **Variables** (YAML format):
   ```yaml
   ---
   # Connection Settings
   ansible_host: YOUR_WINDOWS_SERVER_IP  # Replace with actual IP
   ansible_connection: winrm
   ansible_port: 5985
   ansible_winrm_transport: ntlm
   ansible_winrm_server_cert_validation: ignore
   
   # SSMS Configuration
   ssms_version: "20.2"
   ssms_download_url: "https://aka.ms/ssmsfullsetup"
   restart_after_install: false
   ```
6. **Click**: Save

### Example for Multiple Servers

**Server 1:**
```yaml
ansible_host: 192.168.1.100
ansible_connection: winrm
ansible_port: 5985
ansible_winrm_transport: ntlm
ansible_winrm_server_cert_validation: ignore
```

**Server 2:**
```yaml
ansible_host: 192.168.1.101
ansible_connection: winrm
ansible_port: 5985
ansible_winrm_transport: ntlm
ansible_winrm_server_cert_validation: ignore
```

---

## 🔐 Step 5: Create Credentials

### Windows Administrator Credentials

1. **Navigate to**: Resources → Credentials
2. **Click**: Add (+)
3. **Fill in**:
   ```
   Name: Windows Admin - SQL Servers
   Description: Administrator credentials for Windows SQL Servers
   Organization: Default
   Credential Type: Machine
   Username: Administrator
   Password: [Your Windows Admin Password]
   ```
4. **Click**: Save

### SQL Server Credentials (Optional - for validation)

1. **Click**: Add (+)
2. **Fill in**:
   ```
   Name: SQL Server SA Account
   Description: SQL Server database credentials
   Organization: Default
   Credential Type: Machine
   Username: sa
   Password: [Your SQL Server SA Password]
   ```
3. **Click**: Save

---

## 🎬 Step 6: Create Job Template for SSMS Installation

### Main Installation Template

1. **Navigate to**: Resources → Templates
2. **Click**: Add → Add job template
3. **Fill in details**:

   **General:**
   ```
   Name: Install SSMS on Windows Server
   Description: Automated SSMS installation with pre-flight checks
   Job Type: Run
   Inventory: Windows SQL Servers
   Project: STAP Deployment
   Playbook: install_ssms_dynamic.yml
   Credentials: 
     - Windows Admin - SQL Servers
     - SQL Server SA Account (if created)
   Execution Environment: Default execution environment
   ```

   **Options** (Check these):
   - ✅ Privilege Escalation
   - ✅ Enable Fact Storage
   - ✅ Prompt on launch (for Variables)

   **Extra Variables**:
   ```yaml
   ---
   # Target Configuration (will be prompted)
   target_host: "{{ ansible_host }}"
   windows_username: "Administrator"
   sql_username: "sa"
   
   # SSMS Settings
   ssms_version: "20.2"
   ssms_download_url: "https://aka.ms/ssmsfullsetup"
   restart_after_install: false
   
   # Installation Paths
   ssms_installer_path: "C:\\Temp\\SSMS-Setup-ENU.exe"
   ssms_install_dir: "C:\\Program Files (x86)\\Microsoft SQL Server Management Studio 20.2"
   ssms_log_path: "C:\\Temp\\SSMS_Install_Log.txt"
   sql_config_path: "C:\\Temp\\sql_connection_config.txt"
   
   # Timeout (in seconds)
   install_timeout: 3600
   ```

4. **Click**: Save

---

## 🔧 Step 7: Prepare Windows Server (One-Time Setup)

### On Each Windows Server (Run as Administrator):

```powershell
# 1. Enable PowerShell Remoting
Enable-PSRemoting -Force

# 2. Download and run WinRM setup script
# Option A: If you have the script locally
cd C:\Path\To\Script
.\windows_server_winrm_setup.ps1

# Option B: Download from your repository
$url = "https://raw.githubusercontent.com/Manish-Bhadane/stap-deployment/main/windows_server_winrm_setup.ps1"
Invoke-WebRequest -Uri $url -OutFile "C:\Temp\setup.ps1"
Set-ExecutionPolicy Bypass -Scope Process -Force
C:\Temp\setup.ps1

# 3. Verify WinRM is running
Test-WSMan
Get-Service WinRM

# 4. Test from AWX server (optional)
# From AWX server terminal:
# ansible all -i "YOUR_WINDOWS_IP," -m win_ping -e "ansible_user=Administrator ansible_password=YourPass ansible_connection=winrm ansible_winrm_server_cert_validation=ignore"
```

### Verify SQL Server is Ready

```powershell
# Check SQL Server service
Get-Service MSSQLSERVER

# Test SQL connection
sqlcmd -S localhost -U sa -P YourPassword -Q "SELECT @@VERSION"

# If SQL Server Authentication is not enabled:
# 1. Open SQL Server Configuration Manager
# 2. SQL Server Services → SQL Server → Properties → Security
# 3. Set "Server authentication" to "SQL Server and Windows Authentication mode"
# 4. Restart SQL Server: Restart-Service MSSQLSERVER
```

---

## ▶️ Step 8: Run the SSMS Installation

### Method 1: Launch Job Template

1. **Navigate to**: Resources → Templates
2. **Find**: "Install SSMS on Windows Server"
3. **Click**: Launch button (🚀 rocket icon)
4. **If prompted for variables**:
   - Review and modify if needed
   - Confirm SQL Server password
5. **Click**: Launch
6. **Monitor**: Real-time output in the job details page

### Method 2: Run from Command Line (API)

```bash
# Get authentication token
TOKEN=$(curl -X POST https://9.46.241.103/api/v2/tokens/ \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "Finance@123456789"}' \
  -k -s | jq -r '.token')

# Launch job template (replace {id} with your template ID)
curl -X POST https://9.46.241.103/api/v2/job_templates/{id}/launch/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "ssms_version": "20.2",
      "restart_after_install": false
    }
  }' \
  -k
```

---

## 📊 Step 9: Monitor Installation Progress

### Real-time Monitoring

The job output will show:

```
PLAY [Gather Dynamic Input for SSMS Installation] ****************************

TASK [Add target host to inventory dynamically] ******************************
ok: [localhost]

PLAY [Install MS SQL Server Management Studio on Windows] ********************

TASK [Test WinRM connectivity] ***********************************************
ok: [windows-sql-server-01]

TASK [Check if SSMS is already installed] ************************************
ok: [windows-sql-server-01]

TASK [Download SSMS installer] ***********************************************
changed: [windows-sql-server-01]
(Downloading 600+ MB - may take 5-10 minutes)

TASK [Install SSMS silently] *************************************************
changed: [windows-sql-server-01]
(Installation in progress - this takes 15-30 minutes)

TASK [Verify SSMS installation] **********************************************
ok: [windows-sql-server-01]
SUCCESS: SSMS Version 20.2.30.0 installed

PLAY RECAP *******************************************************************
windows-sql-server-01 : ok=25   changed=8    unreachable=0    failed=0
```

### Check Installation Logs on Windows Server

```powershell
# View installation log
Get-Content C:\Temp\SSMS_Install_Log.txt -Tail 100

# View SQL connection configuration
Get-Content C:\Temp\sql_connection_config.txt

# Verify SSMS is installed
Test-Path "C:\Program Files (x86)\Microsoft SQL Server Management Studio*\Common7\IDE\Ssms.exe"

# Get SSMS version
$ssms = Get-ChildItem "C:\Program Files (x86)\Microsoft SQL Server Management Studio*\Common7\IDE\Ssms.exe"
$ssms.VersionInfo.FileVersion
```

---

## ✅ Step 10: Post-Installation Verification

### On Windows Server

1. **Launch SSMS**:
   - Double-click desktop shortcut "SQL Server Management Studio"
   - Or from Start Menu

2. **Connect to SQL Server**:
   ```
   Server name: localhost
   Authentication: SQL Server Authentication
   Login: sa
   Password: [Your SQL Password]
   ```

3. **Verify Connection**:
   - Should connect successfully
   - Can see databases and run queries

### In AWX

1. **Check Job Status**: Should show "Successful"
2. **Review Output**: All tasks should be "ok" or "changed"
3. **Check Facts**: Navigate to job → Facts tab
4. **Download Logs**: Click "Download Output" for records

---

## 🔍 Troubleshooting

### Issue 1: Job Fails with "No hosts matched"

**Solution:**
```yaml
# Check host variables in inventory
# Ensure ansible_host is set correctly
ansible_host: 192.168.1.100  # Must be actual IP
```

### Issue 2: WinRM Connection Failed

**Solution:**
```powershell
# On Windows Server
Enable-PSRemoting -Force
winrm quickconfig -q
Test-WSMan

# Check firewall
Get-NetFirewallRule -Name "WinRM-HTTP-In-TCP"
Test-NetConnection -ComputerName localhost -Port 5985
```

### Issue 3: Authentication Failed

**Solution:**
1. Verify credentials in AWX
2. Test manually:
   ```bash
   # From AWX server
   ansible all -i "192.168.1.100," -m win_ping \
     -e "ansible_user=Administrator" \
     -e "ansible_password=YourPassword" \
     -e "ansible_connection=winrm" \
     -e "ansible_winrm_server_cert_validation=ignore"
   ```

### Issue 4: Download Fails

**Solution:**
```powershell
# On Windows Server, test internet connectivity
Test-NetConnection -ComputerName aka.ms -Port 443

# Or download manually
Invoke-WebRequest -Uri "https://aka.ms/ssmsfullsetup" -OutFile "C:\Temp\SSMS-Setup-ENU.exe"
```

### Issue 5: Installation Hangs

**Solution:**
```powershell
# Check installation process
Get-Process | Where-Object {$_.Name -like "*SSMS*" -or $_.Name -like "*Setup*"}

# Check disk space
Get-PSDrive C | Select-Object Used,Free

# View installation log in real-time
Get-Content C:\Temp\SSMS_Install_Log.txt -Wait
```

---

## 🔒 Security Best Practices

### 1. Use HTTPS for WinRM (Production)

```powershell
# On Windows Server
.\windows_server_winrm_setup.ps1 -ProductionMode -EnableHTTPS -DisableHTTP

# Update inventory variables
ansible_port: 5986
ansible_winrm_transport: ssl
```

### 2. Secure Credentials in AWX

- ✅ Use AWX credential encryption (automatic)
- ✅ Rotate passwords regularly
- ✅ Use least privilege accounts
- ✅ Enable audit logging

### 3. Network Security

```bash
# Restrict AWX access by IP
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="9.46.241.103" port port="5985" protocol="tcp" accept' --permanent
sudo firewall-cmd --reload
```

---

## 📈 Advanced Configuration

### Create Workflow Template

1. **Navigate to**: Resources → Templates
2. **Click**: Add → Add workflow template
3. **Name**: "Complete SSMS Deployment Workflow"
4. **Click**: Visualizer
5. **Add nodes**:
   - Node 1: WinRM Setup (if needed)
   - Node 2: Install SSMS
   - Node 3: Verification
6. **Save**

### Schedule Regular Updates

1. **Go to**: Job Template → Schedules tab
2. **Click**: Add
3. **Configure**:
   ```
   Name: Monthly SSMS Update Check
   Start Date: First Sunday of month
   Frequency: Monthly
   Time: 02:00 AM
   ```

### Create Survey for User Input

1. **Edit**: Job Template
2. **Navigate to**: Survey tab
3. **Add questions**:
   - Target Server (Multiple Choice)
   - SSMS Version (Text)
   - Restart After Install (Yes/No)

---

## 📝 Quick Reference

### AWX Details
```
URL: https://9.46.241.103
Username: admin
Password: Finance@123456789
Project: STAP Deployment
Repository: https://github.com/Manish-Bhadane/stap-deployment.git
```

### File Locations on Windows Server
```
Installer: C:\Temp\SSMS-Setup-ENU.exe
Install Log: C:\Temp\SSMS_Install_Log.txt
Config File: C:\Temp\sql_connection_config.txt
SSMS Path: C:\Program Files (x86)\Microsoft SQL Server Management Studio 20.2\Common7\IDE\Ssms.exe
```

### Common Commands
```bash
# Sync AWX project
# Click Sync button in AWX UI

# Test connectivity
ansible all -i inventory.ini -m win_ping

# Run playbook manually (from AWX server)
ansible-playbook install_ssms_dynamic.yml -i inventory.ini
```

---

## ✅ Deployment Checklist

- [ ] Files pushed to GitHub repository
- [ ] AWX project synced successfully
- [ ] Inventory created with Windows servers
- [ ] Host variables configured correctly
- [ ] Credentials created and tested
- [ ] Job template created
- [ ] WinRM configured on Windows servers
- [ ] SQL Server running and accessible
- [ ] Test job executed successfully
- [ ] SSMS installed and verified
- [ ] Desktop shortcuts created
- [ ] Documentation reviewed

---

## 🎯 Summary

You now have a complete AWX-based automation for SSMS installation:

1. ✅ **AWX Project**: Connected to your GitHub repository
2. ✅ **Playbooks**: Ready for SSMS installation
3. ✅ **WinRM Setup**: Script for Windows Server preparation
4. ✅ **Job Templates**: One-click deployment
5. ✅ **Monitoring**: Real-time progress tracking
6. ✅ **Logging**: Comprehensive installation logs

**Next Action**: Follow Step 1 to push files to your repository, then proceed with the remaining steps!

---

**Made with ❤️ by Bob**

*For support, check AWX logs or Windows Server installation logs*