#!/usr/bin/env bash
set -euo pipefail

# full-deploy-verify.sh
# Runs deploy and performs a series of verification steps for the portfolio platform
# Usage: ./scripts/full-deploy-verify.sh [--sample /path/to/sample.file] [--namespace portfolio]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NAMESPACE=portfolio
SAMPLE_PATH="/tmp/sample-upload.bin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sample) SAMPLE_PATH="$2"; shift 2;;
    --namespace) NAMESPACE="$2"; shift 2;;
    -h|--help) echo "Usage: $0 [--sample /path] [--namespace ns]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

echo "Running full deploy+verify from: $REPO_ROOT"
cd "$REPO_ROOT"

echo; echo "1) Render Helm templates (syntax check)"
helm template portfolio ./helm-charts/portfolio-chart > /tmp/portfolio-render.yaml || { echo "Helm template failed"; exit 3; }
echo "OK: Helm template rendered to /tmp/portfolio-render.yaml"

echo; echo "2) Build & deploy using scripts/deploy-all.sh"
if [[ ! -x ./scripts/deploy-all.sh ]]; then
  chmod +x ./scripts/deploy-all.sh || true
fi
./scripts/deploy-all.sh

echo; echo "3) Wait for key deployments to be ready"
for d in malware-analyzer cloudflared frontend backend; do
  echo "Waiting deployment/$d..."
  kubectl -n "$NAMESPACE" rollout status deployment/$d --timeout=180s || true
done

echo; echo "4) Check pods"
kubectl -n "$NAMESPACE" get pods -o wide

echo; echo "5) Get cloudflared URL (if Quick Tunnel it prints to logs)"
kubectl -n "$NAMESPACE" logs -l app=cloudflared --tail=400 | grep -Eo 'https?://[^"\s]*trycloudflare\.com[^"\s]*' || echo "No trycloudflare URL found in logs"

echo; echo "6) Port-forward malware-analyzer service to localhost:5000 and check /health"
kubectl -n "$NAMESPACE" port-forward svc/malware-analyzer-service 5000:5000 >/dev/null 2>&1 &
PF_PID=$!
sleep 1
if ps -p $PF_PID >/dev/null 2>&1; then
  echo "Port-forward started (pid=$PF_PID). Curling /health..."
  if command -v curl >/dev/null 2>&1; then
    curl -sS http://127.0.0.1:5000/health || echo "health endpoint call failed"
  else
    echo "curl not installed locally; please run: curl http://127.0.0.1:5000/health"
  fi
  kill $PF_PID || true
else
  echo "Port-forward failed to start"
fi

echo; echo "7) Try an upload test (bypass Cloudflare)"
if [[ ! -f "$SAMPLE_PATH" ]]; then
  head -c 1024 /dev/zero > "$SAMPLE_PATH" || true
fi
if command -v curl >/dev/null 2>&1; then
  echo "Uploading $SAMPLE_PATH to local service..."
  curl -v -F "file=@${SAMPLE_PATH}" http://127.0.0.1:5000/analyze -o /tmp/analyze-response.json || echo "Upload request failed"
  echo "Saved response to /tmp/analyze-response.json"
else
  echo "curl not installed locally; skip upload test"
fi

echo; echo "8) Collect logs (last 200 lines)"
mkdir -p /tmp/verify-logs
kubectl -n "$NAMESPACE" logs -l app=malware-analyzer --tail=200 > /tmp/verify-logs/malware-analyzer.log || true
kubectl -n "$NAMESPACE" logs -l app=cloudflared --tail=200 > /tmp/verify-logs/cloudflared.log || true
kubectl -n "$NAMESPACE" logs -l app=frontend --tail=200 > /tmp/verify-logs/frontend.log || true

echo "Collected logs in /tmp/verify-logs"

echo; echo "9) Quick status summary"
kubectl -n "$NAMESPACE" get pods -o wide
kubectl -n "$NAMESPACE" get svc -o wide

echo; echo "Full-deploy-verify finished. If you see failures, paste /tmp/verify-logs/* and /tmp/analyze-response.json here."
