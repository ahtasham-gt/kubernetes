#!/bin/bash
set -e

echo "🔹 Updating system..."
apt update && apt upgrade -y

echo "🔹 Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "🔹 Loading kernel modules..."
modprobe overlay
modprobe br_netfilter

cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "🔹 Setting sysctl params..."
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

echo "🔹 Installing dependencies..."
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "🔹 Installing containerd..."
apt install -y containerd

mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

echo "🔹 Adding Kubernetes repo..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
 | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
> /etc/apt/sources.list.d/kubernetes.list

apt update

echo "🔹 Installing kubeadm, kubelet, kubectl..."
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "🔹 Enabling kubelet..."
systemctl enable kubelet

echo "🔹 Initializing Kubernetes MASTER..."
kubeadm init --pod-network-cidr=192.168.0.0/16

echo "🔹 Configuring kubectl for ubuntu user..."
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

echo "🔹 Installing Calico CNI..."
su - ubuntu -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml"

echo "🔹 Allowing pods on control-plane (single-node)..."
su - ubuntu -c "kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true"

echo "✅ Kubernetes MASTER setup complete!"
echo "👉 Run: kubectl get nodes -o wide"
echo "👉 Save join command using: kubeadm token create --print-join-command"
