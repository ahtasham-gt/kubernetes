#!/bin/bash

set -e

echo "🔹 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "🔹 Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "🔹 Loading kernel modules..."
sudo modprobe overlay
sudo modprobe br_netfilter

echo "🔹 Persisting kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "🔹 Setting sysctl params for Kubernetes..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                = 1
EOF

echo "🔹 Applying sysctl params..."
sudo sysctl --system

echo "🔹 Installing required packages..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "🔹 Installing containerd..."
sudo apt install -y containerd

echo "🔹 Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

echo "🔹 Adding Kubernetes GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "🔹 Adding Kubernetes repository..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "🔹 Installing kubelet, kubeadm, kubectl..."
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

echo "🔹 Holding Kubernetes packages..."
sudo apt-mark hold kubelet kubeadm kubectl

echo "✅ kubeadm installation completed successfully!"
echo "👉 Reboot the system, then run: sudo kubeadm init"
