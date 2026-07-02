.PHONY: dev test deploy-k3s full clean logs status help build

# Biến - thay thế bằng YOUR_GITHUB_USER của bạn
GITHUB_USER ?= YOUR_GITHUB_USER
IMAGE_TAG   ?= latest
NAMESPACE   := mijil

# Chạy môi trường dev (local) — full stack với Malware Analyzer
dev:
	docker compose up -d
	@echo "================================"
	@echo "  Ứng dụng đã khởi động:"
	@echo "  Frontend:           http://localhost:3000"
	@echo "  Backend API:        http://localhost:8080"
	@echo "  Malware Analyzer:   http://localhost:5000"
	@echo "  Database:           localhost:5433"
	@echo "================================"

# Build tất cả images
build:
	docker compose build

# Test local + review code (dùng Docker Compose)
test:
	bash scripts/test-and-deploy.sh --test-only

# Deploy frontend lên k3s/k3d cluster
deploy-k3s:
	bash scripts/test-and-deploy.sh --deploy

# Full pipeline: review → test local → deploy k3s
full:
	bash scripts/test-and-deploy.sh

# Xem logs
logs:
	kubectl logs -n $(NAMESPACE) -l app=frontend --tail=50 -f &
	kubectl logs -n $(NAMESPACE) -l app=backend  --tail=50 -f

# Trạng thái cluster
status:
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE)
	@echo "=== Services ==="
	kubectl get svc -n $(NAMESPACE)
	@echo "=== Ingress ==="
	kubectl get ingress -n $(NAMESPACE)

# Dọn dẹp
clean:
	docker compose down -v
	helm uninstall mijil -n $(NAMESPACE) || true

# Hướng dẫn
help:
	@echo "Các lệnh có sẵn:"
	@echo "  make dev          - Chạy local full stack (frontend + backend + malware-analyzer + db)"
	@echo "  make test         - Review code + test local (không deploy)"
	@echo "  make deploy-k3s   - Build frontend + deploy lên k3s/k3d"
	@echo "  make full         - Full pipeline: test -> deploy"
	@echo "  make build        - Build tất cả images"
	@echo "  make logs         - Xem logs từ k3s cluster"
	@echo "  make status       - Xem trạng thái cluster"
	@echo "  make clean        - Dọn dẹp (docker compose + helm)"