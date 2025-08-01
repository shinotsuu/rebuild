# Operations and Deployment

Status: Compose-first with K8s later

This document covers environment configuration, containerization, docker-compose for development, initial production considerations, observability, and scaling. Kubernetes manifests/Helm are included in sourcecode/kubernetes for future deployment.

## Environments

- Development: Docker Compose (frontend, api, ollama, vector db optional)
- Staging: Compose or K8s with limited scale
- Production: K8s with Ingress, secrets, persistent volumes

## Environment Variables

Refer to sourcecode/.env.example. Key variables:
- OLLAMA_BASE_URL (e.g., http://localhost:11434)
- OPENAI_API_BASE_URL, OPENAI_API_KEY
- CORS_ALLOW_ORIGIN (semicolon-separated)
- FORWARDED_ALLOW_IPS
- DATABASE_URL (assumed sqlite:///./data/app.db initially)
- DO_NOT_TRACK, ANONYMIZED_TELEMETRY

## Docker Compose (Dev)

Definition: sourcecode/docker-compose.yaml. Example services:
- ollama: upstream model host
- open-webui: FastAPI backend + built frontend served via Uvicorn
- Volumes: persistent for ollama and open-webui data
- Ports: ${OPEN_WEBUI_PORT:-3000} mapped to container 8080

Commands
- docker compose -f sourcecode/docker-compose.yaml up -d
- docker compose -f sourcecode/docker-compose.yaml logs -f
- docker compose -f sourcecode/docker-compose.yaml down

## Images

- API/Frontend combined image built by Dockerfile (serves built frontend via FastAPI in prod)
- For dev local FE: run SvelteKit dev server on 5173 and point API CORS to it

## Kubernetes (Later)

Artifacts
- sourcecode/kubernetes/helm/
- sourcecode/kubernetes/manifest/base/
- sourcecode/kubernetes/manifest/gpu/

Guidance
- Use Ingress for TLS termination and routing to FE and API services
- PersistentVolumeClaims for vector DB and storage
- HorizontalPodAutoscaler on API based on CPU and custom metrics (tokens/sec)
- GPU node pool for GPU workloads; GPU manifest variant provided

## Observability

- Logging: structured logs to stdout, aggregated by platform
- Metrics/Tracing: optional OpenTelemetry compose variant (docker-compose.otel.yaml)
- Health Probes: /healthz endpoints (to be added) for readiness/liveness

## Scaling

- API horizontal scaling; ensure statelessness; Redis pub/sub for WS stop/cancel
- Vector DB: external managed or stateful set with persistence
- Rate limits to protect providers and budget

## Backups and DR (Future)

- Database backups (sqlite -> periodic copy; Postgres -> native tools)
- Object storage backups and lifecycle policies
- Disaster recovery runbooks

## Security Hardening

- Run containers as non-root when possible
- Network policies on K8s
- Secrets via K8s Secrets and external secrets managers when available
- Regular dependency and image scans

## Release Process

- Version from package.json; changelog maintained in sourcecode/CHANGELOG.md
- CI pipeline:
  - Lint/typecheck
  - Unit tests (pytest, vitest)
  - Build images, run smoke
  - Push to registry
- Deployment via GitOps or manual helm upgrade --install