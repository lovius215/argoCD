@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 取得腳本所在目錄
set "SCRIPT_DIR=%~dp0"
set "ROOT_APP_FILE=%SCRIPT_DIR%root-app.yaml"

echo ============================================================
echo 🚀 [Windows CMD] 部署 / 執行 Argo CD Root Application (App of Apps)
echo ============================================================

:: 1. 檢查 kubectl 是否存在
where kubectl >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ 錯誤: 未找到 kubectl 指令，請先安裝 kubectl 並加入 PATH。
    pause
    exit /b 1
)

:: 2. 檢查 Kubernetes 連線狀態
echo ^>^> 檢查 Kubernetes 叢集連線...
kubectl cluster-info >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ 錯誤: 無法連線至 Kubernetes 叢集，請確認 K8s 叢集 (Docker Desktop / minikube / kind) 是否已啟動。
    pause
    exit /b 1
)
echo ✅ K8s 叢集連線正常

:: 3. 檢查 argocd namespace 是否存在
kubectl get namespace argocd >nul 2>nul
if %errorlevel% neq 0 (
    echo ⚠️  未偵測到 argocd namespace，正在建立...
    kubectl create namespace argocd
)

:: 4. 檢查 root-app.yaml 檔案
if not exist "%ROOT_APP_FILE%" (
    echo ❌ 錯誤: 找不到 %ROOT_APP_FILE%
    pause
    exit /b 1
)

:: 5. 套用 root-app.yaml
echo.
echo ^>^> 套用 %ROOT_APP_FILE% 到 argocd namespace...
kubectl apply -f "%ROOT_APP_FILE%"
if %errorlevel% neq 0 (
    echo ❌ 部署失敗，請檢查錯誤訊息。
    pause
    exit /b 1
)

echo.
echo ============================================================
echo ✅ root-app 部署成功！
echo ============================================================
echo.
echo 📋 目前 ArgoCD Application 狀態：
kubectl get applications -n argocd -o wide 2>nul || kubectl get application -n argocd

echo.
echo 💡 提示：
echo • 若有安裝 ArgoCD CLI，可使用指令查看同步狀態: argocd app get root-app
echo • 或至 ArgoCD UI 查看 App-of-Apps 拓撲結構
echo ============================================================

endlocal
