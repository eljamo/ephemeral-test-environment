#!/usr/bin/env bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kind create cluster --name devenv --config "${SCRIPT_DIR}/config.yaml"

echo ""
printf "Installing ingress-nginx"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml > /dev/null

while ! kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=2s > /dev/null 2>&1; do
  printf "."
  sleep 1
done

echo ""
printf "Installing argo-workflows"

helm install argo-workflows argo/argo-workflows -n argo --create-namespace --wait > /dev/null 2>&1 &
HELM_PID=$!

while ps -p $HELM_PID > /dev/null 2>&1; do
  printf "."
  sleep 1
done

wait $HELM_PID

echo ""
printf "Creating roles for service accounts"

kubectl create clusterrolebinding argo-admin-server --clusterrole=cluster-admin --serviceaccount=argo:argo-server -n argo > /dev/null
kubectl create clusterrolebinding argo-admin-default --clusterrole=cluster-admin --serviceaccount=argo:default -n argo > /dev/null

printf "."
echo ""
