#!/usr/bin/env bash
# start-system.sh — Khởi động k3d cluster + patch mọi lỗi phổ biến tự động
# Các lỗi được xử lý:
#   [E1] Docker chưa chạy
#   [E2] Port 80/443 đang bị chiếm
#   [E3] Cluster container ở trạng thái xấu (exited/dead)
#   [E4] serverlb bị tách khỏi Docker network → nginx crash loop
#   [E5] kubeconfig stale (0.0.0.0:PORT bị mất sau restart)
#   [E6] kubeconfig context sai cluster
#   [E7] API server chưa sẵn sàng (race condition sau start)
#   [E8] Namespace không tồn tại

set -uo pipefail   # pipefail nhưng KHÔNG set -e (script tự handle exit)

echo "🚀 Khởi động hệ thống K3s và tự động deploy"

# ─── Cấu hình ──────────────────────────────────────────────────────────────
K3D_CLUSTER=${K3D_CLUSTER:-mijil-dev}
NAMESPACE=${NAMESPACE:-mijil}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── Tiện ích ───────────────────────────────────────────────────────────────
log_ok()   { echo "✅ $*"; }
log_info() { echo "ℹ️  $*"; }
log_warn() { echo "⚠️  $*" >&2; }
log_err()  { echo "❌ $*" >&2; }
die()      { log_err "$*"; exit 1; }

# ─── [PRE] Kiểm tra công cụ bắt buộc ───────────────────────────────────────
echo ""
echo "🔍 Kiểm tra môi trường..."

command -v kubectl >/dev/null 2>&1 || die "kubectl không tìm thấy. Cài kubectl trước."
command -v k3d    >/dev/null 2>&1 || die "k3d không tìm thấy. Cài k3d trước: https://k3d.io"
command -v docker >/dev/null 2>&1 || die "docker không tìm thấy."

# ─── [E1] Docker có đang chạy không? ───────────────────────────────────────
if ! docker info >/dev/null 2>&1; then
    die "[E1] Docker daemon chưa chạy. Hãy khởi động Docker Desktop trước."
fi
log_ok "Docker đang chạy"

# ─── [E2] Kiểm tra port conflict 80/443 ────────────────────────────────────
check_port() {
    local port=$1
    # ss hoặc netstat để kiểm tra port đang bị chiếm bởi non-Docker process
    if ss -tlnp 2>/dev/null | grep -q ":${port} " ; then
        # Nếu port đang dùng bởi container k3d thì ok, ngược lại cảnh báo
        local owner
        owner=$(ss -tlnp 2>/dev/null | grep ":${port} " | head -1)
        log_warn "[E2] Port ${port} đang bị chiếm: ${owner}"
        log_warn "     Nếu lỗi serverlb, hãy giải phóng port ${port} trước."
    fi
}
check_port 80
check_port 443

# ─── [E3] Dọn container zombie (exited/dead) trước khi start ───────────────
echo ""
echo "🧹 Kiểm tra containers zombie..."
for CONTAINER_SUFFIX in "server-0" "agent-0" "serverlb"; do
    CNAME="k3d-${K3D_CLUSTER}-${CONTAINER_SUFFIX}"
    STATUS=$(docker inspect "$CNAME" --format '{{.State.Status}}' 2>/dev/null || echo "missing")
    case "$STATUS" in
        "exited"|"dead"|"created")
            log_warn "[E3] Container $CNAME ở trạng thái '$STATUS' — xóa để k3d tạo lại sạch..."
            docker rm -f "$CNAME" 2>/dev/null || true
            ;;
        "running"|"restarting"|"paused"|"missing")
            # ok hoặc sẽ xử lý ở bước sau
            ;;
    esac
done

# ─── Khởi động hoặc tạo cluster ─────────────────────────────────────────────
echo ""
echo "🟢 Xử lý cluster k3d: $K3D_CLUSTER"

if k3d cluster list 2>/dev/null | grep -q "^${K3D_CLUSTER}[[:space:]]"; then
    log_info "Cluster đã tồn tại — start lại..."
    k3d cluster start "$K3D_CLUSTER" || {
        log_warn "k3d cluster start thất bại lần 1, thử restart..."
        k3d cluster stop "$K3D_CLUSTER" 2>/dev/null || true
        sleep 3
        k3d cluster start "$K3D_CLUSTER" || die "Không thể start cluster. Thử: k3d cluster delete $K3D_CLUSTER"
    }
