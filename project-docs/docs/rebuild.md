# Rebuild and Environment Setup Guide

Purpose
This guide explains how to rebuild the project from scratch on a clean machine. It covers prerequisites, environment setup, dependency installation, build steps, testing, linting/formatting, running locally, database/migrations, configuration, CI/CD notes, troubleshooting, reproducibility tips, and diagram references. All commands are designed to be copy-paste ready with repo-relative paths. This guide is non-intrusive and does not modify files outside project-docs/.

Overview
- Monorepo layout (discovered under sourcecode/):
  - Frontend: SvelteKit + Vite + Tailwind (TypeScript), with Cypress e2e.
  - Backend: FastAPI + Uvicorn (Python 3.11+), with Alembic migrations and optional vector DBs.
  - Docker Compose and Kubernetes manifests present for containerized workflows.
- This document provides generic and project-tailored steps to rebuild without altering existing repository files outside project-docs/.

Prerequisites
Operating Systems
- Linux: Ubuntu 22.04+ or Debian 12+ recommended
- macOS: 13+ (Ventura) with Homebrew
- Windows: 10/11 with WSL2 recommended for Linux-like workflows, or native PowerShell

Tooling Versions
- Node.js: >= 18.13.0 and <= 22.x.x (per package.json engines)
- npm: >= 6.0.0
- Python: 3.11.x (project lists >=3.11, <3.13.0a1)
- Git: 2.34+
- Optional:
  - Docker 24+ and Docker Compose v2
  - Redis (optional for scaling WebSocket streaming)
  - Qdrant/Chroma if testing vector DB integrations locally

System Packages
Linux (Debian/Ubuntu):
- sudo apt-get update && sudo apt-get install -y build-essential curl git python3.11 python3.11-venv python3.11-dev

macOS (Homebrew):
- brew install node@20 python@3.11 git

Windows:
- Install Node.js 20 LTS and Python 3.11 from official installers, or use WSL2 with Ubuntu and follow Linux steps

Environment Setup
Toolchain
- Ensure Node and npm are on PATH: node -v, npm -v
- Ensure Python 3.11 is default or available: python3.11 --version

Environment Variables
- Project baseline .env example exists at sourcecode/.env.example. Copy it (non-intrusively) for local runs:
  - cp sourcecode/.env.example sourcecode/.env
