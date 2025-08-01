#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
setup-env.sh - bootstrap environment variables and prerequisites checks

Usage:
  sh project-docs/scripts/setup-env.sh [--verbose]

Options:
  --verbose     Enable verbose logging

Notes:
  - Non-intrusive: Does not modify files outside project-docs/.
  - Creates sourcecode/.env from sourcecode/.env.example if missing.
EOF
}

VERBOSE=0
if [[ "${1:-}" == "--verbose" ]]; then
  VERBOSE=1
fi

log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "[setup-env] $*"
  fi
}

# Repo root detection
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Basic checks
command -v node >/dev/null 2>&1 || { echo "Node.js not found. Install Node 18-22."; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm not found. Install npm."; exit 1; }
command -v python3 >/dev/null 2>&1 || command -v python3.11 >/dev/null 2>&1 || { echo "Python 3.11 required."; exit 1; }

# Copy .env if missing
if [[ -f sourcecode/.env ]]; then
  log "sourcecode/.env exists"
else
  if [[ -f sourcecode/.env.example ]]; then
    cp sourcecode/.env.example sourcecode/.env
    echo "Created sourcecode/.env from .env.example"
  else
    echo "sourcecode/.env.example not found. Skipping .env creation."
  fi
fi

echo "Environment bootstrap complete."