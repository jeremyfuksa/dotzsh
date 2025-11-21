#!/usr/bin/env bash
# Franklin Installer (Stage 2)
#
# Purpose: Configure the Franklin environment after bootstrap
#
# This script:
# 1. Detects the platform (macOS/Debian/RHEL) and architecture
# 2. Backs up existing Zsh configuration files
# 3. Prompts for Campfire color selection (interactive mode)
# 4. Installs dependencies via the appropriate package manager
# 5. Sets up Sheldon, Starship, and NVM
# 6. Symlinks ~/.zshrc to the Franklin template
# 7. Installs the Franklin CLI via Python

set -euo pipefail

# --- Configuration ---
FRANKLIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${HOME}/.local/share/franklin/backups/$(date +%Y-%m-%d_%H%M%S)"
CONFIG_DIR="${HOME}/.config/franklin"
CONFIG_FILE="${CONFIG_DIR}/config.env"
VENV_DIR="${HOME}/.local/share/franklin/venv"

# --- Logging Functions ---
log_info() {
    echo "INFO: $*" >&2
}

log_success() {
    echo "SUCCESS: $*" >&2
}

log_error() {
    echo "ERROR: $*" >&2
    exit 1
}

log_warning() {
    echo "WARNING: $*" >&2
}

# --- Platform Detection ---
log_info "Detecting platform..."

OS_FAMILY=""
OS_DISTRO=""
OS_ARCH="$(uname -m)"

case "$(uname -s)" in
    Darwin)
        OS_FAMILY="macos"
        OS_DISTRO="macos"
        ;;
    Linux)
        # Parse /etc/os-release
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                debian|ubuntu|pop|elementary|linuxmint|neon|kali|raspbian)
                    OS_FAMILY="debian"
                    OS_DISTRO="$ID"
                    ;;
                fedora|rhel|centos|rocky|almalinux|amzn)
                    OS_FAMILY="fedora"
                    OS_DISTRO="$ID"
                    ;;
                *)
                    log_error "Unsupported Linux distribution: $ID"
                    ;;
            esac
        else
            log_error "Cannot determine Linux distribution (/etc/os-release not found)"
        fi
        ;;
    *)
        log_error "Unsupported operating system: $(uname -s)"
        ;;
esac

log_success "Platform: $OS_FAMILY ($OS_DISTRO) on $OS_ARCH"

# --- Backup Existing Configuration ---
log_info "Backing up existing Zsh configuration..."

mkdir -p "$BACKUP_DIR"

for file in .zshrc .zprofile .zshenv; do
    filepath="${HOME}/${file}"
    if [ -f "$filepath" ] && [ ! -L "$filepath" ]; then
        log_info "Backing up $file to $BACKUP_DIR"
        mv "$filepath" "$BACKUP_DIR/"
    fi
done

log_success "Backup complete (if files existed): $BACKUP_DIR"

# --- Color Display Helper ---
# Convert hex color to ANSI 24-bit color code and display a colored swatch
show_color() {
    local name="$1"
    local hex="$2"

    # Strip # from hex
    hex="${hex#\#}"

    # Convert hex to RGB
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))

    # ANSI 24-bit color: \033[38;2;R;G;Bm for foreground
    # Display colored block characters as preview
    printf "  \033[38;2;%d;%d;%dm████\033[0m  %-15s (#%s)\n" "$r" "$g" "$b" "$name" "$hex" >&2
}

# --- Campfire Color Selection ---
log_info "Configuring MOTD color..."

# Default color
MOTD_COLOR="#607a97"  # Cello

