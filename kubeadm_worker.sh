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

echo "🔹 Installing kubeadm & kubelet..."
apt install -y kubeadm kubelet kubectl
apt-mark hold kubeadm kubelet kubectl

systemctl enable kubelet

echo "✅ Worker node setup completed!"
echo "👉 Now run the kubeadm join command from the MASTER node"
