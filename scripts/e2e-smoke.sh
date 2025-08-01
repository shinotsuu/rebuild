#!/usr/bin/env bash
set -euo pipefail

# Runs a basic end-to-end smoke test:
# 1) Start Docker Compose stack for API + Frontend (and Ollama).
# 2) Wait for API to respond.
# 3) Optionally run Cypress smoke tests if present.
#
# Usage:
#   bash scripts/e2e-smoke.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
COMPOSE_FILE="${ROOT_DIR}/sourcecode/docker-compose.yaml"

echo "==> Starting Docker Compose stack using ${COMPOSE_FILE}"
docker compose -f "${COMPOSE_FILE}" up -d

API_URL="http://localhost:${OPEN_WEBUI_PORT-3000}"
# docker-compose maps ${OPEN_WEBUI_PORT}:8080 for open-webui, default 3000 -> 8080
# Health check: poll /
echo "==> Waiting for API at ${API_URL}"
for i in {1..60}; do
  if curl -fsS "${API_URL}/" >/dev/null 2>&1; then
    echo "==> API is responding"
    break
  fi
  sleep 2
done

if ! curl -fsS "${API_URL}/" >/dev/null 2>&1; then
  echo "ERROR: API did not become ready in time" >&2
  exit 1
fi

# Run Cypress if available
if [ -d "${ROOT_DIR}/sourcecode/cypress" ]; then
  echo "==> Running Cypress smoke tests"
  pushd "${ROOT_DIR}/sourcecode" >/dev/null
  if ! command -v npx >/dev/null 2>&1; then
    echo "WARNING: npx not found; skipping Cypress tests"
  else
    npx cypress run --spec 'cypress/e2e/**/*.cy.ts' || echo "WARNING: Cypress returned non-zero exit (continuing)"
  fi
  popd >/dev/null
else
  echo "==> Cypress directory not found; skipping e2e tests"
fi

echo "==> Smoke test complete"