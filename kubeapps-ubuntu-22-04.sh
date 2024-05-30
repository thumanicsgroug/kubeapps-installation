#!/bin/bash
 sudo apt-get update -y
 sudo apt-get upgrade -y

# Install MicroK8s
echo "Installing MicroK8s..."
sudo snap install microk8s --classic

# Wait for MicroK8s to be ready
echo "Waiting for MicroK8s to be ready..."
sudo microk8s status --wait-ready

# Enable required MicroK8s addons
echo "Enabling MicroK8s addons..."
sudo microk8s enable dns storage

# Install Helm
echo "Installing Helm..."
sudo snap install helm --classic

echo "MicroK8s and Helm installation completed."

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
 microk8s kubectl create namespace kubeapps
 microk8s helm install kubeapps --namespace kubeapps bitnami/kubeapps --set useHelm3=true

 microk8s kubectl create --namespace default serviceaccount kubeapps-operator

 microk8s kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator

cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kubeapps-operator-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: kubeapps-operator
type: kubernetes.io/service-account-token
EOF

microk8s kubectl get --namespace default secret kubeapps-operator-token -o go-template='{{.data.token | base64decode}}'

microk8s kubectl port-forward -n kubeapps svc/kubeapps 8080:80 --address 0.0.0.0