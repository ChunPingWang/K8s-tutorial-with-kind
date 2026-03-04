# 第二章：Kind 基本觀念與安裝

## 目錄

1. [什麼是 Kind？](#1-什麼是-kind)
2. [Kind vs 其他本地 K8s 方案](#2-kind-vs-其他本地-k8s-方案)
3. [安裝 Kind](#3-安裝-kind)
4. [安裝 kubectl](#4-安裝-kubectl)
5. [建立叢集](#5-建立叢集)
6. [叢集管理操作](#6-叢集管理操作)
7. [多節點叢集](#7-多節點叢集)
8. [載入映像檔到 Kind](#8-載入映像檔到-kind)
9. [實作練習](#9-實作練習)

---

## 1. 什麼是 Kind？

**Kind**（**K**ubernetes **in** **D**ocker）是一個使用 Docker 容器作為「節點」來執行本地 Kubernetes 叢集的工具。

```
Kind 運作原理

┌─────────────────────────────────────────┐
│              你的電腦 (Host)             │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │         Docker Engine            │   │
│  │                                  │   │
│  │  ┌────────────┐ ┌────────────┐  │   │
│  │  │ Container  │ │ Container  │  │   │
│  │  │ (Control   │ │ (Worker    │  │   │
│  │  │  Plane)    │ │  Node)     │  │   │
│  │  │            │ │            │  │   │
│  │  │ ┌────────┐ │ │ ┌────────┐│  │   │
│  │  │ │kubelet │ │ │ │kubelet ││  │   │
│  │  │ │etcd    │ │ │ │kube-   ││  │   │
│  │  │ │api-srv │ │ │ │proxy   ││  │   │
│  │  │ └────────┘ │ │ └────────┘│  │   │
│  │  └────────────┘ └────────────┘  │   │
│  │                                  │   │
│  └──────────────────────────────────┘   │
│                                         │
│  kubectl ──────▶ K8s API Server         │
│                                         │
└─────────────────────────────────────────┘
```

### Kind 的特色

- **輕量快速**：數十秒內即可建立 K8s 叢集
- **多節點支援**：可模擬多個 Control Plane 與 Worker Node
- **使用 Docker**：只要有 Docker 就能執行，無需額外虛擬化軟體
- **符合標準**：執行的是完整的 Kubernetes，API 完全相容
- **適合開發與測試**：是 Kubernetes 官方推薦的本地開發工具之一

---

## 2. Kind vs 其他本地 K8s 方案

| 特性 | Kind | Minikube | K3s | MicroK8s |
|------|------|----------|-----|----------|
| 底層技術 | Docker 容器 | VM / Docker | 輕量 K8s | Snap 套件 |
| 多節點 | 支援 | 有限支援 | 支援 | 支援 |
| 資源需求 | 低 | 中～高 | 低 | 低～中 |
| 啟動速度 | 快（秒級） | 慢（分鐘級） | 快 | 中 |
| 作業系統 | Linux/macOS/Windows | Linux/macOS/Windows | Linux | Linux |
| 主要用途 | 開發/測試/CI | 本地開發 | 邊緣/IoT/開發 | 開發/邊緣 |
| K8s 版本 | 可選擇 | 可選擇 | 固定（輕量版） | 可選擇 |

**建議使用 Kind 的場景**：
- 本地開發與測試 Kubernetes 應用
- CI/CD pipeline 中的整合測試
- 學習 Kubernetes 觀念與操作
- 需要多節點叢集的情境

---

## 3. 安裝 Kind

### 前置條件

- 已安裝 Docker（參考[第一章](../01-docker-basics/)）
- Docker Daemon 正在執行

### Linux

```bash
# 下載 Kind 二進位檔
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-arm64

# 設定執行權限並移動到 PATH
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# 驗證安裝
kind --version
```

### macOS

```bash
# 使用 Homebrew
brew install kind

# 或手動下載
# Intel Mac
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-darwin-amd64
# Apple Silicon Mac
[ $(uname -m) = arm64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-darwin-arm64

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# 驗證安裝
kind --version
```

### Windows

```powershell
# 使用 Chocolatey
choco install kind

# 或使用 Scoop
scoop install kind

# 驗證安裝
kind --version
```

---

## 4. 安裝 kubectl

`kubectl` 是 Kubernetes 的命令列工具，用來與 K8s 叢集互動。

### Linux

```bash
# 下載最新版本
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# 安裝
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# 驗證
kubectl version --client
```

### macOS

```bash
# 使用 Homebrew
brew install kubectl

# 驗證
kubectl version --client
```

### Windows

```powershell
# 使用 Chocolatey
choco install kubernetes-cli

# 驗證
kubectl version --client
```

### 設定自動補全（建議）

```bash
# Bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc

# Zsh
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'alias k=kubectl' >> ~/.zshrc
source ~/.zshrc
```

---

## 5. 建立叢集

### 建立預設叢集（單節點）

```bash
# 建立叢集（預設名稱為 "kind"）
kind create cluster

# 建立指定名稱的叢集
kind create cluster --name my-cluster

# 確認叢集已建立
kind get clusters

# 確認 kubectl 可以連接叢集
kubectl cluster-info --context kind-my-cluster
kubectl get nodes
```

### 建立指定 K8s 版本的叢集

```bash
# 使用特定 Kubernetes 版本
kind create cluster --image kindest/node:v1.31.0
```

---

## 6. 叢集管理操作

```bash
# 列出所有 Kind 叢集
kind get clusters

# 查看叢集節點（Docker 容器）
docker ps

# 切換 kubectl context（多叢集時）
kubectl config get-contexts
kubectl config use-context kind-my-cluster

# 刪除叢集
kind delete cluster --name my-cluster

# 刪除所有叢集
kind delete clusters --all

# 匯出叢集日誌（除錯用）
kind export logs --name my-cluster ./kind-logs
```

---

## 7. 多節點叢集

Kind 支援建立多節點的 K8s 叢集，模擬真實生產環境。

### 叢集設定檔

參考 [kind-config.yaml](./kind-config.yaml)：

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  # Control Plane 節點
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      # 將主機的 80 埠對應到節點的 80 埠
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      # 將主機的 443 埠對應到節點的 443 埠
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  # Worker 節點 1
  - role: worker
  # Worker 節點 2
  - role: worker
```

### 使用設定檔建立叢集

```bash
# 使用設定檔建立多節點叢集
kind create cluster --name multi-node --config kind-config.yaml

# 確認節點
kubectl get nodes
# NAME                       STATUS   ROLES           AGE   VERSION
# multi-node-control-plane   Ready    control-plane   1m    v1.31.0
# multi-node-worker          Ready    <none>          1m    v1.31.0
# multi-node-worker2         Ready    <none>          1m    v1.31.0
```

### 多 Control Plane（HA 叢集）

```yaml
# kind-ha-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: control-plane
  - role: control-plane
  - role: worker
  - role: worker
  - role: worker
```

---

## 8. 載入映像檔到 Kind

Kind 叢集執行在 Docker 內部，無法直接存取本機的 Docker 映像檔。需要手動載入。

```bash
# 先在本機建構映像檔
docker build -t my-app:1.0 ./app

# 載入映像檔到 Kind 叢集
kind load docker-image my-app:1.0 --name my-cluster

# 載入多個映像檔
kind load docker-image my-app:1.0 my-app:2.0 --name my-cluster

# 確認映像檔已載入（進入 Kind 節點查看）
docker exec -it my-cluster-control-plane crictl images
```

```
映像檔載入流程

  Host Docker           Kind Cluster
┌─────────────┐      ┌─────────────────┐
│ my-app:1.0  │      │  Kind Node      │
│             │ ───▶ │  ┌───────────┐  │
│ docker      │ kind │  │ my-app:1.0│  │
│ images      │ load │  └───────────┘  │
└─────────────┘      └─────────────────┘
```

> **注意**：載入到 Kind 的映像檔，在 K8s manifest 中應設定 `imagePullPolicy: Never` 或 `imagePullPolicy: IfNotPresent`，避免 K8s 嘗試從外部 Registry 拉取。

---

## 9. 實作練習

### 練習 1：建立與管理叢集

```bash
# 建立一個名為 "lab" 的單節點叢集
kind create cluster --name lab

# 確認叢集
kind get clusters
kubectl get nodes

# 查看叢集資訊
kubectl cluster-info

# 刪除叢集
kind delete cluster --name lab
```

### 練習 2：建立多節點叢集

```bash
# 使用提供的設定檔建立叢集
kind create cluster --name multi --config kind-config.yaml

# 確認所有節點
kubectl get nodes -o wide

# 查看節點詳細資訊
kubectl describe node multi-control-plane

# 完成後清理
kind delete cluster --name multi
```

### 練習 3：載入自訂映像檔

```bash
# 建立叢集
kind create cluster --name app-test

# 建構範例應用映像檔
cd ../01-docker-basics/app
docker build -t my-node-app:1.0 .

# 載入到 Kind
kind load docker-image my-node-app:1.0 --name app-test

# 在 K8s 中使用此映像檔（下一章會詳細介紹）
kubectl run my-app --image=my-node-app:1.0 --image-pull-policy=Never

# 確認 Pod 正在執行
kubectl get pods

# 清理
kind delete cluster --name app-test
```

---

## 常用指令速查表

```bash
# === Kind 叢集管理 ===
kind create cluster --name <name>              # 建立叢集
kind create cluster --config <file>            # 使用設定檔建立
kind get clusters                              # 列出叢集
kind delete cluster --name <name>              # 刪除叢集
kind delete clusters --all                     # 刪除所有叢集
kind load docker-image <image> --name <name>   # 載入映像檔
kind export logs --name <name> <dir>           # 匯出日誌

# === kubectl 基本 ===
kubectl cluster-info                           # 叢集資訊
kubectl get nodes                              # 列出節點
kubectl config get-contexts                    # 列出所有 context
kubectl config use-context kind-<name>         # 切換 context
```

---

上一章：[01 - Docker 基本觀念與安裝](../01-docker-basics/) ｜ 下一章：[03 - Kubernetes 觀念與基本操作](../03-k8s-basics/)
