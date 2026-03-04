# Kubernetes 教育訓練教材 — 使用 Kind 實戰

> 適用對象：程式開發者（具備基本 Linux 指令操作能力）

本教材從 Docker 基礎觀念出發，逐步引導至使用 Kind 建立本地 Kubernetes 叢集，最終掌握 K8s 核心觀念與基本操作。

---

## 課程大綱

| 章節 | 主題 | 內容概述 |
|------|------|----------|
| [01-docker-basics](./01-docker-basics/) | Docker 基本觀念與安裝 | Container 觀念、Docker 安裝、映像檔建立、容器操作 |
| [02-kind-basics](./02-kind-basics/) | Kind 基本觀念與安裝 | Kind 簡介、安裝方式、叢集建立與管理 |
| [03-k8s-basics](./03-k8s-basics/) | Kubernetes 觀念與基本操作 | K8s 架構、Pod / Deployment / Service 等核心資源操作 |

---

## 先備條件

- 作業系統：Linux / macOS / Windows（建議使用 Linux 或 macOS）
- 已安裝 [Git](https://git-scm.com/)
- 具備基本終端機（Terminal）操作能力
- 建議記憶體 8GB 以上

---

## 學習路徑

```
Docker 基礎        Kind 本地叢集        Kubernetes 操作
┌──────────┐      ┌──────────┐        ┌──────────────┐
│ Container│      │ Kind     │        │ Pod          │
│ Image    │ ──▶  │ Cluster  │  ──▶   │ Deployment   │
│ Dockerfile│     │ kubectl  │        │ Service      │
│ Registry │      │ 多節點    │        │ ConfigMap    │
└──────────┘      └──────────┘        │ Namespace    │
                                      └──────────────┘
```

---

## 快速開始

```bash
# 1. Clone 本教材
git clone <repository-url>
cd K8s-tutorial-with-kind

# 2. 從第一章開始
cd 01-docker-basics
```

---

## 授權

本教材僅供教育訓練使用。
