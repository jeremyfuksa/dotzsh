# **Franklin Technical Implementation Plan**

Objective: Build the Franklin Zsh environment (v2.0) based on the Functional Document.  
Target Platforms: macOS (Apple Silicon/Intel), Debian-based, RHEL-based.

## **Phase 1: Project Scaffolding & Python Core**

*Goal: Build the logic center (CLI) first so the installer has something to call.*

### **1.1 Directory Structure Setup**

* \[ \] Create the following directory tree:  
  franklin/  
  ├── bin/  
  │   └── franklin          \# POSIX Shim  
  ├── config/  
  │   ├── plugins.toml      \# Sheldon config  
  │   └── starship.toml     \# Starship config  
  ├── src/  
  │   ├── bootstrap.sh      \# Stage 1 Installer  
  │   ├── install.sh        \# Stage 2 Installer  
  │   └── lib/  
  │       ├── \_\_init\_\_.py  
  │       ├── main.py       \# Typer Entry Point  
  │       ├── constants.py  \# Colors, Paths  
  │       ├── motd.py       \# MOTD Logic  
  │       └── ui.py         \# Rich/Campfire TUI Helpers  
  ├── templates/  
  │   └── zshrc.zsh         \# The .zshrc template  
  └── requirements.txt

### **1.2 Python Dependencies**

* \[ \] Create requirements.txt with:  
  * typer\>=0.9.0  
  * rich\>=13.0.0  
  * psutil\>=5.9.0 (For memory/process stats in MOTD)

### **1.3 The "Campfire" UI Library (src/lib/ui.py)**

* \[ \] Implement the CampfireUI class using rich.  
* \[ \] Define the **Glyph Dictionary**:  
  * ACTION \= "⏺"  
  * BRANCH \= "⎿"  
  * LOGIC \= "∴"  
  * WAIT \= "✻"  
* \[ \] Implement print\_header(text): Prints ⏺ text.  
* \[ \] Implement print\_branch(text): Prints ⎿ text (3-space indent).  
* \[ \] Implement print\_error(text): Prints ⎿ text in Red (\#bf616a).

## **Phase 2: The CLI Logic (src/lib/)**

### **2.1 MOTD Generator (src/lib/motd.py)**

* \[ \] Implement get\_system\_stats():  
  * **Linux:** Parse /etc/os-release and /proc/meminfo.  
  * **macOS:** Use sw\_vers and vm\_stat.  
* \[ \] Implement render\_motd(width, color):  
  * **Constraint:** Max width 80 chars.  
  * **Constraint:** Min width 40 chars (fallback layout).  
  * **Visuals:** Top/Bottom borders using ─.

### **2.2 CLI Entry Point (src/lib/main.py)**

* \[ \] Initialize typer.Typer.  
* \[ \] Implement doctor command:  
  * Check Zsh version.  
  * Check sheldon binary presence.  
  * Check starship binary presence.  
  * Output in "Tree" format using CampfireUI.  
* \[ \] Implement update\_all command:  
  * Check for \--system flag.  
  * If \--system is present, use subprocess to call apt/dnf/brew with sudo.

## **Phase 3: The Installer Scripts**

### **3.1 Stage 1: Bootstrap (src/bootstrap.sh)**

* \[ \] Write a POSIX sh script.  
* \[ \] **Logic:**  
  1. Parse \--dir and \--ref.  
  2. git clone the repo to target dir.  
  3. exec into src/install.sh.

### **3.2 Stage 2: Installer (src/install.sh)**

* \[ \] **Platform Detection Block:**  
  * Detect OS (Darwin/Linux).  
  * Detect Distro (Debian/RHEL).  
  * Detect Arch (arm64/x86\_64).  
* \[ \] **Backup Logic:**  
  * mv \~/.zshrc to \~/.franklin/backups/Timestamp/.  
* \[ \] **TUI Configuration:**  
  * Implement a simple read loop to ask for Campfire Color (if TTY).  
  * Defaults to "Cello" (\#607a97) if non-interactive.  
* \[ \] **Dependency Loop:**  
  * Iterate through curl, git, python3, python3-venv.  
  * Install missing deps using the detected Package Manager.  
* \[ \] **Symlink:**  
  * Link \~/.zshrc \-\> franklin/templates/zshrc.zsh.

## **Phase 4: The Runtime Environment**

### **4.1 The .zshrc Template (templates/zshrc.zsh)**

* \[ \] **Platform Normalization:**  
  * Export CLICOLOR/LS\_COLORS.  
  * Alias bat \-\> batcat (Debian check).  
* \[ \] **Plugin Loading:**  
  * eval "$(sheldon source)".  
* \[ \] **Keybindings:**  
  * Bind Up/Down to history search.  
  * Bind Home/End.  
* \[ \] **NVM Lazy Load:**  
  * Write the nvm() function stub that unsets itself and sources $NVM\_DIR/nvm.sh.  
* \[ \] **MOTD Trigger:**  
  * Call franklin motd (via the shim) at the bottom of the file.

### **4.2 The Shim (bin/franklin)**

* \[ \] Write a POSIX sh script.  
* \[ \] **Logic:**  
  1. Check if python3 is available.  
  2. Set PYTHONPATH to the src dir.  
  3. Execute python3 \-m lib.main "$@".  
  4. Trap SIGINT to exit cleanly (code 130).

## **Phase 5: Configuration Files**

### **5.1 Sheldon (config/plugins.toml)**

* \[ \] Populate with the list from the Functional Doc (omitting command-not-found if OS support is missing, or keep it commented).

### **5.2 Starship (config/starship.toml)**

* \[ \] Configure a minimal, fast prompt matching the "Campfire" aesthetic (e.g., no line breaks, concise git status).