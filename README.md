# k3s-website-scanner

k3s-website-scanner is a static malware analysis platform built with a microservices architecture and deployed automatically on Kubernetes (K3s/K3d). It integrates Kubernetes scalability, Cloudflare Tunnel security, and a web interface for detailed analysis of suspicious files.

## Architecture

- Frontend (Nginx + HTML/CSS/JS): Web user interface supporting EN/VI and dark mode.
- Malware Analyzer (Python/Flask + Gunicorn): Core service for file hashing, PE structure analysis, IoC extraction, YARA scanning, VirusTotal lookup, MITRE ATT&CK mapping, and risk scoring.
- Backend (Node.js/Express): API for extended features (user management, history, logs).
- Database (PostgreSQL): Data storage for the Backend.
- Cloudflare Tunnel (cloudflared): Secure tunnel for internet access without NAT or Port Forwarding.
- K3s / K3d: Lightweight Kubernetes cluster managing pod lifecycle.

## Prerequisites

- Docker / Docker Desktop
- K3d
- kubectl
- Helm v3
- WSL (Windows) or Linux/macOS

## Quick Start

1. Start the entire system:
```bash
bash scripts/start-system.sh
```

2. Access the Web Interface:
The script generates a Cloudflare Quick Tunnel URL. Find it in the logs or run:
```bash
kubectl -n mijil logs -l app=cloudflared --tail=100 | grep trycloudflare.com
```

## Repository Structure

- apps/
  - frontend/: Nginx web server, static UI
  - backend/: Node.js Express API
  - database/: Postgres initialization scripts
  - malware-analyzer/: Static analysis core (Python)
- helm-charts/: Main chart for K8s resources
- k8s-manifests/: Optional standalone manifests
- scripts/: Automation scripts for cluster and deployment

## Troubleshooting

Check running pods:
```bash
kubectl get pods -n mijil
```

View Malware Analyzer logs:
```bash
kubectl logs -l app=malware-analyzer -n mijil -f
```

View Cloudflare Tunnel logs:
```bash
kubectl logs -l app=cloudflared -n mijil -f
```
