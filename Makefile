.PHONY: dev build push deploy clean logs status

# Biến - thay YOUR_GITHUB_USER
GITHUB_USER ?= YOUR_GITHUB_USER
IMAGE_TAG   ?= latest
NAMESPACE   := portfolio

# Chạy môi trường dev
dev:
	docker compose up -d
	@echo "Frontend: http://localhost:3000"
	@echo "Backend:  http://localhost:8080"

# Build tất cả images
build:
	docker build -t portfolio-frontend:$(IMAGE_TAG) ./apps/frontend
	docker build -t portfolio-backend:$(IMAGE_TAG)  ./apps/backend

# Tag images cho GHCR
tag: build
	docker tag portfolio-frontend:$(IMAGE_TAG) \
	  ghcr.io/$(GITHUB_USER)/portfolio-frontend:$(IMAGE_TAG)
	docker tag portfolio-backend:$(IMAGE_TAG) \
	  ghcr.io/$(GITHUB_USER)/portfolio-backend:$(IMAGE_TAG)

# Push lên GHCR
push: tag
	docker push ghcr.io/$(GITHUB_USER)/portfolio-frontend:$(IMAGE_TAG)
	docker push ghcr.io/$(GITHUB_USER)/portfolio-backend:$(IMAGE_TAG)

# Deploy lên K3s
deploy:
	bash scripts/deploy.sh $(IMAGE_TAG)

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
	helm uninstall portfolio -n $(NAMESPACE) || true
