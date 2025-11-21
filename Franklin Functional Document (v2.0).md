# **Franklin Functional Document (v2.0)**

This document describes the functionality of the Franklin Zsh environment. It is intended to be a comprehensive overview of how Franklin is installed, configured, and used, with a strict focus on cross-platform compatibility (macOS, Debian, RHEL).

## **Introduction**

Franklin is a Zsh configuration framework designed to provide a consistent, portable, and aesthetically pleasing shell experience across mixed environments. It bundles a curated set of tools and plugins, features a "Campfire" theme, and abstracts away the underlying differences between BSD (macOS) and GNU (Linux) userlands.

## **Rules & Guidelines**

1. **Idempotency:** The installation process must be safe to run multiple times without causing issues, duplicating configurations, or appending duplicate lines to RC files.  
2. **Safety First:** The installation must back up any existing user configurations *before* making changes.  
3. **Granular Platform Detection:** The installation must strictly identify the specific operating system variant, version, and CPU architecture. Generic "Linux" detection is insufficient.  
4. **Performance:** Shell startup time is critical. Heavy initializers (like NVM or rbenv) must be lazy-loaded.  
5. **User Feedback:** The installation must provide clear, color-coded feedback (stdout vs stderr) about actions taken.  
6. **Respect Existing Tools:** The installation must detect existing installations of tools (NVM, Sheldon, Starship) and integrate with them rather than attempting to overwrite them.  
7. **Runtime Normalization:** The runtime must export environment variables that standardize command flags (e.g., ls colors, grep behavior) to bridge the BSD/GNU divide.  
8. **MOTD Visuals:** A "Message of the Day" must be displayed on login, strictly adhering to the **Campfire Style Guide** (Source: https://github.com/jeremyfuksa/campfire).  
   * **Borders:** A thin horizontal line (using box-drawing characters ─) must appear at the top and bottom of the banner.  
   * **Content:** The center of the banner must display the **Hostname**, **IP Address**, and **Franklin Version**.  
   * **Color:** The user must select a color from the "Campfire" signature palette (e.g., Cello, Terracotta, Sage) or define a custom HEX code (\#rrggbb).  
   * **Adaptive Layout:**  
     * **Maximum Width:** The banner must never exceed **80 columns**.  
     * **Dynamic Range:** The layout must fluidly adapt between **40 columns** (minimum) and **80 columns** (maximum).  
     * **Minimum Layout:** A specific fallback layout must be defined for 40-column terminals (e.g., vertical stacking instead of horizontal spacing).  
9. **Container Awareness:** If Docker or Podman is detected, the MOTD should include a status grid for running containers below the main banner.  
10. **CLI Management:** The runtime must provide a CLI (franklin) for managing the environment, designed to be resilient even if the system Python environment is compromised.

## **Installation**

The installation process is broken down into two main stages: Bootstrap (fetch) and Install (configure).

### **Stage 1: Bootstrap**

The bootstrap.sh script is the entry point, typically run via curl.

1. **Minimal Arguments:** Accepts *only* a destination flag (--dir) and a source reference (--ref for branch/tag). All other configuration happens in Stage 2\.  
2. **Pre-flight Check:** Validates that the OS is supported.  
3. **Fetch:** Downloads the Franklin repository to \~/.local/share/franklin.  
4. **Handoff:** Executes install.sh.

### **Stage 2: Installation**

The install.sh script configures the environment.

1. **Granular Distro & Architecture Detection:**  
   * **Darwin (macOS):** Must distinguish between Apple Silicon (arm64) and Intel (x86\_64).  
   * **Debian Family:** Must explicitly identify Debian, Ubuntu, Kali, Pop\!\_OS, Mint, Raspberry Pi OS.  
   * **RHEL Family:** Must explicitly identify RHEL, CentOS Stream, Fedora, Rocky, AlmaLinux, Amazon Linux 2/2023.  
2. **Backups & Symlinking:**  
   * Moves existing .zshrc, .zprofile, and .zshenv to a timestamped backup directory (e.g., \~/.franklin/backups/YYYY-MM-DD\_HHMM).  
   * Links \~/.zshrc to the Franklin repository version.  
3. **Configuration (Interactive Mode):**  
   * **Campfire Color Selection:** A TUI (Text User Interface) list presenting the signature colors:  
     * **Cello** (\#607a97)  
     * **Terracotta** (\#b87b6a)  
     * **Black Rock** (\#747b8a)  
     * **Sage** (\#8fb14b)  
     * **Golden Amber** (\#f9c574)  
     * **Flamingo** (\#e75351)  
     * **Blue Calx** (\#b8c5d9)  
   * **Custom Input:** Must support rrggbb, \#rrggbb, and short \#rgb formats, validating against ^\#\[0-9A-Fa-f\]{6}$.  
   * **Automation Mode:** Defaults to "Cello" if \! \-t 0 (not TTY) or \--yes is passed.  
4. **Package Installation (The Polyglot Layer):**  
   * **macOS:** Runs brew bundle.  
   * **Debian/Ubuntu:** Runs apt-get install. Must explicitly install python3-venv, python3-pip, and batcat.  
   * **RHEL/Fedora:** Runs dnf install. Must check SELinux context.  
5. **Handling Existing Installations:**  
   * **NVM Policy:** If NVM is missing, install it. If NVM exists, ask the user before switching Node versions. If no input (Automation Mode), preserve existing version.  
   * **Foreign Tools:** Detects and integrates with existing sheldon or starship binaries rather than overwriting.

## **Core Components**

* **Zsh:** The shell.  
* **Sheldon:** Rust-based plugin manager.  
  * **Default Plugins:** zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions, git, history-substring-search, colored-man-pages, command-not-found.  
* **Starship:** Cross-shell prompt.  
* **bat:** cat replacement (aliased to batcat on Debian).  
* **Python 3 & uv:** Python language and package manager.  
* **NVM:** Node Version Manager (Lazy-Loaded).

## **Runtime Environment**

The .zshrc orchestration:

1. **Platform Normalization:**  
   * Sets CLICOLOR=1 (BSD) and LS\_COLORS (GNU).  
   * Aliases ls, grep, and bat to their colorized/correct binary names based on OS.  
2. **Standard Aliases:**  
   * ll: ls \-lAh  
   * la: ls \-A  
   * lh: ls \-lh  
   * l: ls \-CF  
   * Navigation: .., ..., ...., \~.  
3. **History Configuration:**  
   * HISTSIZE=200000, SAVEHIST=200000.  
   * Enables APPEND\_HISTORY, SHARE\_HISTORY.  
   * Deduplication: HIST\_IGNORE\_DUPS, HIST\_IGNORE\_SPACE.  
4. **Input & Keybindings:**  
   * Uses terminfo keys for broad compatibility.  
   * Up/Down: History Substring Search.  
   * Home/End: Beginning/End of line.  
   * Ctrl+Left/Right: Jump by word.  
5. **Lazy Loaders:**  
   * nvm, node, npm, npx are defined as functions that unset themselves, source NVM, and then run the command.  
6. **MOTD Execution:**  
   * Calculates geometry (min(terminal\_width, 80)).  
   * Renders the Campfire banner with the user's selected color.  
   * Displays System Stats (Distro, Memory) and Service Status (Docker).

## **CLI Architecture & Maintenance**

The franklin CLI is the primary interface for managing the environment. It is designed using the **Shim Pattern** to ensure robustness.

### **1\. The Shim Architecture**

To avoid "chicken and egg" problems (where a broken Python environment prevents fixing the Python environment), the entry point is split:

* **The Shim (bin/franklin):**  
  * **Language:** POSIX sh (no dependencies).  
  * **Responsibility:**  
    * Traps signals (SIGINT) for clean exits.  
    * Checks for the existence of Python 3\.  
    * If Python is missing, prints a standard error and exits 1\.  
    * If Python exists, hands off execution to lib/franklin\_core.py.  
* **The Core (lib/franklin\_core.py):**  
  * **Language:** Python 3\.  
  * **Libraries:** **Typer** (CLI routing), **Rich** (UI/TUI).  
  * **Responsibility:** Complex logic, API interactions, JSON formatting, and TUI rendering.

### **2\. Command Reference**

The CLI favors subcommands (verbs) over flags.

| Command | Description | Flags |
| :---- | :---- | :---- |
| franklin update | Updates Franklin core (git pull). | \--yes |
| franklin update-all | Updates Core \+ System Packages \+ Plugins. Requires sudo privileges for OS packages. | \--yes, \--system |
| franklin doctor | Runs a diagnostic check of the environment. | \--json |
| franklin config | Interactive TUI to change settings (e.g., color). | \--color \<hex\> |

### **3\. The "Campfire" UX Standards**

* **Visual Philosophy:** "Structured, Connected, Minimal." The UI treats every action as a node in a tree. **Hierarchy is enforced via strict indentation**, and **data is presented in aligned columns** to minimize cognitive load.  
* **Glyph Dictionary:**  
  * ⏺ (Record/Action): Indicates the start of a discrete task (e.g., "Installing Zsh").  
  * ⎿ (Branch/Connector): Connects the action header to its output or metadata.  
  * ∴ (Therefore/Thought): Indicates internal logic, decision making, or checks.  
  * ✻ (Asterisk/Spinner): Indicates active processing.  
* **Layout Rules:**  
  * **Indentation:**  
    * **Level 0 (Roots):** Start at column 0\.  
    * **Level 1 (Outputs):** Indented by **3 spaces** to align under the glyph of the parent.  
  * **Columnar Data:**  
    * Lists of keys/values (like in franklin doctor) must be aligned to a grid to allow vertical scanning.  
    * Ragged edges on the "key" side are forbidden.  
* **Layout Patterns:**  
  * **Command Execution:**  
    ⏺ Bash(apt-get install zsh)  
    ⎿  Reading package lists... Done  
       Building dependency tree... Done

  * **Columnar Status Checks:**  
    ∴ Checking Environment...  
    ⎿  Shell       :: Zsh 5.9  
       OS          :: Debian 12 (Bookworm)  
       Python      :: 3.11.2

  * **Input Prompts:**  
    ⎿  Tip: Use arrow keys to select your preferred color.

  * Output Truncation:  
    If command output exceeds a threshold (e.g., 10 lines), visually truncate to preserve tree structure.  
    ⎿  ... \+45 lines hidden (full log at \~/.local/share/franklin/logs/latest.log)

* **Stream Separation (The Rule of Silence):**  
  * stdout: Strictly reserved for machine-readable data (when \--json is used) or the final requested output.  
  * stderr: Strictly reserved for the "Tree" visualization, spinners, and user interactions.  
* **TTY Detection:** If the output is piped (\!isatty), all colors and animations are automatically disabled.  
* **Exit Codes:**  
  * 0: Success.  
  * 1: Generic/Runtime Error (e.g., Python script crash).  
  * 126: Command invoked cannot execute (e.g., git permission denied).  
  * 127: Command not found (e.g., git is missing entirely).  
  * 130: Script terminated by user (Ctrl+C).

### **4\. Automation Contract**

* **Default to Interactive:** Unless \--yes is passed or no TTY is present, scripts should ask before doing destructive work.  
* **Sudo Handling:** If update-all requires root:  
  1. Pause the spinner.  
  2. Clear the current line.  
  3. Request sudo password explicitly.  
  4. Resume the progress indicator.

## **Configuration Files**

* \~/.zshrc: The entry point (symlinked).  
* \~/.franklin.local.zsh: User overrides (git-ignored).  
* \~/.config/sheldon/plugins.toml: Plugin definitions.  
* \~/.config/starship.toml: Prompt styling.  
* \~/.local/share/franklin/config.env: Stores state (e.g., MOTD color preference).