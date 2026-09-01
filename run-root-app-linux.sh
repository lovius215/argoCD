#!/bin/bash
set -eo pipefail

# 切換至腳本所在目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_APP_FILE="${SCRIPT_DIR}/root-app.yaml"

echo "============================================================"
echo "🚀 [Linux] 部署 / 執行 Argo CD Root Application (App of Apps)"
echo "============================================================"

# 1. 檢查 kubectl 是否存在
if ! command -v kubectl &> /dev/null; then
  echo "❌ 錯誤: 未找到 kubectl 指令，請先安裝 kubectl (Linux)。"
  echo "   安裝參考: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
  exit 1
fi

# 2. 檢查 Kubernetes 連線狀態
echo ">> 檢查 Kubernetes 叢集連線..."
if ! kubectl cluster-info &> /dev/null; then
  echo "❌ 錯誤: 無法連線至 Kubernetes 叢集，請確認 K8s 叢集 (如 kind/k3d/minikube/k8s) 是否已啟動。"
  exit 1
fi
echo "✅ K8s 叢集連線正常"

# 3. 檢查 argocd namespace 是否存在
if ! kubectl get namespace argocd &> /dev/null; then
  echo "⚠️  未偵測到 argocd namespace，正在建立..."
  kubectl create namespace argocd
fi

# 4. 檢查 root-app.yaml 檔案
if [ ! -f "${ROOT_APP_FILE}" ]; then
  echo "❌ 錯誤: 找不到 ${ROOT_APP_FILE}"
  exit 1
fi

# 5. 套用 root-app.yaml
echo ""
echo ">> 套用 ${ROOT_APP_FILE} 到 argocd namespace..."
kubectl apply -f "${ROOT_APP_FILE}"

echo ""
echo "============================================================"
echo "✅ root-app 部署成功！"
echo "============================================================"
echo ""
echo "📋 目前 ArgoCD Application 狀態："
kubectl get applications -n argocd -o wide 2>/dev/null || kubectl get application -n argocd

echo ""
echo "💡 提示："
echo "• 若有安裝 ArgoCD CLI，可使用指令查看同步狀態: argocd app get root-app"
echo "• 或至 ArgoCD UI 查看 App-of-Apps 拓撲結構"
echo "============================================================"
