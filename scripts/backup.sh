#!/bin/bash
# scripts/backup.sh
set -euo pipefail

NAMESPACE='portfolio'
BACKUP_DIR='./backups'
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql.gz"

mkdir -p $BACKUP_DIR
echo '=== Backup PostgreSQL ==='
kubectl exec -n $NAMESPACE postgres-0 -- \
  pg_dumpall -U portfolio | gzip > $BACKUP_FILE

echo "Backup lưu tại: $BACKUP_FILE"
ls -lh $BACKUP_DIR
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
echo 'Xóa backup cũ hơn 7 ngày xong.'
