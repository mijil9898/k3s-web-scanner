#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SAMPLE_FILE="${1:-${PWD}/sample.bin}"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found in PATH. Run this in WSL where kubectl is available." >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "curl not found in PATH." >&2; exit 2; }

if [ ! -f "$SAMPLE_FILE" ]; then
  echo "Creating sample file at $SAMPLE_FILE"
  if command -v head >/dev/null 2>&1 && [ -e /dev/urandom ]; then
    head -c 1024 /dev/urandom > "$SAMPLE_FILE"
  else
    printf 'test' > "$SAMPLE_FILE"
  fi
fi

echo "Retrieving ANALYZE_AUTH_TOKEN from namespace 'portfolio'..."
TOKEN=$(kubectl -n portfolio get secret malware-secrets -o jsonpath='{.data.ANALYZE_AUTH_TOKEN}' 2>/dev/null || true)
if [ -z "$TOKEN" ]; then
  echo "Could not read secret 'malware-secrets' in namespace 'portfolio'." >&2
  exit 3
fi
TOKEN=$(echo "$TOKEN" | base64 --decode)

echo "Starting port-forward to svc/malware-analyzer-service -> 127.0.0.1:5000"
kubectl -n portfolio port-forward svc/malware-analyzer-service 5000:5000 >/tmp/ma-port-forward.log 2>&1 &
PF_PID=$!
echo "port-forward PID=$PF_PID"

# wait for service to be ready locally
echo "Waiting for local service to respond on http://127.0.0.1:5000/health (timeout 20s)"
READY=0
for i in $(seq 1 20); do
  if curl -sS --max-time 1 http://127.0.0.1:5000/health >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done

if [ "$READY" -ne 1 ]; then
  echo "Port-forward did not become ready. Check /tmp/ma-port-forward.log for details." >&2
  tail -n +1 /tmp/ma-port-forward.log || true
  kill "$PF_PID" 2>/dev/null || true
  exit 4
fi

echo "Sending file: $SAMPLE_FILE"
OUTFILE=/tmp/ma-analyze-output.json
HTTP_STATUS=000
curl -sS -w "HTTP_STATUS:%{http_code}\n" -H "Authorization: Bearer $TOKEN" -F "file=@${SAMPLE_FILE}" http://127.0.0.1:5000/analyze -o "$OUTFILE" || true

if [ -f "$OUTFILE" ]; then
  sed -n '1,200p' "$OUTFILE"
  grep '^HTTP_STATUS:' "$OUTFILE" >/dev/null 2>&1 || true
fi

echo "Stopping port-forward (PID=$PF_PID)"
kill "$PF_PID" 2>/dev/null || true
wait "$PF_PID" 2>/dev/null || true

echo "Log: /tmp/ma-port-forward.log"
tail -n 200 /tmp/ma-port-forward.log || true

echo "Done"
