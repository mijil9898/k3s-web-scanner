#!/usr/bin/env bash
# scripts/backup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NAMESPACE=${NAMESPACE:-mijil}
BACKUP_DIR="${BACKUP_DIR:-$REPO_ROOT/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql.gz"

mkdir -p "$BACKUP_DIR"
echo '=== Backup PostgreSQL ==='

# Prefer statefulset pod name detection if possible
POD=$(kubectl -n $NAMESPACE get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -z "$POD" ]; then
  POD="postgres-0"
fi

kubectl -n $NAMESPACE exec "$POD" -- \
  pg_dumpall -U mijil | gzip > "$BACKUP_FILE"

echo "Backup lưu tại: $BACKUP_FILE"
ls -lh "$BACKUP_DIR" || true
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete || true
echo 'Xóa backup cũ hơn 7 ngày xong.'
