#!/usr/bin/env bash
set -euo pipefail

# Bootstrap developer environment:
# - Copy .env.example to .env if missing
# - Create local data directories
# - Initialize database via Alembic if available
# - Seed minimal data (admin user placeholder)
#
# Usage:
#   bash scripts/bootstrap.sh
#
# Notes:
# - This script assumes repository root layout with sourcecode/ housing the app.
# - Alembic steps are no-ops if alembic is not installed or migration config absent.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
SRC_DIR="${ROOT_DIR}/sourcecode"
ENV_EXAMPLE="${SRC_DIR}/.env.example"
ENV_FILE="${SRC_DIR}/.env"
BACKEND_DIR="${SRC_DIR}/backend"
DATA_DIR="${BACKEND_DIR}/data"

echo "==> Bootstrap starting in ${ROOT_DIR}"

if [ ! -f "${ENV_FILE}" ]; then
  if [ -f "${ENV_EXAMPLE}" ]; then
    echo "==> Creating ${ENV_FILE} from .env.example"
    cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  else
    echo "WARNING: ${ENV_EXAMPLE} not found; creating a minimal ${ENV_FILE}"
    cat > "${ENV_FILE}" <<'EOF'
OLLAMA_BASE_URL='http://localhost:11434'
OPENAI_API_BASE_URL=''
OPENAI_API_KEY=''
CORS_ALLOW_ORIGIN='http://localhost:5173;http://localhost:8080'
FORWARDED_ALLOW_IPS='*'
SCARF_NO_ANALYTICS=true
DO_NOT_TRACK=true
ANONYMIZED_TELEMETRY=false
EOF
  fi
else
  echo "==> ${ENV_FILE} already exists; leaving unchanged"
fi

echo "==> Ensuring backend data directory exists at ${DATA_DIR}"
mkdir -p "${DATA_DIR}"

# Try Alembic migrations if available
if command -v alembic >/dev/null 2>&1 && [ -f "${BACKEND_DIR}/open_webui/migrations/env.py" ]; then
  echo "==> Running Alembic migrations"
  pushd "${BACKEND_DIR}" >/dev/null
  # If alembic.ini exists in backend/ or project root, use it; otherwise, best-effort
  if [ -f "${BACKEND_DIR}/alembic.ini" ]; then
    ALEMBIC_CFG="${BACKEND_DIR}/alembic.ini"
  elif [ -f "${SRC_DIR}/alembic.ini" ]; then
    ALEMBIC_CFG="${SRC_DIR}/alembic.ini"
  else
    ALEMBIC_CFG=""
  fi

  if [ -n "${ALEMBIC_CFG}" ]; then
    alembic -c "${ALEMBIC_CFG}" upgrade head || true
  else
    alembic upgrade head || true
  fi
  popd >/dev/null
else
  echo "==> Alembic not available or migrations not found; skipping DB migration"
fi

# Seed placeholder (document-only; real seed should call FastAPI admin-create or direct DB inserts)
SEED_FILE="${DATA_DIR}/SEED_INFO.txt"
if [ ! -f "${SEED_FILE}" ]; then
  echo "==> Writing seed info placeholder at ${SEED_FILE}"
  cat > "${SEED_FILE}" <<'EOF'
Seed placeholder:
- Create admin user via API or management command.
- Suggested default admin email: admin@example.com
- Set password via POST /api/auth/signup or direct DB tools in dev only.
EOF
else
  echo "==> Seed info already exists; skipping"
fi

echo "==> Bootstrap complete.
Next steps:
  - Render diagrams: npm i -g @mermaid-js/mermaid-cli && bash scripts/mermaid-render.sh
  - Start dev using Docker Compose: docker compose -f sourcecode/docker-compose.yaml up -d
  - Or run frontend locally: (cd sourcecode && npm install --force && npm run dev)
"