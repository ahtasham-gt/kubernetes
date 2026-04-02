#!/bin/bash

set -e

echo "🔄 Updating system..."
sudo apt update -y && sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release

# -----------------------------
# Install Docker
# -----------------------------
echo "🐳 Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Add ubuntu user to docker group
sudo usermod -aG docker $USER

# -----------------------------
# Install kubectl
# -----------------------------
echo "☸️ Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# -----------------------------
# Install Minikube
# -----------------------------
echo "🚀 Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# -----------------------------
# Start Minikube (optimized for t3.small)
# -----------------------------
echo "⚙️ Starting Minikube..."
minikube start \
  --driver=docker \
  --memory=1800mb \
  --cpus=2

# -----------------------------
# Install Helm
# -----------------------------
echo "📦 Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -----------------------------
# Add Prometheus & Grafana repo
# -----------------------------
echo "📊 Installing Prometheus & Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack (includes Grafana)
helm install monitoring prometheus-community/kube-prometheus-stack

# -----------------------------
# Access info
# -----------------------------
echo "🎉 Setup Completed!"

echo "👉 Get Grafana password:"
echo "kubectl get secret monitoring-grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode && echo"

echo "👉 Access Grafana:"
echo "kubectl port-forward svc/monitoring-grafana 3000:80"

echo "👉 Access Prometheus:"
echo "kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090"
