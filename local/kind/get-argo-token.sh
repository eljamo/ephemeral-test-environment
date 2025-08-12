#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: ./get-argo-token.sh [-n NAMESPACE] [--context KUBE_CONTEXT]
# Defaults:
NS="argo"
CTX=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace) NS="$2"; shift 2;;
    --context) CTX="--context=$2"; shift 2;;
    -h|--help)
      echo "Usage: $0 [-n NAMESPACE] [--context KUBE_CONTEXT]"
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 2;;
  esac
done

# Ensure we can talk to the cluster/namespace
kubectl $CTX get ns "$NS" >/dev/null

# Get a Running pod whose name starts with argo-workflows-server-
SERVER_POD="$(
  kubectl $CTX get pods -n "$NS" -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{"\n"}{end}' \
  | grep -E '^argo-workflows-server-' \
  | head -n 1
)"

if [[ -z "${SERVER_POD:-}" ]]; then
  echo "Error: No running argo-workflows-server pod found in namespace '$NS'." >&2
  echo "Hint: kubectl $CTX get pods -n $NS" >&2
  exit 1
fi

# Execute the argo CLI inside the server pod to get a token
kubectl $CTX -n "$NS" exec "$SERVER_POD" -- argo auth token
