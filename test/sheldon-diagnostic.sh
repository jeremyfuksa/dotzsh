#!/usr/bin/env bash
# Sheldon Diagnostic Script
# Tests Sheldon installation and plugin loading for Franklin

set -euo pipefail

echo "=== Sheldon Diagnostic Report ==="
echo ""

# 1. Check if Sheldon is installed
echo "1. Sheldon Installation:"
if command -v sheldon >/dev/null 2>&1; then
    echo "   ✓ Sheldon found: $(which sheldon)"
    echo "   ✓ Version: $(sheldon --version | head -1)"
else
    echo "   ✗ Sheldon NOT found in PATH"
    exit 1
fi
echo ""

# 2. Check config file
echo "2. Configuration:"
CONFIG_FILE="${HOME}/.config/sheldon/plugins.toml"
if [ -L "$CONFIG_FILE" ]; then
    TARGET=$(readlink "$CONFIG_FILE")
    echo "   ✓ Config is symlink: $CONFIG_FILE"
    echo "   ✓ Points to: $TARGET"
    if [ -f "$TARGET" ]; then
        echo "   ✓ Target file exists"
    else
        echo "   ✗ Target file MISSING: $TARGET"
        exit 1
    fi
elif [ -f "$CONFIG_FILE" ]; then
    echo "   ✓ Config exists (regular file): $CONFIG_FILE"
else
    echo "   ✗ Config NOT found: $CONFIG_FILE"
    exit 1
fi
echo ""

# 3. Check for invalid 'defer' template (the bug that was fixed)
echo "3. Plugin Configuration Validation:"
if grep -q 'apply.*defer' "$CONFIG_FILE" 2>/dev/null; then
    echo "   ✗ INVALID 'defer' template found in config!"
    echo "   This is the bug - 'defer' is not a valid Sheldon template"
    grep -n 'apply.*defer' "$CONFIG_FILE"
    exit 1
else
    echo "   ✓ No invalid 'defer' templates found"
fi
echo ""

# 4. Test Sheldon source generation
echo "4. Plugin Source Generation:"
if sheldon source >/dev/null 2>&1; then
    echo "   ✓ 'sheldon source' executes without errors"
    PLUGIN_COUNT=$(sheldon source | grep -c '^source ' || true)
    echo "   ✓ Generates $PLUGIN_COUNT plugin source commands"
else
    echo "   ✗ 'sheldon source' FAILED"
    sheldon source 2>&1
    exit 1
fi
echo ""

# 5. Check if plugins are downloaded
echo "5. Downloaded Plugins:"
SHELDON_REPOS="${HOME}/.local/share/sheldon/repos/github.com"
if [ -d "$SHELDON_REPOS" ]; then
    echo "   ✓ Plugin repos directory exists"
    REPO_COUNT=$(find "$SHELDON_REPOS" -maxdepth 2 -type d | wc -l | tr -d ' ')
    echo "   ✓ Found $REPO_COUNT plugin repositories"

    # Check for specific expected plugins
    for plugin in "zsh-users/zsh-autosuggestions" "zsh-users/zsh-syntax-highlighting" "ohmyzsh/ohmyzsh"; do
        if [ -d "${SHELDON_REPOS}/${plugin}" ]; then
            echo "   ✓ $plugin downloaded"
        else
            echo "   ✗ $plugin NOT downloaded"
        fi
    done
else
    echo "   ✗ Plugin repos directory NOT found: $SHELDON_REPOS"
    echo "   Run 'sheldon lock --update' to download plugins"
fi
echo ""

# 6. Test plugin loading in a subshell
echo "6. Plugin Loading Test:"
TEST_OUTPUT=$(zsh -c 'eval "$(sheldon source)" 2>&1 && echo SUCCESS' || echo "FAILED")
if echo "$TEST_OUTPUT" | grep -q "SUCCESS"; then
    echo "   ✓ Plugins load successfully in test shell"

    # Check for common errors
    if echo "$TEST_OUTPUT" | grep -q "command not found: compdef"; then
        echo "   ⚠ Warning: compdef errors detected (compinit ordering issue)"
    fi
else
    echo "   ✗ Plugin loading FAILED"
    echo "$TEST_OUTPUT"
fi
echo ""

# 7. Test specific plugin functionality
echo "7. Plugin Functionality Test:"
FRANKLIN_UI_QUIET=1 zsh -ic 'command -v gst >/dev/null 2>&1' && echo "   ✓ Git aliases (OMZ git plugin) working" || echo "   ✗ Git aliases NOT working"
FRANKLIN_UI_QUIET=1 zsh -ic '[ -n "$ZSH_AUTOSUGGEST_STRATEGY" ]' && echo "   ✓ Autosuggestions plugin loaded" || echo "   ✗ Autosuggestions NOT loaded"
echo ""

# 8. Platform-specific notes
echo "8. Platform Information:"
echo "   OS: $(uname -s)"
echo "   Shell: $SHELL ($(zsh --version))"
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "   ✓ macOS - Sheldon installed via Homebrew"
else
    echo "   ✓ Linux - Sheldon should be in ~/.local/bin"
fi
echo ""

echo "=== Diagnostic Complete ==="
echo ""
echo "If all checks passed, Sheldon is working correctly."
echo "If any checks failed, see the errors above for remediation steps."
