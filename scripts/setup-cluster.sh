#!/usr/bin/env bash
# setup-cluster.sh — 一鍵建立 Kind 叢集並載入範例映像檔
# 使用方式: ./scripts/setup-cluster.sh
set -euo pipefail

CLUSTER_NAME="${1:-ckad-lab}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
KIND_CONFIG="${ROOT_DIR}/02-kind-basics/kind-config.yaml"

echo "============================================"
echo " K8s CKAD Lab — 叢集建立腳本"
echo "============================================"

# ---- 前置檢查 ----
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "[ERROR] 找不到指令: $1，請先安裝。"
    exit 1
  fi
}

check_command docker
check_command kind
check_command kubectl

echo "[✓] docker, kind, kubectl 皆已安裝"

# ---- 檢查 Docker 是否執行中 ----
if ! docker info &> /dev/null; then
  echo "[ERROR] Docker 未啟動，請先啟動 Docker。"
  exit 1
fi
echo "[✓] Docker 正在執行"

# ---- 建立叢集 ----
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "[!] 叢集 '${CLUSTER_NAME}' 已存在，跳過建立。"
else
  echo "[*] 正在建立 Kind 叢集: ${CLUSTER_NAME} ..."
  kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}" --wait 60s
  echo "[✓] 叢集建立完成"
fi

# ---- 確認叢集狀態 ----
echo ""
echo "[*] 叢集節點狀態:"
kubectl get nodes -o wide

# ---- 建構範例映像檔 ----
APP_DIR="${ROOT_DIR}/01-docker-basics/app"
if [ -d "$APP_DIR" ]; then
  echo ""
  echo "[*] 正在建構範例映像檔: my-node-app:1.0 ..."
  docker build -t my-node-app:1.0 "$APP_DIR" -q
  echo "[✓] 映像檔建構完成"

  echo "[*] 正在載入映像檔到 Kind 叢集 ..."
  kind load docker-image my-node-app:1.0 --name "${CLUSTER_NAME}"
  echo "[✓] 映像檔載入完成"
fi

echo ""
echo "============================================"
echo " 叢集準備就緒！"
echo " 叢集名稱: ${CLUSTER_NAME}"
echo " Context:  kind-${CLUSTER_NAME}"
echo "============================================"
echo ""
echo "你可以開始使用以下指令操作叢集："
echo "  kubectl get nodes"
echo "  kubectl cluster-info"
