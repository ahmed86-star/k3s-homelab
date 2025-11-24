# Deploy K3s Cluster RIGHT NOW! 🚀

Your VMs are ready. Let's install K3s!

## ✅ Your Setup
- Master: 192.168.0.84 (will run K3s server)
- Worker 1: 192.168.0.235 (will run K3s agent)
- Worker 2: 192.168.0.115 (will run K3s agent)
- Username: ahmed1

## 🚀 3-Step Deployment

### Step 1: Set Your Password

Open PowerShell and edit the configuration:

```powershell
notepad terraform.tfvars
```

Change this line:
```
ssh_password = "YOUR_PASSWORD_HERE"
```

To your actual password:
```
ssh_password = "your-actual-password"
```

Save and close!

### Step 2: Test SSH Connectivity

```powershell
# Test SSH to all nodes
.\setup-ssh.ps1

# Or test manually:
ssh ahmed1@192.168.0.84
ssh ahmed1@192.168.0.235
ssh ahmed1@192.168.0.115
```

All should connect successfully!

### Step 3: Deploy K3s Cluster

```powershell
# Initialize Terraform (first time only)
terraform init

# Deploy everything!
terraform apply
```

Type `yes` when asked.

**Wait 3-5 minutes** while Terraform:
1. Installs K3s server on master (192.168.0.84)
2. Gets the cluster token
3. Installs K3s agent on worker 1 (192.168.0.235)
4. Installs K3s agent on worker 2 (192.168.0.115)
5. Downloads kubeconfig to your machine

## ✅ Verify Your Cluster

```powershell
# Set kubeconfig
$env:KUBECONFIG="$PWD\kubeconfig.yaml"

# Check all nodes
kubectl get nodes

# Should show:
# NAME           STATUS   ROLES                  AGE   VERSION
# k3s-master     Ready    control-plane,master   1m    v1.28.5+k3s1
# k3s-worker-1   Ready    <none>                 45s   v1.28.5+k3s1
# k3s-worker-2   Ready    <none>                 40s   v1.28.5+k3s1
```

## 🎯 Test Connectivity Between Nodes

```powershell
# Check cluster info
kubectl cluster-info

# Check all pods (should see system pods running)
kubectl get pods -A

# Check node details
kubectl get nodes -o wide
```

All nodes should show "Ready" status!

## 🔧 If You Need kubectl

```powershell
# Install kubectl (if not installed)
choco install kubernetes-cli

# Or download from:
# https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

## 🎉 What's Next?

Your cluster is ready for workloads!

### Test Deployment:

```powershell
# Deploy nginx
kubectl create deployment nginx --image=nginx

# Check it
kubectl get pods

# Expose it
kubectl expose deployment nginx --port=80 --type=NodePort

# Get the port
kubectl get svc nginx
```

### Later: Add Load Balancer

You mentioned wanting to add a load balancer. Here are options:

1. **MetalLB** (for bare metal):
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

2. **Configure IP pool** (after MetalLB):
```yaml
# Create: metallb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.0.200-192.168.0.250
```

Apply it:
```bash
kubectl apply -f metallb-config.yaml
```

## 🐛 Troubleshooting

### "terraform: command not found"

**In PowerShell:**
```powershell
# Install Terraform
choco install terraform

# Verify
terraform version
```

### "SSH connection failed"

Make sure password authentication is enabled on all Ubuntu servers:

```bash
# On each node, edit SSH config
sudo nano /etc/ssh/sshd_config

# Make sure this line is set:
PasswordAuthentication yes

# Restart SSH
sudo systemctl restart sshd
```

### "kubectl: command not found"

```powershell
choco install kubernetes-cli
```

### Nodes Not Joining

SSH to worker and check logs:
```bash
ssh ahmed1@192.168.0.235
sudo journalctl -u k3s-agent -f
```

## 📞 Need Help?

- Check: README.md - Full documentation
- Check: QUICK_START.md - Quick guide
- Check: WINDOWS_SSH_SETUP.md - SSH issues

---

**Ready? Run these commands in PowerShell:**

```powershell
# 1. Set password
notepad terraform.tfvars

# 2. Test SSH
.\setup-ssh.ps1

# 3. Deploy!
terraform init
terraform apply
```

**That's it!** Your K3s cluster will be ready in 5 minutes! 🎉



