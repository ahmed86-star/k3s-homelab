terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
  required_version = ">= 1.0"
}

# Install K3s on Master Node
resource "null_resource" "k3s_master" {
  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "Installing K3s on master node (${var.master_ip})..."
      
      $installScript = @'
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} sh -s - server --disable traefik --disable servicelb --write-kubeconfig-mode 644
sudo systemctl enable k3s
sudo systemctl start k3s
sleep 10
echo "K3s master installation complete"
'@
      
      # Execute on remote master node
      $password = "${var.ssh_password}"
      $command = "echo '$installScript' | ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${var.master_ip} 'bash -s'"
      Invoke-Expression $command
      
      Write-Host "Master node setup complete!"
    EOT
    interpreter = ["powershell", "-Command"]
  }
}

# Get K3s token from master
resource "null_resource" "get_k3s_token" {
  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "Retrieving K3s token from master..."
      ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${var.master_ip} "sudo cat /var/lib/rancher/k3s/server/node-token" | Out-File -FilePath "k3s-token.txt" -Encoding UTF8 -NoNewline
      Write-Host "Token saved to k3s-token.txt"
    EOT
    interpreter = ["powershell", "-Command"]
  }

  depends_on = [null_resource.k3s_master]
}

# Get kubeconfig from master
resource "null_resource" "get_kubeconfig" {
  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "Downloading kubeconfig from master..."
      ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${var.master_ip} "sudo cat /etc/rancher/k3s/k3s.yaml" | Out-File -FilePath "kubeconfig.yaml" -Encoding UTF8
      
      # Replace 127.0.0.1 with master IP
      (Get-Content kubeconfig.yaml -Raw) -replace '127.0.0.1', '${var.master_ip}' | Set-Content kubeconfig.yaml -NoNewline
      Write-Host "Kubeconfig saved to kubeconfig.yaml"
    EOT
    interpreter = ["powershell", "-Command"]
  }

  depends_on = [null_resource.k3s_master]
}

# Install K3s on Worker Node 1
resource "null_resource" "k3s_worker_1" {
  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "Installing K3s on worker node 1 (${var.worker_ips[0]})..."
      Start-Sleep -Seconds 5
      
      # Get the token
      $token = Get-Content k3s-token.txt -Raw
      $token = $token.Trim()
      
      $installScript = @"
export K3S_TOKEN='$token'
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} K3S_URL=https://${var.master_ip}:6443 sh -
sudo systemctl enable k3s-agent
sudo systemctl start k3s-agent
echo 'K3s agent installation complete'
"@
      
      # Execute on remote worker node
      $command = "echo `"$installScript`" | ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${var.worker_ips[0]} 'bash -s'"
      Invoke-Expression $command
      
      Write-Host "Worker node 1 joined the cluster!"
    EOT
    interpreter = ["powershell", "-Command"]
  }

  depends_on = [
    null_resource.k3s_master,
    null_resource.get_k3s_token
  ]
}

# Install K3s on Worker Node 2
resource "null_resource" "k3s_worker_2" {
  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "Installing K3s on worker node 2 (${var.worker_ips[1]})..."
      Start-Sleep -Seconds 5
      
      # Get the token
      $token = Get-Content k3s-token.txt -Raw
      $token = $token.Trim()
      
      $installScript = @"
export K3S_TOKEN='$token'
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} K3S_URL=https://${var.master_ip}:6443 sh -
sudo systemctl enable k3s-agent
sudo systemctl start k3s-agent
echo 'K3s agent installation complete'
"@
      
      # Execute on remote worker node
      $command = "echo `"$installScript`" | ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${var.worker_ips[1]} 'bash -s'"
      Invoke-Expression $command
      
      Write-Host "Worker node 2 joined the cluster!"
    EOT
    interpreter = ["powershell", "-Command"]
  }

  depends_on = [
    null_resource.k3s_master,
    null_resource.get_k3s_token
  ]
}

# Verify cluster
resource "null_resource" "verify_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "`nWaiting for cluster to be ready..."
      Start-Sleep -Seconds 15
      
      $env:KUBECONFIG = "$(Get-Location)\kubeconfig.yaml"
      
      Write-Host "`n========================================="
      Write-Host "   K3s Cluster Deployment Complete!    "
      Write-Host "=========================================`n"
      
      Write-Host "Cluster Nodes:"
      kubectl get nodes -o wide
      
      Write-Host "`n`nTo use kubectl, run:"
      Write-Host '  $env:KUBECONFIG="' -NoNewline
      Write-Host "$(Get-Location)\kubeconfig.yaml" -NoNewline -ForegroundColor Yellow
      Write-Host '"'
      Write-Host "  kubectl get nodes"
      Write-Host "`nOr permanently set it:"
      Write-Host '  [System.Environment]::SetEnvironmentVariable("KUBECONFIG", "' -NoNewline
      Write-Host "$(Get-Location)\kubeconfig.yaml" -NoNewline -ForegroundColor Yellow
      Write-Host '", "User")'
    EOT
    interpreter = ["powershell", "-Command"]
  }

  depends_on = [
    null_resource.get_kubeconfig,
    null_resource.k3s_worker_1,
    null_resource.k3s_worker_2
  ]
}
