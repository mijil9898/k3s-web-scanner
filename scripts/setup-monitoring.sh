#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Cài đặt Prometheus & Grafana stack vào namespace 'monitoring'..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Cài đặt kube-prometheus-stack
# Thiết lập prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false để scrape TẤT CẢ ServiceMonitors bất kể nhãn.
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --wait

echo "✅ Đã cài đặt Prometheus Stack thành công."
echo "Để truy cập Grafana, sử dụng port-forward:"
echo "kubectl port-forward svc/monitoring-grafana 3001:80 -n monitoring"
echo "Tài khoản mặc định: admin / prom-operator"
