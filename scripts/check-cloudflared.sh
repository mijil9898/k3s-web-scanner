#!/usr/bin/env bash
set -euo pipefail

# check-cloudflared.sh
# Quick health and Cloudflared troubleshooting script for the portfolio namespace
# Usage: ./scripts/check-cloudflared.sh [--credentials /path/to/credentials.json]

NAMESPACE=${NAMESPACE:-portfolio}
CREDENTIALS_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --credentials)
      CREDENTIALS_PATH="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

echo "Namespace: $NAMESPACE"
echo "-- Pods (cloudflared)"
kubectl -n "$NAMESPACE" get pods -l app=cloudflared -o wide || true

echo
echo "-- Recent cloudflared logs (last 200 lines)"
kubectl -n "$NAMESPACE" logs -l app=cloudflared --tail=200 || true

echo
echo "-- Searching for trycloudflare URL in logs"
kubectl -n "$NAMESPACE" logs -l app=cloudflared --tail=400 2>/dev/null | grep -Eo 'https?://[^"\s]*trycloudflare\.com[^"\s]*' || true

echo
echo "-- Cloudflared Deployment"
kubectl -n "$NAMESPACE" describe deployment cloudflared || true

echo
echo "-- cloudflared ConfigMap"
kubectl -n "$NAMESPACE" get configmap cloudflared-config -o yaml || true

echo
echo "-- cloudflared secret (credentials)"
kubectl -n "$NAMESPACE" get secret cloudflared-tunnel-credentials -o yaml || true

echo
echo "-- Malware-analyzer service"
kubectl -n "$NAMESPACE" get svc malware-analyzer-service -o wide || true

echo
echo "-- Attempting to port-forward malware-analyzer service to localhost:5000 and curl /health"
PF_PID=""
kubectl -n "$NAMESPACE" port-forward svc/malware-analyzer-service 5000:5000 >/dev/null 2>&1 &
PF_PID=$!
sleep 1
if ps -p $PF_PID >/dev/null 2>&1; then
  echo "port-forward started (pid=$PF_PID), testing /health..."
  if command -v curl >/dev/null 2>&1; then
    curl -sS http://127.0.0.1:5000/health || echo "curl to /health failed"
  else
    echo "curl not found locally — please run: curl http://127.0.0.1:5000/health"
  fi
  kill $PF_PID || true
else
  echo "port-forward failed to start"
fi

if [[ -n "$CREDENTIALS_PATH" ]]; then
  echo
  echo "-- Creating cloudflared secret from: $CREDENTIALS_PATH"
  if [[ -f "$CREDENTIALS_PATH" ]]; then
    kubectl -n "$NAMESPACE" create secret generic cloudflared-tunnel-credentials --from-file=credentials.json="$CREDENTIALS_PATH" --dry-run=client -o yaml | kubectl apply -f -
    echo "Restarting cloudflared deployment..."
    kubectl -n "$NAMESPACE" rollout restart deployment/cloudflared
    echo "Watch logs: kubectl -n $NAMESPACE logs -l app=cloudflared -f"
  else
    echo "Credentials file not found: $CREDENTIALS_PATH"
    exit 2
  fi
fi

echo
echo "Done. If you need further analysis, paste the output above here."
