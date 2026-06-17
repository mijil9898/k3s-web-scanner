#!/bin/bash
echo "🛑 Đang tắt hệ thống K3s Portfolio..."

# Tắt các tiến trình port-forward đang chạy ngầm (nếu có) để giải phóng port
pkill -f "kubectl port-forward" 2>/dev/null
echo "✅ Đã đóng các cổng port-forward."

# Dừng cluster k3d (Giữ nguyên dữ liệu PVC, Image, chỉ giải phóng RAM/CPU)
k3d cluster stop portfolio-dev
if [ $? -eq 0 ]; then
    echo "✅ Đã tắt cluster k3d an toàn. Dữ liệu Database vẫn được bảo toàn."
else
    echo "❌ Có lỗi xảy ra khi tắt cluster."
fi

