#!/bin/bash

set -e


# Step 1: Create KinD cluster
echo "Step 1: Create KinD cluster"
kind create cluster --config KinD/clusterConfig.yaml

echo "Waiting for KinD cluster to be ready"
kubectl wait --for=condition=ready node/local-cluster-control-plane --timeout=5m


# Step 2: Add ArgoCD
echo "Step 2: Add ArgoCD"

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD to be ready"
kubectl wait --all-namespaces --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=90s


# Step 3: Add ingress controllers
echo "Step 3: Add ingress controllers"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress controller to be ready"
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s


# Step 4.1: Check ArgoCD deplouyment was successful
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=90s


# Step 4: Port forward argo service
echo "Step 4: Port forward argo service"

kubectl port-forward -n argocd service/argocd-server 8443:443 &>/dev/null &

# Wait for port forward to be ready
while ! nc -z localhost 8443; do
    sleep 1
done

# Step 5: Retrieve argo admin password and decode
echo "Step 5: Retrieve argo admin password and decode"

password=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)

# Step 6: Login to ArgoCD with admin user and password
echo "Step 6: Login to ArgoCD with admin user and password"

argocd login 127.0.0.1:8443 --username admin --password "${password}" --insecure

# Step 7: Add Github Helm repo and pass in SSH key for access
echo "Step 7: Add Github Helm repo and pass in SSH key for access"

argocd repo add git@github.com:Patryk-Stefanski/CovidStatsHelmCharts.git --ssh-private-key-path SSH-keys/argocd_key

# Step8: Deploy application
echo "Step 8: Deploy application"

kubectl apply -f argo/application.yaml

echo "ArgoCD UI available at https://localhost:8443"
echo "ArgoCD admin password: ${password}"
echo "Script finished successfully"

