#!/bin/bash
# scripts/setup-k3s.sh - Cài K3s trên Linux production
set -euo pipefail

echo "=== Cài đặt K3s ==="
curl -sfL https://get.k3s.io | sh -s - \
  --disable traefik \
  --write-kubeconfig-mode 644

sleep 10
kubectl wait --for=condition=Ready node --all --timeout=120s

mkdir -p $HOME/.kube
cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

echo "=== Cài Traefik v2 ==="
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set globalArguments[0]='--global.checknewversion=false'

echo "=== Cài Cert-Manager ==="
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true

echo "=== K3s đã sẵn sàng! ==="
kubectl get nodes
