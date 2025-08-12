#!/usr/bin/env bash

echo "Creating new kind cluster"
echo ""

kind create cluster --config ./config.yaml --name dev

echo ""
echo "Appling Ingress NGINX"
echo ""

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo ""
echo "Installng argo-workflows in namespace argo"
echo ""

helm install argo-workflows argo/argo-workflows -n argo --create-namespace --wait

# echo ""
# echo "Applying Argo Workflows Ingress"
# echo ""

# kubectl apply -f ./argo-workflow-ingress.yaml

echo ""
echo "Creating roles for service accounts"
echo ""

kubectl create clusterrolebinding argo-admin-server --clusterrole=cluster-admin --serviceaccount=argo:argo-server -n argo
kubectl create clusterrolebinding argo-admin-default --clusterrole=cluster-admin --serviceaccount=argo:default -n argo

echo ""
echo "Fetching argo auth token"
echo ""

echo "$(./get-argo-token.sh -n argo 2>/dev/null)"