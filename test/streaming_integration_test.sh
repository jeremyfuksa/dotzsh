#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=src/lib/colors.sh
source "$ROOT_DIR/src/lib/colors.sh"
# shellcheck source=src/lib/ui.sh
source "$ROOT_DIR/src/lib/ui.sh"
# shellcheck source=src/lib/streaming_filters.sh
source "$ROOT_DIR/src/lib/streaming_filters.sh"

export FRANKLIN_STREAM_ALLOW_PIPE=1

test_streaming_filters_output() {
  export FRANKLIN_UPDATE_MODE=auto
  local output
  output="$(franklin_ui_stream_filtered "[TEST]" "brew" bash -c $'printf "==> Downloading foo\\n==> Upgrading wget\\nWarning: already installed golang\\n"' 2>&1 || true)"

  if ! grep -q "Upgrading wget" <<<"$output"; then
    echo "FAIL: Expected upgrade lines in output"
    exit 1
  fi

  if grep -q "^  ==> Downloading foo" <<<"$output"; then
    echo "FAIL: Expected download lines to be filtered"
    exit 1
  fi
}

test_exit_code_propagation() {
  export FRANKLIN_UPDATE_MODE=auto
  local exit_code
  set +e
  franklin_ui_stream_filtered "[TEST]" "brew" bash -c $'echo "Some output"; exit 3' >/dev/null 2>&1
  exit_code=$?
  set -e

  if [[ $exit_code -ne 3 ]]; then
    echo "FAIL: Expected exit code 3, got $exit_code"
    exit 1
  fi
}

run_tests() {
  test_streaming_filters_output
  test_exit_code_propagation
}

run_tests
printf '• Ran %s\n' "bash test/streaming_integration_test.sh"
printf '  └ All streaming integration tests passed ✓\n'
