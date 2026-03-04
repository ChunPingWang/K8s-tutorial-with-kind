# 第八章：CKAD — 服務與網路 (Services and Networking)

> **CKAD 考試佔比：20%**

## 目錄

1. [Service 深入理解](#1-service-深入理解)
2. [DNS 與服務發現](#2-dns-與服務發現)
3. [NetworkPolicy](#3-networkpolicy)
4. [Ingress](#4-ingress)
5. [實作練習](#5-實作練習)

---

## 1. Service 深入理解

### Service 類型總覽

```
Service 暴露方式

ClusterIP        NodePort           LoadBalancer
(叢集內部)       (節點埠)           (雲端負載均衡)

                                   ┌───────────┐
                                   │  Cloud LB │
                                   │  (外部IP) │
                                   └─────┬─────┘
                 ┌───────────┐           │
                 │ NodePort  │     ┌─────▼─────┐
                 │ :30080    │     │ NodePort  │
                 └─────┬─────┘     │ :30080    │
                       │           └─────┬─────┘
┌───────────┐    ┌─────▼─────┐     ┌─────▼─────┐
│ ClusterIP │    │ ClusterIP │     │ ClusterIP │
│ 10.96.x.x│    │ 10.96.x.x│     │ 10.96.x.x│
└─────┬─────┘    └─────┬─────┘     └─────┬─────┘
      │                │                  │
   ┌──▼──┐          ┌──▼──┐           ┌──▼──┐
   │ Pod │          │ Pod │           │ Pod │
   └─────┘          └─────┘           └─────┘
```

### Service 選取機制

Service 透過 `selector` 找到對應的 Pod，並自動建立 Endpoints：

```bash
# 查看 Service 的 Endpoints
kubectl get endpoints -n demo

# 或使用 describe
kubectl describe svc demo-app-service -n demo
# 會顯示 Endpoints: 10.244.1.5:3000, 10.244.2.8:3000, ...

# 排查：如果 Endpoints 為空
# 1. 確認 Pod 有正確的 labels
kubectl get pods -n demo --show-labels
# 2. 確認 Service 的 selector
kubectl get svc demo-app-service -n demo -o yaml | grep -A 2 selector
```

### Headless Service

ClusterIP 設為 `None` 的 Service，DNS 直接回傳 Pod IP 而非 Service IP：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: headless-svc
spec:
  clusterIP: None        # Headless Service
  selector:
    app: my-app
  ports:
    - port: 80
```

---

## 2. DNS 與服務發現

### K8s 內部 DNS 格式

```
Service DNS:
  <service-name>.<namespace>.svc.cluster.local

範例:
  demo-app-service.demo.svc.cluster.local

簡寫（同 namespace）:
  demo-app-service

Pod DNS:
  <pod-ip-dashed>.<namespace>.pod.cluster.local

範例:
  10-244-1-5.demo.pod.cluster.local
```

### DNS 測試

```bash
# 建立測試 Pod
kubectl run dns-test --image=busybox:1.36 --rm -it --restart=Never -n demo -- sh

# 在 Pod 內測試 DNS
nslookup demo-app-service.demo.svc.cluster.local
nslookup kubernetes.default.svc.cluster.local

# 使用 wget 測試連線
wget -qO- http://demo-app-service.demo

# 查看 DNS 設定
cat /etc/resolv.conf
```

---

## 3. NetworkPolicy

NetworkPolicy 控制 Pod 之間的**網路流量**。

### 重要概念

- 沒有 NetworkPolicy → 所有流量都允許
- 有 NetworkPolicy → 只允許符合規則的流量
- NetworkPolicy 是 Namespace 層級的

```
NetworkPolicy 流量控制

預設（無 Policy）：全部允許
┌─────┐    ┌─────┐    ┌─────┐
│ Pod │◄──▶│ Pod │◄──▶│ Pod │
└─────┘    └─────┘    └─────┘

設定 deny-all 後：全部封鎖
┌─────┐    ┌─────┐    ┌─────┐
│ Pod │ ✗  │ Pod │ ✗  │ Pod │
└─────┘    └─────┘    └─────┘

設定 allow 規則：精確控制
┌──────────┐         ┌─────────┐
│ frontend │────✓───▶│ backend │
│ role:fe  │         │ app:demo│
└──────────┘         └─────────┘
       ✗                  ✗
┌──────────┐         ┌─────────┐
│ attacker │────✗───▶│ database│
└──────────┘         └─────────┘
```

### 選取器類型

| 選取器 | 說明 | 範例 |
|--------|------|------|
| `podSelector` | 選取特定 Pod | `matchLabels: {app: frontend}` |
| `namespaceSelector` | 選取特定 Namespace | `matchLabels: {env: prod}` |
| `ipBlock` | 選取 IP 範圍 | `cidr: 10.0.0.0/8` |

### 操作指令

```bash
# 建立 deny-all 規則
kubectl apply -f manifests/network-policy-deny-all.yaml

# 建立允許規則
kubectl apply -f manifests/network-policy-allow-app.yaml

# 查看 NetworkPolicy
kubectl get networkpolicy -n demo
kubectl describe networkpolicy allow-frontend-to-backend -n demo

# 刪除 NetworkPolicy
kubectl delete networkpolicy deny-all-ingress -n demo
```

### YAML 範例

參考：
- [manifests/network-policy-deny-all.yaml](./manifests/network-policy-deny-all.yaml)
- [manifests/network-policy-allow-app.yaml](./manifests/network-policy-allow-app.yaml)

---

## 4. Ingress

Ingress 提供 HTTP/HTTPS 路由，將外部流量導向叢集內的 Service。

### Ingress 架構

```
Ingress 路由

外部請求                    Ingress Controller              Service
                            (nginx / traefik)
                           ┌─────────────────┐
 demo.local/api  ─────────▶│ path: /api      ├────▶ api-service
                           │                 │
 demo.local/     ─────────▶│ path: /         ├────▶ frontend-service
                           │                 │
 admin.local/    ─────────▶│ host: admin     ├────▶ admin-service
                           └─────────────────┘
```

### pathType 類型

| 類型 | 說明 | 範例 |
|------|------|------|
| `Exact` | 精確匹配 | `/api` 只匹配 `/api` |
| `Prefix` | 前綴匹配 | `/api` 匹配 `/api`, `/api/v1`, `/api/users` |

### Kind 安裝 Ingress Controller

```bash
# 安裝 nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 等待就緒
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### 操作指令

```bash
# 建立 Ingress
kubectl apply -f manifests/ingress.yaml

# 查看 Ingress
kubectl get ingress -n demo
kubectl describe ingress demo-ingress -n demo

# 測試（需要先設定 /etc/hosts 或使用 curl -H）
curl -H "Host: demo.local" http://localhost/
curl -H "Host: demo.local" http://localhost/api
```

### YAML 範例

參考 [manifests/ingress.yaml](./manifests/ingress.yaml)

---

## 5. 實作練習

### 練習 1：Service 與 DNS 測試

```bash
# 確保有 Deployment 和 Service 運行
kubectl apply -f ../03-k8s-basics/manifests/namespace.yaml
kubectl apply -f ../03-k8s-basics/manifests/configmap.yaml
kubectl apply -f ../03-k8s-basics/manifests/deployment.yaml
kubectl apply -f ../03-k8s-basics/manifests/service-clusterip.yaml

# DNS 測試
kubectl run dns-test --image=busybox:1.36 --rm -it --restart=Never -n demo -- \
  nslookup demo-app-service.demo.svc.cluster.local

# 連通性測試
kubectl run curl-test --image=busybox:1.36 --rm -it --restart=Never -n demo -- \
  wget -qO- http://demo-app-service.demo
```

### 練習 2：NetworkPolicy 測試

```bash
# 建立 deny-all
kubectl apply -f manifests/network-policy-deny-all.yaml

# 測試被阻擋（需要支援 NetworkPolicy 的 CNI）
kubectl run test-blocked --image=busybox:1.36 --rm -it --restart=Never -n demo -- \
  wget -qO- --timeout=3 http://demo-app-service.demo

# 建立允許規則
kubectl apply -f manifests/network-policy-allow-app.yaml

# 以正確的 label 測試
kubectl run test-allowed --image=busybox:1.36 --rm -it --restart=Never -n demo \
  --labels="role=frontend" -- \
  wget -qO- --timeout=3 http://demo-app-service.demo
```

### 練習 3：Ingress 設定

```bash
# 安裝 ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 等待就緒
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 建立 Ingress
kubectl apply -f manifests/ingress.yaml

# 測試
curl -H "Host: demo.local" http://localhost/
```

---

上一章：[07 - CKAD 設定與安全](../07-ckad-configuration/)
