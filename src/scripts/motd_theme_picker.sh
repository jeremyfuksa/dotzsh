#!/usr/bin/env bash
# Standalone MOTD Theme Picker
# Can be run post-installation to change banner theme

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRANKLIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRANKLIN_CONFIG_DIR="${FRANKLIN_CONFIG_DIR:-$HOME/.config/franklin}"
CONFIG_FILE="$FRANKLIN_CONFIG_DIR/motd.env"

# Simple logging functions (don't source ui.sh to avoid dependencies)
log_info() { echo "ℹ $*" >&2; }
log_success() { echo "✓ $*" >&2; }
log_warning() { echo "⚠ $*" >&2; }
log_error() { echo "✗ $*" >&2; }

# Basic color variables
GREEN="\033[38;2;143;177;75m"
NC="\033[0m"

# Theme metadata (matches motd-helpers.zsh)
THEME_ENTRIES=(
  "thick|Thick|Classic Unicode half-blocks (▄▀)"
  "thin|Thin|Clean single-line box-drawing (┌─┐)"
  "thin-double|Thin Double|Bold double-line box-drawing (╔═╗)"
)

render_theme_preview() {
  local theme="$1"
  local color="${2:-#4C627D}"
  local width=50

  # Extract RGB from hex
  local hex="${color#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))

  # Calculate darker variant (90% brightness)
  local dr=$(( r * 90 / 100 ))
  local dg=$(( g * 90 / 100 ))
  local db=$(( b * 90 / 100 ))

  # Determine text color based on luminance
  local luminance=$(( (299 * r + 587 * g + 114 * b) / 1000 ))
  local tr=247 tg=248 tb=249  # Light text
  if [ $luminance -gt 128 ]; then
    tr=43 tg=48 tb=59  # Dark text
  fi

  case "$theme" in
    thick)
      # Top row: ▄
      printf "    \033[38;2;%d;%d;%dm" "$dr" "$dg" "$db"
      for ((i=0; i<width; i++)); do printf "▄"; done
      printf "\033[0m\n"
      # Middle row: background with text
      printf "    \033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm hostname (10.0.0.1)" "$r" "$g" "$b" "$tr" "$tg" "$tb"
      printf "%*s\033[0m\n" $((width - 22)) ""
      # Bottom row: ▀
      printf "    \033[38;2;%d;%d;%dm" "$dr" "$dg" "$db"
      for ((i=0; i<width; i++)); do printf "▀"; done
      printf "\033[0m\n"
      ;;
    thin)
      # Top row: ┌──┐
      printf "    \033[38;2;%d;%d;%dm┌" "$dr" "$dg" "$db"
      for ((i=0; i<width-2; i++)); do printf "─"; done
      printf "┐\033[0m\n"
      # Middle row: │background│
      printf "    \033[38;2;%d;%d;%dm│\033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm hostname (10.0.0.1)" "$dr" "$dg" "$db" "$r" "$g" "$b" "$tr" "$tg" "$tb"
      printf "%*s\033[0m\033[38;2;%d;%d;%dm│\033[0m\n" $((width - 24)) "" "$dr" "$dg" "$db"
      # Bottom row: └──┘
      printf "    \033[38;2;%d;%d;%dm└" "$dr" "$dg" "$db"
      for ((i=0; i<width-2; i++)); do printf "─"; done
      printf "┘\033[0m\n"
      ;;
    thin-double)
      # Top row: ╔══╗
      printf "    \033[38;2;%d;%d;%dm╔" "$dr" "$dg" "$db"
      for ((i=0; i<width-2; i++)); do printf "═"; done
      printf "╗\033[0m\n"
      # Middle row: ║background║
      printf "    \033[38;2;%d;%d;%dm║\033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm hostname (10.0.0.1)" "$dr" "$dg" "$db" "$r" "$g" "$b" "$tr" "$tg" "$tb"
      printf "%*s\033[0m\033[38;2;%d;%d;%dm║\033[0m\n" $((width - 24)) "" "$dr" "$dg" "$db"
      # Bottom row: ╚══╝
      printf "    \033[38;2;%d;%d;%dm╚" "$dr" "$dg" "$db"
      for ((i=0; i<width-2; i++)); do printf "═"; done
      printf "╝\033[0m\n"
      ;;
  esac
}

main() {
  # Check if config file exists
  if [ ! -f "$CONFIG_FILE" ]; then
    log_error "MOTD config not found: $CONFIG_FILE"
    log_info "Run 'bash install.sh' first to create initial configuration"
    exit 2
  fi

  # Source existing config to get MOTD_COLOR
  source "$CONFIG_FILE"
  local current_color="${MOTD_COLOR:-#4C627D}"
  local current_theme="${MOTD_THEME:-thick}"

  echo ""
  log_info "Franklin MOTD Banner Theme Selector"
  echo ""
  log_info "Current theme: $current_theme"
  echo ""

  # Show all themes with previews
  local idx=1
  for entry in "${THEME_ENTRIES[@]}"; do
    IFS='|' read -r slug label desc <<<"$entry"
    echo ""
    render_theme_preview "$slug" "$current_color"
    printf "  %d) %-12s — %s" "$idx" "$label" "$desc"
    if [ "$slug" = "$current_theme" ]; then
      printf " ${GREEN}(current)${NC}"
    fi
    printf "\n"
    ((idx++))
  done

  echo ""
  printf "Select a banner theme [1-${#THEME_ENTRIES[@]}]: "
  local menu_choice=""
  read -r menu_choice || menu_choice=""

  if [ -z "$menu_choice" ]; then
    log_warning "No selection made, keeping current theme ($current_theme)"
    exit 0
  fi

  if ! [[ $menu_choice =~ ^[0-9]+$ ]] || [ "$menu_choice" -lt 1 ] || [ "$menu_choice" -gt "${#THEME_ENTRIES[@]}" ]; then
    log_error "Invalid choice. Please select a number between 1 and ${#THEME_ENTRIES[@]}"
    exit 1
  fi

  # Extract chosen theme
  local chosen_theme
  IFS='|' read -r chosen_theme _ _ <<<"${THEME_ENTRIES[$((menu_choice - 1))]}"

  # Update motd.env
  if grep -q "^export MOTD_THEME=" "$CONFIG_FILE"; then
    # Update existing line (portable sed)
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/franklin.XXXXXX")
    grep -v "^export MOTD_THEME=" "$CONFIG_FILE" > "$tmpfile"
    echo "export MOTD_THEME=\"$chosen_theme\"" >> "$tmpfile"
    mv "$tmpfile" "$CONFIG_FILE"
  else
    # Append new line
    echo "export MOTD_THEME=\"$chosen_theme\"" >> "$CONFIG_FILE"
  fi

  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
  export MOTD_THEME="$chosen_theme"

  echo ""
  log_success "Banner theme updated to: $chosen_theme"
  log_info "Restart your shell or run 'source ~/.zshrc' to see the new theme"
  echo ""
  log_info "Preview: franklin motd preview"
}

main "$@"
