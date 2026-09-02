#!/bin/bash
set -eo pipefail

# 切換至腳本所在目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_APP_FILE="${SCRIPT_DIR}/root-app.yaml"
ENV_FILE="${SCRIPT_DIR}/.env"

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

# 4. 讀取 .env 並配置 Git Repository Secret
if [ -f "${ENV_FILE}" ]; then
  # 載入 .env 變數
  set -a
  # 忽略註解與空行
  # shellcheck disable=SC1090
  source <(grep -v '^#' "${ENV_FILE}" | sed -e 's/\r$//' | grep -v '^$')
  set +a
fi

GITHUB_USERNAME="${GITHUB_USERNAME:-lovius215}"
GITHUB_REPO_URL="${GITHUB_REPO_URL:-https://github.com/lovius215/k8s.git}"

if [ -n "${GITHUB_TOKEN}" ] && [ "${GITHUB_TOKEN}" != "your_github_token_here" ]; then
  echo ">> 正在從 .env 設定 Argo CD 儲存庫憑證 (${GITHUB_REPO_URL})..."
  cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: v1
kind: Secret
metadata:
  name: github-k8s-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: ${GITHUB_REPO_URL}
  username: ${GITHUB_USERNAME}
  password: ${GITHUB_TOKEN}
EOF
  echo "✅ Argo CD Git 儲存庫憑證 (github-k8s-repo) 設定完成"
else
  echo "ℹ️  提示: 未在 .env 偵測到有效的 GITHUB_TOKEN。若為私有儲存庫，請在 .env 中填寫 GITHUB_TOKEN"
fi

# 5. 檢查 root-app.yaml 檔案
if [ ! -f "${ROOT_APP_FILE}" ]; then
  echo "❌ 錯誤: 找不到 ${ROOT_APP_FILE}"
  exit 1
fi

# 6. 套用 root-app.yaml
echo ""
echo ">> 套用 ${ROOT_APP_FILE} 到 argocd namespace..."
kubectl apply -f "${ROOT_APP_FILE}"

# 7. 觸發 ArgoCD Application 重新整理
echo ">> 觸發 ArgoCD Application 重新整理..."
kubectl annotate applications --all -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null > /dev/null || true

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
