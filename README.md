# k3s-portfolio-platform — Hướng dẫn sản xuất (Production)

Tài liệu này mô tả cách triển khai, cấu hình, bảo mật và vận hành ứng dụng "k3s-portfolio-platform" ở môi trường production (hoặc môi trường dev/k3s với các best-practices tương tự).

Nội dung chính:
- Tổng quan kiến trúc
- Yêu cầu và chuẩn bị môi trường
- Triển khai bằng k3d (local dev) hoặc k3s (production)
- Cloudflare Tunnel: Quick Tunnel vs Named Tunnel
- Quản lý secret và cấu hình bảo mật
- Helm chart và manifest chính
- Script tự động (start/stop/deploy)
- CI/CD (GitHub Actions)
- Khắc phục sự cố thường gặp
- Bước tiếp theo đề xuất

---

## 1. Tổng quan kiến trúc

Ứng dụng được tách thành các thành phần chính:
- `malware-analyzer`: ứng dụng backend (Node.js/TypeScript) để phân tích mẫu
- `database`: Postgres
- `frontend`: giao diện (nếu có)
- `cloudflared`: Cloudflare Tunnel để che phủ origin và cung cấp truy cập an toàn

Triển khai chính được quản lý bằng Helm chart ở `helm-charts/portfolio-chart`.

## 2. Yêu cầu & Chuẩn bị

- Kubernetes cluster: k3s (production) hoặc k3d (local dev).
- `kubectl`, `helm`, `k3d` (nếu dùng k3d), `docker`/`podman`.
- (Tùy chọn) `cloudflared` CLI để tạo Named Tunnel và login vào Cloudflare.
- Quyền truy cập để tạo Secret trong namespace `portfolio`.

## 3. Triển khai nhanh (Local dev với k3d)

1. Tạo/start cluster k3d (ví dụ):

```bash
# tạo cluster (chỉ lần đầu)
k3d cluster create portfolio-dev --servers 1 --agents 0

# hoặc start nếu đã tồn tại
k3d cluster start portfolio-dev
```

2. Chạy script khởi động tổng hợp (nếu cần):

```bash
cd k3s-portfolio-platform
scripts/start-system.sh
```

3. Triển khai ứng dụng (build image, import vào k3d, helm deploy):

```bash
scripts/deploy-all.sh
```

Script `scripts/deploy-all.sh` sẽ:
- Build image `malware-analyzer:latest` từ `apps/malware-analyzer`.
- Lưu image thành tar và import vào k3d bằng `k3d image import`.
- Tạo `namespace` và `Secret` `malware-secrets` nếu chưa có.
- `helm upgrade --install portfolio` để triển khai chart.

## 4. Triển khai vào production (k3s)

Gợi ý an toàn:
- Không expose Service `LoadBalancer` trực tiếp; sử dụng Cloudflare Tunnel hoặc Cloudflare-proxied DNS.
- Chạy `malware-analyzer` không root trong container (tham khảo Dockerfile đã harden).
- Sử dụng `ClusterIP` cho service, reverse proxy tại edge.

Quy trình cơ bản (manual):

```bash
# Build image và push vào registry private (recommended)
docker build -t ghcr.io/<org>/malware-analyzer:tag apps/malware-analyzer
docker push ghcr.io/<org>/malware-analyzer:tag

# Cập nhật values.yaml để dùng image trên registry
helm upgrade --install portfolio helm-charts/portfolio-chart -n portfolio --create-namespace
```

## 5. Cloudflare Tunnel

Hai lựa chọn để mở truy cập an toàn từ internet vào cluster:

- Quick Tunnel (`cloudflared tunnel --url http://...` hoặc `cloudflared tunnel run`):
  - Miễn phí, nhanh, nhưng URL thay đổi (ephemeral) — hữu dụng cho demo hoặc dev.
  - `scripts/start-system.sh` và `scripts/deploy-all.sh` sẽ cố gắng tìm URL trycloudflare trong logs.

- Named Tunnel (recommended cho production):
  - Tạo tunnel có tên, cần domain đã thêm vào Cloudflare.
  - Quy trình tóm tắt:

