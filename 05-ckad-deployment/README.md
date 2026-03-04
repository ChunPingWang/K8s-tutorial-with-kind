# 第五章：CKAD — 應用程式部署 (Application Deployment)

> **CKAD 考試佔比：20%**

## 目錄

1. [滾動更新 (Rolling Update)](#1-滾動更新-rolling-update)
2. [Blue-Green 部署](#2-blue-green-部署)
3. [Canary 部署](#3-canary-部署)
4. [Deployment 回滾](#4-deployment-回滾)
5. [實作練習](#5-實作練習)

---

## 1. 滾動更新 (Rolling Update)

K8s Deployment 預設的更新策略，逐步替換舊版 Pod 為新版。

### 策略參數

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # 更新期間最多額外幾個 Pod
    maxUnavailable: 1  # 更新期間最多幾個 Pod 不可用
```

```
滾動更新過程（replicas=4, maxSurge=1, maxUnavailable=1）

初始:  [v1] [v1] [v1] [v1]           共 4 個 Pod

Step1: [v1] [v1] [v1] [--] [v2↑]     移除 1 個 v1, 建立 1 個 v2
Step2: [v1] [v1] [--] [v2✓] [v2↑]    v2 Ready, 移除 1 個 v1
Step3: [v1] [--] [v2✓] [v2✓] [v2↑]
Step4: [--] [v2✓] [v2✓] [v2✓] [v2↑]
完成:  [v2✓] [v2✓] [v2✓] [v2✓]      全部更新完成
```

### 操作指令

```bash
# 建立 Deployment
kubectl apply -f manifests/rolling-update.yaml

# 觸發更新（修改映像檔版本）
kubectl set image deployment/rolling-demo app=busybox:1.37 -n demo

# 即時監看更新進度
kubectl rollout status deployment/rolling-demo -n demo

# 查看 ReplicaSet 變化
kubectl get rs -n demo -l app=rolling-demo

# 加上變更說明（CKAD 考試可能會考）
kubectl annotate deployment/rolling-demo -n demo \
  kubernetes.io/change-cause="Updated to busybox:1.37"
```

### YAML 範例

參考 [manifests/rolling-update.yaml](./manifests/rolling-update.yaml)

---

## 2. Blue-Green 部署

同時部署兩個版本，透過修改 Service selector 瞬間切換流量。

```
Blue-Green 切換流程

Step 1: Blue 接收流量
┌──────────┐     ┌──────────────┐
│ Service  ├────▶│ Blue (v1) ✓  │
│ app:web  │     └──────────────┘
│ ver:blue │     ┌──────────────┐
│          │     │ Green (v2)   │ ← 待機中
└──────────┘     └──────────────┘

Step 2: 切換到 Green
┌──────────┐     ┌──────────────┐
│ Service  │     │ Blue (v1)    │ ← 可保留做回滾
│ app:web  │     └──────────────┘
│ ver:green├────▶┌──────────────┐
│          │     │ Green (v2) ✓ │
└──────────┘     └──────────────┘
```

### 操作步驟

```bash
# 1. 部署 Blue 和 Green
kubectl apply -f manifests/blue-green/blue-deployment.yaml
kubectl apply -f manifests/blue-green/green-deployment.yaml

# 2. 建立 Service（初始指向 Blue）
kubectl apply -f manifests/blue-green/service.yaml

# 3. 確認 Service 指向 Blue
kubectl describe svc webapp-service -n demo | grep Selector

# 4. 測試 Green 沒問題後，切換到 Green
kubectl patch svc webapp-service -n demo \
  -p '{"spec":{"selector":{"version":"green"}}}'

# 5. 確認切換成功
kubectl describe svc webapp-service -n demo | grep Selector

# 6. 如果有問題，回切到 Blue
kubectl patch svc webapp-service -n demo \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# 7. 確認穩定後，刪除 Blue Deployment
kubectl delete deployment app-blue -n demo
```

### YAML 範例

參考 [manifests/blue-green/](./manifests/blue-green/)

---

## 3. Canary 部署

將少量流量導向新版本，觀察是否正常，再逐步增加比例。

```
Canary 流量分配

Service (selector: app=canary-app)
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌──▼──┐
│Stable │ │Canary│
│ 4 Pod │ │1 Pod │
│  v1   │ │ v2   │
│  80%  │ │ 20%  │
└───────┘ └──────┘
```

### 操作步驟

```bash
# 1. 部署穩定版 (4 replicas)
kubectl apply -f manifests/canary/stable-deployment.yaml

# 2. 部署金絲雀版 (1 replica)
kubectl apply -f manifests/canary/canary-deployment.yaml

# 3. 建立共用 Service
kubectl apply -f manifests/canary/service.yaml

# 4. 確認所有 Pod 都被 Service 選到
kubectl describe svc canary-service -n demo | grep Endpoints

# 5. 確認 canary 正常後，逐步增加比例
kubectl scale deployment app-canary -n demo --replicas=2
kubectl scale deployment app-stable -n demo --replicas=3
# 現在比例為 3:2 = 60%:40%

# 6. 完全切換到新版
kubectl scale deployment app-canary -n demo --replicas=4
kubectl scale deployment app-stable -n demo --replicas=0

# 7. 刪除舊版 Deployment
kubectl delete deployment app-stable -n demo
```

### YAML 範例

參考 [manifests/canary/](./manifests/canary/)

---

## 4. Deployment 回滾

```bash
# 查看更新歷史
kubectl rollout history deployment/rolling-demo -n demo

# 查看特定版本的詳細資訊
kubectl rollout history deployment/rolling-demo -n demo --revision=2

# 回滾到上一個版本
kubectl rollout undo deployment/rolling-demo -n demo

# 回滾到指定版本
kubectl rollout undo deployment/rolling-demo -n demo --to-revision=1

# 暫停更新（可以做多次修改後一次更新）
kubectl rollout pause deployment/rolling-demo -n demo

# 恢復更新
kubectl rollout resume deployment/rolling-demo -n demo
```

---

## 5. 實作練習

### 練習 1：滾動更新與回滾

```bash
# 建立 Deployment
kubectl apply -f manifests/rolling-update.yaml

# 觸發更新
kubectl set image deployment/rolling-demo app=busybox:1.37 -n demo

# 觀察更新過程
kubectl rollout status deployment/rolling-demo -n demo
kubectl get rs -n demo -l app=rolling-demo

# 回滾
kubectl rollout undo deployment/rolling-demo -n demo
```

### 練習 2：Blue-Green 切換

```bash
kubectl apply -f manifests/blue-green/
kubectl describe svc webapp-service -n demo
kubectl patch svc webapp-service -n demo -p '{"spec":{"selector":{"version":"green"}}}'
kubectl describe svc webapp-service -n demo
```

### 練習 3：Canary 漸進部署

```bash
kubectl apply -f manifests/canary/
kubectl get pods -n demo -l app=canary-app -L track,version
kubectl scale deployment app-canary -n demo --replicas=2
kubectl get pods -n demo -l app=canary-app -L track,version
```

---

上一章：[04 - CKAD 應用程式設計與建構](../04-ckad-workloads/) ｜ 下一章：[06 - CKAD 可觀測性與維護](../06-ckad-observability/)
