# Local Kubernetes Setup

## 1. Install Deps

```
brew install kubectl kind cloud-provider-kind kustomize helm argo

helm repo add argo https://argoproj.github.io/argo-helm
```

## 2. Setup cluster and run background processes

```
bash ./local/kind/run.sh
```