else
    log_info "Cluster chưa tồn tại — tạo mới..."
    k3d cluster create "$K3D_CLUSTER" \
        --servers 1 --agents 1 \
        -p "80:80@loadbalancer" \
        -p "443:443@loadbalancer" \
        || die "Không thể tạo cluster k3d."
fi

# ─── [E4] Fix serverlb crash loop (lost Docker network) ────────────────────
echo ""
echo "🔌 Kiểm tra serverlb..."
SERVERLB="k3d-${K3D_CLUSTER}-serverlb"
NETWORK="k3d-${K3D_CLUSTER}"

fix_serverlb() {
    local attempt=${1:-1}
    local is_in_net is_restarting
    is_in_net=$(docker network inspect "$NETWORK" \
        --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null \
        | grep -c "$SERVERLB" || echo "0")
    is_restarting=$(docker inspect "$SERVERLB" \
        --format '{{.State.Restarting}}' 2>/dev/null || echo "false")

    if [ "$is_in_net" -eq 0 ] || [ "$is_restarting" = "true" ]; then
        log_warn "[E4] serverlb bị tách network hoặc đang crash (attempt $attempt/3)..."
        docker network connect "$NETWORK" "$SERVERLB" 2>/dev/null || true
        docker restart "$SERVERLB" 2>/dev/null || true
        # Chờ ổn định
        local j stable=false
        for j in $(seq 1 15); do
            local st
            st=$(docker inspect "$SERVERLB" --format '{{.State.Restarting}}' 2>/dev/null || echo "true")
            if [ "$st" = "false" ]; then stable=true; break; fi
            sleep 2
        done
        if [ "$stable" = "true" ]; then
            log_ok "serverlb ổn định sau khi reconnect"
        else
            if [ "$attempt" -lt 3 ]; then
                log_warn "serverlb vẫn không ổn — thử lại..."
                fix_serverlb $((attempt + 1))
            else
                log_warn "serverlb vẫn restarting sau 3 lần thử. Tiếp tục nhưng có thể lỗi load balancer."
            fi
        fi
    else
        log_ok "serverlb đang chạy bình thường"
    fi
}
fix_serverlb 1

# ─── [E5] Fix kubeconfig stale address ─────────────────────────────────────
echo ""
echo "🔄 Cập nhật kubeconfig..."
k3d kubeconfig merge "$K3D_CLUSTER" --kubeconfig-merge-default >/dev/null 2>&1 || \
    log_warn "k3d kubeconfig merge thất bại — tiếp tục với kubeconfig hiện có."

SERVER_CONTAINER="k3d-${K3D_CLUSTER}-server-0"
SERVER_IP=$(docker inspect "$SERVER_CONTAINER" \
    --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
    2>/dev/null | tr ' ' '\n' | grep -v '^$' | head -1)

if [ -n "$SERVER_IP" ]; then
    kubectl config set-cluster "k3d-${K3D_CLUSTER}" \
        --server="https://${SERVER_IP}:6443" >/dev/null 2>&1
    log_ok "API server: https://${SERVER_IP}:6443"
else
    log_warn "[E5] Không lấy được IP server container — kubeconfig có thể sai địa chỉ."
fi

# ─── [E6] Đảm bảo context đúng cluster ────────────────────────────────────
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "")
EXPECTED_CTX="k3d-${K3D_CLUSTER}"
if [ "$CURRENT_CTX" != "$EXPECTED_CTX" ]; then
    log_warn "[E6] Context hiện tại '$CURRENT_CTX' ≠ '$EXPECTED_CTX' — đang switch..."
    kubectl config use-context "$EXPECTED_CTX" >/dev/null 2>&1 || \
        log_warn "Không thể switch context. kubectl có thể dùng sai cluster."
else
    log_ok "Context: $CURRENT_CTX"
fi

# ─── [E7] Chờ API sẵn sàng với retry ──────────────────────────────────────
echo ""
echo "⏳ Đang chờ Kubernetes API sẵn sàng..."
API_READY=false
for i in $(seq 1 30); do
    if kubectl cluster-info >/dev/null 2>&1; then
        API_READY=true
        log_ok "API sẵn sàng (thử lần $i)"
        break
    fi
    echo "  [${i}/30] API chưa sẵn sàng, thử lại sau 3s..."
    # Nếu lần 10 vẫn chưa được → thử patch lại kubeconfig một lần nữa
    if [ "$i" -eq 10 ] && [ -n "$SERVER_IP" ]; then
        log_warn "  API chậm — thử patch kubeconfig lần 2..."
        kubectl config set-cluster "k3d-${K3D_CLUSTER}" \
            --server="https://${SERVER_IP}:6443" >/dev/null 2>&1 || true
    fi
    sleep 3
