# Spring PetClinic Kubernetes Deployment

This project deploys the Spring PetClinic application to a local Kubernetes cluster using Terraform and k3d.

## Important Notes

- The application runs on port 8081 to avoid conflicts with Jenkins (which typically uses port 8080)
- If you need to use a different port, you can modify the `container_port` and `SERVER_PORT` in `terraform/main.tf`

## Setup Stages

### Stage 1: Repository Setup
1. Clone this repository:
   ```bash
   # Using HTTPS (recommended for first-time setup)
   git clone https://github.com/Enea-Dervishi/SpringPetClinic.git
   cd SpringPetClinic

   # OR using SSH (if you have SSH keys configured)
   git clone git@github.com:Enea-Dervishi/SpringPetClinic.git
   cd SpringPetClinic
   ```

### Stage 2: Environment Setup
1. Make the setup script executable and run it:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. After the setup completes, you may need to log out and log back in for Docker group changes to take effect.

### Stage 3: Deployment
1. Navigate to the terraform directory and initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

2. Apply the Terraform configuration:
   ```bash
   terraform apply
   ```
   When prompted for the environment name, enter `dev`.

## Accessing the Application

Once the deployment is complete, the Spring PetClinic application will be available at:
```
http://localhost:<NODE_PORT>
```

To find the NodePort, run:
```bash
kubectl get svc -n petclinic
```

## Cleaning Up

To remove the k3d cluster:
```bash
k3d cluster delete petclinic-cluster
```

To remove all resources created by Terraform:
```bash
cd terraform
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Docker Permission Issues**
   ```bash
   sudo usermod -aG docker $USER
   ```
   Then log out and log back in.

2. **Cluster Access Issues**
   ```bash
   k3d cluster list
   kubectl get nodes
   ```

3. **Pod Issues**
   ```bash
   kubectl get pods -n petclinic
   kubectl describe pod -n petclinic <pod-name>
   ```

4. **GitHub Access Issues**
   - If using HTTPS: Make sure you have your GitHub credentials
   - If using SSH: Ensure your SSH key is added to GitHub
   - To test SSH connection: `ssh -T git@github.com`

## Project Structure

- `setup.sh`: Script to install prerequisites and create the k3d cluster
- `terraform/`: Contains Terraform configuration files
  - `main.tf`: Main Terraform configuration
  - `variables.tf`: Variable definitions

## Prerequisites

- Ubuntu 20.04 or later
- sudo privileges
- Internet connection
- Git
- Docker (will be installed by setup script)
- At least 2GB of free RAM
- At least 10GB of free disk space 