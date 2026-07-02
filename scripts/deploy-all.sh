#!/usr/bin/env bash
set -euo pipefail

# Script deploy-all đã được chuyển vào thư mục scripts/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MALWARE_DIR="$REPO_ROOT/apps/malware-analyzer"
FRONTEND_DIR="$REPO_ROOT/apps/frontend"
BACKEND_DIR="$REPO_ROOT/apps/backend"
MALWARE_IMAGE="malware-analyzer:latest"
FRONTEND_IMAGE="mijil-frontend:latest"
BACKEND_IMAGE="mijil-backend:latest"
K3D_CLUSTER=${K3D_CLUSTER:-mijil-dev}
NAMESPACE=mijil

# Xác minh các công cụ CLI cần thiết
for cmd in docker kubectl helm; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "Required command '$cmd' not found in PATH. Install/enable it before running." >&2
    exit 2
  fi
done

if [ ! -d "$MALWARE_DIR" ]; then
  echo "malware-analyzer not found at $MALWARE_DIR" >&2
  exit 2
fi

if ! command -v k3d >/dev/null 2>&1; then
  echo "Warning: k3d not found. If you are using k3d, install it or set K3D_CLUSTER to a running cluster." >&2
fi

echo "Building Docker images"

cd "$FRONTEND_DIR"
echo "Building $FRONTEND_IMAGE"
docker build -t $FRONTEND_IMAGE .

cd "$BACKEND_DIR"
echo "Building $BACKEND_IMAGE"
docker build -t $BACKEND_IMAGE .

cd "$MALWARE_DIR"
echo "Building $MALWARE_IMAGE"
docker build -t $MALWARE_IMAGE .

TMP_TAR=$(mktemp --suffix=-images.tar)
trap 'rm -f "$TMP_TAR" 2>/dev/null || true' EXIT

echo "Saving images to $TMP_TAR"
docker save $FRONTEND_IMAGE $BACKEND_IMAGE $MALWARE_IMAGE -o "$TMP_TAR"

if command -v k3d >/dev/null 2>&1; then
  echo "Importing images into k3d cluster $K3D_CLUSTER"
  k3d image import -c "$K3D_CLUSTER" "$TMP_TAR"
else
  echo "k3d not available; ensure the images are available to your cluster (push to registry)." >&2
fi

echo "Ensure secret $NAMESPACE/malware-secrets exists (creating random values if missing)"
kubectl -n $NAMESPACE create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
if ! kubectl -n $NAMESPACE get secret malware-secrets >/dev/null 2>&1; then
  SECRET_KEY=$(openssl rand -hex 32)
  TOKEN=$(openssl rand -hex 16)
  kubectl -n $NAMESPACE create secret generic malware-secrets \
    --from-literal=SECRET_KEY="$SECRET_KEY" \
    --from-literal=ANALYZE_AUTH_TOKEN="$TOKEN" \
    --from-literal=VT_API_KEY='' \
    --from-literal=OTX_API_KEY=''
fi

echo "Ensure secret $NAMESPACE/postgres-secret exists"
if ! kubectl -n $NAMESPACE get secret postgres-secret >/dev/null 2>&1; then
  DB_PASS=$(openssl rand -hex 16)
  kubectl -n $NAMESPACE create secret generic postgres-secret \
    --from-literal=password="$DB_PASS"
fi

echo "Ensure secret $NAMESPACE/neo4j-secret exists"
if ! kubectl -n $NAMESPACE get secret neo4j-secret > /dev/null 2>&1; then
  NEO4J_PASS=$(openssl rand -hex 16)
  kubectl -n $NAMESPACE create secret generic neo4j-secret \
    --from-literal=password="$NEO4J_PASS" \
    --from-literal=neo4j_auth="neo4j/$NEO4J_PASS"
fi

echo "Helm upgrade/install mijil chart"
cd "$REPO_ROOT/helm-charts/mijil-chart"
helm upgrade --install mijil . -n $NAMESPACE --create-namespace

echo "Waiting for malware-analyzer and cloudflared pods to be ready"
kubectl -n $NAMESPACE wait --for=condition=available --timeout=180s deployment/malware-analyzer || true
kubectl -n $NAMESPACE rollout status deployment/malware-analyzer --timeout=180s || true
kubectl -n $NAMESPACE rollout status deployment/cloudflared --timeout=180s || true

echo "Waiting for Neo4j to be ready (may take up to 60s for JVM startup)"
kubectl -n $NAMESPACE rollout status deployment/neo4j --timeout=240s || true

echo "Cloudflared public URL (may take a minute to appear):"
kubectl -n $NAMESPACE logs -l app=cloudflared --tail=400 | grep -Eo 'https?://[^"\s]*trycloudflare\.com[^"\s]*' || true

echo ""
echo "=== Pod status ==="
kubectl get pods -n $NAMESPACE

echo "Done."
