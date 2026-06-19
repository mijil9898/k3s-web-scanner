#!/usr/bin/env bash
set -euo pipefail

# Script: scripts/ci-cd.sh
# Purpose: Trigger the `devsecops-audit.yml` workflow via GitHub CLI
# Usage:
#   ./scripts/ci-cd.sh                      # triggers default workflow on main
#   ./scripts/ci-cd.sh --ref develop        # trigger on different ref
#   ./scripts/ci-cd.sh --workflow path.yml  # trigger a different workflow file/name
#   ./scripts/ci-cd.sh --repo owner/repo    # specify repo explicitly

WORKFLOW=".github/workflows/devsecops-audit.yml"
REF="main"
REPO=""

usage(){
  cat <<EOF
Usage: $0 [--workflow PATH|NAME] [--ref REF] [--repo owner/repo]
Examples:
  $0
  $0 --ref feature/xyz
  $0 --workflow "DevSecOps Audit & Visibility"
  $0 --repo mijil9898/k3s-mijil-platform
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workflow)
      WORKFLOW="$2"; shift 2;;
    --ref)
      REF="$2"; shift 2;;
    --repo)
      REPO="$2"; shift 2;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install from https://cli.github.com/" >&2
  exit 2
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated. Run: gh auth login" >&2
  exit 3
fi

if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner) || {
    echo "Failed to detect repository. Provide --repo owner/repo" >&2; exit 4;
  }
fi

echo "Triggering workflow '$WORKFLOW' on $REPO (ref: $REF)"
gh workflow run "$WORKFLOW" --repo "$REPO" --ref "$REF"

echo "Dispatched. To view recent runs:"
echo "  gh run list --repo $REPO"
echo "To follow logs for the latest run (example):"
echo "  RUN_ID=
gh run list --repo $REPO --limit 1 --json databaseId --jq '.[0].databaseId'"
echo "  gh run view \$RUN_ID --repo $REPO --log"

exit 0
