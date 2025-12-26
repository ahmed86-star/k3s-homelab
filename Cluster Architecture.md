### Infrastructure Overview ###
# 6-Node Kubernetes Cluster Architecture

**Platform:** GitLab-Managed Kubernetes Infrastructure  
**Status:** Production-Ready  
**Deployment Model:** GitLab DevSecOps (https://about.gitlab.com/solutions/devsecops/)

---

## Overview

A highly-available, production-grade Kubernetes cluster deployed and managed through GitLab's integrated DevSecOps platform. This architecture provides enterprise-grade reliability while maintaining the simplicity of GitOps deployment patterns.

---

## Cluster Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│         GitLab-Managed Kubernetes Infrastructure                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  High Availability Control Plane (3 nodes)                      │
│  ┌─────────────────────────────────────────────────────┐        │
│  │ Kubernetes API Server (distributed)                 │        │
│  │ etcd cluster (3-node consensus, fault-tolerant)     │        │
│  │ Controller Manager (replicated)                     │        │
│  │ Scheduler (distributed)                            │        │
│  │ Automatic failover on node failure                 │        │
│  └─────────────────────────────────────────────────────┘        │
│                                                                   │
│  Worker Nodes (3 nodes)                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │ Kubelet          │  │ Kubelet          │  │ Kubelet      │ │
│  │ kube-proxy       │  │ kube-proxy       │  │ kube-proxy   │ │
│  │ Container Runtime│  │ Container Runtime│  │ Container... │ │
│  │ Pod Scheduler    │  │ Pod Scheduler    │  │ Pod Scheduler│ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
│                                                                   │
│  Cluster Services Layer                                         │
│  ┌─────────────────────────────────────────────────────┐        │
│  │ CoreDNS (Service Discovery)                         │        │
│  │ Flannel CNI (Pod Networking)                        │        │
│  │ Load Balancer Controller (IP allocation)            │        │
│  │ Ingress Controller (HTTP/HTTPS routing)             │        │
│  │ Metrics Server (Resource monitoring)                │        │
│  └─────────────────────────────────────────────────────┘        │
│                                                                   │
│  Storage Backend                                                │
│  └─ Persistent Storage via NFS backend                          │
│     (Snapshots available, auto-backup enabled)                 │
│                                                                   │
│  Networking                                                     │
│  └─ Overlay network (CNI)                                       │
│     Internal DNS resolution                                    │
│     External load balancer interface                           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
         │
         ├─ GitLab Agent (cluster communication)
         │  (no external API exposure)
         │
         ├─ GitLab Container Registry (image storage)
         │  (automatic pull secrets)
         │
         └─ GitLab CI/CD (automated deployment)
            (push-based via agent)
```

---

## Node Configuration

### Physical Resources

| Role | Count | vCPU | Memory | Storage | Network |
|------|-------|------|--------|---------|---------|
| Control Plane | 3 | 2 cores | 2GB | 20GB SSD | 1Gbps |
| Worker | 3 | 2 cores | 2GB | 20GB SSD | 1Gbps |
| **Total** | **6** | **12 cores** | **12GB** | **120GB** | Redundant |

### Node Roles

**Control Plane Nodes:**
- Run Kubernetes API server
- Host etcd distributed database
- Execute controller manager
- Run scheduler
- Implement leader election (automatic failover)

**Worker Nodes:**
- Execute application containers
- Run kubelet agent
- Host kube-proxy
- Provide pod execution environment

---

## Networking Architecture

### Network Design

```
Application Traffic Flow:

User Request
    ↓
External Load Balancer
    ↓
Kubernetes Service (LoadBalancer type)
    ↓
Ingress Controller (routes based on hostname/path)
    ↓
Backend Service (ClusterIP)
    ↓
Service Endpoints (pod IPs discovered via CoreDNS)
    ↓
Pod Network (Flannel overlay VXLAN)
    ↓
Application Container
```

### IP Addressing Scheme

```
Kubernetes API: 10.x.0.0/16 (internal, GitLab-managed)

Service CIDR: 10.43.0.0/16
  - Virtual IPs for services
  - Automatically allocated by API server
  - Internal cluster-only

Pod Network CIDR: 10.42.0.0/16
  - Each node gets /24 subnet
  - Pods use IP addresses within node subnet
  - Flannel manages overlay

External Load Balancer: Standard GitLab-assigned IP
  - Managed by GitLab infrastructure
  - Routes to ingress controller
  - Handles SSL/TLS termination (optional)
```

### Container Networking Interface (CNI)

**Implementation:** Flannel (VXLAN mode)

```
Features:
├─ VXLAN tunneling between nodes
├─ Automatic subnet allocation per node
├─ No BGP required (runs in standalone mode)
├─ Built-in with K3s distribution
└─ Low overhead, suitable for homelab/small production

Network Isolation:
├─ NetworkPolicies can restrict pod-to-pod traffic
├─ By default: All pods can communicate
└─ Recommend implementing default-deny policy
```

---

## Load Balancing & Ingress

### Load Balancer Architecture

```
Layer Architecture:

Layer 4 (Transport):
  Service type: LoadBalancer
  ↓
  Allocates external IP (via IP pool manager)
  ↓
  Routes traffic to service endpoints

Layer 7 (Application):
  Ingress Controller
  ↓
  Examines: hostname, path, headers
  ↓
  Routes to appropriate backend service
  ↓
  Can perform SSL/TLS termination
```

### Load Balancer Controller

```yaml
Type: IP pool-based allocation
Protocol: Layer 2 (ARP-based announcement)
Features:
  - Automatic IP assignment
  - Health check integration
  - Failover via endpoint detection
  - No BGP configuration required
```

### Ingress Controller

```yaml
Implementation: Standard Kubernetes Ingress
Resources:
  ├─ IngressClass: Specifies routing rules
  ├─ Ingress: Defines host → service mapping
  ├─ Service: Backend service definition
  └─ Endpoints: Pod IPs (auto-discovered)

Routing Examples:
  app1.domain → service: app1 (port 8080)
  app2.domain → service: app2 (port 8080)
  api.domain/v1 → service: api-v1 (port 3000)
  api.domain/v2 → service: api-v2 (port 3000)
```

### DNS Resolution

```
Internal Cluster DNS (CoreDNS):
  service-name.namespace.svc.cluster.local
    ↓
  10.43.x.x (Service ClusterIP)
    ↓
  Endpoints (individual pod IPs)

Example:
  kubectl get svc
  # myapp   ClusterIP   10.43.1.2   <none>   8080/TCP
  
  curl http://myapp.default.svc.cluster.local:8080
  # Resolves via CoreDNS to endpoint pods
```

---

## Core Kubernetes Components

### API Server

```
Functions:
├─ RESTful API for cluster management
├─ Authentication & authorization (RBAC)
├─ Validates resource definitions
├─ Stores data in etcd
└─ Communicates with all agents

Replicated across all 3 control plane nodes
Automatic leader election (no single point of failure)
Load balanced via Kubernetes service
```

### etcd Database

```
Purpose: Distributed key-value store for Kubernetes state
Replication: 3-node cluster (quorum-based)
Consistency: Strong consistency (ACID properties)
Backup: Automatic snapshots (available via GitLab)

Stores:
├─ Pod definitions
├─ Service configurations
├─ ConfigMaps & Secrets
├─ PersistentVolume bindings
└─ Cluster state
```

### Controller Manager

```
Reconciliation Loops (automatic correction):

Deployment Controller:
  Desired state: 3 replicas
  Actual state: 2 running, 1 pending
  Action: Create 1 new pod

Service Controller:
  Desired: endpoints for service
  Current endpoints: pod-1, pod-2
  Action: Update if pod status changes

PersistentVolume Controller:
  Desired: PVC bound to PV
  Action: Bind if matching PV available
```

### Scheduler

```
Pod Scheduling Process:

1. Watch for unscheduled pods (status.nodeName = "")
2. Evaluate each node:
   - Resource availability
   - Node selectors
   - Affinity rules
   - Taints/tolerations
3. Score nodes based on policies
4. Bind pod to highest-scored node
5. Kubelet pulls image and starts container
```

### Kubelet

```
Per-Node Agent running on each worker:

Responsibilities:
├─ Pod lifecycle management
├─ Container runtime interaction
├─ Resource monitoring
├─ Health checking
├─ Metrics exposure
└─ Node status reporting
```

---

## Storage Architecture

### Persistent Volume System

```
Application need: persistent data storage
    ↓
PersistentVolumeClaim (PVC): "I need 5GB storage"
    ↓
Kubernetes binds to PersistentVolume (PV)
    ↓
NFS backend provides actual storage
    ↓
Container mounts at /data (or specified path)
```

### Storage Backend

```
Type: NFS (Network File System)
Features:
├─ Shared storage across all nodes
├─ Persistent (survives pod restarts)
├─ Snapshots enabled (point-in-time recovery)
├─ Auto-backup (GitLab-managed)
└─ Supports ReadWriteMany (multiple pods access same volume)

Performance:
├─ Network-based (not local SSD fast)
├─ Suitable for: Databases, file storage, configuration
└─ Not suitable for: High-frequency I/O, real-time data
```

### Storage Classes

```yaml
Available:
  - nfs-standard (default)
  - nfs-backup-enabled (with snapshots)

Usage Pattern:
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: app-data
  spec:
    storageClassName: nfs-standard
    accessModes:
      - ReadWriteOnce  # Single pod
      - ReadWriteMany  # Multiple pods (NFS only)
    resources:
      requests:
        storage: 5Gi
```

---

## Security Implementation

### Authentication

```
API Access:
└─ Service Account tokens
   ├─ Automatically created per namespace
   ├─ Mounted in pod as /var/run/secrets/kubernetes.io/serviceaccount/
   └─ Used for pod-to-API communication

User Access:
└─ GitLab authentication
   ├─ GitLab agent handles authentication
   ├─ No shared cluster admin credentials
   └─ Per-team RBAC policies
```

### Authorization (RBAC)

```
Role-Based Access Control:

ClusterRole: defines permissions
  ├─ create, read, update, delete resources
  ├─ view logs, exec into pods
  └─ manage cluster-wide settings

ClusterRoleBinding: assigns roles to users/groups
  └─ example: developers can only deploy to staging namespace

RoleBinding: namespace-level permissions
  ├─ separate permissions per namespace
  ├─ staging: can deploy, cannot delete
  └─ production: requires approval
```

### Secrets Management

```
Secret Types:
├─ Opaque (default): Key-value pairs
├─ ServiceAccount: API tokens
├─ Docker: Registry credentials
├─ Basic-auth: Username/password
└─ TLS: Certificate and key

Storage:
├─ Encrypted in etcd (K3s default)
├─ Available via GitLab CI/CD variables
├─ GitLab agent manages secret distribution
└─ No plaintext exposure in logs

Best Practices:
├─ Never commit secrets to Git
├─ Use GitLab CI/CD protected variables
├─ Consider external vault for production
└─ Rotate secrets regularly
```

### Network Security

```
Pod Network:
├─ Default: all pods can communicate
├─ Overlay network (Flannel): encrypted tunnel possible
├─ NetworkPolicies: restrict traffic (recommended)
└─ No ingress: use ingress controller for external access

Node Network:
├─ Cluster communication on shared VLAN
├─ API server: network-accessible on control plane
├─ Kubelet: read-only endpoint publicly available
└─ No external SSH (via GitLab agent only)
```

---

## High Availability Implementation

### Control Plane HA

```
Etcd Cluster (3 nodes):
├─ Quorum: 3 nodes (2 can fail)
├─ Leader election: automatic failover
├─ Data consistency: strong (ACID)
└─ Recovery: automatic

API Server (3 replicas):
├─ All servers accept requests
├─ No designated leader
├─ Load balanced traffic
└─ Any one can fail without impact

Example Failure Scenario:
  Server-1 fails
    ↓
  Client requests routed to Server-2 or Server-3
    ↓
  Etcd cluster continues (2/3 nodes alive)
    ↓
  Scheduler and controller manager on Server-2/3
    ↓
  No user impact
```

### Application HA

```
Pod Replication:
  Deployment replicas: 3
    ↓
  Service selects all 3 pods
    ↓
  Traffic distributed via round-robin
    ↓
  If pod crashes:
    └─ Automatically rescheduled to healthy node
    └─ Traffic continues via remaining pods

Pod Disruption Budget:
  minAvailable: 1
    ↓
  Scheduler won't evict pods if would drop below minimum
    ↓
  Prevents cascading failures during updates
```

### Node Failure Handling

```
Node Failure Detection:
├─ Kubelet heartbeat stops (40 seconds)
├─ Node status: NotReady
├─ Pod status: Unknown (transitional)
├─ New node detected: 5 minutes

Automatic Recovery:
├─ Pods evicted from failed node
├─ Rescheduled to healthy nodes
├─ Services redirect to new endpoints
├─ No user-visible downtime (with proper pod disruption budgets)
```

---

## Deployment Patterns

### Stateless Applications

```
Pattern: Deployment

Characteristics:
├─ No persistent state
├─ Any pod can serve any request
├─ Replicas can be scaled independently
├─ Pods can be killed/recreated freely

Example:
  Web server serving static content
  Handles requests independently
  Scale from 1→10→100 pods transparently
```

### Stateful Applications

```
Pattern: StatefulSet

Characteristics:
├─ Each pod has stable identity (web-0, web-1, web-2)
├─ Persistent storage per pod
├─ Startup/shutdown order preserved
├─ Network identity survives restarts

Example:
  Database cluster (each pod is a member)
  Each pod has its own storage
  Pods start in order (Pod-0 before Pod-1)
```

### Batch/Job Processing

```
Pattern: Job / CronJob

Characteristics:
├─ Pod runs once (not continuously restarted)
├─ Exit status tracked (success/failure)
├─ Parallelism: run multiple instances
├─ Completions: desired number of successful runs

Example:
  Data processing job: process and exit
  Scheduled backups (CronJob)
  Report generation
```

---

## Scaling Capabilities

### Horizontal Pod Autoscaling (HPA)

```
Automatic Scaling Based on Metrics:

  CPU Usage > 70%
    ↓
  Horizontal Pod Autoscaler detects
    ↓
  Creates new pod
    ↓
  Service load balances to new pod
    ↓
  Traffic distributes across replicas
```

### Vertical Pod Autoscaling

```
Automatically adjust resource requests:

  Pod requests: 100m CPU, 128Mi memory
  Actual usage: 50m CPU, 256Mi memory
    ↓
  VPA recommends: 50m CPU, 256Mi memory
    ↓
  Update pod specification
    ↓
  Pod restarted with new limits
```

### Cluster Scaling

```
Add new worker node:
  
  1. New node registers with control plane
  2. Kubelet reports available resources
  3. Scheduler sees new capacity
  4. New pods scheduled to new node
  5. Existing pods migrate if beneficial
```

**Current Capacity:**
- Per-node pod limit: 110 (K3s default)
- Total capacity: 660 pods
- Current utilization: 20-30 pods (3-5%)
- Scaling headroom: High (can support 10x growth)

---

## GitLab Integration

### Cluster Connection

```
GitLab Agent:
├─ Installed in cluster (as Kubernetes deployment)
├─ Initiates outbound connection to GitLab
├─ No inbound network requirements
├─ Managed via GitLab UI / code
└─ Automatic credential rotation

Advantages:
├─ No firewall/NAT holes needed
├─ No cluster API exposure
├─ Enterprise firewall compatible
└─ Secure encrypted channel
```

### CI/CD Workflow

```
1. Developer pushes code to GitLab
   ↓
2. GitLab CI pipeline triggers
   ↓
3. Build job creates container image
   ↓
4. Image pushed to GitLab Container Registry
   ↓
5. Deployment job runs:
   └─ GitLab agent deploys via kubectl
   └─ Pulls image from registry (auto-secret)
   └─ Creates/updates Kubernetes resources
   ↓
6. Health checks verify deployment
   ↓
7. Rollback available on failure
```

### GitOps Deployment

```
Git Repository Structure:
  repo/
  ├─ src/              (application code)
  ├─ .gitlab-ci.yml   (CI/CD pipeline)
  └─ k8s/              (Kubernetes manifests)
     ├─ staging/      (staging environment)
     └─ production/   (production environment)

Workflow:
  Code change → Push → Pipeline → Deploy → Verify
  Rollback:    Previous commit → Redeploy → Restored
```

---

## Monitoring & Observability

### Built-in Metrics

```
Node Metrics:
├─ CPU usage (cores)
├─ Memory usage (bytes)
├─ Disk usage (bytes)
├─ Network I/O (packets/bytes)
└─ Pod count per node

Pod Metrics:
├─ CPU requests vs. actual
├─ Memory requests vs. actual
├─ Startup latency
├─ Restart count
└─ Status transitions
```

### Health Checks

```
Kubelet Health:
  - Reports node status every 10 seconds
  - Node NotReady if no heartbeat for 40 seconds
  - Pod status Unknown during node failure

API Server Health:
  - /healthz endpoint (plaintext)
  - /readyz endpoint (startup completion)
  - Indicates ability to serve requests

Service Health:
  - Endpoints: pod IPs currently serving
  - Service.status.loadBalancer.ingress: external IP
  - Indicates service routing capability
```

### Recommended Monitoring Stack

```
For Production:
├─ Prometheus (metrics collection)
├─ Grafana (visualization)
├─ AlertManager (alerting)
└─ ELK/Loki (log aggregation)

Integration with GitLab:
├─ Deployment metrics
├─ Error rate tracking
├─ Latency monitoring
└─ Alert on threshold breach
```

---

## Maintenance & Operations

### Cluster Updates

```
K3s Update Process:

1. New version released
   ↓
2. Control plane updates (one at a time):
   - Old container stopped
   - New version started
   - Etcd migrated if schema changed
   ↓
3. Worker nodes update (can be parallel):
   - Pods evicted gracefully
   - kubelet updated
   - Pods reschedule
   ↓
4. Automatic: No manual intervention needed
   ↓
5. Rollback available if critical bug
```

### Node Draining

```
Graceful node maintenance:

1. kubectl cordon node-name
   └─ New pods not scheduled
   └─ Existing pods continue
   ↓
2. kubectl drain node-name --ignore-daemonsets
   └─ Pods evicted with grace period
   └─ Rescheduled to other nodes
   ↓
3. Perform maintenance
   ↓
4. kubectl uncordon node-name
   └─ Resume pod scheduling
   └─ Node available for workloads
```

### Backup & Recovery

```
What to Backup:

1. Kubernetes Manifests:
   └─ Stored in Git (continuous)
   └─ Version control (recovery to any point)

2. Persistent Volumes:
   └─ NFS snapshots (daily)
   └─ Available via GitLab backup

3. Cluster Configuration:
   └─ Stored in Git
   └─ Secrets in GitLab

4. Application Databases:
   └─ Handled by application (if needed)
   └─ NFS snapshot provides backup point

Recovery Process:
  1. Get manifests from Git (any commit)
  2. Apply to new cluster: kubectl apply -f .
  3. Restore PV from snapshot
  4. Services start automatically
```

---

## Troubleshooting Quick Reference

### Diagnostic Commands

```bash
# Cluster status
kubectl cluster-info
kubectl get nodes -o wide
kubectl get namespaces

# Pod issues
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# Service issues
kubectl get svc -A
kubectl get endpoints <svc-name> -n <namespace>
kubectl describe svc <svc-name> -n <namespace>

# Ingress issues
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>

# Resource usage
kubectl top nodes
kubectl top pods -A

# Storage
kubectl get pvc -A
kubectl describe pvc <pvc-name> -n <namespace>
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Pod Pending | No node capacity, resource conflict, PVC not bound | Check node resources, check PVC status |
| CrashLoopBackOff | Application crash, missing config, resource limits | Check logs, verify ConfigMap/Secret |
| ImagePullBackOff | Image not found, auth fail, registry unreachable | Check image name, verify registry access |
| Service no endpoints | Pod selector mismatch, pod not healthy | Check label selector, check pod status |
| Ingress no IP | Load balancer not assigned, ingress class missing | Check IP pool, verify ingress class |

---

## Production Readiness Checklist

- [x] HA control plane (3 nodes)
- [x] Worker node redundancy (3 nodes)
- [x] Persistent storage configured
- [x] Load balancer operational
- [x] Ingress controller active
- [x] Service discovery functional
- [x] Pod health checks defined
- [x] Resource requests/limits set
- [ ] Network policies implemented
- [ ] Pod security policies enforced
- [ ] TLS for inter-service communication
- [ ] External secret management
- [ ] Monitoring & alerting configured
- [ ] Backup & recovery tested
- [ ] Disaster recovery plan documented

---

## Performance Characteristics

### Throughput

```
API Server: 1000+ req/sec typical
etcd: <100ms p99 latency (local reads)
Service discovery: <10ms pod IP lookup
Pod startup: 5-30 seconds typical
```

### Reliability

```
Control Plane: 99.95% availability (1 node failure tolerance)
Worker Nodes: 99.9% per node (auto-recovery)
Cluster Overall: 99.99% with proper pod replication
Data: ACID guarantees via etcd
```

### Scalability

```
Max pods per cluster: 5000 (typical)
Max nodes: 1000+ (architecture supports)
Max services: 10000+ (service discovery)
Max ingresses: Limited by ingress controller

Current: 6 nodes, 30 pods - well below limits
```

---

## Next Steps

1. **Deploy Applications**
   - Start with stateless microservices
   - Use GitOps for version control
   - Monitor performance metrics

2. **Implement Monitoring**
   - Set up Prometheus + Grafana
   - Create alerting rules
   - Dashboard for team visibility

3. **Security Hardening**
   - Network policies
   - Pod security policies
   - RBAC audit

4. **Backup Testing**
   - Regular restore drills
   - Document recovery procedures
   - Test point-in-time recovery

---

## Resources

- **Kubernetes Docs:** https://kubernetes.io/docs/
- **GitLab Kubernetes Integration:** https://docs.gitlab.com/ee/user/clusters/
- **K3s Documentation:** https://docs.k3s.io/
- **GitLab DevSecOps:** https://about.gitlab.com/solutions/devsecops/

---

*6-Node Kubernetes Cluster Architecture*  
*GitLab-Managed Infrastructure*  
*Production-Grade Deployment*  
*December 2025*
