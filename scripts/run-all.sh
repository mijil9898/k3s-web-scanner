#!/usr/bin/env bash
set -euo pipefail

# scripts/run-all.sh
# Tập hợp các bước deploy & test tự động cho môi trường dev (k3d/k3s)
# Không tự động push lên remote; script chỉ tạo artifacts và in hướng dẫn push.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MALWARE_DIR="$ROOT_DIR/apps/malware-analyzer"
IMAGE_NAME="malware-analyzer:latest"
K3D_CLUSTER=${K3D_CLUSTER:-portfolio-dev}
NAMESPACE=${NAMESPACE:-portfolio}

echo "[run-all] Working dir: $ROOT_DIR"

command -v docker >/dev/null 2>&1 || { echo "docker CLI không tìm thấy. Chạy trên host có Docker." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl không tìm thấy. Cấu hình KUBECONFIG trước khi chạy." >&2; exit 1; }

if [ ! -d "$MALWARE_DIR" ]; then
  echo "Không tìm thấy malware-analyzer tại $MALWARE_DIR" >&2
  exit 2
fi

echo "[run-all] 1) Build Docker image"
cd "$MALWARE_DIR"
docker build -t $IMAGE_NAME .

echo "[run-all] 2) Save image and import vào k3d (nếu k3d tồn tại)"
TMP_TAR=$(mktemp --suffix=-malware-analyzer.tar)
docker save $IMAGE_NAME -o "$TMP_TAR"
if command -v k3d >/dev/null 2>&1; then
  echo "[run-all] Import image vào k3d cluster $K3D_CLUSTER"
  k3d image import -c "$K3D_CLUSTER" "$TMP_TAR"
else
  echo "[run-all] k3d không cài; nếu bạn dùng k3s trên node khác vui lòng push image lên registry." >&2
fi

echo "[run-all] 3) Tạo namespace + malware-secrets nếu chưa có"
kubectl -n $NAMESPACE create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
if ! kubectl -n $NAMESPACE get secret malware-secrets >/dev/null 2>&1; then
  SECRET_KEY=$(openssl rand -hex 32)
  TOKEN=$(openssl rand -hex 16)
  kubectl -n $NAMESPACE create secret generic malware-secrets \
    --from-literal=SECRET_KEY="$SECRET_KEY" \
    --from-literal=ANALYZE_AUTH_TOKEN="$TOKEN" \
    --from-literal=VT_API_KEY='' \
    --from-literal=OTX_API_KEY=''
  echo "[run-all] Tạo secret malware-secrets (ANALYZE_AUTH_TOKEN được sinh mới)."
else
  echo "[run-all] Secret malware-secrets đã tồn tại; bỏ qua tạo mới."
fi

echo "[run-all] 4) Helm upgrade/install portfolio chart"
cd "$ROOT_DIR/helm-charts/portfolio-chart"
helm upgrade --install portfolio . -n $NAMESPACE --create-namespace

echo "[run-all] 5) Chờ deployment sẵn sàng (malware-analyzer, cloudflared)"
kubectl -n $NAMESPACE wait --for=condition=available --timeout=180s deployment/malware-analyzer || true
kubectl -n $NAMESPACE rollout status deployment/malware-analyzer --timeout=180s || true
kubectl -n $NAMESPACE rollout status deployment/cloudflared --timeout=180s || true

echo "[run-all] 6) In Cloudflared public URL (nếu dùng Quick Tunnel)"
kubectl -n $NAMESPACE logs -l app=cloudflared --tail=400 | grep -Eo 'https?://[^"\s]*trycloudflare\.com[^"\s]*' || true

echo "[run-all] 7) Chạy test analyze (port-forward + gửi sample)"
cd "$ROOT_DIR/scripts"
if [ -x ./assistant-run-analyze-test.sh ]; then
  ./assistant-run-analyze-test.sh || echo "[run-all] Test analyze trả lỗi — kiểm tra logs." >&2
else
  echo "[run-all] Không tìm thấy hoặc không executable: assistant-run-analyze-test.sh" >&2
fi

echo
echo "[run-all] Hoàn thành. Nếu bạn muốn commit file script này và đẩy lên GitHub, chạy:" \
  "git add scripts/run-all.sh && git commit -m 'Add combined run-all script' && git push origin <branch>"

exit 0