done

if [ "$API_READY" = false ]; then
    die "[E7] Kubernetes API không phản hồi sau 90 giây.
   Debug: docker ps --filter name=k3d-${K3D_CLUSTER}
          kubectl config view --minify
          docker logs k3d-${K3D_CLUSTER}-server-0 --tail=30"
fi

kubectl wait --for=condition=Ready nodes --all --timeout=60s 2>/dev/null || \
    log_warn "Một số node chưa Ready nhưng tiếp tục..."

# ─── [E8] Đảm bảo namespace tồn tại ──────────────────────────────────────
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    log_warn "[E8] Namespace '$NAMESPACE' chưa tồn tại — tạo mới..."
    kubectl create namespace "$NAMESPACE" || log_warn "Không tạo được namespace."
fi

# ─── Cloudflared credentials (optional) ────────────────────────────────────
if [ -n "${CLOUDFLARED_CRED_PATH:-}" ] && [ -f "${CLOUDFLARED_CRED_PATH}" ]; then
    echo ""
    echo "🔐 Tạo Secret k8s từ cloudflared credentials..."
    kubectl -n "$NAMESPACE" create secret generic cloudflared-tunnel-credentials \
        --from-file=credentials.json="${CLOUDFLARED_CRED_PATH}" \
        --dry-run=client -o yaml | kubectl apply -f - || \
        log_warn "Không tạo được cloudflared secret."

    if [ -d "$REPO_ROOT/k8s-manifests/cloudflared" ]; then
        echo "📄 Áp dụng manifests cloudflared..."
        kubectl -n "$NAMESPACE" apply \
            -f "$REPO_ROOT/k8s-manifests/cloudflared/cloudflared-configmap.yaml" || true
        kubectl -n "$NAMESPACE" apply \
            -f "$REPO_ROOT/k8s-manifests/cloudflared/cloudflared-deployment-named.yaml" || true
    fi

    if [ -n "${CF_TUNNEL_NAME:-}" ] && [ -n "${HOSTNAME:-}" ]; then
        if command -v cloudflared >/dev/null 2>&1; then
            echo "🌐 Routing DNS: $CF_TUNNEL_NAME → $HOSTNAME"
            cloudflared tunnel route dns "$CF_TUNNEL_NAME" "$HOSTNAME" || \
                log_warn "route dns thất bại; đảm bảo cloudflared đã login."
        fi
    fi
fi

# ─── Hiển thị Cloudflare tunnel URL ────────────────────────────────────────
echo ""
echo "🔎 Cloudflared logs (tìm URL public)..."
kubectl -n "$NAMESPACE" logs -l app=cloudflared --tail=50 2>/dev/null \
    | grep -E "(trycloudflare|Registered tunnel|Your quick Tunnel)" || true

if [ -n "${HOSTNAME:-}" ]; then
    echo "🔔 Hostname: $HOSTNAME"
fi

# ─── GitHub Actions trigger (optional) ─────────────────────────────────────
if [ -n "${GITHUB_REPO:-}" ] && [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${WORKFLOW_FILE:-}" ]; then
    BRANCH=${BRANCH:-main}
    echo "🚀 Trigger GitHub Actions: $GITHUB_REPO/$WORKFLOW_FILE @ $BRANCH"
    curl -s -X POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches" \
        -d "{\"ref\": \"${BRANCH}\"}" || log_warn "GitHub dispatch thất bại."
fi

# ─── Kết quả ────────────────────────────────────────────────────────────────
echo ""
echo "✅ HỆ THỐNG KHỞI ĐỘNG XONG. Pods:"
kubectl get pods -n "$NAMESPACE" 2>/dev/null || log_warn "Không lấy được pod list."

echo ""
echo "📌 Xem cloudflared logs realtime: kubectl -n $NAMESPACE logs -l app=cloudflared -f"
echo "📌 Deploy apps: ./scripts/deploy-all.sh"

exit 0
