# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Integrated Neo4j service for Threat Intelligence Graph in local development (Docker Compose) and Helm chart.
- Added `scripts/test-and-deploy.sh` script to streamline `make test`, `make deploy-k3s` and `make full` commands.
- Configured HorizontalPodAutoscaler (HPA) and robust resource limits for Malware Analyzer, Frontend, Backend, Database and Cloudflared.
- Added execution timeouts for malware analysis in `app.py` to prevent DoS by large/malformed files.
- Added OpenAPI specification (`openapi.yaml`) for Malware Analyzer.
- Added Network policies for better isolation in Kubernetes.
- CI workflows enhanced with `ruff` and integration testing.
- Added `CONTRIBUTING.md`, `LICENSE`, and CI badges to `README.md`.
- Converted `emptyDir` to PersistentVolumeClaim for malware analyzer uploads directory.
