#!/bin/bash
echo "🚀 Đang khởi động hệ thống K3s "

# Bật lại cluster k3d
k3d cluster start portfolio-dev
if [ $? -ne 0 ]; then
    echo "❌ Không thể khởi động cluster. Vui lòng kiểm tra lại Docker/WSL2."
    exit 1
fi

# Đợi Kubernetes API sẵn sàng
echo "⏳ Đang chờ Kubernetes API sẵn sàng..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null 2>&1

# Kiểm tra nhanh trạng thái Pod cốt lõi
echo "📊 Trạng thái các Pod trong namespace 'portfolio':"
kubectl get pods -n portfolio

echo ""
echo "✅ HỆ THỐNG ĐÃ SẴN SÀNG!"
echo "🌐 Truy cập Web App tại: http://portfolio.local:8080"
echo "📈 Để xem Grafana, mở terminal khác và chạy: kubectl port-forward svc/prometheus-grafana 8082:80 -n monitoring"
