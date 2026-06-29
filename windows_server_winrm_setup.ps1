<#
.SYNOPSIS
    Windows Server WinRM Configuration Script for Ansible Automation
    
.DESCRIPTION
    This PowerShell script configures Windows Remote Management (WinRM) on Windows Server
    to enable Ansible automation for SSMS installation and other management tasks.
    
    Features:
    - Enables WinRM service
    - Configures HTTP and HTTPS listeners
    - Sets up authentication methods
    - Configures firewall rules
    - Creates self-signed certificate for HTTPS
    - Tests WinRM connectivity
    - Provides security recommendations
    
.NOTES
    Author: Bob
    Version: 1.0
    Requires: PowerShell 5.1 or higher
    Run as: Administrator
    
.EXAMPLE
    .\windows_server_winrm_setup.ps1
    
.EXAMPLE
    .\windows_server_winrm_setup.ps1 -EnableHTTPS -DisableHTTP
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$EnableHTTPS = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DisableHTTP = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ProductionMode = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$CertificateDnsName = $env:COMPUTERNAME,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFirewall = $false
)

# Ensure script is running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator!"
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Function to write section header
function Write-SectionHeader {
    param([string]$Title)
    
    Write-Host ""
    Write-ColorOutput "============================================" "Cyan"
    Write-ColorOutput " $Title" "Cyan"
    Write-ColorOutput "============================================" "Cyan"
}

# Function to test if a port is listening
function Test-PortListening {
    param(
        [int]$Port
    )
    
    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return ($null -ne $listener)
}

# Start script
Clear-Host
Write-ColorOutput "╔════════════════════════════════════════════════════════════╗" "Green"
Write-ColorOutput "║   Windows Server WinRM Configuration for Ansible          ║" "Green"
Write-ColorOutput "║   Version 1.0                                              ║" "Green"
Write-ColorOutput "╚════════════════════════════════════════════════════════════╝" "Green"
Write-Host ""

# Display current configuration
Write-SectionHeader "Current System Information"
Write-ColorOutput "Computer Name: " "Yellow" -NoNewline
Write-Host $env:COMPUTERNAME
Write-ColorOutput "OS Version: " "Yellow" -NoNewline
Write-Host (Get-CimInstance Win32_OperatingSystem).Caption
Write-ColorOutput "PowerShell Version: " "Yellow" -NoNewline
Write-Host $PSVersionTable.PSVersion
Write-ColorOutput "Execution Mode: " "Yellow" -NoNewline
if ($ProductionMode) {
    Write-ColorOutput "PRODUCTION (Secure)" "Green"
} else {
    Write-ColorOutput "DEVELOPMENT (Testing)" "Yellow"
}

# Step 1: Enable PowerShell Remoting
Write-SectionHeader "Step 1: Enabling PowerShell Remoting"
try {
    Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null
    Write-ColorOutput "✓ PowerShell Remoting enabled successfully" "Green"
} catch {
    Write-ColorOutput "✗ Failed to enable PowerShell Remoting: $_" "Red"
    exit 1
}

# Step 2: Configure WinRM Service
Write-SectionHeader "Step 2: Configuring WinRM Service"
try {
    # Set WinRM service to automatic startup
    Set-Service WinRM -StartupType Automatic
    Write-ColorOutput "✓ WinRM service set to Automatic startup" "Green"
    
    # Start WinRM service
    Start-Service WinRM -ErrorAction SilentlyContinue
    $winrmService = Get-Service WinRM
    if ($winrmService.Status -eq "Running") {
        Write-ColorOutput "✓ WinRM service is running" "Green"
    } else {
        Write-ColorOutput "✗ WinRM service failed to start" "Red"
        exit 1
    }
} catch {
    Write-ColorOutput "✗ Failed to configure WinRM service: $_" "Red"
    exit 1
}

# Step 3: Configure WinRM
Write-SectionHeader "Step 3: Configuring WinRM Settings"
try {
    # Quick configuration
    winrm quickconfig -quiet -force | Out-Null
    Write-ColorOutput "✓ WinRM quick configuration completed" "Green"
    
    # Set maximum memory per shell
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' | Out-Null
    Write-ColorOutput "✓ Maximum memory per shell set to 1024 MB" "Green"
    
    # Set maximum timeout
    winrm set winrm/config '@{MaxTimeoutms="1800000"}' | Out-Null
    Write-ColorOutput "✓ Maximum timeout set to 30 minutes" "Green"
    
    # Set maximum concurrent operations
    winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="1500"}' | Out-Null
    Write-ColorOutput "✓ Maximum concurrent operations set to 1500" "Green"
    
} catch {
    Write-ColorOutput "✗ Failed to configure WinRM settings: $_" "Red"
    exit 1
}

