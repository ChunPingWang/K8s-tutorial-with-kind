#!/usr/bin/env bash
# cleanup.sh — 清理所有 K8s 資源與 Kind 叢集
# 使用方式: ./scripts/cleanup.sh [cluster-name]
set -euo pipefail

CLUSTER_NAME="${1:-ckad-lab}"

echo "============================================"
echo " K8s CKAD Lab — 清理腳本"
echo "============================================"

# ---- 刪除所有教學用 Namespace ----
NAMESPACES=("demo" "dev" "staging" "prod" "ckad-lab" "network-lab")
for ns in "${NAMESPACES[@]}"; do
  if kubectl get namespace "$ns" &> /dev/null 2>&1; then
    echo "[*] 正在刪除 Namespace: $ns ..."
    kubectl delete namespace "$ns" --wait=false
  fi
done

# ---- 刪除 Kind 叢集 ----
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "[*] 正在刪除 Kind 叢集: ${CLUSTER_NAME} ..."
  kind delete cluster --name "${CLUSTER_NAME}"
  echo "[✓] 叢集已刪除"
else
  echo "[!] 叢集 '${CLUSTER_NAME}' 不存在，跳過。"
fi

# ---- 清理 Docker 映像檔 ----
echo "[*] 正在清理範例映像檔 ..."
docker rmi my-node-app:1.0 2>/dev/null || true
docker rmi my-node-app:2.0 2>/dev/null || true

echo ""
echo "[✓] 清理完成！"
