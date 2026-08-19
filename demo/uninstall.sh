#!/bin/bash
set -e

cd "$(dirname "$0")"

KUBE_CONTEXT="kind-devlab"
ARGOCD_APP_FILE="../argocd/demo-dev-application.yaml"

echo "Deleting Demo App ArgoCD application..."
kubectl --context "${KUBE_CONTEXT}" delete -f "${ARGOCD_APP_FILE}" || true

echo "Demo App uninstalled."
