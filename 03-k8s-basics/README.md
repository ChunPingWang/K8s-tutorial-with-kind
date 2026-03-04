# 第三章：Kubernetes 觀念與基本操作

## 目錄

1. [什麼是 Kubernetes？](#1-什麼是-kubernetes)
2. [K8s 架構](#2-k8s-架構)
3. [核心資源物件](#3-核心資源物件)
4. [Namespace（命名空間）](#4-namespace命名空間)
5. [Pod](#5-pod)
6. [Deployment](#6-deployment)
7. [Service](#7-service)
8. [ConfigMap 與 Secret](#8-configmap-與-secret)
9. [實戰演練：完整部署範例](#9-實戰演練完整部署範例)
10. [除錯與排查](#10-除錯與排查)

---

## 1. 什麼是 Kubernetes？

Kubernetes（K8s）是一個開源的**容器編排平台**，用於自動化容器化應用程式的部署、擴展和管理。

### 為什麼需要 Kubernetes？

當你只有 1-2 個容器時，`docker run` 就夠用了。但當你有數十甚至數百個容器時：

| 挑戰 | K8s 的解決方案 |
|------|---------------|
| 容器當機怎麼辦？ | 自動重啟（Self-healing） |
| 如何擴展服務？ | 水平自動擴展（HPA） |
| 如何更新不停機？ | 滾動更新（Rolling Update） |
| 如何做負載均衡？ | Service 負載分散 |
| 如何管理設定？ | ConfigMap / Secret |
| 如何跨主機部署？ | 叢集調度（Scheduling） |

---

## 2. K8s 架構

```
Kubernetes 叢集架構

┌─────────────────────────────────────────────────────────┐
│                    Control Plane                         │
│                                                         │
│  ┌─────────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ API Server  │  │ etcd     │  │ Controller Manager│  │
│  │             │  │ (資料庫) │  │                   │  │
│  │ 所有操作的  │  │ 儲存叢集 │  │ 確保實際狀態     │  │
│  │ 唯一入口    │  │ 狀態資料 │  │ 符合期望狀態     │  │
│  └──────┬──────┘  └──────────┘  └───────────────────┘  │
│         │         ┌──────────────────┐                   │
│         │         │ Scheduler        │                   │
│         │         │ 決定 Pod 部署到  │                   │
│         │         │ 哪個 Node        │                   │
│         │         └──────────────────┘                   │
└─────────┼───────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│                    Worker Nodes                          │
│                                                         │
│  ┌─────────────────────┐  ┌─────────────────────┐      │
│  │     Worker Node 1   │  │     Worker Node 2   │      │
│  │                     │  │                     │      │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │      │
│  │  │ kubelet       │  │  │  │ kubelet       │  │      │
│  │  │ (節點代理)    │  │  │  │ (節點代理)    │  │      │
│  │  ├───────────────┤  │  │  ├───────────────┤  │      │
│  │  │ kube-proxy    │  │  │  │ kube-proxy    │  │      │
│  │  │ (網路代理)    │  │  │  │ (網路代理)    │  │      │
│  │  ├───────────────┤  │  │  ├───────────────┤  │      │
│  │  │ ┌─Pod──┐      │  │  │  │ ┌─Pod──┐      │  │      │
│  │  │ │ App  │      │  │  │  │ │ App  │      │  │      │
│  │  │ └──────┘      │  │  │  │ └──────┘      │  │      │
│  │  │ ┌─Pod──┐      │  │  │  │ ┌─Pod──┐      │  │      │
│  │  │ │ App  │      │  │  │  │ │ App  │      │  │      │
│  │  │ └──────┘      │  │  │  │ └──────┘      │  │      │
│  │  └───────────────┘  │  │  └───────────────┘  │      │
│  └─────────────────────┘  └─────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

### 核心元件說明

| 元件 | 位置 | 功能 |
|------|------|------|
| **API Server** | Control Plane | 所有操作的入口，處理 REST 請求 |
| **etcd** | Control Plane | 分散式鍵值資料庫，儲存叢集所有狀態 |
| **Controller Manager** | Control Plane | 管理各種 Controller，確保期望狀態 |
| **Scheduler** | Control Plane | 決定新建的 Pod 應該放到哪個 Node |
| **kubelet** | Worker Node | 節點代理，管理該節點上的 Pod |
| **kube-proxy** | Worker Node | 網路代理，處理 Service 的網路轉發 |

### 宣告式管理（Declarative）

Kubernetes 採用**宣告式**的方式管理資源——你描述「期望的狀態」，K8s 負責達成：

```yaml
# 你告訴 K8s：「我要 3 個 nginx Pod」
spec:
  replicas: 3
```

K8s 會自動確保永遠有 3 個 nginx Pod 在運行。如果有 Pod 當機，K8s 會自動補一個新的。

---

## 3. 核心資源物件

```
K8s 資源物件關係圖

                    ┌───────────┐
                    │ Namespace │  ← 邏輯分隔
                    └─────┬─────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
  ┌─────▼─────┐   ┌──────▼──────┐   ┌──────▼──────┐
  │Deployment │   │  Service    │   │ ConfigMap   │
  │ (管理 Pod │   │ (網路存取) │   │ (設定)      │
  │  的數量)   │   │             │   │             │
  └─────┬─────┘   └──────┬──────┘   └─────────────┘
        │                 │
  ┌─────▼─────┐          │
  │ ReplicaSet│          │
  │           │          │
  └─────┬─────┘          │
        │                 │
  ┌─────▼─────────────────▼──┐
  │          Pod             │  ← 最小部署單位
  │   ┌───────────────────┐  │
  │   │    Container      │  │
  │   └───────────────────┘  │
  └──────────────────────────┘
```

### YAML 基本結構

所有 K8s 資源都使用 YAML 格式定義：

```yaml
apiVersion: v1            # API 版本
kind: Pod                 # 資源類型
metadata:                 # 後設資料
  name: my-pod            #   資源名稱
  namespace: default      #   命名空間
  labels:                 #   標籤（用於選取）
    app: my-app
spec:                     # 規格（期望狀態）
  containers:
    - name: my-container
      image: nginx:latest
```

---

## 4. Namespace（命名空間）

Namespace 用於在同一個叢集中建立**邏輯隔離**的環境。

```
Namespace 隔離示意

┌─────────────────────────────────────────┐
│              K8s Cluster                 │
│                                         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │ ns: dev      │  │ ns: prod     │    │
│  │              │  │              │    │
│  │ ┌──────────┐ │  │ ┌──────────┐ │    │
│  │ │ App v2.0 │ │  │ │ App v1.0 │ │    │
│  │ └──────────┘ │  │ └──────────┘ │    │
│  │ ┌──────────┐ │  │ ┌──────────┐ │    │
│  │ │ DB test  │ │  │ │ DB prod  │ │    │
│  │ └──────────┘ │  │ └──────────┘ │    │
│  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────┘
```

### 操作指令

```bash
# 列出所有 Namespace
kubectl get namespaces
# 或簡寫
kubectl get ns

# 建立 Namespace
kubectl create namespace dev

# 使用 YAML 建立
kubectl apply -f manifests/namespace.yaml

# 在特定 Namespace 中操作
kubectl get pods -n dev
kubectl get all -n dev

# 設定預設 Namespace
kubectl config set-context --current --namespace=dev

# 刪除 Namespace（會刪除其中所有資源）
kubectl delete namespace dev
```

### Namespace YAML

參考 [manifests/namespace.yaml](./manifests/namespace.yaml)。

---

## 5. Pod

Pod 是 K8s 中**最小的部署單位**，包含一個或多個緊密相關的容器。

### Pod 的特性

- 同一個 Pod 中的容器共享**網路**和**儲存**
- Pod 是短暫的（ephemeral），隨時可能被重建
- 通常不直接建立 Pod，而是透過 Deployment 管理

```
Pod 內部結構

┌─────────────────────────────────┐
│            Pod                  │
│                                 │
│  ┌───────────┐  ┌───────────┐  │
│  │ Container │  │ Container │  │
│  │ (App)     │  │ (Sidecar) │  │
│  │           │  │           │  │
│  │ Port:3000 │  │ Port:9090 │  │
│  └───────────┘  └───────────┘  │
│                                 │
│  共享 Network: 10.244.0.5      │
│  共享 Volume:  /shared-data    │
│                                 │
└─────────────────────────────────┘
```

### 操作指令

```bash
# 快速建立 Pod（測試用）
kubectl run nginx --image=nginx

# 使用 YAML 建立 Pod
kubectl apply -f manifests/pod.yaml

# 列出 Pod
kubectl get pods
kubectl get pods -o wide          # 顯示更多資訊（IP、Node）
kubectl get pods -w               # 即時監看

# 查看 Pod 詳細資訊
kubectl describe pod my-pod

# 查看 Pod 日誌
kubectl logs my-pod
kubectl logs -f my-pod            # 即時追蹤日誌
kubectl logs my-pod -c my-container  # 指定容器（多容器 Pod）

# 進入 Pod 中的容器
kubectl exec -it my-pod -- bash
kubectl exec -it my-pod -c my-container -- sh

# Port Forward（本地測試）
kubectl port-forward my-pod 8080:3000
# 然後在瀏覽器開啟 http://localhost:8080

# 刪除 Pod
kubectl delete pod my-pod
kubectl delete -f manifests/pod.yaml
```

### Pod YAML

參考 [manifests/pod.yaml](./manifests/pod.yaml)。

---

## 6. Deployment

Deployment 是管理 Pod 的高階控制器，提供：

- **副本管理**：確保指定數量的 Pod 執行中
- **滾動更新**：不停機更新應用
- **回滾**：快速回到先前版本

```
Deployment 管理結構

┌──────────────────────────────────────────┐
│ Deployment (my-app)                      │
│ replicas: 3                              │
│                                          │
│  ┌───────────────────────────────────┐   │
│  │ ReplicaSet (my-app-6d4f5b8c7)    │   │
│  │                                   │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│  │  │ Pod 1   │ │ Pod 2   │ │ Pod 3   │ │
│  │  │ my-app  │ │ my-app  │ │ my-app  │ │
│  │  └─────────┘ └─────────┘ └─────────┘ │
│  └───────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

### 操作指令

```bash
# 使用 YAML 建立 Deployment
kubectl apply -f manifests/deployment.yaml

# 列出 Deployment
kubectl get deployments
# 或簡寫
kubectl get deploy

# 查看 Deployment 詳細資訊
kubectl describe deployment my-app

# 查看 ReplicaSet
kubectl get replicaset
kubectl get rs

# 擴縮副本數量
kubectl scale deployment my-app --replicas=5

# 更新映像檔版本
kubectl set image deployment/my-app my-app=my-app:2.0

# 查看更新狀態
kubectl rollout status deployment/my-app

# 查看更新歷史
kubectl rollout history deployment/my-app

# 回滾到上一個版本
kubectl rollout undo deployment/my-app

# 回滾到指定版本
kubectl rollout undo deployment/my-app --to-revision=2

# 刪除 Deployment
kubectl delete deployment my-app
```

### 滾動更新過程

```
滾動更新（v1 → v2）

Step 1: 初始狀態
  [Pod v1] [Pod v1] [Pod v1]

Step 2: 建立新 Pod，終止舊 Pod
  [Pod v1] [Pod v1] [Pod v2 ✓]

Step 3: 繼續更新
  [Pod v1] [Pod v2 ✓] [Pod v2 ✓]

Step 4: 更新完成
  [Pod v2 ✓] [Pod v2 ✓] [Pod v2 ✓]
```

### Deployment YAML

參考 [manifests/deployment.yaml](./manifests/deployment.yaml)。

---

## 7. Service

Service 提供穩定的網路端點來存取一組 Pod。Pod 的 IP 會隨著重建改變，但 Service 的 IP 是固定的。

### Service 類型

| 類型 | 說明 | 使用場景 |
|------|------|---------|
| **ClusterIP** | 叢集內部存取（預設） | 微服務之間通訊 |
| **NodePort** | 透過節點埠對外暴露 | 開發/測試環境 |
| **LoadBalancer** | 雲端負載均衡器 | 生產環境（雲端） |

```
Service 類型比較

ClusterIP (叢集內部)
┌─────────────────────────────────┐
│  Cluster                        │
│  ┌─────────┐    ┌──────────┐   │
│  │ Pod A   ├───▶│ Service  │   │
│  │ (client)│    │ ClusterIP├──▶│ Pod B (backend)
│  └─────────┘    └──────────┘   │
└─────────────────────────────────┘

NodePort (對外暴露)
                  ┌─────────────────────────────────┐
 外部使用者       │  Cluster                        │
 ┌──────┐        │  ┌──────────┐   ┌──────────┐   │
 │ User ├────────┤─▶│ NodePort ├──▶│  Pod     │   │
 │      │ :30080 │  │ Service  │   │ (app)    │   │
 └──────┘        │  └──────────┘   └──────────┘   │
                  └─────────────────────────────────┘
```

### 操作指令

```bash
# 使用 YAML 建立 Service
kubectl apply -f manifests/service.yaml

# 列出 Service
kubectl get services
# 或簡寫
kubectl get svc

# 查看 Service 詳細資訊
kubectl describe service my-app-service

# 快速建立 Service（expose Deployment）
kubectl expose deployment my-app --port=80 --target-port=3000 --type=NodePort

# 測試 ClusterIP Service（從叢集內部）
kubectl run curl --image=curlimages/curl --rm -it -- sh
# 在容器內: curl http://my-app-service

# 測試 NodePort Service
# 取得 NodePort 埠號
kubectl get svc my-app-service -o jsonpath='{.spec.ports[0].nodePort}'

# 刪除 Service
kubectl delete service my-app-service
```

### Service YAML

參考 [manifests/service-clusterip.yaml](./manifests/service-clusterip.yaml) 和 [manifests/service-nodeport.yaml](./manifests/service-nodeport.yaml)。

---

## 8. ConfigMap 與 Secret

### ConfigMap

ConfigMap 用於儲存**非機密**的設定資料，讓設定與程式碼分離。

```bash
# 從命令列建立 ConfigMap
kubectl create configmap my-config \
  --from-literal=DB_HOST=localhost \
  --from-literal=DB_PORT=5432

# 從檔案建立 ConfigMap
kubectl create configmap nginx-config --from-file=nginx.conf

# 使用 YAML 建立
kubectl apply -f manifests/configmap.yaml

# 查看 ConfigMap
kubectl get configmap
kubectl describe configmap my-config
```

### Secret

Secret 用於儲存**機密資料**（密碼、Token、金鑰等）。Secret 的值以 Base64 編碼儲存。

```bash
# 從命令列建立 Secret
kubectl create secret generic db-secret \
  --from-literal=DB_PASSWORD=mysecretpassword \
  --from-literal=DB_USER=admin

# 使用 YAML 建立
kubectl apply -f manifests/secret.yaml

# 查看 Secret
kubectl get secrets
kubectl describe secret db-secret

# 查看 Secret 的值（Base64 解碼）
kubectl get secret db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

> **注意**：Base64 不是加密！生產環境建議搭配外部 Secret 管理方案（如 Vault、Sealed Secrets）。

### 在 Pod 中使用 ConfigMap / Secret

```yaml
# 方式 1：作為環境變數
env:
  - name: DB_HOST
    valueFrom:
      configMapKeyRef:
        name: my-config
        key: DB_HOST
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: DB_PASSWORD

# 方式 2：作為 Volume 掛載
volumes:
  - name: config-volume
    configMap:
      name: my-config
```

### ConfigMap / Secret YAML

參考 [manifests/configmap.yaml](./manifests/configmap.yaml) 和 [manifests/secret.yaml](./manifests/secret.yaml)。

---

## 9. 實戰演練：完整部署範例

以下步驟會將第一章的範例應用部署到 Kind 叢集。

### 步驟 1：建立 Kind 叢集

```bash
cd ../02-kind-basics
kind create cluster --name lab --config kind-config.yaml

# 確認叢集
kubectl get nodes
```

### 步驟 2：建構與載入映像檔

```bash
# 建構映像檔
cd ../01-docker-basics/app
docker build -t my-node-app:1.0 .

# 載入到 Kind
kind load docker-image my-node-app:1.0 --name lab
```

### 步驟 3：部署應用

```bash
cd ../../03-k8s-basics

# 建立 Namespace
kubectl apply -f manifests/namespace.yaml

# 建立 ConfigMap
kubectl apply -f manifests/configmap.yaml

# 建立 Deployment
kubectl apply -f manifests/deployment.yaml

# 建立 Service
kubectl apply -f manifests/service-nodeport.yaml

# 確認所有資源
kubectl get all -n demo
```

### 步驟 4：測試應用

```bash
# Port Forward 測試
kubectl port-forward -n demo service/demo-app-service 8080:80 &

# 發送請求
curl http://localhost:8080

# 多次請求，觀察不同 Pod 回應（負載均衡）
for i in $(seq 1 5); do curl -s http://localhost:8080 | jq .hostname; done
```

### 步驟 5：擴縮與更新

```bash
# 擴展到 5 個副本
kubectl scale deployment demo-app -n demo --replicas=5
kubectl get pods -n demo -w

# 查看 Pod 分布在哪些 Node
kubectl get pods -n demo -o wide
```

### 步驟 6：清理

```bash
# 刪除所有資源
kubectl delete namespace demo

# 刪除 Kind 叢集
kind delete cluster --name lab
```

---

## 10. 除錯與排查

### 常用除錯指令

```bash
# 查看 Pod 狀態
kubectl get pods -o wide

# 查看 Pod 事件（找出為什麼啟動失敗）
kubectl describe pod <pod-name>

# 查看 Pod 日誌
kubectl logs <pod-name>
kubectl logs <pod-name> --previous    # 查看上一次容器的日誌

# 進入 Pod 執行命令
kubectl exec -it <pod-name> -- sh

# 查看叢集事件
kubectl get events --sort-by=.metadata.creationTimestamp

# 查看資源使用狀況
kubectl top nodes
kubectl top pods
```

### 常見問題排查

#### Pod 狀態為 ImagePullBackOff

```
原因：無法拉取映像檔
解法：
1. 確認映像檔名稱是否正確
2. Kind 環境需要先 `kind load docker-image`
3. 設定 imagePullPolicy: Never 或 IfNotPresent
```

#### Pod 狀態為 CrashLoopBackOff

```
原因：容器啟動後立即退出
解法：
1. kubectl logs <pod-name> 查看錯誤日誌
2. kubectl logs <pod-name> --previous 查看上次日誌
3. 檢查 CMD / ENTRYPOINT 是否正確
4. 檢查環境變數與設定是否正確
```

#### Pod 狀態為 Pending

```
原因：無法被調度到任何 Node
解法：
1. kubectl describe pod <pod-name> 查看 Events
2. 確認 Node 是否有足夠資源
3. 確認是否有 Node Selector 或 Taint 限制
```

#### Service 無法連線

```
解法：
1. 確認 Pod 正在執行: kubectl get pods
2. 確認 Service selector 與 Pod labels 匹配
3. 確認目標 Port 正確
4. kubectl describe svc <service-name> 查看 Endpoints
```

---

## 常用指令速查表

```bash
# === 基本操作 ===
kubectl get <resource>              # 列出資源
kubectl describe <resource> <name>  # 詳細資訊
kubectl apply -f <file>             # 建立/更新資源
kubectl delete -f <file>            # 刪除資源
kubectl delete <resource> <name>    # 刪除指定資源

# === Pod ===
kubectl get pods -o wide            # 列出 Pod（含 IP、Node）
kubectl logs <pod>                  # 查看日誌
kubectl exec -it <pod> -- sh       # 進入容器
kubectl port-forward <pod> 8080:80  # 轉發埠

# === Deployment ===
kubectl get deploy                  # 列出 Deployment
kubectl scale deploy <name> --replicas=N  # 擴縮
kubectl rollout status deploy <name>      # 更新狀態
kubectl rollout undo deploy <name>        # 回滾

# === Service ===
kubectl get svc                     # 列出 Service
kubectl expose deploy <name> --port=80    # 快速建立

# === 除錯 ===
kubectl describe pod <name>         # Pod 事件
kubectl logs <pod> --previous       # 上次日誌
kubectl get events                  # 叢集事件

# === 資源簡寫 ===
# pods → po | deployments → deploy | services → svc
# namespaces → ns | configmaps → cm | replicasets → rs
```

---

上一章：[02 - Kind 基本觀念與安裝](../02-kind-basics/)
