#!/usr/bin/env bash
set -euo pipefail

echo "🛑 Đang tắt hệ thống K3s Mijil..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default cluster
K3D_CLUSTER=${K3D_CLUSTER:-mijil-dev}

# Tắt các tiến trình port-forward đang chạy ngầm (nếu có) để giải phóng port
if command -v pkill >/dev/null 2>&1; then
    pkill -f "kubectl port-forward" 2>/dev/null || true
    echo "✅ Đã đóng các cổng port-forward."
else
    echo "ℹ️ pkill không có; bỏ qua đóng port-forward." >&2
fi

if command -v k3d >/dev/null 2>&1; then
    echo "⏳ Đang tắt k3d cluster: $K3D_CLUSTER"
    if k3d cluster list | grep -q "$K3D_CLUSTER"; then
        if k3d cluster stop "$K3D_CLUSTER"; then
            echo "✅ Đã tắt cluster k3d an toàn. Dữ liệu Database vẫn được bảo toàn."
        else
            echo "❌ Có lỗi xảy ra khi tắt cluster." >&2
        fi
    else
        echo "ℹ️ Cluster $K3D_CLUSTER không tồn tại hoặc đã bị xóa."
    fi
else
    echo "⚠️ k3d không cài đặt; nếu bạn dùng k3s, dừng cluster theo cách phù hợp." >&2
fi

