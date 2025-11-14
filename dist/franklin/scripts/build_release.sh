#!/bin/bash
# Package a production-ready copy of franklin without development-only assets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
PROJECT_SLUG="${PROJECT_SLUG:-franklin}"
OUTPUT_DIR="${1:-$DIST_DIR/$PROJECT_SLUG}"
MANIFEST_DIR="$DIST_DIR/manifests"
OS_TARGETS=(macos debian fedora)
FRANKLIN_UI_QUIET=${FRANKLIN_UI_QUIET:-0}

# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/ui.sh
. "$ROOT_DIR/lib/ui.sh"

log_info() { franklin_ui_log info "[BUILD]" "$@"; }
log_success() { franklin_ui_log success " DONE " "$@"; }
log_warning() { franklin_ui_log warning " WARN " "$@"; }
log_error() { franklin_ui_log error " ERR " "$@"; }

COMMON_FILES=(
  "VERSION"
  ".zshrc"
  "install.sh"
  "update-all.sh"
  "README.md"
  "CONTRIBUTING.md"
  "LICENSE"
  "starship.toml"
  "bootstrap.sh"
  "lib/README.md"
  "lib/colors.sh"
  "lib/ui.sh"
  "lib/motd-helpers.zsh"
  "lib/motd.zsh"
  "lib/notify.zsh"
  "lib/nvm.zsh"
  "lib/os_detect.sh"
  "lib/os_detect.zsh"
  "lib/install_helpers.sh"
  "lib/versions.sh"
  "scripts/check_versions.sh"
  "scripts/current_franklin_version.sh"
  "scripts/write_version_file.sh"
)

mkdir -p "$DIST_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

EXCLUDES=(
  ".git/"
  ".github/"
  ".serena/"
  ".claude/"
  "dist/"
  "test/"
  "node_modules/"
  "CHANGELOG.md"
)

RSYNC_ARGS=()
for exclude in "${EXCLUDES[@]}"; do
  RSYNC_ARGS+=(--exclude="$exclude")
done

rsync -a "${RSYNC_ARGS[@]}" "$ROOT_DIR/" "$OUTPUT_DIR/"

ARCHIVE_PATH="$OUTPUT_DIR.tar.gz"
rm -f "$ARCHIVE_PATH"
tar -czf "$ARCHIVE_PATH" -C "$DIST_DIR" "$(basename "$OUTPUT_DIR")"

mkdir -p "$MANIFEST_DIR"

build_manifest() {
  local name="$1"
  shift
  local file="$MANIFEST_DIR/$name.txt"
  : > "$file"
  for entry in "$@"; do
    if [ -e "$OUTPUT_DIR/$entry" ]; then
      printf '%s\n' "$entry" >> "$file"
    else
      log_warning "$entry missing from release output"
    fi
  done
  log_info "Manifest generated: $file"
}

os_specific_files() {
  case "$1" in
    macos)
      echo "lib/install_macos.sh"
      ;;
    debian)
      echo "lib/install_debian.sh"
      ;;
    fedora)
      echo "lib/install_fedora.sh"
      ;;
  esac
}

# Generate per-OS manifests and archives
for os in "${OS_TARGETS[@]}"; do
  extra_files=$(os_specific_files "$os")
  if [ -n "$extra_files" ]; then
    build_manifest "$os" "${COMMON_FILES[@]}" $extra_files
  else
    build_manifest "$os" "${COMMON_FILES[@]}"
  fi

  manifest_file="$MANIFEST_DIR/$os.txt"
  os_stage="$DIST_DIR/os-$os"
  rm -rf "$os_stage"
  mkdir -p "$os_stage"
  rsync -a --files-from="$manifest_file" "$OUTPUT_DIR/" "$os_stage/"

  python3 "$SCRIPT_DIR/render_os_specific.py" --os "$os" --zshrc "$os_stage/.zshrc" --update "$os_stage/update-all.sh"

  tar -czf "$DIST_DIR/$PROJECT_SLUG-$os.tar.gz" -C "$os_stage" .
  log_success "OS archive built: $DIST_DIR/$PROJECT_SLUG-$os.tar.gz"
done

log_success "Release directory: $OUTPUT_DIR"
log_success "Release archive:   $ARCHIVE_PATH"
