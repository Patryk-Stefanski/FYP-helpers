#!/bin/bash

set -e

emoji_keycap_1=1️⃣
emoji_keycap_0=0️⃣
emoji_keycap_1=1️⃣
emoji_keycap_2=2️⃣
emoji_keycap_3=3️⃣
emoji_keycap_4=4️⃣
emoji_keycap_5=5️⃣
emoji_keycap_6=6️⃣
emoji_keycap_7=7️⃣
emoji_keycap_8=8️⃣
emoji_keycap_9=9️⃣
emoji_keycap_10=🔟
emoji_hourglass_not_done=⏳
emoji_check_mark_button=✅


# Function to wait for port forwarding to be ready
wait_for_port_forward() {
    local port=$1
    echo "${emoji_hourglass_not_done} Waiting for port forwarding to be ready on port ${port}..."
    while ! nc -z localhost $port; do
        sleep 1
    done
    echo "${emoji_check_mark_button} Port forwarding on port ${port} is ready"
}

# Step 1: Create KinD cluster
echo "${emoji_keycap_1} Step 1: Create KinD cluster"
kind create cluster --config KinD/clusterConfig.yaml

echo "${emoji_hourglass_not_done} Waiting for KinD cluster to be ready"
kubectl wait --for=condition=ready node/local-cluster-control-plane --timeout=5m

# Step 2: Add ArgoCD
echo "${emoji_keycap_2} Step 2: Add ArgoCD"

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "${emoji_hourglass_not_done} Waiting for ArgoCD to be ready"
kubectl wait --all-namespaces --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=180s


# Step 3: Add ingress controllers
echo "${emoji_keycap_3} Step 3: Add ingress controllers"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "${emoji_hourglass_not_done} Waiting for ingress controller to be ready"
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s


# Step 4.1: Check ArgoCD deployment was successful
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=90s


# Step 4: Port forward argo service
echo "${emoji_keycap_4} Step 4: Port forward argo service"

kubectl port-forward -n argocd service/argocd-server 8443:443 &

# Wait for port forward to be ready
while ! nc -z localhost 8443; do
    sleep 1
done

# Step 5: Retrieve argo admin password and decode
echo "${emoji_keycap_5} Step 5: Retrieve argo admin password and decode"

password=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)

# Step 6: Login to ArgoCD with admin user and password
echo "${emoji_keycap_6} Step 6: Login to ArgoCD with admin user and password"

argocd login 127.0.0.1:8443 --username admin --password "${password}" --insecure

# Step 7: Add Github Helm repo and pass in SSH key for access
echo "${emoji_keycap_7} Step 7: Add Github Helm repo and pass in SSH key for access"

argocd repo add git@github.com:Patryk-Stefanski/CovidStatsHelmCharts.git --ssh-private-key-path SSH-keys/argocd_key

# Step8: Deploy application
echo "${emoji_keycap_8} Step 8: Deploy application"

kubectl apply -f argo/application.yaml

# Step 9: Deploy monitoring with kube-prometheus
echo "${emoji_keycap_9} Step 9: Deploy monitoring with kube-prometheus"

kubectl apply --server-side -f Manifests/kube-prometheus/setup
kubectl apply -f Manifests/kube-prometheus/

kubectl wait --namespace monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=grafana --timeout=90s
kubectl wait --namespace monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus --timeout=90s
kubectl wait --namespace monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=alertmanager --timeout=90s


# Step 10: Port forward monitoring services
echo "${emoji_keycap_10} Step 10: Port forward services"

kubectl port-forward -n monitoring svc/grafana 8080:3000 &

while ! nc -z localhost 8080; do
    sleep 1
done

kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090 &

while ! nc -z localhost 9090; do
    sleep 1
done

kubectl port-forward -n monitoring svc/alertmanager-main 9093:9093 -n monitoring & 

while ! nc -z localhost 9093; do
    sleep 1
done


echo "ArgoCD UI available at https://localhost:8443"
echo "ArgoCD admin password: ${password}"
echo "************************************"
echo "Grafana UI available at http://localhost:3000"
echo "Grafa admin password: admin"
echo "************************************"
echo "Prometheus UI available at http://localhost:9090"
echo "************************************"
echo "Alertmanager UI available at http://localhost:9093"
echo "************************************"

echo "Script finished successfully"