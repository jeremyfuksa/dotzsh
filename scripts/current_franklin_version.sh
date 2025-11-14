#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -n "${FRANKLIN_VERSION:-}" ]; then
  echo "$FRANKLIN_VERSION"
elif [ -f "$ROOT_DIR/VERSION" ]; then
  cat "$ROOT_DIR/VERSION"
else
  echo "unknown"
fi
