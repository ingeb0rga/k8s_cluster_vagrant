#!/bin/bash
#
# Setup for Node servers

# set -euxo pipefail

# Load the necessary modules for Containerd:
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup the required kernel parameters:
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# Add Docker official GPG key:
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Set up kubernetes repository:
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    apt-transport-https \
    lsb-release \
    jq

# Install containerd and the latest versions of kubernetes components
sudo apt-get install -y containerd.io kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl containerd.io

# Add vagrant user to docker group
sudo usermod -aG docker vagrant

# Enable CRI plugin.
sudo sed -i 's/disabled_plugins/\#disabled_plugins/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Disable swap in order for the kubelet to work properly.
sudo swapoff -a
sudo cp /etc/fstab /etc/fstab.bak
sudo sed -i 's/\/swap/\#\/swap/' /etc/fstab

# Join current node to kubernetes cluster
config_path="/vagrant/configs/"

mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/config
sudo chown vagrant:vagrant -R /home/vagrant/.kube/

sudo /bin/bash $config_path/join.sh -v
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker

# Install bash auto-completion
sudo apt-get install bash-completion
kubectl completion bash &>/dev/null
echo "source /usr/share/bash-completion/bash_completion" | sudo tee -a ~/.bashrc
echo "source <(kubectl completion bash)" | sudo tee -a ~/.bashrc
echo 'alias k=kubectl' | sudo tee -a ~/.bashrc
echo 'complete -o default -F __start_kubectl k' | sudo tee -a ~/.bashrc