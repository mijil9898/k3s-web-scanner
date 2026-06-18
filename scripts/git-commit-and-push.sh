#!/usr/bin/env bash
set -euo pipefail

# git-commit-and-push.sh
# Stages all changes, commits with provided message, and pushes to the remote branch.
# Optionally triggers CI by calling trigger-ci.sh (if second arg is 'ci').

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
