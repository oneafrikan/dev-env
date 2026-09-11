#!/usr/bin/env bash
# ─────────────────────────────────────────────
# scripts/iterm2-profiles/setup.sh
#
# Symlinks this machine's iTerm2 profile (profiles/<machine>.json) into
# iTerm2's DynamicProfiles folder, so it's picked up on launch and
# live-reloaded whenever the JSON changes. Safe to run multiple times.
#
# Machine name is taken from `hostname -s` (e.g. "laptop", "server1").
#
# Usage:
#   bash ~/.dev-env/scripts/iterm2-profiles/setup.sh [machine-name]
# ─────────────────────────────────────────────
set -euo pipefail

log()  { echo "  $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*" >&2; }
err()  { echo "  ✗ $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/profiles"
DYNAMIC_PROFILES_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

MACHINE="${1:-$(hostname -s)}"
SRC="$PROFILES_DIR/$MACHINE.json"
DEST="$DYNAMIC_PROFILES_DIR/$MACHINE.json"

if [[ ! -f "$SRC" ]]; then
  err "No profile for '$MACHINE' — expected $SRC"
  log "Known profiles: $(ls "$PROFILES_DIR" | sed 's/\.json$//' | tr '\n' ' ')"
  exit 1
fi

mkdir -p "$DYNAMIC_PROFILES_DIR"

if [[ -L "$DEST" && "$(readlink "$DEST")" == "$SRC" ]]; then
  ok "Already linked: $DEST -> $SRC"
elif [[ -e "$DEST" ]]; then
  err "$DEST exists and isn't the expected symlink — remove or inspect it manually before re-running"
  exit 1
else
  ln -s "$SRC" "$DEST"
  ok "Linked: $DEST -> $SRC"
fi

log "iTerm2 picks this up automatically (Dynamic Profiles reload live, no restart needed)."
log "Because this profile reuses the Guid of an existing manual profile (where one existed),"
log "it takes over that profile in place — same entry in the Profiles list, now git-managed."
