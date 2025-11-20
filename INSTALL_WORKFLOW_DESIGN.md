# Franklin Install Workflow Design

## Problem Statement

The current install script has several reliability issues when existing installations are present:

### Current Issues

1. **Antigen Conflicts**
   - `ensure_antigen_installed()` only checks `~/.antigen/antigen.zsh`
   - Doesn't detect brew-installed antigen (`/opt/homebrew/Cellar/antigen/...`)
   - Downloads duplicate copy to `~/.antigen` even when brew version exists
   - Result: Two conflicting antigen installations, unreliable plugin loading

2. **Starship Conflicts**
   - Multiple installation methods (brew, snap, dnf, official installer)
   - No detection of existing installations before choosing method
   - Can result in multiple starship binaries in PATH:
     - `/opt/homebrew/bin/starship` (brew)
     - `/usr/local/bin/starship` (official installer)
   - Result: Wrong version may be used, unpredictable behavior

3. **No Version Checking**
   - Install script doesn't check if existing tools meet minimum versions
   - Doesn't upgrade existing tools to Franklin's pinned versions
   - Can leave outdated tools in place

4. **No Consolidation**
   - Doesn't migrate existing installations to Franklin's preferred locations
   - Doesn't clean up conflicting installations

5. **Performance Impact**
   - Antigen is significantly slower than modern alternatives (sheldon, zinit)
   - Critical on slower machines (Raspberry Pi, older hardware)
   - **Note**: Starship remains the prompt choice (actively maintained, performance acceptable)

## Design Goals

1. **Idempotent** - Safe to re-run multiple times
2. **Smart Detection** - Find all existing installations
3. **Version-Aware** - Check versions and upgrade if needed
4. **Consolidation** - Move/reuse existing installations when appropriate
5. **Performance** - Use sheldon instead of antigen for Raspberry Pi/weak machines
6. **Clean** - Remove conflicting installations
7. **Backup** - Preserve user data before making changes

## Proposed Workflow

### Universal Tool Installation Pattern

For each tool (sheldon, starship, bat, NVM, etc.):

```
1. DETECT phase
   └─> Find all installations (brew, system, manual, etc.)
   └─> Record paths, versions, installation methods

2. EVALUATE phase
   └─> Determine preferred installation method for platform
   └─> Check if any existing install meets version requirement
   └─> Decide: reuse, upgrade, or fresh install

3. CONSOLIDATE phase
   └─> If reusing: ensure it's accessible to Franklin
   └─> If upgrading: use existing package manager
   └─> If fresh install: use preferred method for platform

4. VERIFY phase
   └─> Confirm tool is accessible
   └─> Check version meets requirement
   └─> Test basic functionality

5. CLEANUP phase
   └─> Remove conflicting installations
   └─> Clean up legacy/deprecated locations
```

### Tool-Specific Workflows

#### Sheldon (replaces Antigen)

**Preferred installation methods:**
- macOS: Homebrew (`brew install sheldon`)
- Debian: Manual install from GitHub releases (no apt package)
- Fedora: Manual install from GitHub releases (no dnf package)

**Detection locations:**
- Homebrew: `/opt/homebrew/bin/sheldon` or `/usr/local/bin/sheldon`
- Manual: `~/.local/bin/sheldon`
- Cargo: `~/.cargo/bin/sheldon`

**Migration from Antigen:**
- Detect existing Antigen installation
- Convert Antigen plugins to sheldon `plugins.toml`
- Backup `~/.antigen` directory
- Remove Antigen from PATH precedence

**plugins.toml format:**
```toml
# Franklin Plugin Configuration

[plugins.zsh-syntax-highlighting]
github = "zsh-users/zsh-syntax-highlighting"

[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"

[plugins.zsh-completions]
github = "zsh-users/zsh-completions"

[plugins.git]
github = "ohmyzsh/ohmyzsh"
dir = "plugins/git"

[plugins.history-substring-search]
github = "ohmyzsh/ohmyzsh"
dir = "plugins/history-substring-search"

[plugins.colored-man-pages]
github = "ohmyzsh/ohmyzsh"
dir = "plugins/colored-man-pages"

[plugins.command-not-found]
github = "ohmyzsh/ohmyzsh"
dir = "plugins/command-not-found"
```

#### Starship