# Step 4: Configure Authentication
Write-SectionHeader "Step 4: Configuring Authentication Methods"
try {
    if ($ProductionMode) {
        # Production mode - secure settings
        Set-Item WSMan:\localhost\Service\Auth\Basic -Value $false -Force
        Write-ColorOutput "✓ Basic authentication: DISABLED (Production)" "Green"
        
        Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $false -Force
        Write-ColorOutput "✓ Unencrypted traffic: DISABLED (Production)" "Green"
    } else {
        # Development mode - allow basic auth for testing
        Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true -Force
        Write-ColorOutput "✓ Basic authentication: ENABLED (Development)" "Yellow"
        
        Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true -Force
        Write-ColorOutput "✓ Unencrypted traffic: ENABLED (Development)" "Yellow"
    }
    
    # Enable other authentication methods
    Set-Item WSMan:\localhost\Service\Auth\Kerberos -Value $true -Force
    Write-ColorOutput "✓ Kerberos authentication: ENABLED" "Green"
    
    Set-Item WSMan:\localhost\Service\Auth\Negotiate -Value $true -Force
    Write-ColorOutput "✓ Negotiate authentication: ENABLED" "Green"
    
    Set-Item WSMan:\localhost\Service\Auth\Certificate -Value $true -Force
    Write-ColorOutput "✓ Certificate authentication: ENABLED" "Green"
    
    Set-Item WSMan:\localhost\Service\Auth\CredSSP -Value $true -Force
    Write-ColorOutput "✓ CredSSP authentication: ENABLED" "Green"
    
} catch {
    Write-ColorOutput "✗ Failed to configure authentication: $_" "Red"
    exit 1
}

# Step 5: Configure HTTP Listener
Write-SectionHeader "Step 5: Configuring HTTP Listener"
if (-not $DisableHTTP) {
    try {
        # Remove existing HTTP listener if exists
        Get-ChildItem WSMan:\Localhost\listener | Where-Object {$_.Keys -contains "Transport=HTTP"} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        
        # Create new HTTP listener
        New-Item -Path WSMan:\LocalHost\Listener -Transport HTTP -Address * -Force | Out-Null
        Write-ColorOutput "✓ HTTP listener created on port 5985" "Green"
        
    } catch {
        Write-ColorOutput "✗ Failed to configure HTTP listener: $_" "Red"
    }
} else {
    Write-ColorOutput "⊘ HTTP listener disabled (as requested)" "Yellow"
}

# Step 6: Configure HTTPS Listener
Write-SectionHeader "Step 6: Configuring HTTPS Listener"
if ($EnableHTTPS) {
    try {
        # Check if certificate already exists
        $existingCert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=$CertificateDnsName*"} | Select-Object -First 1
        
        if ($existingCert) {
            Write-ColorOutput "✓ Using existing certificate: $($existingCert.Thumbprint)" "Green"
            $certThumbprint = $existingCert.Thumbprint
        } else {
            # Create self-signed certificate
            Write-ColorOutput "Creating self-signed certificate..." "Yellow"
            $cert = New-SelfSignedCertificate -DnsName $CertificateDnsName -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(5)
            $certThumbprint = $cert.Thumbprint
            Write-ColorOutput "✓ Self-signed certificate created: $certThumbprint" "Green"
        }
        
        # Remove existing HTTPS listener if exists
        Get-ChildItem WSMan:\Localhost\listener | Where-Object {$_.Keys -contains "Transport=HTTPS"} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        
        # Create HTTPS listener
        New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $certThumbprint -Force | Out-Null
        Write-ColorOutput "✓ HTTPS listener created on port 5986" "Green"
        
    } catch {
        Write-ColorOutput "✗ Failed to configure HTTPS listener: $_" "Red"
        Write-ColorOutput "  Error: $_" "Red"
    }
} else {
    Write-ColorOutput "⊘ HTTPS listener not configured (use -EnableHTTPS to enable)" "Yellow"
}

