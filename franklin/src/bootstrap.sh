#!/bin/sh
# Franklin Bootstrap Script (Stage 1)
#
# Purpose: Fetch Franklin from GitHub and hand off to install.sh
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/USER/franklin/main/src/bootstrap.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/USER/franklin/main/src/bootstrap.sh | sh -s -- --dir /custom/path --ref v2.0.0
#
# Flags:
#   --dir DIR   Installation directory (default: ~/.local/share/franklin)
#   --ref REF   Git branch or tag to checkout (default: main)

set -e

# --- Defaults ---
INSTALL_DIR="${HOME}/.local/share/franklin"
GIT_REF="main"
REPO_URL="https://github.com/jeremyfuksa/franklin.git"

# --- Parse Arguments ---
while [ $# -gt 0 ]; do
    case "$1" in
        --dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --ref)
            GIT_REF="$2"
            shift 2
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            echo "Usage: bootstrap.sh [--dir DIR] [--ref REF]" >&2
            exit 1
            ;;
    esac
done

# --- Logging Functions ---
log_info() {
    echo "INFO: $*" >&2
}

log_error() {
    echo "ERROR: $*" >&2
    exit 1
}

log_success() {
    echo "SUCCESS: $*" >&2
}

# --- Pre-flight Checks ---
log_info "Starting Franklin bootstrap..."

# Check OS is supported
OS="$(uname -s)"
case "$OS" in
    Darwin)
        log_info "Detected macOS"
        ;;
    Linux)
        log_info "Detected Linux"
        # Verify it's a supported distro by checking /etc/os-release
        if [ ! -f /etc/os-release ]; then
            log_error "Cannot determine Linux distribution (/etc/os-release not found)"
        fi
        ;;
    *)
        log_error "Unsupported operating system: $OS (Franklin supports macOS, Debian, and RHEL)"
        ;;
esac

# Check for required commands
for cmd in git curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "$cmd is required but not found. Please install it and try again."
    fi
done

# Check for Python 3
if ! command -v python3 >/dev/null 2>&1; then
    log_error "Python 3 is required but not found. Please install Python 3 and try again."
fi

log_success "Pre-flight checks passed"

# --- Fetch Franklin ---
log_info "Fetching Franklin from $REPO_URL (ref: $GIT_REF)..."

# Remove existing directory if present
if [ -d "$INSTALL_DIR" ]; then
    log_info "Removing existing installation at $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
fi

# Clone repository
mkdir -p "$(dirname "$INSTALL_DIR")"
git clone --branch "$GIT_REF" --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>&1 | \
    sed 's/^/  /' >&2

log_success "Franklin fetched to $INSTALL_DIR"

# --- Hand off to installer ---
log_info "Starting installation..."

cd "$INSTALL_DIR"

if [ -f "franklin/src/install.sh" ]; then
    exec sh "franklin/src/install.sh"
else
    log_error "Installation script not found at franklin/src/install.sh"
fi