**Preferred installation methods:**
- macOS: Homebrew (Brewfile)
- Debian: snap > official installer
- Fedora: dnf

**Detection locations:**
- Homebrew: `/opt/homebrew/bin/starship`
- snap: `/snap/bin/starship`
- dnf: `/usr/bin/starship`
- Official installer: `/usr/local/bin/starship`
- Cargo: `~/.cargo/bin/starship`

**Consolidation strategy:**
- Keep package manager version if present (brew/snap/dnf)
- Remove official installer version if package manager version exists
- Only use official installer as last resort

#### Bat

**Preferred installation methods:**
- macOS: Homebrew (Brewfile)
- Debian: apt (`bat` package, command is `batcat`)
- Fedora: dnf (`bat` package)

**Detection locations:**
- Homebrew: `/opt/homebrew/bin/bat`
- apt: `/usr/bin/batcat` (aliased to `bat` in .zshrc)
- dnf: `/usr/bin/bat`
- Cargo: `~/.cargo/bin/bat`

**No conflicts expected** - package managers handle this cleanly

#### NVM & Node.js

**Preferred installation:**
- All platforms: Manual install to `~/.nvm` (official installer)

**Detection locations:**
- Manual: `~/.nvm/nvm.sh`
- Homebrew: `/opt/homebrew/opt/nvm` (not recommended, slower)

**Consolidation strategy:**
- If brew-installed: warn user and suggest migration to manual
- Manual installation is preferred (faster, more compatible)

**Node.js Version Policy (Interactive):**

This is the **only interactive question** during installation.

1. **On first install:** Ask user to choose policy (lts/keep/manual)
2. **Store preference:** `~/.config/franklin/node.policy`
3. **On updates:** Respect policy
   - `lts`: Auto-update to latest LTS
   - `keep`: Never touch Node version (for legacy projects)
   - `manual`: Install NVM but user manages Node

**Rationale:**
- Node ecosystem is fragmented (v14, v16, v18, v20...)
- Projects often locked to specific versions
- Breaking system-installed Node breaks legacy projects
- This is high-impact enough to warrant asking

**Implementation:**
```bash
# In install.sh after NVM installation
if [ ! -f ~/.config/franklin/node.policy ]; then
  prompt_node_policy  # Interactive prompt
fi

# Apply policy
case "$FRANKLIN_NODE_POLICY" in
  lts)
    nvm install --lts
    nvm alias default lts/*
    ;;
  keep)
    # Keep existing Node version, don't install new
    ;;
  manual)
    echo "NVM installed. Run 'nvm install --lts' when ready."
    ;;
esac
```

#### Python & UV

**Preferred installation methods:**
- macOS: Homebrew (python3, uv via Brewfile)
- Debian: apt (python3, python3-pip, python3-venv) + UV via official installer
- Fedora: dnf (python3, python3-pip) + UV via official installer

**Detection locations:**
- System Python: `/usr/bin/python3`, `/opt/homebrew/bin/python3`
- UV: `~/.cargo/bin/uv`, `/opt/homebrew/bin/uv`

**No version policy needed (Asymmetric by design):**
- Install system Python 3.x (automatic, no questions asked)
- Install UV (handles venv, packages, and optional version management)
- Users who need specific Python versions: `uv python install 3.11`

**Why no interactive prompt like Node?**
- **Python 3.9+ mostly compatible** - Less version fragmentation than Node
- **Virtual environments (venv) handle isolation** - Don't need multiple Python versions
- **UV provides escape hatch** - Power users can use `uv python install 3.12` if needed
- **System Python works for 95% of users** - Simpler default experience
- **Lower ecosystem fragmentation** - Not like Node's v14/v16/v18/v20 chaos

**Asymmetric approach rationale:**
- **Node**: High fragmentation, breaking changes between versions → Interactive policy required
- **Python**: Low fragmentation, stable compatibility → Automatic installation sufficient
- **Result**: Simpler UX (one question instead of two), matches real-world needs

**UV's role:**
```bash
# UV handles Python versions (like pyenv), venvs, and packages
uv python install 3.11        # Install specific Python version
uv venv --python 3.11          # Create venv with specific version
uv pip install django          # Install packages (faster than pip)
```

UV is like **NVM + venv + pip** combined, but Rust-based (extremely fast).

## Implementation Plan

### Phase 1: Create Detection Library (`lib/detect_tools.sh`)

