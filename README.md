# Web-Scan — Static Malware Analysis Platform

[![CI](https://github.com/mijil9898/k3s-portfolio-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/mijil9898/k3s-portfolio-platform/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A self-hosted static malware analysis platform built with a microservices architecture, deployed on Kubernetes via Helm, and exposed securely through Cloudflare Tunnel — no port forwarding required.

---

##  Features

- **File Analysis**: PE (EXE/DLL), Office macros, PDF, scripts (PS1/VBS/JS/BAT), .NET assemblies, archives (ZIP/RAR)
- **Detection Engine**: YARA rules scanning with 3 built-in rulesets (common malware, PowerShell threats, shellcode injection)
- **Threat Intelligence**: VirusTotal hash lookup, AlienVault OTX IP reputation, MITRE ATT&CK mapping
- **ML Classifier**: LightGBM model (74 features) auto-trained from VT-labeled samples via incremental retraining
- **IoC Graph**: Neo4j-powered threat intelligence graph linking files, IPs, domains, and YARA signatures
- **Risk Scoring**: Heuristic-based 0–100 risk score with breakdown by category
- **Reporting**: JSON + HTML reports, STIX 2.1 export, executive summary
- **Monitoring**: Prometheus metrics endpoint (`/metrics`), Grafana-ready
- **Real-time**: Server-Sent Events (SSE) for live analysis progress

---

## Architecture

```
Internet
   
Cloudflare Tunnel (cloudflared)
   
    Frontend (Nginx + HTML/CSS/JS) :3000
           Bilingual UI (EN/VI), dark mode
   
    Backend (Node.js/TypeScript + Express) :8080
           REST API, rate limiting, helmet security
   
    Malware Analyzer (Python/Flask + Gunicorn) :5000
           Analysis Pipeline (13 steps)
           ML Pipeline (LightGBM + VT Oracle)
           Neo4j IoC Graph
   
    Database (PostgreSQL) :5433
            Analysis history
            ML training samples
```

---

##  Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Docker / Docker Desktop | Latest | Container runtime |
| K3d | v5+ | Local K3s cluster |
| kubectl | v1.28+ | Cluster management |
| Helm | v3+ | Chart deployment |
| WSL2 (Windows) / Linux / macOS | — | Shell environment |

---

##  Quick Start

### Local Development (Docker Compose)

```bash
# Start full stack: frontend + backend + malware-analyzer + neo4j + postgres
make dev

# Access points:
#   Frontend:          http://localhost:3000
#   Backend API:       http://localhost:8080
#   Malware Analyzer:  http://localhost:5000
#   Neo4j Browser:     http://localhost:7474
#   PostgreSQL:        localhost:5433
```

### Production (K3s/K3d + Helm)

```bash
# 1. Full pipeline: test → build → deploy
make full

# 2. Or deploy only
make deploy-k3s

# 3. Get the public Cloudflare Tunnel URL
kubectl -n mijil logs -l app=cloudflared --tail=100 | grep trycloudflare.com
```

---

##  API Endpoints — Malware Analyzer

### Core Analysis
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/analyze` | Upload file, start async analysis. Returns `analysis_id` |
| `GET` | `/status/<id>` | Poll analysis status (`pending` / `running` / `done` / `error`) |
| `GET` | `/stream/<id>` | SSE stream for real-time progress |
| `GET` | `/report/<id>?fmt=json\|html` | Download report |
| `GET` | `/export/stix/<id>` | Export as STIX 2.1 Bundle |

### Intelligence & History
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/history` | Recent analyses (supports `?limit=` `?risk_level=`) |
| `GET` | `/ioc-graph/<id>` | IoC graph data for visualization |
| `GET` | `/graph/search?type=&value=` | Search by IoC (ip/domain/url/yara/mitre) |
| `POST` | `/retrohunt` | Re-scan all stored reports with current YARA rules |
| `GET` | `/delta?a=<id>&b=<id>` | Diff two analysis reports |

### ML Pipeline
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/ml/stats` | Model status, version, training sample counts |
| `POST` | `/ml/retrain` | Manually trigger retraining (requires Bearer token) |
| `GET` | `/ml/training-stats` | Detailed PostgreSQL sample breakdown |

### System
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Service health check (VT, YARA, Neo4j, ML status) |
| `GET` | `/metrics` | Prometheus metrics |

---

##  ML Pipeline

The platform includes a **self-training LightGBM classifier** that improves automatically as more files are analyzed:

```
File analyzed → VirusTotal hash lookup → VT Oracle labels the sample
                                               
                                    ≥10 detections → malicious (1)
                                    0 detections + ≥30 engines → clean (0)
                                               
                                    Stored in PostgreSQL
                                               
                          50 samples → First training (~2-5s)
                          Every 25 new samples → Incremental retrain
                                               
                                    Hot-swap into server (no restart)
```

**74 features** across 10 categories: File stats, Entropy, PE Header, PE Sections, Suspicious Imports, Strings/IOC, YARA, MITRE ATT&CK, Risk Heuristics, Deep Static.

---

## Configuration

Copy `.env.example` to `.env` in `apps/malware-analyzer/`:

```env
FLASK_DEBUG=false
SECRET_KEY=<generate with: python -c "import secrets; print(secrets.token_hex(32))">

# Threat intelligence
VT_API_KEY=<your VirusTotal API key>       # Required for ML auto-labeling
OTX_API_KEY=<your AlienVault OTX key>      # Optional, for IP reputation

# Security
ANALYZE_AUTH_TOKEN=<bearer token>          # Protect /analyze endpoint
ANALYZE_RATE_LIMIT_PER_MINUTE=30

# ML tuning
ML_MIN_SAMPLES_FIRST_TRAIN=50
ML_MIN_NEW_SAMPLES_RETRAIN=25
VT_POSITIVE_THRESHOLD=10
VT_MIN_ENGINES=30
```

---

##  Repository Structure

```
web-scan/
 apps/
    frontend/          # Nginx + static UI (HTML/CSS/JS, bilingual)
    backend/           # Node.js/TypeScript + Express REST API
    database/          # PostgreSQL init scripts
    malware-analyzer/  # Python/Flask analysis engine
        app.py                  # Flask application (all routes)
        malware_analyzer_lib/   # Core analysis modules
           pe_analyzer.py      # PE structure analysis
           entropy_analyzer.py # Entropy & packing detection
           yara_scanner.py     # YARA rules engine
           ml_classifier.py    # LightGBM inference
           ml_trainer.py       # VT Oracle + auto-retraining
           ml_features.py      # Feature extraction (74 features)
           mitre_mapper.py     # MITRE ATT&CK mapping
           risk_score.py       # Heuristic risk scoring
           graph_db.py         # Neo4j IoC graph
           ...                 # (15 modules total)
        models/                 # LightGBM model files (gitignored)
        yara_rules/             # YARA detection rulesets

 helm-charts/
    mijil-chart/       # Helm chart (backend, frontend, db, malware, cloudflared)
 k8s-manifests/
    cloudflared/       # Standalone Cloudflare Tunnel manifests
 scripts/               # Deploy & automation scripts
 docker-compose.yml     # Local dev orchestration
 Makefile               # Dev shortcuts
```

---

## Make Commands

```bash
make dev          # Start local full stack (Docker Compose)
make build        # Build all Docker images
make test         # Run tests without deploying
make deploy-k3s   # Build + deploy to K3s cluster
make full         # Test → build → deploy (full pipeline)
make status       # Show pod/service/ingress status
make logs         # Tail logs from K3s cluster
make clean        # Stop Docker Compose + uninstall Helm chart
```

---

##  Troubleshooting

```bash
# Pod status
kubectl get pods -n mijil

# Malware Analyzer logs
kubectl logs -l app=malware-analyzer -n mijil -f

# Backend logs
kubectl logs -l app=backend -n mijil -f

# Cloudflare Tunnel URL
kubectl logs -l app=cloudflared -n mijil --tail=100 | grep trycloudflare.com

# Check ML model status
curl http://localhost:5000/ml/stats

# Health check
curl http://localhost:5000/health
```

---

##  Security

- **File sandboxing**: Uploaded files deleted immediately after analysis
- **Rate limiting**: Sliding window per IP (default 30 req/min)
- **Bearer token auth**: Optional protection for `/analyze` endpoint
- **Helmet + Talisman**: HTTP security headers (HSTS, CSP, X-Frame-Options)
- **Path traversal protection**: UUID-validated report access
- **No file upload to VT**: Only SHA256 hash is sent — payload stays local
