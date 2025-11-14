#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"

if [ -n "${FRANKLIN_VERSION:-}" ]; then
  version="$FRANKLIN_VERSION"
elif git -C "$ROOT_DIR" describe --tags --dirty --always >/dev/null 2>&1; then
  version=$(git -C "$ROOT_DIR" describe --tags --dirty --always)
else
  version="unknown"
fi

echo "$version" >"$VERSION_FILE"