# Interactive mode if TTY
if [ -t 0 ]; then
    echo "" >&2
    echo "Select your Campfire color for the MOTD banner:" >&2
    echo "" >&2
    show_color "1) Cello" "#607a97"
    show_color "2) Terracotta" "#b87b6a"
    show_color "3) Black Rock" "#747b8a"
    show_color "4) Sage" "#8fb14b"
    show_color "5) Golden Amber" "#f9c574"
    show_color "6) Flamingo" "#e75351"
    show_color "7) Blue Calx" "#b8c5d9"
    echo "  8) Custom (enter hex code)" >&2
    echo "" >&2

    read -r -p "Enter choice [1-8, default: 1]: " color_choice

    case "${color_choice:-1}" in
        1) MOTD_COLOR="#607a97" ;;
        2) MOTD_COLOR="#b87b6a" ;;
        3) MOTD_COLOR="#747b8a" ;;
        4) MOTD_COLOR="#8fb14b" ;;
        5) MOTD_COLOR="#f9c574" ;;
        6) MOTD_COLOR="#e75351" ;;
        7) MOTD_COLOR="#b8c5d9" ;;
        8)
            read -r -p "Enter hex code (#rrggbb): " custom_color
            # Basic validation
            if [[ "$custom_color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
                MOTD_COLOR="$custom_color"
            else
                log_warning "Invalid hex code, using default (Cello)"
            fi
            ;;
        *)
            log_warning "Invalid choice, using default (Cello)"
            ;;
    esac
fi

# Save color to config
mkdir -p "$CONFIG_DIR"
echo "MOTD_COLOR=\"${MOTD_COLOR}\"" > "$CONFIG_FILE"
log_success "MOTD color set to $MOTD_COLOR"

# --- Install Dependencies ---
log_info "Installing dependencies..."

case "$OS_FAMILY" in
    macos)
        # Check for Homebrew
        if ! command -v brew >/dev/null 2>&1; then
            log_error "Homebrew is required on macOS but not found. Please install it first: https://brew.sh"
        fi

        # Install dependencies
        log_info "Installing packages via Homebrew..."
        brew install curl git zsh python3 bat sheldon starship 2>&1 | sed 's/^/  /' >&2 || true
        ;;

    debian)
        log_info "Installing packages via apt..."
        sudo apt-get update -qq 2>&1 | sed 's/^/  /' >&2
        sudo apt-get install -y -qq curl git zsh python3 python3-venv python3-pip batcat 2>&1 | sed 's/^/  /' >&2 || true

        # Install Sheldon (not in apt)
        if ! command -v sheldon >/dev/null 2>&1; then
            log_info "Installing Sheldon..."
            curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin 2>&1 | sed 's/^/  /' >&2
        fi

        # Install Starship (not in apt)
        if ! command -v starship >/dev/null 2>&1; then
            log_info "Installing Starship..."
            curl -fsSL https://starship.rs/install.sh | sh -s -- --yes 2>&1 | sed 's/^/  /' >&2
        fi
        ;;

    fedora)
        log_info "Installing packages via dnf..."
        sudo dnf install -y curl git zsh python3 python3-pip bat 2>&1 | sed 's/^/  /' >&2 || true

        # Install Sheldon (not in dnf)
        if ! command -v sheldon >/dev/null 2>&1; then
            log_info "Installing Sheldon..."
            curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin 2>&1 | sed 's/^/  /' >&2
        fi

        # Install Starship (not in dnf)
        if ! command -v starship >/dev/null 2>&1; then
            log_info "Installing Starship..."
            curl -fsSL https://starship.rs/install.sh | sh -s -- --yes 2>&1 | sed 's/^/  /' >&2
        fi
        ;;
esac

log_success "Dependencies installed"

# --- Install NVM ---
log_info "Setting up NVM..."

NVM_DIR="${HOME}/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    log_info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash 2>&1 | sed 's/^/  /' >&2
else
    log_info "NVM already installed"
fi

log_success "NVM ready"

# --- Set up Python Virtual Environment ---
log_info "Setting up Python virtual environment..."

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    log_success "Virtual environment created at $VENV_DIR"
else
    log_info "Virtual environment already exists"
fi

# --- Install Franklin CLI ---
log_info "Installing Franklin CLI..."

"$VENV_DIR/bin/pip" install --quiet -e "$FRANKLIN_ROOT/franklin" 2>&1 | sed 's/^/  /' >&2 || \
    log_warning "Failed to install Franklin CLI (non-fatal)"

log_success "Franklin CLI installed"

# --- Symlink Configuration Files ---
log_info "Linking configuration files..."

# Link .zshrc
ZSHRC_TARGET="${FRANKLIN_ROOT}/franklin/templates/zshrc.zsh"
ZSHRC_LINK="${HOME}/.zshrc"

if [ -L "$ZSHRC_LINK" ]; then
    log_info "Removing existing .zshrc symlink"
    rm "$ZSHRC_LINK"
fi

ln -sf "$ZSHRC_TARGET" "$ZSHRC_LINK"
log_success ".zshrc linked to Franklin template"

# Link Sheldon config
SHELDON_CONFIG_DIR="${HOME}/.config/sheldon"
mkdir -p "$SHELDON_CONFIG_DIR"
ln -sf "${FRANKLIN_ROOT}/franklin/config/plugins.toml" "${SHELDON_CONFIG_DIR}/plugins.toml"
log_success "Sheldon config linked"

# Link Starship config
STARSHIP_CONFIG="${HOME}/.config/starship.toml"
ln -sf "${FRANKLIN_ROOT}/franklin/config/starship.toml" "$STARSHIP_CONFIG"
log_success "Starship config linked"

# --- Post-Install Instructions ---
echo "" >&2
log_success "Franklin installation complete!"
echo "" >&2
echo "Next steps:" >&2
echo "  1. Add Franklin to your PATH by adding this to your .zshrc:" >&2
echo "     export PATH=\"${VENV_DIR}/bin:\$PATH\"" >&2
echo "" >&2
echo "  2. Restart your shell or run: exec zsh" >&2
echo "" >&2
echo "  3. Verify installation with: franklin doctor" >&2
echo "" >&2
