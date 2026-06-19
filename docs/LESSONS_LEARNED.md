
# Bài học rút ra — Di chuyển Malware Analyzer sang k3s

Tài liệu này tóm tắt các kết luận, quyết định, sự cố và bước tiếp theo được khuyến nghị sau khi di chuyển ứng dụng `malware-analyzer` vào môi trường k3s/k3d và mở truy cập an toàn qua Cloudflare Tunnel.

## Kết quả chính
- Ứng dụng đã được đóng gói thành container với hình ảnh runtime được harden và chạy không phải root.
- Triển khai lên cụm k3d cục bộ và mở ra Internet thông qua Cloudflare Quick Tunnel.
- Đã tích hợp vào Helm chart (`helm-charts/mijil-chart`) để quản lý `malware-analyzer` và `cloudflared` bằng Helm.

## Bài học kỹ thuật quan trọng

- Quick Tunnel vs Named Tunnel
  - Quick Tunnel (`trycloudflare.com`) miễn phí và dễ dùng nhưng hostname là tạm thời và không thể tùy chỉnh.
  - Named Tunnel + DNS cung cấp hostname cố định nhưng cần một domain được thêm vào Cloudflare (bạn phải đổi nameserver tại registrar) và tạo file credentials cho tunnel.

- File credentials của `cloudflared`
  - Named Tunnel yêu cầu file credentials (`~/.cloudflared/<TUNNEL-ID>.json`). KHÔNG commit file này vào Git.
  - Tạo một Kubernetes Secret từ file này trong namespace `mijil` và mount vào Deployment `cloudflared`.

- Vấn đề ảnh Docker trong k3d
  - Lỗi `ErrImagePull` xảy ra khi image chỉ có trong Docker daemon cục bộ nhưng chưa được load vào các node k3d.
  - Dùng `docker save` + `k3d image import` (hoặc push lên registry) để đưa image vào cluster. Repo có `deploy-all.sh` tự động hoá luồng này.

- Hệ thống file chỉ đọc & Gunicorn
  - Gunicorn hoặc một số tiến trình cần thư mục writable (HOME/tmp). Khi rootfs là read-only, cần đặt `HOME=/tmp` và dùng `emptyDir` cho các đường dẫn cần ghi.

- Thư viện native (YARA) và phụ thuộc hệ thống
  - Các binding Python như `yara-python` có thể cần các gói hệ thống khi build. Nếu endpoint health báo `yara_available:false`, kiểm tra và thêm các gói OS cần thiết vào image runtime.

- Secrets & token
  - Nếu secrets bị lộ thì phải xoay (rotate). Lưu `ANALYZE_AUTH_TOKEN` và các API key trong Kubernetes Secret (`malware-secrets`) và tránh in chúng ra logs.

## Bảo mật / Chống DDoS

- Để Cloudflare bảo vệ origin khỏi DDoS và áp dụng WAF, domain phải được thêm vào Cloudflare (Cloudflare là authoritative DNS) HOẶC origin phải kết nối outbound tới Cloudflare qua Cloudflare Tunnel (`cloudflared`) để origin không trực tiếp public.
- Cấu hình khuyến nghị cho môi trường dev trên laptop: giữ origin ở trạng thái private và dùng Named Tunnel. Traffic sẽ đi qua Cloudflare edge trước, nơi Cloudflare xử lý TLS, WAF và mitigations.

## Mẹo vận hành

- Đăng ký domain qua Freenom có thể miễn phí nhưng nhiều tên có giá (premium). Thử các tên dài hơn hoặc thêm hậu tố (ví dụ `duonquan-dev.tk`) nếu tên chính bị tính phí.
- Nếu không thể thêm domain vào Cloudflare, có thể dùng DuckDNS + Let's Encrypt để có HTTPS, nhưng sẽ mất khả năng bảo vệ edge của Cloudflare.
- Dùng các lệnh `kubectl -n mijil rollout status deployment/<name>` và `kubectl logs` để kiểm tra trạng thái pod `cloudflared` và ứng dụng.

## File & script quan trọng
- `deploy-all.sh` — build image, import vào k3d, tạo secrets, và Helm deploy chart `mijil`.
- `helm-charts/mijil-chart/` — template cho `malware-analyzer` và `cloudflared`.
- `k8s-manifests/cloudflared/` — manifest và README cho deployment Named Tunnel.

## Các bước khuyến nghị tiếp theo
1. Quyết định chiến lược domain: tiếp tục thử Freenom hoặc mua domain giá rẻ; thêm domain vào Cloudflare để có hostname ổn định.
2. Nếu dùng Named Tunnel: chạy `cloudflared login` → `cloudflared tunnel create` → tạo k8s Secret từ file credentials → `cloudflared tunnel route dns` → áp dụng `k8s-manifests/cloudflared/*`.
3. Khắc phục việc YARA không khả dụng trong runtime bằng cách thêm các gói hệ thống cần thiết và test local trước khi deploy.
4. Hardening k8s: đảm bảo Services là `ClusterIP`, hạn chế truy cập trực tiếp vào node, bật Cloudflare Firewall rules và rate-limiting.

## Ghi chú cuối
Việc di chuyển này cho thấy cần cân bằng giữa tiện lợi (Quick Tunnel) và độ ổn định cho production (Named Tunnel + Cloudflare DNS). Việc bảo quản credentials và secrets, đảm bảo image có sẵn trong k3d, và ẩn origin khỏi Internet là các hành động có tác động lớn nhất để giữ hệ thống an toàn và có khả năng chịu lỗi.

-- Nhóm Dự án

