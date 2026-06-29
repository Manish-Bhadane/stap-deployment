# 🚀 AWX Dynamic SSMS Installation with Survey (No Inventory Required)

## 📋 Overview

This guide shows how to set up AWX for **fully dynamic SSMS installation** using the Survey feature. Users will input server details at runtime through a web form - **no need to maintain server inventory**.

---

## ✅ Prerequisites

- ✅ AWX installed and accessible: https://9.46.241.103
- ✅ Files pushed to GitHub: https://github.com/Manish-Bhadane/stap-deployment
- ✅ Windows Server with WinRM enabled
- ✅ SQL Server installed and running

---

## 🎯 Step 1: Sync AWX Project (2 minutes)

1. **Login to AWX**: https://9.46.241.103
   - Username: `admin`
   - Password: `Finance@123456789`

2. **Navigate to**: Resources → Projects → **STAP Deployment**

3. **Click**: Sync button (🔄 circular arrow icon)

4. **Wait**: For sync to complete
   - Status should show: ✅ **Successful**
   - Commit hash: `3612ae3`

5. **Verify**: New playbook appears
   - Go to: Resources → Templates → Add job template
   - Check if `install_ssms_dynamic.yml` is available in playbook dropdown

---

## 📦 Step 2: Create Minimal Inventory (5 minutes)

Even for dynamic execution, AWX requires a minimal inventory. We'll create a dummy one:

1. **Navigate to**: Resources → Inventories

2. **Click**: Add → Add inventory

3. **Fill in**:
   ```
   Name: Dynamic Execution Inventory
   Description: Minimal inventory for dynamic job execution
   Organization: Default
   ```

4. **Click**: Save

5. **Add a localhost host** (required by AWX):
   - Click on the inventory: **Dynamic Execution Inventory**
   - Go to: **Hosts** tab
   - Click: **Add** (+)
   - Fill in:
     ```
     Name: localhost
     Description: Local execution host for dynamic targeting
     ```
   - **Variables** (YAML):
     ```yaml
     ---
     ansible_connection: local
     ansible_python_interpreter: /usr/bin/python3
     ```
   - Click: **Save**

---

## 🔐 Step 3: Create Machine Credential Type (One-time Setup)

Since we're using Survey for credentials, we need a custom credential type:

### Option A: Use Built-in Machine Credential (Simpler)

1. **Navigate to**: Resources → Credentials
2. **Click**: Add (+)
3. **Fill in**:
   ```
   Name: Dynamic Windows Credentials
   Description: Placeholder for survey-based credentials
   Organization: Default
   Credential Type: Machine
   Username: placeholder
   Password: placeholder
   ```
4. **Click**: Save

> **Note**: The actual credentials will come from the Survey, not this credential object.

### Option B: Skip Credentials (Use Survey Only)

You can skip creating credentials entirely and rely solely on Survey inputs. AWX will use the Survey variables directly in the playbook.

---

## 🎬 Step 4: Create Job Template with Survey (10 minutes)

### 4.1 Create Job Template

1. **Navigate to**: Resources → Templates

2. **Click**: Add → Add job template

3. **Fill in General Settings**:
   ```
   Name: SSMS Dynamic Installation (Survey)
   Description: Install SSMS on any Windows Server - Input details at runtime
   Job Type: Run
   Inventory: Dynamic Execution Inventory
   Project: STAP Deployment
   Playbook: install_ssms_dynamic.yml
   Execution Environment: Default execution environment
   ```

4. **Credentials**: 
   - Leave empty OR select "Dynamic Windows Credentials" (optional)
   - Survey will provide the actual credentials

5. **Options** (Check these):
   - ✅ **Prompt on launch** (for Extra Variables)
   - ✅ **Enable Fact Storage**
   - ⬜ Privilege Escalation (not needed for Windows)

6. **Extra Variables** (Important - this makes it work):
   ```yaml
   ---
   # These will be overridden by Survey inputs
   target_host: "{{ survey_target_host }}"
   windows_username: "{{ survey_windows_username }}"
   windows_password: "{{ survey_windows_password }}"
   sql_username: "{{ survey_sql_username }}"
   sql_password: "{{ survey_sql_password }}"
   ssms_version: "{{ survey_ssms_version }}"
   ssms_download_url: "{{ survey_ssms_download_url }}"
   restart_after_install: "{{ survey_restart_after_install }}"
   ```

