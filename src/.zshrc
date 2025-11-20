#!/bin/zsh
# franklin Configuration File
#
# Main shell configuration that sources all franklin libraries

# ============================================================================
# Core Setup
# ============================================================================

# Detect Franklin location from where this .zshrc actually lives
if [[ -L ~/.zshrc ]]; then
  # Follow symlink to find the repo location
  export FRANKLIN_CONFIG_DIR="$(cd "$(dirname "$(readlink ~/.zshrc)")" && pwd)"
else
  # Fallback if not a symlink (user copied file instead)
  export FRANKLIN_CONFIG_DIR="${FRANKLIN_CONFIG_DIR:-$HOME/.config/franklin}"
fi
export ZSH_CONFIG_DIR="$FRANKLIN_CONFIG_DIR"
export FRANKLIN_PLUGINS_DIR="${FRANKLIN_PLUGINS_DIR:-$FRANKLIN_CONFIG_DIR/lib}"

# User configuration (e.g., MOTD color)
if [ -f "$FRANKLIN_CONFIG_DIR/motd.env" ]; then
  source "$FRANKLIN_CONFIG_DIR/motd.env"
fi

: "${FRANKLIN_LOCAL_CONFIG:=${HOME}/.franklin.local.zsh}"
if [ -f "$FRANKLIN_LOCAL_CONFIG" ]; then
  source "$FRANKLIN_LOCAL_CONFIG"
fi

# Early platform detection
if [ -f "$FRANKLIN_PLUGINS_DIR/os_detect.zsh" ]; then
  source "$FRANKLIN_PLUGINS_DIR/os_detect.zsh"
fi

# ============================================================================
# Sheldon Plugin Manager
# ============================================================================

# Initialize Sheldon if available
if command -v sheldon >/dev/null 2>&1; then
  # Sheldon config directory
  export SHELDON_CONFIG_DIR="${SHELDON_CONFIG_DIR:-$HOME/.config/franklin/sheldon}"

  # Initialize Sheldon plugins
  eval "$(sheldon source)"
else
  echo "franklin: Sheldon not found; skipping plugin initialization" >&2
  echo "franklin: Install with: brew install sheldon (macOS) or see https://sheldon.cli.rs" >&2
fi

# ============================================================================
# Completion System
# ============================================================================

_franklin_init_completion() {
  autoload -Uz compinit 2>/dev/null || return
  : "${FRANKLIN_ZCOMP_CACHE:=$FRANKLIN_CONFIG_DIR/.zcompdump}"
  local cache_file="$FRANKLIN_ZCOMP_CACHE"
  local cache_dir="${cache_file:h}"
  if [ -n "$cache_dir" ] && [ ! -d "$cache_dir" ]; then
    mkdir -p "$cache_dir" 2>/dev/null || true
  fi

  local refresh_cache=1
  if [ -f "$cache_file" ]; then
    refresh_cache=0
    if zmodload zsh/stat 2>/dev/null; then
      local -a _fr_comp_stat
      if zstat -A _fr_comp_stat +mtime -- "$cache_file" 2>/dev/null; then
        if [[ -z "${EPOCHSECONDS+x}" ]]; then
          zmodload zsh/datetime 2>/dev/null || true
        fi
        local now=${EPOCHSECONDS:-$(date +%s)}
        local age=$(( now - ${_fr_comp_stat[1]} ))
        if (( age > 86400 )); then
          refresh_cache=1
        fi
      else
        refresh_cache=1
      fi
    else
      refresh_cache=1
    fi
  fi

  if [ "$refresh_cache" -eq 0 ]; then
    compinit -C -d "$cache_file" >/dev/null 2>&1 || compinit -i -d "$cache_file"
  else
    compinit -i -d "$cache_file"
  fi
}
_franklin_init_completion
unset -f _franklin_init_completion

# ============================================================================
# Shell Options
# ============================================================================

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=200000
SAVEHIST=200000

# History options
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Other options
setopt AUTO_CD
setopt CORRECT
setopt PROMPT_SUBST
setopt INTERACTIVE_COMMENTS

# ============================================================================
# Key Bindings
# ============================================================================

# Platform-specific keybindings
if [ "$OS_FAMILY" = "macos" ]; then
  # macOS / Darwin terminals
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
else
  # Linux terminals (most honor the same sequences, but keep separate
  # so render_os_specific.py can emit OS-trimmed bundles)
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi


# ============================================================================
# Aliases
# ============================================================================

