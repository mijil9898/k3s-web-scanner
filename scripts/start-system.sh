#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Khởi động hệ thống K3s và tự động deploy (run-all)"

# Default cluster/name
K3D_CLUSTER=${K3D_CLUSTER:-portfolio-dev}
NAMESPACE=${NAMESPACE:-portfolio}

command -v kubectl >/dev/null 2>&1 || { echo "kubectl không tìm thấy. Cấu hình KUBECONFIG trước khi chạy." >&2; exit 1; }

echo "🟢 Bắt đầu cluster k3d: $K3D_CLUSTER"
if command -v k3d >/dev/null 2>&1; then
    k3d cluster start "$K3D_CLUSTER"
else
    echo "⚠️  k3d không cài đặt. Nếu bạn dùng k3s, đảm bảo kubeconfig trỏ tới cluster đúng." >&2
fi

echo "⏳ Đang chờ Kubernetes API sẵn sàng..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s || true

echo "📦 Chạy script tổng hợp deploy: scripts/run-all.sh"
if [ -x "$(pwd)/scripts/run-all.sh" ]; then
    scripts/run-all.sh || echo "[start-system] Lưu ý: scripts/run-all.sh trả lỗi; kiểm tra logs." >&2
else
    echo "[start-system] Không tìm thấy script scripts/run-all.sh hoặc không có quyền thực thi." >&2
fi

# Optional: auto-create cloudflared secret and route DNS if env vars provided
# Set the following ENV vars in your shell (or export in CI):
# CLOUDFLARED_CRED_PATH - path to ~/.cloudflared/<TUNNEL-ID>.json
# CF_TUNNEL_NAME - name used when creating tunnel (cloudflared tunnel create <name>)
# HOSTNAME - desired hostname (e.g. mijil-analyzer.example.com)
# If you want a GitHub CI trigger set GITHUB_REPO and GITHUB_TOKEN and WORKFLOW_FILE (filename) and BRANCH.

if [ -n "${CLOUDFLARED_CRED_PATH:-}" ] && [ -f "${CLOUDFLARED_CRED_PATH}" ]; then
    echo "🔐 Tạo Secret k8s từ cloudflared credentials: ${CLOUDFLARED_CRED_PATH}"
    kubectl -n $NAMESPACE create secret generic cloudflared-tunnel-credentials \
        --from-file=credentials.json="${CLOUDFLARED_CRED_PATH}" --dry-run=client -o yaml | kubectl apply -f -

    # Apply cloudflared manifests if exist
    if [ -d "k8s-manifests/cloudflared" ]; then
        echo "📄 Áp dụng manifests cloudflared"
        kubectl -n $NAMESPACE apply -f k8s-manifests/cloudflared/cloudflared-configmap.yaml || true
        kubectl -n $NAMESPACE apply -f k8s-manifests/cloudflared/cloudflared-deployment-named.yaml || true
    fi

    # If CF_TUNNEL_NAME and HOSTNAME provided, attempt to route DNS (requires cloudflared login)
    if [ -n "${CF_TUNNEL_NAME:-}" ] && [ -n "${HOSTNAME:-}" ]; then
        if command -v cloudflared >/dev/null 2>&1; then
            echo "🌐 Routing DNS: cloudflared tunnel route dns $CF_TUNNEL_NAME $HOSTNAME"
            cloudflared tunnel route dns "$CF_TUNNEL_NAME" "$HOSTNAME" || echo "[start-system] route dns failed; ensure cloudflared logged in and domain is in Cloudflare." >&2
        else
            echo "⚠️ cloudflared không cài; không thể route DNS tự động." >&2
        fi
    fi
fi

# Show cloudflared public URL (trycloudflare) if present in logs
echo "🔎 Kiểm tra Cloudflared logs để tìm URL public (trycloudflare) hoặc hiển thị HOSTNAME nếu đã set"
kubectl -n $NAMESPACE logs -l app=cloudflared --tail=200 || true

if [ -n "${HOSTNAME:-}" ]; then
    echo "🔔 Hostname đã yêu cầu: $HOSTNAME"
else
    echo "🔔 Nếu bạn chưa có HOSTNAME, Cloudflared Quick Tunnel URL có thể xuất hiện trong logs trên stdout above."
fi

# Optional: trigger GitHub Actions workflow dispatch
if [ -n "${GITHUB_REPO:-}" ] && [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${WORKFLOW_FILE:-}" ]; then
    BRANCH=${BRANCH:-main}
    echo "🚀 Trigger GitHub Actions workflow $WORKFLOW_FILE on $GITHUB_REPO#$BRANCH"
    curl -s -X POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        https://api.github.com/repos/${GITHUB_REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches \
        -d "{\"ref\": \"${BRANCH}\"}" || echo "[start-system] GitHub dispatch failed"
fi

echo "✅ HỆ THỐNG KHỞI ĐỘNG XONG. Kiểm tra pods:"
kubectl get pods -n $NAMESPACE || true

echo "📌 Nếu cần xem logs cloudflared realtime: kubectl -n $NAMESPACE logs -l app=cloudflared -f"

exit 0
