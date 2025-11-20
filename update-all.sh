#!/usr/bin/env bash

# Thin wrapper to ensure the repo version of update-all is used.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/src/update-all.sh" "$@"