7. **Click**: Save

### 4.2 Add Survey to Job Template

1. **Click on**: The job template you just created: **SSMS Dynamic Installation (Survey)**

2. **Navigate to**: **Survey** tab

3. **Click**: Add

4. **Add Survey Questions** (Add each question one by one):

#### Question 1: Target Server IP
```
Question: Target Windows Server IP or Hostname
Description: Enter the IP address or hostname of the Windows Server
Answer Variable Name: survey_target_host
Answer Type: Text
Minimum Length: 7
Maximum Length: 253
Default Answer: (leave empty)
Required: ✅ Yes
```

#### Question 2: Windows Username
```
Question: Windows Administrator Username
Description: Username with admin rights on the Windows Server
Answer Variable Name: survey_windows_username
Answer Type: Text
Minimum Length: 1
Maximum Length: 100
Default Answer: Administrator
Required: ✅ Yes
```

#### Question 3: Windows Password
```
Question: Windows Administrator Password
Description: Password for the Windows admin account
Answer Variable Name: survey_windows_password
Answer Type: Password
Minimum Length: 1
Maximum Length: 100
Default Answer: (leave empty)
Required: ✅ Yes
```

#### Question 4: SQL Server Username
```
Question: SQL Server Database Username
Description: SQL Server authentication username (e.g., sa)
Answer Variable Name: survey_sql_username
Answer Type: Text
Minimum Length: 1
Maximum Length: 100
Default Answer: sa
Required: ✅ Yes
```

#### Question 5: SQL Server Password
```
Question: SQL Server Database Password
Description: Password for SQL Server authentication
Answer Variable Name: survey_sql_password
Answer Type: Password
Minimum Length: 1
Maximum Length: 100
Default Answer: (leave empty)
Required: ✅ Yes
```

#### Question 6: SSMS Version
```
Question: SSMS Version to Install
Description: Version number (e.g., 20.2 for latest)
Answer Variable Name: survey_ssms_version
Answer Type: Text
Minimum Length: 1
Maximum Length: 10
Default Answer: 20.2
Required: ✅ Yes
```

#### Question 7: SSMS Download URL
```
Question: SSMS Download URL
Description: Direct download link for SSMS installer
Answer Variable Name: survey_ssms_download_url
Answer Type: Text
Minimum Length: 10
Maximum Length: 500
Default Answer: https://aka.ms/ssmsfullsetup
Required: ✅ Yes
```

#### Question 8: Restart After Install
```
Question: Restart Server After Installation?
Description: Choose whether to restart the server after SSMS installation
Answer Variable Name: survey_restart_after_install
Answer Type: Multiple Choice (single select)
Multiple Choice Options:
  - no
  - yes
Default Answer: no
Required: ✅ Yes
```

5. **Click**: Save for each question

6. **Enable Survey**:
   - Toggle the **Survey Enabled** switch to ON
   - Click: Save

---

## 🖥️ Step 5: Prepare Windows Server (10 minutes)

Run this on your Windows Server as Administrator:

```powershell
# Download WinRM setup script from GitHub
$url = "https://raw.githubusercontent.com/Manish-Bhadane/stap-deployment/main/windows_server_winrm_setup.ps1"
$output = "C:\Temp\winrm_setup.ps1"

# Create Temp directory if it doesn't exist
New-Item -ItemType Directory -Force -Path C:\Temp

# Download the script
Invoke-WebRequest -Uri $url -OutFile $output

# Set execution policy and run
Set-ExecutionPolicy Bypass -Scope Process -Force
& $output

# Verify WinRM is running
Test-WSMan
Get-Service WinRM

# Check firewall rule
Get-NetFirewallRule -Name "WinRM-HTTP-In-TCP"

# Test connectivity
Test-NetConnection -ComputerName localhost -Port 5985
```

### Verify SQL Server

```powershell
# Check SQL Server service
Get-Service MSSQLSERVER

# Test SQL Server connection
sqlcmd -S localhost -U sa -P YourPassword -Q "SELECT @@VERSION"

# If authentication fails, enable SQL Server Authentication:
# 1. Open SQL Server Configuration Manager
# 2. SQL Server Services → SQL Server (MSSQLSERVER) → Properties
# 3. Security tab → Set "Server authentication" to "SQL Server and Windows Authentication mode"
# 4. Restart SQL Server
Restart-Service MSSQLSERVER
```

