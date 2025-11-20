#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=src/lib/streaming_filters.sh
source "$ROOT_DIR/src/lib/streaming_filters.sh"

fail() {
  echo "FAIL: $1"
  exit 1
}

assert_show() {
  local preset="$1"
  local line="$2"
  if ! _should_show_line "$preset" "$line"; then
    fail "Expected line to be shown for preset '$preset': $line"
  fi
}

assert_hide() {
  local preset="$1"
  local line="$2"
  if _should_show_line "$preset" "$line"; then
    fail "Expected line to be hidden for preset '$preset': $line"
  fi
}

test_brew_filter() {
  assert_show brew "==> Upgrading wget"
  assert_show brew "Warning: already installed golang"
  assert_hide brew "==> Downloading https://ghcr.io/v2/homebrew/core/wget"
  assert_hide brew "######################################################################## 100%"
}

test_apt_filter() {
  assert_show apt "The following packages will be upgraded"
  assert_show apt "Setting up ca-certificates (20250101) ..."
  assert_hide apt "Get:1 http://archive.ubuntu.com/ubuntu"
  assert_hide apt "dpkg: warning: old package triggers"
}

test_dnf_filter() {
  assert_show dnf "Installing: starship-1.20.0.fc39"
  assert_hide dnf "Downloading Packages:"
  assert_hide dnf "[=== ] 45%"
}

test_npm_filter() {
  assert_show npm "added 2 packages, and audited 15 packages in 2s"
  assert_hide npm "npm timing npm Completed"
  assert_hide npm "npm http fetchPackageMetaData"
}

test_tool_filter() {
  assert_show tool "Cloning into 'starship'..."
  assert_hide tool "Counting objects: 45, done."
  assert_hide tool "   % Total    % Received % Xferd  Average Speed"
}

run_tests() {
  test_brew_filter
  test_apt_filter
  test_dnf_filter
  test_npm_filter
  test_tool_filter
}

run_tests
printf '• Ran %s\n' "bash test/streaming_filters_test.sh"
printf '  └ All streaming filter tests passed ✓\n'
