# 第一章：Docker 基本觀念與安裝

## 目錄

1. [什麼是容器（Container）？](#1-什麼是容器container)
2. [Docker 簡介](#2-docker-簡介)
3. [Docker 安裝](#3-docker-安裝)
4. [Docker 核心觀念](#4-docker-核心觀念)
5. [Docker 基本操作](#5-docker-基本操作)
6. [Dockerfile 撰寫](#6-dockerfile-撰寫)
7. [實作練習](#7-實作練習)

---

## 1. 什麼是容器（Container）？

### 傳統部署 vs 容器化部署

```
傳統部署                          容器化部署
┌─────────────────────┐          ┌─────────────────────┐
│      App A  App B   │          │  ┌─App A┐  ┌─App B┐ │
│    ┌───────────────┐│          │  │ Libs  │  │ Libs  ││
│    │   Libraries   ││          │  │ Deps  │  │ Deps  ││
│    ├───────────────┤│          │  └───────┘  └───────┘│
│    │  Guest OS     ││          │  ┌─────────────────┐ │
│    ├───────────────┤│          │  │  Container Engine│ │
│    │  Hypervisor   ││          │  │  (Docker)        │ │
│    ├───────────────┤│          │  ├─────────────────┤ │
│    │  Host OS      ││          │  │  Host OS         │ │
│    ├───────────────┤│          │  ├─────────────────┤ │
│    │  Hardware     ││          │  │  Hardware        │ │
│    └───────────────┘│          │  └─────────────────┘ │
└─────────────────────┘          └─────────────────────┘
     虛擬機器 (VM)                      容器 (Container)
```

### 容器的核心概念

容器是一種**輕量級的虛擬化技術**，它利用 Linux Kernel 的功能（如 Namespace、Cgroups）來隔離應用程式的執行環境。

| 特性 | 虛擬機器 (VM) | 容器 (Container) |
|------|--------------|-----------------|
| 啟動時間 | 分鐘級 | 秒級 |
| 資源佔用 | GB 級 | MB 級 |
| 隔離層級 | 作業系統層級 | 程序層級 |
| 效能 | 有虛擬化開銷 | 接近原生效能 |
| 可攜性 | 較差 | 極佳 |

### 為什麼開發者需要容器？

- **環境一致性**：「在我的電腦上可以跑」的問題不再出現
- **快速部署**：秒級啟動，快速迭代
- **版本控制**：映像檔可以版本化管理
- **微服務架構**：每個服務獨立容器化，解耦合
- **CI/CD 整合**：標準化的建構與部署流程

---

## 2. Docker 簡介

Docker 是目前最流行的容器化平台，提供了完整的工具鏈來建立、發布與執行容器。

### Docker 架構

```
┌──────────────────────────────────────────┐
│              Docker Client               │
│         (docker CLI / Docker Desktop)    │
└──────────────┬───────────────────────────┘
               │  REST API
┌──────────────▼───────────────────────────┐
│            Docker Daemon (dockerd)        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │ Images   │ │Containers│ │ Networks │ │
│  └──────────┘ └──────────┘ └──────────┘ │
│  ┌──────────┐                            │
│  │ Volumes  │                            │
│  └──────────┘                            │
└──────────────────────────────────────────┘
               │
┌──────────────▼───────────────────────────┐
│          Container Registry              │
│       (Docker Hub / Private Registry)    │
└──────────────────────────────────────────┘
```

### 核心元件

| 元件 | 說明 |
|------|------|
| **Docker Daemon** | 背景服務，管理映像檔、容器、網路、儲存 |
| **Docker Client** | 使用者操作介面（CLI 指令） |
| **Docker Image** | 唯讀的應用程式模板（藍圖） |
| **Docker Container** | Image 的執行實例（運行中的應用） |
| **Docker Registry** | 儲存與分享 Image 的倉庫 |

---

## 3. Docker 安裝

### Linux（Ubuntu/Debian）

```bash
# 更新套件索引
sudo apt-get update

# 安裝必要的套件
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 新增 Docker 官方 GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 設定 Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安裝 Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 將目前使用者加入 docker 群組（免 sudo）
sudo usermod -aG docker $USER

# 重新登入後驗證安裝
docker --version
docker run hello-world
```

### macOS

```bash
# 使用 Homebrew 安裝 Docker Desktop
brew install --cask docker

# 啟動 Docker Desktop 應用程式後驗證
docker --version
docker run hello-world
```

### Windows

1. 下載 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. 執行安裝程式，啟用 WSL 2 後端
3. 重新啟動電腦
4. 開啟 Docker Desktop
5. 在 PowerShell 或 CMD 中驗證：

```powershell
docker --version
docker run hello-world
```

### 驗證安裝成功

```bash
# 確認 Docker 版本
docker --version

# 確認 Docker 服務正在執行
docker info

# 執行測試容器
docker run hello-world
```

如果看到 "Hello from Docker!" 的訊息，表示安裝成功。

---

## 4. Docker 核心觀念

### Image（映像檔）

映像檔是一個**唯讀的模板**，包含了執行應用程式所需的一切：程式碼、執行環境、系統工具、程式庫和設定。

```
映像檔的分層結構（Layer）

┌─────────────────────────┐
│  Layer 4: App Code      │  ← 你的應用程式
├─────────────────────────┤
│  Layer 3: npm install   │  ← 依賴套件
├─────────────────────────┤
│  Layer 2: Node.js       │  ← 執行環境
├─────────────────────────┤
│  Layer 1: Ubuntu        │  ← 基礎作業系統
└─────────────────────────┘
```

- 每一層是前一層的差異（差分）
- 各層是唯讀的，可以被多個映像檔共用
- 啟動容器時，會在最上方加一個**可寫入層（Writable Layer）**

### Container（容器）

容器是映像檔的**執行實例**。你可以從同一個映像檔啟動多個容器。

```bash
# 從 nginx 映像檔啟動一個容器
docker run -d --name my-nginx -p 8080:80 nginx
```

### Volume（儲存卷）

容器預設是**暫時性的**——容器刪除後，資料就消失了。Volume 讓你將資料持久化。

```bash
# 建立並掛載 Volume
docker run -d -v my-data:/app/data my-app
```

### Network（網路）

Docker 提供多種網路模式讓容器之間通訊：

| 模式 | 說明 |
|------|------|
| bridge | 預設模式，容器透過虛擬橋接器通訊 |
| host | 容器直接使用主機網路 |
| none | 無網路連線 |

---

## 5. Docker 基本操作

### 映像檔操作

```bash
# 從 Registry 拉取映像檔
docker pull nginx
docker pull node:20-alpine

# 列出本地映像檔
docker images

# 刪除映像檔
docker rmi nginx

# 搜尋 Docker Hub 上的映像檔
docker search nginx
```

### 容器操作

```bash
# 啟動容器（前景模式）
docker run nginx

# 啟動容器（背景模式）
docker run -d --name my-nginx nginx

# 啟動容器並進入互動式 Shell
docker run -it ubuntu bash

# 列出執行中的容器
docker ps

# 列出所有容器（包含已停止）
docker ps -a

# 停止容器
docker stop my-nginx

# 啟動已停止的容器
docker start my-nginx

# 重新啟動容器
docker restart my-nginx

# 刪除容器
docker rm my-nginx

# 強制刪除執行中的容器
docker rm -f my-nginx

# 查看容器日誌
docker logs my-nginx
docker logs -f my-nginx  # 即時追蹤

# 進入執行中的容器
docker exec -it my-nginx bash

# 查看容器詳細資訊
docker inspect my-nginx
```

### Port Mapping（埠映射）

```bash
# 將主機的 8080 埠對應到容器的 80 埠
docker run -d -p 8080:80 --name web nginx

# 存取方式：在瀏覽器開啟 http://localhost:8080
```

```
Port Mapping 示意圖

    Host (你的電腦)              Container (容器)
  ┌─────────────────┐        ┌─────────────────┐
  │                 │        │                 │
  │  localhost:8080 ├───────▶│ container:80    │
  │                 │        │  (nginx)        │
  │                 │        │                 │
  └─────────────────┘        └─────────────────┘
```

### 環境變數

```bash
# 傳遞環境變數
docker run -d -e MY_VAR=hello -e DB_HOST=localhost my-app

# 從檔案載入環境變數
docker run -d --env-file .env my-app
```

---

## 6. Dockerfile 撰寫

Dockerfile 是一個文字檔案，定義了如何建立 Docker 映像檔。

### 常用指令

| 指令 | 說明 | 範例 |
|------|------|------|
| `FROM` | 指定基礎映像檔 | `FROM node:20-alpine` |
| `WORKDIR` | 設定工作目錄 | `WORKDIR /app` |
| `COPY` | 複製檔案到映像檔 | `COPY . .` |
| `RUN` | 執行指令（建構時） | `RUN npm install` |
| `EXPOSE` | 宣告容器埠號 | `EXPOSE 3000` |
| `CMD` | 容器啟動指令 | `CMD ["node", "server.js"]` |
| `ENV` | 設定環境變數 | `ENV NODE_ENV=production` |
| `ENTRYPOINT` | 容器進入點 | `ENTRYPOINT ["python"]` |

### 範例 Dockerfile（Node.js 應用）

參考 [app/Dockerfile](./app/Dockerfile)：

```dockerfile
# 使用 Node.js Alpine 作為基礎映像檔（輕量）
FROM node:20-alpine

# 設定工作目錄
WORKDIR /app

# 先複製 package.json（利用 Docker 快取機制）
COPY package.json package-lock.json* ./

# 安裝依賴
RUN npm install --production

# 複製應用程式原始碼
COPY . .

# 宣告容器對外的埠
EXPOSE 3000

# 啟動應用程式
CMD ["node", "server.js"]
```

### 建構映像檔

```bash
# 建構映像檔
docker build -t my-app:1.0 .

# 從指定 Dockerfile 建構
docker build -f Dockerfile.dev -t my-app:dev .

# 建構時不使用快取
docker build --no-cache -t my-app:1.0 .
```

### Dockerfile 最佳實踐

1. **使用精簡的基礎映像檔**：優先選擇 `alpine` 版本
2. **善用分層快取**：將不常變動的指令放在前面
3. **使用 .dockerignore**：排除不需要的檔案
4. **不要以 root 執行**：使用 `USER` 指令切換使用者
5. **一個容器一個程序**：遵循單一職責原則

### .dockerignore 範例

```
node_modules
npm-debug.log
.git
.env
*.md
```

---

## 7. 實作練習

### 練習 1：建構與執行範例應用程式

```bash
# 進入範例應用目錄
cd app/

# 建構映像檔
docker build -t my-node-app:1.0 .

# 執行容器
docker run -d -p 3000:3000 --name my-app my-node-app:1.0

# 測試
curl http://localhost:3000

# 查看日誌
docker logs my-app

# 清理
docker rm -f my-app
```

### 練習 2：容器基本操作

```bash
# 啟動一個 nginx 容器
docker run -d --name web -p 8080:80 nginx

# 確認容器正在執行
docker ps

# 進入容器內部
docker exec -it web bash

# 在容器內查看 nginx 設定
cat /etc/nginx/nginx.conf

# 離開容器
exit

# 停止並刪除容器
docker stop web && docker rm web
```

### 練習 3：使用 Volume 持久化資料

```bash
# 建立一個帶有 Volume 的容器
docker run -d --name db \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=mysecretpassword \
  postgres:16-alpine

# 確認 Volume 已建立
docker volume ls

# 停止並刪除容器
docker stop db && docker rm db

# Volume 仍然存在
docker volume ls

# 清理 Volume
docker volume rm db-data
```

---

## 常用指令速查表

```bash
# === 映像檔 ===
docker pull <image>          # 拉取映像檔
docker images                # 列出映像檔
docker rmi <image>           # 刪除映像檔
docker build -t <tag> .      # 建構映像檔

# === 容器 ===
docker run <image>           # 執行容器
docker ps                    # 列出執行中容器
docker ps -a                 # 列出所有容器
docker stop <container>      # 停止容器
docker start <container>     # 啟動容器
docker rm <container>        # 刪除容器
docker logs <container>      # 查看日誌
docker exec -it <c> bash     # 進入容器

# === 系統 ===
docker system df             # 查看磁碟使用
docker system prune          # 清理未使用資源
```

---

下一章：[02 - Kind 基本觀念與安裝](../02-kind-basics/)
