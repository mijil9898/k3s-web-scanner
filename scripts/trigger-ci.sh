#!/usr/bin/env bash
set -euo pipefail

# trigger-ci.sh
# Trigger a GitHub Actions workflow_dispatch for a workflow file.
# Requires env variables: GITHUB_REPO (owner/repo), GITHUB_TOKEN, WORKFLOW_FILE (filename or id), REF (branch/tag)

if [ -z "${GITHUB_REPO:-}" ] || [ -z "${GITHUB_TOKEN:-}" ] || [ -z "${WORKFLOW_FILE:-}" ]; then
  echo "Usage: set GITHUB_REPO, GITHUB_TOKEN, WORKFLOW_FILE. Optionally REF (default main)." >&2
  exit 2
fi

REF="${REF:-main}"

API="https://api.github.com/repos/${GITHUB_REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches"

echo "Triggering workflow ${WORKFLOW_FILE} on ${GITHUB_REPO} (ref=${REF})"
curl -sS -X POST -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  $API -d "{\"ref\": \"${REF}\"}"

echo "Triggered (response code above)."
