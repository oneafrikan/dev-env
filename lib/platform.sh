#!/usr/bin/env bash
# ─────────────────────────────────────────────
# lib/platform.sh — OS detection and wrappers
# Source this file; do not execute it directly
# ─────────────────────────────────────────────

# Detect once, export for child scripts
if [[ "$(uname -s)" == "Darwin" ]]; then
  export OS="mac"
else
  export OS="linux"
fi

# Open a GUI application by name
# Usage: platform_open_app "Cursor"
platform_open_app() {
  local app="$1"
  if [[ "$OS" == "mac" ]]; then
    open -a "$app" 2>/dev/null || warn "$app not found — skipping"
  else
    warn "platform_open_app: no Linux equivalent configured for '$app'"
  fi
}

# Open a file or workspace in Cursor
# Usage: platform_open_workspace "/path/to/file-or-workspace"
platform_open_workspace() {
  local target="$1"
  if [[ "$OS" == "mac" ]]; then
    open -a Cursor "$target" 2>/dev/null || warn "Cursor not found — skipping workspace open"
  else
    if command -v cursor &>/dev/null; then
      cursor "$target" &
    else
      warn "cursor CLI not found — skipping workspace open"
    fi
  fi
}

# Open a URL in the default browser
# Usage: platform_open_url "https://..."
platform_open_url() {
  local url="$1"
  if [[ "$OS" == "mac" ]]; then
    open "$url"
  else
    xdg-open "$url" 2>/dev/null || warn "xdg-open not available"
  fi
}

# Switch to a macOS Space via Hammerspoon (no-op on Linux)
# Usage: platform_switch_space 2
platform_switch_space() {
  local space="$1"
  if [[ "$OS" == "mac" ]]; then
    osascript -e "tell application \"Hammerspoon\" to execute lua code \"hs.spaces.gotoSpace($space)\"" 2>/dev/null || \
      warn "Hammerspoon not running — skipping Space switch"
  fi
  # Linux: no-op (use i3/sway workspaces natively if needed)
}

# Get the correct sed in-place flag (macOS requires '' arg, GNU doesn't)
# Usage: sed $(platform_sed_i) 's/foo/bar/' file
platform_sed_i() {
  if [[ "$OS" == "mac" ]]; then
    echo "-i ''"
  else
    echo "-i"
  fi
}

# Get stat mtime in seconds since epoch (macOS vs GNU stat differ)
# Usage: platform_stat_mtime "/path/to/file"
platform_stat_mtime() {
  local file="$1"
  if [[ "$OS" == "mac" ]]; then
    stat -f %m "$file"
  else
    stat -c %Y "$file"
  fi
}

# Get available disk space on a path in bytes
# Usage: platform_disk_free "/path"
platform_disk_free() {
  local path="$1"
  if [[ "$OS" == "mac" ]]; then
    df -k "$path" | awk 'NR==2 {print $4 * 1024}'
  else
    df --output=avail -B1 "$path" | tail -1
  fi
}
