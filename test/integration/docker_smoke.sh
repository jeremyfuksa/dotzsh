#!/bin/bash
# Basic Docker-based integration smoke tests for franklin installers.

set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not available, skipping integration smoke tests."
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGES=(
  "ubuntu:22.04"
  "debian:12"
  "fedora:39"
)

for image in "${IMAGES[@]}"; do
  echo "==> Running smoke test in $image"
  docker pull "$image" >/dev/null
  docker run --rm \
    -v "$ROOT_DIR":/franklin \
    "$image" \
    /bin/bash -c "cd /franklin && bash install.sh --help >/dev/null"
done

echo "Docker smoke tests completed successfully."
