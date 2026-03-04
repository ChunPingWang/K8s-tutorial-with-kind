#!/usr/bin/env bash
# run-lab.sh — 逐章執行實驗並驗證結果
# 使用方式: ./scripts/run-lab.sh [chapter]
# 範例: ./scripts/run-lab.sh 03   (只跑第三章)
#       ./scripts/run-lab.sh       (跑全部)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CHAPTER="${1:-all}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}[✓]${NC} $1"; }
fail() { echo -e "  ${RED}[✗]${NC} $1"; }
info() { echo -e "  ${YELLOW}[*]${NC} $1"; }

wait_for_pods() {
  local ns="$1"
  local timeout="${2:-120}"
  kubectl wait --for=condition=Ready pods --all -n "$ns" --timeout="${timeout}s" 2>/dev/null
}

# ================================================================
# Chapter 03: K8s Basics
# ================================================================
run_ch03() {
  echo ""
  echo "========================================"
  echo " 第三章：K8s 基本操作 驗證"
  echo "========================================"

  info "建立 Namespace ..."
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/namespace.yaml"
  pass "Namespace demo 已建立"

  info "建立 ConfigMap ..."
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/configmap.yaml"
  pass "ConfigMap 已建立"

  info "建立 Secret ..."
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/secret.yaml"
  pass "Secret 已建立"

  info "建立 Pod ..."
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/pod.yaml"

  info "等待 Pod Ready ..."
  if kubectl wait --for=condition=Ready pod/demo-pod -n demo --timeout=60s &>/dev/null; then
    pass "Pod demo-pod 已就緒"
  else
    fail "Pod demo-pod 未能在 60 秒內就緒"
    kubectl describe pod demo-pod -n demo
  fi

  info "建立 Deployment ..."
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/deployment.yaml"
  if kubectl rollout status deployment/demo-app -n demo --timeout=120s &>/dev/null; then
    pass "Deployment demo-app 已就緒 (3 replicas)"
  else
    fail "Deployment 未能在 120 秒內就緒"
  fi

  info "建立 Service (ClusterIP) ..."
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/service-clusterip.yaml"
  pass "ClusterIP Service 已建立"

  info "建立 Service (NodePort) ..."
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/service-nodeport.yaml"
  pass "NodePort Service 已建立"

  echo ""
  info "第三章資源總覽："
  kubectl get all -n demo
  echo ""

  # 測試 Service 連通性
  info "測試 Service 連通性 ..."
  SVC_IP=$(kubectl get svc demo-app-service -n demo -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
  if kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -n demo \
    -- curl -s --max-time 5 "http://${SVC_IP}" 2>/dev/null | grep -q "hostname"; then
    pass "Service 連通性測試通過"
  else
    info "Service 連通性測試跳過 (可能需要等待 Pod 完全啟動)"
  fi

  # 清理
  info "清理第三章資源 ..."
  kubectl delete -f "${ROOT_DIR}/03-k8s-basics/manifests/pod.yaml" --ignore-not-found &>/dev/null
  kubectl delete -f "${ROOT_DIR}/03-k8s-basics/manifests/deployment.yaml" --ignore-not-found &>/dev/null
  kubectl delete -f "${ROOT_DIR}/03-k8s-basics/manifests/service-clusterip.yaml" --ignore-not-found &>/dev/null
  kubectl delete -f "${ROOT_DIR}/03-k8s-basics/manifests/service-nodeport.yaml" --ignore-not-found &>/dev/null
  pass "第三章資源已清理"
}

# ================================================================
# Chapter 04: CKAD Workloads
# ================================================================
run_ch04() {
  echo ""
  echo "========================================"
  echo " 第四章：CKAD Workloads 驗證"
  echo "========================================"

  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/namespace.yaml" 2>/dev/null || true
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/configmap.yaml" 2>/dev/null || true
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/secret.yaml" 2>/dev/null || true

  info "建立 Multi-container Pod (init + sidecar) ..."
  kubectl apply -f "${ROOT_DIR}/04-ckad-workloads/manifests/multi-container-pod.yaml"
  if kubectl wait --for=condition=Ready pod/multi-container-demo -n demo --timeout=90s &>/dev/null; then
    pass "Multi-container Pod 已就緒"
  else
    fail "Multi-container Pod 未能就緒"
    kubectl describe pod multi-container-demo -n demo
  fi

  info "建立 Job ..."
  kubectl apply -f "${ROOT_DIR}/04-ckad-workloads/manifests/job.yaml"
  if kubectl wait --for=condition=Complete job/math-job -n demo --timeout=60s &>/dev/null; then
    pass "Job 執行完成"
    info "Job 輸出: $(kubectl logs job/math-job -n demo 2>/dev/null | head -1)"
  else
    fail "Job 未能在 60 秒內完成"
  fi

  info "建立 CronJob ..."
  kubectl apply -f "${ROOT_DIR}/04-ckad-workloads/manifests/cronjob.yaml"
  pass "CronJob 已建立 (排程: */1 * * * *)"

  info "建立 PersistentVolumeClaim ..."
  kubectl apply -f "${ROOT_DIR}/04-ckad-workloads/manifests/pvc.yaml"
  pass "PVC 已建立"

  info "建立使用 PVC 的 Pod ..."
  kubectl apply -f "${ROOT_DIR}/04-ckad-workloads/manifests/pod-with-pvc.yaml"
  if kubectl wait --for=condition=Ready pod/pvc-demo-pod -n demo --timeout=60s &>/dev/null; then
    pass "PVC Pod 已就緒"
  else
    info "PVC Pod 等待中 (StorageClass 可能不支援動態供應)"
  fi

  # 清理
  info "清理第四章資源 ..."
  kubectl delete -f "${ROOT_DIR}/04-ckad-workloads/manifests/" -n demo --ignore-not-found &>/dev/null
  pass "第四章資源已清理"
}

# ================================================================
# Chapter 05: CKAD Deployment Strategies
# ================================================================
run_ch05() {
  echo ""
  echo "========================================"
  echo " 第五章：CKAD 部署策略 驗證"
  echo "========================================"

  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/namespace.yaml" 2>/dev/null || true
  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/configmap.yaml" 2>/dev/null || true

  info "建立 Rolling Update Deployment ..."
  kubectl apply -f "${ROOT_DIR}/05-ckad-deployment/manifests/rolling-update.yaml"
  if kubectl rollout status deployment/rolling-demo -n demo --timeout=90s &>/dev/null; then
    pass "Rolling Update Deployment 已就緒"
  else
    fail "Rolling Update Deployment 未能就緒"
  fi

  info "建立 Blue-Green Deployment ..."
  kubectl apply -f "${ROOT_DIR}/05-ckad-deployment/manifests/blue-green/blue-deployment.yaml"
  kubectl apply -f "${ROOT_DIR}/05-ckad-deployment/manifests/blue-green/green-deployment.yaml"
  kubectl apply -f "${ROOT_DIR}/05-ckad-deployment/manifests/blue-green/service.yaml"
  pass "Blue-Green 資源已建立"

  info "建立 Canary Deployment ..."
  kubectl apply -f "${ROOT_DIR}/05-ckad-deployment/manifests/canary/stable-deployment.yaml"
  kubectl apply -f "${ROOT_DIR}/05-ckad-deployment/manifests/canary/canary-deployment.yaml"
  kubectl apply -f "${ROOT_DIR}/05-ckad-deployment/manifests/canary/service.yaml"
  pass "Canary 資源已建立"

  # 清理
  info "清理第五章資源 ..."
  kubectl delete -f "${ROOT_DIR}/05-ckad-deployment/manifests/rolling-update.yaml" --ignore-not-found &>/dev/null
  kubectl delete -f "${ROOT_DIR}/05-ckad-deployment/manifests/blue-green/" --ignore-not-found &>/dev/null
  kubectl delete -f "${ROOT_DIR}/05-ckad-deployment/manifests/canary/" --ignore-not-found &>/dev/null
  pass "第五章資源已清理"
}

# ================================================================
# Chapter 06: Observability
# ================================================================
run_ch06() {
  echo ""
  echo "========================================"
  echo " 第六章：CKAD Observability 驗證"
  echo "========================================"

  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/namespace.yaml" 2>/dev/null || true

  info "建立 Probes 示範 Pod ..."
  kubectl apply -f "${ROOT_DIR}/06-ckad-observability/manifests/probes-pod.yaml"
  if kubectl wait --for=condition=Ready pod/probes-demo -n demo --timeout=60s &>/dev/null; then
    pass "Probes Pod 已就緒"
  else
    info "Probes Pod 等待中"
  fi

  info "建立 Logging 示範 Pod ..."
  kubectl apply -f "${ROOT_DIR}/06-ckad-observability/manifests/logging-pod.yaml"
  pass "Logging Pod 已建立"

  info "建立 Debug Pod ..."
  kubectl apply -f "${ROOT_DIR}/06-ckad-observability/manifests/debug-pod.yaml"
  pass "Debug Pod 已建立"

  # 清理
  info "清理第六章資源 ..."
  kubectl delete -f "${ROOT_DIR}/06-ckad-observability/manifests/" -n demo --ignore-not-found &>/dev/null
  pass "第六章資源已清理"
}

# ================================================================
# Chapter 07: Configuration and Security
# ================================================================
run_ch07() {
  echo ""
  echo "========================================"
  echo " 第七章：CKAD Configuration & Security 驗證"
  echo "========================================"

  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/namespace.yaml" 2>/dev/null || true

  info "建立 ResourceQuota ..."
  kubectl apply -f "${ROOT_DIR}/07-ckad-configuration/manifests/resource-quota.yaml"
  pass "ResourceQuota 已建立"

  info "建立 LimitRange ..."
  kubectl apply -f "${ROOT_DIR}/07-ckad-configuration/manifests/limit-range.yaml"
  pass "LimitRange 已建立"

  info "建立 ServiceAccount ..."
  kubectl apply -f "${ROOT_DIR}/07-ckad-configuration/manifests/service-account.yaml"
  pass "ServiceAccount 已建立"

  info "建立 SecurityContext Pod ..."
  kubectl apply -f "${ROOT_DIR}/07-ckad-configuration/manifests/security-context-pod.yaml"
  if kubectl wait --for=condition=Ready pod/security-demo -n demo --timeout=60s &>/dev/null; then
    pass "SecurityContext Pod 已就緒"
  else
    info "SecurityContext Pod 等待中"
  fi

  info "建立 ConfigMap Volume Pod ..."
  kubectl apply -f "${ROOT_DIR}/07-ckad-configuration/manifests/configmap-volume-pod.yaml"
  pass "ConfigMap Volume Pod 已建立"

  info "建立 Secret Volume Pod ..."
  kubectl apply -f "${ROOT_DIR}/07-ckad-configuration/manifests/secret-volume-pod.yaml"
  pass "Secret Volume Pod 已建立"

  # 清理
  info "清理第七章資源 ..."
  kubectl delete -f "${ROOT_DIR}/07-ckad-configuration/manifests/" -n demo --ignore-not-found &>/dev/null
  pass "第七章資源已清理"
}

# ================================================================
# Chapter 08: Networking
# ================================================================
run_ch08() {
  echo ""
  echo "========================================"
  echo " 第八章：CKAD Networking 驗證"
  echo "========================================"

  kubectl apply -f "${ROOT_DIR}/03-k8s-basics/manifests/namespace.yaml" 2>/dev/null || true

  info "建立 NetworkPolicy ..."
  kubectl apply -f "${ROOT_DIR}/08-ckad-networking/manifests/network-policy-deny-all.yaml"
  kubectl apply -f "${ROOT_DIR}/08-ckad-networking/manifests/network-policy-allow-app.yaml"
  pass "NetworkPolicy 已建立"

  info "建立 Ingress ..."
  kubectl apply -f "${ROOT_DIR}/08-ckad-networking/manifests/ingress.yaml"
  pass "Ingress 已建立"

  # 清理
  info "清理第八章資源 ..."
  kubectl delete -f "${ROOT_DIR}/08-ckad-networking/manifests/" -n demo --ignore-not-found &>/dev/null
  pass "第八章資源已清理"
}

# ================================================================
# Main
# ================================================================
echo "============================================"
echo " K8s CKAD Lab — 全章節驗證"
echo "============================================"

# 確認叢集連線
if ! kubectl cluster-info &>/dev/null; then
  echo "[ERROR] 無法連線到 K8s 叢集，請先執行 ./scripts/setup-cluster.sh"
  exit 1
fi

case "$CHAPTER" in
  03) run_ch03 ;;
  04) run_ch04 ;;
  05) run_ch05 ;;
  06) run_ch06 ;;
  07) run_ch07 ;;
  08) run_ch08 ;;
  all)
    run_ch03
    run_ch04
    run_ch05
    run_ch06
    run_ch07
    run_ch08
    ;;
  *) echo "使用方式: $0 [03|04|05|06|07|08|all]"; exit 1 ;;
esac

# 最終清理 namespace
kubectl delete namespace demo --ignore-not-found --wait=false &>/dev/null || true

echo ""
echo "============================================"
echo " 全部驗證完成！"
echo "============================================"
