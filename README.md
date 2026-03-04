# Kubernetes 教育訓練教材 — 使用 Kind 實戰（CKAD 認證等級）

> 適用對象：程式開發者（具備基本 Linux 指令操作能力）
> 教材等級：涵蓋 CKAD（Certified Kubernetes Application Developer）認證考試全部範圍

本教材從 Docker 基礎觀念出發，逐步引導至使用 Kind 建立本地 Kubernetes 叢集，最終掌握 K8s 核心觀念與 CKAD 認證考試所需的全部技能。

---

## CKAD 考試範圍對照

| CKAD 考試領域 | 佔比 | 對應章節 |
|--------------|------|---------|
| Application Design and Build | 20% | [Ch04](./04-ckad-workloads/) |
| Application Deployment | 20% | [Ch05](./05-ckad-deployment/) |
| Application Observability and Maintenance | 15% | [Ch06](./06-ckad-observability/) |
| Application Environment, Configuration and Security | 25% | [Ch07](./07-ckad-configuration/) |
| Services and Networking | 20% | [Ch08](./08-ckad-networking/) |

---

## 課程大綱

### 基礎篇（Ch01 - Ch03）

| 章節 | 主題 | 內容概述 |
|------|------|----------|
| [01-docker-basics](./01-docker-basics/) | Docker 基本觀念與安裝 | Container vs VM、Docker 架構與安裝、映像檔建構、容器操作、Dockerfile 撰寫 |
| [02-kind-basics](./02-kind-basics/) | Kind 基本觀念與安裝 | Kind 簡介與比較、安裝方式、單/多節點叢集建立、映像檔載入 |
| [03-k8s-basics](./03-k8s-basics/) | Kubernetes 觀念與基本操作 | K8s 架構、Namespace / Pod / Deployment / Service / ConfigMap / Secret |

### CKAD 進階篇（Ch04 - Ch08）

| 章節 | 主題 | 內容概述 |
|------|------|----------|
| [04-ckad-workloads](./04-ckad-workloads/) | 應用程式設計與建構 | 多容器 Pod（Init/Sidecar）、Job、CronJob、PV/PVC 持久化儲存 |
| [05-ckad-deployment](./05-ckad-deployment/) | 應用程式部署策略 | Rolling Update、Blue-Green 部署、Canary 部署、Rollback |
| [06-ckad-observability](./06-ckad-observability/) | 可觀測性與維護 | Probes（Liveness/Readiness/Startup）、日誌、監控、除錯技巧 |
| [07-ckad-configuration](./07-ckad-configuration/) | 設定與安全 | ResourceQuota、LimitRange、SecurityContext、ServiceAccount、Volume 掛載 |
| [08-ckad-networking](./08-ckad-networking/) | 服務與網路 | Service 深入、DNS 服務發現、NetworkPolicy、Ingress |

---

## 學習路徑

```
基礎篇                                    CKAD 進階篇

Ch01 Docker    Ch02 Kind    Ch03 K8s     Ch04         Ch05          Ch06
┌──────────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐ ┌──────────┐  ┌──────────┐
│Container │  │ Kind    │  │ Pod     │  │ Job      │ │ Rolling  │  │ Probes   │
│Image     │─▶│ Cluster │─▶│ Deploy  │─▶│ CronJob  │ │ Blue-Grn │  │ Logging  │
│Dockerfile│  │ kubectl │  │ Service │  │ Init/Side│ │ Canary   │  │ Debug    │
└──────────┘  └─────────┘  └─────────┘  │ PV/PVC   │ └──────────┘  └──────────┘
                                        └──────────┘
                                                      Ch07          Ch08
                                                      ┌──────────┐  ┌──────────┐
                                                      │ Quota    │  │ NetPol   │
                                                      │ Security │  │ Ingress  │
                                                      │ SA/RBAC  │  │ DNS      │
                                                      └──────────┘  └──────────┘
```

---

## 先備條件