```bash
detect_sheldon() {
  # Returns: version|install_type|path
  # install_type: brew|manual|cargo|absent
}

detect_starship() {
  # Returns: version|install_type|path
  # install_type: brew|snap|dnf|official|cargo|absent
}

detect_bat() {
  # Returns: version|install_type|path
  # install_type: brew|apt|dnf|cargo|absent
}

detect_nvm() {
  # Returns: version|install_type|path
  # install_type: manual|brew|absent
}
```

### Phase 2: Create Installation Helpers (`lib/install_helpers_v2.sh`)

```bash
ensure_sheldon_installed() {
  local detected
  detected=$(detect_sheldon)
  # Parse detection result
  # Decide on action (reuse/upgrade/install)
  # Execute action
  # Verify result
}

migrate_antigen_to_sheldon() {
  # Backup ~/.antigen
  # Create plugins.toml from Antigen bundles
  # Update .zshrc to source sheldon
}

consolidate_starship() {
  local detected
  detected=$(detect_starship)
  # If multiple installations found
  # Keep package manager version
  # Remove other versions
}
```

### Phase 3: Update Platform Installers

Update `install_macos.sh`, `install_debian.sh`, `install_fedora.sh` to:
1. Use new detection + installation helpers
2. Remove direct package installation loops
3. Add consolidation step after installation

### Phase 4: Update `.zshrc`

Replace Antigen loading with sheldon:
```zsh
# Initialize sheldon plugin manager
if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
else
  echo "franklin: sheldon not found; skipping plugin initialization" >&2
fi
```

### Phase 5: Migration Script

Create `src/scripts/migrate_to_sheldon.sh` for existing Franklin users:
- Detect Antigen installation
- Convert plugins to sheldon format
- Update .zshrc
- Verify sheldon works
- Optionally remove Antigen

## Testing Strategy

### Test Scenarios

1. **Clean Install** - Fresh system with no existing tools
2. **Brew-Only Install** - System with brew-installed tools
3. **Mixed Install** - System with mix of brew/manual/snap tools
4. **Conflicting Install** - Multiple versions of same tool
5. **Outdated Install** - Existing tools with old versions
6. **Raspberry Pi** - Performance testing on weak hardware

### Test Matrices

| Platform | Scenario | Expected Result |
|----------|----------|-----------------|
| macOS | Clean | Install via Brewfile |
| macOS | Brew antigen exists | Migrate to sheldon, remove antigen |
| macOS | Multiple starship | Keep brew, remove others |
| Debian | Clean | Install sheldon manually, others via apt |
| Debian | snap starship | Keep snap starship |
| Fedora | Clean | Install sheldon manually, others via dnf |
| Raspberry Pi | All scenarios | Verify sheldon performance gain |

## Versioning & Migration Strategy

### Semantic Versioning

**Franklin 2.0.0** represents a major version bump due to breaking changes:

- **1.x** - Antigen-based plugin management (current)
- **2.0+** - Sheldon-based plugin management (new architecture)

### Breaking Changes in 2.0

1. **Plugin Manager Change**
   - Old: Antigen (`~/.antigen/`)
   - New: Sheldon (`~/.local/share/sheldon/`)

2. **Plugin Configuration**
   - Old: Antigen bundles in `.zshrc`
   - New: `plugins.toml` + sheldon init in `.zshrc`

3. **Installation Method (macOS)**
   - Old: Manual package installation loop
   - New: Brewfile-based declarative dependencies

4. **Version Pinning**
   - Old: `lib/versions.sh` constants
   - New: Brewfile versions (macOS), versions.sh (Linux)

### Update Script Detection (Critical!)

**In `update-franklin.sh`:**

