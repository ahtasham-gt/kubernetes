#!/bin/bash
# for t3.medium aws
set -e

echo "🔄 Updating system..."
sudo apt update -y && sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release software-properties-common

# -----------------------------
# Install Docker
# -----------------------------
echo "🐳 Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER

# -----------------------------
# Install kubectl
# -----------------------------
echo "☸️ Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# -----------------------------
# Install Minikube
# -----------------------------
echo "🚀 Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# -----------------------------
# Start Minikube (optimized for t3.medium)
# -----------------------------
echo "⚙️ Starting Minikube..."
minikube start \
  --driver=docker \
  --cpus=2 \
  --memory=3000mb

# -----------------------------
# Install Helm
# -----------------------------
echo "📦 Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -----------------------------
# Add Helm repos
# -----------------------------
echo "📊 Adding Helm repos..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# -----------------------------
# Create namespace
# -----------------------------
kubectl create namespace monitoring || true

# -----------------------------
# Install full monitoring stack
# -----------------------------
echo "📈 Installing Prometheus + Grafana (kube-prometheus-stack)..."
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring

# -----------------------------
# Wait for pods
# -----------------------------
echo "⏳ Waiting for pods to be ready..."
sleep 60

kubectl get pods -n monitoring

# -----------------------------
# Access Info
# -----------------------------
echo "🎉 Setup Completed!"

echo ""
echo "👉 Get Grafana Password:"
echo "kubectl get secret -n monitoring monitoring-grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode && echo"

echo ""
echo "👉 Access Grafana:"
echo "kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"

echo ""
echo "👉 Access Prometheus:"
echo "kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090"

echo ""
echo "🌐 Then open in browser:"
echo "http://<EC2-PUBLIC-IP>:3000 (Grafana)"
echo "http://<EC2-PUBLIC-IP>:9090 (Prometheus)"