- 作業系統：Linux / macOS / Windows（建議使用 Linux 或 macOS）
- 已安裝 [Git](https://git-scm.com/)
- 已安裝 [Docker](https://docs.docker.com/get-docker/)
- 具備基本終端機（Terminal）操作能力
- 建議記憶體 **8GB 以上**

---

## 快速開始

```bash
# 1. Clone 本教材
git clone <repository-url>
cd K8s-tutorial-with-kind

# 2. 安裝必要工具後，一鍵建立叢集
./scripts/setup-cluster.sh

# 3. 驗證所有 YAML 檔案語法正確
./scripts/validate-all.sh

# 4. 執行全章節自動驗證
./scripts/run-lab.sh

# 5. 從第一章開始學習
cd 01-docker-basics
```

---

## 腳本工具

| 腳本 | 功能 |
|------|------|
| [`scripts/setup-cluster.sh`](./scripts/setup-cluster.sh) | 一鍵建立 Kind 叢集、建構映像檔並載入 |
| [`scripts/validate-all.sh`](./scripts/validate-all.sh) | 驗證所有 YAML 檔案語法正確性（`kubectl --dry-run`） |
| [`scripts/run-lab.sh`](./scripts/run-lab.sh) | 逐章執行實驗並自動驗證（支援單章或全部） |
| [`scripts/cleanup.sh`](./scripts/cleanup.sh) | 清理所有資源與叢集 |

```bash
# 執行特定章節驗證
./scripts/run-lab.sh 04   # 只驗證第四章
./scripts/run-lab.sh all  # 驗證全部章節
```

---

## 專案結構

```
K8s-tutorial-with-kind/
├── README.md                              ← 你在這裡
├── .gitignore
├── scripts/
│   ├── setup-cluster.sh                   # 叢集建立腳本
│   ├── validate-all.sh                    # YAML 驗證腳本
│   ├── run-lab.sh                         # 全章節自動驗證
│   └── cleanup.sh                         # 清理腳本
│
├── 01-docker-basics/                      # Docker 基礎
│   ├── README.md
│   └── app/                               # 範例 Node.js 應用
│       ├── server.js
│       ├── package.json
│       ├── Dockerfile
│       └── .dockerignore
│
├── 02-kind-basics/                        # Kind 基礎
│   ├── README.md
│   ├── kind-config.yaml                   # 多節點叢集設定
│   └── kind-ha-config.yaml                # HA 叢集設定
│
├── 03-k8s-basics/                         # K8s 基礎
│   ├── README.md
│   └── manifests/
│       ├── namespace.yaml
│       ├── pod.yaml
│       ├── deployment.yaml
│       ├── service-clusterip.yaml
│       ├── service-nodeport.yaml
│       ├── configmap.yaml
│       └── secret.yaml
│
├── 04-ckad-workloads/                     # CKAD: 工作負載
│   ├── README.md
│   └── manifests/
│       ├── multi-container-pod.yaml       # Init Container + Sidecar
│       ├── job.yaml                       # 一次性任務
│       ├── cronjob.yaml                   # 排程任務
│       ├── pvc.yaml                       # 持久化儲存
│       └── pod-with-pvc.yaml             # 使用 PVC 的 Pod
│
├── 05-ckad-deployment/                    # CKAD: 部署策略
│   ├── README.md
│   └── manifests/
│       ├── rolling-update.yaml            # 滾動更新
│       ├── blue-green/                    # Blue-Green 部署
│       │   ├── blue-deployment.yaml
│       │   ├── green-deployment.yaml
│       │   └── service.yaml
│       └── canary/                        # Canary 部署
│           ├── stable-deployment.yaml
│           ├── canary-deployment.yaml
│           └── service.yaml
│
├── 06-ckad-observability/                 # CKAD: 可觀測性
│   ├── README.md
│   └── manifests/
│       ├── probes-pod.yaml                # 三種探針
│       ├── logging-pod.yaml               # 日誌範例
│       └── debug-pod.yaml                 # 除錯 Pod
│
├── 07-ckad-configuration/                 # CKAD: 設定與安全
│   ├── README.md
│   └── manifests/
│       ├── resource-quota.yaml            # 資源配額
│       ├── limit-range.yaml               # 預設資源限制
│       ├── service-account.yaml           # ServiceAccount
│       ├── security-context-pod.yaml      # 安全上下文
│       ├── configmap-volume-pod.yaml      # ConfigMap Volume
│       └── secret-volume-pod.yaml         # Secret Volume
│
└── 08-ckad-networking/                    # CKAD: 網路
    ├── README.md
    └── manifests/
        ├── network-policy-deny-all.yaml   # 預設拒絕
        ├── network-policy-allow-app.yaml  # 允許規則
        └── ingress.yaml                   # Ingress 路由
```

---

## CKAD 考試準備建議

### 考試形式
- **時間**：2 小時
- **題數**：15-20 題
- **及格分**：66%
- **環境**：真實 K8s 叢集，只能用 kubectl 和官方文件

### 必備技能
1. **速度**：熟練使用 `kubectl` 指令，善用 `--dry-run=client -o yaml` 產生模板
2. **YAML 撰寫**：快速撰寫 Pod, Deployment, Service, ConfigMap 等 YAML
3. **除錯能力**：快速定位 Pod 啟動失敗、Service 連不上等問題
4. **vim 操作**：考試只能用終端文字編輯器

### 快速產生 YAML 模板

```bash
# Pod
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Deployment
kubectl create deployment nginx --image=nginx --replicas=3 \
  --dry-run=client -o yaml > deploy.yaml

# Service (expose)
kubectl expose deployment nginx --port=80 --target-port=8080 \
  --type=NodePort --dry-run=client -o yaml > svc.yaml

# Job
kubectl create job my-job --image=busybox \
  --dry-run=client -o yaml -- echo "hello" > job.yaml

# CronJob
kubectl create cronjob my-cron --image=busybox \
  --schedule="*/5 * * * *" \
  --dry-run=client -o yaml -- echo "hello" > cron.yaml

# ConfigMap
kubectl create configmap my-config \
  --from-literal=key1=val1 \
  --dry-run=client -o yaml > cm.yaml

# Secret
kubectl create secret generic my-secret \
  --from-literal=pass=secret \
  --dry-run=client -o yaml > secret.yaml

# ServiceAccount
kubectl create serviceaccount my-sa \
  --dry-run=client -o yaml > sa.yaml
```

### kubectl 效率技巧

```bash
# 設定別名
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'

# 快速切換 Namespace
kubectl config set-context --current --namespace=demo

# 查看資源欄位說明
kubectl explain pod.spec.containers.livenessProbe
kubectl explain deployment.spec.strategy

# JSON 路徑查詢
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get nodes -o jsonpath='{.items[*].status.addresses[0].address}'
```

---

## 授權

本教材僅供教育訓練使用。
