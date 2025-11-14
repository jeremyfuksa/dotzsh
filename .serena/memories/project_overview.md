# dotzsh Project Overview

## Purpose
A spec-first, idempotent, cross-platform shell configuration system for macOS, Ubuntu, Debian, and Fedora. Combines Zsh, Antigen, Starship, and Node.js into a cohesive development environment.

## Tech Stack
- **Shell**: Zsh (primary), POSIX sh/Bash (for installation scripts)
- **Package Managers**: Homebrew (macOS), apt (Ubuntu/Debian), dnf (Fedora)
- **Plugin Manager**: Antigen
- **Prompt**: Starship
- **Node Manager**: NVM (Node Version Manager)
- **Testing**: Bash-based unit tests (no external framework)

## Key Components
1. **Platform Detection** (`lib/os_detect.sh`, `lib/os_detect.zsh`)
2. **Installation** (`install.sh`, `lib/install_*.sh`)
3. **Update System** (`update-all.sh`)
4. **Shell Helpers** (`lib/notify.zsh`, `lib/nvm.zsh`)
5. **MOTD Dashboard** (`lib/motd.zsh`, `lib/motd-helpers.zsh`)
6. **Configuration** (`.zshrc`, `starship.toml`)

## Platform Support
- macOS 10.15+
- Ubuntu 20.04+
- Debian 11+
- Fedora 36+
