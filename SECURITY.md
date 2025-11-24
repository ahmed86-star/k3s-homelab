# Security Guidelines

## 🔐 Before Pushing to GitHub

This repository contains Infrastructure as Code (IaC) templates. **NEVER commit sensitive information!**

### ⚠️ Files That Should NEVER Be Committed

The `.gitignore` file is configured to protect:

- ❌ `terraform.tfvars` - Contains passwords and real IPs
- ❌ `terraform-proxmox.tfvars` - Contains Proxmox credentials
- ❌ `kubeconfig.yaml` - Cluster access credentials
- ❌ `k3s-token.txt` - Cluster join token
- ❌ `*.tfstate*` - Terraform state (may contain secrets)
- ❌ `.terraform/` - Provider plugins and cached data
- ❌ `proxmox-config/` - Proxmox configuration files

### ✅ Safe to Commit

- ✅ `*.tf` files (with placeholder values)
- ✅ `terraform.tfvars.example` - Template file
- ✅ Documentation files (*.md)
- ✅ Scripts (*.ps1) - with placeholder IPs/usernames
- ✅ `.gitignore` - Protection configuration

## 🛡️ Security Checklist

Before pushing to GitHub, verify:

1. **Check .gitignore is working:**
   ```bash
   git status
   ```
   Ensure `terraform.tfvars` is NOT listed

2. **Verify no sensitive data in tracked files:**
   ```bash
   git diff --staged
   ```
   Check for:
   - Real IP addresses
   - Passwords
   - Usernames
   - API tokens

3. **Use example configuration:**
   - Copy `terraform.tfvars.example` to `terraform.tfvars`
   - Update with YOUR real values (never commit!)

## 📝 What This Project Uses

### Placeholder Values in Documentation

All documentation uses example values:

- **IPs:** `192.168.1.10`, `192.168.1.11`, `192.168.1.12`
- **Username:** `your-username`
- **Passwords:** `YOUR_PASSWORD_HERE`

### Your Real Values (Keep Private!)

Store your actual values in `terraform.tfvars`:

```hcl
ssh_user     = "your-actual-username"
ssh_password = "your-actual-password"
master_ip    = "your.real.ip.address"
worker_ips   = ["your.worker1.ip", "your.worker2.ip"]
```

This file is protected by `.gitignore`! ✅

## 🚨 If You Accidentally Commit Secrets

If you accidentally commit sensitive data:

1. **Remove from history:**
   ```bash
   # Remove file from git history
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch terraform.tfvars" \
     --prune-empty --tag-name-filter cat -- --all
   
   # Force push
   git push origin --force --all
   ```

2. **Rotate credentials:**
   - Change all passwords
   - Change SSH keys
   - Regenerate API tokens
   - Update cluster access

3. **Update GitHub:** Consider making the repo private

## 🔒 Best Practices

### For Development

1. **Use SSH keys** instead of passwords when possible
2. **Use environment variables** for sensitive data:
   ```bash
   export TF_VAR_ssh_password="your-password"
   ```

3. **Use Terraform Cloud** for remote state (keeps state secure)

### For Production

1. **Use API tokens** instead of passwords
2. **Use HashiCorp Vault** for secrets management
3. **Enable MFA** on all accounts
4. **Use private Git repositories**
5. **Implement least privilege** access

## 📞 Questions?

- Review `.gitignore` to see what's protected
- Check `terraform.tfvars.example` for safe template
- Never share actual `terraform.tfvars` file

---

**Remember:** When in doubt, DON'T commit it! Better safe than sorry. 🔐

