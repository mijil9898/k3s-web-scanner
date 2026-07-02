#!/usr/bin/env bash
set -euo pipefail

# git-commit-and-push.sh
# Chuẩn bị tất cả thay đổi, commit với thông điệp được cung cấp, và push lên nhánh remote.
# Có thể kích hoạt CI bằng cách gọi trigger-ci.sh (nếu đối số thứ hai là 'ci').

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

MSG="${1:-chore: update repository}" 
BRANCH="${2:-$(git rev-parse --abbrev-ref HEAD)}"

echo "[git-commit-and-push] Branch: $BRANCH"
git add -A
if git commit -m "$MSG"; then
  echo "[git-commit-and-push] Committed: $MSG"
else
  echo "[git-commit-and-push] No changes to commit"
fi

echo "[git-commit-and-push] Pushing to origin/$BRANCH"
git push origin "$BRANCH"

if [ "${3:-}" = "ci" ]; then
  if [ -x "$REPO_ROOT/scripts/trigger-ci.sh" ]; then
    echo "[git-commit-and-push] Triggering CI via scripts/trigger-ci.sh"
    "$REPO_ROOT/scripts/trigger-ci.sh" || echo "[git-commit-and-push] trigger-ci.sh failed"
  else
    echo "[git-commit-and-push] trigger-ci.sh not found or not executable"
  fi
fi

echo "Done."