if [[ "$OS_FAMILY" == "macos" || "$OS_FAMILY" == "darwin" ]]; then
  # macOS uses -G for color (requires CLICOLOR)
  export CLICOLOR=1
  export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
  alias ls='command ls -G'
  alias ll='command ls -laG'
  alias la='command ls -aG'
  alias lh='command ls -lhG'
else
  # Linux/Unix: rely on GNU coreutils --color flags
  alias ls='command ls --color=auto'
  alias ll='command ls -la --color=auto'
  alias la='command ls -a --color=auto'
  alias lh='command ls -lh --color=auto'
fi

alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'

# Grep with colors
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# bat (cat with syntax highlighting)
if command -v bat >/dev/null 2>&1; then
  # macOS/Fedora: bat command available
  alias cat='bat --paging=never'
  alias bcat='bat'  # Original bat with paging
elif command -v batcat >/dev/null 2>&1; then
  # Debian/Ubuntu: batcat command (naming conflict)
  alias cat='batcat --paging=never'
  alias bat='batcat'
  alias bcat='batcat'
fi

# ============================================================================
# Starship Prompt
# ============================================================================

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ============================================================================
# Notifications
# ============================================================================

if [ -f "$FRANKLIN_PLUGINS_DIR/notify.zsh" ]; then
  source "$FRANKLIN_PLUGINS_DIR/notify.zsh"
fi

# ============================================================================
# NVM (Node Version Manager)
# ============================================================================

if [ -f "$FRANKLIN_PLUGINS_DIR/nvm.zsh" ]; then
  source "$FRANKLIN_PLUGINS_DIR/nvm.zsh"
elif [ -s "$HOME/.nvm/nvm.sh" ]; then
  source "$HOME/.nvm/nvm.sh"
  [ -s "$HOME/.nvm/bash_completion" ] && source "$HOME/.nvm/bash_completion"
fi

# ============================================================================
# System Message of the Day (motd) Display
# ============================================================================

FRANKLIN_ENABLE_MOTD="${FRANKLIN_ENABLE_MOTD:-1}"
FRANKLIN_SHOW_MOTD_ON_LOGIN="${FRANKLIN_SHOW_MOTD_ON_LOGIN:-1}"
export FRANKLIN_ENABLE_MOTD FRANKLIN_SHOW_MOTD_ON_LOGIN

if [ "$FRANKLIN_ENABLE_MOTD" -eq 1 ]; then
  if [ -f "$FRANKLIN_PLUGINS_DIR/motd-helpers.zsh" ]; then
    source "$FRANKLIN_PLUGINS_DIR/motd-helpers.zsh"
  fi

  if [ -f "$FRANKLIN_PLUGINS_DIR/motd.zsh" ]; then
    source "$FRANKLIN_PLUGINS_DIR/motd.zsh"
    if [ "$FRANKLIN_SHOW_MOTD_ON_LOGIN" -eq 1 ] && command -v motd >/dev/null 2>&1; then
      motd
    fi
  fi
fi

# ============================================================================
# Functions
# ============================================================================

# cleanup-path: Remove duplicates and invalid entries from PATH
cleanup-path() {
  typeset -U path
  path=(${path:#*/.antigen/bundles/*})
  export PATH=${(j/:/)path}
}

# install: Unified package manager wrapper
install() {
  if [ $# -eq 0 ]; then
    echo "Usage: install <package...>" >&2
    return 1
  fi

  if [ "$OS_FAMILY" = "macos" ] && command -v brew >/dev/null 2>&1; then
    brew install "$@"
  elif [ "$OS_FAMILY" = "debian" ]; then
    sudo apt install -y "$@"
  elif [ "$OS_FAMILY" = "fedora" ]; then
    sudo dnf install -y "$@"
  else
    echo "Error: Unsupported OS or package manager not found" >&2
    return 1
  fi
}

# update-all: Update all components
update-all() {
  if [ -f "$ZSH_CONFIG_DIR/update-all.sh" ]; then
    bash "$ZSH_CONFIG_DIR/update-all.sh" "$@"
  else
    echo "update-all.sh not found"
    return 1
  fi
}

# franklin: Helper CLI wrapper
franklin() {
  local cli="$ZSH_CONFIG_DIR/franklin"
  if [ ! -x "$cli" ]; then
    cli="$ZSH_CONFIG_DIR/franklin.sh"
  fi

  if [ -x "$cli" ]; then
    "$cli" "$@"
  else
    echo "Franklin CLI not found" >&2
    return 1
  fi
}

# ============================================================================
# PATH Cleanup
# ============================================================================

# Clean up PATH on shell startup (remove duplicates and invalid entries)
cleanup-path
