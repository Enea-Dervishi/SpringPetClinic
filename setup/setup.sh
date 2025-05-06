#!/bin/bash

# Exit on error
set -e

echo "Installing prerequisites..."

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install k3d
echo "Installing k3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Terraform
echo "Installing Terraform..."
sudo snap install terraform --classic

# Create k3d cluster
echo "Creating k3d cluster..."
k3d cluster create petclinic-cluster

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
sleep 10

# Verify cluster is running
echo "Verifying cluster..."
kubectl get nodes

echo "Setup complete! You can now run 'terraform init' and 'terraform apply' in the terraform directory."
echo "Note: You may need to log out and log back in for Docker group changes to take effect." 