```bash
# Check current Franklin version
current_version=$(cat "$FRANKLIN_CONFIG_DIR/VERSION" 2>/dev/null || echo "0.0.0")
major_version=$(echo "$current_version" | cut -d. -f1)

# Check latest available version
latest_version=$(curl -fsSL https://raw.githubusercontent.com/[USER]/franklin/main/VERSION 2>/dev/null || echo "0.0.0")
latest_major=$(echo "$latest_version" | cut -d. -f1)

# Detect major version upgrade
if [ "$major_version" -lt "$latest_major" ]; then
  cat <<EOF

╔════════════════════════════════════════════════════════════════╗
║                  Franklin ${latest_version} Available                      ║
║                                                                ║
║  This is a MAJOR version upgrade with breaking changes.       ║
║                                                                ║
║  What's changing in 2.0:                                       ║
║  • Plugin manager: Antigen → Sheldon (faster, Rust-based)     ║
║  • Configuration: plugins.toml replaces .zshrc bundles        ║
║  • Automatic migration of your existing plugins               ║
║                                                                ║
║  Why upgrade?                                                  ║
║  ✓ Significantly faster shell startup (critical for RPi)      ║
║  ✓ Modern, actively maintained architecture                   ║
║  ✓ Better conflict detection and resolution                   ║
║  ✓ Automatic backup and rollback support                      ║
║                                                                ║
║  1.x Status:                                                   ║
║  • End of Life (no updates, bug fixes, or security patches)   ║
║  • Frozen at current version                                   ║
║  • Upgrade to 2.0 recommended for continued support           ║
║                                                                ║
║  Choose your path:                                             ║
║  [1] Upgrade to 2.0 (recommended)                              ║
║  [2] Stay on 1.x (frozen, unsupported)                         ║
║  [3] Show detailed changelog                                   ║
║  [4] Cancel update                                             ║
╚════════════════════════════════════════════════════════════════╝

EOF

  read -r -p "Your choice [1-4]: " choice

  case "$choice" in
    1)
      log_info "Proceeding with 2.0 upgrade..."
      FRANKLIN_ALLOW_MAJOR_UPGRADE=1
      ;;
    2)
      log_warning "Staying on 1.x (unsupported, frozen version)"
      # Pin to current version, block all updates
      FRANKLIN_BLOCK_ALL_UPDATES=1
      echo "$(cat "$FRANKLIN_CONFIG_DIR/VERSION")" > ~/.config/franklin/VERSION_PINNED
      log_info "Franklin updates disabled. To re-enable: rm ~/.config/franklin/VERSION_PINNED"
      ;;
    3)
      # Show full changelog
      show_changelog "$current_version" "$latest_version"
      # Re-prompt
      ;;
    4)
      log_info "Update cancelled"
      exit 0
      ;;
    *)
      log_error "Invalid choice"
      exit 1
      ;;
  esac
fi
```

### Migration Paths

#### Path A: Upgrade to 2.0 (Recommended)

**Automatic Migration Process:**

1. **Pre-Migration Backup**
   ```bash
   backup_dir=~/.local/share/franklin/backups/pre-2.0-$(date +%s)
   mkdir -p "$backup_dir"

   # Backup everything
   cp -r ~/.zshrc "$backup_dir/"
   cp -r ~/.antigen "$backup_dir/" 2>/dev/null || true
   cp -r ~/.config/franklin "$backup_dir/" 2>/dev/null || true

   # Create migration manifest
   cat > "$backup_dir/MANIFEST.txt" <<EOF
   Franklin 1.x → 2.0 Migration Backup
   Created: $(date)

   Backed up files:
   - .zshrc
   - .antigen/ (Antigen plugin cache)
   - .config/franklin/ (Franklin configuration)

   To rollback: franklin rollback pre-2.0
   EOF
   ```

2. **Plugin Migration**
   ```bash
   # Extract Antigen bundles from .zshrc
   extract_antigen_plugins() {
     grep "antigen bundle" ~/.zshrc | while read -r line; do
       # Parse: antigen bundle zsh-users/zsh-syntax-highlighting
       plugin=$(echo "$line" | sed 's/.*antigen bundle //' | tr -d '"' | tr -d "'")
       echo "$plugin"
     done
   }

   # Convert to plugins.toml
   generate_plugins_toml() {
     cat > ~/.config/franklin/plugins.toml <<EOF
   # Franklin 2.0 Plugin Configuration
   # Migrated from Antigen on $(date)

   EOF

     extract_antigen_plugins | while read -r plugin; do
       # Convert github:org/repo to sheldon format
       plugin_name=$(basename "$plugin")
       cat >> ~/.config/franklin/plugins.toml <<EOF
   [plugins.${plugin_name}]
   github = "${plugin}"

   EOF
     done
   }
   ```

3. **Install Sheldon**
   - macOS: Add to Brewfile, `brew bundle install`
   - Linux: Download from GitHub releases

