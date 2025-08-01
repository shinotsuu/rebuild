#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
build.sh - perform clean build for frontend and prepare backend

Usage:
  sh project-docs/scripts/build.sh [--clean] [--verbose]

Options:
  --clean     Remove common build artifacts before building
  --verbose   Verbose logging

Notes:
  - Non-intrusive: does not modify files outside project-docs/.
  - Frontend build uses: npm run build (sourcecode/)
  - Backend: ensure editable install is present via install-deps.sh --backend
EOF
}

CLEAN=0
VERBOSE=0

for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=1 ;;
    --verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg"; usage; exit 2 ;;
  esac
done

log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "[build] $*"
  fi
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ "$CLEAN" -eq 1 ]]; then
  log "Cleaning frontend build artifacts"
  rm -rf sourcecode/.svelte-kit sourcecode/build || true
fi

if [[ -f sourcecode/package.json ]]; then
  log "Building frontend (SvelteKit)"
  (cd sourcecode && npm run build)
else
  echo "sourcecode/package.json not found; skipping frontend build."
fi

echo "Build complete."