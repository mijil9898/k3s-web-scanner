# Mijil Platform: Hệ Thống Phân Tích Mã Độc Toàn Diện

Mijil Platform là một nền tảng phân tích mã độc tĩnh (Static Malware Analysis) hoàn chỉnh, được thiết kế với kiến trúc Microservices và triển khai hoàn toàn tự động trên Kubernetes (K3s/K3d). Hệ thống kết hợp khả năng mở rộng của Kubernetes, bảo mật của Cloudflare Tunnel, và giao diện web hiện đại để cung cấp cái nhìn chi tiết về các tệp đáng ngờ.

---

## 🏗 Kiến Trúc Hệ Thống (Architecture)

Hệ thống được chia thành các thành phần (services) chạy độc lập, giao tiếp với nhau qua mạng nội bộ của Kubernetes:

- **Frontend (Nginx + HTML/CSS/JS)**: Giao diện người dùng web chuyên nghiệp với chủ đề Cybersecurity. Hỗ trợ đa ngôn ngữ (EN/VI), Dark Mode, và hiển thị trực quan quy trình phân tích (Pipeline) cùng báo cáo chi tiết.
- **Malware Analyzer (Python/Flask + Gunicorn)**: Trái tim của hệ thống. Nhận file từ Frontend, thực hiện băm hash, phân tích cấu trúc PE, trích xuất chuỗi IoC, quét YARA rules, tra cứu VirusTotal, ánh xạ MITRE ATT&CK và xuất điểm rủi ro. Báo cáo lưu trữ qua Persistent Volume (PVC).
- **Backend (Node.js/Express)**: Ứng dụng Backend API dùng để mở rộng thêm các nghiệp vụ (quản lý người dùng, lịch sử phân tích, logs,...).
- **Database (PostgreSQL)**: Cơ sở dữ liệu lưu trữ dữ liệu của Backend (được cấu hình bằng StatefulSet).
- **Cloudflare Tunnel (cloudflared)**: Đường hầm bảo mật giúp hệ thống nội bộ có thể được truy cập trực tiếp từ Internet thông qua URL public (`trycloudflare.com` hoặc domain thật) mà không cần cấu hình NAT, Port Forwarding, hay mở firewall.
- **K3s / K3d**: Cụm Kubernetes hạng nhẹ quản lý toàn bộ vòng đời (scaling, self-healing) của các pods.

---

## 🛠 Yêu Cầu Hệ Thống (Prerequisites)

Để chạy Mijil Platform ở môi trường Local Development, bạn cần:
1. **Docker / Docker Desktop**: Để chạy container.
2. **K3d**: Tạo cụm K3s trong Docker (`curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash`).
3. **kubectl**: CLI tương tác với Kubernetes.
4. **Helm v3**: Package manager cho K8s để cài đặt chart.
5. **WSL (Windows Subsystem for Linux) hoặc Linux/macOS**.

---

## 🚀 Hướng Dẫn Khởi Động Nhanh (Quick Start)

Mijil cung cấp một script duy nhất để cấu hình, build Docker image, import vào cụm, và cài đặt Helm Chart.

### Bước 1: Khởi động toàn bộ hệ thống
Mở terminal và chạy lệnh:
```bash
bash scripts/start-system.sh
```

**Quá trình này sẽ diễn ra:**
1. Khởi động cụm `mijil-dev` bằng k3d.
2. Build 3 Docker images: `mijil-frontend`, `mijil-backend`, `malware-analyzer`.
3. Import images vào K3d để cluster có thể lấy được không cần Registry.
4. Tạo namespace `mijil` và các Secret mặc định.
5. `helm upgrade --install` thư mục `helm-charts/mijil-chart`.

### Bước 2: Truy cập Giao diện Web
Khi script kết thúc, Cloudflare Quick Tunnel sẽ tự động sinh ra một public URL có dạng `https://<random-words>.trycloudflare.com`.
Bạn có thể xem URL này ở cuối output của log, hoặc chạy lệnh sau để lấy URL mới nhất:
```bash
kubectl -n mijil logs -l app=cloudflared --tail=100 | grep trycloudflare.com
```
👉 **Mở URL trên trình duyệt và trải nghiệm.**

---

## 📂 Cấu Trúc Mã Nguồn

```text
k3s-mijil-platform/
├── apps/
│   ├── frontend/         # Nginx web server, UI HTML tĩnh
│   ├── backend/          # Node.js Express API
│   ├── database/         # Postgres script khởi tạo (nếu không dùng Helm DB)
│   └── malware-analyzer/ # Lõi phân tích tĩnh bằng Python
├── helm-charts/
│   └── mijil-chart/      # Chart chính cấu hình K8s Resources (Deployments, Services, PVC)
├── k8s-manifests/        # (Tuỳ chọn) Các file manifest rời cho namespace, ingress
└── scripts/
    ├── start-system.sh   # Khởi động cụm + gọi deploy
    ├── deploy-all.sh     # Build images + Helm install
    ├── stop-system.sh    # Dừng cụm
    └── URL.sh            # Script hỗ trợ tìm URL truy cập
```

---

## ⚙ Cấu Hình Nâng Cao: Tên Miền Tùy Chỉnh (Named Tunnel)

Nếu bạn không muốn dùng URL ngẫu nhiên của `trycloudflare.com`, bạn có thể kết nối với Cloudflare Zero Trust để dùng domain thật.

1. Đăng nhập Cloudflare trên máy tính: `cloudflared tunnel login`.
2. Tạo Tunnel: `cloudflared tunnel create mijil-tunnel`.
3. Tạo CNAME DNS: `cloudflared tunnel route dns mijil-tunnel analyzer.yourdomain.com`.
4. Export credentials ra file `credentials.json` và đưa vào Kubernetes dưới dạng secret.
5. Cập nhật file `helm-charts/mijil-chart/values.yaml` (hoặc cấu hình file configmap) để truyền đúng `tunnel_id` và `credentials-file`.

---

## 🐛 Troubleshooting & Gỡ Lỗi

Dưới đây là một số lệnh `kubectl` hữu ích để xem trạng thái hệ thống:

**Kiểm tra tất cả các pod có đang chạy (Running) không:**
```bash
kubectl get pods -n mijil
```

**Xem log của Malware Analyzer:**
```bash
kubectl logs -l app=malware-analyzer -n mijil -f
```

**Xem log kết nối của Cloudflare Tunnel:**
```bash
kubectl logs -l app=cloudflared -n mijil -f
```

**Khởi động lại một service (VD: frontend) sau khi build image mới:**
```bash
kubectl rollout restart deployment frontend -n mijil
```

---

*Hệ thống được thiết kế để dễ dàng CI/CD, tự động phục hồi (Self-healing), và mở rộng quy mô tuỳ nhu cầu (HPA).*
