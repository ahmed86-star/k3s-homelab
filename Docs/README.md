# K3s Homelab - Rancher Installation Next Steps

This document outlines the final steps to complete the Rancher installation using the successfully bound NFS Persistent Volume Claim (rancher-data-pvc).

## Status: Storage Bound

The storage is ready! The PVC is Bound to the PV:
- PVC: rancher-data-pvc
- STATUS: Bound
- STORAGECLASS: nfs-static-rancher

## Next Actions (Must be run on the K3s Master Node)

1.  **Force Uninstall the Stuck Helm Release:**
    This clears the previous failed installation metadata.
    ```bash
    helm uninstall rancher -n cattle-system
    ```

2.  **Run Final Rancher Installation:**
    This installs the Rancher server.
    ```bash
    helm install rancher rancher-stable/rancher \
      --namespace cattle-system \
      -f rancher-helm-values.yaml \
      --set bootstrapPassword= \
      --version 2.8.3
    ```

3.  **Verify Pod Status (Wait 5-10 minutes):**
    Check that the Rancher pods are running.
    ```bash
    kubectl get pods -n cattle-system
    ```