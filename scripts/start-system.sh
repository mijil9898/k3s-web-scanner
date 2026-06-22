#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Khởi động hệ thống K3s và tự động deploy"

# Default cluster/name
K3D_CLUSTER=${K3D_CLUSTER:-mijil-dev}
NAMESPACE=${NAMESPACE:-mijil}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl không tìm thấy. Cấu hình KUBECONFIG trước khi chạy." >&2; exit 1; }

echo "🟢 Bắt đầu cluster k3d: $K3D_CLUSTER"
if command -v k3d >/dev/null 2>&1; then
    if k3d cluster list | grep -q "$K3D_CLUSTER"; then
        echo "🟢 Bắt đầu cluster k3d đã có: $K3D_CLUSTER"
        k3d cluster start "$K3D_CLUSTER"

        # Fix: sau restart, serverlb có thể bị mất khỏi Docker network → nginx crash loop.
        # Nếu serverlb đang restarting hoặc chưa join network → reconnect và restart.
        SERVERLB="k3d-${K3D_CLUSTER}-serverlb"
        NETWORK="k3d-${K3D_CLUSTER}"
        IS_IN_NET=$(docker network inspect "$NETWORK" \
            --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | grep -c "$SERVERLB" || true)
        IS_RESTARTING=$(docker inspect "$SERVERLB" \
            --format '{{.State.Restarting}}' 2>/dev/null || echo "false")
        if [ "$IS_IN_NET" -eq 0 ] || [ "$IS_RESTARTING" = "true" ]; then
            echo "🔌 serverlb chưa join network hoặc đang crash — reconnect và restart..."
            docker network connect "$NETWORK" "$SERVERLB" 2>/dev/null || true
            docker restart "$SERVERLB"
            # Chờ serverlb ổn định
            for j in $(seq 1 10); do
                STATUS=$(docker inspect "$SERVERLB" --format '{{.State.Restarting}}' 2>/dev/null || echo "true")
                [ "$STATUS" = "false" ] && break
                sleep 2
            done
            echo "✅ serverlb đã ổn định"
        fi
    else
        echo "🟢 Tạo mới cluster k3d: $K3D_CLUSTER"
        k3d cluster create "$K3D_CLUSTER" --servers 1 --agents 1 -p "80:80@loadbalancer" -p "443:443@loadbalancer"
    fi
    echo "🔄 Cập nhật kubeconfig..."
    k3d kubeconfig merge "$K3D_CLUSTER" --kubeconfig-merge-default

    # k3d's kubeconfig uses 0.0.0.0:<port> (host port mapping) which breaks
    # after Docker/WSL restarts when the port binding is lost.
    # Patch the server address to the container's stable internal Docker IP instead.
    SERVER_CONTAINER="k3d-${K3D_CLUSTER}-server-0"
    SERVER_IP=$(docker inspect "$SERVER_CONTAINER" \
        --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$SERVER_IP" ]; then
        echo "🔧 Gán server API: https://${SERVER_IP}:6443"
        kubectl config set-cluster "k3d-${K3D_CLUSTER}" --server="https://${SERVER_IP}:6443"
    else
        echo "⚠️  Không lấy được IP container ${SERVER_CONTAINER}; dùng địa chỉ mặc định từ kubeconfig." >&2
    fi
else
    echo "⚠️  k3d không cài đặt. Nếu bạn dùng k3s, đảm bảo kubeconfig trỏ tới cluster đúng." >&2
fi

echo "⏳ Đang chờ Kubernetes API sẵn sàng..."
API_READY=false
for i in $(seq 1 30); do
    if kubectl cluster-info >/dev/null 2>&1; then
        API_READY=true
        break
    fi
    echo "  [${i}/30] API chưa sẵn sàng, thử lại sau 3s..."
    sleep 3
done
if [ "$API_READY" = false ]; then
    echo "❌ Kubernetes API không phản hồi sau 90 giây. Kiểm tra k3d cluster status." >&2
    exit 1
fi
kubectl wait --for=condition=Ready nodes --all --timeout=60s || true

echo "📦 Cluster đã sẵn sàng. Để deploy ứng dụng, hãy chạy thủ công script: ./scripts/deploy-all.sh"

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