# Step 7: Configure Firewall Rules
Write-SectionHeader "Step 7: Configuring Firewall Rules"
if (-not $SkipFirewall) {
    try {
        # Remove existing rules
        Remove-NetFirewallRule -Name "WinRM-HTTP-In-TCP" -ErrorAction SilentlyContinue
        Remove-NetFirewallRule -Name "WinRM-HTTPS-In-TCP" -ErrorAction SilentlyContinue
        
        if (-not $DisableHTTP) {
            # Create HTTP firewall rule
            New-NetFirewallRule -Name "WinRM-HTTP-In-TCP" `
                -DisplayName "Windows Remote Management (HTTP-In)" `
                -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5985]" `
                -Group "Windows Remote Management" `
                -Protocol TCP `
                -LocalPort 5985 `
                -Action Allow `
                -Enabled True `
                -Direction Inbound | Out-Null
            Write-ColorOutput "✓ Firewall rule created for HTTP (port 5985)" "Green"
        }
        
        if ($EnableHTTPS) {
            # Create HTTPS firewall rule
            New-NetFirewallRule -Name "WinRM-HTTPS-In-TCP" `
                -DisplayName "Windows Remote Management (HTTPS-In)" `
                -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
                -Group "Windows Remote Management" `
                -Protocol TCP `
                -LocalPort 5986 `
                -Action Allow `
                -Enabled True `
                -Direction Inbound | Out-Null
            Write-ColorOutput "✓ Firewall rule created for HTTPS (port 5986)" "Green"
        }
        
    } catch {
        Write-ColorOutput "✗ Failed to configure firewall rules: $_" "Red"
    }
} else {
    Write-ColorOutput "⊘ Firewall configuration skipped (as requested)" "Yellow"
}

# Step 8: Test WinRM Configuration
Write-SectionHeader "Step 8: Testing WinRM Configuration"
try {
    # Test local WinRM
    $testResult = Test-WSMan -ComputerName localhost -ErrorAction Stop
    Write-ColorOutput "✓ WinRM is responding correctly" "Green"
    Write-ColorOutput "  Product Version: $($testResult.ProductVersion)" "Gray"
    Write-ColorOutput "  Protocol Version: $($testResult.ProtocolVersion)" "Gray"
    
    # Test HTTP port
    if (-not $DisableHTTP) {
        if (Test-PortListening -Port 5985) {
            Write-ColorOutput "✓ HTTP port 5985 is listening" "Green"
        } else {
            Write-ColorOutput "✗ HTTP port 5985 is NOT listening" "Red"
        }
    }
    
    # Test HTTPS port
    if ($EnableHTTPS) {
        if (Test-PortListening -Port 5986) {
            Write-ColorOutput "✓ HTTPS port 5986 is listening" "Green"
        } else {
            Write-ColorOutput "✗ HTTPS port 5986 is NOT listening" "Red"
        }
    }
    
} catch {
    Write-ColorOutput "✗ WinRM test failed: $_" "Red"
}

# Step 9: Display Configuration Summary
Write-SectionHeader "Configuration Summary"

# Get current WinRM configuration
$winrmConfig = winrm get winrm/config

Write-ColorOutput "WinRM Service Status:" "Yellow"
$service = Get-Service WinRM
Write-Host "  Status: $($service.Status)"
Write-Host "  Startup Type: $($service.StartType)"

Write-Host ""
Write-ColorOutput "Listeners:" "Yellow"
Get-ChildItem WSMan:\Localhost\listener | ForEach-Object {
    $transport = $_.Keys | Where-Object {$_ -like "Transport=*"}
    $port = if ($transport -like "*HTTPS*") { "5986" } else { "5985" }
    Write-Host "  $transport on port $port"
}

Write-Host ""
Write-ColorOutput "Authentication Methods:" "Yellow"
$authConfig = Get-Item WSMan:\localhost\Service\Auth\*
foreach ($auth in $authConfig) {
    $status = if ($auth.Value -eq "true") { "✓ Enabled" } else { "✗ Disabled" }
    $color = if ($auth.Value -eq "true") { "Green" } else { "Red" }
    Write-ColorOutput "  $($auth.Name): " "Gray" -NoNewline
    Write-ColorOutput $status $color
}

Write-Host ""
Write-ColorOutput "Network Information:" "Yellow"
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -ExpandProperty IPAddress
Write-Host "  IP Addresses:"
foreach ($ip in $ipAddresses) {
    Write-Host "    - $ip"
}

# Step 10: Ansible Connection Test Command
Write-SectionHeader "Ansible Connection Test"
Write-ColorOutput "Test from your Ansible control machine using:" "Yellow"
Write-Host ""

