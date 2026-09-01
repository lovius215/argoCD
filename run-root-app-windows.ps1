# PowerShell Script: run-root-app-windows.ps1
# Requires PowerShell 5.1+ or PowerShell Core (pwsh)

$ErrorActionPreference = "Stop"

# 取得腳本所在目錄
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootAppFile = Join-Path $ScriptDir "root-app.yaml"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 [Windows PowerShell] 部署 / 執行 Argo CD Root Application (App of Apps)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 檢查 kubectl 是否存在
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 錯誤: 未找到 kubectl 指令，請先安裝 kubectl (Windows)。" -ForegroundColor Red
    Write-Host "   可使用 winget 或 choco 安裝: winget install Kubernetes.kubectl" -ForegroundColor Yellow
    exit 1
}

# 2. 檢查 Kubernetes 連線狀態
Write-Host ">> 檢查 Kubernetes 叢集連線..." -ForegroundColor Yellow
$clusterInfo = kubectl cluster-info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 錯誤: 無法連線至 Kubernetes 叢集，請確認 K8s 叢集 (Docker Desktop / minikube / kind) 是否已啟動。" -ForegroundColor Red
    exit 1
}
Write-Host "✅ K8s 叢集連線正常" -ForegroundColor Green

# 3. 檢查 argocd namespace 是否存在
$nsCheck = kubectl get namespace argocd 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  未偵測到 argocd namespace，正在建立..." -ForegroundColor Yellow
    kubectl create namespace argocd
}

# 4. 檢查 root-app.yaml 檔案
if (-not (Test-Path -Path $RootAppFile)) {
    Write-Host "❌ 錯誤: 找不到 $RootAppFile" -ForegroundColor Red
    exit 1
}

# 5. 套用 root-app.yaml
Write-Host ""
Write-Host ">> 套用 $RootAppFile 到 argocd namespace..." -ForegroundColor Yellow
kubectl apply -f "$RootAppFile"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ root-app 部署成功！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 目前 ArgoCD Application 狀態：" -ForegroundColor Cyan
kubectl get applications -n argocd -o wide 2>$null
if ($LASTEXITCODE -ne 0) {
    kubectl get application -n argocd
}

Write-Host ""
Write-Host "💡 提示：" -ForegroundColor Cyan
Write-Host "• 若有安裝 ArgoCD CLI，可使用指令查看同步狀態: argocd app get root-app"
Write-Host "• 或至 ArgoCD UI (例如 http://localhost:8080 或 https://localhost:8000) 查看 App-of-Apps 拓撲結構"
Write-Host "============================================================" -ForegroundColor Cyan
