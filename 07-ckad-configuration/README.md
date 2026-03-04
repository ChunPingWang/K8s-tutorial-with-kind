# 第七章：CKAD — 應用程式環境、設定與安全 (Application Environment, Configuration and Security)

> **CKAD 考試佔比：25%**（最高佔比章節）

## 目錄

1. [Resource Requests 與 Limits](#1-resource-requests-與-limits)
2. [ResourceQuota](#2-resourcequota)
3. [LimitRange](#3-limitrange)
4. [ConfigMap 進階用法](#4-configmap-進階用法)
5. [Secret 進階用法](#5-secret-進階用法)
6. [ServiceAccount](#6-serviceaccount)
7. [SecurityContext](#7-securitycontext)
8. [實作練習](#8-實作練習)

---

## 1. Resource Requests 與 Limits

### 概念

```
Resource 模型

requests: 調度依據（Node 至少要有這麼多資源）
limits:   執行上限（容器不能超過此限制）

┌─────────────────────────────┐
│           Node              │
│  Allocatable: 4 CPU, 8Gi   │
│                             │
│  ┌────────────┐             │
│  │ Pod A      │             │
│  │ req: 0.5CPU│             │
│  │ lim: 1 CPU │             │
│  └────────────┘             │
│  ┌────────────┐             │
│  │ Pod B      │             │
│  │ req: 1 CPU │             │
│  │ lim: 2 CPU │             │
│  └────────────┘             │
│                             │
│  已 Request: 1.5 CPU       │
│  剩餘可調度: 2.5 CPU       │
└─────────────────────────────┘
```

### CPU vs Memory 限制行為差異

| 行為 | CPU | Memory |
|------|-----|--------|
| 超過 Limits | 被節流（Throttle） | 被 OOM Kill |
| 單位 | 核心數（1 = 1核, 100m = 0.1核） | Bytes（Mi, Gi） |

### YAML 範例

```yaml
containers:
  - name: app
    image: my-app
    resources:
      requests:
        cpu: "100m"      # 0.1 核心
        memory: "64Mi"   # 64 MiB
      limits:
        cpu: "500m"      # 0.5 核心
        memory: "256Mi"  # 256 MiB
```

---

## 2. ResourceQuota

ResourceQuota 限制**整個 Namespace** 的資源使用上限。

### 操作指令

```bash
# 建立 ResourceQuota
kubectl apply -f manifests/resource-quota.yaml

# 查看 ResourceQuota 使用狀況
kubectl describe resourcequota demo-quota -n demo

# 查看已使用 / 上限
kubectl get resourcequota demo-quota -n demo -o yaml

# 重點：當 ResourceQuota 存在時，每個 Pod 都必須設定 requests/limits
# 否則會被拒絕建立
```

### YAML 範例

參考 [manifests/resource-quota.yaml](./manifests/resource-quota.yaml)

---

## 3. LimitRange

LimitRange 為**單一容器**設定預設值和範圍限制。

```
ResourceQuota vs LimitRange

ResourceQuota:  限制整個 Namespace 的總量
                「這個 Namespace 最多用 4 CPU」

LimitRange:     限制單一 Container 的範圍
                「每個 Container 最多用 1 CPU，最少 10m」
                「沒設定的話預設給 200m」
```

### 操作指令

```bash
# 建立 LimitRange
kubectl apply -f manifests/limit-range.yaml

# 查看 LimitRange
kubectl describe limitrange demo-limits -n demo

# 測試：建立一個不設定 resources 的 Pod
kubectl run test-limits --image=busybox:1.36 -n demo \
  --command -- sleep 3600

# 查看自動套用的預設值
kubectl get pod test-limits -n demo -o yaml | grep -A 6 resources
```

### YAML 範例

參考 [manifests/limit-range.yaml](./manifests/limit-range.yaml)

---

## 4. ConfigMap 進階用法

### 使用方式比較

| 方式 | 說明 | 適用場景 |
|------|------|---------|
| 環境變數 (env) | 注入為環境變數 | 簡單的鍵值設定 |
| Volume 掛載 | 以檔案方式掛載 | 設定檔案（nginx.conf 等） |

### Volume 掛載特性

- ConfigMap 變更後，Volume 中的檔案會**自動更新**（約 60 秒）
- 環境變數方式注入後**不會自動更新**，需重啟 Pod

```bash
# 建立 ConfigMap Volume Pod
kubectl apply -f manifests/configmap-volume-pod.yaml

# 驗證 ConfigMap 檔案已掛載
kubectl exec configmap-volume-demo -n demo -- cat /config/app.properties
kubectl exec configmap-volume-demo -n demo -- ls -la /config/

# 更新 ConfigMap 後，檔案會自動更新
kubectl edit configmap app-config-file -n demo
# 等待約 60 秒
kubectl exec configmap-volume-demo -n demo -- cat /config/app.properties
```

### YAML 範例

參考 [manifests/configmap-volume-pod.yaml](./manifests/configmap-volume-pod.yaml)

---

## 5. Secret 進階用法

### Secret 類型

| Type | 說明 |
|------|------|
| `Opaque` | 通用型（預設） |
| `kubernetes.io/tls` | TLS 憑證 |
| `kubernetes.io/dockerconfigjson` | Docker Registry 認證 |
| `kubernetes.io/basic-auth` | 基本認證 |

### Volume 掛載

```bash
# 建立 Secret Volume Pod
kubectl apply -f manifests/secret-volume-pod.yaml

# 驗證 Secret 檔案
kubectl exec secret-volume-demo -n demo -- ls -la /certs/
kubectl exec secret-volume-demo -n demo -- cat /certs/tls.crt

# 建立 Docker Registry Secret（CKAD 考點）
kubectl create secret docker-registry my-registry \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  -n demo
```

### YAML 範例

參考 [manifests/secret-volume-pod.yaml](./manifests/secret-volume-pod.yaml)

---

## 6. ServiceAccount

ServiceAccount 為 Pod 提供身份，搭配 RBAC 控制對 K8s API 的存取。

```
ServiceAccount + RBAC 關係

ServiceAccount ──── RoleBinding ──── Role
(身份)              (繫結)          (權限)

Role 定義:
  可以 GET pods
  可以 LIST services
  不可以 DELETE anything
```

### 操作指令

```bash
# 建立 ServiceAccount
kubectl apply -f manifests/service-account.yaml

# 列出 ServiceAccount
kubectl get serviceaccounts -n demo

# 查看 Pod 使用的 ServiceAccount
kubectl get pod sa-demo-pod -n demo -o jsonpath='{.spec.serviceAccountName}'

# 查看預設 ServiceAccount
kubectl get sa default -n demo -o yaml
```

### YAML 範例

參考 [manifests/service-account.yaml](./manifests/service-account.yaml)

---

## 7. SecurityContext

SecurityContext 控制容器的安全相關設定。

### Pod 層級 vs Container 層級

| 層級 | 設定 | 說明 |
|------|------|------|
| Pod | `runAsUser` | 所有容器預設以此 UID 執行 |
| Pod | `runAsGroup` | 所有容器預設以此 GID 執行 |
| Pod | `fsGroup` | Volume 的群組擁有者 |
| Container | `runAsNonRoot` | 強制非 root |
| Container | `readOnlyRootFilesystem` | 唯讀根檔案系統 |
| Container | `allowPrivilegeEscalation` | 禁止提權 |
| Container | `capabilities` | Linux capabilities |

### 操作指令

```bash
# 建立 SecurityContext Pod
kubectl apply -f manifests/security-context-pod.yaml

# 驗證以非 root 執行
kubectl exec security-demo -n demo -- id
# 輸出: uid=1000 gid=3000 groups=2000

# 驗證唯讀檔案系統
kubectl exec security-demo -n demo -- touch /test 2>&1
# 輸出: touch: /test: Read-only file system

# 驗證可寫 Volume 正常
kubectl exec security-demo -n demo -- cat /tmp/writable/test.txt
```

### YAML 範例

參考 [manifests/security-context-pod.yaml](./manifests/security-context-pod.yaml)

---

## 8. 實作練習

### 練習 1：ResourceQuota 測試

```bash
# 建立 ResourceQuota
kubectl apply -f manifests/resource-quota.yaml

# 查看配額使用狀況
kubectl describe resourcequota demo-quota -n demo

# 嘗試建立超過配額的 Pod
kubectl run big-pod --image=busybox:1.36 -n demo \
  --overrides='{"spec":{"containers":[{"name":"big","image":"busybox:1.36","command":["sleep","3600"],"resources":{"requests":{"memory":"3Gi"}}}]}}'
# 應該會被拒絕
```

### 練習 2：SecurityContext 驗證

```bash
kubectl apply -f manifests/security-context-pod.yaml
kubectl exec security-demo -n demo -- id
kubectl exec security-demo -n demo -- touch /test 2>&1
kubectl exec security-demo -n demo -- cat /tmp/writable/test.txt
```

### 練習 3：ConfigMap 動態更新

```bash
kubectl apply -f manifests/configmap-volume-pod.yaml

# 修改 ConfigMap
kubectl patch configmap app-config-file -n demo \
  --type merge -p '{"data":{"app.properties":"server.port=9090\nlog.level=DEBUG\n"}}'

# 等待約 60 秒後檢查
kubectl exec configmap-volume-demo -n demo -- cat /config/app.properties
```

---

上一章：[06 - CKAD 可觀測性與維護](../06-ckad-observability/) ｜ 下一章：[08 - CKAD 網路](../08-ckad-networking/)
