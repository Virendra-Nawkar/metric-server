#!/bin/bash
# ============================================================
#   Metrics Server - One Shot Install Script
#   For: kubeadm on-prem cluster (Azure VMs)
#   Fixes included:
#     1. Cleans up any old raw-YAML metrics-server install
#     2. Installs Helm if not present
#     3. Installs Metrics Server via Helm with all kubeadm fixes
#        - --kubelet-insecure-tls  (self-signed certs on kubeadm)
#        - hostNetwork.enabled     (API Server can reach pod)
#        - secure-port=10251       (avoid port conflict with kubelet on 10250)
# ============================================================

set -e

echo ""
echo "============================================================"
echo "   Metrics Server Install Script for kubeadm"
echo "============================================================"
echo ""

echo "[1/4] Cleaning up any old raw-YAML metrics-server resources..."

kubectl delete deployment metrics-server -n kube-system 2>/dev/null || true
kubectl delete serviceaccount metrics-server -n kube-system 2>/dev/null || true
kubectl delete service metrics-server -n kube-system 2>/dev/null || true
kubectl delete rolebinding metrics-server-auth-reader -n kube-system 2>/dev/null || true
kubectl delete role metrics-server -n kube-system 2>/dev/null || true
kubectl delete clusterrole system:aggregated-metrics-reader 2>/dev/null || true
kubectl delete clusterrole system:metrics-server 2>/dev/null || true
kubectl delete clusterrolebinding metrics-server:system:auth-delegator 2>/dev/null || true
kubectl delete clusterrolebinding system:metrics-server 2>/dev/null || true
kubectl delete apiservice v1beta1.metrics.k8s.io 2>/dev/null || true

echo "    Done."
echo ""

echo "[2/4] Checking Helm installation..."

if ! command -v helm &> /dev/null; then
    echo "    Helm not found. Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "    Helm installed!"
else
    echo "    Helm already installed: $(helm version --short)"
fi
echo ""

echo "[3/4] Adding Metrics Server Helm repo..."

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ 2>/dev/null || true
helm repo update
echo ""

echo "[4/4] Installing Metrics Server via Helm..."

helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set hostNetwork.enabled=true \
  --set containerPort=10251 \
  --set args[0]=--kubelet-insecure-tls \
  --set args[1]=--secure-port=10251

echo ""
echo "============================================================"
echo "   Install complete! Waiting 60s for metrics to collect..."
echo "============================================================"
echo ""

sleep 60

echo "--- Helm Release ---"
helm list -n kube-system | grep metrics-server

echo ""
echo "--- Pod Status ---"
kubectl get pods -n kube-system | grep metrics-server

echo ""
echo "--- API Service Status ---"
kubectl get apiservice v1beta1.metrics.k8s.io

echo ""
echo "--- Node Metrics ---"
kubectl top nodes

echo ""
echo "============================================================"
echo "   Metrics Server is ready!"
echo "   kubectl top nodes"
echo "   kubectl top pods -n <namespace>"
echo "   kubectl top pods -n kube-system --sort-by=cpu"
echo "   kubectl top pods -n kube-system --sort-by=memory"
echo "============================================================"
