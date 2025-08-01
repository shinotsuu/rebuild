#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
test.sh - run unit/integration/e2e tests

Usage:
  sh project-docs/scripts/test.sh [--unit] [--integration] [--e2e] [--verbose]

Options:
  --unit         Run backend unit tests (pytest) and frontend unit tests (vitest)
  --integration  Alias for --unit in this stub (extend as needed)
  --e2e          Run Cypress e2e (headless) if available
  --verbose      Verbose logging
EOF
}

UNIT=0
INTEGRATION=0
E2E=0
VERBOSE=0

for arg in "$@"; do
  case "$arg" in
    --unit) UNIT=1 ;;
    --integration) INTEGRATION=1 ;;
    --e2e) E2E=1 ;;
    --verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg"; usage; exit 2 ;;
  esac
done

log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "[test] $*"
  fi
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ "$UNIT" -eq 1 || "$INTEGRATION" -eq 1 ]]; then
  # Frontend unit tests (Vitest)
  if [[ -f sourcecode/package.json ]]; then
    log "Running frontend unit tests (Vitest)"
    (cd sourcecode && npx vitest run --passWithNoTests)
  else
    echo "sourcecode/package.json not found; skipping frontend unit tests."
  fi

  # Backend tests (pytest)
  if [[ -f sourcecode/pyproject.toml ]]; then
    log "Running backend tests (pytest)"
    if [[ -d "sourcecode/.venv" ]]; then
      # shellcheck disable=SC1091
      source sourcecode/.venv/bin/activate
    fi
    (cd sourcecode && pytest -q)
  else
    echo "sourcecode/pyproject.toml not found; skipping backend tests."
  fi
fi

if [[ "$E2E" -eq 1 ]]; then
  if [[ -f sourcecode/package.json ]]; then
    log "Running Cypress e2e tests (headless)"
    (cd sourcecode && npx cypress run || { echo 'Cypress failed'; exit 1; })
  else
    echo "sourcecode/package.json not found; skipping Cypress e2e."
  fi
fi

if [[ "$UNIT" -eq 0 && "$INTEGRATION" -eq 0 && "$E2E" -eq 0 ]]; then
  echo "Nothing to do. Pass --unit and/or --e2e."
fi