4. **Update .zshrc**
   - Remove Antigen loading block
   - Add Sheldon initialization
   - Preserve user customizations in `.franklin.local.zsh`

5. **Verification**
   ```bash
   # Test new shell
   zsh -c 'source ~/.zshrc && sheldon list'

   # Compare plugin list
   diff <(antigen list | sort) <(sheldon list | sort)

   # Measure startup time
   old_time=$(cat "$backup_dir/startup-time.txt")
   new_time=$(time zsh -i -c exit 2>&1 | grep real)

   echo "Shell startup: ${old_time} → ${new_time}"
   ```

6. **Cleanup (Optional)**
   ```bash
   # After confirming everything works
   rm -rf ~/.antigen
   brew uninstall antigen  # macOS only
   ```

#### Path B: Stay on 1.x (Unsupported, Frozen)

**What "Stay on 1.x" means:**

- ❌ No bug fixes
- ❌ No security updates
- ❌ No new features
- ✓ Frozen at current version
- ✓ Continues to work (until OS/dependency changes break it)

**Implementation:**

```bash
# In update-franklin.sh
if [ "$FRANKLIN_BLOCK_ALL_UPDATES" = "1" ]; then
  # Pin current version
  current_version=$(cat "$FRANKLIN_CONFIG_DIR/VERSION")
  echo "$current_version" > ~/.config/franklin/VERSION_PINNED

  log_warning "Franklin updates disabled"
  log_info "Current version: $current_version (frozen)"
  log_info "To re-enable updates: rm ~/.config/franklin/VERSION_PINNED"
  log_info "To upgrade to 2.0 later: franklin update --force"
  exit 0
fi

# Check if version is pinned
if [ -f ~/.config/franklin/VERSION_PINNED ]; then
  pinned_version=$(cat ~/.config/franklin/VERSION_PINNED)
  log_info "Franklin updates are pinned at version $pinned_version"
  log_info "To upgrade: rm ~/.config/franklin/VERSION_PINNED && franklin update"
  exit 0
fi
```

**When to stay on 1.x:**

- Production system that "just works" and can't risk changes
- Testing 2.0 on separate machine first
- Planning to migrate away from Franklin
- Temporary: will upgrade within days/weeks

**Risks of staying on 1.x:**

- No security patches if vulnerabilities discovered
- May break with future macOS/Linux updates
- No support or help with issues
- Performance remains slower (Antigen vs Sheldon)

### Testing Migration

**Pre-release Testing (Beta Program):**

1. Release 2.0.0-beta.1 with migration script
2. Recruit beta testers (especially Raspberry Pi users)
3. Test migration from various 1.x versions
4. Collect feedback on migration UX
5. Fix issues before 2.0.0 GA

**Migration Test Scenarios:**

| Scenario | Expected Result |
|----------|-----------------|
| Fresh 1.5.8 install | Clean migration, all plugins work |
| Heavily customized .zshrc | User mods preserved in .franklin.local.zsh |
| Custom Antigen plugins | All plugins migrated to plugins.toml |
| Conflicting oh-my-zsh | Detected, offer resolution options |
| Low disk space | Graceful failure with cleanup |
| Network failure during upgrade | Rollback to 1.x automatically |

### Rollback Support

**Automated Rollback:**

```bash
franklin rollback pre-2.0
```

**Manual Rollback:**

```bash
# Restore backup
backup_dir=$(ls -t ~/.local/share/franklin/backups/pre-2.0-* | head -1)
cp "$backup_dir/.zshrc" ~/.zshrc

# Reinstall 1.x
cd ~/.config/franklin
git fetch origin v1.x-maintenance
git checkout v1.x-maintenance
bash install.sh

# Restore Antigen
cp -r "$backup_dir/.antigen" ~/ 2>/dev/null || true

exec zsh
```

## Migration Guide for Users

**Documentation (CHANGELOG, docs, release notes):**

### Before Upgrading

1. **Check current version**: `franklin version`
2. **Review changelog**: `franklin changelog 2.0`
3. **Backup manually** (optional): `franklin backup`
4. **Check disk space**: `df -h ~` (need ~500MB free)

### During Upgrade

1. Run update: `franklin update` or `bash update-franklin.sh`
2. See 2.0 prompt, choose option [1]
3. Watch automated migration
4. Wait for verification

### After Upgrade

