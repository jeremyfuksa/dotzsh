#!/usr/bin/env bash
if [ -n "${FRANKLIN_STREAMING_FILTERS:-}" ]; then
  return 0 2>/dev/null || true
fi
FRANKLIN_STREAMING_FILTERS=1
_should_show_line() {
  local preset="$1"
  local line="$2"
  case "$preset" in
    brew) _filter_brew "$line" ;;
    apt) _filter_apt "$line" ;;
    dnf) _filter_dnf "$line" ;;
    npm) _filter_npm "$line" ;;
    sheldon|starship|nvm|uv|tool) _filter_tool_update "$line" ;;
    *) return 0 ;;
  esac
}
_is_package_line() {
  local preset="$1"
  local line="$2"
  case "$preset" in
    brew)
      case "$line" in
        "==> Upgrading "*|"==> Installing "*|"==> Reinstalling "*|"==> Uninstalling "*) return 0 ;;
      esac
      return 1 ;;
    apt)
      case "$line" in
        Unpacking*|"Setting up"*|"Processing triggers for"*) return 0 ;;
      esac
      return 1 ;;
    dnf)
      case "$line" in
        Installing*|Upgrading*|Reinstalling*) return 0 ;;
      esac
      return 1 ;;
    npm)
      case "$line" in
        added*|updated*|removed*|changed*) return 0 ;;
      esac
      return 1 ;;
    *) return 1 ;;
  esac
}
_filter_brew() {
  local line="$1"
  if [[ "$line" =~ ^(Error:|Warning:) ]]; then
    return 0
  fi
  case "$line" in
    "==> Upgrading "*|"==> Installing "*|"==> Reinstalling "*|"==> Uninstalling "*) return 0 ;;
    "==> Summary"*|"🍺 "*) return 0 ;;
    "==> Downloading "*|"==> Fetching "*|"==> Pouring "*|"==> Building "*) return 1 ;;
    "==> Running "*cleanup*) return 1 ;;
    "###"*|"####"*|"#####"*) return 1 ;;
  esac
  if [[ "$line" =~ ^[[:space:]]+(files?,|Cellar/) ]]; then
    return 1
  fi
  return 0
}
_filter_apt() {
  local line="$1"
  if [[ "$line" =~ ^(E:|W:) ]]; then
    return 0
  fi
  if [[ "$line" =~ ^The\ following ]] ||
     [[ "$line" =~ ^(Unpacking|Setting\ up|Processing\ triggers\ for) ]] ||
     [[ "$line" =~ upgraded.*newly\ installed ]]; then
    return 0
  fi
  if [[ "$line" =~ ^(Get:|Fetched|Reading|Building\ dependency) ]] ||
     [[ "$line" =~ ^(Selecting\ previously|Preparing\ to\ unpack) ]] ||
     [[ "$line" =~ dpkg ]]; then
    return 1
  fi
  return 0
}
_filter_dnf() {
  local line="$1"
  if [[ "$line" =~ ^(Error:|Warning:) ]]; then
    return 0
  fi
  if [[ "$line" =~ ^(Transaction\ Summary|Installing|Upgrading|Reinstalling|Running\ transaction|Complete!) ]]; then
    return 0
  fi
  if [[ "$line" =~ (metadata|Downloading\ Packages|\[.*\]\ [0-9]+%|Dependencies\ resolved) ]]; then
    return 1
  fi
  return 0
}
_filter_npm() {
  local line="$1"
  if [[ "$line" =~ (ERR!|WARN) ]]; then
    return 0
  fi
  if [[ "$line" =~ ^(added|updated|removed|changed) ]]; then
    return 0
  fi
  if [[ "$line" =~ (vulnerabilities|packages\ in) ]]; then
    return 0
  fi
  if [[ "$line" =~ (npm\ http|npm\ timing|fetchPackageMetaData) ]]; then
    return 1
  fi
  return 1
}
_filter_tool_update() {
  local line="$1"
  if [[ "$line" =~ (Error|Warning|Failed|fatal) ]]; then
    return 0
  fi
  if [[ "$line" =~ ^(Updating|Cloning|Fetching|Already\ up|Successfully|Downloading|Installing|Checking) ]]; then
    return 0
  fi
  if [[ "$line" =~ (Counting\ objects|Compressing|Receiving\ objects|\[=+.*\]|%\ Total) ]]; then
    return 1
  fi
  return 0
}
