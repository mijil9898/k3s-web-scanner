#!/usr/bin/env bash
set -euo pipefail

# fix-cluster.sh
# Script hỗ trợ chẩn đoán và chuẩn bị các bước khôi phục cho namespace mijil.
# Chú ý: script này sẽ in các lệnh cần chạy để sửa; chỉ thực hiện hành động nguy hiểm
# (force-delete, rollout restart) khi chạy với --apply (non-interactive).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NAMESPACE=${1:-mijil}
MODE="check" # check | apply

if [ "${2:-}" = "--apply" ] || [ "${2:-}" = "apply" ]; then
  MODE="apply"
fi

echo "[fix-cluster] Namespace: $NAMESPACE — Mode: $MODE"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl không tìm thấy. Thoát." >&2; exit 1; }

echo "\n=== Nodes ==="
kubectl get nodes -o wide || true

echo "\n=== Recent events (namespace $NAMESPACE) ==="
kubectl -n "$NAMESPACE" get events --sort-by='.lastTimestamp' | tail -n 80 || true

echo "\n=== Pods summary ==="
kubectl -n "$NAMESPACE" get pods -o wide || true

echo "\n=== Pods in problematic state ==="
kubectl -n "$NAMESPACE" get pods | awk '/Terminating|Error|CrashLoopBackOff|Pending|Unknown/ {print $1, $2, $3, $4}' || true

# Collect logs for cloudflared and frontend
echo "\n=== Cloudflared logs (last 200 lines) ==="
kubectl -n "$NAMESPACE" logs -l app=cloudflared --tail=200 || true

echo "\n=== Frontend logs (last 200 lines) ==="
kubectl -n "$NAMESPACE" logs -l app=frontend --tail=200 || true

# Check secrets
echo "\n=== Secrets check ==="
if kubectl -n "$NAMESPACE" get secret malware-secrets >/dev/null 2>&1; then
  echo "- Secret 'malware-secrets' exists"
else
  echo "- Secret 'malware-secrets' NOT FOUND"
  echo "  -> You can create a random one with:"
  echo "     kubectl -n $NAMESPACE create secret generic malware-secrets --from-literal=SECRET_KEY=\$(openssl rand -hex 32) --from-literal=ANALYZE_AUTH_TOKEN=\$(openssl rand -hex 16)"
fi

if kubectl -n "$NAMESPACE" get secret cloudflared-tunnel-credentials >/dev/null 2>&1; then
  echo "- Secret 'cloudflared-tunnel-credentials' exists"
else
  echo "- Secret 'cloudflared-tunnel-credentials' NOT FOUND"
  echo "  -> If using Named Tunnel, create it from your credentials JSON:" 
  echo "     kubectl -n $NAMESPACE create secret generic cloudflared-tunnel-credentials --from-file=credentials.json=~/.cloudflared/<TUNNEL-ID>.json --dry-run=client -o yaml | kubectl apply -f -"
fi

echo "\n=== Suggest fixes / actions ==="
echo "1) Nếu có Pod 'Terminating' lâu, có thể xóa (soft) để cho ReplicaSet tạo lại:" 
echo "   kubectl -n $NAMESPACE delete pod <pod-name> --grace-period=30"
echo "   Nếu vẫn Terminating lâu, xóa force (dangerous): kubectl -n $NAMESPACE delete pod <pod-name> --grace-period=0 --force"

echo "2) Để khởi lại Deployment (non-destructive): kubectl -n $NAMESPACE rollout restart deployment/<deployment-name>"
echo "   Ví dụ: kubectl -n $NAMESPACE rollout restart deployment/cloudflared"

echo "3) Nếu cần re-apply manifests cloudflared (named/quick):"
if [ -d "$REPO_ROOT/k8s-manifests/cloudflared" ]; then
  echo "   kubectl -n $NAMESPACE apply -f $REPO_ROOT/k8s-manifests/cloudflared/"
else
  echo "   (No local manifests detected at k8s-manifests/cloudflared)"
fi

if [ "$MODE" = "apply" ]; then
  echo "\n[fix-cluster] APPLY mode: attempting safe remediation steps..."

  # Reapply cloudflared manifests if exist
  if [ -d "$REPO_ROOT/k8s-manifests/cloudflared" ]; then
    echo "- Applying cloudflared manifests"
    kubectl -n "$NAMESPACE" apply -f "$REPO_ROOT/k8s-manifests/cloudflared/" || true
  fi

  # Restart common deployments to recover from Unknown/Error
  for d in cloudflared cloudflared-named frontend backend malware-analyzer; do
    if kubectl -n "$NAMESPACE" get deployment "$d" >/dev/null 2>&1; then
      echo "- Restarting deployment/$d"
      kubectl -n "$NAMESPACE" rollout restart deployment/$d || true
    fi
  done

  # Delete long-running Terminating pods cautiously
  TERM_PODS=$(kubectl -n "$NAMESPACE" get pods --no-headers | awk '/Terminating/ {print $1}') || true
  if [ -n "$TERM_PODS" ]; then
    for p in $TERM_PODS; do
      echo "- Deleting terminating pod $p (grace 30s)"
      kubectl -n "$NAMESPACE" delete pod "$p" --grace-period=30 || true
    done
  fi

  echo "- Waiting for rollouts (120s each)"
  for d in cloudflared frontend backend malware-analyzer; do
    if kubectl -n "$NAMESPACE" get deployment "$d" >/dev/null 2>&1; then
      kubectl -n "$NAMESPACE" rollout status deployment/$d --timeout=120s || true
    fi
  done

  echo "\n[fix-cluster] Remediation finished. Check pods and logs again."
fi

echo "\n=== Final pods summary ==="
kubectl -n "$NAMESPACE" get pods -o wide || true

echo "\n=== Tail failing pods logs (if any) ==="
for label in cloudflared frontend; do
  echo "\n--- Logs for pods with label app=$label ---"
  kubectl -n "$NAMESPACE" logs -l app=$label --tail=200 || true
done

echo "\n[fix-cluster] Done. If you want me to run this script (apply) now, reply: Chạy" 
