#!/usr/bin/env bash
set -euo pipefail

# URL.sh - tìm URL truy cập hiện tại cho dịch vụ (Quick Tunnel hoặc Named Tunnel)
NAMESPACE=${1:-mijil}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[URL.sh] Namespace: $NAMESPACE"

# 1) Quick Tunnel (trycloudflare) từ logs
echo "Searching for Quick Tunnel URL in cloudflared logs..."
# Prefer logs from the most-recently started cloudflared pod to avoid stale URLs
POD=$(kubectl -n "$NAMESPACE" get pods -l app=cloudflared -o jsonpath='{range .items[*]}{.metadata.name}|{.status.startTime}\n{end}' 2>/dev/null | sort -t'|' -k2 | tail -n1 | cut -d'|' -f1 || true)
if [ -n "$POD" ]; then
  QT_URL=$(kubectl -n "$NAMESPACE" logs "$POD" --tail=1000 2>/dev/null | grep -Eo 'https?://[a-z0-9-]+\.trycloudflare\.com' | tail -n1 || true)
else
  # Fallback: check any cloudflared logs by label
  QT_URL=$(kubectl -n "$NAMESPACE" logs -l app=cloudflared --tail=1000 2>/dev/null | grep -Eo 'https?://[a-z0-9-]+\.trycloudflare\.com' | tail -n1 || true)
fi

if [ -n "$QT_URL" ]; then
  echo "Found Quick Tunnel URL: $QT_URL"
  exit 0
fi

echo "No Quick Tunnel URL found in recent logs. Checking deployment/config for Named Tunnel or HOSTNAME..."

# 2) Check deployment env HOSTNAME
HOSTNAME=$(kubectl -n "$NAMESPACE" get deployment cloudflared -o yaml 2>/dev/null | awk '/name: *HOSTNAME/{getline; print}' | sed -E 's/.*value: *//') || true
if [ -n "$HOSTNAME" ]; then
  echo "Found HOSTNAME in cloudflared deployment: $HOSTNAME"
  echo "Try: https://$HOSTNAME"
  exit 0
fi

# 3) Check configmap for hostname or tunnel configuration
if kubectl -n "$NAMESPACE" get configmap cloudflared-config >/dev/null 2>&1; then
  echo "Inspecting ConfigMap cloudflared-config..."
  kubectl -n "$NAMESPACE" get configmap cloudflared-config -o yaml | sed -n '1,200p' | grep -Ei 'hostname|tunnel|url' || true
fi

# 4) Check Services/Ingress for external IPs / hostnames
echo "Checking Services and Ingresses in namespace $NAMESPACE..."
kubectl -n "$NAMESPACE" get svc --show-labels || true
kubectl -n "$NAMESPACE" get ingress || true

echo "If none of the above show a public URL, and you expect a Named Tunnel, run on a machine with cloudflared credentials:"
echo "  cloudflared tunnel list  # to list tunnels"
echo "  cloudflared tunnel route dns <TUNNEL-NAME>  # to see DNS route"

echo "Unable to determine a public URL automatically. If you want, run:"
echo "  kubectl -n $NAMESPACE logs -l app=cloudflared --tail=400 | grep trycloudflare"
echo "or paste output here and tôi sẽ giúp phân tích."

exit 1