1. **Test shell**: `exec zsh`
2. **Verify plugins**: `sheldon list`
3. **Check customizations**: `cat ~/.franklin.local.zsh`
4. **Measure performance**: `franklin benchmark`
5. **Report issues**: `franklin report-issue` (includes logs)

### If Something Breaks

```bash
# Quick rollback
franklin rollback pre-2.0

# Manual rollback
cd ~/.config/franklin
git checkout v1.x-maintenance
bash install.sh

# Get help
open https://github.com/[USER]/franklin/issues/new?template=2.0-migration-issue
```

### Customizations That Need Manual Update

**Custom Antigen plugins** (not in standard list):

```bash
# Old (.zshrc)
antigen bundle my-user/my-custom-plugin

# New (plugins.toml)
[plugins.my-custom-plugin]
github = "my-user/my-custom-plugin"
```

**Antigen theme** (if customized):

```bash
# Old (.zshrc)
antigen theme romkatv/powerlevel10k

# New (.zshrc)
# Themes not managed by sheldon - install manually
# Starship is Franklin's default prompt
```

**Antigen options**:

```bash
# Old (.zshrc)
antigen bundle zsh-users/zsh-syntax-highlighting --branch=main

# New (plugins.toml)
[plugins.zsh-syntax-highlighting]
github = "zsh-users/zsh-syntax-highlighting"
branch = "main"
```

## Realistic "No-Touch" Features for 2.0

Franklin should be "set and forget" without becoming a maintenance nightmare for a hobby project (259 clones).

### Features to Include (Practical, Low Complexity)

#### 1. Update Reminder (Not Auto-Update)
```bash
# Check once per week on shell start
if [ "$(find ~/.config/franklin/LAST_CHECK -mtime +7 2>/dev/null)" ]; then
  echo "💡 Franklin update available. Run: franklin update"
  touch ~/.config/franklin/LAST_CHECK
fi
```
- Non-intrusive
- User controls when to update
- No background processes

#### 2. Startup Performance Warning
```bash
# Simple threshold check at end of .zshrc
if [ "$FRANKLIN_STARTUP_TIME" -gt 500 ]; then
  echo "⚠️  Slow shell startup (${FRANKLIN_STARTUP_TIME}ms)"
  echo "   Run: franklin benchmark"
fi
```
- One simple check
- Helps users detect problems
- No complexity

#### 3. Automatic Backup Cleanup
```bash
# During updates/installs - keep last 5 backups
franklin_cleanup_old_backups() {
  local backups=~/.local/share/franklin/backups
  ls -t "$backups" | tail -n +6 | xargs rm -rf
}
```
- Prevents disk bloat
- Runs during updates only
- Simple one-liner

#### 4. Self-Heal Broken Plugins
```bash
# In .zshrc - if sheldon fails to load
if ! sheldon source 2>/dev/null; then
  echo "Franklin: Regenerating plugin cache..."
  sheldon lock --update >/dev/null 2>&1
fi
```
- Fixes most common plugin issue
- Silent unless needed
- No user intervention

#### 5. NVM Cleanup on Update
```bash
# In update-all.sh after NVM update
# Keep only current + LTS, remove old versions
nvm ls | grep -v "$(nvm current)\|lts" | xargs -n1 nvm uninstall
```
- Prevents NVM bloat (common issue)
- Runs during updates
- Simple, battle-tested

#### 6. `franklin doctor` Command
```bash
franklin doctor:
  ✓ Shell startup time: 247ms
  ✓ All required tools installed
  ✓ Plugins loading correctly
  ⚠ 3 old Node versions found (run: franklin cleanup)
  ✓ No disk space issues
```
- User-initiated diagnostic
- Helpful for troubleshooting
- Not automatic

### Features to Skip (Too Complex)

- ❌ Auto-updates (background processes, failure modes)
- ❌ Cross-machine sync (requires backend)
- ❌ Email/desktop notifications (platform-specific)
- ❌ Cron/systemd timers (setup complexity)
- ❌ Sophisticated caching (over-engineering)

### 2.0 Scope Summary

**Core improvements:**
1. Sheldon (faster than Antigen)
2. Smart detection/consolidation
3. Node version policy (interactive)
4. Update reminder (passive)
5. Self-healing (broken plugins)
6. Performance warning
7. Auto-cleanup (backups, old Node)
8. `franklin doctor` (diagnostics)

