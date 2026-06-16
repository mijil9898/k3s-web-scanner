#!/bin/bash
# scripts/deploy.sh
set -euo pipefail

NAMESPACE='portfolio'
CHART_DIR='./helm-charts/portfolio-chart'
IMAGE_TAG=${1:-latest}

echo "=== Deploy với tag: $IMAGE_TAG ==="

kubectl cluster-info || { echo 'Lỗi: Không kết nối được cluster'; exit 1; }
kubectl get ns $NAMESPACE &>/dev/null || kubectl create ns $NAMESPACE

helm upgrade --install portfolio $CHART_DIR \
  --namespace $NAMESPACE \
  --set frontend.image.tag=$IMAGE_TAG \
  --set backend.image.tag=$IMAGE_TAG \
  --wait --timeout 5m \
  --atomic

echo '=== Trạng thái triển khai ==='
kubectl get pods -n $NAMESPACE
kubectl get ingress -n $NAMESPACE
