#!/bin/bash
# Shared installation helpers for platform-specific installers.

if [ -n "${FRANKLIN_INSTALL_HELPERS_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi

_franklin_helper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/versions.sh
if [ -f "$_franklin_helper_dir/versions.sh" ]; then
  . "$_franklin_helper_dir/versions.sh"
fi
unset _franklin_helper_dir

_franklin_verify_checksum() {
  local file="$1"
  local expected="$2"

  if [ -z "$expected" ]; then
    return 0
  fi

  local checksum_cmd=""
  if command -v shasum >/dev/null 2>&1; then
    checksum_cmd="shasum -a 256"
  elif command -v sha256sum >/dev/null 2>&1; then
    checksum_cmd="sha256sum"
  else
    log_warning "No SHA-256 utility found; skipping checksum verification for $file"
    return 0
  fi

  local actual
  actual=$($checksum_cmd "$file" | awk '{print $1}')

  if [ "$actual" != "$expected" ]; then
    return 1
  fi

  return 0
}

ensure_nvm_installed() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
  local nvm_script="$nvm_dir/nvm.sh"

  if [ -s "$nvm_script" ]; then
    log_debug "NVM already installed at $nvm_dir"
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log_warning "curl is required to install NVM"
    return 1
  fi

  log_info "Installing NVM ${FRANKLIN_NVM_VERSION}..."
  mkdir -p "$nvm_dir"

  local nvm_installer_url="https://raw.githubusercontent.com/nvm-sh/nvm/${FRANKLIN_NVM_VERSION}/install.sh"
  local installer
  installer=$(mktemp "${TMPDIR:-/tmp}/franklin.XXXXXX") || {
    log_warning "Unable to create temporary file for NVM installer"
    return 1
  }

  if ! curl -fsSL "$nvm_installer_url" -o "$installer"; then
    log_warning "Failed to download NVM installer from $nvm_installer_url"
    rm -f "$installer"
    return 1
  fi

  if ! _franklin_verify_checksum "$installer" "$FRANKLIN_NVM_INSTALL_SHA256"; then
    log_error "NVM installer checksum mismatch (expected $FRANKLIN_NVM_INSTALL_SHA256)"
    rm -f "$installer"
    return 2
  fi

  if ! bash "$installer" >/dev/null 2>&1; then
    log_warning "NVM installer reported an error"
    rm -f "$installer"
    return 1
  fi

  rm -f "$installer"
  log_success "NVM installed at $nvm_dir"
  return 0
}

FRANKLIN_INSTALL_HELPERS_LOADED=1
