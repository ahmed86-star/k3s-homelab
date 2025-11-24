# Quick Start Guide - K3s Homelab

Get your K3s cluster running in 5 minutes!

## Prerequisites Checklist

- [ ] 3 Ubuntu VMs running and accessible
- [ ] Terraform installed (`choco install terraform`)
- [ ] kubectl installed (`choco install kubernetes-cli`)
- [ ] SSH access to all nodes working
- [ ] You know your SSH password

## 5-Minute Deployment

### Step 1: Verify SSH (30 seconds)

```powershell
.\setup-ssh.ps1
```

✅ All nodes should show as reachable

### Step 2: Configure Password (10 seconds)

Edit `terraform.tfvars`:

```hcl
ssh_password = "YOUR_ACTUAL_PASSWORD"
```

### Step 3: Deploy Cluster (3-4 minutes)

```powershell
# Initialize Terraform
terraform init

# Deploy!
terraform apply
```

Type `yes` when prompted.

### Step 4: Use Your Cluster (10 seconds)

```powershell
# Set kubeconfig
$env:KUBECONFIG="$PWD\kubeconfig.yaml"

# Check your nodes
kubectl get nodes

# See all running pods
kubectl get pods -A
```

## What Just Happened?

1. ✅ K3s installed on master (192.168.0.84)
2. ✅ K3s agents installed on 2 workers
3. ✅ All nodes joined the cluster
4. ✅ Kubeconfig downloaded to your machine
5. ✅ You're ready to deploy apps!

## First Deployment

Deploy nginx in 10 seconds:

```powershell
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc nginx
```

Visit: `http://192.168.0.84:<PORT>` (use the NodePort from the output)

## Useful Commands

```powershell
# See all nodes
kubectl get nodes -o wide

# See all pods across all namespaces
kubectl get pods -A

# Check cluster info
kubectl cluster-info

# Describe a node
kubectl describe node k3s-master
```

## Need to Start Over?

```powershell
# Destroy everything
terraform destroy

# Then run apply again
terraform apply
```

## Troubleshooting

**"kubectl: command not found"**
```powershell
choco install kubernetes-cli
```

**"Unable to connect to the server"**
```powershell
# Make sure kubeconfig is set
$env:KUBECONFIG="$PWD\kubeconfig.yaml"
```

**"Nodes not ready"**
```powershell
# Give it a minute, then check
Start-Sleep -Seconds 30
kubectl get nodes
```

**SSH issues?**
- See [WINDOWS_SSH_SETUP.md](WINDOWS_SSH_SETUP.md)

## Next Steps

- Deploy more applications
- Set up persistent storage
- Install ingress controller (Traefik, Nginx)
- Set up monitoring (Prometheus, Grafana)
- Configure MetalLB for load balancing

## Learn More

- [Main README](README.md) - Full documentation
- [K3s Docs](https://docs.k3s.io/) - Official K3s documentation
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

🎉 **Congratulations!** You now have a working Kubernetes cluster!



