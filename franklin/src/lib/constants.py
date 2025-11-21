"""
Franklin Constants - Paths and Color Definitions
"""

from pathlib import Path
import os

# --- Paths ---
HOME = Path.home()
FRANKLIN_ROOT = Path(os.environ.get("FRANKLIN_ROOT", HOME / ".local" / "share" / "franklin"))
CONFIG_DIR = HOME / ".config" / "franklin"
CONFIG_FILE = CONFIG_DIR / "config.env"
BACKUP_DIR = FRANKLIN_ROOT / "backups"

# --- Campfire Color Palette (for MOTD) ---
# These are the signature colors users can select for their MOTD banner
CAMPFIRE_COLORS = {
    "Cello": "#607a97",
    "Terracotta": "#b87b6a",
    "Black Rock": "#747b8a",
    "Sage": "#8fb14b",
    "Golden Amber": "#f9c574",
    "Flamingo": "#e75351",
    "Blue Calx": "#b8c5d9",
}

# Default color
DEFAULT_CAMPFIRE_COLOR = "Cello"

# --- UI Chrome Colors (for CLI output, not MOTD) ---
# These are used for the UI helpers in ui.py
UI_ERROR_COLOR = "#bf616a"  # Red for errors
UI_SUCCESS_COLOR = "#a3be8c"  # Green for success
UI_INFO_COLOR = "#88c0d0"  # Blue for info
UI_WARNING_COLOR = "#ebcb8b"  # Yellow for warnings

# --- Glyph Dictionary ---
GLYPH_ACTION = "⏺"
GLYPH_BRANCH = "⎿"
GLYPH_LOGIC = "∴"
GLYPH_WAIT = "✻"

# --- MOTD Layout Constants ---
MOTD_MAX_WIDTH = 80
MOTD_MIN_WIDTH = 40
MOTD_BORDER_CHAR = "─"
