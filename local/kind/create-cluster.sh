#!/usr/bin/env bash

echo "Creating new kind cluster"
echo ""

kind create cluster --name dev --config ./config.yaml

echo ""
echo "Installing Ingress NGINX"
echo ""

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo ""

until kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller 2>/dev/null | grep -q .; do
  sleep 2
done

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo ""
echo "Installng argo-workflows"
echo ""

helm install argo-workflows argo/argo-workflows -n argo --create-namespace --wait

echo ""
echo "Creating roles for service accounts"
echo ""

kubectl create clusterrolebinding argo-admin-server --clusterrole=cluster-admin --serviceaccount=argo:argo-server -n argo
kubectl create clusterrolebinding argo-admin-default --clusterrole=cluster-admin --serviceaccount=argo:default -n argo

echo ""
echo "Fetching argo auth token"
echo ""

echo "$(./get-argo-token.sh -n argo 2>/dev/null)"