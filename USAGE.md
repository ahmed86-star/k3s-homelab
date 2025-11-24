# K3s Homelab - Usage Guide

Quick reference for deploying and managing your K3s cluster.

## 🚀 Quick Deployment

### Step 1: Configure

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
# or
vim terraform.tfvars
```

Update these values:
- `ssh_user` - Your SSH username
- `ssh_password` - Your SSH password (or use SSH keys)
- `master_ip` - Master node IP
- `worker_ips` - List of worker IPs

### Step 2: Deploy

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy the cluster
terraform apply
```

Type `yes` when prompted.

### Step 3: Use Your Cluster

```bash
# Set kubeconfig
export KUBECONFIG="$PWD/kubeconfig.yaml"

# Verify nodes
kubectl get nodes

# See all pods
kubectl get pods -A
```

## 📋 Common Commands

### Cluster Management

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes -o wide

# View system pods
kubectl get pods -n kube-system

# Describe a node
kubectl describe node <node-name>
```

### Deploy Applications

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx

# Expose as a service
kubectl expose deployment nginx --port=80 --type=NodePort

# Get service details
kubectl get svc nginx

# Scale deployment
kubectl scale deployment nginx --replicas=3
```

### Troubleshooting

```bash
# Check pod logs
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>

# Get into a pod
kubectl exec -it <pod-name> -- /bin/bash

# Check node status
kubectl get nodes
kubectl describe node <node-name>
```

## 🔄 Cluster Operations

### Update Cluster

```bash
# Modify terraform.tfvars as needed
terraform plan
terraform apply
```

### Destroy Cluster

```bash
# Remove K3s from all nodes
terraform destroy
```

### SSH to Nodes

```bash
# SSH to master
ssh your-username@192.168.1.10

# Check K3s status
sudo systemctl status k3s

# View K3s logs
sudo journalctl -u k3s -f
```

## 📊 Monitoring

### Check K3s Services

```bash
# On master node
ssh your-username@192.168.1.10
sudo systemctl status k3s

# On worker nodes
ssh your-username@192.168.1.11
sudo systemctl status k3s-agent
```

### View K3s Logs

```bash
# On master
sudo journalctl -u k3s -f

# On workers
sudo journalctl -u k3s-agent -f
```

## 🔧 Advanced Usage

### Using SSH Keys Instead of Password

1. Generate SSH key pair:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/k3s-cluster
```

2. Copy to all nodes:
```bash
ssh-copy-id -i ~/.ssh/k3s-cluster.pub your-username@192.168.1.10
ssh-copy-id -i ~/.ssh/k3s-cluster.pub your-username@192.168.1.11
ssh-copy-id -i ~/.ssh/k3s-cluster.pub your-username@192.168.1.12
```

3. Update `variables.tf` to use SSH keys instead of passwords

### Environment Variables

Set sensitive variables via environment instead of `terraform.tfvars`:

```bash
export TF_VAR_ssh_password="your-password"
export TF_VAR_master_ip="192.168.1.10"
terraform apply
```

### Custom K3s Version

Edit `terraform.tfvars`:
```hcl
k3s_version = "v1.28.5+k3s1"
```

## 🛠️ Maintenance

### Update K3s

To update K3s to a newer version:

1. Update `k3s_version` in `terraform.tfvars`
2. Run `terraform apply`

### Backup kubeconfig

```bash
# Backup your cluster credentials
cp kubeconfig.yaml kubeconfig.yaml.backup
```

### Reset a Node

If a node has issues:

```bash
# SSH to the node
ssh your-username@192.168.1.11

# Uninstall K3s
sudo /usr/local/bin/k3s-agent-uninstall.sh

# Redeploy with Terraform
terraform apply
```

## 📚 Next Steps

After your cluster is running:

1. **Install MetalLB** for load balancing
2. **Set up Ingress** controller (Nginx, Traefik)
3. **Add monitoring** (Prometheus, Grafana)
4. **Configure storage** (Longhorn, NFS)
5. **Deploy applications**

See the main [README.md](README.md) for more details!

---

**Questions?** Check [TROUBLESHOOTING.md](README.md#-troubleshooting) in the main README.

