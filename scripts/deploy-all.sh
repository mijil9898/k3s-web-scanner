#!/usr/bin/env bash
set -euo pipefail

# Wrapper deploy-all moved into scripts/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MALWARE_DIR="$REPO_ROOT/apps/malware-analyzer"
IMAGE_NAME="malware-analyzer:latest"
K3D_CLUSTER=${K3D_CLUSTER:-portfolio-dev}
NAMESPACE=portfolio

if [ ! -d "$MALWARE_DIR" ]; then
  echo "malware-analyzer not found at $MALWARE_DIR" >&2
  exit 2
fi

echo "Building Docker image from $MALWARE_DIR"
cd "$MALWARE_DIR"
docker build -t $IMAGE_NAME .

TMP_TAR=$(mktemp --suffix=-malware-analyzer.tar)
echo "Saving image to $TMP_TAR"
docker save $IMAGE_NAME -o "$TMP_TAR"

echo "Importing image into k3d cluster $K3D_CLUSTER"
k3d image import -c "$K3D_CLUSTER" "$TMP_TAR"

echo "Ensure secret $NAMESPACE/malware-secrets exists (creating random values if missing)"
if ! kubectl -n $NAMESPACE get secret malware-secrets >/dev/null 2>&1; then
  SECRET_KEY=$(openssl rand -hex 32)
  TOKEN=$(openssl rand -hex 16)
  kubectl -n $NAMESPACE create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n $NAMESPACE create secret generic malware-secrets \
    --from-literal=SECRET_KEY="$SECRET_KEY" \
    --from-literal=ANALYZE_AUTH_TOKEN="$TOKEN" \
    --from-literal=VT_API_KEY='' \
    --from-literal=OTX_API_KEY=''
fi

echo "Helm upgrade/install portfolio chart"
cd "$REPO_ROOT/helm-charts/portfolio-chart"
helm upgrade --install portfolio . -n $NAMESPACE --create-namespace

echo "Waiting for malware-analyzer and cloudflared pods to be ready"
kubectl -n $NAMESPACE wait --for=condition=available --timeout=180s deployment/malware-analyzer || true
kubectl -n $NAMESPACE rollout status deployment/malware-analyzer --timeout=180s || true
kubectl -n $NAMESPACE rollout status deployment/cloudflared --timeout=180s || true

echo "Cloudflared public URL (may take a minute to appear):"
kubectl -n $NAMESPACE logs -l app=cloudflared --tail=400 | grep -Eo 'https?://[^"\s]*trycloudflare\.com[^"\s]*' || true

echo "Done."