---

## ▶️ Step 6: Launch Dynamic SSMS Installation (30-45 minutes)

### 6.1 Launch the Job

1. **Navigate to**: Resources → Templates

2. **Find**: **SSMS Dynamic Installation (Survey)**

3. **Click**: Launch button (🚀 rocket icon)

4. **Survey Form Appears** - Fill in the details:
   ```
   Target Windows Server IP: 192.168.1.100
   Windows Administrator Username: Administrator
   Windows Administrator Password: ********
   SQL Server Database Username: sa
   SQL Server Database Password: ********
   SSMS Version: 20.2
   SSMS Download URL: https://aka.ms/ssmsfullsetup
   Restart Server After Installation: no
   ```

5. **Click**: Next (or Launch)

6. **Confirm**: Review the summary and click **Launch**

### 6.2 Monitor Installation

The job output will show real-time progress:

```
PLAY [Gather Dynamic Input for SSMS Installation] ****************************

TASK [Add target host to inventory dynamically] ******************************
ok: [localhost]

TASK [Display configuration summary] *****************************************
ok: [localhost] => {
    "msg": [
        "==========================================",
        "Configuration Summary",
        "==========================================",
        "Target Server: 192.168.1.100",
        "Windows User: Administrator",
        "SQL DB User: sa",
        "SSMS Version: 20.2",
        "Restart After Install: no",
        "=========================================="
    ]
}

PLAY [Install MS SQL Server Management Studio on Windows] ********************

TASK [Test WinRM connectivity] ***********************************************
ok: [192.168.1.100]

TASK [Check if SSMS is already installed] ************************************
ok: [192.168.1.100]

TASK [Download SSMS installer] ***********************************************
changed: [192.168.1.100]
(Downloading 600+ MB - takes 5-10 minutes)

TASK [Install SSMS silently] *************************************************
changed: [192.168.1.100]
(Installation in progress - takes 15-30 minutes)

TASK [Verify SSMS installation] **********************************************
ok: [192.168.1.100]
SUCCESS: SSMS Version 20.2.30.0 installed

PLAY RECAP *******************************************************************
192.168.1.100 : ok=25   changed=8    unreachable=0    failed=0
```

---

## 📊 Installation Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| Survey Input | 1-2 min | User fills in server details |
| Pre-flight Checks | 1-2 min | WinRM, SQL connectivity tests |
| SSMS Download | 5-10 min | Download 600+ MB installer |
| SSMS Installation | 15-30 min | Silent installation |
| Post-Install Tasks | 2-3 min | Shortcuts, validation |
| **Total** | **25-45 min** | Complete automation |

---

## ✅ Post-Installation Verification

### On Windows Server

```powershell
# Verify SSMS is installed
Test-Path "C:\Program Files (x86)\Microsoft SQL Server Management Studio*\Common7\IDE\Ssms.exe"

# Get SSMS version
$ssms = Get-ChildItem "C:\Program Files (x86)\Microsoft SQL Server Management Studio*\Common7\IDE\Ssms.exe"
$ssms.VersionInfo.FileVersion

# Check desktop shortcut
Test-Path "C:\Users\Public\Desktop\SQL Server Management Studio.lnk"

# View installation log
Get-Content C:\Temp\SSMS_Install_Log.txt -Tail 50

# View SQL connection config
Get-Content C:\Temp\sql_connection_config.txt
```

### Launch SSMS

1. **Double-click**: Desktop shortcut "SQL Server Management Studio"
2. **Connect to SQL Server**:
   - Server name: `localhost` or your server IP
   - Authentication: `SQL Server Authentication`
   - Login: `sa` (or your SQL username)
   - Password: [Your SQL password]
3. **Click**: Connect

---

## 🔍 Troubleshooting

### Issue 1: Survey Not Showing

**Solution:**
- Ensure Survey is **Enabled** in the job template
- Check that all survey questions are saved
- Try refreshing the browser

### Issue 2: WinRM Connection Failed

**Solution:**
```powershell
# On Windows Server
Enable-PSRemoting -Force
winrm quickconfig -q
Test-WSMan

# Check firewall
Get-NetFirewallRule -Name "WinRM-HTTP-In-TCP"
New-NetFirewallRule -Name "WinRM-HTTP-In-TCP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985
```

