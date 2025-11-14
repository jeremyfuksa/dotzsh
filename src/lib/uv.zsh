#!/bin/zsh
# uv (Python Package Manager) Integration
#
# Loads uv for Python package management

# Add uv to PATH if installed
if [ -d "$HOME/.cargo/bin" ] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# uv completions (if available)
if command -v uv >/dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh 2>/dev/null || true)"
fi
