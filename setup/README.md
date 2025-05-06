# Spring PetClinic Kubernetes Deployment

This project deploys the Spring PetClinic application to a local Kubernetes cluster using Terraform and k3d.

## Prerequisites

- Ubuntu 20.04 or later
- sudo privileges
- Internet connection

## Setup Instructions

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd SpringPetClinic
   ```

2. Make the setup script executable and run it:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. After the setup completes, you may need to log out and log back in for Docker group changes to take effect.

4. Navigate to the terraform directory and initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

5. Apply the Terraform configuration:
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

1. If you get permission errors with Docker:
   ```bash
   sudo usermod -aG docker $USER
   ```
   Then log out and log back in.

2. If the cluster isn't accessible:
   ```bash
   k3d cluster list
   kubectl get nodes
   ```

3. If pods aren't starting:
   ```bash
   kubectl get pods -n petclinic
   kubectl describe pod -n petclinic <pod-name>
   ```

## Project Structure

- `setup.sh`: Script to install prerequisites and create the k3d cluster
- `terraform/`: Contains Terraform configuration files
  - `main.tf`: Main Terraform configuration
  - `variables.tf`: Variable definitions 