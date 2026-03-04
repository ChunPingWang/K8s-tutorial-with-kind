# 第四章：CKAD — 應用程式設計與建構 (Application Design and Build)

> **CKAD 考試佔比：20%**

## 目錄

1. [多容器 Pod 設計模式](#1-多容器-pod-設計模式)
2. [Job（一次性任務）](#2-job一次性任務)
3. [CronJob（排程任務）](#3-cronjob排程任務)
4. [持久化儲存（PV / PVC）](#4-持久化儲存pv--pvc)
5. [實作練習](#5-實作練習)

---

## 1. 多容器 Pod 設計模式

CKAD 考試要求理解多容器 Pod 的三種設計模式：

### 設計模式概覽

```
┌─────────────────────────────────────────────────────────┐
│                 Multi-Container Patterns                │
│                                                         │
│  Sidecar              Ambassador         Adapter        │
│  ┌──────────────┐    ┌──────────────┐   ┌────────────┐ │
│  │ ┌────┐┌────┐ │    │ ┌────┐┌────┐ │   │┌────┐┌────┐│ │
│  │ │App ││Side│ │    │ │App ││Amb │ │   ││App ││Adpt││ │
│  │ │    ││car │ │    │ │    ││    │ │   ││    ││    ││ │
│  │ └────┘└────┘ │    │ └────┘└─┬──┘ │   │└──┬─┘└──┬─┘│ │
│  │              │    │         │    │   │   │     │   │ │
│  │ 輔助功能     │    │    外部服務   │   │ 格式轉換  │ │
│  │ (日誌/監控)  │    │    代理       │   │          │ │
│  └──────────────┘    └──────────────┘   └────────────┘ │
└─────────────────────────────────────────────────────────┘
```

| 模式 | 說明 | 範例 |
|------|------|------|
| **Sidecar** | 為主容器提供輔助功能 | 日誌收集器、檔案同步 |
| **Ambassador** | 代理主容器的對外連線 | 資料庫連線代理 |
| **Adapter** | 轉換主容器的輸出格式 | 日誌格式標準化 |

### Init Container

Init Container 在所有一般容器啟動之前依序執行，常用於：

- 等待相依服務就緒
- 初始化設定檔案
- 執行資料庫遷移

```
Init Container 執行順序

┌────────┐   ┌────────┐   ┌────────────────────────┐
│ Init 1 │──▶│ Init 2 │──▶│  Main + Sidecar 容器   │
│ (完成) │   │ (完成) │   │  (同時啟動)            │
└────────┘   └────────┘   └────────────────────────┘
  依序執行                     全部 Init 完成後啟動
```

### 操作指令

```bash
# 建立多容器 Pod
kubectl apply -f manifests/multi-container-pod.yaml

# 查看 Pod 中各容器狀態
kubectl get pod multi-container-demo -n demo -o wide

# 查看特定容器日誌
kubectl logs multi-container-demo -n demo -c app
kubectl logs multi-container-demo -n demo -c log-collector
kubectl logs multi-container-demo -n demo -c init-setup

# 進入特定容器
kubectl exec -it multi-container-demo -n demo -c app -- sh

# 查看共享的 Volume 資料
kubectl exec multi-container-demo -n demo -c app -- cat /shared/init.log
```

### YAML 範例

參考 [manifests/multi-container-pod.yaml](./manifests/multi-container-pod.yaml)

---

## 2. Job（一次性任務）

Job 確保一個或多個 Pod 成功完成指定的任務。

### Job 類型

| 類型 | completions | parallelism | 說明 |
|------|------------|-------------|------|
| 單一任務 | 1 | 1 | 執行一次就完成 |
| 固定完成數 | N | 1 | 依序完成 N 次 |
| 平行處理 | N | M | 同時 M 個 Pod 執行，共完成 N 次 |

### 操作指令

```bash
# 建立 Job
kubectl apply -f manifests/job.yaml

# 查看 Job 狀態
kubectl get jobs -n demo

# 查看 Job 產生的 Pod
kubectl get pods -n demo -l app=math-job

# 查看 Job 執行結果
kubectl logs job/math-job -n demo

# 等待 Job 完成
kubectl wait --for=condition=Complete job/math-job -n demo --timeout=60s

# 手動刪除 Job（及其 Pod）
kubectl delete job math-job -n demo
```

### YAML 範例

參考 [manifests/job.yaml](./manifests/job.yaml)

---

## 3. CronJob（排程任務）

CronJob 按照 Cron 排程定期建立 Job。

### Cron 排程語法

```
┌───────────── 分 (0 - 59)
│ ┌─────────── 時 (0 - 23)
│ │ ┌───────── 日 (1 - 31)
│ │ │ ┌─────── 月 (1 - 12)
│ │ │ │ ┌───── 星期 (0 - 6, 0=Sunday)
│ │ │ │ │
* * * * *

範例:
*/5 * * * *     每 5 分鐘
0 */2 * * *     每 2 小時
0 9 * * 1-5     週一到週五 09:00
0 0 1 * *       每月 1 號 00:00
```

### concurrencyPolicy

| 值 | 說明 |
|------|------|
| `Allow` | 允許多個 Job 同時執行（預設） |
| `Forbid` | 禁止同時執行，跳過新的排程 |
| `Replace` | 取消目前執行中的 Job，啟動新的 |

### 操作指令

```bash
# 建立 CronJob
kubectl apply -f manifests/cronjob.yaml

# 查看 CronJob
kubectl get cronjob -n demo

# 手動觸發一次執行
kubectl create job --from=cronjob/health-check-cron manual-run -n demo

# 查看排程產生的 Job 歷史
kubectl get jobs -n demo

# 暫停 CronJob
kubectl patch cronjob health-check-cron -n demo -p '{"spec":{"suspend":true}}'

# 恢復 CronJob
kubectl patch cronjob health-check-cron -n demo -p '{"spec":{"suspend":false}}'

# 刪除 CronJob
kubectl delete cronjob health-check-cron -n demo
```

### YAML 範例

參考 [manifests/cronjob.yaml](./manifests/cronjob.yaml)

---

## 4. 持久化儲存（PV / PVC）

### 儲存概念

```
儲存架構

┌──────────────┐     ┌──────────────────┐     ┌───────────────┐
│     Pod      │     │ PersistentVolume │     │  實際儲存     │
│              │     │     Claim (PVC)  │     │               │
│ volumeMounts:│────▶│                  │────▶│ - 本地磁碟    │
│  /data       │     │ 100Mi, RWO       │     │ - NFS         │
│              │ 引用 │                  │ 綁定 │ - Cloud Disk  │
└──────────────┘     └──────────────────┘     └───────────────┘
                              │
                     ┌────────▼────────┐
                     │ StorageClass    │
                     │ (動態供應規則)  │
                     └─────────────────┘
```

### Volume 類型比較

| 類型 | 生命週期 | 說明 |
|------|---------|------|
| `emptyDir` | Pod 生命週期 | Pod 刪除即消失 |
| `hostPath` | Node 生命週期 | 掛載節點本地路徑 |
| `PV/PVC` | 獨立於 Pod | 持久化儲存 |

### 存取模式 (Access Modes)

| 模式 | 縮寫 | 說明 |
|------|------|------|
| ReadWriteOnce | RWO | 單節點讀寫 |
| ReadOnlyMany | ROX | 多節點唯讀 |
| ReadWriteMany | RWX | 多節點讀寫 |

### 操作指令

```bash
# 建立 PVC
kubectl apply -f manifests/pvc.yaml

# 查看 PVC 狀態
kubectl get pvc -n demo
# 狀態: Pending → Bound

# 查看 PV（自動建立的）
kubectl get pv

# 建立使用 PVC 的 Pod
kubectl apply -f manifests/pod-with-pvc.yaml

# 驗證資料持久化：刪除 Pod 後重建
kubectl delete pod pvc-demo-pod -n demo
kubectl apply -f manifests/pod-with-pvc.yaml
kubectl exec pvc-demo-pod -n demo -- cat /data/log.txt
# 可以看到之前寫入的資料仍然存在！

# 清理
kubectl delete -f manifests/pod-with-pvc.yaml
kubectl delete -f manifests/pvc.yaml
```

### YAML 範例

參考 [manifests/pvc.yaml](./manifests/pvc.yaml) 和 [manifests/pod-with-pvc.yaml](./manifests/pod-with-pvc.yaml)

---

## 5. 實作練習

### 練習 1：建立多容器 Pod

建立一個包含以下容器的 Pod：
- Init Container：寫入一段歡迎訊息到共享 Volume
- 主容器：讀取並顯示歡迎訊息，然後持續輸出日誌
- Sidecar：定期讀取主容器的日誌並輸出

```bash
kubectl apply -f manifests/multi-container-pod.yaml
kubectl logs multi-container-demo -n demo -c app
kubectl logs multi-container-demo -n demo -c log-collector
```

### 練習 2：執行批次任務

建立一個 Job，計算並輸出結果，然後驗證 Job 完成狀態：

```bash
kubectl apply -f manifests/job.yaml
kubectl wait --for=condition=Complete job/math-job -n demo --timeout=60s
kubectl logs job/math-job -n demo
```

### 練習 3：排程任務

建立 CronJob 並觀察排程執行：

```bash
kubectl apply -f manifests/cronjob.yaml
# 等待 1-2 分鐘
kubectl get jobs -n demo
kubectl get pods -n demo -l app=health-check
```

### 練習 4：驗證資料持久化

```bash
# 建立 PVC 和 Pod
kubectl apply -f manifests/pvc.yaml
kubectl apply -f manifests/pod-with-pvc.yaml

# 寫入資料
kubectl exec pvc-demo-pod -n demo -- sh -c 'echo "important data" > /data/test.txt'

# 刪除 Pod
kubectl delete pod pvc-demo-pod -n demo

# 重建 Pod
kubectl apply -f manifests/pod-with-pvc.yaml
kubectl wait --for=condition=Ready pod/pvc-demo-pod -n demo --timeout=60s

# 驗證資料仍存在
kubectl exec pvc-demo-pod -n demo -- cat /data/test.txt
```

---

上一章：[03 - Kubernetes 觀念與基本操作](../03-k8s-basics/) ｜ 下一章：[05 - CKAD 部署策略](../05-ckad-deployment/)
