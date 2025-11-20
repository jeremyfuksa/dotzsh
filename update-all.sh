#!/usr/bin/env bash

# Wrapper to ensure we run the repo's current update-all with a local archive,
# so we don't fall back to the latest tagged release (v1.6.0) on GitHub.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${FRANKLIN_BOOTSTRAP_ARCHIVE:-}" ]; then
  tmp_archive="$(mktemp "/tmp/franklin-head.XXXXXX.tar.gz")"
  tar -czf "$tmp_archive" -C "$SCRIPT_DIR/src" .
  export FRANKLIN_BOOTSTRAP_ARCHIVE="file://$tmp_archive"
fi

exec bash "$SCRIPT_DIR/src/update-all.sh" "$@"
