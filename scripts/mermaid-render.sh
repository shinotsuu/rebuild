#!/usr/bin/env bash
set -euo pipefail

# Renders all Mermaid .mmd files in diagrams/ to both .png and .svg using mermaid-cli (mmdc).
# Prerequisite: npm i -g @mermaid-js/mermaid-cli
# Usage: bash scripts/mermaid-render.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAM_DIR="${ROOT_DIR}/diagrams"

if ! command -v mmdc >/dev/null 2>&1; then
  echo "Error: mermaid-cli (mmdc) not found. Install with: npm i -g @mermaid-js/mermaid-cli" >&2
  exit 1
fi

mkdir -p "${DIAGRAM_DIR}"

shopt -s nullglob
MMDS=( "${DIAGRAM_DIR}"/*.mmd )
shopt -u nullglob

if [ ${#MMDS[@]} -eq 0 ]; then
  echo "No .mmd files found in ${DIAGRAM_DIR}"
  exit 0
fi

for src in "${MMDS[@]}"; do
  base="$(basename "${src}" .mmd)"
  png="${DIAGRAM_DIR}/${base}.png"
  svg="${DIAGRAM_DIR}/${base}.svg"

  echo "Rendering ${src} -> ${png}"
  mmdc -i "${src}" -o "${png}" -b transparent -s 1 -p 1

  echo "Rendering ${src} -> ${svg}"
  mmdc -i "${src}" -o "${svg}" -b transparent -s 1 -p 1
done

echo "All Mermaid diagrams rendered to PNG and SVG in ${DIAGRAM_DIR}"