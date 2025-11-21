"""
MOTD (Message of the Day) Generator

Implements the Campfire-style MOTD banner with:
- Adaptive layout (40-80 columns)
- Border lines using box-drawing characters
- System stats (Hostname, IP, Franklin Version)
- User-selected Campfire color palette
- Platform-specific system info gathering
"""

import os
import platform
import socket
import subprocess
import sys
from pathlib import Path
from typing import Optional

import psutil
from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.align import Align

from .constants import (
    CAMPFIRE_COLORS,
    DEFAULT_CAMPFIRE_COLOR,
    MOTD_MAX_WIDTH,
    MOTD_MIN_WIDTH,
    MOTD_BORDER_CHAR,
    CONFIG_FILE,
)


def get_franklin_version() -> str:
    """Read Franklin version from VERSION file."""
    version_file = Path(__file__).parent.parent.parent.parent / "VERSION"
    if version_file.exists():
        return version_file.read_text().strip()
    return "unknown"


def get_hostname() -> str:
    """Get the system hostname."""
    try:
        return socket.gethostname()
    except Exception:
        return "unknown"


def get_ip_address() -> str:
    """Get the primary IP address."""
    try:
        # Connect to external DNS to find local IP (doesn't actually send data)
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception:
        return "0.0.0.0"


def get_system_stats() -> dict:
    """
    Gather system statistics.

    Returns:
        Dictionary with system information
    """
    stats = {
        "hostname": get_hostname(),
        "ip_address": get_ip_address(),
        "franklin_version": get_franklin_version(),
        "os": "",
        "memory": "",
    }

    # Platform-specific OS detection
    system = platform.system()

    if system == "Darwin":
        # macOS: Use sw_vers
        try:
            result = subprocess.run(
                ["sw_vers", "-productVersion"],
                capture_output=True,
                text=True,
                check=True,
            )
            macos_version = result.stdout.strip()
            stats["os"] = f"macOS {macos_version}"
        except Exception:
            stats["os"] = "macOS (version unknown)"

        # macOS memory via psutil
        try:
            mem = psutil.virtual_memory()
            total_gb = mem.total / (1024 ** 3)
            used_gb = mem.used / (1024 ** 3)
            stats["memory"] = f"{used_gb:.1f}GB / {total_gb:.1f}GB ({mem.percent:.0f}%)"
        except Exception:
            stats["memory"] = "unknown"

    elif system == "Linux":
        # Linux: Parse /etc/os-release
        try:
            os_release = {}
            with open("/etc/os-release") as f:
                for line in f:
                    if "=" in line:
                        key, value = line.strip().split("=", 1)
                        os_release[key] = value.strip('"')

            distro_name = os_release.get("NAME", "Linux")
            distro_version = os_release.get("VERSION_ID", "")
            if distro_version:
                stats["os"] = f"{distro_name} {distro_version}"
            else:
                stats["os"] = distro_name
        except Exception:
            stats["os"] = "Linux (unknown distribution)"

        # Linux memory from /proc/meminfo
        try:
            mem = psutil.virtual_memory()
            total_gb = mem.total / (1024 ** 3)
            used_gb = mem.used / (1024 ** 3)
            stats["memory"] = f"{used_gb:.1f}GB / {total_gb:.1f}GB ({mem.percent:.0f}%)"
        except Exception:
            stats["memory"] = "unknown"

    else:
        stats["os"] = system
        stats["memory"] = "unknown"

    return stats


def load_motd_color() -> str:
    """
    Load the user's MOTD color preference from config.

    Returns:
        Hex color string (e.g., "#607a97")
    """
    if not CONFIG_FILE.exists():
        return CAMPFIRE_COLORS[DEFAULT_CAMPFIRE_COLOR]

    try:
        with open(CONFIG_FILE) as f:
            for line in f:
                if line.startswith("MOTD_COLOR="):
                    color = line.split("=", 1)[1].strip().strip('"')
                    return color
    except Exception:
        pass

    return CAMPFIRE_COLORS[DEFAULT_CAMPFIRE_COLOR]


def render_motd(width: Optional[int] = None) -> None:
    """
    Render the Campfire MOTD banner.

    Args:
        width: Terminal width (auto-detected if None)
    """
    console = Console()

    # Determine terminal width
    if width is None:
        width = console.width

    # Constrain to MOTD min/max
    width = max(MOTD_MIN_WIDTH, min(width, MOTD_MAX_WIDTH))

    # Load user's color preference
    color = load_motd_color()

    # Gather system stats
    stats = get_system_stats()

    # Build the banner content
    lines = []

    # Adaptive layout based on width
    if width >= 60:
        # Wide layout: horizontal
        lines.append(f"Hostname: {stats['hostname']}")
        lines.append(f"IP Address: {stats['ip_address']}")
        lines.append(f"Franklin: v{stats['franklin_version']}")
        lines.append("")
        lines.append(f"OS: {stats['os']}")
        lines.append(f"Memory: {stats['memory']}")
    else:
        # Narrow layout: more compact
        lines.append(f"{stats['hostname']}")
        lines.append(f"{stats['ip_address']}")
        lines.append(f"Franklin v{stats['franklin_version']}")
        lines.append("")
        lines.append(f"{stats['os']}")
        lines.append(f"Mem: {stats['memory']}")

    # Create the panel with borders
    banner = Text("\n".join(lines), style=color, justify="center")

    panel = Panel(
        Align.center(banner),
        border_style=color,
        width=width,
        padding=(1, 2),
    )

    console.print(panel)


if __name__ == "__main__":
    render_motd()
