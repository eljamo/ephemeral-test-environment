#!/usr/bin/env bash

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

# Set up trap for cleanup on exit
trap cleanup EXIT INT TERM

# Handle sudo authentication
sudo -v || { echo "Authentication failed"; exit 1; }

# Start the background processes
sudo cloud-provider-kind > /dev/null 2>&1 &
CPK_PID=$!

kubectl -n argo port-forward deployment.apps/argo-workflows-server 2746:2746 > /dev/null 2>&1 &

printf "Starting devenv"

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
echo "========================================="
echo "Devenv Details"
echo "========================================="
printf "%-30s %s\n" "cloud-provider-kind PID:" "$CPK_PID"
echo ""

docker ps --format "{{.Names}}" | while read CONTAINER; do
    if [[ "$CONTAINER" =~ ^kindccm-[a-z0-9]+$ ]] || \
       [[ "$CONTAINER" == "devenv-worker" ]] || \
       [[ "$CONTAINER" == "devenv-control-plane" ]]; then

        IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER" 2>/dev/null)

        if [ -n "$IP" ]; then
            printf "%-30s %s\n" "${CONTAINER} IP:" "${IP}"
        else
            printf "%-30s %s\n" "${CONTAINER} IP:" "<not available>"
        fi
    fi
done

echo ""

printf "%-30s %s\n" "argo-workflows URL:" "http://localhost:2746"
printf "%-30s %s\n" "argo-workflows login JWT:" "$(${SCRIPT_DIR}/get-argo-token.sh -n argo 2>/dev/null || echo "<not available>")"

echo ""
echo "========================================="
echo "Options:"
echo "  - Press Ctrl+C to exit"

while true; do
    # Check if background processes are still running
    if ! ps -p $CPK_PID > /dev/null 2>&1; then
        echo ""
        echo "cloud-provider-kind has been stopped"
        exit 1
    fi
done
