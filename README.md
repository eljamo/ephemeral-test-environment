# Local Kubernetes Setup

## Getting started locally

### 1. Install docker

Install docker via whatever method you prefer

### 2. Install dependencies

Install these packages via whatever method you prefer or use homebrew

```
brew install kubectl kind cloud-provider-kind kustomize helm argo
```

### 3. Add argo repo using helm

Once you installed helm, add the argo repo

```
helm repo add argo https://argoproj.github.io/argo-helm
```

### 4. Setup cluster if it doesn't exist and start local environment

```
sudo bash ./local/kind/run.sh
```

### 5. Create GitHub API Token Secret

```
kubectl create secret generic github-clone-token -n argo --from-literal=value=<YOUR_CLONE_TOKEN>
```

### Post Setup

### Updating argo-workflows

```
helm repo update argo
```

### Update dependencies using homebrew

```
brew update && brew upgrade kubectl kind cloud-provider-kind kustomize helm argo
```