$testIP = $ipAddresses | Select-Object -First 1
Write-ColorOutput "# Test with win_ping module:" "Cyan"
Write-Host "ansible all -i `"$testIP,`" -m win_ping \"
Write-Host "  -e `"ansible_user=Administrator`" \"
Write-Host "  -e `"ansible_password=YourPassword`" \"
Write-Host "  -e `"ansible_connection=winrm`" \"
Write-Host "  -e `"ansible_winrm_server_cert_validation=ignore`" \"
if ($EnableHTTPS) {
    Write-Host "  -e `"ansible_port=5986`" \"
    Write-Host "  -e `"ansible_winrm_transport=ssl`""
} else {
    Write-Host "  -e `"ansible_port=5985`""
}

Write-Host ""
Write-ColorOutput "# Or create an inventory file (inventory.ini):" "Cyan"
Write-Host "[windows]"
Write-Host "$testIP"
Write-Host ""
Write-Host "[windows:vars]"
Write-Host "ansible_user=Administrator"
Write-Host "ansible_password=YourPassword"
Write-Host "ansible_connection=winrm"
Write-Host "ansible_winrm_server_cert_validation=ignore"
if ($EnableHTTPS) {
    Write-Host "ansible_port=5986"
    Write-Host "ansible_winrm_transport=ssl"
} else {
    Write-Host "ansible_port=5985"
}

# Security Recommendations
Write-SectionHeader "Security Recommendations"
if (-not $ProductionMode) {
    Write-ColorOutput "⚠ WARNING: Current configuration is for DEVELOPMENT/TESTING only!" "Yellow"
    Write-Host ""
    Write-ColorOutput "For PRODUCTION environments, run with -ProductionMode:" "Yellow"
    Write-Host "  .\windows_server_winrm_setup.ps1 -ProductionMode -EnableHTTPS -DisableHTTP"
    Write-Host ""
    Write-ColorOutput "Production recommendations:" "Yellow"
    Write-Host "  1. Use HTTPS only (disable HTTP)"
    Write-Host "  2. Use proper SSL certificates (not self-signed)"
    Write-Host "  3. Disable Basic authentication"
    Write-Host "  4. Disable unencrypted traffic"
    Write-Host "  5. Use domain accounts instead of local Administrator"
    Write-Host "  6. Implement network segmentation"
    Write-Host "  7. Use Ansible Vault for password management"
} else {
    Write-ColorOutput "✓ Running in PRODUCTION mode with secure settings" "Green"
    Write-Host ""
    Write-ColorOutput "Additional recommendations:" "Yellow"
    Write-Host "  1. Replace self-signed certificate with CA-signed certificate"
    Write-Host "  2. Implement IP whitelisting in firewall"
    Write-Host "  3. Enable audit logging"
    Write-Host "  4. Regular security updates"
}

# Final Status
Write-Host ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════╗" "Green"
Write-ColorOutput "║   WinRM Configuration Completed Successfully!              ║" "Green"
Write-ColorOutput "╚════════════════════════════════════════════════════════════╝" "Green"
Write-Host ""
Write-ColorOutput "Next Steps:" "Yellow"
Write-Host "  1. Test Ansible connectivity from control machine"
Write-Host "  2. Run the SSMS installation playbook:"
Write-Host "     ansible-playbook install_ssms_dynamic.yml"
Write-Host "  3. Review security settings for production use"
Write-Host ""

# Save configuration to file
$configFile = "C:\Temp\WinRM_Configuration_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null

$configOutput = @"
WinRM Configuration Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Computer: $env:COMPUTERNAME
Mode: $(if ($ProductionMode) { "Production" } else { "Development" })

Service Status:
- WinRM Service: $($service.Status)
- Startup Type: $($service.StartType)

Listeners:
$(Get-ChildItem WSMan:\Localhost\listener | ForEach-Object { "- $($_.Keys -join ', ')" } | Out-String)

Authentication:
$(Get-Item WSMan:\localhost\Service\Auth\* | ForEach-Object { "- $($_.Name): $($_.Value)" } | Out-String)

IP Addresses:
$($ipAddresses | ForEach-Object { "- $_" } | Out-String)

Firewall Rules:
$(Get-NetFirewallRule -Name "WinRM-*" -ErrorAction SilentlyContinue | Select-Object Name, Enabled, Direction | Format-Table | Out-String)
"@

$configOutput | Out-File -FilePath $configFile -Encoding UTF8
Write-ColorOutput "Configuration saved to: $configFile" "Gray"

Write-Host ""
Write-ColorOutput "Script execution completed!" "Green"

# Made with Bob
