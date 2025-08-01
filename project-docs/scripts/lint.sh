#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
lint.sh - run linting and formatting checks

Usage:
  sh project-docs/scripts/lint.sh [--fix] [--verbose]

Options:
  --fix       Apply automatic fixes (frontend: eslint/prettier; backend: black)
  --verbose   Verbose logging
EOF
}

FIX=0
VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    --fix) FIX=1 ;;
    --verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg"; usage; exit 2 ;;
  esac
done

log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "[lint] $*"
  fi
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Frontend lint/typecheck
if [[ -f sourcecode/package.json ]]; then
  if [[ "$FIX" -eq 1 ]]; then
    log "Frontend: eslint --fix + prettier"
    (cd sourcecode && npm run lint && npm run format && npm run check)
  else
    log "Frontend: eslint + prettier check + svelte-check"
    (cd sourcecode && npx eslint . && npx prettier --check "**/*.{js,ts,svelte,css,md,html,json}" && npm run check)
  fi
else
  echo "sourcecode/package.json not found; skipping frontend lint."
fi

# Backend lint/format
if [[ -f sourcecode/pyproject.toml ]]; then
  if [[ "$FIX" -eq 1 ]]; then
    log "Backend: black (format) + pylint"
    (cd sourcecode && python3 -m venv .venv && source .venv/bin/activate && pip install --upgrade pip && pip install black pylint || true)
    (cd sourcecode && black . --exclude ".venv/|/venv/" || true)
    (cd sourcecode && npm run lint:backend || true)
  else
    log "Backend: pylint"
    (cd sourcecode && npm run lint:backend || true)
  fi
else
  echo "sourcecode/pyproject.toml not found; skipping backend lint."
fi

echo "Lint completed."