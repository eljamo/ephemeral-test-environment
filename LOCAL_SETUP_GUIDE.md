# Local Kubernetes Setup

## 0. Install Deps

```
brew install kubectl kind kustomize helm argo

helm repo add argo https://argoproj.github.io/argo-helm
```

## 1. Create Cluster

```
kind create cluster
```

## 2. Add NGINX Ingress Controller to cluster

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

## 3. Add argo-workflows to cluster

Kind of annoying we need to use helm here instead of the `kubectl` but seems like `helm` install has some magic sauce which just works versus. the normal install so adds a `helm` dependency until I can figure it out.

```
helm install argo-workflows argo/argo-workflows -n argo --create-namespace
```

## 4. Crete Service Accounts and Roles

Shouldn't set it up like this in production but fine for local.

```
kubectl create clusterrolebinding argo-admin-server --clusterrole=cluster-admin --serviceaccount=argo:argo-server -n argo
kubectl create clusterrolebinding argo-admin-default --clusterrole=cluster-admin --serviceaccount=argo:default -n argo
```

## 5. Port Forward argo-workflows UI

```
kubectl -n argo port-forward deployment.apps/argo-workflows-server 2746:2746
```

## 6. Go to UI

Go to the UI by going to `http://localhost:2746` in your browser

## 7. Get login auth token

Get the list of pods

```
kubectl get pods -n argo
```

It will look like this...

```
NAME                                                 READY   STATUS    RESTARTS   AGE
argo-workflows-server-8676c597d9-2wzmj               1/1     Running   0          2m8s
argo-workflows-workflow-controller-f9f8c875d-2zmn2   1/1     Running   0          2m8s
```

Using the podname of the `argo-workflows-server` fetch the auth token like so

```
kubectl -n argo exec argo-workflows-server-8676c597d9-kkfx5 -- argo auth token
```

Copy and paste the output into the text box of the UI and login

## 8. Add git service token

```
kubectl create secret generic github-token -n argo --from-literal=token=<TOKEN>
```
