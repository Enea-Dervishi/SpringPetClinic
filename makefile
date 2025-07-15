# Makefile for managing Kubernetes resources in k8s folder

K8S_BASE=k8s/base
K8S_OVERLAYS=k8s/overlays
SECRET_NAME ?= ghcr-secret

.PHONY: apply-dev apply-staging apply-prod apply-base delete-dev delete-staging delete-prod delete-base create-namespace-dev create-namespace-staging create-namespace-prod get-secret-dev expose-argo

apply-dev:
	kubectl apply -k $(K8S_OVERLAYS)/dev

apply-staging:
	kubectl apply -k $(K8S_OVERLAYS)/staging

apply-prod:
	kubectl apply -k $(K8S_OVERLAYS)/prod

apply-base:
	kubectl apply -k $(K8S_BASE)

delete-dev:
	kubectl delete -k $(K8S_OVERLAYS)/dev

delete-staging:
	kubectl delete -k $(K8S_OVERLAYS)/staging

delete-prod:
	kubectl delete -k $(K8S_OVERLAYS)/prod

delete-base:
	kubectl delete -k $(K8S_BASE)

create-namespace-dev:
	kubectl apply -f $(K8S_BASE)/namespace.yaml

create-namespace-staging:
	kubectl apply -f $(K8S_BASE)/namespace.yaml

create-namespace-prod:
	kubectl apply -f $(K8S_BASE)/namespace.yaml

get-secret-dev:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

expose-argo:
  kubectl port-forward -n argocd svc/argocd-server 8080:80



