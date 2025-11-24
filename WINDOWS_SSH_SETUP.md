# Windows SSH Setup Guide

This guide will help you set up SSH on Windows for the K3s Terraform deployment.

## Method 1: Using OpenSSH (Recommended)

### Install OpenSSH Client

OpenSSH is built into Windows 10/11. To install or verify:

```powershell
# Run PowerShell as Administrator

# Check if installed
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'

# Install if needed
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

### Test SSH Connections

Run the setup helper script:

```powershell
.\setup-ssh.ps1
```

Or manually test each node:

```powershell
ssh ahmed1@192.168.0.84
ssh ahmed1@192.168.0.235
ssh ahmed1@192.168.0.115
```

## Method 2: Using PuTTY (Alternative)

If you prefer PuTTY:

1. Download and install [PuTTY](https://www.putty.org/)
2. Make sure `plink.exe` is in your PATH
3. Test connectivity with PuTTY before running Terraform

## SSH Configuration for Password Authentication

### Configure SSH Config (Optional)

Create or edit: `C:\Users\YourUsername\.ssh\config`

```
Host k3s-master
    HostName 192.168.0.84
    User ahmed1
    StrictHostKeyChecking no
    
Host k3s-worker-1
    HostName 192.168.0.235
    User ahmed1
    StrictHostKeyChecking no
    
Host k3s-worker-2
    HostName 192.168.0.115
    User ahmed1
    StrictHostKeyChecking no
```

## Troubleshooting

### "Permission denied" Error

Make sure password authentication is enabled on your Ubuntu nodes:

```bash
# On each Ubuntu node, edit SSH config
sudo nano /etc/ssh/sshd_config

# Ensure these lines are set:
PasswordAuthentication yes
PermitRootLogin no

# Restart SSH
sudo systemctl restart sshd
```

### "Connection refused" Error

1. Check if SSH service is running on the node:
   ```bash
   sudo systemctl status sshd
   ```

2. Check firewall rules:
   ```bash
   sudo ufw status
   sudo ufw allow 22/tcp
   ```

### "Host key verification failed"

First-time connections require accepting the host key:

```powershell
# Accept the host key for each node
ssh-keyscan -H 192.168.0.84 >> ~/.ssh/known_hosts
ssh-keyscan -H 192.168.0.235 >> ~/.ssh/known_hosts
ssh-keyscan -H 192.168.0.115 >> ~/.ssh/known_hosts
```

## Alternative: SSH Key Authentication (More Secure)

Instead of password authentication, you can use SSH keys:

### Generate SSH Key

```powershell
ssh-keygen -t ed25519 -C "k3s-homelab"
```

### Copy Key to Nodes

```powershell
# You'll need to enter password once per node
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh ahmed1@192.168.0.84 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh ahmed1@192.168.0.235 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh ahmed1@192.168.0.115 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Update Terraform Configuration

If using SSH keys, you can modify `main.tf` to remove password prompts.

## Verify Setup

Run the verification script:

```powershell
.\setup-ssh.ps1
```

All nodes should show "✓ reachable" before proceeding with Terraform deployment.

---

**Ready?** Head back to the main [README.md](README.md) to deploy your K3s cluster!



