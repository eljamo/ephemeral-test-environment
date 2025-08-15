#!/usr/bin/env bash

if [ -z "$SUDO_USER" ]; then
    echo "This script must be run with sudo"
    exit 1
fi

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if devenv kind cluster exists
if ! kind get clusters | grep -q devenv; then  
  echo ""
  "${SCRIPT_DIR}/create-cluster.sh"
fi

# cloud-provider-kind pid
CPK_PID=""

# Function to cleanup on exit
cleanup() {
    if [ -n "$CPK_PID" ] && ps -p $CPK_PID > /dev/null 2>&1; then
        echo ""
        echo "Stopping cloud-provider-kind..."
        sudo kill $CPK_PID 2>/dev/null
        # Wait for process to actually stop
        sleep 1
        if ps -p $CPK_PID > /dev/null 2>&1; then
            echo "Process still running, forcing kill..."
            sudo kill -9 $CPK_PID 2>/dev/null
        fi
        echo "cloud-provider-kind has been stopped."
    fi

    exit 0
}

# Function to keep sudo alive
sudo_keepalive() {
    while true; do
        sleep 60  # Refresh every minute
        sudo -v
    done
}

# Set up trap for cleanup on exit
trap cleanup EXIT INT TERM

EXPECTED_CONTEXT="kind-devenv"
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null)

if [ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]; then
    echo "Error: Wrong Kubernetes context!"
    echo "  Expected: $EXPECTED_CONTEXT"
    echo "  Current:  $CURRENT_CONTEXT"
    echo ""
    echo "Switch to the correct context using:"
    echo "  kubectl config use-context $EXPECTED_CONTEXT"
    exit 1
fi

printf "Starting devenv"

# Start the background processes
sudo cloud-provider-kind > /dev/null 2>&1 &
CPK_PID=$!

sudo_keepalive &

kubectl -n argo port-forward deployment.apps/argo-workflows-server 2746:2746 > /dev/null 2>&1 &

# Check if cloud-provider-kind is running
if ! ps -p $CPK_PID > /dev/null; then
    echo ""
    echo "Error: cloud-provider-kind failed to start"
    exit 1
fi

# Wait for Argo to be accessible
while ! curl -s http://localhost:2746 > /dev/null 2>&1; do
    printf "."
    sleep 1
done

echo ""
echo ""
echo "========================================="
echo "Devenv Details:"
echo "========================================="
printf "%-30s %s\n" "cloud-provider-kind PID:" "$CPK_PID"
echo ""

(kubectl get services --all-namespaces -o json | jq -r '.items[] | select(.status.loadBalancer.ingress[0].ip != null) | "\(.metadata.name) \(.status.loadBalancer.ingress[0].ip)"'; kubectl get services --all-namespaces -o json | jq -r '.items[] | select(.spec.externalIPs[0] != null) | "\(.metadata.name) \(.spec.externalIPs[0])"') | while read SERVICE IP; do printf "%-30s %s\n" "${SERVICE} IP:" "${IP}"; done

echo ""

printf "%-30s %s\n" "argo-workflows URL:" "http://localhost:2746"
printf "%-30s %s\n" "argo-workflows login JWT:" "$(${SCRIPT_DIR}/get-argo-token.sh -n argo 2>/dev/null || echo "<not available>")"

echo ""
echo "========================================="
echo "Options:"
echo "========================================="
echo "  * Press Ctrl+C to exit"

while true; do
    # Check if background processes are still running
    if ! ps -p $CPK_PID > /dev/null 2>&1; then
        echo ""
        echo "cloud-provider-kind has been stopped"
        exit 1
    fi

    # Update hosts file (will only print if it actually updates)
    "${SCRIPT_DIR}/update-etc-hosts.sh"

    # Wait 1 second before next iteration
    sleep 1
done