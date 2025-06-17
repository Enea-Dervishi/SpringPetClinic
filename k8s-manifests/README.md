# Kubernetes Manifests for GitOps

This directory contains Kubernetes manifests for deploying the PetClinic application using ArgoCD GitOps workflow.

## Structure

```
k8s-manifests/
├── environments/
│   ├── dev/          # Development environment manifests
│   ├── staging/      # Staging environment manifests
│   └── prod/         # Production environment manifests
└── base/             # Base manifests (if using Kustomize overlays)
```

## How it Works

1. **Jenkins Pipeline** builds and pushes Docker images
2. **Terraform** generates environment-specific Kubernetes manifests
3. **Jenkins** commits and pushes manifest changes to Git
4. **ArgoCD** detects changes and syncs to Kubernetes cluster

## Generated Files

Each environment directory contains:
- `deployment.yaml` - Application deployment
- `service.yaml` - Service configuration
- `namespace.yaml` - Namespace definition
- `ghcr-secret.yaml` - GitHub Container Registry credentials
- `kustomization.yaml` - Kustomize configuration

## ArgoCD Applications

ArgoCD applications are configured to monitor:
- **Repository**: https://github.com/enea-dervishi/SpringPetClinic.git
- **Path**: `k8s-manifests/environments/{environment}`
- **Target**: Respective environment namespace

## Manual Sync

To manually sync an application:
```bash
argocd app sync petclinic-dev
argocd app wait petclinic-dev
``` 