**Total new code:** ~200-300 lines
**Maintenance burden:** Low
**User impact:** High

## Timeline

- **Design Review** - ✅ Complete
- **Implementation** - 1-2 weeks
- **Testing** - 1 week (especially Raspberry Pi testing)
- **Documentation** - Parallel with testing
- **Beta Release** - 2.0.0-beta.1 for migration testing
- **GA Release** - After beta feedback

## First-Run Install Checklist

### 1. System Discovery & Validation

**Environment Detection:**
- [ ] OS/Distribution (macOS, Debian, Fedora, etc.)
- [ ] Architecture (x86_64, arm64/aarch64)
- [ ] Shell version (Zsh version check)
- [ ] Available disk space (warn if < 1GB free)
- [ ] Network connectivity test
- [ ] Sudo/admin access verification

**Conflict Detection:**
- [ ] Existing shell configurations (.zshrc, .zshenv, .zprofile)
- [ ] Existing plugin managers (oh-my-zsh, antigen, zinit, antibody)
- [ ] Existing prompts (powerlevel10k, pure, spaceship)
- [ ] Package manager conflicts (multiple Homebrew installs, etc.)

### 2. User Preferences (Interactive Mode)

**Single Interactive Question: Node.js Version Policy**

Franklin is opinionated about everything EXCEPT Node.js versions (legacy project compatibility).

```bash
╔════════════════════════════════════════════════════════════════╗
║                    Node.js Configuration                       ║
╚════════════════════════════════════════════════════════════════╝

Franklin will install NVM (Node Version Manager).

Current Node: v16.14.2 (EOL: September 2023)
Latest LTS:   v20.11.0 (Iron)

Choose your Node.js policy:

  [1] Install latest LTS (v20.11.0) - Recommended
      → Franklin will keep Node updated to latest LTS

  [2] Keep current version (v16.14.2)
      → Franklin won't change your Node version
      → Use this for legacy projects

  [3] Let me manage Node myself
      → Install NVM but don't install Node
      → You'll use 'nvm install' manually

Your choice [1-3]: _
```

**Policy Storage:** `~/.config/franklin/node.policy`
```bash
FRANKLIN_NODE_POLICY=lts  # or: keep, manual
FRANKLIN_NODE_VERSION=v16.14.2  # if policy=keep
FRANKLIN_NODE_LAST_CHECK=1705420800
```

**Update Behavior:**
- `lts`: Auto-update to latest LTS on `franklin update`
- `keep`: Never change Node version
- `manual`: Notify about updates but don't install

**Change Policy:** `franklin node-policy [lts|keep|manual]`

**Everything Else is Automatic:**
- Python (system Python 3.x + UV for version management)
- Zsh, Starship, bat, sheldon, Antigen
- All installed/updated automatically without asking

**Non-Interactive Mode:**
- [ ] Accept flags: `--node-policy=[lts|keep|manual]`, `--yes`
- [ ] Environment variable: `FRANKLIN_NODE_POLICY=lts`
- [ ] Default to `lts` if non-interactive

### 3. Pre-Installation Safety

**Backup Everything:**
- [ ] `.zshrc` (already doing this ✓)
- [ ] `.zshenv`, `.zprofile`, `.zlogin`
- [ ] Existing plugin manager configs
- [ ] Shell history
- [ ] Create manifest of what will be changed
- [ ] Store backup location prominently

**Conflict Resolution:**
- [ ] Detect oh-my-zsh installation
  - Offer: migrate, disable, or abort
- [ ] Detect other plugin managers
  - Offer: migrate plugins, remove, or coexist
- [ ] Detect custom .zshrc modifications
  - Extract user customizations to `.franklin.local.zsh`

### 4. Installation & Configuration

**Package Installation:**
- [ ] Use smart detection (design doc workflow)
- [ ] Show progress for long operations
- [ ] Log all operations to install log
- [ ] Handle failures gracefully (continue vs abort)

**Initial Configuration:**
- [ ] Generate `plugins.toml` with sensible defaults
- [ ] Create `.franklin.local.zsh` with helpful comments
- [ ] Set up directory structure (`~/.config/franklin`, etc.)
- [ ] Create empty SSH config if missing (optional)
- [ ] Set git user.name/user.email if not configured (interactive)

### 5. Post-Install Health Check

