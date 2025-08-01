#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
install-deps.sh - install frontend and/or backend dependencies

Usage:
  sh project-docs/scripts/install-deps.sh [--frontend] [--backend] [--verbose]

Options:
  --frontend   Install Node.js dependencies for SvelteKit frontend (sourcecode/)
  --backend    Install Python dependencies for FastAPI backend (sourcecode/)
  --verbose    Verbose logging

Notes:
  - Non-intrusive: does not modify files outside project-docs/.
  - Uses npm ci for deterministic installs on frontend.
  - Uses Python venv with pip for backend.
EOF
}

FRONTEND=0
BACKEND=0
VERBOSE=0

for arg in "$@"; do
  case "$arg" in
    --frontend) FRONTEND=1 ;;
    --backend) BACKEND=1 ;;
    --verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg"; usage; exit 2 ;;
  esac
done

log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "[install-deps] $*"
  fi
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ "$FRONTEND" -eq 1 ]]; then
  log "Installing frontend dependencies with npm ci"
  if [[ ! -f sourcecode/package.json ]]; then
    echo "sourcecode/package.json not found"; exit 3
  fi
  (cd sourcecode && npm ci)
  echo "Frontend deps installed."
fi

if [[ "$BACKEND" -eq 1 ]]; then
  log "Installing backend dependencies with Python venv + pip"
  if [[ ! -f sourcecode/pyproject.toml ]]; then
    echo "sourcecode/pyproject.toml not found"; exit 4
  fi
  (cd sourcecode && python3 -m venv .venv && source .venv/bin/activate && pip install --upgrade pip && pip install -e .)
  echo "Backend deps installed."
fi

if [[ "$FRONTEND" -eq 0 && "$BACKEND" -eq 0 ]]; then
  echo "Nothing to do. Pass --frontend and/or --backend."
fi