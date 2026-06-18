# Hướng dẫn CI/CD (GitHub Actions)

Tài liệu này hướng dẫn chi tiết cách chạy workflow CI/CD đã thêm vào repo.

Mục tiêu:
- Chạy test (pytest)
- Build image frontend/backend/malware-analyzer và push lên GHCR
- (Tùy chọn) Deploy lên cluster k3s bằng `scripts/deploy-all.sh`

Yêu cầu trước:
- Repository đã được push lên GitHub
- Có quyền tạo Secrets trên repo
- Nếu push image lên GHCR: có PAT (`CR_PAT`) với scope `write:packages, read:packages`
- Nếu deploy từ Actions: kubeconfig base64 secret `KUBE_CONFIG_BASE64`

Các bước chi tiết

1) Đẩy repo lên GitHub

```bash
git remote add origin git@github.com:YOUR_USER/YOUR_REPO.git
git push -u origin main
```

2) Thiết lập secrets trên GitHub

Trên GitHub: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`.

- `CR_PAT` (tuỳ): Personal Access Token (PAT) với scope `write:packages, read:packages`. Dùng để push image lên `ghcr.io`.
- `KUBE_CONFIG_BASE64` (tuỳ, chỉ cần nếu muốn deploy từ Actions): nội dung base64 của file kubeconfig.

Tạo `KUBE_CONFIG_BASE64` (WSL/Linux):

```bash
base64 -w0 ~/.kube/config > kubeconfig.b64
# mở file kubeconfig.b64 và copy nội dung dán vào secret KUBE_CONFIG_BASE64
```

PowerShell (Windows):

```powershell
$bytes = [System.IO.File]::ReadAllBytes("$env:USERPROFILE\.kube\config")
$b64 = [Convert]::ToBase64String($bytes)
# copy $b64 vào secret KUBE_CONFIG_BASE64
```

3) Trigger workflow

- Tự động: đẩy commit vào `main`/`master` sẽ chạy job `test` và `build`.

```bash
git add -A
git commit -m "ci: add GitHub Actions workflow"
git push origin main
```

- Thủ công: chạy bằng `gh` CLI (cần cài `gh` và đã login):

```bash
gh workflow run "CI/CD" --repo YOUR_USER/YOUR_REPO --ref main -f deploy=false
# hoặc kèm deploy
gh workflow run "CI/CD" --repo YOUR_USER/YOUR_REPO --ref main -f deploy=true
```

4) Theo dõi run

```bash
# list runs
gh run list --workflow "CI/CD" --repo YOUR_USER/YOUR_REPO
# xem logs
gh run view <RUN_ID> --repo YOUR_USER/YOUR_REPO --log
```

Hoặc mở GitHub → Actions → chọn workflow → chọn run và xem step logs.

5) Kết quả mong đợi

- Job `test` chạy pytest. (Failures sẽ hiển thị lỗi tests.)
- Job `build` build và push images lên `ghcr.io/${{ github.repository }}/...:latest`.
- Nếu `deploy=true` và `KUBE_CONFIG_BASE64` hợp lệ: job `deploy` sẽ decode kubeconfig, kết nối cluster và chạy `./scripts/deploy-all.sh`.

6) Kiểm tra trên cluster sau deploy

```bash
kubectl -n portfolio get pods
kubectl -n portfolio rollout status deployment/frontend --timeout=120s
kubectl -n portfolio logs -l app=frontend --tail=200
```

7) Xử lý lỗi thường gặp

- Lỗi push image: kiểm tra `CR_PAT` đúng và có permission, hoặc cấu hình registry khác.
- Lỗi decode kubeconfig: đảm bảo secret `KUBE_CONFIG_BASE64` là base64 của file kubeconfig hợp lệ.
- Lỗi deploy script: chạy `./scripts/deploy-all.sh` local để debug trước.

8) Tùy chỉnh

- Thay đổi registry: chỉnh `tags:` trong `.github/workflows/ci-cd.yml`.
- Chỉ build khi push tag: chỉnh `on:` trong workflow.

---

Nếu bạn muốn, tôi có thể:
- Tự động tạo secret `CR_PAT` hướng dẫn chi tiết từng bước trên GitHub web,
- Hoặc tạo `Jenkinsfile` nếu bạn cần Jenkins.

File này được lưu tại `docs/CI.md` trong repo.
