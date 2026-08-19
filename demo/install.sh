#!/bin/bash
set -e

cd "$(dirname "$0")"

KUBE_CONTEXT="kind-devlab"
ARGOCD_APP_FILE="../argocd/demo-dev-application.yaml"
ARGOCD_NAMESPACE="argocd"

echo "Registering Demo App ArgoCD application in ${KUBE_CONTEXT}..."

kubectl --context "${KUBE_CONTEXT}" apply -f "${ARGOCD_APP_FILE}"

kubectl --context "${KUBE_CONTEXT}" -n "${ARGOCD_NAMESPACE}" annotate application demo-dev \
  argocd.argoproj.io/refresh=hard \
  --overwrite

echo "Demo App ArgoCD application registered successfully."
echo "Check status with: kubectl --context ${KUBE_CONTEXT} -n argocd get application demo-dev"
echo "Check pods with:   kubectl --context ${KUBE_CONTEXT} get pods -l app=demo-app"
echo "Access app:        http://localhost:30088"