```bash
# 1. Đăng nhập trên máy dev (tạo credentials JSON)
cloudflared login

# 2. Tạo tunnel
cloudflared tunnel create <TUNNEL-NAME>

# 3. Route DNS (ví dụ)
cloudflared tunnel route dns <TUNNEL-NAME> app.example.com

# 4. Tạo Kubernetes Secret từ file credentials JSON
kubectl -n portfolio create secret generic cloudflared-tunnel-credentials \
  --from-file=credentials.json=~/.cloudflared/<TUNNEL-ID>.json --dry-run=client -o yaml | kubectl apply -f -

# 5. Áp dụng manifests trong k8s-manifests/cloudflared
kubectl -n portfolio apply -f k8s-manifests/cloudflared/cloudflared-configmap.yaml
kubectl -n portfolio apply -f k8s-manifests/cloudflared/cloudflared-deployment-named.yaml
```

Lưu ý bảo mật: không commit file credentials JSON vào Git.

## 6. Quản lý Secret

Các Secret chính:
- `malware-secrets`: `SECRET_KEY`, `ANALYZE_AUTH_TOKEN`, `VT_API_KEY`, `OTX_API_KEY`.
- `cloudflared-tunnel-credentials`: file JSON credentials của tunnel.

Tạo nhanh `malware-secrets` (nếu chưa có):

```bash
kubectl -n portfolio create secret generic malware-secrets \
  --from-literal=SECRET_KEY=$(openssl rand -hex 32) \
  --from-literal=ANALYZE_AUTH_TOKEN=$(openssl rand -hex 16) \
  --from-literal=VT_API_KEY='' \
  --from-literal=OTX_API_KEY=''
```

## 7. Helm chart

Chart chính nằm ở `helm-charts/portfolio-chart` và gồm templates cho `malware-analyzer`, `database`, `frontend`, `cloudflared`.

Để update image/values:

```bash
helm upgrade --install portfolio helm-charts/portfolio-chart -n portfolio --set malware.image.repository=ghcr.io/<org>/malware-analyzer,malware.image.tag=tag
```

## 8. Scripts quan trọng

- `scripts/start-system.sh`: khởi cluster (k3d) và trigger deploy tổng hợp.
- `scripts/stop-system.sh`: dừng/clean cluster (nếu dùng k3d).
- `scripts/deploy-all.sh`: build image, import vào k3d, tạo secret, helm deploy.
- `apps/malware-analyzer/scripts/deploy-to-k3s.sh`: script deploy chi tiết cho app (nếu cần chạy riêng).
- `scripts/backup.sh`: backup Postgres (lưu vào `backups/`).

Sử dụng:

```bash
# Khởi cluster và deploy
scripts/start-system.sh

# Chỉ deploy (build + helm)
scripts/deploy-all.sh

# Dừng cluster
scripts/stop-system.sh
```

## 9. CI/CD

Pipeline GitHub Actions nằm ở `.github/workflows/ci-cd.yaml` và thực hiện:
- Quét bảo mật bằng Trivy
- Build & push image lên registry (GHCR)
- Upload báo cáo
- (tùy chọn) notification Discord

Lưu ý: workflow có thể yêu cầu secrets như `GHCR_TOKEN`, `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `DISCORD_WEBHOOK`.

## 10. Bảo mật & Hardening (tóm tắt)

- Chạy container non-root, set `HOME=/tmp` nếu cần.
- Dùng immutable images, multi-stage build để giảm attack surface.
- Chỉ mở port ở edge (Cloudflare), dùng WAF và rate-limiting.
- Hạn chế RBAC quyền cho ServiceAccount.
- Không commit credentials vào git; dùng k8s Secret hoặc Vault.

## 11. Khắc phục sự cố thường gặp

- ErrImagePull trên k3d: cần `docker save` -> `k3d image import` hoặc push image vào registry.
- Cloudflared không show URL: kiểm tra logs `kubectl -n portfolio logs -l app=cloudflared`.
- Named Tunnel lỗi: đảm bảo `cloudflared login` đã tạo credentials JSON và Secret đã được tạo.

Ví dụ kiểm tra:

```bash
kubectl -n portfolio get pods
kubectl -n portfolio logs -l app=cloudflared --tail=200
kubectl -n portfolio describe pod <malware-pod>
```

## 12. Bước tiếp theo đề xuất

- Hoàn thiện Named Tunnel cho hostname ổn định (domain + Cloudflare). 
- Đưa image vào registry private (GHCR) và điều chỉnh Helm `values.yaml` dùng image registry.
- Thêm secrets management (Vault / sealed-secrets) cho production.
- Thêm job hardening & container scanning (Trivy) trong CI và blocking policy cho PR.

---

Nếu bạn muốn mình commit file này và push lên `origin/main`, trả lời `Chạy` để mình thực hiện (hoặc mình gửi lệnh để bạn chạy thủ công).
