#!/bin/bash
#
# Setup for Control Plane servers

sudo chown -R vagrant:vagrant /vagrant

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

# Install the latest version of Docker Engine, containerd, and Docker Compose
sudo apt-get install -y containerd.io docker-ce docker-ce-cli docker-compose-plugin
sudo apt-mark hold containerd.io

# Enable CRI plugin.
sudo sed -i 's/disabled_plugins/\#disabled_plugins/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Configure containerd
# sudo mkdir -p /etc/containerd
# containerd config default | sudo tee /etc/containerd/config.toml
# sudo systemctl restart containerd

# Install the latest versions of kubernetes components
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Disable swap in order for the kubelet to work properly.
sudo swapoff -a
sudo cp /etc/fstab /etc/fstab.bak
sudo sed -i 's/\/swap/\#\/swap/' /etc/fstab

# Start kubernetes cluster
sudo kubeadm init --apiserver-advertise-address="$(hostname -I | awk '{print $2}')" --cri-socket=unix:///var/run/containerd/containerd.sock --pod-network-cidr=10.244.0.0/16

# Copy cluster config into ~/.kube directory
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant -R /home/vagrant/.kube/

# Create cluster token
config_path="/vagrant/configs/"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

sudo cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh
kubeadm token create --print-join-command > $config_path/join.sh

# Install Flunnel Network Plugin
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml

# Install bash auto-completion
sudo apt-get install bash-completion
kubectl completion bash &>/dev/null
echo "source /usr/share/bash-completion/bash_completion" | sudo tee -a ~/.bashrc
echo "source <(kubectl completion bash)" | sudo tee -a ~/.bashrc
echo 'alias k=kubectl' | sudo tee -a ~/.bashrc
echo 'complete -o default -F __start_kubectl k' | sudo tee -a ~/.bashrc

# Check if Flunnel pod is created and running so it's possible to continue provisioning workers
until [ "$(kubectl get pods -n kube-flannel | tail -1 | awk '{print $3}')" = "Running" ]; do
  echo "============ flunnel deployment not ready yet ============"; sleep 3;
done