### Issue 3: Variables Not Passed to Playbook

**Solution:**
- Verify Extra Variables in job template use correct survey variable names
- Check that survey variable names match: `survey_target_host`, `survey_windows_username`, etc.
- Ensure "Prompt on launch" is enabled for Extra Variables

### Issue 4: SQL Server Connection Failed

**Solution:**
```powershell
# Enable SQL Server Authentication
# 1. Open SQL Server Management Studio (if already installed)
# 2. Connect with Windows Authentication
# 3. Right-click server → Properties → Security
# 4. Select "SQL Server and Windows Authentication mode"
# 5. Restart SQL Server
Restart-Service MSSQLSERVER

# Test connection
sqlcmd -S localhost -U sa -P YourPassword -Q "SELECT @@VERSION"
```

---

## 🎯 Advantages of Survey-Based Approach

✅ **No Inventory Management**: Don't need to pre-configure servers  
✅ **On-Demand Execution**: Install SSMS on any server anytime  
✅ **Secure**: Credentials entered at runtime, not stored  
✅ **User-Friendly**: Web form interface, no CLI knowledge needed  
✅ **Flexible**: Different servers, different credentials each time  
✅ **Audit Trail**: AWX logs all executions with input parameters  

---

## 📋 Quick Reference

### AWX Access
```
URL: https://9.46.241.103
Username: admin
Password: Finance@123456789
```

### Job Template
```
Name: SSMS Dynamic Installation (Survey)
Inventory: Dynamic Execution Inventory
Playbook: install_ssms_dynamic.yml
Survey: Enabled (8 questions)
```

### Survey Variables
```yaml
survey_target_host: Windows Server IP
survey_windows_username: Admin username
survey_windows_password: Admin password
survey_sql_username: SQL username
survey_sql_password: SQL password
survey_ssms_version: SSMS version
survey_ssms_download_url: Download URL
survey_restart_after_install: yes/no
```

### File Locations on Windows
```
Installer: C:\Temp\SSMS-Setup-ENU.exe
Install Log: C:\Temp\SSMS_Install_Log.txt
Config File: C:\Temp\sql_connection_config.txt
SSMS Path: C:\Program Files (x86)\Microsoft SQL Server Management Studio 20.2\Common7\IDE\Ssms.exe
```

---

## 🚀 Usage Workflow

1. **User**: Opens AWX → Launches "SSMS Dynamic Installation (Survey)"
2. **Survey**: User fills in server IP, credentials, SSMS version
3. **AWX**: Validates inputs and starts job
4. **Ansible**: Connects to target server dynamically
5. **Installation**: Downloads and installs SSMS silently
6. **Verification**: Tests SSMS and SQL connectivity
7. **Completion**: User receives success notification

**Total Time**: 25-45 minutes (mostly automated)

---

## 📊 Example Survey Inputs

### Production Server
```
Target: 10.20.30.40
Windows User: Administrator
Windows Pass: Prod@Pass123
SQL User: sa
SQL Pass: SqlProd@123
SSMS Version: 20.2
Download URL: https://aka.ms/ssmsfullsetup
Restart: no
```

### Development Server
```
Target: 192.168.1.100
Windows User: devadmin
Windows Pass: Dev@Pass123
SQL User: sa
SQL Pass: SqlDev@123
SSMS Version: 19.3
Download URL: https://aka.ms/ssmsfullsetup
Restart: yes
```

---

## ✅ Deployment Checklist

- [x] Files pushed to GitHub (commit: 3612ae3)
- [ ] AWX project synced
- [ ] Minimal inventory created (Dynamic Execution Inventory)
- [ ] Job template created
- [ ] Survey added with 8 questions
- [ ] Survey enabled
- [ ] WinRM configured on target Windows servers
- [ ] SQL Server running on target servers
- [ ] Test execution completed successfully
- [ ] SSMS verified on target server

---

## 🎉 Success!

You now have a **fully dynamic SSMS installation system** where:
- ✅ No need to maintain server inventory
- ✅ Users input server details via web form
- ✅ Credentials are secure (entered at runtime)
- ✅ Can install on any Windows Server on-demand
- ✅ Complete automation from download to verification

**Next Action**: Sync AWX project and create the job template with survey!

---

**Made with ❤️ by Bob**

*For support, check AWX job output or Windows Server logs at C:\Temp\SSMS_Install_Log.txt*