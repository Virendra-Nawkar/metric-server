# Metrics Server — kubeadm Install

One-shot script to install **Metrics Server** on a self-managed kubeadm cluster (on-prem / Azure VMs) via Helm.

Enables:
- `kubectl top nodes` — live CPU and memory of nodes
- `kubectl top pods` — live CPU and memory of pods
- HPA (Horizontal Pod Autoscaler) — autoscaling based on CPU/memory

---

## Cluster Setup

| Node   | Role   |
|--------|--------|
| Master | Control Plane |
| Node1  | Worker |
| Node2  | Worker |

- Kubernetes: v1.32
- CNI: Calico
- Runtime: containerd

---

## Why special flags are needed on kubeadm

| Flag | Problem it solves |
|---|---|
| `--kubelet-insecure-tls` | kubeadm kubelets use self-signed certs — Metrics Server can't verify them without this |
| `hostNetwork.enabled=true` | API Server can't reach pod overlay IPs (Calico) on Azure VMs — hostNetwork uses real node IP instead |
| `--secure-port=10251` | kubelet already owns port 10250 on every node — Metrics Server moves to 10251 to avoid crash |

---

## How to use

### Fresh install
```bash
# Clone the repo
git clone https://github.com/Virendra-Nawkar/metric-server
cd metrics-server

# Give permission and run
chmod +x install.sh
./install.sh
```

### If Metrics Server already installed via raw YAML

No worries — the script **automatically cleans up** old resources before installing.

### Verify it works
```bash
kubectl top nodes
kubectl top pods -n <your-namespace>
```

---

## Useful commands after install
```bash
# CPU and memory of all nodes
kubectl top nodes

# CPU and memory of pods in a namespace
kubectl top pods -n vir

# Sort by CPU usage
kubectl top pods -n kube-system --sort-by=cpu

# Sort by memory usage
kubectl top pods -n kube-system --sort-by=memory

# Check Helm release
helm list -n kube-system

# Check Metrics Server logs
kubectl logs -n kube-system deploy/metrics-server
```

---

## Uninstall
```bash
helm uninstall metrics-server -n kube-system
```

---

## Errors we hit and fixed

| Error | Cause | Fix |
|---|---|---|
| `invalid ownership metadata` | Old raw-YAML install blocked Helm | Delete all old resources first |
| `FailedDiscoveryCheck / context deadline exceeded` | API Server couldn't reach pod IP | Added `hostNetwork.enabled=true` |
| `address already in use` on port 10250 | kubelet owns port 10250 | Added `--secure-port=10251` |
