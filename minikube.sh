#!/bin/bash

set -e

echo "=============================================="
echo "   Minikube + Docker Setup Script (Ubuntu)   "
echo "=============================================="

# Step 1: Update system
echo "[1/7] Updating system..."
sudo apt update -y && sudo apt upgrade -y

# Step 2: Install required packages
echo "[2/7] Installing dependencies..."
sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release

# Step 3: Install Docker
echo "[3/7] Installing Docker..."
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Step 4: Install kubectl
echo "[4/7] Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Step 5: Install Minikube
echo "[5/7] Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube

# Step 6: Reload group permissions
echo "[6/7] Applying Docker group permissions..."
newgrp docker <<EONG

# Step 7: Start Minikube
echo "[7/7] Starting Minikube using Docker driver..."
minikube start --driver=docker

EONG

echo "=============================================="
echo "     Minikube Installation Completed! 🚀      "
echo "=============================================="

echo "Run 'kubectl get nodes' to verify cluster."
