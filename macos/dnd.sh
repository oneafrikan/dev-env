#!/usr/bin/env bash
# ─────────────────────────────────────────────
# macos/dnd.sh — toggle macOS Focus/Do Not Disturb
# Usage: dnd [on|off|status] [duration]
#        duration: 30m, 1h, 2h
# macOS only
# ─────────────────────────────────────────────
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "  ⚠ macos/dnd.sh — macOS only, skipping"
  exit 0
fi

ACTION="${1:-status}"

parse_seconds() {
  local input="$1"
  if [[ "$input" =~ ^([0-9]+)h$ ]]; then
    echo $(( ${BASH_REMATCH[1]} * 3600 ))
  elif [[ "$input" =~ ^([0-9]+)m$ ]]; then
    echo $(( ${BASH_REMATCH[1]} * 60 ))
  else
    echo ""
  fi
}

dnd_on() {
  osascript -e 'tell application "System Events"
    tell appearance preferences
      set dark mode to dark mode
    end tell
  end tell' 2>/dev/null || true
  # macOS 13+ Focus mode via shortcuts — this is the best available API
  osascript -e 'tell application "System Events" to keystroke "d" using {command down, option down}' 2>/dev/null || \
    echo "  ⚠ Could not toggle DND via keyboard shortcut — set manually in System Settings > Focus"
  echo "  ✓ DND toggled on"
}

dnd_off() {
  osascript -e 'tell application "System Events" to keystroke "d" using {command down, option down}' 2>/dev/null || \
    echo "  ⚠ Could not toggle DND — set manually in System Settings > Focus"
  echo "  ✓ DND toggled off"
}

case "$ACTION" in
  on)
    dnd_on
    DURATION="${2:-}"
    if [[ -n "$DURATION" ]]; then
      SECS=$(parse_seconds "$DURATION")
      if [[ -n "$SECS" ]]; then
        echo "  Auto-disabling in $DURATION..."
        (sleep "$SECS" && dnd_off && echo "  ✓ DND auto-disabled after $DURATION") &
      fi
    fi
    ;;
  off)
    dnd_off
    ;;
  status)
    echo "  DND status: check System Settings > Focus for current state"
    ;;
  *)
    echo "Usage: dnd [on|off|status] [duration]"
    echo "       duration: 30m, 1h, 2h"
    exit 1
    ;;
esac
