#!/usr/bin/env bash
# validate-all.sh — 驗證所有 YAML 檔案的語法正確性
# 使用方式: ./scripts/validate-all.sh
# 需要: kubectl (使用 --dry-run=client 驗證)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo " K8s YAML 驗證腳本"
echo "============================================"
echo ""

TOTAL=0
PASSED=0
FAILED=0
ERRORS=()

# 收集所有 YAML 檔案（排除 kustomization.yaml 需要特殊處理）
while IFS= read -r -d '' file; do
  filename=$(basename "$file")
  # 跳過 kustomization.yaml（需搭配 kustomize 驗證）和 kind config（非 K8s 資源）
  if [[ "$filename" == "kustomization.yaml" ]] || [[ "$file" == *"kind-"*".yaml" ]]; then
    continue
  fi

  TOTAL=$((TOTAL + 1))
  relative_path="${file#$ROOT_DIR/}"

  if kubectl apply --dry-run=client -f "$file" &> /dev/null; then
    echo "  [✓] ${relative_path}"
    PASSED=$((PASSED + 1))
  else
    error_msg=$(kubectl apply --dry-run=client -f "$file" 2>&1)
    echo "  [✗] ${relative_path}"
    echo "       ${error_msg}"
    FAILED=$((FAILED + 1))
    ERRORS+=("${relative_path}: ${error_msg}")
  fi
done < <(find "$ROOT_DIR" -name "*.yaml" -not -path "*/.git/*" -print0 | sort -z)

echo ""
echo "============================================"
echo " 驗證結果"
echo "============================================"
echo "  總計:  ${TOTAL} 個檔案"
echo "  通過:  ${PASSED} 個"
echo "  失敗:  ${FAILED} 個"
echo "============================================"

if [ ${FAILED} -gt 0 ]; then
  echo ""
  echo "失敗的檔案:"
  for err in "${ERRORS[@]}"; do
    echo "  - ${err}"
  done
  exit 1
fi

echo ""
echo "[✓] 所有 YAML 檔案驗證通過！"