**Verification:**
- [ ] All tools in PATH and executable
- [ ] Version check for all components
- [ ] Plugin manager can load plugins
- [ ] Prompt renders correctly
- [ ] No shell startup errors
- [ ] Completion system works
- [ ] Shell startup time < 500ms (warn if slower)

**Performance Baseline:**
- [ ] Measure shell startup time
- [ ] Test git operations in large repo
- [ ] Verify plugin loading time
- [ ] Store baseline for future comparison

### 6. Documentation & Next Steps

**Installation Report:**
```
Franklin Installation Complete! 🏕️

System Information:
  OS: macOS 13.5 (arm64)
  Shell: Zsh 5.9

Installed Components:
  ✓ sheldon 0.8.5 (brew)
  ✓ starship 1.17.1 (brew)
  ✓ bat 0.24.0 (brew)
  ✓ NVM 0.39.7 (manual)
  ✓ Node.js v20.11.0 LTS

Configuration:
  Franklin: ~/.config/franklin
  Backups: ~/.local/share/franklin/backups/20250120-143022
  Local overrides: ~/.franklin.local.zsh
  Install log: ~/.local/share/franklin/install.log

Next Steps:
  1. Restart terminal: exec zsh
  2. Run configuration wizard: franklin configure
  3. Customize: edit ~/.franklin.local.zsh
  4. Get help: franklin --help

Shell Startup Time: 247ms (baseline recorded)
```

**Interactive Tour (Optional):**
- [ ] Offer quick demo of features
- [ ] Show how to customize
- [ ] Explain `.franklin.local.zsh`
- [ ] Demo useful aliases/functions

### 7. Security & Permissions

**File Permissions:**
- [ ] Set `.franklin.local.zsh` to 600 (user-only)
- [ ] Verify no world-writable files created
- [ ] Check SSH key permissions if generated
- [ ] Warn about any insecure configurations

**Checksum Verification:**
- [ ] Verify downloaded binaries (already doing for NVM ✓)
- [ ] Check plugin sources are official repos
- [ ] Warn about unverified downloads

### 8. Cleanup & Rollback

**Post-Install Cleanup:**
- [ ] Remove temporary files
- [ ] Clear package manager cache (optional)
- [ ] Remove legacy/conflicting installations (if user agreed)

**Rollback Support:**
- [ ] Create uninstall script: `franklin uninstall`
- [ ] Document rollback procedure in install log
- [ ] Test rollback in CI/testing

### 9. Error Handling & Recovery

**Failure Modes:**
- [ ] Network failure: retry with backoff
- [ ] Package install failure: continue with warnings
- [ ] Permission denied: clear sudo instructions
- [ ] Disk full: abort with cleanup
- [ ] Partial install: offer resume or rollback

**Logging:**
- [ ] Verbose install log: `~/.local/share/franklin/install.log`
- [ ] Include timestamps, command output, errors
- [ ] Sanitize sensitive data (tokens, passwords)
- [ ] Make log easily shareable for debugging

### 10. Platform-Specific Considerations

**Raspberry Pi / ARM:**
- [ ] Detect ARM architecture
- [ ] Warn about longer install times
- [ ] Use pre-compiled binaries where available
- [ ] Skip heavy optional components by default

**Corporate/Restricted Environments:**
- [ ] Detect proxy settings and use them
- [ ] Offer offline install mode (bundled deps)
- [ ] Skip operations requiring sudo if unavailable
- [ ] Support custom package mirrors

**WSL/Windows:**
- [ ] Detect WSL environment
- [ ] Handle Windows line endings
- [ ] Skip macOS-specific features
- [ ] Integrate with Windows Terminal config (future)

## Open Questions

1. Should we support both sheldon and antigen for a transition period?
2. How to handle users who customized Antigen bundles?
3. Should sheldon be truly required, or optional with graceful degradation?
4. How to test on all platforms (need Raspberry Pi access)?
5. Should we add a configuration wizard (`franklin configure`) for post-install customization?
6. Do we need offline install support for restricted environments?
7. Should we measure and report shell startup time as part of install?

## References

- Sheldon: https://sheldon.cli.rs
- Antigen performance issues: https://github.com/zsh-users/antigen/issues
- Current Franklin .zshrc: `src/.zshrc`
- Current install helpers: `src/lib/install_helpers.sh`
