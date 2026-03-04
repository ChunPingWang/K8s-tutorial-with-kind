# 第六章：CKAD — 可觀測性與維護 (Application Observability and Maintenance)

> **CKAD 考試佔比：15%**

## 目錄

1. [探針 (Probes)](#1-探針-probes)
2. [容器日誌](#2-容器日誌)
3. [監控與資源使用](#3-監控與資源使用)
4. [除錯技巧](#4-除錯技巧)
5. [API 版本與棄用](#5-api-版本與棄用)
6. [實作練習](#6-實作練習)

---

## 1. 探針 (Probes)

K8s 透過三種探針來判斷容器的狀態：

```
探針類型與生命週期

Container 啟動
    │
    ▼
┌──────────────┐
│ startupProbe │ ← 啟動期間只有此探針運作
│ 檢查啟動狀態 │    失敗 → 重啟容器
└──────┬───────┘
       │ 成功
       ▼
┌──────────────┐    ┌───────────────┐
│livenessProbe │    │readinessProbe │
│ 檢查是否存活 │    │ 檢查是否就緒  │
│ 失敗→重啟    │    │ 失敗→移出     │
│   容器       │    │   Service     │
└──────────────┘    └───────────────┘
   持續檢查              持續檢查
```

### 三種探針比較

| 探針 | 功能 | 失敗後果 | 使用時機 |
|------|------|---------|---------|
| **startupProbe** | 檢查容器啟動完成 | 重啟容器 | 啟動緩慢的應用 |
| **livenessProbe** | 檢查容器是否存活 | 重啟容器 | 偵測死鎖或卡死 |
| **readinessProbe** | 檢查容器是否就緒 | 從 Service 移除 | 暫時無法服務 |

### 探測方式

| 方式 | 說明 | 範例 |
|------|------|------|
| `exec` | 執行命令，回傳碼 0 為成功 | `command: ['cat', '/tmp/healthy']` |
| `httpGet` | HTTP GET 請求，2xx/3xx 為成功 | `path: /health, port: 8080` |
| `tcpSocket` | TCP 連線，連線成功為成功 | `port: 3306` |

### 探針參數

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10   # 首次探測延遲秒數
  periodSeconds: 10          # 探測間隔秒數
  timeoutSeconds: 3          # 探測逾時秒數
  failureThreshold: 3        # 連續失敗幾次才視為失敗
  successThreshold: 1        # 連續成功幾次才視為成功
```

### 操作指令

```bash
# 建立 Probes Pod
kubectl apply -f manifests/probes-pod.yaml

# 觀察 Pod 狀態變化
kubectl get pod probes-demo -n demo -w

# 查看探針事件
kubectl describe pod probes-demo -n demo | grep -A 20 Events

# 模擬 Liveness 失敗（刪除 health 檔案）
kubectl exec probes-demo -n demo -- rm /tmp/healthy
# 等待 30 秒觀察容器重啟
kubectl get pod probes-demo -n demo -w
```

### YAML 範例

參考 [manifests/probes-pod.yaml](./manifests/probes-pod.yaml)

---

## 2. 容器日誌

### 查看日誌

```bash
# 查看 Pod 日誌
kubectl logs <pod-name> -n demo

# 即時追蹤日誌（類似 tail -f）
kubectl logs -f <pod-name> -n demo

# 查看最近 N 行日誌
kubectl logs --tail=20 <pod-name> -n demo

# 查看最近 N 秒的日誌
kubectl logs --since=60s <pod-name> -n demo

# 查看多容器 Pod 中特定容器的日誌
kubectl logs <pod-name> -n demo -c <container-name>

# 查看所有容器的日誌
kubectl logs <pod-name> -n demo --all-containers=true

# 查看已重啟容器的前一次日誌
kubectl logs <pod-name> -n demo --previous

# 查看 Deployment 所有 Pod 的日誌
kubectl logs deployment/<deploy-name> -n demo

# 使用 Label Selector 查看多個 Pod 日誌
kubectl logs -l app=my-app -n demo
```

### 多容器日誌範例

```bash
# 建立多容器日誌 Pod
kubectl apply -f manifests/logging-pod.yaml

# 查看 app 容器日誌
kubectl logs logging-demo -n demo -c app

# 查看 access-log 容器日誌
kubectl logs logging-demo -n demo -c access-log

# 同時查看所有容器日誌
kubectl logs logging-demo -n demo --all-containers=true

# 過濾日誌
kubectl logs logging-demo -n demo -c app | grep ERROR
kubectl logs logging-demo -n demo -c app | grep WARN
```

---

## 3. 監控與資源使用

```bash
# 查看節點資源使用（需要 metrics-server）
kubectl top nodes

# 查看 Pod 資源使用
kubectl top pods -n demo

# 查看特定 Pod 各容器的資源使用
kubectl top pod <pod-name> -n demo --containers

# 排序查看（依 CPU）
kubectl top pods -n demo --sort-by=cpu

# 排序查看（依 Memory）
kubectl top pods -n demo --sort-by=memory
```

> **注意**：`kubectl top` 需要 Metrics Server。Kind 叢集預設未安裝。

---

## 4. 除錯技巧

### 4.1 Pod 除錯流程

```
Pod 除錯決策樹

Pod 狀態異常？
    │
    ├── Pending ──────▶ kubectl describe pod → 查看 Events
    │                   可能原因：資源不足、Node Selector、Taint
    │
    ├── ImagePullBackOff ──▶ 映像檔名稱錯誤 / Registry 認證失敗
    │                       Kind: 確認已 kind load docker-image
    │
    ├── CrashLoopBackOff ──▶ kubectl logs <pod> --previous
    │                       容器啟動後立即退出
    │                       檢查 CMD/ENTRYPOINT、環境變數
    │
    ├── Running 但不正常 ──▶ kubectl exec -it <pod> -- sh
    │                       進入容器內部檢查
    │
    └── Terminating ──────▶ kubectl delete pod <pod> --grace-period=0 --force
```

### 4.2 使用 Debug Pod

```bash
# 建立 debug pod
kubectl apply -f manifests/debug-pod.yaml

# 進入 debug pod
kubectl exec -it debug-pod -n demo -- sh

# 在 debug pod 內測試 DNS
nslookup kubernetes.default.svc.cluster.local

# 測試 Service 連通性
wget -qO- http://demo-app-service.demo.svc.cluster.local

# 測試 TCP 連接
nc -zv demo-app-service.demo 80
```

### 4.3 常用除錯指令

```bash
# 查看 Pod 事件
kubectl describe pod <pod-name> -n demo

# 查看叢集事件（按時間排序）
kubectl get events -n demo --sort-by='.metadata.creationTimestamp'

# 查看資源的 YAML 定義
kubectl get pod <pod-name> -n demo -o yaml

# 使用 JSONPath 提取資訊
kubectl get pod <pod-name> -n demo -o jsonpath='{.status.phase}'
kubectl get pod <pod-name> -n demo -o jsonpath='{.status.containerStatuses[0].restartCount}'

# 臨時執行除錯 Pod
kubectl run tmp-debug --image=busybox:1.36 --rm -it --restart=Never -n demo -- sh

# 使用 ephemeral container 除錯（K8s 1.25+）
kubectl debug <pod-name> -n demo -it --image=busybox:1.36
```

---

## 5. API 版本與棄用

### 常見 API 版本

| 資源 | API Version |
|------|-------------|
| Pod, Service, ConfigMap, Secret | `v1` |
| Deployment, ReplicaSet, DaemonSet | `apps/v1` |
| Job, CronJob | `batch/v1` |
| Ingress | `networking.k8s.io/v1` |
| NetworkPolicy | `networking.k8s.io/v1` |
| PersistentVolume, PVC | `v1` |
| ServiceAccount | `v1` |
| Role, RoleBinding | `rbac.authorization.k8s.io/v1` |

### 查看可用 API 資源

```bash
# 列出所有 API 資源
kubectl api-resources

# 查看特定資源的 API 版本
kubectl api-resources | grep deployment

# 查看 API 版本
kubectl api-versions

# 解釋特定資源的欄位
kubectl explain pod.spec.containers
kubectl explain deployment.spec.strategy
```

---

## 6. 實作練習

### 練習 1：探針行為驗證

```bash
# 建立 Probes Pod
kubectl apply -f manifests/probes-pod.yaml

# 觀察 Pod 從 Not Ready → Ready 的過程
kubectl get pod probes-demo -n demo -w

# 模擬 Liveness 失敗
kubectl exec probes-demo -n demo -- rm /tmp/healthy

# 觀察容器重啟
kubectl get pod probes-demo -n demo -w
# RESTARTS 欄位會增加
```

### 練習 2：多容器日誌分析

```bash
kubectl apply -f manifests/logging-pod.yaml
# 等待 30 秒產生日誌

# 分別查看各容器日誌
kubectl logs logging-demo -n demo -c app --tail=10
kubectl logs logging-demo -n demo -c access-log --tail=10

# 過濾 ERROR
kubectl logs logging-demo -n demo -c app | grep ERROR
```

### 練習 3：Pod 除錯

```bash
# 使用 describe 查看 Pod 事件
kubectl describe pod probes-demo -n demo

# 使用 JSONPath 取得 Pod IP
kubectl get pod probes-demo -n demo -o jsonpath='{.status.podIP}'

# 進入容器內部檢查
kubectl exec -it probes-demo -n demo -- sh
ls /tmp/
cat /tmp/healthy
exit
```

---

上一章：[05 - CKAD 部署策略](../05-ckad-deployment/) ｜ 下一章：[07 - CKAD 設定與安全](../07-ckad-configuration/)
