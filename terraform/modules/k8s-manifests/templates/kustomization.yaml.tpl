apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - ghcr-secret.yaml
  - deployment.yaml
  - service.yaml

commonLabels:
  app: ${app_name} 