- Important environment keys:
  - OLLAMA_BASE_URL (default: http://localhost:11434)
  - OPENAI_API_BASE_URL, OPENAI_API_KEY (if using OpenAI-compatible providers)
  - CORS_ALLOW_ORIGIN for local dev
  - FORWARDED_ALLOW_IPS
  - DO_NOT_TRACK/telemetry flags
- Database URL and vector DB provider may be required in backend when customizing; keep secrets out of frontend.

Secrets Handling
- Never commit secrets. Prefer *_FILE variants or Docker/K8s secrets in production.
- For local only, sourcecode/.env is acceptable but do not commit changes.

Local Config Files
- Frontend: sourcecode/vite.config.ts includes onnxruntime-web copy hook.
- Backend: sourcecode/pyproject.toml enumerates dependencies; migrations present under backend/open_webui/.

Dependency Installation
Frontend (SvelteKit)
Linux/macOS:
- cd sourcecode
- npm ci

Windows PowerShell:
- Set-Location sourcecode
- npm ci

Backend (FastAPI)
Using venv (Linux/macOS):
- cd sourcecode
- python3.11 -m venv .venv
- source .venv/bin/activate
- pip install --upgrade pip
- pip install -e .

Using venv (Windows PowerShell):
- Set-Location sourcecode
- py -3.11 -m venv .venv
- .\.venv\Scripts\Activate.ps1
- python -m pip install --upgrade pip
- pip install -e .

Alternative (uv or rye): If you already use uv or rye, you can adapt accordingly, but the above pip workflow is canonical.

Build Steps
Frontend build
Linux/macOS:
- cd sourcecode
- npm run build

Windows PowerShell:
- Set-Location sourcecode
- npm run build

Notes:
- Vite will copy onnxruntime-web WASM artifacts to dist via vite-plugin-static-copy per vite.config.ts.

Backend build
- Python package is editable-installed via pip install -e ., no explicit “build” required for dev.
- For production wheel building, the project uses hatchling (pyproject). Example (optional):
  - cd sourcecode
  - python -m pip install hatchling
  - python -m build (if you add build backends; otherwise not required for dev)

Clean targets
- Frontend: rm -rf sourcecode/.svelte-kit sourcecode/build (Linux/macOS)
- Windows PowerShell: Remove-Item -Recurse -Force sourcecode\.svelte-kit, sourcecode\build

Testing
Frontend unit tests (Vitest)
- cd sourcecode
- npm run test:frontend

Frontend e2e (Cypress)
- cd sourcecode
- npm run cy:open
- Or headless in CI: npx cypress run

Backend tests (Pytest)
- cd sourcecode
- source .venv/bin/activate  # Linux/macOS
- pytest -q

- Windows PowerShell:
  - .\.venv\Scripts\Activate.ps1
  - pytest -q

Linting/Formatting
Frontend lint (ESLint) and type checks (svelte-check)
- cd sourcecode
- npm run lint
- npm run check

Frontend formatting (Prettier)
- cd sourcecode
- npm run format

Backend lint/format (pylint/black)
- cd sourcecode
- npm run lint:backend   # runs pylint backend/
- npm run format:backend # runs black with exclude patterns

Running Locally
Option A: Direct processes
Frontend (dev server with hot reload):
- cd sourcecode
- npm run dev  # defaults host binding; dev:5050 available on port 5050

Backend (Uvicorn with reload):
- cd sourcecode
- source .venv/bin/activate  # Linux/macOS
- uvicorn open_webui.main:app --reload --port 8080

- Windows PowerShell:
  - .\.venv\Scripts\Activate.ps1
  - uvicorn open_webui.main:app --reload --port 8080

Access:
- Frontend: http://localhost:5173 (default for Vite dev)
- Backend: http://localhost:8080

Option B: Docker Compose (non-intrusive)
- cd sourcecode
- docker compose up --build
This will start open-webui (exposing :8080 inside container, mapped to ${OPEN_WEBUI_PORT-3000}) and an ollama service. Use this when you prefer containerized local runs.

Database/Migrations
Defaults
- SQLite is typically default for dev; repository ignores db.sqlite3 artifacts.
Migrations (Alembic)
- Ensure backend venv is active:
  - alembic upgrade head
- Create a new revision (example):
  - alembic revision -m "add notes table"
- Downgrade for dev only:
  - alembic downgrade -1

Seed data (example approach)
- Create an admin user via a small script or API call during dev bootstrap. Document exact steps in scripts/setup-env.* if you automate it.

Configuration
Env files
- Start by copying .env example:
  - cp sourcecode/.env.example sourcecode/.env
Example .env with placeholders
- OLLAMA_BASE_URL='http://localhost:11434'
- OPENAI_API_BASE_URL=''
- OPENAI_API_KEY=''
- CORS_ALLOW_ORIGIN='http://localhost:5173;http://localhost:8080'
- FORWARDED_ALLOW_IPS='*'
- DO_NOT_TRACK=true

Profiles
- Consider using different .env.* files for dev/test; ensure they are gitignored (as already configured). Do not commit secrets.

CI/CD Notes
- Frontend CI should run: npm ci, npm run check, npm run lint, npm run build, and optionally Cypress headless.
- Backend CI should set up Python 3.11, install deps (pip install -e .), run black/pylint and pytest.
- Docker images can be built using Dockerfile and docker-compose.yaml under sourcecode/, but keep CI pipeline consistent with local steps.

Troubleshooting
Common issues
- Node version mismatch:
  - Ensure node satisfies ">=18.13.0 <=22.x.x". Use nvm (Linux/macOS) or volta.
- Python version mismatch:
  - Confirm python3.11 is used; check virtual environment activation.
- CORS issues when running frontend and backend separately:
  - Set CORS_ALLOW_ORIGIN properly in sourcecode/.env to include http://localhost:5173 and http://localhost:8080.
- Missing provider keys:
  - OPENAI_API_KEY or OLLAMA_BASE_URL not set; configure per your usage.
- Permissions on Windows PowerShell scripts:
  - Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Reproducibility Tips
- Use lockfiles:
  - Frontend: package-lock.json is present; prefer npm ci.
  - Backend: pyproject.toml defines versions; consider uv.lock if using uv. Pin Python minor versions.
- Cache node_modules and Python wheels in CI where possible.
- Use consistent environment (Docker/DevContainer) if team variability causes drift.

Diagrams Reference
- Project diagrams are stored under project-docs/diagrams/.
- Placeholders/stubs are provided initially. You can replace them with binary sources (e.g., .drawio, .png) as your team finalizes system visuals.

Notes and Deviations
- This guide intentionally avoids modifying any files outside project-docs/.
- If repository instructions conflict (e.g., different ports or commands), honor the existing project docs for execution and record the discrepancy here. For example, sourcecode/docker-compose.yaml exposes application on ${OPEN_WEBUI_PORT-3000} mapped to 8080 inside the container; adjust local expectations accordingly.

Script Entry Points (Helpers)
Use the helper scripts in project-docs/scripts/ for predictably running setup, installs, builds, tests, and lint checks:
- POSIX: .sh variants
- Windows: .ps1 variants

Examples:
Linux/macOS:
- sh project-docs/scripts/setup-env.sh --verbose
- sh project-docs/scripts/install-deps.sh --frontend --backend
- sh project-docs/scripts/build.sh --clean
- sh project-docs/scripts/test.sh --unit --e2e
- sh project-docs/scripts/lint.sh --fix

Windows PowerShell:
- ./project-docs/scripts/setup-env.ps1 -Verbose
- ./project-docs/scripts/install-deps.ps1 -Frontend -Backend
- ./project-docs/scripts/build.ps1 -Clean
- ./project-docs/scripts/test.ps1 -Unit -E2E
- ./project-docs/scripts/lint.ps1 -Fix

Appendix: Ports Summary
- Frontend dev: 5173
- Backend dev (Uvicorn): 8080
- Docker Compose (open-webui container): Host port ${OPEN_WEBUI_PORT-3000} -> container 8080
- Ollama default: 11434